#!/bin/bash
# paperctl.d/cmd_report.sh -- Student activity report (compare pre-sync state vs current HEAD)
#
# Usage:
#   paperctl report [--output <file>] [--json] [--update-notes]
#
# Requires: `paperctl start` must have been run at least once to save state.

# --- Parse flags ---
REPORT_OUTPUT=""
REPORT_JSON=false
REPORT_UPDATE_NOTES=false

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --output)       REPORT_OUTPUT="$2"; shift 2 ;;
    --json)         REPORT_JSON=true; shift ;;
    --update-notes) REPORT_UPDATE_NOTES=true; shift ;;
    --paper)        PAPERCTL_PAPER="$2"; export PAPERCTL_PAPER; shift 2 ;;
    --dir)          PAPERCTL_DIR="$2"; export PAPERCTL_DIR; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

load_config

# --- Check state file exists ---
if ! load_sync_state; then
  echo "❌ No sync state found. Run 'paperctl start' first to save pre-sync state." >&2
  exit 1
fi

SAVED_TS=$(get_saved_timestamp)

# --- Output buffer ---
_rbuf=""
_rp() { _rbuf+="$*"$'\n'; }

# --- JSON accumulator ---
_json_papers=()
_changed_count=0
_unchanged_names=()

# --- File category classifier ---
_classify_file() {
  local file="$1"
  case "$file" in
    *.bib)                   echo "references" ;;
    sections/*.tex)          echo "section" ;;
    ECCV_submission/sections/*.tex) echo "section" ;;
    CVPR_submission/sections/*.tex) echo "section" ;;
    figures/*|figs/*|ECCV_submission/figures/*) echo "figure" ;;
    main.tex|*/main.tex)     echo "structure" ;;
    preamble.tex|common_macros.tex|*/preamble.tex) echo "structure" ;;
    *.tex)                   echo "tex" ;;
    *.py|*.sh)               echo "code" ;;
    *)                       echo "other" ;;
  esac
}

# --- Extract section name from path ---
_section_name() {
  local file="$1"
  # sections/introduction.tex → introduction
  local base
  base=$(basename "$file" .tex)
  echo "$base"
}

