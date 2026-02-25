#!/bin/bash
# paperctl.d/lib_check.sh -- Shared utilities for format checking

# Counters (per-repo and global)
REPO_PASS=0; REPO_WARN=0; REPO_FAIL=0
TOTAL_PASS=0; TOTAL_WARN=0; TOTAL_FAIL=0

check_pass() {
  echo "  ✅ $1"
  REPO_PASS=$((REPO_PASS + 1))
}

check_warn() {
  echo "  ⚠️  WARN: $1"
  REPO_WARN=$((REPO_WARN + 1))
}

check_fail() {
  echo "  ❌ FAIL: $1"
  REPO_FAIL=$((REPO_FAIL + 1))
}

check_info() {
  echo "  ℹ️  $1"
}

reset_repo_counts() {
  REPO_PASS=0; REPO_WARN=0; REPO_FAIL=0
}

flush_repo_counts() {
  echo ""
  echo "  📊 Result: ✅ $REPO_PASS pass | ⚠️  $REPO_WARN warn | ❌ $REPO_FAIL fail"
  TOTAL_PASS=$((TOTAL_PASS + REPO_PASS))
  TOTAL_WARN=$((TOTAL_WARN + REPO_WARN))
  TOTAL_FAIL=$((TOTAL_FAIL + REPO_FAIL))
}

# Find main tex file in a repo directory
# Searches root first, then common subdirs (e.g. ECCV_submission/)
find_main_tex() {
  local repo_dir="$1"
  local result=""

  # 1. Check root-level main.tex / paper.tex
  if [[ -f "$repo_dir/main.tex" ]]; then
    echo "$repo_dir/main.tex"
    return
  fi
  if [[ -f "$repo_dir/paper.tex" ]]; then
    echo "$repo_dir/paper.tex"
    return
  fi

  # 2. Search root-level .tex files for \documentclass
  result=$(find "$repo_dir" -maxdepth 1 -name "*.tex" -exec grep -l '\\documentclass' {} + 2>/dev/null | head -1) || true
  if [[ -n "$result" ]]; then
    echo "$result"
    return
  fi

  # 3. Search one level deeper (e.g. ECCV_submission/main.tex)
  result=$(find "$repo_dir" -maxdepth 2 -name "main.tex" -not -path "*/.git/*" 2>/dev/null | head -1) || true
  if [[ -n "$result" ]]; then
    echo "$result"
    return
  fi
  result=$(find "$repo_dir" -maxdepth 2 -name "paper.tex" -not -path "*/.git/*" 2>/dev/null | head -1) || true
  if [[ -n "$result" ]]; then
    echo "$result"
    return
  fi

  # 4. Last resort: any .tex with \documentclass up to depth 2
  result=$(find "$repo_dir" -maxdepth 2 -name "*.tex" -not -path "*/.git/*" -exec grep -l '\\documentclass' {} + 2>/dev/null | head -1) || true
  if [[ -n "$result" ]]; then
    echo "$result"
    return
  fi

  # Nothing found — return empty
  echo ""
}

# Collect all tex content (main + \input'd files)
collect_tex_content() {
  local main_tex="$1"
  local repo_dir
  repo_dir=$(dirname "$main_tex")
  local files=("$main_tex")

  # Find \input{...} references (macOS compatible — no grep -P)
  local input_refs
  input_refs=$(grep -o '\\input{[^}]*}' "$main_tex" 2>/dev/null | sed 's/\\input{//;s/}//' || true)

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    for ext in "" ".tex"; do
      if [[ -f "$repo_dir/$f$ext" ]]; then
        files+=("$repo_dir/$f$ext")
        break
      fi
    done
  done <<< "$input_refs"

  cat "${files[@]}" 2>/dev/null || true
}

print_check_banner() {
  local title="$1"
  echo "╔══════════════════════════════════════════════════════╗"
  printf "║  %-52s║\n" "$title"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""
}

print_check_summary() {
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║                  OVERALL SUMMARY                    ║"
  echo "╠══════════════════════════════════════════════════════╣"
  printf "║  ✅ Pass: %-42s║\n" "$TOTAL_PASS"
  printf "║  ⚠️  Warn: %-42s║\n" "$TOTAL_WARN"
  printf "║  ❌ Fail: %-42s║\n" "$TOTAL_FAIL"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""
  if [[ $TOTAL_FAIL -gt 0 ]]; then
    echo "🚨 ACTION REQUIRED: $TOTAL_FAIL format issues must be fixed before submission!"
  else
    echo "🎉 All repos pass format checks!"
  fi
}
