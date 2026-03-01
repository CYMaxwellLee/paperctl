#!/bin/bash
# paperctl.d/cmd_heatmap.sh -- Per-section change heatmap
#
# Shows which sections of each paper have been modified recently,
# with visual intensity indicators. Useful for tracking student progress
# across multiple papers at a glance.
#
# Uses git diff --stat against a reference point (default: 3 days ago).
#
# Usage:
#   paperctl heatmap [--paper <name>] [--since "3 days ago"]

load_config
. "$PAPERCTL_LIB/lib_check.sh"

SINCE="3 days ago"
SUMMARY=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    --summary) SUMMARY=true; shift ;;
    *) break ;;
  esac
done

# Intensity bar based on line count
_intensity() {
  local lines="$1"
  if [[ "$lines" -eq 0 ]]; then
    echo "  ·"
  elif [[ "$lines" -le 5 ]]; then
    echo "  ░"
  elif [[ "$lines" -le 20 ]]; then
    echo "  ▒"
  elif [[ "$lines" -le 50 ]]; then
    echo "  ▓"
  else
    echo "  █"
  fi
}

# --- Summary: compact one-liner per paper ---
_heatmap_summary() {
  set +e
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  local since_sha
  since_sha=$(git -C "$repo_dir" log --until="$SINCE" --format="%H" -1 2>/dev/null || echo "")
  [[ -z "$since_sha" ]] && since_sha=$(git -C "$repo_dir" rev-list --max-parents=0 HEAD 2>/dev/null | head -1)

  local total_add=0 total_del=0
  if [[ -n "$since_sha" ]]; then
    while IFS= read -r diffline; do
      [[ -z "$diffline" ]] && continue
      local ins del fn
      ins=$(echo "$diffline" | awk '{print $1}')
      del=$(echo "$diffline" | awk '{print $2}')
      fn=$(echo "$diffline" | awk '{print $3}')
      [[ "$ins" == "-" ]] && continue  # binary
      [[ "$fn" != *.tex && "$fn" != *.bib ]] && continue
      total_add=$((total_add + ins))
      total_del=$((total_del + del))
    done < <(git -C "$repo_dir" diff --numstat "$since_sha"..HEAD 2>/dev/null)
  fi

  local total=$((total_add + total_del))

  # Build a visual bar (max width 20 chars, scaled to 2000 lines)
  local bar_len=0
  if [[ "$total" -gt 0 ]]; then
    bar_len=$(( (total * 20) / 2000 ))
    [[ "$bar_len" -lt 1 ]] && bar_len=1
    [[ "$bar_len" -gt 20 ]] && bar_len=20
  fi

  local bar=""
  local i=0
  while [[ $i -lt $bar_len ]]; do
    bar+="█"
    i=$((i + 1))
  done
  # Pad to 20
  while [[ $i -lt 20 ]]; do
    bar+="░"
    i=$((i + 1))
  done

  # Figure count
  local fig_changes=0
  if [[ -n "$since_sha" ]]; then
    fig_changes=$(git -C "$repo_dir" diff --name-only "$since_sha"..HEAD 2>/dev/null \
      | grep -cE '\.(pdf|png|jpg|jpeg|eps|svg)$' || true)
    [[ -z "$fig_changes" ]] && fig_changes=0
  fi

  local fig_str=""
  [[ "$fig_changes" -gt 0 ]] && fig_str=" 📊${fig_changes}"

  printf "  %-14s %s %5d (+%-4d -%d)%s\n" "$name" "$bar" "$total" "$total_add" "$total_del" "$fig_str"
  set -e
}

