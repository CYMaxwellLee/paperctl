#!/bin/bash
# paperctl.d/cmd_push.sh -- Commit & push repos that have changes

load_config

MSG="${1:-chore: batch update}"

echo "📤 Pushing changes: \"$MSG\""
echo "   Conference: $CONF_NAME $CONF_YEAR ($CONF_SLUG)"
echo ""

_push_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
  local branch
  branch=$(get_local_branch "$repo_dir")

  if [[ -n "$(git -C "$repo_dir" status --porcelain)" ]]; then
    echo "=== Pushing $repo ==="
    git -C "$repo_dir" add -A
    git -C "$repo_dir" commit -m "$MSG"
    git -C "$repo_dir" push origin "$branch"
    git -C "$repo_dir" push "$CONF_OVERLEAF_REMOTE" "$branch:$CONF_OVERLEAF_BRANCH"
    echo "✅ $repo pushed ($branch)"
  else
    echo "⏭️  $repo: no changes"
  fi
  echo ""
}

for_each_paper _push_paper

echo "🎉 All repos processed!"
