#!/bin/bash
# paperctl.d/cmd_compile.sh -- Compile all papers and report page counts
#
# Full compile cycle: pdflatex -> bibtex -> pdflatex x2
# Reports: page count, errors, warnings, undefined refs/cites
#
# Usage:
#   paperctl compile                     # compile all papers
#   paperctl compile --paper <name>      # single paper
#   paperctl compile --parallel          # compile all concurrently
#   paperctl compile --clean             # remove aux files after compile

load_config
. "$PAPERCTL_LIB/lib_check.sh"

PARALLEL=false
CLEAN=false
VERBOSE=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --parallel) PARALLEL=true; shift ;;
    --clean) CLEAN=true; shift ;;
    --verbose|-v) VERBOSE=true; shift ;;
    --help|-h) echo "Usage: paperctl compile [--parallel] [--clean] [--verbose]"; exit 0 ;;
    *) break ;;
  esac
done

# Global counters for summary
_COMPILE_TOTAL=0
_COMPILE_OK=0
_COMPILE_WARN=0
_COMPILE_FAIL=0
_COMPILE_TOTAL_PAGES=0

# --- Resolve TeX binaries (version-agnostic) ---
PDFLATEX=""
BIBTEX=""

# macOS: /Library/TeX/texbin is a stable symlink regardless of TL version
if [[ -x "/Library/TeX/texbin/pdflatex" ]]; then
  PDFLATEX="/Library/TeX/texbin/pdflatex"
  BIBTEX="/Library/TeX/texbin/bibtex"
fi

# Linux / fallback: search common locations
if [[ -z "$PDFLATEX" ]]; then
  for _texbin in /usr/local/texlive/*/bin/*/; do
    if [[ -x "${_texbin}pdflatex" ]]; then
      PDFLATEX="${_texbin}pdflatex"
      BIBTEX="${_texbin}bibtex"
      break
    fi
  done
fi

# Last resort: PATH
if [[ -z "$PDFLATEX" ]] && command -v pdflatex &>/dev/null; then
  PDFLATEX="$(command -v pdflatex)"
  BIBTEX="$(command -v bibtex)"
fi

if [[ -z "$PDFLATEX" ]]; then
  echo "ERROR: pdflatex not found. Install TeX Live:" >&2
  echo "  macOS: brew install --cask mactex" >&2
  echo "  Linux: apt install texlive-full" >&2
  exit 1
fi

