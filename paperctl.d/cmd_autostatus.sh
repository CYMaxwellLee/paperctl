#!/bin/bash
# paperctl.d/cmd_autostatus.sh -- Auto-detect paper status from section content

# Parse flags
UPDATE=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --update) UPDATE=true; shift ;;
    --paper) PAPERCTL_PAPER="$2"; export PAPERCTL_PAPER; shift 2 ;;
    --dir) PAPERCTL_DIR="$2"; export PAPERCTL_DIR; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

load_config

echo "🔍 Auto-detecting paper status from section content"
echo ""
printf "%-18s %8s  %-14s → %-14s  %s\n" "PAPER" "LINES" "CURRENT" "DETECTED" "SECTIONS"
printf "%-18s %8s  %-14s   %-14s  %s\n" "-----" "-----" "-------" "--------" "--------"

_count_content_lines() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo 0
    return
  fi
  # Count non-blank, non-comment lines.
  # Note: `grep -c` always prints a number, but exits 1 when count is 0.
  # A naive `grep -c ... || echo 0` would emit "0\n0" in that case and break
  # arithmetic downstream. Capture once and default to 0 on any error.
  local count
  count=$(grep -cvE '^\s*(%|$)' "$file" 2>/dev/null) || count=0
  echo "${count:-0}"
}

_detect_status() {
  local repo_dir="$1"
  
  # Find section directory
  local sec_dir=""
  for d in "$repo_dir/sections" "$repo_dir/Sections" "$repo_dir/ECCV_submission/sections"; do
    if [[ -d "$d" ]]; then
      sec_dir="$d"
      break
    fi
  done
  
  if [[ -z "$sec_dir" ]]; then
    echo "early|0|no sections dir"
    return
  fi
  
  local total=0 content_count=0 section_info=""
  local has_intro=false has_method=false has_exp=false
  
  for texfile in "$sec_dir"/*.tex; do
    [[ ! -f "$texfile" ]] && continue
    local fname
    fname=$(basename "$texfile" .tex)
    local lines
    lines=$(_count_content_lines "$texfile")
    total=$((total + lines))
    
    local level="stub"
    if [[ $lines -gt 30 ]]; then
      level="content"
      content_count=$((content_count + 1))
    elif [[ $lines -gt 5 ]]; then
      level="partial"
    fi
    
    # Track key sections
    case "$fname" in
      *intro*|*1_*) [[ "$level" == "content" ]] && has_intro=true ;;
      *method*|*3_*|*approach*) [[ "$level" == "content" ]] && has_method=true ;;
      *experiment*|*4_*|*result*) [[ "$level" == "content" ]] && has_exp=true ;;
    esac
    
    if [[ "$level" != "stub" ]]; then
      [[ -n "$section_info" ]] && section_info+=", "
      section_info+="$fname(${lines})"
    fi
  done
  
  # Determine status
  local detected="early"
  if [[ "$has_intro" == "true" && "$has_method" == "true" && "$has_exp" == "true" ]]; then
    detected="complete"
  elif [[ $content_count -ge 3 && $total -gt 300 ]]; then
    detected="near-complete"
  elif [[ $content_count -ge 2 && $total -gt 100 ]]; then
    detected="draft"
  elif [[ $content_count -ge 1 ]]; then
    detected="outline"
  fi
  
  echo "$detected|$total|$section_info"
}

_autostatus_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
  
  # Get current status from conference.json
  local i=0
  while [[ $i -lt $CONF_PAPER_COUNT ]]; do
    if [[ "$(paper_field $i "name")" == "$name" ]]; then
      break
    fi
    i=$((i + 1))
  done
  local current_status
  current_status=$(paper_field $i "status")
  [[ "$current_status" == "null" ]] && current_status="-"
  
  # Detect
  local result
  result=$(_detect_status "$repo_dir")
  local detected total sections
  detected=$(echo "$result" | cut -d'|' -f1)
  total=$(echo "$result" | cut -d'|' -f2)
  sections=$(echo "$result" | cut -d'|' -f3)
  
  # Arrow indicator
  local arrow="  "
  if [[ "$current_status" != "$detected" ]]; then
    arrow="⬆️"
    [[ "$current_status" == "complete" || "$current_status" == "near-complete" ]] && arrow="  "
  fi
  
  printf "%-18s %8s  %-14s %s %-14s  %s\n" "$name" "$total" "$current_status" "$arrow" "$detected" "${sections:-empty}"
  
  # Update if --update and detected is "higher" than current (never downgrade)
  if [[ "$UPDATE" == "true" && "$current_status" != "$detected" ]]; then
    # Status rank
    _rank() {
      case "$1" in
        early) echo 0 ;;
        outline) echo 1 ;;
        draft) echo 2 ;;
        near-complete) echo 3 ;;
        complete) echo 4 ;;
        *) echo 0 ;;
      esac
    }
    local cur_rank det_rank
    cur_rank=$(_rank "$current_status")
    det_rank=$(_rank "$detected")
    
    if [[ $det_rank -gt $cur_rank ]]; then
      if command -v jq &>/dev/null; then
        local tmp
        tmp=$(mktemp)
        # Use cat-redirect (not mv) to preserve symlink: CONF_FILE may be a symlink
        # to <conf>-meta/conference.json; mv would replace the symlink with a regular file.
        jq ".papers[$i].status = \"$detected\"" "$CONF_FILE" > "$tmp" && cat "$tmp" > "$CONF_FILE" && rm -f "$tmp"
      else
        python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
data['papers'][$i]['status'] = sys.argv[2]
with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
" "$CONF_FILE" "$detected"
      fi
      echo "  📝 Updated $name: $current_status → $detected"
    fi
  fi
}

for_each_paper _autostatus_paper

echo ""
if [[ "$UPDATE" == "true" ]]; then
  echo "✅ conference.json updated (only upgrades, never downgrades)"
else
  echo "💡 Use --update to write detected statuses to conference.json"
fi
