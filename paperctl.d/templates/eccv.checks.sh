#!/bin/bash
# paperctl.d/templates/eccv.checks.sh -- ECCV format compliance checks
#
# ECCV Key Requirements:
# - Document class: \documentclass[runningheads]{llncs}
# - Style files: eccv.sty, llncs.cls, splncs04.bst
# - Page limit: 14 pages (excluding references)
# - Line numbering: MUST be enabled for review
# - Anonymity: "Anonymous ECCV submission", no author names/affiliations
# - Bibliography: \bibliographystyle{splncs04}
# - No appendix allowed (supplementary materials only)
# - Font: ECCV specific (NOT CVPR font — desk-reject if wrong!)

run_checks() {
  local repo_dir="$1" main_tex="$2" all_tex="$3"
  # tex_dir = directory where main.tex lives (may be subdir)
  local tex_dir
  tex_dir=$(dirname "$main_tex")

  # === CHECK 1: Document class ===
  if echo "$all_tex" | grep -q '\\documentclass\[runningheads\]{llncs}'; then
    check_pass "Document class: \\documentclass[runningheads]{llncs}"
  elif echo "$all_tex" | grep -q '\\documentclass.*{llncs}'; then
    check_warn "llncs class found but missing [runningheads] option"
  else
    local docclass
    docclass=$(echo "$all_tex" | grep '\\documentclass' | head -1)
    check_fail "Wrong document class! Found: $docclass"
    echo "         Expected: \\documentclass[runningheads]{llncs}"
  fi

  # === CHECK 2: eccv.sty ===
  if [[ -f "$tex_dir/eccv.sty" ]] || [[ -f "$repo_dir/eccv.sty" ]]; then
    check_pass "eccv.sty present"
  else
    check_fail "eccv.sty missing! Get from official ECCV template"
  fi

  # === CHECK 3: llncs.cls ===
  if [[ -f "$tex_dir/llncs.cls" ]] || [[ -f "$repo_dir/llncs.cls" ]]; then
    check_pass "llncs.cls present"
  else
    check_fail "llncs.cls missing! Get from official ECCV template"
  fi

  # === CHECK 4: splncs04.bst ===
  if [[ -f "$tex_dir/splncs04.bst" ]] || [[ -f "$repo_dir/splncs04.bst" ]]; then
    check_pass "splncs04.bst present"
  else
    check_fail "splncs04.bst missing! Get from official ECCV template"
  fi

  # === CHECK 5: \usepackage{eccv} ===
  if echo "$all_tex" | grep -q '\\usepackage.*{eccv}'; then
    check_pass "\\usepackage{eccv} found"
  else
    check_fail "\\usepackage{eccv} not found in main tex or preamble"
  fi

  # === CHECK 6: Review mode (line numbering) ===
  if echo "$all_tex" | grep -q '\\usepackage\[.*review.*\]{eccv}'; then
    check_pass "Review mode enabled (line numbers on)"
  elif echo "$all_tex" | grep -q '\\usepackage{eccv}'; then
    check_warn "eccv package loaded but NOT in review mode. Use \\usepackage[review]{eccv}"
  else
    check_warn "Cannot determine review mode status"
  fi

  # === CHECK 7: Anonymity ===
  if echo "$all_tex" | grep -qi '\\author{Anonymous'; then
    check_pass "Anonymous author"
  elif echo "$all_tex" | grep -q '\\author{'; then
    local author_line
    author_line=$(echo "$all_tex" | grep '\\author{' | head -1 | sed 's/^[ \t]*//')
    check_warn "Author not anonymous! Found: $author_line"
  else
    check_warn "No \\author{} found"
  fi

  # === CHECK 8: Bibliography style ===
  if echo "$all_tex" | grep -q '\\bibliographystyle{splncs04}'; then
    check_pass "Bibliography style: splncs04"
  else
    local bst
    bst=$(echo "$all_tex" | grep '\\bibliographystyle' | head -1 | sed 's/^[ \t]*//')
    if [[ -n "$bst" ]]; then
      check_fail "Wrong bibliography style! Found: $bst"
      echo "         Expected: \\bibliographystyle{splncs04}"
    else
      check_warn "No \\bibliographystyle found"
    fi
  fi

  # === CHECK 9: No appendix ===
  if echo "$all_tex" | grep -q '\\appendix\|\\begin{appendix}'; then
    check_fail "\\appendix found! ECCV does NOT allow appendices."
    echo "         Use supplementary materials instead."
  else
    check_pass "No appendix (correct)"
  fi

  # === CHECK 10: Wrong template detection (CVPR/ICCV) ===
  if echo "$all_tex" | grep -q '\\usepackage.*{cvpr}\|\\usepackage.*{iccv}'; then
    check_fail "CVPR/ICCV template detected! Must use ECCV template."
    echo "         This will cause DESK REJECTION (wrong font!)."
  else
    check_pass "No CVPR/ICCV template conflict"
  fi

  # === CHECK 11: Paper ID ===
  if echo "$all_tex" | grep -qE '\\usepackage\[.*ID=[0-9]+.*\]\{eccv\}'; then
    local paper_id
    paper_id=$(echo "$all_tex" | grep -oE 'ID=[0-9]+' | head -1)
    check_info "Paper $paper_id"
  elif echo "$all_tex" | grep -q 'ID=\*\*\*\*\*'; then
    check_warn "Paper ID is still placeholder (*****). Update before submission."
  else
    check_warn "No Paper ID found in \\usepackage options"
  fi

  # === CHECK 12: hyperref package ===
  if echo "$all_tex" | grep -q '\\usepackage.*{hyperref}'; then
    check_pass "hyperref loaded"
  else
    check_warn "hyperref not found (strongly recommended for review)"
  fi

  # === CHECK 13: .bib file exists ===
  local bib_files
  bib_files=$(find "$repo_dir" -maxdepth 2 -name "*.bib" 2>/dev/null)
  if [[ -n "$bib_files" ]]; then
    local bib_count
    bib_count=$(echo "$bib_files" | wc -l | tr -d ' ')
    check_pass "Bibliography file(s): $bib_count found"
  else
    check_warn "No .bib file found"
  fi
}
