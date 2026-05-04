#!/bin/bash
# paperctl.d/cmd_autostatus.sh -- Paper status overview
#
# Collects per-section facts (content lines, placeholders, citations,
# figures) for each paper and prints a structured summary.
#
# Status judgment is NOT done by this script. A strict reviewer (Claude
# Opus via Claude Code Agent) reads the actual prose and decides.
# This script only gathers the evidence and, if --update is passed,
# writes a status value that was already decided externally.

UPDATE=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --update) UPDATE=true; shift ;;
    --set) SET_STATUS="$2"; shift 2 ;;
    --paper) PAPERCTL_PAPER="$2"; export PAPERCTL_PAPER; shift 2 ;;
    --dir) PAPERCTL_DIR="$2"; export PAPERCTL_DIR; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

load_config

# --- helpers ----------------------------------------------------------------

_count() {
  local file="$1" pattern="$2"
  [[ ! -f "$file" ]] && { echo 0; return; }
  local n; n=$(grep -cE "$pattern" "$file" 2>/dev/null) || n=0; echo "${n:-0}"
}

_content_lines() {
  local file="$1"; [[ ! -f "$file" ]] && { echo 0; return; }
  local n; n=$(grep -cvE '^\s*(%|$)' "$file" 2>/dev/null) || n=0; echo "${n:-0}"
}

_placeholder_count() {
  _count "$1" '\\(placeholder|todo|TODO|dotline)\{|\[TODO:|\[cite\]|\\textcolor\{red\}'
}

_cite_count() {
  _count "$1" '\\cite[tp]?\{[^}]+\}'
}

_fig_ref_count() {
  _count "$1" '\\(ref|cref|Cref|autoref)\{fig:'
}

# --- per-paper driver -------------------------------------------------------

_autostatus_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  # Current status
  local i=0
  while [[ $i -lt $CONF_PAPER_COUNT ]]; do
    [[ "$(paper_field $i "name")" == "$name" ]] && break
    i=$((i + 1))
  done
  local current_status
  current_status=$(paper_field $i "status")
  [[ "$current_status" == "null" ]] && current_status="-"

  echo "📄 $name  [current: $current_status]"

  # Find sections dir
  local sec_dir=""
  for d in "$repo_dir/sections" "$repo_dir/Sections" "$repo_dir/ECCV_submission/sections"; do
    [[ -d "$d" ]] && { sec_dir="$d"; break; }
  done

  if [[ -z "$sec_dir" ]]; then
    echo "  ⚠️  No sections/ directory found"
    echo ""
    return
  fi

  # Per-section breakdown
  local total_lines=0 total_ph=0 total_cites=0 total_figrefs=0
  printf "  %-30s %5s %3s %3s %3s\n" "Section" "Lines" "PH" "Cit" "Fig"
  printf "  %-30s %5s %3s %3s %3s\n" "-------" "-----" "--" "---" "---"

  for f in "$sec_dir"/*.tex; do
    [[ ! -f "$f" ]] && continue
    local fname lines ph cites figs
    fname=$(basename "$f" .tex)
    lines=$(_content_lines "$f")
    ph=$(_placeholder_count "$f")
    cites=$(_cite_count "$f")
    figs=$(_fig_ref_count "$f")
    total_lines=$((total_lines + lines))
    total_ph=$((total_ph + ph))
    total_cites=$((total_cites + cites))
    total_figrefs=$((total_figrefs + figs))
    printf "  %-30s %5d %3d %3d %3d\n" "$fname" "$lines" "$ph" "$cites" "$figs"
  done

  # Inline abstract from main.tex
  if [[ -f "$repo_dir/main.tex" ]]; then
    local abs_lines
    abs_lines=$(awk '/\\begin\{abstract\}/,/\\end\{abstract\}/' "$repo_dir/main.tex" 2>/dev/null \
      | grep -cvE '^\s*(%|$|\\(begin|end)\{abstract\})') || abs_lines=0
    if [[ $abs_lines -gt 0 ]]; then
      printf "  %-30s %5d %3s %3s %3s\n" "(inline abstract in main.tex)" "$abs_lines" "-" "-" "-"
    fi
  fi

  # Appendix / tables placeholders
  local extra_ph=0
  for sub_dir in appendix tables; do
    [[ ! -d "$repo_dir/$sub_dir" ]] && continue
    for f in "$repo_dir/$sub_dir"/*.tex; do
      [[ ! -f "$f" ]] && continue
      extra_ph=$((extra_ph + $(_placeholder_count "$f")))
    done
  done
  if [[ -f "$repo_dir/main.tex" ]]; then
    extra_ph=$((extra_ph + $(_placeholder_count "$repo_dir/main.tex")))
  fi
  total_ph=$((total_ph + extra_ph))

  # Figure files
  local fig_files=0
  for fig_dir in "$repo_dir/figures" "$repo_dir/Figures"; do
    [[ -d "$fig_dir" ]] || continue
    local n
    n=$(find "$fig_dir" -maxdepth 2 -type f \( -name '*.pdf' -o -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) 2>/dev/null | wc -l | tr -d ' ')
    fig_files=$((fig_files + n))
  done

  echo "  ─────────────────────────────────────────────────"
  printf "  %-30s %5d %3d %3d %3d   fig_files=%d\n" "TOTAL" "$total_lines" "$total_ph" "$total_cites" "$total_figrefs" "$fig_files"

  # --set: manually override status (e.g., from Claude Code reviewer judgment)
  if [[ -n "${SET_STATUS:-}" && "$UPDATE" == "true" ]]; then
    if command -v jq &>/dev/null; then
      local tmp; tmp=$(mktemp)
      jq ".papers[$i].status = \"$SET_STATUS\"" "$CONF_FILE" > "$tmp" \
        && cat "$tmp" > "$CONF_FILE" && rm -f "$tmp"
    else
      python3 -c "
import json, sys
with open(sys.argv[1]) as f: data = json.load(f)
data['papers'][$i]['status'] = sys.argv[2]
with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False); f.write('\n')
" "$CONF_FILE" "$SET_STATUS"
    fi
    echo "  📝 Status set: $current_status → $SET_STATUS"
  fi

  echo ""
}

echo "📊 Paper section overview"
echo ""
for_each_paper _autostatus_paper

if [[ "$UPDATE" != "true" ]]; then
  echo "💡 To set status: paperctl autostatus --paper <name> --set <status> --update"
fi
