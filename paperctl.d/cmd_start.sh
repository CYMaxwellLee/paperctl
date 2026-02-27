#!/bin/bash
# paperctl.d/cmd_start.sh -- Pre-session sync (pull all remotes)

load_config

echo "🚀 Starting work session — syncing all repos..."
echo "   Conference: $CONF_NAME $CONF_YEAR ($CONF_SLUG)"
echo ""

# Save pre-sync state for later comparison (used by `paperctl report`)
save_pre_sync_state
echo ""

_start_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
  local branch
  branch=$(get_local_branch "$repo_dir")

  echo "=== $repo ==="

  # Fork repos: sync upstream first
  if is_fork "$upstream"; then
    echo "  📥 Fetching upstream..."
    git -C "$repo_dir" fetch "$CONF_UPSTREAM_REMOTE" 2>/dev/null
    local _merged=false
    if [[ -n "$CONF_UPSTREAM_BRANCH" ]]; then
      git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/$CONF_UPSTREAM_BRANCH" --no-edit 2>/dev/null && _merged=true
    else
      { git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/main" --no-edit 2>/dev/null \
        || git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/master" --no-edit 2>/dev/null; } && _merged=true
    fi
    if [[ "$_merged" == "true" ]]; then
      echo "  ✅ Upstream merged"
    else
      echo "  ⚠️  CONFLICT with upstream! Resolve before editing."
    fi
  fi

  # Pull from origin + overleaf
  git -C "$repo_dir" pull origin "$branch" --no-rebase 2>/dev/null
  git -C "$repo_dir" pull "$CONF_OVERLEAF_REMOTE" "$CONF_OVERLEAF_BRANCH" --no-rebase

  echo "✅ $repo ready ($branch)"
  echo ""
}

for_each_paper _start_paper

echo "🎉 All repos up to date. Start working!"
