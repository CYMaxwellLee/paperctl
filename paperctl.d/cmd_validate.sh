#!/bin/bash
# paperctl.d/cmd_validate.sh -- Static LaTeX validation + local compilation
#
# Static checks (no compiler needed):
#   1. Undefined cross-references (\ref, \cref, \Cref, \eqref, \autoref)
#   2. Undefined citations (vs .bib entries)
#   3. Missing \input files
#   4. Missing figure files (\includegraphics)
#   5. Missing table \input files
#   6. Page count (from compiled PDF)
#
# With --compile: runs pdflatex + bibtex locally, reports errors + page count.
#
# Usage:
#   paperctl validate [--paper <name>]           # static checks only
#   paperctl validate [--paper <name>] --compile # also compile locally

load_config
. "$PAPERCTL_LIB/lib_check.sh"

DO_COMPILE=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --compile) DO_COMPILE=true; shift ;;
    *) break ;;
  esac
done

# --- Resolve TeX binaries (BasicTeX / MacTeX may not be in PATH) ---
PDFLATEX=""
BIBTEX=""
for _texbin in "/Library/TeX/texbin" "/usr/local/texlive/2025/bin/universal-darwin" "/usr/local/texlive/2024/bin/universal-darwin"; do
  if [[ -x "$_texbin/pdflatex" ]]; then
    PDFLATEX="$_texbin/pdflatex"
    BIBTEX="$_texbin/bibtex"
    break
  fi
done
# Fallback: check PATH
if [[ -z "$PDFLATEX" ]] && command -v pdflatex &>/dev/null; then
  PDFLATEX="$(command -v pdflatex)"
  BIBTEX="$(command -v bibtex)"
fi

# --- Collect ALL tex content recursively (strips comments) ---
_collect_all_tex() {
  local repo_dir="$1" main_tex="$2"
  local tex_dir
  tex_dir=$(dirname "$main_tex")

  # Write Python helper to temp file to avoid bash escaping issues
  local py_helper
  py_helper=$(mktemp /tmp/paperctl_collect.XXXXXX.py)
  cat > "$py_helper" << 'PYEOF'
import os, sys

repo_dir = sys.argv[1]
main_tex = sys.argv[2]
tex_dir = os.path.dirname(main_tex)

visited = set()

def resolve_file(path, base_dirs):
    for bdir in base_dirs:
        for ext in ['', '.tex']:
            candidate = os.path.join(bdir, path + ext)
            if os.path.isfile(candidate):
                return candidate
    return None

def find_inputs(text):
    """Find all \\input{...} in text using string operations."""
    results = []
    marker = '\\input{'
    start = 0
    while True:
        idx = text.find(marker, start)
        if idx == -1:
            break
        brace_start = idx + len(marker)
        brace_end = text.find('}', brace_start)
        if brace_end == -1:
            break
        inp = text[brace_start:brace_end]
        results.append((idx, brace_end + 1, inp))
        start = brace_end + 1
    return results

def collect(filepath, base_dirs):
    filepath = os.path.realpath(filepath)
    if filepath in visited:
        return ''
    visited.add(filepath)
    if not os.path.isfile(filepath):
        return ''
    with open(filepath) as f:
        content = f.read()
    # Strip comment-only lines (but keep lines with code before %)
    lines = []
    for line in content.split('\n'):
        stripped = line.lstrip()
        if stripped.startswith('%'):
            continue
        # Remove trailing comment (naive: not inside verbatim)
        idx = -1
        for i, ch in enumerate(line):
            if ch == '%' and (i == 0 or line[i-1] != '\\'):
                idx = i
                break
        if idx > 0:
            lines.append(line[:idx])
        else:
            lines.append(line)
    clean = '\n'.join(lines)
    # Recursively resolve \input{...}
    for full_start, full_end, inp in reversed(find_inputs(clean)):
        resolved = resolve_file(inp, base_dirs)
        if resolved:
            sub_content = collect(resolved, base_dirs)
            clean = clean[:full_start] + sub_content + clean[full_end:]
    return clean

base_dirs = list(set([tex_dir, repo_dir]))
result = collect(main_tex, base_dirs)
print(result)
PYEOF
  python3 "$py_helper" "$repo_dir" "$main_tex"
  rm -f "$py_helper"
}

