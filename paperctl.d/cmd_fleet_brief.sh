#!/bin/bash
# paperctl.d/cmd_fleet_brief.sh -- Composite fleet status brief (v0)
#
# Composes THREE existing read-only checks per paper -- ref-check, bib-check, lint --
# without reimplementing any of their logic, and aggregates the result into:
#   (a) a terminal summary banner per paper (pass/warn/fail counts per sub-check,
#       using the check_* vocabulary from lib_check.sh)
#   (b) a markdown "fleet brief" file per paper, written NEXT TO the paper repos
#       (one level up from repo_dir, i.e. the conference workspace dir -- never
#       inside the git repo itself), containing a FAIL/WARN section per sub-check
#       (captured verbatim) and a TASK CARDS section (one card per FAIL item:
#       Goal / Evidence / File hint / Verify-with) meant for dispatching worker
#       agents against.
#
# Isolation note: the main `paperctl` script dispatches every command by SOURCING
# its cmd_*.sh file (". $PAPERCTL_LIB/cmd_x.sh", not exec/subshell) -- fine for a
# leaf command, but cmd_lint.sh ends with a bare top-level `exit 0`/`exit 1`, so
# sourcing it directly in-process here would terminate fleet-brief itself before it
# could run bib-check or write anything. Every sub-check below therefore runs in an
# explicit `( ... )` subshell, with its own scoped PAPERCTL_PAPER, so its `exit`
# (and any load_config/flag-parsing side effects) stay contained to that subshell.
#
# Vocabulary note: none of the three composed commands actually call lib_check.sh's
# check_pass/check_warn/check_fail for their substantive per-item results (only for
# a couple of early-exit branches, e.g. "no main.tex found") -- bib-check/ref-check
# print matching "  ✅ ...", "  ⚠️  WARN: ...", "  ❌ FAIL: ..." lines from an inline
# python heredoc instead, and never call flush_repo_counts/print_check_summary, so
# their OWN exit code is always 0 regardless of FAILs found. lint.sh prints "❌"/
# "⚠️ " per violation too, but without the literal words FAIL:/WARN:, and DOES exit 1
# when any fail-severity rule fires. Given that mix, this command's pass/warn/fail
# counts and its own exit code are derived by grepping each sub-check's captured
# stdout for the shared glyph vocabulary (✅ / ⚠️  / ❌), not by trusting the
# sub-check's own exit code alone -- see _fb_count/_fb_extract below.
#
# v0 scope:
#   - Does not run `compile` (slow: pdflatex+bibtex, unlike the other three, which
#     are fast and read-only). --with-compile is accepted but is a documented no-op
#     stub for now; see the TODO next to its flag-parsing arm.
#   - Runs ref-check/bib-check/lint with their own defaults (e.g. bib-check's
#     --unused is never passed); v0 does not expose their individual flags.
#
# Usage:
#   paperctl fleet-brief                        # all papers
#   paperctl fleet-brief --paper <name>          # single paper
#   paperctl fleet-brief --with-compile          # accepted, currently a no-op (TODO)

load_config
. "$PAPERCTL_LIB/lib_check.sh"

WITH_COMPILE=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --with-compile)
      # TODO(v1): also run `paperctl compile --paper <name> --dir <CONF_DIR>` per
      # paper (see cmd_compile.sh) and fold a pass/fail line for it into both the
      # terminal summary and the brief's sections. Left unimplemented in v0 because
      # compile is a full pdflatex+bibtex cycle -- much slower than the other three
      # read-only checks -- so wiring it in naively would make plain `fleet-brief`
      # (all papers, no flag) slow by default; needs its own opt-in gate, which is
      # exactly what this flag is reserved for.
      WITH_COMPILE=true; shift ;;
    *) break ;;
  esac
done

if $WITH_COMPILE; then
  check_info "--with-compile is not implemented yet (v0 TODO) -- compile is skipped"
fi

# ============================================================
# Sub-check runner (isolated subshell)
# ============================================================