_heatmap_paper() {
  set +e
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $name  (since: $SINCE)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local main_tex
  main_tex=$(find_main_tex "$repo_dir")
  if [[ -z "$main_tex" ]]; then
    echo "  (no main.tex)"
    echo ""
    return
  fi

  local tex_dir
  tex_dir=$(dirname "$main_tex")

  # Get the commit SHA from --since
  local since_sha
  since_sha=$(git -C "$repo_dir" log --until="$SINCE" --format="%H" -1 2>/dev/null || echo "")

  if [[ -z "$since_sha" ]]; then
    # No commits before that date; use first commit
    since_sha=$(git -C "$repo_dir" rev-list --max-parents=0 HEAD 2>/dev/null | head -1)
  fi

  if [[ -z "$since_sha" ]]; then
    echo "  (no git history)"
    echo ""
    return
  fi

  # Get per-file diff stats for .tex files
  local total_changed=0
  local has_output=false

  # Section mapping: try to map filenames to section names
  while IFS= read -r diffline; do
    [[ -z "$diffline" ]] && continue
    # Format: "insertions deletions filename"
    local ins del filename
    ins=$(echo "$diffline" | awk '{print $1}')
    del=$(echo "$diffline" | awk '{print $2}')
    filename=$(echo "$diffline" | awk '{print $3}')

    # Skip non-tex files and hidden files
    [[ "$filename" != *.tex ]] && continue
    [[ "$filename" == .* ]] && continue

    local total_lines=$((ins + del))
    [[ "$total_lines" -eq 0 ]] && continue

    total_changed=$((total_changed + total_lines))
    has_output=true

    local bar
    bar=$(_intensity "$total_lines")

    # Format: intensity bar | filename | +ins -del
    printf "  %s %-35s +%-4d -%d\n" "$bar" "$filename" "$ins" "$del"
  done < <(git -C "$repo_dir" diff --numstat "$since_sha"..HEAD 2>/dev/null)

  # Also check for .bib changes
  while IFS= read -r diffline; do
    [[ -z "$diffline" ]] && continue
    local ins del filename
    ins=$(echo "$diffline" | awk '{print $1}')
    del=$(echo "$diffline" | awk '{print $2}')
    filename=$(echo "$diffline" | awk '{print $3}')

    [[ "$filename" != *.bib ]] && continue

    local total_lines=$((ins + del))
    [[ "$total_lines" -eq 0 ]] && continue

    total_changed=$((total_changed + total_lines))
    has_output=true

    local bar
    bar=$(_intensity "$total_lines")
    printf "  %s %-35s +%-4d -%d\n" "$bar" "$filename" "$ins" "$del"
  done < <(git -C "$repo_dir" diff --numstat "$since_sha"..HEAD 2>/dev/null)

  # Figure changes (count only)
  local fig_changes
  fig_changes=$(git -C "$repo_dir" diff --name-only "$since_sha"..HEAD 2>/dev/null \
    | grep -cE '\.(pdf|png|jpg|jpeg|eps|svg)$' || true)
  [[ -z "$fig_changes" ]] && fig_changes=0
  if [[ "$fig_changes" -gt 0 ]]; then
    has_output=true
    echo "  📊 $fig_changes figure file(s) changed"
  fi

  if ! $has_output; then
    echo "  (no changes)"
  else
    echo "  ─────────────────────────────────────"
    echo "  Total: $total_changed lines changed"
  fi

  echo ""
  # Legend on first paper
  if [[ "$name" == "$(paper_field 0 name)" || "${PAPERCTL_PAPER:-}" == "$name" ]]; then
    echo "  Legend: · none  ░ 1-5  ▒ 6-20  ▓ 21-50  █ 50+"
    echo ""
  fi

  set -e
}

echo ""
if $SUMMARY; then
  echo "  📊 Heatmap Summary (since: $SINCE)"
  echo "  ──────────────────────────────────────────────────────"
  for_each_paper _heatmap_summary
  echo "  ──────────────────────────────────────────────────────"
  echo "  Legend: █ changed  ░ remaining (scale: 20 chars = 2000 lines)"
  echo ""
else
  echo "=========================================="
  echo "  Section Change Heatmap"
  echo "=========================================="
  echo ""
  for_each_paper _heatmap_paper
fi
