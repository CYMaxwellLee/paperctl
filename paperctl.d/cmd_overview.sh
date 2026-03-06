#!/bin/bash
# paperctl.d/cmd_overview.sh -- Unified project overview
#
# Shows: compile status, page count, word count, git status, last activity
#
# Usage:
#   paperctl overview                    # full dashboard
#   paperctl overview --paper <name>     # single paper detail

load_config
. "$PAPERCTL_LIB/lib_check.sh"

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --help|-h) echo "Usage: paperctl overview [--paper <name>]"; exit 0 ;;
    *) break ;;
  esac
done

# --- Resolve TeX binary ---
PDFLATEX=""
if [[ -x "/Library/TeX/texbin/pdflatex" ]]; then
  PDFLATEX="/Library/TeX/texbin/pdflatex"
elif command -v pdflatex &>/dev/null; then
  PDFLATEX="$(command -v pdflatex)"
fi

_overview_one() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  # --- Git status ---
  local dirty=""
  local uncommitted
  uncommitted=$(git -C "$repo_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  [[ "$uncommitted" -gt 0 ]] && dirty="*"

  local branch
  branch=$(git -C "$repo_dir" symbolic-ref --short HEAD 2>/dev/null || echo "?")

  local last_commit_date
  last_commit_date=$(git -C "$repo_dir" log -1 --format='%ar' 2>/dev/null || echo "?")

  local last_author
  last_author=$(git -C "$repo_dir" log -1 --format='%an' 2>/dev/null | head -c 12 || echo "?")

  # --- Page count from existing PDF ---
  local pages="-"
  local main_tex
  main_tex=$(find_main_tex "$repo_dir")
  if [[ -n "$main_tex" ]]; then
    local main_base
    main_base=$(basename "$main_tex" .tex)
    local pdf_dir
    pdf_dir=$(dirname "$main_tex")
    # Check both tex dir and repo root
    for _p in "$pdf_dir/$main_base.pdf" "$repo_dir/$main_base.pdf"; do
      if [[ -f "$_p" ]] && command -v pdfinfo &>/dev/null; then
        pages=$(pdfinfo "$_p" 2>/dev/null | grep -i "^Pages:" | awk '{print $2}')
        break
      fi
    done
  fi

  # --- Word count (fast: just total from existing .tex) ---
  local words="-"
  if [[ -n "$main_tex" ]]; then
    local content
    content=$(collect_tex_content "$main_tex" 2>/dev/null || true)
    if [[ -n "$content" ]]; then
      # Strip comments and common LaTeX commands for rough word count
      words=$(echo "$content" | \
        sed 's/%.*//' | \
        sed 's/\\[a-zA-Z]*{[^}]*}//g' | \
        sed 's/\\[a-zA-Z]*\[[^]]*\]//g' | \
        sed 's/\\[a-zA-Z]*//g' | \
        sed 's/[{}\\$&%#^_~]//g' | \
        wc -w | tr -d ' ')
    fi
  fi

  # --- Conference status from config ---
  local idx
  idx=$(paper_index_by_name "$name")
  local status="-"
  [[ -n "$idx" ]] && status=$(paper_field "$idx" "status")

  # --- Format output ---
  printf "  %-16s  %-14s  %3s pp  %5s w  %-12s  %s%s\n" \
    "$name" "$status" "$pages" "$words" "$last_author" "$last_commit_date" "${dirty:+ [dirty]}"
}

echo ""
echo "📋 Project Overview: ${CONF_NAME} ${CONF_YEAR} (${CONF_PAPER_COUNT} papers)"
echo ""
printf "  %-16s  %-14s  %5s  %7s  %-12s  %s\n" \
  "PAPER" "STATUS" "PAGES" "WORDS" "LAST AUTHOR" "LAST ACTIVITY"
printf "  %-16s  %-14s  %5s  %7s  %-12s  %s\n" \
  "─────" "──────" "─────" "─────" "───────────" "─────────────"

for_each_paper _overview_one

echo ""