# Runs one existing cmd_<x>.sh for ONE paper, the same way the main `paperctl`
# script would (source lib.sh, then the cmd file), but inside a subshell so its
# `exit` (cmd_lint.sh) and its load_config/flag-parsing side effects never touch
# this process. Scopes the sub-check to a single paper via a subshell-local
# PAPERCTL_PAPER, regardless of what --paper (if any) was passed to fleet-brief
# itself. Clears positional params first so lib.sh's universal --help scan and the
# cmd file's own flag-parsing loop both see "no args" (v0 always runs each
# sub-check with its defaults). Captures stdout+stderr together so nothing a
# sub-check prints is silently lost.
_fb_run_subcheck() {
  local cmd_file="$1" paper_name="$2"
  (
    PAPERCTL_PAPER="$paper_name"
    export PAPERCTL_PAPER
    set --
    . "$PAPERCTL_LIB/lib.sh"
    . "$PAPERCTL_LIB/$cmd_file"
  ) 2>&1
}

# ============================================================
# Vocabulary parsing (grep the check_* glyphs a sub-check already printed)
# ============================================================

# Counts lines that open (after optional indent) with the given glyph -- i.e. an
# actual per-item check_* result line. Excludes cmd_lint.sh's own final tally line
# ("N fail-severity violation(s) -- exit 1"), which also starts with the FAIL glyph
# and would otherwise be double-counted on top of every per-violation line it is
# summing. The trailing `|| true` absorbs grep's exit 1 for zero matches (this file
# runs under the caller's `set -e`, inherited from the main paperctl script).
_fb_count() {
  local text="$1" glyph="$2"
  printf '%s\n' "$text" | grep -v 'fail-severity violation' | grep -cE "^[[:space:]]*${glyph}" || true
}

# Same idea as _fb_count but returns the matching lines verbatim instead of a
# count (used both for the brief's FAIL/WARN sections and, via _fb_pairs_flat /
# _fb_lint_pairs below, for the TASK CARDS).
_fb_extract() {
  local text="$1" glyph="$2"
  printf '%s\n' "$text" | grep -v 'fail-severity violation' | grep -E "^[[:space:]]*${glyph}" || true
}

# ref-check/bib-check report by citation/label key across the whole paper -- they
# never print which file a given match came from. So every FAIL line from one of
# them is paired with the same constant file hint (the paper's main .tex, resolved
# once by the caller via find_main_tex -- the same helper ref-check/bib-check
# themselves call). Emits "file<TAB>fail-line" rows.
_fb_pairs_flat() {
  local out="$1" file_hint="$2"
  local fails
  fails=$(_fb_extract "$out" '❌')
  [[ -z "$fails" ]] && return 0
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    printf '%s\t%s\n' "$file_hint" "$line"
  done <<< "$fails"
  return 0
}

# Best-effort file attribution for lint's FAIL lines: cmd_lint.sh prints a
# "  <rel_path>:" header immediately before that file's violation lines (see its
# file_header_printed logic) whenever --cyl/--all scanning finds something in that
# file. We remember the most recently seen such header while scanning lint's raw
# captured output line-by-line (using a here-string, not a piped while-read, so the
# running "last_path" state survives across iterations in THIS shell) and pair it
# with each FAIL-glyph line as we reach it. This reads lint's own printed grouping;
# it does not re-derive anything lint didn't already report. Presentation-only,
# best-effort: a header line that doesn't match the assumed "  text:" shape (it
# always does, in the current cmd_lint.sh) would just leave the fallback label in
# place for whatever follows. Emits "file<TAB>fail-line" rows, FAIL glyph only.
_fb_lint_pairs() {
  local out="$1"
  local last_path="(file not attributed by lint output)"
  local line
  while IFS= read -r line; do
    if [[ "$line" == *"fail-severity violation"* ]]; then
      continue  # lint's own final tally line -- not a per-item result, not a header
    elif [[ "$line" == *"❌"* ]]; then
      printf '%s\t%s\n' "$last_path" "$line"
    elif [[ "$line" == *"⚠️"* ]]; then
      :  # a warn line -- not a header, and cards are FAIL-only, nothing to do
    elif [[ "$line" == "  "*":" ]]; then
      last_path="${line#  }"
      last_path="${last_path%:}"
    fi
  done <<< "$out"
  return 0
}

# ============================================================
# TASK CARDS
# ============================================================

