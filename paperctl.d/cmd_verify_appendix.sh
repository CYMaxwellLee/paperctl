#!/bin/bash
# paperctl.d/cmd_verify_appendix.sh -- READ-ONLY structural verifier for appendix rewrites
#
# Line-by-line lint (cmd_lint.sh) operates on ONE version of the text. The appendix
# doctrine is about the RELATIONSHIP between the preserved student text and the blue
# professor rewrite, which lint cannot express. This command pairs them per (sub)section
# and enforces:
#   A  blue rewrite >= student length        (anti-summarize)
#   B  blue paragraph count >= student        (no collapsing N paragraphs into 1)
#   C  every table/figure/number in student reappears in blue (no silent drops)
#   D  student DISPLAYED equations stay displayed in blue (no flattening to prose)
#   E  table/figure is the sentence SUBJECT  (no "(Table~\ref{})" / "As shown in")
#   F  no context-assuming openers           ("This sweep ...") -- connect to main or name a subject
#   J  per-paper LaTeX dialect               (manual \ref vs \cref; [H] availability)
#
# "Blue" = professor text inside \cyl{...}, \textcolor{blue}{...}, or {\color{blue} ...}.
# "Student" = the preserved plain prose + commented-out original in the same (sub)section.
# Verbatim quoted data (\textit{``...''}) is masked so its but/;/em-dash are not flagged.
#
# This command NEVER writes files. Exit status is 1 if any FAIL, so it can gate a push.
#
# Usage:
#   paperctl verify-appendix [--paper <name>] [--file <path>]

load_config
. "$PAPERCTL_LIB/lib_check.sh"

VERIFY_FILE=""
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --file) VERIFY_FILE="${2:-}"; shift 2 ;;
    *) break ;;
  esac
done

