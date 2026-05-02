#!/bin/bash
# paperctl.d/cmd_supp_check.sh -- Validate supplementary material structure
#
# Enforces a single standard: supp.tex as a standalone document.
# Non-standard filenames are flagged as FAIL (use scaffold-supp to generate).
#
# Checks:
#   1. supp.tex exists (standard filename, no alternatives)
#   2. Standalone document (own \documentclass)
#   3. Float package loaded (for [H] specifier)
#   4. Notation table present with [H] placement
#   5. Standard section labels used
#   6. Main paper doesn't append supplementary
#   7. Bibliography present

load_config
. "$PAPERCTL_LIB/lib_check.sh"

# Standard section labels we expect in supp.tex
STANDARD_LABELS=(
  "sec:supp_notation"
  "sec:supp_impl"
  "sec:supp_experiments"
  "sec:supp_qualitative"
)

_check_supp() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  echo "── $name ──"
  reset_repo_counts

  # Find main.tex location
  local main_tex tex_dir
  main_tex=$(find_main_tex "$repo_dir")
  if [[ -z "$main_tex" ]]; then
    check_fail "No main.tex found"
    flush_repo_counts
    echo ""
    return
  fi
  tex_dir=$(dirname "$main_tex")

  # === CHECK 1: supp.tex exists (strict — only standard name) ===
  local supp_path="$tex_dir/supp.tex"
  if [[ ! -f "$supp_path" ]]; then
    check_fail "supp.tex not found — run: paperctl scaffold-supp --paper $name"
    flush_repo_counts
    echo ""
    return
  fi
  check_pass "supp.tex found"

  # Read supp content
  local supp_content
  supp_content=$(cat "$supp_path" 2>/dev/null)

  # === CHECK 2: Standalone document ===
  if echo "$supp_content" | grep -q '\\documentclass'; then
    check_pass "Standalone document (own \\documentclass)"
  else
    check_fail "Not a standalone document — must have its own \\documentclass"
  fi

  # === CHECK 3: Float package ===
  if echo "$supp_content" | grep -q '\\usepackage.*{float}'; then
    check_pass "float package loaded"
  else
    check_warn "float package not loaded (needed for [H] table placement)"
  fi

  # === CHECK 4: Notation table with [H] ===
  if echo "$supp_content" | grep -q 'tab:notation'; then
    if echo "$supp_content" | grep -q '\\begin{table\*\?\}\[H\]'; then
      check_pass "Notation table with [H] placement"
    elif echo "$supp_content" | grep -q '\\begin{table'; then
      check_warn "Notation table found but not using [H] placement"
    fi
  else
    check_warn "No notation table (\\label{tab:notation})"
  fi

  # === CHECK 5: Standard section labels ===
  local found_count=0
  local total=${#STANDARD_LABELS[@]}
  for label in "${STANDARD_LABELS[@]}"; do
    if echo "$supp_content" | grep -q "\\\\label{$label}"; then
      found_count=$((found_count + 1))
    fi
  done
  if [[ $found_count -eq $total ]]; then
    check_pass "All $total standard section labels present"
  elif [[ $found_count -gt 0 ]]; then
    check_info "$found_count/$total standard section labels found"
    for label in "${STANDARD_LABELS[@]}"; do
      if ! echo "$supp_content" | grep -q "\\\\label{$label}"; then
        echo "         Missing: \\label{$label}"
      fi
    done
  else
    check_warn "No standard section labels (use scaffold-supp template)"
  fi

  # === CHECK 6: Main paper doesn't append supp ===
  local main_content
  main_content=$(cat "$main_tex" 2>/dev/null)
  local has_appended_supp=false

  # Check for uncommented \input of supp-related files after \bibliography
  local after_bib=false
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*% ]] && continue
    if echo "$line" | grep -q '\\bibliography{'; then
      after_bib=true
    fi
    if [[ "$after_bib" == "true" ]]; then
      if echo "$line" | grep -q '\\input{.*suppl\|\\input{.*supplementary\|\\input{.*X_suppl'; then
        has_appended_supp=true
        break
      fi
    fi
  done < "$main_tex"

  # Check for \appendix followed by \input
  if echo "$main_content" | grep -v '^[[:space:]]*%' | grep -q '\\appendix'; then
    if echo "$main_content" | grep -v '^[[:space:]]*%' | grep -q '\\input.*supp\|\\input.*appendix'; then
      has_appended_supp=true
    fi
  fi

  if [[ "$has_appended_supp" == "true" ]]; then
    check_warn "Main paper appends supplementary — should be separate document"
  else
    check_pass "Main paper does not append supplementary"
  fi

  # === CHECK 7: Bibliography in supp ===
  if echo "$supp_content" | grep -q '\\bibliography{'; then
    check_pass "Bibliography present"
  elif echo "$supp_content" | grep -q '\\begin{thebibliography}'; then
    check_pass "Bibliography present (inline)"
  else
    check_warn "No bibliography in supp"
  fi

  flush_repo_counts
  echo ""
}

# --- Main ---
print_check_banner "Supplementary Material Check ($CONF_NAME $CONF_YEAR)"

for_each_paper _check_supp

print_check_summary