# Emits one "### Card N (<subcheck>)" block per row of $1 (tab-separated
# "file<TAB>fail-line" pairs, FAIL glyph only, from _fb_pairs_flat/_fb_lint_pairs).
# Numbers continuously across all three sub-checks for one paper via the shared
# global _FB_CARD_N (reset by the caller, _fb_write_brief, once per paper). Meant
# for dispatching worker agents: Goal is the FAIL line's own message (glyph/prefix
# stripped, so it stays grounded in what the sub-check actually printed rather than
# a paraphrase); Evidence is that same line completely verbatim; Verify-with is the
# exact paperctl invocation (with --dir, so it is runnable from anywhere) that must
# go green to close the card.
_fb_emit_cards_from_pairs() {
  local pairs="$1" subcheck="$2" name="$3" conf_dir="$4"
  [[ -z "$pairs" ]] && return 0
  local file line goal
  while IFS=$'\t' read -r file line; do
    [[ -z "$line" ]] && continue
    _FB_CARD_N=$((_FB_CARD_N + 1))
    goal=$(printf '%s' "$line" | sed -E 's/^[[:space:]]*❌[[:space:]]*(FAIL:[[:space:]]*)?//')
    echo "### Card $_FB_CARD_N ($subcheck)"
    echo ""
    echo "- Goal: Fix -- $goal"
    echo "- Evidence: \`$line\`"
    echo "- File hint: $file"
    echo "- Verify-with: \`paperctl $subcheck --paper $name --dir \"$conf_dir\"\`"
    echo ""
  done <<< "$pairs"
  return 0
}

# ============================================================
# Markdown brief
# ============================================================

# Appends one "## <label>" section (FAIL then WARN lines, verbatim, or "(none)")
# for one sub-check's captured output. Caller composes several of these inside one
# `{ ...; } > file` redirect block that builds the whole brief.
_fb_write_section() {
  local label="$1" out="$2"
  local fails warns
  fails=$(_fb_extract "$out" '❌')
  warns=$(_fb_extract "$out" '⚠️')
  echo "## $label"
  echo ""
  echo "FAIL:"
  echo ""
  if [[ -n "$fails" ]]; then
    echo '```'
    printf '%s\n' "$fails"
    echo '```'
  else
    echo "(none)"
  fi
  echo ""
  echo "WARN:"
  echo ""
  if [[ -n "$warns" ]]; then
    echo '```'
    printf '%s\n' "$warns"
    echo '```'
  else
    echo "(none)"
  fi
  echo ""
}

# Writes the markdown brief for one paper to <conference-dir>/fleet-brief-<paper>-
# <YYYYMMDD-HHMM>.md -- one level up from repo_dir (i.e. next to the repo, NEVER
# inside it; see lib.sh's for_each_paper, which sets repo_dir="$CONF_DIR/$repo") --
# and echoes the path it wrote on stdout. Sections: header (paper name / generated
# timestamp / repo HEAD), one "## <subcheck>" per sub-check with its FAIL/WARN
# lines verbatim, then "## TASK CARDS" (one card per FAIL item, across all three).
_fb_write_brief() {
  local name="$1" repo_dir="$2" refcheck_out="$3" bibcheck_out="$4" lint_out="$5" main_tex="$6" conf_dir="$7"
  local brief_dir head_sha ts brief_path file_hint
  brief_dir=$(dirname "$repo_dir")
  head_sha=$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null || echo "unknown")
  ts=$(date "+%Y%m%d-%H%M")
  brief_path="$brief_dir/fleet-brief-${name}-${ts}.md"
  if [[ -n "$main_tex" ]]; then
    file_hint="$main_tex"
  else
    file_hint="(no main .tex found)"
  fi

  _FB_CARD_N=0
  local rc_pairs bc_pairs li_pairs

  {
    echo "# Fleet Brief: $name"
    echo ""
    echo "- Generated: $(date "+%Y-%m-%d %H:%M:%S %z")"
    echo "- Paper: $name"
    echo "- Repo: $repo_dir"
    echo "- Repo HEAD: $head_sha"
    echo ""
    _fb_write_section "ref-check" "$refcheck_out"
    _fb_write_section "bib-check" "$bibcheck_out"
    _fb_write_section "lint" "$lint_out"
    echo "## TASK CARDS"
    echo ""
    rc_pairs=$(_fb_pairs_flat "$refcheck_out" "$file_hint")
    bc_pairs=$(_fb_pairs_flat "$bibcheck_out" "$file_hint")
    li_pairs=$(_fb_lint_pairs "$lint_out")
    _fb_emit_cards_from_pairs "$rc_pairs" "ref-check" "$name" "$conf_dir"
    _fb_emit_cards_from_pairs "$bc_pairs" "bib-check" "$name" "$conf_dir"
    _fb_emit_cards_from_pairs "$li_pairs" "lint" "$name" "$conf_dir"
    if [[ "$_FB_CARD_N" -eq 0 ]]; then
      echo "(no FAIL items -- nothing to dispatch)"
      echo ""
    fi
  } > "$brief_path"

  echo "$brief_path"
}

