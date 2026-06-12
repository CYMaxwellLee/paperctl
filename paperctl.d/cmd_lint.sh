#!/bin/bash
# paperctl.d/cmd_lint.sh -- Writing-style lint (BAN rules)
#
# Checks for violations of project-wide writing conventions.
# Scans only \cyl{} regions (professor-written text) by default.
# Use --all to scan entire tex content.
#
# BAN rules enforced (always-on, WHOLE paper -- the professor's general bans):
#   1.  Em dash (---, —, –)
#   2.  Adverb+comma sentence openers (Specifically allowed)
#   3.  thereby / utilize / straightforward / numerous
#   4.  Weak reference phrases: "As shown in", "As can be seen from"
#   5.  Casual give/gives
#   6.  Casual conjunctions (, but / , so / , yet) and semicolon clause-joins
#   7.  Comma + V-ing (participial-preposition + -ing-noun whitelist)
#   8.  because (use since / as / given that)
#   9.  Bare \ref{} (use \cref; auto-skipped for papers without cleveref, e.g. SAGA)
#  10.  Float placement must be [t] (top of the page of first mention)
#  11.  Straight quotes "..." (must be ``...'')
#  12.  Inline math \(...\) (must be $...$; display math is allowed anywhere)
# Intro-only (--intro):
#  I1.  \item bullets outside the contributions block
#
# Provenance discipline (2026-06-12 professor ruling): every rule cites the
# professor's statement next to its definition. Unattested rules were removed
# (five GPT-ism phrases, intro display-math/notation/c4-c8-c2/"In this paper"/
# figure-ref bans). Do not add rules without provenance.
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
declare -a RULE_EXCLUDES=()

# _add_rule <pattern> <desc> <severity> [exclude-ERE]
# One call appends all four arrays so they can never fall out of alignment
# (the old per-array appends left RULE 7 with no severity entry, which silently
# shifted every --intro rule's severity by one slot).
# exclude-ERE: matched lines are dropped (false-positive guard, e.g. -ing nouns).
_add_rule() {
  RULE_PATTERNS+=("$1"); RULE_DESCS+=("$2"); RULE_SEVERITY+=("$3"); RULE_EXCLUDES+=("${4:-}")
}

# ============================================================
# ALWAYS-ON RULES -- the professor's general bans, WHOLE paper.
# Provenance discipline (2026-06-12 ruling): every rule cites where the professor
# stated it. Rules that existed only in code with no professor provenance were
# removed. Do NOT add a rule here without a citation.
# 2026-06-12: 「有一些general的精神是必須要共同整篇遵守的，例如comma+V-ing...以及but
# 這類的用詞。不應該歸納為有些用詞只有在introduction不該用」-- casual/V-ing/because
# were wrongly intro-gated before and are now global.
# ============================================================

# Em dash -- conference CLAUDE.md ABSOLUTE BANS + memory writing_bans #1
_add_rule '---|—|–' "Em dash (--- or — or –)" fail

# Adverb+comma openers, Specifically allowed -- CLAUDE.md + memory #2
# Anchors: line start (content carries a "N:" line-number prefix) or after { (inside \cyl{)
_add_rule '(^[0-9]*:|[{])[[:space:]]*(Notably|Importantly|Crucially|Interestingly|Essentially|Fundamentally|Consequently|Additionally|Furthermore|Moreover|Remarkably|Significantly|Particularly|Ultimately|Accordingly|Obviously|Clearly|Undoubtedly|Naturally|Admittedly),' \
  "Adverb+comma sentence opener (except Specifically)" fail

# Banned words -- straightforward: CLAUDE.md; thereby/utilize/numerous: ruling 2026-06-12 同意
_add_rule '\b(thereby|utilize|utilizes|utilized|utilizing|straightforward|numerous)\b' \
  "Banned word (thereby/utilize/straightforward/numerous)" fail

# Weak reference phrases -- professor 2026-06 appendix session (floats must be the sentence subject).
# The five other GPT-isms that used to live here were ruled OK on 2026-06-12 and removed.
_add_rule '(As can be seen from|[Aa]s shown in)' \
  "Weak reference phrase (As shown in / As can be seen from) -- make the table/figure the subject" fail

# Casual give/gives -- professor 2026-06 (「避免casual用詞像是so, but, 這邊還有give等」)
_add_rule '\b[Gg]ives?\b' "Casual 'give/gives' -- use provides/yields/produces" fail

# Casual conjunctions + semicolon clause-joins -- memory #4 (FLORA 明確禁止) + 2026-06 session (so/but)
_add_rule '(, yet [a-z]|, but [a-z]|, so [a-z]|; however,|; [a-z])' \
  "Casual conjunction / semicolon join -- use however/while/although or a period" fail

