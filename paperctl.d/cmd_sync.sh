#!/bin/bash
# paperctl.d/cmd_sync.sh -- Full bidirectional sync (pull + push all remotes)

load_config

echo "🔄 Full sync — pulling & pushing all repos..."
echo "   Conference: $CONF_NAME $CONF_YEAR ($CONF_SLUG)"
echo ""

_sync_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
  local branch
  branch=$(get_local_branch "$repo_dir")

  echo "=== Syncing $repo ==="

  # Fork repos: pull upstream first
  if is_fork "$upstream"; then
    echo "  📥 Pulling upstream..."
    git -C "$repo_dir" fetch "$CONF_UPSTREAM_REMOTE" 2>/dev/null
    if [[ -n "$CONF_UPSTREAM_BRANCH" ]]; then
      git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/$CONF_UPSTREAM_BRANCH" --no-edit 2>/dev/null
    else
      git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/main" --no-edit 2>/dev/null \
        || git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/master" --no-edit 2>/dev/null
    fi
  fi

  # Pull from origin + overleaf
  git -C "$repo_dir" pull origin "$branch" --no-rebase 2>/dev/null
  git -C "$repo_dir" pull "$CONF_OVERLEAF_REMOTE" "$CONF_OVERLEAF_BRANCH" --no-rebase

  # Push to origin + overleaf
  git -C "$repo_dir" push origin "$branch"
  git -C "$repo_dir" push "$CONF_OVERLEAF_REMOTE" "$branch:$CONF_OVERLEAF_BRANCH"

  echo "✅ $repo synced ($branch)"
  echo ""
}

for_each_paper _sync_paper

echo "🎉 All repos synced!"
