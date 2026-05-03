#!/bin/bash
# paperctl.d/cmd_lint.sh -- Writing-style lint (BAN rules)
#
# Checks for violations of project-wide writing conventions.
# Scans only \cyl{} regions (professor-written text) by default.
# Use --all to scan entire tex content.
#
# BAN rules enforced:
#   1. No em dashes (---, —, –) anywhere
#   2. No adverb+comma sentence openers (Specifically is allowed)
#      (Notably, Importantly, Crucially, Interestingly,
#       Essentially, Fundamentally, Consequently, Additionally, Furthermore,
#       Remarkably, Significantly, Particularly, Ultimately, Accordingly)
#   3. Banned single words: thereby, utilize, straightforward, numerous
#   4. Banned GPT-isms (sentence-initial or mid):
#      "It is worth noting that", "As expected,", "As can be seen from",
#      "demonstrates the effectiveness of", "has gained significant attention",
#      "Recently, many works"
#   5. Bare \ref{} for Figure/Table/Eq./Section (must be \cref or \Cref)
#   6. Float placement [h], [b], [H] (must be [t])
#   7. Straight quotes "..." in prose (must be ``...'')
#
# Usage:
#   paperctl lint [--paper <name>]       # lint \cyl{} regions only
#   paperctl lint [--paper <name>] --all # lint all tex content

load_config
. "$PAPERCTL_LIB/lib_check.sh"

SCAN_ALL=false
INTRO_ONLY=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --all) SCAN_ALL=true; shift ;;
    --intro) INTRO_ONLY=true; SCAN_ALL=true; shift ;;
    *) break ;;
  esac
done

# ============================================================
# BAN RULES DEFINITION
# ============================================================
# Each rule: pattern (extended regex), description, severity (fail/warn)
# Patterns are applied line-by-line.

declare -a RULE_PATTERNS=()
declare -a RULE_DESCS=()
declare -a RULE_SEVERITY=()

# --- RULE 1: Em dashes ---
RULE_PATTERNS+=('---|—|–')
RULE_DESCS+=("Em dash (--- or — or –)")
RULE_SEVERITY+=("fail")

# --- RULE 2: Adverb+comma sentence openers ---
# Match at start of line (after optional whitespace) or after { (inside \cyl{})
RULE_PATTERNS+=('(^|[{])\s*(Notably|Importantly|Crucially|Interestingly|Essentially|Fundamentally|Consequently|Additionally|Furthermore|Remarkably|Significantly|Particularly|Ultimately|Accordingly|Obviously|Clearly|Undoubtedly|Naturally|Admittedly),')
RULE_DESCS+=("Adverb+comma sentence opener (except Specifically)")
RULE_SEVERITY+=("fail")

# --- RULE 3: Banned single words ---
RULE_PATTERNS+=('\b(thereby|utilize|utilizes|utilized|utilizing|straightforward|numerous)\b')
RULE_DESCS+=("Banned word (thereby/utilize/straightforward/numerous)")
RULE_SEVERITY+=("fail")

# --- RULE 4: Banned GPT-isms / phrases ---
RULE_PATTERNS+=('(It is worth noting that|As expected,|As can be seen from|demonstrates the effectiveness of|has gained significant attention|Recently, many works)')
RULE_DESCS+=("GPT-ism phrase")
RULE_SEVERITY+=("fail")

# --- RULE 5: Bare \ref{} for Figure/Table/Eq./Section ---
# Must be \cref{} or \Cref{} -- catches "Figure~\ref{...}", "Table \ref{...}", etc.
RULE_PATTERNS+=('(Figure|Table|Eq\.|Equation|Section|Sec\.|Fig\.)[~ ]*\\ref\{')
RULE_DESCS+=("Bare \\\\ref{} -- use \\\\cref{} or \\\\Cref{}")
RULE_SEVERITY+=("fail")

# --- RULE 6: Float placement [h]/[b]/[H] (must be [t]) ---
RULE_PATTERNS+=('\\begin\{(figure|table|figure\*|table\*)\}\[(h|b|H|ht|hb|tb|bt|hbt|tbh|htbp)\]')
RULE_DESCS+=("Float placement -- use [t] only")
RULE_SEVERITY+=("warn")

