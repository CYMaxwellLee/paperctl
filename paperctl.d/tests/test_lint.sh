#!/bin/bash
# paperctl.d/tests/test_lint.sh -- self-contained fixture tests for the lint rules
#
# Covers the 2026-06-12 rulings end-to-end plus the verifier-team fixes:
#   - every attested always-on ban fires (incl. capitalized forms, mid-line sentence
#     starts, sentence-initial But/So, parenthetical "(Table 9)", any bare \ref)
#   - whitelists hold per-MATCH (a whitelisted ', including' cannot mask a real
#     ', producing' on the same line; ', but also' and ', so that' are allowed)
#   - rules the professor removed stay silent (GPT-isms, In-this-paper, display math)
#   - %-commented \cyl graveyard lines are silent in default mode
#   - multi-line \cyl closing lines are scanned in default mode
#   - manual-ref papers are not flagged for Table~\ref{} (dialect skip)
#   - --intro exempts the contributions itemize and flags only stray \item
#   - exit contract: fail-severity hits -> exit 1; clean paper -> exit 0
#
# Usage: bash paperctl.d/tests/test_lint.sh   (exit 0 = all assertions pass)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAPERCTL="$(cd "$TESTS_DIR/../.." && pwd)/paperctl"
TMP=$(mktemp -d /tmp/paperctl_lintfx.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()  { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
assert_has() { if grep -qE "$2" <<<"$3"; then ok "$1"; else bad "$1 (missing: $2)"; fi; }
assert_not() { if grep -qE "$2" <<<"$3"; then bad "$1 (unexpected: $2)"; else ok "$1"; fi; }
assert_rc()  { if [[ "$2" -eq "$3" ]]; then ok "$1"; else bad "$1 (rc=$2, want $3)"; fi; }
assert_cnt() { local c; c=$(grep -cE "$2" <<<"$3"); if [[ "$c" -eq "$4" ]]; then ok "$1"; else bad "$1 (count=$c, want $4)"; fi; }

mkdir -p "$TMP"/paper-{x,y,z}/sections

cat > "$TMP/conference.json" <<'EOF'
{
  "conference": {"name": "testconf", "year": 2099, "slug": "testconf2099", "template": "none", "org": "none"},
  "defaults": {"github_branch": "main", "overleaf_branch": "master", "overleaf_remote": "overleaf", "upstream_remote": "upstream"},
  "papers": [
    {"name": "paper-x", "repo": "paper-x", "overleaf": "", "upstream": null},
    {"name": "paper-y", "repo": "paper-y", "overleaf": "", "upstream": null},
    {"name": "paper-z", "repo": "paper-z", "overleaf": "", "upstream": null}
  ]
}
EOF

for p in x z; do
cat > "$TMP/paper-$p/main.tex" <<'EOF'
\documentclass{article}
\usepackage[capitalize,noabbrev]{cleveref}
\usepackage{float}
\begin{document}
\input{sections/body}
\end{document}
EOF
done
cat > "$TMP/paper-y/main.tex" <<'EOF'
\documentclass{article}
\usepackage{graphicx}
\begin{document}
\input{sections/body}
\end{document}
EOF

# paper-x: one violation (or one whitelisted near-miss) per line.
cat > "$TMP/paper-x/sections/body.tex" <<'EOF'
\section{Test}
This sentence stays clean and, including the caveat, is fine.
Then, nothing changes in the loop and this line stays clean.
The corpus covers diverse scenes and, training data aside, stays balanced.
It is worth noting that this phrase was ruled OK and stays silent.
In this paper, we keep this phrase since it was ruled OK.
\[ y = x \]
Specifically, the Specifically opener stays allowed.
The lemma was shown in prior work and stays silent.
The schedule was tuned, so that the model converges, and stays allowed.
The study covers not only the cause, but also the timing of failures.
\cyl{The runs were stable, but the variance grew under load.}
\cyl{The seeds moved because the scheduler restarted.}
\cyl{The pipeline was rerun, producing drift in the logs.}
\cyl{The model was trained, using the solver without tuning.}
\cyl{The caveat stands, including the edge case, producing drift anyway.}
\cyl{Notably, the gain was large on the held-out split.}
\cyl{The setup is simple. Moreover, the cost stays flat.}
\cyl{The margin model gives a wide buffer on most tasks.}
\cyl{As shown in the table, accuracy stays high.}
\cyl{The score rose; the cost stayed flat.}
\cyl{We utilize the fast mode for the final pass.}
\cyl{Numerous prior works exist and Utilizing them is common.}
\cyl{The "fast" mode label uses straight quotes here.}
\cyl{The interval \(x+1\) sits inline in this sentence.}
\cyl{The gap widened --- the dash gets flagged.}
\cyl{Yet the model held steady on the harder split.}
\cyl{These results underscore the value of the design choices.}
\cyl{The gain is large in this setting (Table 9).}
\cyl{But the baseline holds. So we keep the default.}
\cyl{The loss dropped, so we stopped the run early.}
\cyl{Table~\ref{tab:q} gets flagged on a cleveref paper.}
\cyl{The opening line of this multi-line block stays clean here
and the closing line makes a straightforward claim.}
\begin{table}[H]
\end{table}
\begin{figure}[htb]
\end{figure}
\begin{table}[p]
\end{table}
\begin{figure}[h!]
\end{figure}
\begin{table}[t]
\end{table}
\begin{figure}[!t]
\end{figure}
EOF

cat > "$TMP/paper-x/sections/introduction.tex" <<'EOF'
\section{Introduction}
The introduction body stays clean prose for this fixture.
Our contributions are as follows:
\begin{itemize}
\item the first legitimate contribution bullet stays unflagged
\item the second legitimate contribution bullet stays unflagged
\end{itemize}
\[ y = x \]
\item this stray bullet gets flagged in intro mode
EOF

# paper-y (NO cleveref): house-style \ref allowed; commented \cyl graveyard is dead text;
# mid-sentence ', yet' is a WARN (很不 prefer) and must NOT trip the exit-1 gate.
cat > "$TMP/paper-y/sections/body.tex" <<'EOF'
\section{Test}
\cyl{Table~\ref{tab:q} is the correct house style on this paper.}
\cyl{The probe ran, yet the cache stayed cold.}
% \cyl{This commented line says because twice because it is dead text.}
EOF

# paper-z: fully clean professor text.
cat > "$TMP/paper-z/sections/body.tex" <<'EOF'
\section{Test}
\cyl{The verified pipeline holds across every benchmark we report.}
EOF

echo "── paper-x --all: every rule fires; whitelists hold; removed rules stay silent ──"
OUT=$("$PAPERCTL" lint --dir "$TMP" --paper paper-x --all 2>&1); RC=$?
assert_rc  "exit 1 on fail-severity hits"          "$RC" 1
assert_has "em dash fires"                          'Em dash' "$OUT"
assert_has "adverb opener fires (Notably,)"         'Notably, the gain' "$OUT"
assert_has "mid-line adverb fires (. Moreover,)"    'Moreover, the cost' "$OUT"
assert_has "utilize fires"                          'We utilize' "$OUT"
assert_has "capitalized Numerous/Utilizing fire"    'Numerous prior works' "$OUT"
assert_has "weak ref fires (As shown in)"           'Weak reference' "$OUT"
assert_not "'was shown in' passive stays silent"    'lemma' "$OUT"
assert_has "gives fires"                            "Casual 'give" "$OUT"
assert_has "', but' fires"                          'variance grew' "$OUT"
assert_not "', but also' correlative stays silent"  'timing of failures' "$OUT"
assert_not "', so that' purposive stays silent"     'model converges' "$OUT"
assert_has "', so we' fires"                        'stopped the run' "$OUT"
assert_has "semicolon join fires"                   'score rose' "$OUT"
assert_has "comma+V-ing fires (, producing)"        'producing drift in the logs' "$OUT"
assert_has "', using' fires (whitelist removed)"    'solver without tuning' "$OUT"
assert_has "per-match: whitelisted+real on one line still fires" 'edge case' "$OUT"
assert_not "', training data' noun stays silent"    'training data' "$OUT"
assert_not "', nothing' stays silent"               'nothing changes' "$OUT"
assert_not "', including' alone stays silent"       'including the caveat' "$OUT"
assert_has "because fires"                          'scheduler restarted' "$OUT"
assert_not "'It is worth noting' stays OK"          'It is worth noting' "$OUT"
assert_not "'In this paper, we' stays OK"           'keep this phrase' "$OUT"
assert_not "display math stays OK"                  'Display math' "$OUT"
assert_not "Specifically stays allowed"             'opener stays allowed' "$OUT"
assert_has "bare Table~\\ref fires (cleveref paper)" 'Bare' "$OUT"
assert_cnt "float: exactly 4 of 6 specs flagged ([H]/[htb]/[p]/[h!]; [t]/[!t] pass)" 'Float placement' "$OUT" 4
assert_has "straight quote fires"                   'Straight quote' "$OUT"
assert_has "inline \\(...\\) fires"                 'Inline math' "$OUT"
assert_has "sentence-initial Yet fires"             "Sentence-initial 'Yet'" "$OUT"
assert_has "underscore fires (any use)"             'underscore.+any use' "$OUT"
assert_has "parenthetical (Table 9) fires"          'Parenthetical' "$OUT"
assert_has "sentence-initial But/So fires"          "Sentence-initial 'But'" "$OUT"

echo "── paper-x default (cyl) mode: multi-line closing line + violations caught ──"
OUT=$("$PAPERCTL" lint --dir "$TMP" --paper paper-x 2>&1); RC=$?
assert_rc  "default mode exits 1 too"               "$RC" 1
assert_has "multi-line \\cyl closing line scanned"  'straightforward claim' "$OUT"
assert_has "cyl-mode catches casual conjunction"    'Casual conjunction' "$OUT"

echo "── paper-y default: dialect skip + graveyard silent + ', yet' warns without gating ──"
OUT=$("$PAPERCTL" lint --dir "$TMP" --paper paper-y 2>&1); RC=$?
assert_rc  "warn-only paper still exits 0 (', yet' must not gate)" "$RC" 0
assert_has "', yet' warns as strongly dispreferred"  'dispreferred' "$OUT"
assert_not "Table~\\ref not flagged without cleveref" 'Bare' "$OUT"
assert_not "commented '% \\cyl{...because...}' silent" 'dead text' "$OUT"

echo "── paper-z default: fully clean exits 0 ──"
OUT=$("$PAPERCTL" lint --dir "$TMP" --paper paper-z 2>&1); RC=$?
assert_rc  "clean paper exits 0"                    "$RC" 0
assert_has "reports all clean"                      'All clean' "$OUT"

echo "── paper-x --intro: contributions itemize exempt, stray \\item flagged ──"
OUT=$("$PAPERCTL" lint --dir "$TMP" --paper paper-x --intro 2>&1); RC=$?
assert_cnt "exactly one item-bullet flag (the stray one)" 'item bullet' "$OUT" 1
assert_has "the flagged one is the stray bullet"    'stray bullet' "$OUT"
assert_not "contribution bullets stay unflagged"    'legitimate contribution' "$OUT"
assert_not "intro display math stays OK"            'Display math' "$OUT"

echo ""
echo "📊 $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
