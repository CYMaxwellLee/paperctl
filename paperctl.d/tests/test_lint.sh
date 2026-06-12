#!/bin/bash
# paperctl.d/tests/test_lint.sh -- self-contained fixture tests for the lint rules
#
# Verifies the 2026-06-12 provenance ruling end-to-end with zero external deps:
#   - every attested always-on ban FIRES (em dash, adverb opener, banned words,
#     weak refs, give/gives, casual conjunctions, comma+V-ing, because, bare \ref,
#     float placement, straight quotes, inline \(...\))
#   - whitelisted constructions do NOT fire (", including", ", nothing", Specifically)
#   - rules the professor removed stay SILENT ("It is worth noting that",
#     "In this paper, we", display math \[...\])
#   - manual-ref papers (no cleveref) are NOT flagged for Table~\ref{} (dialect skip)
#   - --intro flags \item bullets (proves the line-number-prefix anchor works)
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

mkdir -p "$TMP"/paper-{x,y}/sections

cat > "$TMP/conference.json" <<'EOF'
{
  "conference": {"name": "testconf", "year": 2099, "slug": "testconf2099", "template": "none", "org": "none"},
  "defaults": {"github_branch": "main", "overleaf_branch": "master", "overleaf_remote": "overleaf", "upstream_remote": "upstream"},
  "papers": [
    {"name": "paper-x", "repo": "paper-x", "overleaf": "", "upstream": null},
    {"name": "paper-y", "repo": "paper-y", "overleaf": "", "upstream": null}
  ]
}
EOF

cat > "$TMP/paper-x/main.tex" <<'EOF'
\documentclass{article}
\usepackage[capitalize,noabbrev]{cleveref}
\begin{document}
\input{sections/body}
\input{sections/introduction}
\end{document}
EOF

cat > "$TMP/paper-y/main.tex" <<'EOF'
\documentclass{article}
\usepackage{graphicx}
\begin{document}
\input{sections/body}
\end{document}
EOF

# paper-x body: one violation (or one whitelisted near-miss) per line.
cat > "$TMP/paper-x/sections/body.tex" <<'EOF'
\section{Test}
This sentence stays clean and, including the caveat, must not be flagged.
Then, nothing changes in the loop and this line must stay clean.
It is worth noting that this phrase was ruled OK and must not be flagged.
In this paper, we keep this phrase since it was ruled OK.
\[ y = x \]
Specifically, the Specifically opener stays allowed.
\cyl{The runs were stable, but the variance grew under load.}
\cyl{The seeds moved because the scheduler restarted.}
\cyl{The pipeline was rerun, producing drift in the logs.}
\cyl{Notably, the gain was large on the held-out split.}
\cyl{The margin model gives a wide buffer on most tasks.}
\cyl{As shown in the table, accuracy stays high.}
\cyl{The score rose; the cost stayed flat.}
\cyl{We utilize the fast mode for the final pass.}
\cyl{The "fast" mode label uses straight quotes here.}
\cyl{The interval \(x+1\) sits inline in this sentence.}
\cyl{The gap widened --- the dash must be flagged.}
\cyl{Table~\ref{tab:q} must be flagged on a cleveref paper.}
\begin{table}[H]
\end{table}
EOF

cat > "$TMP/paper-x/sections/introduction.tex" <<'EOF'
\section{Introduction}
The introduction body stays clean prose for this fixture.
\item this stray bullet must be flagged in intro mode
EOF

# paper-y (NO cleveref): the same Table~\ref must NOT be flagged (house dialect).
cat > "$TMP/paper-y/sections/body.tex" <<'EOF'
\section{Test}
\cyl{Table~\ref{tab:q} is the correct house style on this paper.}
EOF

echo "── paper-x --all (always-on rules fire; removed rules stay silent) ──"
OUT=$("$PAPERCTL" lint --dir "$TMP" --paper paper-x --all 2>&1)
assert_has "em dash fires"                    'Em dash' "$OUT"
assert_has "adverb opener fires (Notably,)"   'Adverb\+comma' "$OUT"
assert_has "utilize fires"                    'Banned word' "$OUT"
assert_has "As shown in fires"                'Weak reference' "$OUT"
assert_has "gives fires"                      "Casual 'give" "$OUT"
assert_has "', but' fires"                    'Casual conjunction' "$OUT"
assert_has "semicolon join fires"             'semicolon join|Casual conjunction' "$OUT"
assert_has "comma+V-ing fires (, producing)"  'Comma \+ V-ing' "$OUT"
assert_has "because fires"                    'because' "$OUT"
assert_has "bare Table~\\ref fires (cleveref paper)" 'Bare' "$OUT"
assert_has "float [H] fires"                  'Float placement' "$OUT"
assert_has "straight quote fires"             'Straight quote' "$OUT"
assert_has "inline \\(...\\) fires"           'Inline math' "$OUT"
assert_not "', including' whitelisted"        'L2 .*Comma' "$OUT"
assert_not "', nothing' whitelisted"          'L3 .*Comma' "$OUT"
assert_not "'It is worth noting' stays OK (ruled 2026-06-12)" 'It is worth noting' "$OUT"
assert_not "'In this paper, we' stays OK (ruled 2026-06-12)"  'Template phrase' "$OUT"
assert_not "display math \\[...\\] stays OK (ruled 2026-06-12)" 'Display math' "$OUT"
assert_not "Specifically stays allowed"       'L7 ' "$OUT"

echo "── paper-x default mode (cyl regions scanned) ──"
OUT=$("$PAPERCTL" lint --dir "$TMP" --paper paper-x 2>&1)
assert_has "cyl-mode catches violations too"  'Casual conjunction' "$OUT"

echo "── paper-y --all (manual-ref dialect: bare \\ref must NOT fire) ──"
OUT=$("$PAPERCTL" lint --dir "$TMP" --paper paper-y --all 2>&1)
assert_not "Table~\\ref not flagged without cleveref" 'Bare' "$OUT"

echo "── paper-x --intro (\\item bullet, with line-number prefix) ──"
OUT=$("$PAPERCTL" lint --dir "$TMP" --paper paper-x --intro 2>&1)
assert_has "stray \\item flagged in intro"    'item bullet' "$OUT"

echo ""
echo "📊 $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
