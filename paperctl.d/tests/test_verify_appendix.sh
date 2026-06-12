#!/bin/bash
# paperctl.d/tests/test_verify_appendix.sh -- self-contained fixture tests for verify-appendix
#
# Proves every structural rule actually fires, with zero external dependencies:
# builds a throwaway conference in mktemp (no git, no network, no real papers) with
# three synthetic papers, then asserts:
#   paper-bad      a summarizing blue rewrite trips A, B, C, D, E, F (and NOT J)
#   paper-good     a compliant full rewrite produces zero findings and exit 0
#   paper-dialect  manual-ref/no-float paper using \cref + [H] in blue trips J twice
# The three blue markers (\cyl{}, {\color{blue} }, \textcolor{blue}{}) are each exercised.
#
# Usage: bash paperctl.d/tests/test_verify_appendix.sh   (exit 0 = all assertions pass)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAPERCTL="$(cd "$TESTS_DIR/../.." && pwd)/paperctl"
TMP=$(mktemp -d /tmp/paperctl_vfx.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()  { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
assert_has() { if grep -qE "$2" <<<"$3"; then ok "$1"; else bad "$1 (missing: $2)"; fi; }
assert_not() { if grep -qE "$2" <<<"$3"; then bad "$1 (unexpected: $2)"; else ok "$1"; fi; }
assert_rc()  { if [[ "$2" -eq "$3" ]]; then ok "$1"; else bad "$1 (rc=$2, want $3)"; fi; }

# ---------- throwaway conference ----------
mkdir -p "$TMP"/paper-{bad,good,dialect}/sections

cat > "$TMP/conference.json" <<'EOF'
{
  "conference": {"name": "testconf", "year": 2099, "slug": "testconf2099", "template": "none", "org": "none"},
  "defaults": {"github_branch": "main", "overleaf_branch": "master", "overleaf_remote": "overleaf", "upstream_remote": "upstream"},
  "papers": [
    {"name": "paper-bad",     "repo": "paper-bad",     "overleaf": "", "upstream": null},
    {"name": "paper-good",    "repo": "paper-good",    "overleaf": "", "upstream": null},
    {"name": "paper-dialect", "repo": "paper-dialect", "overleaf": "", "upstream": null}
  ]
}
EOF

# cleveref + float dialect for bad/good; bare article for dialect paper
for p in bad good; do
cat > "$TMP/paper-$p/main.tex" <<'EOF'
\documentclass{article}
\usepackage[capitalize,noabbrev]{cleveref}
\usepackage{float}
\begin{document}
\input{sections/appendix}
\end{document}
EOF
done
cat > "$TMP/paper-dialect/main.tex" <<'EOF'
\documentclass{article}
\usepackage{graphicx}
\begin{document}
\input{sections/appendix}
\end{document}
EOF

# Shared student passage: 3 paragraphs, 2 table refs, 1 displayed equation, 3 decimals.
read -r -d '' STUDENT <<'EOF' || true
\section{Ablation on Window Size}

The student paragraph one describes the ablation protocol in detail, listing the evaluation settings, the number of random seeds, and the exact benchmark splits used for every reported run in this study so the experiment can be repeated.

\Cref{tab:window} reports success rates across window sizes, and accuracy moves from 90.1 to 97.8 over the sweep while latency stays near 4.2 milliseconds. \Cref{tab:latency} isolates the per-query cost for each setting.
\begin{equation}
y = f(x) + b
\end{equation}
\includegraphics[width=\linewidth]{figs/window_sweep.pdf}

The student paragraph three interprets the trend and argues that the medium window gives the best balance between accuracy and latency for deployment on real robots under the standard evaluation protocol.
EOF

# paper-bad: blue is a one-line summary -- demonstrative opener (F), shorter (A), one
# paragraph (B), drops tab:latency and the equation (C, D), parenthetical ref (E).
{
  printf '%s\n\n' "$STUDENT"
  cat <<'EOF'
\cyl{This sweep varies the window size to test sensitivity. Accuracy reaches 97.8 (Table~\cref{tab:window}). The trend is shown in \cref{tab:window} as well.}
EOF
} > "$TMP/paper-bad/sections/appendix.tex"

# paper-good: blue is a compliant full rewrite in {\color{blue} ...} -- longer, three
# paragraphs, both tables as sentence subjects, equation re-displayed, opener anchored.
{
  printf '%s\n\n' "$STUDENT"
  cat <<'EOF'
{\color{blue}
The ablation protocol in \cref{sec:eval} fixes the evaluation settings before any window comparison and restates the number of random seeds and the exact benchmark splits used for every reported run. This appendix section therefore stands alone for a reader arriving from the main text.

\Cref{tab:window} reports success rates across window sizes, and accuracy climbs from 90.1 to 97.8 over the sweep while latency stays near 4.2 milliseconds per query. \Cref{tab:latency} isolates the per-query cost and confirms the overhead stays flat across every window size tested under the same protocol.
\begin{equation}
y = f(x) + b
\end{equation}
\includegraphics[width=\linewidth]{figs/window_sweep.pdf}

The medium window therefore provides the best balance between accuracy and latency, and the trend across the full sweep supports deploying that setting on real robots without further tuning of the window size or the evaluation protocol described above.
}
EOF
} > "$TMP/paper-good/sections/appendix.tex"

# paper-dialect: paper has NO cleveref and NO float, but blue uses \cref and [H] -> J twice.
# Uses the \textcolor{blue}{} marker so all three markers are covered across fixtures.
cat > "$TMP/paper-dialect/sections/appendix.tex" <<'EOF'
\section{Implementation Notes}

The student paragraph describes the training configuration in enough words to pass the student threshold, covering optimizer settings, batch sizes, the learning-rate schedule, and the hardware used for all reported experiments.

\textcolor{blue}{\cref{sec:setup} anchors this section in the main text. Table~\ref{tab:hyper} lists every value, and the schedule follows the main text with the full configuration repeated here for completeness, including optimizer settings, batch sizes, the learning-rate schedule, and the hardware used for all reported experiments and ablation runs.
\begin{table}[H]
\end{table}
}
EOF

# ---------- run + assert ----------
echo "── paper-bad (summarizing rewrite must trip A/B/C/D/E/F, not J) ──"
OUT=$("$PAPERCTL" verify-appendix --dir "$TMP" --paper paper-bad 2>&1); RC=$?
assert_rc  "exit code 1 (gate blocks)"                  "$RC" 1
assert_has "dialect detected cleveref+float"            'crossref=cleveref  float_H=true' "$OUT"
assert_has "A fires (blue shorter than student)"        'FAIL: \[A\]' "$OUT"
assert_has "B fires (paragraphs collapsed)"             'FAIL: \[B\]' "$OUT"
assert_has "C fires on dropped table"                   'FAIL: \[C\].*tab:latency' "$OUT"
assert_has "C warns on dropped numbers"                 'WARN: \[C\].*90\.1' "$OUT"
assert_has "D fires (equation flattened)"               'FAIL: \[D\]' "$OUT"
assert_has "E fires (parenthetical table ref)"          'FAIL: \[E\]' "$OUT"
assert_has "E fires on weak 'shown in' ref"             "weak 'shown in" "$OUT"
assert_has "E warns when float never the subject"       'WARN: \[E\].*tab:window' "$OUT"
assert_has "C warns on includegraphics dropped"         'WARN: \[C\].*window_sweep' "$OUT"
assert_has "F fires (This sweep... opener)"             'FAIL: \[F\]' "$OUT"
assert_not "J stays silent (dialect is fine)"           'FAIL: \[J\]' "$OUT"

echo "── paper-good (compliant rewrite must pass clean) ──"
OUT=$("$PAPERCTL" verify-appendix --dir "$TMP" --paper paper-good 2>&1); RC=$?
assert_rc  "exit code 0 (gate passes)"                  "$RC" 0
assert_has "reports no structural issues"               'no structural issues' "$OUT"
assert_not "no FAIL of any rule"                        'FAIL:' "$OUT"

echo "── paper-dialect (manual-ref/no-float paper, blue uses \\cref + [H]) ──"
OUT=$("$PAPERCTL" verify-appendix --dir "$TMP" --paper paper-dialect 2>&1); RC=$?
assert_rc  "exit code 1 (gate blocks)"                  "$RC" 1
assert_has "dialect detected manual-ref/no-float"       'crossref=manual-ref  float_H=false' "$OUT"
JC=$(grep -cE 'FAIL: \[J\]' <<<"$OUT")
if [[ "$JC" -eq 2 ]]; then ok "J fires exactly twice (cref + [H])"; else bad "J fired $JC times, want 2"; fi
assert_not "structural rules stay silent"               'FAIL: \[[A-F]\]' "$OUT"

echo ""
echo "📊 $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