# --- RULE 7: Straight quotes in prose (heuristic) ---
# Matches "word..." or "...word" patterns that look like prose quotes
# Skips lines that look like code/url/path/comment
RULE_PATTERNS+=('(^|[^\\=>:_/])"[A-Za-z]')
RULE_DESCS+=("Straight quote -- use \\\`\\\`...'' instead")

# --- INTRO-ONLY rules (added when --intro flag is set) ---
# These are stricter rules per intro_guideline_v4.md, applied only to introduction.tex
if $INTRO_ONLY; then
  # R8: casual conjunctions banned by intro guideline
  RULE_PATTERNS+=('(, yet [a-z]|, but [a-z]|, so [a-z]|; however,|; [a-z])')
  RULE_DESCS+=("Casual conjunction (yet/but/so/; <lower>) -- use however/while/although/period")
  RULE_SEVERITY+=("fail")

  # R9: comma + V-ing (banned across guideline)
  # Whitelist participial prepositions (including/regarding/concerning/etc.)
  # which legitimately introduce parenthetical phrases, not the banned construction.
  RULE_PATTERNS+=(', (?!including|regarding|concerning|involving|containing|given|considering|excluding|notwithstanding|owing|using)[a-z]+ing\b')
  RULE_DESCS+=("Comma + V-ing -- split into two clauses or use 'and V-s'")
  RULE_SEVERITY+=("fail")

  # R10: 'because' (any position) -- use since/as/given that
  RULE_PATTERNS+=('\b[Bb]ecause\b')
  RULE_DESCS+=("'because' -- use 'since'/'as'/'given that'")
  RULE_SEVERITY+=("fail")

  # R11: display math \[ ... \] in body (formulas belong to Method/Theory, not Intro)
  RULE_PATTERNS+=('\\\[')
  RULE_DESCS+=("Display math \\\\[...\\\\] -- formulas belong to Method/Theory, not Intro body")
  RULE_SEVERITY+=("fail")

  # R12: figure refs in body (Intro should not depend on figures that may move)
  RULE_PATTERNS+=('\\(c|C)ref\{fig:')
  RULE_DESCS+=("Figure ref in Intro -- consider moving figure or describing without ref")
  RULE_SEVERITY+=("warn")

  # R13: undefined notation in Intro (\Delta, \tau, \epsilon, \delta, c4/c8/c2)
  # These commonly leak from Method/abstract into Intro and confuse readers
  RULE_PATTERNS+=('\$\\(Delta|tau|epsilon|delta)\$|\b(c4|c8|c2)\b')
  RULE_DESCS+=("Undefined notation in Intro (\\\\Delta/\\\\tau/\\\\epsilon/\\\\delta/c4/c8/c2)")
  RULE_SEVERITY+=("warn")

  # R14: 'In this paper, we' -- intro should not have this template phrase
  RULE_PATTERNS+=('In this paper, we|In this work, we propose')
  RULE_DESCS+=("Template phrase 'In this paper, we' -- restructure")
  RULE_SEVERITY+=("warn")

  # R15: bullet points outside contributions (intro should be paragraphs)
  RULE_PATTERNS+=('^\s*\\item\b')
  RULE_DESCS+=("\\\\item bullet -- only allowed in contributions block")
  RULE_SEVERITY+=("warn")
fi
RULE_SEVERITY+=("warn")

# ============================================================

_extract_cyl_regions() {
  local file="$1"
  python3 -c "
import sys

with open(sys.argv[1], 'r') as f:
    text = f.read()

# Extract content inside \cyl{...} with line numbers
lines = text.split('\n')
in_cyl = False
depth = 0
cyl_lines = []

for lineno, line in enumerate(lines, 1):
    i = 0
    while i < len(line):
        if not in_cyl:
            if line[i:i+5] == '\\\\cyl{':
                in_cyl = True
                depth = 1
                i += 5
                start_col = i
                continue
        else:
            if line[i] == '{' and (i == 0 or line[i-1] != '\\\\'):
                depth += 1
            elif line[i] == '}' and (i == 0 or line[i-1] != '\\\\'):
                depth -= 1
                if depth == 0:
                    in_cyl = False
                    i += 1
                    continue
        i += 1
    if in_cyl or line.find('\\\\cyl{') >= 0:
        cyl_lines.append((lineno, line))
    # Also include lines that are fully inside an open \cyl block
    elif in_cyl:
        cyl_lines.append((lineno, line))

for lineno, line in cyl_lines:
    print(f'{lineno}:{line}')
" "$file"
}