# Comma + V-ing -- memory #5 (FLORA methodology rewrite 明確禁止), whole paper per 2026-06-12.
# ERE-safe rewrite: the old pattern used a PCRE lookahead (?!...) which grep -E rejects,
# so this rule NEVER fired. Whitelist participial prepositions and -ing nouns instead.
_add_rule ', [a-z]+ing\b' "Comma + V-ing -- split into two clauses or use 'and V-s'" fail \
  ', (including|regarding|concerning|involving|containing|given|considering|excluding|notwithstanding|owing|using|during|nothing|something|anything|everything|morning|evening|string|ceiling|spring)\b'

# because -- ruling 2026-06-12 (「整篇我都不想because」)
_add_rule '\b[Bb]ecause\b' "'because' -- use 'since'/'as'/'given that'" fail

# Bare \ref -- CLAUDE.md \cref convention. Auto-skipped for manual-ref papers (no cleveref,
# e.g. SAGA house style Table~\ref / Eq.~\eqref) -- see dialect detection in _lint_paper.
_add_rule '(Figure|Table|Eq\.|Equation|Section|Sec\.|Fig\.)[~ ]*\\ref\{' \
  "Bare \\\\ref{} -- use \\\\cref{} or \\\\Cref{}" fail

# Float placement -- ruling 2026-06-12 (「圖片、Table都置頂，放在第一次mention的那一頁」).
# [t] is the lintable half; same-page-as-first-mention needs a visual pass on the PDF.
_add_rule '\\begin\{(figure|table|figure\*|table\*)\}\[(h|b|H|ht|hb|tb|bt|hbt|tbh|htbp)\]' \
  "Float placement -- use [t] only (top of the page of first mention)" fail

# Straight quotes -- ruling 2026-06-12 (「一定要enforce 這是LaTeX」); was effectively warn
# via the severity-misalignment bug, now an explicit fail.
_add_rule '(^|[^\\=>:_/])"[A-Za-z]' "Straight quote -- use \\\`\\\`...'' instead" fail

# Inline math -- ruling 2026-06-12: display math is fine ANYWHERE (the old intro ban was
# fabricated); the real rule is inline math must use $...$, not \(...\).
_add_rule '\\\(' "Inline math \\(...\\) -- use \$...\$" fail

# --- INTRO-ONLY rules (--intro): section-role rules for the Introduction ---
# 2026-06-12 provenance ruling:
#   KEPT    bullets-outside-contributions (professor: 同意; Intro is four prose paragraphs)
#   REMOVED display-math ban (「沒這種事情，數學應該要哪裡都可以展示」-- the real rule,
#           inline math must use $...$, is now an always-on rule above)
#   REMOVED notation \Delta/\tau/... + c4/c8/c2 ban (「莫名其妙，沒這種規定」; c4/c8/c2
#           was one old paper's notation hardcoded into a general tool)
#   REMOVED "In this paper, we" ban (「沒這種事」)
#   REMOVED figure-ref-in-intro (professor rejected; teaser ref in ¶3 is house style)
#   PROMOTED casual conjunctions / comma+V-ing / because to the always-on set above
if $INTRO_ONLY; then
  # Bullets only in the contributions block -- Intro body is prose paragraphs.
  # (content lines carry a "N:" line-number prefix, hence the anchor)
  _add_rule '^[0-9]*:[[:space:]]*\\item\b' "\\\\item bullet -- only allowed in contributions block" warn
fi

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

  # Cross-ref dialect: a paper that never loads cleveref (e.g. SAGA) legitimately
  # writes Table~\ref{} / Eq.~\eqref{} -- the bare-ref rule must not fire there.
  local crossref="cleveref"
  if ! grep -rqE --include='*.tex' --include='*.sty' --exclude-dir=_clean --exclude-dir=.git \
      '^[^%]*\\(usepackage|RequirePackage)(\[[^]]*\])?\{[^}]*cleveref' "$repo_dir" 2>/dev/null; then
    crossref="manual-ref"
  fi

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
      local exclude="${RULE_EXCLUDES[$rule_idx]}"

      # Manual-ref papers (no cleveref) use Table~\ref{} by design -- skip the bare-ref rule.
      if [[ "$crossref" == "manual-ref" && "$desc" == "Bare"* ]]; then
        rule_idx=$((rule_idx + 1))
        continue
      fi

      local matches
      # '--' terminates option parsing: the em-dash pattern starts with '-' and was
      # silently parsed as a grep OPTION before (error eaten by 2>/dev/null), so the
      # em-dash rule never fired at all until this fix.
      matches=$(echo "$content" | grep -nE -- "$pattern" 2>/dev/null || true)
      if [[ -n "$matches" && -n "$exclude" ]]; then
        matches=$(echo "$matches" | grep -vE -- "$exclude" 2>/dev/null || true)
      fi

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
