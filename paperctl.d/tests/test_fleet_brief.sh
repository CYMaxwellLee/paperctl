#!/bin/bash
# paperctl.d/tests/test_fleet_brief.sh -- self-contained fixture test for
# `paperctl fleet-brief` (mirrors test_lint.sh's mktemp pattern: throwaway
# conference, no network, no real conference dir).
#
# One conference.json, two papers:
#   - paper-a ("dirty"): one lint violation (the professor's attested 'because'
#     ban, reused verbatim from test_lint.sh's own fixture line) + one undefined
#     cross-reference -> fleet-brief must exit 1, and the brief it writes (next to
#     the repo, not inside it) must contain a TASK CARDS section with >=1 card.
#   - paper-b ("clean"): no violations (professor text reused verbatim from
#     test_lint.sh's paper-z fixture), every reference resolves -> exit 0.
#
# Usage: bash paperctl.d/tests/test_fleet_brief.sh   (exit 0 = all assertions pass)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAPERCTL="$(cd "$TESTS_DIR/../.." && pwd)/paperctl"
TMP=$(mktemp -d /tmp/paperctl_fbfx.XXXXXX)
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()  { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
assert_has() { if grep -qE "$2" <<<"$3"; then ok "$1"; else bad "$1 (missing: $2)"; fi; }
assert_not() { if grep -qE "$2" <<<"$3"; then bad "$1 (unexpected: $2)"; else ok "$1"; fi; }
assert_rc()  { if [[ "$2" -eq "$3" ]]; then ok "$1"; else bad "$1 (rc=$2, want $3)"; fi; }

mkdir -p "$TMP"/paper-{a,b}/sections

cat > "$TMP/conference.json" <<'EOF'
{
  "conference": {"name": "testconf", "year": 2099, "slug": "testconf2099", "template": "none", "org": "none"},
  "defaults": {"github_branch": "main", "overleaf_branch": "master", "overleaf_remote": "overleaf", "upstream_remote": "upstream"},
  "papers": [
    {"name": "paper-a", "repo": "paper-a", "overleaf": "", "upstream": null},
    {"name": "paper-b", "repo": "paper-b", "overleaf": "", "upstream": null}
  ]
}
EOF

for p in a b; do
cat > "$TMP/paper-$p/main.tex" <<'EOF'
\documentclass{article}
\usepackage[capitalize,noabbrev]{cleveref}
\begin{document}
\input{sections/body}
\end{document}
EOF
done

# paper-a ("dirty"): one lint violation + one undefined cross-reference.
cat > "$TMP/paper-a/sections/body.tex" <<'EOF'
\section{Test}
\cyl{The seeds moved because the scheduler restarted.}
See Table~\ref{tab:missing} for the undefined cross-reference below.
EOF

# paper-b ("clean"): no violations, every reference resolves.
cat > "$TMP/paper-b/sections/body.tex" <<'EOF'
\section{Test}
\label{sec:test}
\cyl{The verified pipeline holds across every benchmark we report.}
As \cref{sec:test} shows, the setup stays clean.
EOF

echo "── paper-a (dirty): fleet-brief must exit 1, write a brief with TASK CARDS ──"
OUT=$("$PAPERCTL" fleet-brief --dir "$TMP" --paper paper-a 2>&1); RC=$?
assert_rc  "exit 1 when a sub-check has FAILs"       "$RC" 1
assert_has "terminal output shows at least one FAIL" '❌' "$OUT"
assert_has "overall summary flags action required"   'ACTION REQUIRED' "$OUT"

BRIEF=$(find "$TMP" -maxdepth 1 -name 'fleet-brief-paper-a-*.md' | head -1)
if [[ -n "$BRIEF" && -f "$BRIEF" ]]; then
  ok "brief markdown file was created next to the repo (not inside paper-a/)"
else
  bad "brief markdown file was NOT found directly under $TMP"
fi
if [[ -n "$BRIEF" ]]; then
  BRIEF_CONTENT=$(cat "$BRIEF")
  assert_has "brief header names the paper"                        'Fleet Brief: paper-a' "$BRIEF_CONTENT"
  assert_has "brief contains a TASK CARDS section"                  '^## TASK CARDS' "$BRIEF_CONTENT"
  assert_has "brief has at least one task card"                     '^### Card 1' "$BRIEF_CONTENT"
  assert_has "a card carries a Verify-with paperctl command"        'Verify-with:.*paperctl (ref-check|bib-check|lint)' "$BRIEF_CONTENT"
  assert_has "a card carries an Evidence line with the FAIL glyph"  'Evidence:.*❌' "$BRIEF_CONTENT"
  assert_has "the because-ban violation shows up as a FAIL line"    'because' "$BRIEF_CONTENT"
  assert_has "the undefined cross-reference shows up as a FAIL line" 'tab:missing' "$BRIEF_CONTENT"
fi

echo "── paper-b (clean): fleet-brief must exit 0 ──"
OUT=$("$PAPERCTL" fleet-brief --dir "$TMP" --paper paper-b 2>&1); RC=$?
assert_rc  "clean paper exits 0"                    "$RC" 0
assert_not "clean run does not flag action required" 'ACTION REQUIRED' "$OUT"

echo ""
echo "📊 $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