_compile_one() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  # Find main.tex — conference-aware search
  # Priority: root → {SLUG}_submission/ → generic find_main_tex()
  local main_tex="" tex_dir="$repo_dir"
  if [[ -f "$repo_dir/main.tex" ]]; then
    main_tex="$repo_dir/main.tex"
  elif [[ -n "${CONF_NAME:-}" ]]; then
    # Try conference-specific subdirectory first (e.g. ECCV_submission/, NeurIPS_submission/)
    local _slug_upper
    _slug_upper=$(echo "${CONF_NAME}" | tr '[:lower:]' '[:upper:]')
    for _sub in "${_slug_upper}_submission" "${CONF_NAME}_submission" submission; do
      if [[ -f "$repo_dir/$_sub/main.tex" ]]; then
        main_tex="$repo_dir/$_sub/main.tex"
        tex_dir="$repo_dir/$_sub"
        break
      fi
    done
  fi
  # Fallback: use lib_check.sh generic finder
  if [[ -z "$main_tex" ]]; then
    main_tex=$(find_main_tex "$repo_dir")
    [[ -n "$main_tex" ]] && tex_dir=$(dirname "$main_tex")
  fi

  if [[ -z "$main_tex" || ! -f "$main_tex" ]]; then
    printf "  %-18s  ❌ no main.tex\n" "$name"
    return
  fi

  local main_base
  main_base=$(basename "$main_tex" .tex)
  local compile_log
  compile_log=$(mktemp /tmp/paperctl_compile_${name}.XXXXXX)

  # Determine compile directory and relative path
  local compile_dir="$repo_dir"
  local main_rel="${main_tex#$repo_dir/}"

  # Auto-detect TEXINPUTS: if main.tex is in a subdirectory, add that subdir
  # to TEXINPUTS so \usepackage{eccv} etc. can find .sty files next to main.tex
  local extra_texinputs=""
  if [[ "$tex_dir" != "$repo_dir" ]]; then
    extra_texinputs="${tex_dir}//:"
  fi

  # Full compile cycle: pdflatex -> bibtex -> pdflatex x2
  (cd "$compile_dir" && TEXINPUTS="${extra_texinputs}${TEXINPUTS:-}" "$PDFLATEX" -interaction=nonstopmode "$main_rel" > "$compile_log" 2>&1) || true

  # Find and run bibtex
  local aux_file="$compile_dir/$main_base.aux"
  [[ ! -f "$aux_file" ]] && aux_file="$tex_dir/$main_base.aux"
  if [[ -f "$aux_file" && -n "$BIBTEX" ]]; then
    local aux_dir
    aux_dir=$(dirname "$aux_file")
    (cd "$aux_dir" && "$BIBTEX" "$main_base" >> "$compile_log" 2>&1) || true
  fi

  # Pass 2 & 3
  (cd "$compile_dir" && TEXINPUTS="${extra_texinputs}${TEXINPUTS:-}" "$PDFLATEX" -interaction=nonstopmode "$main_rel" >> "$compile_log" 2>&1) || true
  (cd "$compile_dir" && TEXINPUTS="${extra_texinputs}${TEXINPUTS:-}" "$PDFLATEX" -interaction=nonstopmode "$main_rel" >> "$compile_log" 2>&1) || true

  # Find output PDF
  local pdf_file=""
  [[ -f "$compile_dir/$main_base.pdf" ]] && pdf_file="$compile_dir/$main_base.pdf"
  [[ -z "$pdf_file" && -f "$tex_dir/$main_base.pdf" ]] && pdf_file="$tex_dir/$main_base.pdf"

  if [[ -n "$pdf_file" && -f "$pdf_file" ]]; then
    # Get page count — try multiple methods
    local pages=""

    # Method 1: pdfinfo (most reliable)
    if [[ -z "$pages" ]] && command -v pdfinfo &>/dev/null; then
      pages=$(pdfinfo "$pdf_file" 2>/dev/null | grep -i "^Pages:" | awk '{print $2}')
    fi

    # Method 2: parse pdflatex log "Output written on main.pdf (16 pages, ...)"
    if [[ -z "$pages" || "$pages" == "0" ]]; then
      pages=$(grep -o 'Output written on [^ ]* ([0-9]* page' "$compile_log" 2>/dev/null | grep -o '[0-9]*' | tail -1)
    fi

    # Method 3: mdls (macOS Spotlight, may lag on new files)
    if [[ -z "$pages" || "$pages" == "0" ]] && command -v mdls &>/dev/null; then
      pages=$(mdls -name kMDItemNumberOfPages "$pdf_file" 2>/dev/null | awk '{print $3}')
      [[ "$pages" == "(null)" ]] && pages=""
    fi

    # Count errors and warnings
    local errors warnings undef_refs
    errors=$(grep -c "^!" "$compile_log" 2>/dev/null) || errors=0
    warnings=$(grep -c "^LaTeX Warning:" "$compile_log" 2>/dev/null) || warnings=0
    undef_refs=$(grep -c "undefined" "$compile_log" 2>/dev/null) || undef_refs=0

    local status_icon="✅"
    [[ "$errors" -gt 0 ]] && status_icon="⚠️ "
    [[ -z "$pages" || "$pages" == "0" ]] && status_icon="❌"

    printf "  %-18s  %s %2s pages  |  errors: %d  warnings: %d  undef: %d\n" \
      "$name" "$status_icon" "${pages:-?}" "$errors" "$warnings" "$undef_refs"

    # Track stats
    _COMPILE_TOTAL=$((_COMPILE_TOTAL + 1))
    if [[ -z "$pages" || "$pages" == "0" ]]; then
      _COMPILE_FAIL=$((_COMPILE_FAIL + 1))
    elif [[ "$errors" -gt 0 ]]; then
      _COMPILE_WARN=$((_COMPILE_WARN + 1))
      _COMPILE_TOTAL_PAGES=$((_COMPILE_TOTAL_PAGES + ${pages:-0}))
    else
      _COMPILE_OK=$((_COMPILE_OK + 1))
      _COMPILE_TOTAL_PAGES=$((_COMPILE_TOTAL_PAGES + ${pages:-0}))
    fi

    # Verbose: show first error
    if $VERBOSE && [[ "$errors" -gt 0 ]]; then
      local first_err
      first_err=$(grep "^!" "$compile_log" 2>/dev/null | head -1 | head -c 80)
      echo "                      └─ $first_err"
    fi
  else
    local first_error
    first_error=$(grep "^!" "$compile_log" 2>/dev/null | head -1 | head -c 60)
    printf "  %-18s  ❌ FAIL  %s\n" "$name" "${first_error:-no PDF produced}"
    _COMPILE_TOTAL=$((_COMPILE_TOTAL + 1))
    _COMPILE_FAIL=$((_COMPILE_FAIL + 1))

    if $VERBOSE; then
      grep "^!" "$compile_log" 2>/dev/null | head -3 | while read -r line; do
        echo "                      └─ ${line:0:80}"
      done
    fi
  fi

  # Clean aux files if requested
  if $CLEAN; then
    for _dir in "$compile_dir" "$tex_dir"; do
      rm -f "$_dir/$main_base.aux" "$_dir/$main_base.bbl" "$_dir/$main_base.blg" \
            "$_dir/$main_base.log" "$_dir/$main_base.out" "$_dir/$main_base.toc" \
            "$_dir/$main_base.fls" "$_dir/$main_base.fdb_latexmk" \
            "$_dir/$main_base.synctex.gz" 2>/dev/null
    done
  fi

  rm -f "$compile_log"
}

echo ""
echo "🔨 Compiling all papers (pdflatex → bibtex → pdflatex ×2)"
echo ""
printf "  %-18s  %s\n" "PAPER" "RESULT"
printf "  %-18s  %s\n" "-----" "------"

if $PARALLEL; then
  # Run compilations in background
  declare -a pids=()
  declare -a names=()
  i=0
  while [[ $i -lt $CONF_PAPER_COUNT ]]; do
    name=$(paper_field $i "name")
    repo=$(paper_field $i "repo")
    overleaf=$(paper_field $i "overleaf")
    upstream=$(paper_field $i "upstream")
    repo_dir="$CONF_DIR/$repo"

    if [[ -n "${PAPERCTL_PAPER:-}" && "$name" != "$PAPERCTL_PAPER" ]]; then
      i=$((i + 1))
      continue
    fi
    if [[ -d "$repo_dir" ]]; then
      _compile_one "$repo" "$name" "$overleaf" "$upstream" "$repo_dir" &
      pids+=($!)
      names+=("$name")
    fi
    i=$((i + 1))
  done
  # Wait for all
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done
else
  for_each_paper _compile_one
fi

echo ""
echo "  ─────────────────────────────"
printf "  📊 %d papers: ✅ %d ok  ⚠️  %d warn  ❌ %d fail  |  %d total pages\n" \
  "$_COMPILE_TOTAL" "$_COMPILE_OK" "$_COMPILE_WARN" "$_COMPILE_FAIL" "$_COMPILE_TOTAL_PAGES"
echo ""
