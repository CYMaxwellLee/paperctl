#!/bin/bash
# paperctl.d/templates/cvpr.checks.sh -- CVPR/ICCV format compliance checks
#
# CVPR Key Requirements:
# - Style: cvpr.sty (year-specific typically)
# - Document class: \documentclass[10pt,twocolumn,letterpaper]{article}
# - Page limit: 8 pages (excluding references)
# - Anonymity: Must be anonymous for review
# - Line numbering for review
# - Font: Times (via \usepackage{times})
# - Bibliography: IEEE style
# - No appendix in main paper

run_checks() {
  local repo_dir="$1" main_tex="$2" all_tex="$3"

  # === CHECK 1: Document class ===
  if echo "$all_tex" | grep -q '\\documentclass.*{article}'; then
    check_pass "Document class: article"
  else
    local docclass
    docclass=$(echo "$all_tex" | grep '\\documentclass' | head -1)
    check_fail "Wrong document class! Found: $docclass"
    echo "         Expected: \\documentclass[...]{article}"
  fi

  # === CHECK 2: CVPR style file ===
  if echo "$all_tex" | grep -q '\\usepackage.*{cvpr}'; then
    check_pass "CVPR style package loaded"
  elif [[ -n $(find "$repo_dir" -maxdepth 1 -name "cvpr*.sty" 2>/dev/null) ]]; then
    check_warn "cvpr .sty file present but not loaded in main tex"
  else
    check_fail "CVPR style file not found"
  fi

  # === CHECK 3: Review mode ===
  if echo "$all_tex" | grep -q '\\usepackage\[review\]{cvpr}\|\\usepackage\[.*review.*\]{cvpr}'; then
    check_pass "Review mode enabled"
  elif echo "$all_tex" | grep -q '\\usepackage{cvpr}'; then
    check_warn "cvpr package loaded but NOT in review mode"
  else
    check_warn "Cannot determine review mode status"
  fi

  # === CHECK 4: Anonymity ===
  if echo "$all_tex" | grep -qi '\\author{.*Anonymous\|\\author{Anonymous'; then
    check_pass "Anonymous author"
  elif echo "$all_tex" | grep -q '\\author{'; then
    local author_line
    author_line=$(echo "$all_tex" | grep '\\author{' | head -1 | sed 's/^[ \t]*//')
    check_warn "Author not anonymous! Found: $author_line"
  else
    check_warn "No \\author{} found"
  fi

  # === CHECK 5: Times font ===
  if echo "$all_tex" | grep -q '\\usepackage{times}\|\\usepackage.*{mathptmx}'; then
    check_pass "Times font loaded"
  else
    check_warn "Times font package not found (typically required)"
  fi

  # === CHECK 6: Bibliography style ===
  if echo "$all_tex" | grep -q '\\bibliographystyle{ieee_fullname}\|\\bibliographystyle{ieee}'; then
    check_pass "IEEE bibliography style"
  else
    local bst
    bst=$(echo "$all_tex" | grep '\\bibliographystyle' | head -1 | sed 's/^[ \t]*//')
    if [[ -n "$bst" ]]; then
      check_warn "Non-standard bibliography style: $bst"
    else
      check_warn "No \\bibliographystyle found"
    fi
  fi

  # === CHECK 7: No appendix ===
  if echo "$all_tex" | grep -q '\\appendix\|\\begin{appendix}'; then
    check_warn "\\appendix found — ensure it's in supplementary only, not main paper"
  else
    check_pass "No appendix in main paper"
  fi

  # === CHECK 8: Wrong template detection (ECCV/NeurIPS) ===
  if echo "$all_tex" | grep -q '\\usepackage.*{eccv}\|\\usepackage.*{neurips}'; then
    check_fail "ECCV/NeurIPS template detected! Must use CVPR template."
    echo "         This will cause DESK REJECTION."
  else
    check_pass "No ECCV/NeurIPS template conflict"
  fi

  # === CHECK 9: .bib file exists ===
  local bib_files
  bib_files=$(find "$repo_dir" -maxdepth 2 -name "*.bib" 2>/dev/null)
  if [[ -n "$bib_files" ]]; then
    check_pass "Bibliography file(s) found"
  else
    check_warn "No .bib file found"
  fi

  # === CHECK 10: hyperref ===
  if echo "$all_tex" | grep -q '\\usepackage.*{hyperref}'; then
    check_pass "hyperref loaded"
  else
    check_warn "hyperref not found (recommended)"
  fi
}