# --- Structural analyzer (subsection-aware, two-version diff) ---
_verify_py() {
  python3 - "$1" "$2" "$3" << 'PYEOF'
import re, sys

path = sys.argv[1]
crossref = sys.argv[2] if len(sys.argv) > 2 else 'cleveref'
float_H  = (sys.argv[3] == 'true') if len(sys.argv) > 3 else False

try:
    with open(path, errors='replace') as f:
        raw = f.read()
except Exception as e:
    print("INFO|-|%s|cannot read: %s" % (path, e)); sys.exit(0)

def grab_braced(s, j):
    """s[j] is first char of brace content (opening { already consumed, depth=1)."""
    depth = 1; k = j
    while k < len(s):
        c = s[k]
        if c == '\\': k += 2; continue
        if c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0: return s[j:k], k
        k += 1
    return s[j:], len(s)

MARKERS = ['\\cyl{', '\\textcolor{blue}{', '{\\color{blue}']
def extract_blue(text):
    spans = []; i = 0; n = len(text)
    while i < n:
        hit = False
        for m in MARKERS:
            if text.startswith(m, i):
                j = i + len(m)
                content, end = grab_braced(text, j)
                spans.append((content, i, end)); i = end + 1; hit = True; break
        if not hit: i += 1
    return spans

def split_comments(text):
    """Return (plain_no_comments, commented_text) char-by-char %-aware."""
    plain = []; commented = []
    for line in text.split('\n'):
        res = []; i = 0; com = None
        while i < len(line):
            if line[i] == '%' and (i == 0 or line[i-1] != '\\'):
                com = line[i+1:]; break
            res.append(line[i]); i += 1
        plain.append(''.join(res))
        if com is not None: commented.append(com)
    return '\n'.join(plain), '\n'.join(commented)

def mask_quoted(t):
    return re.sub(r'\\textit\{``.*?\'\'\}', ' QUOTED ', t, flags=re.DOTALL)

def strip_words(t):
    t = re.sub(r'\$\$.*?\$\$', ' ', t, flags=re.DOTALL)
    t = re.sub(r'\\\[.*?\\\]', ' ', t, flags=re.DOTALL)
    t = re.sub(r'\\begin\{(equation|align|gather|multline)\*?\}.*?\\end\{\1\*?\}', ' ', t, flags=re.DOTALL)
    t = re.sub(r'\$[^$]+\$', ' M ', t)
    t = re.sub(r'\\begin\{(figure|table|tabular|algorithm)\*?\}.*?\\end\{\1\*?\}', ' ', t, flags=re.DOTALL)
    # Keep the TEXT of formatting commands (drop only the wrapper), same as cmd_wordcount.sh,
    # so \textbf{key point} still counts its words instead of vanishing.
    t = re.sub(r'\\(textbf|textit|emph|underline|textsc|texttt|mbox)\{', ' ', t)
    t = re.sub(r'\\[a-zA-Z]+(\[[^\]]*\])?(\{[^}]*\})?', ' ', t)
    t = re.sub(r'[{}~\\&%#_^]', ' ', t)
    return t

def wc(t):
    return len([w for w in strip_words(t).split() if len(w) > 1 or w.isalpha()])

def paras(t):
    return [p for p in re.split(r'\n\s*\n', t.strip()) if p.strip()]

DISP = re.compile(r'\\begin\{(?:equation|align|gather|multline|eqnarray)\*?\}|\\\[')
def disp_count(t): return len(DISP.findall(t))
def floatrefs(t): return set(re.findall(r'\\[cC]?ref\{((?:tab|fig):[^}]*)\}', t))
def graphics(t):  return set(re.findall(r'\\includegraphics(?:\[[^\]]*\])?\{([^}]*)\}', t))
def numbers(t):   return set(re.findall(r'\b\d+\.\d+\b', strip_words(t)))

F_NOUNS = ('sweep|ablation|table|experiment|setup|study|analysis|result|section|approach|'
           'method|metric|number|value|design|module|component|term|signal|step|figure|variant')

findings = []
def emit(sev, rub, loc, msg): findings.append("%s|%s|%s|%s" % (sev, rub, loc, msg))

heads = list(re.finditer(r'(?m)^[ \t]*\\(?:sub)*section\*?\{([^}]*)\}', raw))
segments = []
for idx, h in enumerate(heads):
    end = heads[idx+1].start() if idx+1 < len(heads) else len(raw)
    segments.append((h.group(1).strip(), raw[h.end():end]))

for title, seg in segments:
    spans = extract_blue(seg)
    blue_raw = '\n'.join(c for c, _, _ in spans)
    if spans:
        cut = []; prev = 0
        for c, s, e in spans:
            cut.append(seg[prev:s]); prev = e + 1
        cut.append(seg[prev:])
        student_seg = ''.join(cut)
    else:
        student_seg = seg
    plain, commented = split_comments(student_seg)
    student_raw = plain + '\n' + commented
    blue_m, student_m = mask_quoted(blue_raw), mask_quoted(student_raw)

    has_blue = wc(blue_raw) > 0
    has_student = wc(student_m) >= 20

    if has_blue and has_student:
        nb, ns = wc(blue_m), wc(student_m)
        if nb < ns:
            emit('FAIL', 'A', title, "blue rewrite shorter than student (%d < %d words) -- likely summarized" % (nb, ns))
        sp, bp = paras(strip_words(plain)), paras(strip_words(blue_raw))
        if len(sp) >= 2 and len(bp) < len(sp):
            emit('FAIL', 'B', title, "blue has fewer paragraphs than student (%d < %d)" % (len(bp), len(sp)))
        miss_f = floatrefs(student_m) - floatrefs(blue_m)
        if miss_f:
            emit('FAIL', 'C', title, "tables/figures in student dropped from blue: %s" % ', '.join(sorted(miss_f)))
        miss_g = graphics(student_m) - graphics(blue_m)
        if miss_g:
            emit('WARN', 'C', title, "includegraphics in student not in blue: %s" % ', '.join(sorted(miss_g)))
        miss_n = numbers(student_m) - numbers(blue_m)
        if miss_n:
            emit('WARN', 'C', title, "decimal numbers in student not found in blue: %s" % ', '.join(sorted(miss_n)))
        ds, db = disp_count(student_seg), disp_count(blue_raw)
        if db < ds:
            emit('FAIL', 'D', title, "displayed equations flattened (%d < %d display-math envs in blue)" % (db, ds))

    if has_blue:
        if re.search(r'\(\s*(?:Table|Figure)?~?\s*\\[cC]?ref\{(?:tab|fig):', blue_m):
            emit('FAIL', 'E', title, "parenthetical table/figure ref -- make the float the sentence subject")
        if re.search(r'\b[Aa]s shown in\b', blue_m) or re.search(r'\bshown in \\[cC]ref\{(?:tab|fig):', blue_m):
            emit('FAIL', 'E', title, "weak 'shown in ...' ref -- lead with the float as subject")
        for r in floatrefs(blue_m):
            subj = re.search(r'(?:^|\.\s+|\n\s*)(?:Table|Figure)?~?\s*\\[cC]ref\{' + re.escape(r) + r'\}', blue_m) \
                or re.search(r'(?:^|\.\s+|\n\s*)(?:Table|Figure)~?\\ref\{' + re.escape(r) + r'\}', blue_m)
            if not subj:
                emit('WARN', 'E', title, "%s never appears as a sentence subject in blue" % r)
        first = re.split(r'(?<=[.!?])\s', blue_m.strip(), 1)[0][:160] if blue_m.strip() else ''
        if re.match(r'^(This|These|That|Those)\s+(?:' + F_NOUNS + r')\b', first) \
           and not re.search(r'\\[cC]ref\{|Section~?\\ref\{|\\Cref\{', first):
            emit('FAIL', 'F', title, "context-assuming opener '%s...' -- connect to main via \\cref or name the subject" % first[:55])
        if crossref == 'manual-ref' and re.search(r'\\[cC]ref\{', blue_m):
            emit('FAIL', 'J', title, "paper uses manual \\ref (no cleveref) but blue uses \\cref/\\Cref -- will be undefined")
        if (not float_H) and re.search(r'\[H\]', blue_raw):
            emit('FAIL', 'J', title, "[H] float but paper has no float package -- use [t]")

for line in findings:
    print(line)
if not findings:
    print("INFO|-|%s|no structural issues found" % path.split('/')[-1])
PYEOF
}

