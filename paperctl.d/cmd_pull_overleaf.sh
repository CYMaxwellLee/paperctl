#!/bin/bash
# paperctl.d/cmd_pull_overleaf.sh -- Pull latest from Overleaf

load_config

echo "📥 Pulling from Overleaf..."
echo "   Conference: $CONF_NAME $CONF_YEAR ($CONF_SLUG)"
echo ""

_pull_overleaf_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
  local branch
  branch=$(get_local_branch "$repo_dir")

  echo "=== Pulling $repo from Overleaf ==="
  git -C "$repo_dir" pull "$CONF_OVERLEAF_REMOTE" "$CONF_OVERLEAF_BRANCH" --no-rebase
  echo "✅ $repo pulled ($branch)"
  echo ""
}

for_each_paper _pull_overleaf_paper

echo "🎉 All repos updated from Overleaf!"