_lint_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $name ($repo)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local main_tex
  main_tex=$(find_main_tex "$repo_dir")
  if [[ -z "$main_tex" ]]; then
    echo "  No main .tex found, skipping."
    echo ""
    return
  fi

  local tex_dir
  tex_dir=$(dirname "$main_tex")

  local total_violations=0

  # Find all .tex files (or just introduction.tex if --intro mode)
  local tex_files=()
  if $INTRO_ONLY; then
    # Look for introduction.tex specifically (per ECCV-style sections/ layout)
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      tex_files+=("$f")
    done < <(find "$tex_dir" -iname "introduction.tex" -not -path "*/_clean/*" -not -path "*/.git/*" 2>/dev/null | sort)
    if [[ ${#tex_files[@]} -eq 0 ]]; then
      echo "  No introduction.tex found in $repo_dir (--intro requires sections/introduction.tex)"
      echo ""
      return
    fi
  else
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      tex_files+=("$f")
    done < <(find "$tex_dir" -name "*.tex" -not -path "*/_clean/*" -not -path "*/.git/*" 2>/dev/null | sort)
  fi

  for tex_file in "${tex_files[@]}"; do
    local rel_path="${tex_file#$repo_dir/}"
    local file_violations=0

    # Get content to lint
    local content
    if $SCAN_ALL; then
      # Scan all non-comment lines (filter must be applied AFTER line-numbering;
      # grep -n produces "N:content" so comment regex needs N: prefix)
      content=$(grep -n '' "$tex_file" | grep -v '^[0-9]*:[[:space:]]*%')
    else
      # Scan only \cyl{} regions
      content=$(_extract_cyl_regions "$tex_file")
      [[ -z "$content" ]] && continue
    fi

    local file_header_printed=false

    # Apply each rule
    local rule_idx=0
    while [[ $rule_idx -lt ${#RULE_PATTERNS[@]} ]]; do
      local pattern="${RULE_PATTERNS[$rule_idx]}"
      local desc="${RULE_DESCS[$rule_idx]}"
      local severity="${RULE_SEVERITY[$rule_idx]}"

      local matches
      matches=$(echo "$content" | grep -nE "$pattern" 2>/dev/null || true)

      if [[ -n "$matches" ]]; then
        if ! $file_header_printed; then
          echo ""
          echo "  $rel_path:"
          file_header_printed=true
        fi

        while IFS= read -r match_line; do
          [[ -z "$match_line" ]] && continue
          file_violations=$((file_violations + 1))
          local icon="❌"
          [[ "$severity" == "warn" ]] && icon="⚠️ "
          # Extract line number (format: outer_grep_n:file_lineno:content)
          # grep -n '' added file_lineno first, then grep -nE wraps with outer index;
          # the actual file line is the SECOND field, content is third+.
          local lineno
          lineno=$(echo "$match_line" | cut -d: -f2)
          local text
          text=$(echo "$match_line" | cut -d: -f3- | sed 's/^[[:space:]]*//' | head -c 80)
          echo "    $icon L$lineno [$desc]: $text"
        done <<< "$matches"
      fi

      rule_idx=$((rule_idx + 1))
    done

    total_violations=$((total_violations + file_violations))
  done

  echo ""
  if [[ $total_violations -gt 0 ]]; then
    echo "  $total_violations violation(s) found"
  else
    echo "  All clean"
  fi
  echo ""
}

echo ""
echo "=========================================="
if $SCAN_ALL; then
  echo "  Writing Style Lint (all content)"
else
  echo "  Writing Style Lint (\\cyl{} regions)"
fi
echo "=========================================="
echo ""

for_each_paper _lint_paper