_detect_dialect() {  # echoes "<crossref> <float_H>"
  local repo_dir="$1" name="$2"
  local crossref="cleveref" float_H="false"
  # conference.json override takes priority (P1 field, optional)
  local idx cj_cross cj_float
  idx=$(paper_index_by_name "$name")
  if [[ -n "$idx" ]]; then
    cj_cross=$(_jq "$CONF_FILE" ".papers[$idx].latex.crossref" 2>/dev/null || echo "null")
    cj_float=$(_jq "$CONF_FILE" ".papers[$idx].latex.float_H" 2>/dev/null || echo "null")
  else
    cj_cross="null"; cj_float="null"
  fi
  # Fallback: detect the real package LOAD across all .tex/.sty (not just main.tex),
  # excluding comment lines (a commented "no cleveref" note must not count as a load).
  local _gopts=(-rqE --include='*.tex' --include='*.sty' --exclude-dir=_clean --exclude-dir=.git)
  if [[ "$cj_cross" != "null" && -n "$cj_cross" ]]; then
    crossref="$cj_cross"
  else
    if ! grep "${_gopts[@]}" '^[^%]*\\(usepackage|RequirePackage)(\[[^]]*\])?\{[^}]*cleveref' "$repo_dir" 2>/dev/null; then
      crossref="manual-ref"
    fi
  fi
  if [[ "$cj_float" != "null" && -n "$cj_float" ]]; then
    float_H="$cj_float"
  else
    if grep "${_gopts[@]}" '^[^%]*\\(usepackage|RequirePackage)(\[[^]]*\])?\{[^}]*float[},]' "$repo_dir" 2>/dev/null; then
      float_H="true"
    fi
  fi
  echo "$crossref $float_H"
}

_find_appendix() {
  local repo_dir="$1"
  if [[ -n "$VERIFY_FILE" ]]; then echo "$VERIFY_FILE"; return; fi
  find "$repo_dir" -iname 'appendix*.tex' -not -path '*/_clean/*' -not -path '*/.git/*' 2>/dev/null | sort | head -1
}

_verify_one() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $name ($repo)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  reset_repo_counts

  local appx; appx=$(_find_appendix "$repo_dir" || true)
  if [[ -z "$appx" || ! -f "$appx" ]]; then
    check_info "no appendix*.tex found, skipping"
    flush_repo_counts; return
  fi

  local dialect; dialect=$(_detect_dialect "$repo_dir" "$name")
  local crossref="${dialect%% *}" floatH="${dialect##* }"
  echo "  file: ${appx#$repo_dir/}    dialect: crossref=$crossref  float_H=$floatH"
  echo ""

  local out; out=$(_verify_py "$appx" "$crossref" "$floatH" 2>/dev/null || true)
  if [[ -z "$out" ]]; then
    check_warn "verifier produced no output (parse error?)"
    flush_repo_counts; return
  fi
  while IFS='|' read -r sev rub loc msg; do
    [[ -z "$sev" ]] && continue
    case "$sev" in
      FAIL) check_fail "[$rub] $loc -- $msg" ;;
      WARN) check_warn "[$rub] $loc -- $msg" ;;
      *)    check_info "$msg" ;;
    esac
  done <<< "$out"
  flush_repo_counts
}

echo ""
print_check_banner "Appendix Structural Verifier (read-only)"
for_each_paper _verify_one
print_check_summary
[[ $TOTAL_FAIL -gt 0 ]] && exit 1 || exit 0
