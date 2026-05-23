#!/bin/bash
# paperctl.d/templates/corl.checks.sh -- CoRL format compliance checks
#
# CoRL Key Requirements:
# - Style: corl_20XX.sty (year-specific)
# - Document class: \documentclass{article}
# - Page limit: 8 pages submission, 9 pages camera-ready (excl. refs & appendix)
# - Anonymity: Double-blind for review
# - Limitations section required (counts toward page limit)
# - Robotics focus required (no robotics = desk reject)
# - Supplementary: zip via OpenReview, video ≤ 250MB

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

  # === CHECK 2: CoRL style file ===
  if echo "$all_tex" | grep -q '\\usepackage.*{corl'; then
    check_pass "CoRL style package loaded"
  elif [[ -n $(find "$repo_dir" -maxdepth 1 -name "corl*.sty" 2>/dev/null) ]]; then
    check_warn "CoRL .sty file present but not loaded in main tex"
  else
    check_fail "CoRL style file not found"
  fi

  # === CHECK 3: Anonymity (no [final] option) ===
  if echo "$all_tex" | grep -q '\\usepackage\[final\].*{corl'; then
    check_fail "Camera-ready mode [final] detected! Must be anonymous for submission."
  else
    check_pass "Not in camera-ready mode"
  fi

  # === CHECK 4: Limitations section ===
  if echo "$all_tex" | grep -qi '\\section.*limitation'; then
    check_pass "Limitations section found"
  else
    check_fail "Limitations section REQUIRED (counts toward 8-page limit)"
  fi

  # === CHECK 5: Bibliography ===
  local bib_files
  bib_files=$(find "$repo_dir" -maxdepth 2 -name "*.bib" 2>/dev/null)
  if [[ -n "$bib_files" ]]; then
    check_pass "Bibliography file(s) found"
  else
    check_warn "No .bib file found"
  fi

  # === CHECK 6: Wrong template detection ===
  if echo "$all_tex" | grep -q '\\usepackage.*{neurips\|\\usepackage.*{eccv}\|\\usepackage.*{cvpr}'; then
    check_fail "Wrong template detected! Must use CoRL template."
  else
    check_pass "No template conflict"
  fi

  # === CHECK 7: hyperref ===
  if echo "$all_tex" | grep -q '\\usepackage.*{hyperref}'; then
    check_pass "hyperref loaded"
  else
    check_warn "hyperref not found (recommended)"
  fi

  # === CHECK 8: natbib ===
  if echo "$all_tex" | grep -q '\\usepackage.*{natbib}'; then
    check_pass "natbib loaded"
  else
    check_warn "natbib not found (typically required)"
  fi
}
