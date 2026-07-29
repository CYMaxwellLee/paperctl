#!/bin/bash
# paperctl.d/cmd_spacing.sh -- Report vertical spacing that was shortened by hand
#
# LaTeX takes every structural gap from the document class, so gaps of the same
# kind are identical throughout a paper. One that falls short of its own kind
# was shortened with \vspace. The PDF holds no LaTeX commands, only glyph
# positions, so this measures the effect rather than reading the command, which
# is also all a reviewer can do.
#
# Usage:
#   paperctl spacing                      analyse every paper in conference.json
#   paperctl spacing --pdf main.pdf       analyse one PDF
#   paperctl spacing --pdf a.pdf --tex a.tex   also check the text block
#   paperctl spacing --fontsize 9         body font is 9pt, not the 10pt default
#   paperctl spacing --json               machine-readable

PDF_ARG=""
TEX_ARGS=()
FONTSIZE="10"
COLUMNS="auto"
AS_JSON=false

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --pdf)      PDF_ARG="$2"; shift 2 ;;
    --tex)      TEX_ARGS+=(--tex "$2"); shift 2 ;;
    --fontsize) FONTSIZE="$2"; shift 2 ;;
    --columns)  COLUMNS="$2"; shift 2 ;;
    --json)     AS_JSON=true; shift ;;
    --paper)    PAPERCTL_PAPER="$2"; export PAPERCTL_PAPER; shift 2 ;;
    --dir)      PAPERCTL_DIR="$2"; export PAPERCTL_DIR; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

if ! command -v pdftotext &>/dev/null; then
  echo "⛔ pdftotext not found. Install poppler (brew install poppler)." >&2
  exit 1
fi

SPACING_PY="${PAPERCTL_LIB}/lib_spacing.py"
if [[ ! -f "$SPACING_PY" ]]; then
  echo "⛔ ${SPACING_PY} missing" >&2
  exit 1
fi

_spacing_run() {
  local pdf="$1"; shift
  local extra=()
  [[ $# -gt 0 ]] && extra=("$@")
  local flags=(--fontsize "$FONTSIZE" --columns "$COLUMNS")
  [[ "$AS_JSON" == "true" ]] && flags+=(--json)
  python3 "$SPACING_PY" "$pdf" "${flags[@]}" ${extra[@]+"${extra[@]}"}
}

# ── Single PDF ────────────────────────────────────────────────────────────────
if [[ -n "$PDF_ARG" ]]; then
  if [[ ! -f "$PDF_ARG" ]]; then
    echo "⛔ no such file: $PDF_ARG" >&2
    exit 1
  fi
  [[ "$AS_JSON" == "false" ]] && { echo "📐 Vertical spacing -- $(basename "$PDF_ARG")"; echo ""; }
  _spacing_run "$PDF_ARG" ${TEX_ARGS[@]+"${TEX_ARGS[@]}"}
  exit $?
fi

# ── Every paper in conference.json ────────────────────────────────────────────
load_config

echo "📐 Vertical spacing across papers"
echo ""

_spacing_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  local tex_dir="$repo_dir"
  if [[ ! -f "$repo_dir/main.tex" ]]; then
    local _found
    _found=$(find "$repo_dir" -name "main.tex" -not -path "*/.git/*" -print -quit 2>/dev/null || true)
    [[ -n "$_found" ]] && tex_dir=$(dirname "$_found")
  fi

  local pdf=""
  [[ -f "$tex_dir/main.pdf" ]] && pdf="$tex_dir/main.pdf"
  [[ -z "$pdf" && -f "$repo_dir/main.pdf" ]] && pdf="$repo_dir/main.pdf"

  echo "── ${name} ──"
  if [[ -z "$pdf" ]]; then
    echo "  (no compiled main.pdf -- run 'paperctl compile' first)"
    echo ""
    return
  fi

  local tex_flags=()
  [[ -f "$tex_dir/main.tex" ]] && tex_flags=(--tex "$tex_dir/main.tex")

  _spacing_run "$pdf" ${tex_flags[@]+"${tex_flags[@]}"}
  echo ""
}

for_each_paper _spacing_paper

echo "💡 Shortened spacing is ordinary typesetting. A redefined text block is not:"
echo "   AAAI, CVPR and ICML forbid it and charge or reject on it."
