#!/bin/bash
# paperctl.d/cmd_preflight.sh -- Submission preflight checklist
#
# Final checks before submission:
#   1. Anonymity: no author names/affiliations leaked
#   2. Page count: within limit (14 for ECCV)
#   3. Review mode: line numbers enabled
#   4. No TODO/FIXME markers left
#   5. No supplementary in main PDF (\input{X_suppl} should be removed)
#   6. Overleaf conflict check (dry-run merge)
#   7. All figures/tables referenced
#   8. No debugging artifacts (\textcolor{red}, \hl{}, \todo{})
#
# Usage: paperctl preflight [--paper <name>]

load_config
. "$PAPERCTL_LIB/lib_check.sh"

_preflight_paper() {
  set +e
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $name ($repo)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  reset_repo_counts

  local main_tex
  main_tex=$(find_main_tex "$repo_dir")
  if [[ -z "$main_tex" ]]; then
    check_warn "No main .tex found, skipping"
    flush_repo_counts
    echo ""
    return
  fi

  local tex_dir
  tex_dir=$(dirname "$main_tex")

  # Collect raw tex (with comments, for scanning TODO etc.)
  local raw_tex=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    raw_tex+="$(cat "$f" 2>/dev/null)"$'\n'
  done < <(find "$tex_dir" -name "*.tex" -not -path "*/_clean/*" -not -path "*/.git/*" 2>/dev/null)

  # Also get comment-stripped version
  local py_helper
  py_helper=$(mktemp /tmp/paperctl_collect.XXXXXX.py)
  cat > "$py_helper" << 'PYEOF'
import os, sys
repo_dir = sys.argv[1]
main_tex = sys.argv[2]
tex_dir = os.path.dirname(main_tex)
visited = set()
def resolve_file(path, base_dirs):
    for bdir in base_dirs:
        for ext in ['', '.tex']:
            candidate = os.path.join(bdir, path + ext)
            if os.path.isfile(candidate):
                return candidate
    return None
def find_inputs(text):
    results = []
    marker = '\\input{'
    start = 0
    while True:
        idx = text.find(marker, start)
        if idx == -1: break
        brace_start = idx + len(marker)
        brace_end = text.find('}', brace_start)
        if brace_end == -1: break
        results.append((idx, brace_end + 1, text[brace_start:brace_end]))
        start = brace_end + 1
    return results
def collect(filepath, base_dirs):
    filepath = os.path.realpath(filepath)
    if filepath in visited: return ''
    visited.add(filepath)
    if not os.path.isfile(filepath): return ''
    with open(filepath) as f: content = f.read()
    lines = []
    for line in content.split('\n'):
        if line.lstrip().startswith('%'): continue
        idx = -1
        for i, ch in enumerate(line):
            if ch == '%' and (i == 0 or line[i-1] != '\\'): idx = i; break
        lines.append(line[:idx] if idx > 0 else line)
    clean = '\n'.join(lines)
    for full_start, full_end, inp in reversed(find_inputs(clean)):
        resolved = resolve_file(inp, base_dirs)
        if resolved:
            clean = clean[:full_start] + collect(resolved, base_dirs) + clean[full_end:]
    return clean
print(collect(main_tex, list(set([tex_dir, repo_dir]))))
PYEOF
  local all_tex
  all_tex=$(python3 "$py_helper" "$repo_dir" "$main_tex")
  rm -f "$py_helper"

  # ============================================================
  # 1. Anonymity check
  # ============================================================
  local anon_violations=()
  # Check for non-anonymous author
  if echo "$all_tex" | grep -q '\\author{' && ! echo "$all_tex" | grep -qi '\\author{.*anonymous'; then
    anon_violations+=("\\author{} is not anonymous")
  fi
  # Check for institute/affiliation
  if echo "$all_tex" | grep -qi '\\institute{[^}]'; then
    local inst
    inst=$(echo "$all_tex" | grep -i '\\institute{' | head -1 | sed 's/^[[:space:]]*//' | head -c 60)
    anon_violations+=("\\institute found: $inst")
  fi
  # Check for "our lab/university" type leaks
  if echo "$all_tex" | grep -qiE '\\(thanks|footnote)\{.*\b(university|institute|lab|department)\b'; then
    anon_violations+=("Possible affiliation in footnote/thanks")
  fi

  if [[ ${#anon_violations[@]} -gt 0 ]]; then
    check_warn "Anonymity concerns (${#anon_violations[@]}):"
    for v in "${anon_violations[@]}"; do
      echo "         $v"
    done
  else
    check_pass "Anonymity: OK"
  fi

  # ============================================================
  # 2. TODO/FIXME markers
  # ============================================================
  local todo_count
  todo_count=$(echo "$raw_tex" | grep -ciE '\\todo\b|TODO|FIXME|XXX|HACK' || true)
  [[ -z "$todo_count" ]] && todo_count=0

  if [[ "$todo_count" -gt 0 ]]; then
    check_warn "TODO/FIXME markers: $todo_count found"
    echo "$raw_tex" | grep -inE '\\todo\b|TODO|FIXME|XXX|HACK' | head -5 | while IFS= read -r line; do
      echo "         $(echo "$line" | sed 's/^[[:space:]]*//' | head -c 80)"
    done
  else
    check_pass "No TODO/FIXME markers"
  fi

  # ============================================================
  # 3. Supplementary inclusion check
  # ============================================================
  if echo "$all_tex" | grep -q '\\input{.*suppl\|\\include{.*suppl'; then
    check_warn "Supplementary included in main PDF (remove before submission)"
    echo "$all_tex" | grep '\\input{.*suppl\|\\include{.*suppl' | head -3 | while IFS= read -r line; do
      echo "         $(echo "$line" | sed 's/^[[:space:]]*//' | head -c 80)"
    done
  else
    check_pass "No supplementary in main PDF"
  fi

  # ============================================================
  # 4. Debug artifacts
  # ============================================================
  local debug_patterns='\\textcolor{red}|\\hl{|\\colorbox{|\\fcolorbox{'
  local debug_count
  debug_count=$(echo "$all_tex" | grep -cE "$debug_patterns" || true)
  [[ -z "$debug_count" ]] && debug_count=0

  if [[ "$debug_count" -gt 0 ]]; then
    check_warn "Debug artifacts: $debug_count (\\textcolor{red}, \\hl{}, etc.)"
  else
    check_pass "No debug artifacts"
  fi

  # ============================================================
  # 5. Overleaf conflict check (dry-run)
  # ============================================================
  if [[ -n "$overleaf" && "$overleaf" != "null" ]]; then
    local ol_remote
    ol_remote="$CONF_OVERLEAF_REMOTE"
    local ol_branch
    ol_branch="$CONF_OVERLEAF_BRANCH"

    if git -C "$repo_dir" remote get-url "$ol_remote" &>/dev/null; then
      # Fetch without merge
      git -C "$repo_dir" fetch "$ol_remote" "$ol_branch" --quiet 2>/dev/null || true

      local local_head ol_head merge_base
      local_head=$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null)
      ol_head=$(git -C "$repo_dir" rev-parse "$ol_remote/$ol_branch" 2>/dev/null || echo "")

      if [[ -n "$ol_head" && "$local_head" != "$ol_head" ]]; then
        merge_base=$(git -C "$repo_dir" merge-base HEAD "$ol_remote/$ol_branch" 2>/dev/null || echo "")
        if [[ "$merge_base" == "$ol_head" ]]; then
          check_pass "Overleaf: local is ahead (safe to push)"
        elif [[ "$merge_base" == "$local_head" ]]; then
          check_warn "Overleaf: remote has new commits (pull first)"
        else
          # Check for actual conflicts
          local conflict_check
          conflict_check=$(git -C "$repo_dir" merge-tree "$merge_base" HEAD "$ol_remote/$ol_branch" 2>/dev/null | grep -c "^<<<<<<<" || true)
          [[ -z "$conflict_check" ]] && conflict_check=0
          if [[ "$conflict_check" -gt 0 ]]; then
            check_fail "Overleaf: CONFLICTS detected ($conflict_check files)"
          else
            check_warn "Overleaf: diverged but auto-mergeable"
          fi
        fi
      else
        check_pass "Overleaf: in sync"
      fi
    else
      check_info "Overleaf remote not configured"
    fi
  fi

  # ============================================================
  # 6. Upstream (student fork) conflict check
  # ============================================================
  if [[ -n "$upstream" && "$upstream" != "null" ]]; then
    local us_remote="$CONF_UPSTREAM_REMOTE"
    local us_branch="${CONF_UPSTREAM_BRANCH:-main}"

    if git -C "$repo_dir" remote get-url "$us_remote" &>/dev/null; then
      git -C "$repo_dir" fetch "$us_remote" "$us_branch" --quiet 2>/dev/null || true

      local us_head
      us_head=$(git -C "$repo_dir" rev-parse "$us_remote/$us_branch" 2>/dev/null || echo "")
      local local_head
      local_head=$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null)

      if [[ -n "$us_head" && "$local_head" != "$us_head" ]]; then
        local us_merge_base
        us_merge_base=$(git -C "$repo_dir" merge-base HEAD "$us_remote/$us_branch" 2>/dev/null || echo "")
        if [[ "$us_merge_base" != "$us_head" && "$us_merge_base" != "$local_head" ]]; then
          local us_conflict
          us_conflict=$(git -C "$repo_dir" merge-tree "$us_merge_base" HEAD "$us_remote/$us_branch" 2>/dev/null | grep -c "^<<<<<<<" || true)
          [[ -z "$us_conflict" ]] && us_conflict=0
          if [[ "$us_conflict" -gt 0 ]]; then
            check_fail "Upstream: CONFLICTS detected ($us_conflict files)"
          else
            check_info "Upstream: diverged but auto-mergeable"
          fi
        elif [[ "$us_merge_base" == "$local_head" ]]; then
          check_warn "Upstream: student has new commits (sync first)"
        fi
      fi
    fi
  fi

  flush_repo_counts
  echo ""
  set -e
}

print_check_banner "Submission Preflight"

for_each_paper _preflight_paper

print_check_summary
