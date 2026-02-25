#!/bin/bash
# paperctl.d/cmd_check.sh -- Format compliance checker dispatcher

load_config
. "$PAPERCTL_LIB/lib_check.sh"

# Load template-specific checks
TEMPLATE_FILE="$PAPERCTL_LIB/templates/${CONF_TEMPLATE}.checks.sh"
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "❌ No format checker found for template: $CONF_TEMPLATE"
  echo "   Expected: $TEMPLATE_FILE"
  echo ""
  echo "Available templates:"
  ls "$PAPERCTL_LIB/templates/"*.checks.sh 2>/dev/null | while read f; do
    basename "$f" .checks.sh
  done
  exit 1
fi

. "$TEMPLATE_FILE"

# The template file must define: run_checks <repo_dir> <main_tex>
# It uses check_pass/check_warn/check_fail from lib_check.sh

print_check_banner "$CONF_NAME $CONF_YEAR Format Compliance Checker"

_check_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📄 $repo"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  reset_repo_counts

  # Find main tex
  local main_tex
  main_tex=$(find_main_tex "$repo_dir")

  if [[ -z "$main_tex" ]]; then
    check_fail "No main .tex file found!"
    flush_repo_counts
    echo ""
    return
  fi

  echo "  📎 Main file: $main_tex"

  # Collect all tex content
  local all_tex
  all_tex=$(collect_tex_content "$main_tex")

  # Run template-specific checks
  run_checks "$repo_dir" "$main_tex" "$all_tex"

  flush_repo_counts
  echo ""
}

for_each_paper _check_paper

print_check_summary