# ============================================================
# Per-paper composer
# ============================================================

FLEET_BRIEF_ANY_FAIL=false

_fleet_brief_one() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  print_check_banner "Fleet Brief: $name"

  local main_tex
  main_tex=$(find_main_tex "$repo_dir")

  local refcheck_out bibcheck_out lint_out
  local refcheck_rc bibcheck_rc lint_rc

  if refcheck_out=$(_fb_run_subcheck "cmd_refcheck.sh" "$name"); then
    refcheck_rc=0
  else
    refcheck_rc=$?
  fi
  if bibcheck_out=$(_fb_run_subcheck "cmd_bibcheck.sh" "$name"); then
    bibcheck_rc=0
  else
    bibcheck_rc=$?
  fi
  if lint_out=$(_fb_run_subcheck "cmd_lint.sh" "$name"); then
    lint_rc=0
  else
    lint_rc=$?
  fi

  local rc_pass rc_warn rc_fail bc_pass bc_warn bc_fail li_pass li_warn li_fail
  rc_pass=$(_fb_count "$refcheck_out" '✅');  rc_warn=$(_fb_count "$refcheck_out" '⚠️');  rc_fail=$(_fb_count "$refcheck_out" '❌')
  bc_pass=$(_fb_count "$bibcheck_out" '✅');  bc_warn=$(_fb_count "$bibcheck_out" '⚠️');  bc_fail=$(_fb_count "$bibcheck_out" '❌')
  li_pass=$(_fb_count "$lint_out" '✅');      li_warn=$(_fb_count "$lint_out" '⚠️');      li_fail=$(_fb_count "$lint_out" '❌')

  echo "    ref-check : ✅ $rc_pass pass | ⚠️  $rc_warn warn | ❌ $rc_fail fail"
  echo "    bib-check : ✅ $bc_pass pass | ⚠️  $bc_warn warn | ❌ $bc_fail fail"
  echo "    lint      : ✅ $li_pass pass | ⚠️  $li_warn warn | ❌ $li_fail fail"

  # Roll the per-sub-check counts up into one per-paper total via the SAME shared
  # counters/printer the rest of the tool uses (lib_check.sh's flush_repo_counts),
  # which also folds this paper into the grand TOTAL_* for print_check_summary at
  # the very end of the whole command.
  reset_repo_counts
  REPO_PASS=$((rc_pass + bc_pass + li_pass))
  REPO_WARN=$((rc_warn + bc_warn + li_warn))
  REPO_FAIL=$((rc_fail + bc_fail + li_fail))
  flush_repo_counts

  local brief_path
  brief_path=$(_fb_write_brief "$name" "$repo_dir" "$refcheck_out" "$bibcheck_out" "$lint_out" "$main_tex" "$CONF_DIR")
  echo "  📝 Brief written: $brief_path"
  echo ""

  # Text-derived fail count is the primary signal (bib-check/ref-check always exit
  # 0 regardless of FAILs -- see the vocabulary note up top); a nonzero sub-check
  # exit code is a defensive extra, so a sub-check that crashes outright (no ❌
  # printed at all) still marks this paper -- and the whole run -- as failed.
  if [[ "$REPO_FAIL" -gt 0 || "$refcheck_rc" -ne 0 || "$bibcheck_rc" -ne 0 || "$lint_rc" -ne 0 ]]; then
    FLEET_BRIEF_ANY_FAIL=true
  fi
}

echo ""
print_check_banner "Fleet Brief (ref-check + bib-check + lint)"
for_each_paper _fleet_brief_one
echo ""
print_check_summary
echo ""
echo "Done."

if $FLEET_BRIEF_ANY_FAIL; then
  exit 1
fi
exit 0