# --- Generate observation string from categorized changes ---
_build_observation() {
  local repo_dir="$1" old_sha="$2" new_sha="$3"

  local parts=()

  # Count bib changes
  local bib_stat
  bib_stat=$(git -C "$repo_dir" diff --numstat "$old_sha..$new_sha" -- '*.bib' 2>/dev/null)
  if [[ -n "$bib_stat" ]]; then
    local bib_added=0
    while IFS=$'\t' read -r added removed _; do
      bib_added=$((bib_added + added))
    done <<< "$bib_stat"
    if [[ $bib_added -gt 0 ]]; then
      parts+=("補了 ${bib_added} 行 references")
    fi
  fi

  # Identify changed sections
  local changed_sections=()
  local changed_files
  changed_files=$(git -C "$repo_dir" diff --name-only "$old_sha..$new_sha" 2>/dev/null)
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    local cat
    cat=$(_classify_file "$f")
    if [[ "$cat" == "section" || "$cat" == "tex" ]]; then
      local sname
      sname=$(_section_name "$f")
      # Avoid duplicates
      local found=false
      for s in "${changed_sections[@]:-}"; do
        [[ "$s" == "$sname" ]] && found=true
      done
      [[ "$found" == "false" ]] && changed_sections+=("$sname")
    fi
  done <<< "$changed_files"
  if [[ ${#changed_sections[@]} -gt 0 ]]; then
    local joined
    joined=$(IFS=', '; echo "${changed_sections[*]}")
    parts+=("更新了 ${joined}")
  fi

  # Count figure changes
  local fig_files=()
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    local cat
    cat=$(_classify_file "$f")
    [[ "$cat" == "figure" ]] && fig_files+=("$(basename "$f")")
  done <<< "$changed_files"
  if [[ ${#fig_files[@]} -gt 0 ]]; then
    # Check if new files (not in old commit)
    local new_count=0 mod_count=0
    for ff in "${fig_files[@]}"; do
      # Use the full path to check existence in old tree
      local full_path
      full_path=$(git -C "$repo_dir" diff --name-only "$old_sha..$new_sha" 2>/dev/null | grep "$ff" | head -1)
      if git -C "$repo_dir" cat-file -e "$old_sha:$full_path" 2>/dev/null; then
        mod_count=$((mod_count + 1))
      else
        new_count=$((new_count + 1))
      fi
    done
    local fig_desc=""
    [[ $new_count -gt 0 ]] && fig_desc+="新增 ${new_count} 張圖"
    [[ $mod_count -gt 0 ]] && { [[ -n "$fig_desc" ]] && fig_desc+=" + "; fig_desc+="更新 ${mod_count} 張圖"; }
    [[ -n "$fig_desc" ]] && parts+=("$fig_desc")
  fi

  # Join parts
  if [[ ${#parts[@]} -gt 0 ]]; then
    local obs
    obs=$(IFS=' + '; echo "${parts[*]}")
    echo "$obs"
  else
    echo "有更新"
  fi
}

# --- Per-paper report ---
_report_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  # Lookup paper fields
  local i=0
  while [[ $i -lt $CONF_PAPER_COUNT ]]; do
    if [[ "$(paper_field $i "name")" == "$name" ]]; then break; fi
    i=$((i + 1))
  done
  local domain paper_id
  domain=$(paper_field $i "domain")
  paper_id=$(paper_field $i "paper_id")
  [[ "$domain" == "null" ]] && domain=""
  [[ "$paper_id" == "null" ]] && paper_id=""

  # Get saved vs current SHA
  local old_sha new_sha
  old_sha=$(get_saved_sha "$name")
  new_sha=$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null)

  if [[ -z "$old_sha" || "$old_sha" == "null" || "$old_sha" == "unknown" ]]; then
    _unchanged_names+=("$name")
    return
  fi

  if [[ "$old_sha" == "$new_sha" ]]; then
    _unchanged_names+=("$name")
    return
  fi

  _changed_count=$((_changed_count + 1))

  # --- Analyze changes ---
  local changed_files diffstat commits commit_count
  changed_files=$(git -C "$repo_dir" diff --name-only "$old_sha..$new_sha" 2>/dev/null)
  diffstat=$(git -C "$repo_dir" diff --stat --stat-width=60 "$old_sha..$new_sha" 2>/dev/null | tail -1)
  commits=$(git -C "$repo_dir" log --oneline "$old_sha..$new_sha" 2>/dev/null)
  commit_count=$(echo "$commits" | grep -c '.' 2>/dev/null || echo "0")

  # Categorize files
  local bib_files=() section_files=() figure_files=() other_files=()
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    local cat
    cat=$(_classify_file "$f")
    case "$cat" in
      references) bib_files+=("$f") ;;
      section|tex) section_files+=("$f") ;;
      figure)     figure_files+=("$f") ;;
      *)          other_files+=("$f") ;;
    esac
  done <<< "$changed_files"

  # Build observation
  local observation
  observation=$(_build_observation "$repo_dir" "$old_sha" "$new_sha")

  # --- Format output ---
  local header="**$name**"
  [[ -n "$domain" ]] && header+=" ($domain)"
  [[ -n "$paper_id" ]] && header+=" #$paper_id"
  _rp "$header"

  # Sections
  if [[ ${#section_files[@]} -gt 0 ]]; then
    local sec_detail=""
    for sf in "${section_files[@]}"; do
      local sname
      sname=$(basename "$sf")
      local numstat
      numstat=$(git -C "$repo_dir" diff --numstat "$old_sha..$new_sha" -- "$sf" 2>/dev/null)
      local added=0 removed=0
      if [[ -n "$numstat" ]]; then
        read -r added removed _ <<< "$numstat"
      fi
      [[ -n "$sec_detail" ]] && sec_detail+=", "
      sec_detail+="\`$sname\` (+$added −$removed)"
    done
    _rp "  📝 Sections: $sec_detail"
  fi

  # References
  if [[ ${#bib_files[@]} -gt 0 ]]; then
    local bib_detail=""
    for bf in "${bib_files[@]}"; do
      local bname
      bname=$(basename "$bf")
      local numstat
      numstat=$(git -C "$repo_dir" diff --numstat "$old_sha..$new_sha" -- "$bf" 2>/dev/null)
      local added=0 removed=0
      if [[ -n "$numstat" ]]; then
        read -r added removed _ <<< "$numstat"
      fi
      [[ -n "$bib_detail" ]] && bib_detail+=", "
      bib_detail+="\`$bname\` (+$added −$removed)"
    done
    _rp "  📚 References: $bib_detail"
  fi

  # Figures
  if [[ ${#figure_files[@]} -gt 0 ]]; then
    local fig_names=()
    for ff in "${figure_files[@]}"; do
      fig_names+=("$(basename "$ff")")
    done
    local fig_list
    fig_list=$(IFS=', '; echo "${fig_names[*]}")
    _rp "  🖼️  Figures: $fig_list"
  fi

  # Diffstat summary
  [[ -n "$diffstat" ]] && _rp "  📊 $diffstat"

  # Observation
  _rp "  💬 $observation"

  # Commits
  if [[ "$commit_count" -gt 0 ]]; then
    _rp "  🔗 Commits ($commit_count):"
    local shown=0
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      _rp "    - $line"
      shown=$((shown + 1))
      [[ $shown -ge 5 ]] && break
    done <<< "$commits"
    if [[ "$commit_count" -gt 5 ]]; then
      _rp "    ... and $((commit_count - 5)) more"
    fi
  fi

  _rp ""

  # --- Update conference.json notes if requested ---
  if [[ "$REPORT_UPDATE_NOTES" == "true" ]]; then
    local current_notes
    current_notes=$(paper_field $i "notes")
    [[ "$current_notes" == "null" ]] && current_notes=""

    # Append observation with date
    local today
    today=$(date "+%m/%d")
    local new_notes="${current_notes:+$current_notes | }[$today] 學生: $observation"

    python3 -c "
import json, sys
conf_file = sys.argv[1]
paper_name = sys.argv[2]
new_notes = sys.argv[3]
with open(conf_file) as f:
    data = json.load(f)
for p in data['papers']:
    if p['name'] == paper_name:
        p['notes'] = new_notes
        break
with open(conf_file, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
" "$CONF_FILE" "$name" "$new_notes"
    _rp "  ✏️  conference.json notes updated"
    _rp ""
  fi
}

# --- Header ---
_today=$(date "+%Y-%m-%d")
_rp "## 📋 Student Activity Report ($_today)"
# Parse saved timestamp for display
if [[ -n "$SAVED_TS" && "$SAVED_TS" != "null" ]]; then
  _human_ts=$(echo "$SAVED_TS" | sed 's/T/ /; s/+.*//; s/\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\) \([0-9]\{2\}:[0-9]\{2\}\).*/\1 \2/')
  _rp "> Since last sync: $_human_ts"
else
  _rp "> Since last sync: unknown"
fi
_rp ""

# --- Process each paper ---
for_each_paper _report_paper

# --- Summary ---
_total=$((_changed_count + ${#_unchanged_names[@]}))
_rp "---"
_rp ""

if [[ $_changed_count -gt 0 ]]; then
  _rp "**有變動: $_changed_count / $_total**"
else
  _rp "**全部無變動 ($_total papers)**"
fi

if [[ ${#_unchanged_names[@]} -gt 0 ]]; then
  _unchanged_list=$(IFS=', '; echo "${_unchanged_names[*]}")
  _rp "無變動: $_unchanged_list"
fi

_rp ""
_rp "_Generated by \`paperctl report\` · $(date '+%Y-%m-%d %H:%M')_"

# --- Output ---
if [[ -n "$REPORT_OUTPUT" ]]; then
  echo "$_rbuf" > "$REPORT_OUTPUT"
  echo "✅ Report written to $REPORT_OUTPUT"
else
  echo "$_rbuf"
fi
