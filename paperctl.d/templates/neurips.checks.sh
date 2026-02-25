#!/bin/bash
# paperctl.d/templates/neurips.checks.sh -- NeurIPS format compliance checks
#
# NeurIPS Key Requirements:
# - Style: neurips_20XX.sty (year-specific)
# - Document class: \documentclass{article}
# - Page limit: 9 pages (excluding references & appendix)
# - Anonymity: Must be anonymous for review
# - No page numbers in review mode
# - Font: Times (via \usepackage{times})
# - Appendix: Allowed (after references)

run_checks() {
  local repo_dir="$1" main_tex="$2" all_tex="$3"

  # === CHECK 1: Document class ===
  if echo "$all_tex" | grep -q '\\documentclass.*{article}'; then
    check_pass "Document class: article"
  else
    local docclass
    docclass=$(echo "$all_tex" | grep '\\documentclass' | head -1)
    check_fail "Wrong document class! Found: $docclass"
    echo "         Expected: \\documentclass{article}"
  fi

  # === CHECK 2: NeurIPS style file ===
  if echo "$all_tex" | grep -q '\\usepackage.*{neurips'; then
    check_pass "NeurIPS style package loaded"
  elif [[ -n $(find "$repo_dir" -maxdepth 1 -name "neurips*.sty" 2>/dev/null) ]]; then
    check_warn "neurips .sty file present but not loaded in main tex"
  else
    check_fail "NeurIPS style file not found"
  fi

  # === CHECK 3: Anonymity ===
  if echo "$all_tex" | grep -q '\\author{.*Anonymous\|\\author{Anonymous'; then
    check_pass "Anonymous author"
  elif echo "$all_tex" | grep -q '\\author{'; then
    local author_line
    author_line=$(echo "$all_tex" | grep '\\author{' | head -1 | sed 's/^[ \t]*//')
    check_warn "Author not anonymous! Found: $author_line"
  else
    check_warn "No \\author{} found"
  fi

  # === CHECK 4: Times font ===
  if echo "$all_tex" | grep -q '\\usepackage{times}\|\\usepackage.*{mathptmx}'; then
    check_pass "Times font loaded"
  else
    check_warn "Times font package not found (typically required)"
  fi

  # === CHECK 5: Bibliography ===
  local bib_files
  bib_files=$(find "$repo_dir" -maxdepth 2 -name "*.bib" 2>/dev/null)
  if [[ -n "$bib_files" ]]; then
    check_pass "Bibliography file(s) found"
  else
    check_warn "No .bib file found"
  fi

  # === CHECK 6: Wrong template detection (ECCV/CVPR) ===
  if echo "$all_tex" | grep -q '\\usepackage.*{eccv}\|\\usepackage.*{cvpr}\|\\usepackage.*{iccv}'; then
    check_fail "ECCV/CVPR/ICCV template detected! Must use NeurIPS template."
  else
    check_pass "No ECCV/CVPR/ICCV template conflict"
  fi

  # === CHECK 7: hyperref ===
  if echo "$all_tex" | grep -q '\\usepackage.*{hyperref}'; then
    check_pass "hyperref loaded"
  else
    check_warn "hyperref not found (recommended)"
  fi

  # === CHECK 8: natbib ===
  if echo "$all_tex" | grep -q '\\usepackage.*{natbib}'; then
    check_pass "natbib loaded (NeurIPS standard)"
  else
    check_warn "natbib not found (NeurIPS typically uses natbib)"
  fi
}