# --- Count non-empty lines in a variable (safe for set -e / pipefail) ---
_count_lines() {
  local text="${1:-}"
  if [[ -z "$text" ]]; then
    echo 0
    return
  fi
  local n=0
  while IFS= read -r line; do
    [[ -n "$line" ]] && n=$((n + 1))
  done <<< "$text"
  echo "$n"
}

# --- Extract bib keys from .bib file ---
_get_bib_keys() {
  local bib_file="$1"
  grep -oE '@[a-zA-Z]+\{[^,]+,' "$bib_file" 2>/dev/null \
    | sed 's/@[a-zA-Z]*{//;s/,$//' \
    | sort -u
}

# --- Main validation per paper ---
_validate_paper() {
  # Disable set -e inside this function; we handle errors via check_fail
  set +e
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $name ($repo)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  reset_repo_counts

  local main_tex
  main_tex=$(find_main_tex "$repo_dir")
  if [[ -z "$main_tex" ]]; then
    check_warn "No main .tex file found, skipping"
    flush_repo_counts
    echo ""
    return
  fi

  local tex_dir
  tex_dir=$(dirname "$main_tex")

  # Collect all tex content (comments stripped, inputs resolved)
  local all_tex
  all_tex=$(_collect_all_tex "$repo_dir" "$main_tex")

  # ============================================================
  # CHECK 1: Cross-references
  # ============================================================
  local labels refs
  labels=$(echo "$all_tex" | grep -oE '\\label\{[^}]+\}' | sed 's/\\label{//;s/}//' | sort -u || true)
  refs=$(echo "$all_tex" | { grep -oE '\\(c?ref|Cref|autoref|eqref|nameref)\{[^}]+\}' || true; } \
    | sed 's/\\[a-zA-Z]*{//;s/}//' \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | sort -u)

  local undef_refs=()
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    if ! echo "$labels" | grep -qxF "$ref"; then
      undef_refs+=("$ref")
    fi
  done <<< "$refs"

  if [[ ${#undef_refs[@]} -gt 0 ]]; then
    check_fail "Undefined references (${#undef_refs[@]}):"
    for r in "${undef_refs[@]}"; do
      echo "         $r"
    done
  else
    local ref_count
    ref_count=$(_count_lines "$refs")
    check_pass "Cross-references: $ref_count resolved"
  fi

  # ============================================================
  # CHECK 2: Citations
  # ============================================================
  local bib_file=""
  # Find bib file referenced in main.tex
  local bib_name
  bib_name=$(echo "$all_tex" | { grep -oE '\\bibliography\{[^}]+\}' || true; } | sed 's/\\bibliography{//;s/}//' | head -1)
  if [[ -n "$bib_name" ]]; then
    for ext in "" ".bib"; do
      for bdir in "$tex_dir" "$repo_dir"; do
        if [[ -f "$bdir/$bib_name$ext" ]]; then
          bib_file="$bdir/$bib_name$ext"
          break 2
        fi
      done
    done
  fi
  # Fallback: find any .bib
  if [[ -z "$bib_file" ]]; then
    bib_file=$(find "$repo_dir" -maxdepth 2 -name "*.bib" -not -path "*/.git/*" 2>/dev/null | head -1)
  fi

  if [[ -n "$bib_file" ]]; then
    local bib_keys cites
    bib_keys=$(_get_bib_keys "$bib_file")
    cites=$(echo "$all_tex" \
      | { grep -oE '\\(cite[tp]?|citep|citet|citealp|citeauthor|citeyear)\{[^}]+\}' || true; } \
      | sed 's/\\[a-zA-Z]*{//;s/}//' \
      | tr ',' '\n' \
      | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
      | sort -u)

    local undef_cites=()
    while IFS= read -r cite; do
      [[ -z "$cite" ]] && continue
      if ! echo "$bib_keys" | grep -qxF "$cite"; then
        undef_cites+=("$cite")
      fi
    done <<< "$cites"

    if [[ ${#undef_cites[@]} -gt 0 ]]; then
      check_fail "Undefined citations (${#undef_cites[@]}):"
      for c in "${undef_cites[@]}"; do
        echo "         $c"
      done
    else
      local cite_count
      cite_count=$(_count_lines "$cites")
      local bib_count
      bib_count=$(_count_lines "$bib_keys")
      check_pass "Citations: $cite_count used / $bib_count in $(basename "$bib_file")"
    fi
  else
    check_warn "No .bib file found"
  fi

  # ============================================================
  # CHECK 3: Missing \input files
  # ============================================================
  # Re-read raw main tex (without recursive expansion) to check file existence
  local raw_inputs
  raw_inputs=$(cat "$main_tex" 2>/dev/null | grep -oE '\\input\{[^}]+\}' | sed 's/\\input{//;s/}//' || true)

  local missing_inputs=()
  while IFS= read -r inp; do
    [[ -z "$inp" ]] && continue
    local found=false
    for ext in "" ".tex"; do
      for bdir in "$tex_dir" "$repo_dir"; do
        if [[ -f "$bdir/$inp$ext" ]]; then
          found=true
          break 2
        fi
      done
    done
    if ! $found; then
      missing_inputs+=("$inp")
    fi
  done <<< "$raw_inputs"

  if [[ ${#missing_inputs[@]} -gt 0 ]]; then
    check_fail "Missing \\input files (${#missing_inputs[@]}):"
    for m in "${missing_inputs[@]}"; do
      echo "         $m"
    done
  else
    local inp_count
    inp_count=$(_count_lines "$raw_inputs")
    check_pass "Input files: $inp_count found"
  fi

  # ============================================================
  # CHECK 4: Missing figures
  # ============================================================
  local fig_refs
  fig_refs=$(echo "$all_tex" | grep -oE '\\includegraphics(\[[^]]*\])?\{[^}]+\}' | sed 's/.*{//;s/}//' || true)

  local missing_figs=()
  while IFS= read -r fig; do
    [[ -z "$fig" ]] && continue
    local found=false
    for ext in "" ".pdf" ".png" ".jpg" ".jpeg" ".eps" ".svg"; do
      for bdir in "$tex_dir" "$repo_dir"; do
        if [[ -f "$bdir/$fig$ext" ]]; then
          found=true
          break 2
        fi
      done
    done
    if ! $found; then
      missing_figs+=("$fig")
    fi
  done <<< "$fig_refs"

  if [[ ${#missing_figs[@]} -gt 0 ]]; then
    check_fail "Missing figures (${#missing_figs[@]}):"
    for f in "${missing_figs[@]}"; do
      echo "         $f"
    done
  else
    local fig_count
    fig_count=$(_count_lines "$fig_refs")
    check_pass "Figures: $fig_count found"
  fi

  # ============================================================
  # CHECK 5: Missing table \input files (from resolved content)
  # ============================================================
  local table_inputs
  table_inputs=$(echo "$all_tex" | grep -oE '\\input\{tables?/[^}]+\}' | sed 's/\\input{//;s/}//' || true)

  local missing_tables=()
  while IFS= read -r tbl; do
    [[ -z "$tbl" ]] && continue
    local found=false
    for ext in "" ".tex"; do
      for bdir in "$tex_dir" "$repo_dir"; do
        if [[ -f "$bdir/$tbl$ext" ]]; then
          found=true
          break 2
        fi
      done
    done
    if ! $found; then
      missing_tables+=("$tbl")
    fi
  done <<< "$table_inputs"

  if [[ ${#missing_tables[@]} -gt 0 ]]; then
    check_fail "Missing table inputs (${#missing_tables[@]}):"
    for t in "${missing_tables[@]}"; do
      echo "         $t"
    done
  elif [[ -n "$table_inputs" ]]; then
    local tbl_count
    tbl_count=$(echo "$table_inputs" | wc -l | tr -d ' ')
    check_pass "Table inputs: $tbl_count found"
  fi

  # ============================================================
  # CHECK 6: BibTeX health (duplicates + orphans)
  # ============================================================
  if [[ -n "$bib_file" ]]; then
    # Duplicate bib keys
    local dup_keys
    dup_keys=$(grep -oE '@[a-zA-Z]+\{[^,]+,' "$bib_file" 2>/dev/null \
      | sed 's/@[a-zA-Z]*{//;s/,$//' \
      | sort | uniq -d)
    if [[ -n "$dup_keys" ]]; then
      local dup_count
      dup_count=$(_count_lines "$dup_keys")
      check_warn "Duplicate bib keys ($dup_count):"
      echo "$dup_keys" | while IFS= read -r k; do
        echo "         $k"
      done
    fi

    # Orphaned bib entries (defined but never cited)
    if [[ -n "${cites:-}" ]]; then
      local orphans=()
      while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        if ! echo "$cites" | grep -qxF "$key"; then
          orphans+=("$key")
        fi
      done <<< "$bib_keys"
      local orphan_count=${#orphans[@]}
      if [[ $orphan_count -gt 0 && $orphan_count -le 10 ]]; then
        check_info "Unused bib entries ($orphan_count): $(IFS=, ; echo "${orphans[*]}" | head -c 80)"
      elif [[ $orphan_count -gt 10 ]]; then
        check_info "Unused bib entries: $orphan_count (run with --paper to see list)"
      fi
    fi
  fi

  # ============================================================
  # CHECK 7: Figure/table label completeness
  # ============================================================
  # Labels defined but never referenced
  local fig_labels tab_labels
  fig_labels=$(echo "$labels" | grep '^fig:' || true)
  tab_labels=$(echo "$labels" | grep '^tab:' || true)

  if [[ -n "$fig_labels" ]]; then
    local unreffed_figs=()
    while IFS= read -r fl; do
      [[ -z "$fl" ]] && continue
      if ! echo "$refs" | grep -qxF "$fl"; then
        unreffed_figs+=("$fl")
      fi
    done <<< "$fig_labels"
    if [[ ${#unreffed_figs[@]} -gt 0 ]]; then
      check_warn "Unreferenced figures (${#unreffed_figs[@]}):"
      for u in "${unreffed_figs[@]}"; do
        echo "         $u"
      done
    fi
  fi

  if [[ -n "$tab_labels" ]]; then
    local unreffed_tabs=()
    while IFS= read -r tl; do
      [[ -z "$tl" ]] && continue
      if ! echo "$refs" | grep -qxF "$tl"; then
        unreffed_tabs+=("$tl")
      fi
    done <<< "$tab_labels"
    if [[ ${#unreffed_tabs[@]} -gt 0 ]]; then
      check_warn "Unreferenced tables (${#unreffed_tabs[@]}):"
      for u in "${unreffed_tabs[@]}"; do
        echo "         $u"
      done
    fi
  fi

  # ============================================================
  # CHECK 8: Local compilation (--compile flag)
  # ============================================================
  local pdf_file=""

  if $DO_COMPILE; then
    if [[ -n "$PDFLATEX" ]]; then
      echo ""
      check_info "Compiling locally..."
      local main_base main_rel
      main_base=$(basename "$main_tex" .tex)
      main_rel="${main_tex#$repo_dir/}"  # e.g. "ECCV_submission/main.tex" or "main.tex"

      # Compile from repo root (matches Overleaf project root) with output in tex_dir
      local compile_log
      compile_log=$(mktemp)

      # Pass 1: pdflatex
      (cd "$repo_dir" && "$PDFLATEX" -interaction=nonstopmode -halt-on-error -output-directory="$tex_dir" "$main_rel" > "$compile_log" 2>&1) || true

      # bibtex (if .bib exists) — runs from tex_dir where .aux lives
      if [[ -n "$bib_file" && -n "$BIBTEX" ]]; then
        (cd "$tex_dir" && "$BIBTEX" "$main_base" >> "$compile_log" 2>&1) || true
      fi

      # Pass 2 & 3: pdflatex
      (cd "$repo_dir" && "$PDFLATEX" -interaction=nonstopmode -output-directory="$tex_dir" "$main_rel" >> "$compile_log" 2>&1) || true
      (cd "$repo_dir" && "$PDFLATEX" -interaction=nonstopmode -output-directory="$tex_dir" "$main_rel" >> "$compile_log" 2>&1) || true

      # Check compilation result
      if [[ -f "$tex_dir/$main_base.pdf" ]]; then
        pdf_file="$tex_dir/$main_base.pdf"
        check_pass "Compilation succeeded"

        # Count LaTeX warnings
        local warn_count
        warn_count=$(grep -c "^LaTeX Warning:" "$compile_log" 2>/dev/null || true)
        [[ -z "$warn_count" ]] && warn_count=0
        local overfull_count
        overfull_count=$(grep -c "^Overfull" "$compile_log" 2>/dev/null || true)
        [[ -z "$overfull_count" ]] && overfull_count=0

        if [[ "$warn_count" -gt 0 ]]; then
          check_warn "LaTeX warnings: $warn_count"
          # Show first few
          grep "^LaTeX Warning:" "$compile_log" | head -5 | while IFS= read -r w; do
            echo "         $(echo "$w" | head -c 80)"
          done
        fi
        if [[ "$overfull_count" -gt 0 ]]; then
          check_warn "Overfull boxes: $overfull_count"
        fi

        # Check for undefined references in log
        local undef_in_log
        undef_in_log=$(grep -c "undefined references\|multiply-defined" "$compile_log" 2>/dev/null || true)
        [[ -z "$undef_in_log" ]] && undef_in_log=0
        if [[ "$undef_in_log" -gt 0 ]]; then
          check_warn "Undefined/multiply-defined references detected in log"
        fi
      else
        check_fail "Compilation failed!"
        # Show last error
        local last_error
        last_error=$(grep -A2 "^!" "$compile_log" | head -6)
        if [[ -n "$last_error" ]]; then
          echo "$last_error" | while IFS= read -r line; do
            echo "         $line"
          done
        fi
      fi

      rm -f "$compile_log"

      # Clean auxiliary files (keep PDF)
      (cd "$tex_dir" && rm -f "$main_base.aux" "$main_base.bbl" "$main_base.blg" \
        "$main_base.log" "$main_base.out" "$main_base.toc" "$main_base.nav" \
        "$main_base.snm" "$main_base.vrb" "$main_base.fls" "$main_base.fdb_latexmk" \
        "$main_base.synctex.gz" 2>/dev/null) || true
    else
      check_warn "pdflatex not found. Install BasicTeX: brew install --cask basictex"
    fi
  fi

  # ============================================================
  # CHECK 7: Page count (from compiled PDF or existing PDF)
  # ============================================================
  if [[ -z "$pdf_file" ]]; then
    for candidate in \
      "$tex_dir/main.pdf" \
      "$repo_dir/main.pdf" \
      "$tex_dir/output.pdf" \
      "$repo_dir/output/main.pdf"; do
      if [[ -f "$candidate" ]]; then
        pdf_file="$candidate"
        break
      fi
    done
  fi

  if [[ -n "$pdf_file" ]]; then
    local pages=""
    if command -v pdfinfo &>/dev/null; then
      pages=$(pdfinfo "$pdf_file" 2>/dev/null | grep "^Pages:" | awk '{print $2}')
    elif command -v python3 &>/dev/null; then
      pages=$(python3 -c "
import fitz
doc = fitz.open('$pdf_file')
print(len(doc))
doc.close()
" 2>/dev/null)
    fi

    if [[ -n "$pages" ]]; then
      if [[ "$pages" -le 14 ]]; then
        check_pass "Pages: $pages / 14 ($(( 14 - pages )) remaining)"
      else
        check_fail "Pages: $pages / 14 (OVER by $(( pages - 14 ))!)"
      fi
    fi

    # Clean up compiled PDF if we created it (don't leave in repo)
    if $DO_COMPILE && [[ -f "$pdf_file" ]]; then
      rm -f "$pdf_file"
    fi
  else
    if ! $DO_COMPILE; then
      check_info "No compiled PDF (use --compile or compile on Overleaf)"
    fi
  fi

  flush_repo_counts
  echo ""
  set -e
}

print_check_banner "LaTeX Static Validation"

for_each_paper _validate_paper

print_check_summary
