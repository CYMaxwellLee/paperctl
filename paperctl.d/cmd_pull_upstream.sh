#!/bin/bash
# paperctl.d/cmd_pull_upstream.sh -- Pull from upstream (fork repos only)

load_config

echo "📥 Pulling from upstream (fork repos)..."
echo "   Conference: $CONF_NAME $CONF_YEAR ($CONF_SLUG)"
echo ""

_pull_upstream_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
  local branch
  branch=$(get_local_branch "$repo_dir")

  # Skip non-fork repos
  if ! is_fork "$upstream"; then
    return
  fi

  echo "=== Syncing upstream for $repo ==="

  git -C "$repo_dir" fetch "$CONF_UPSTREAM_REMOTE" 2>/dev/null
  if [[ -n "$CONF_UPSTREAM_BRANCH" ]]; then
    git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/$CONF_UPSTREAM_BRANCH" --no-edit 2>/dev/null
  else
    git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/main" --no-edit 2>/dev/null \
      || git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/master" --no-edit 2>/dev/null
  fi

  git -C "$repo_dir" push origin "$branch"
  git -C "$repo_dir" push "$CONF_OVERLEAF_REMOTE" "$branch:$CONF_OVERLEAF_BRANCH"

  echo "✅ $repo: upstream merged & pushed ($branch)"
  echo ""
}

for_each_paper _pull_upstream_paper

echo "🎉 Fork repos synced with upstream!"
