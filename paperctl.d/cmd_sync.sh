#!/bin/bash
# paperctl.d/cmd_sync.sh -- Full bidirectional sync (pull + push all remotes)

# --- Flag parsing ---
PARALLEL=false
AUTO_RESOLVE=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --parallel) PARALLEL=true; shift ;;
    --auto-resolve) AUTO_RESOLVE=true; shift ;;
    --paper) PAPERCTL_PAPER="$2"; export PAPERCTL_PAPER; shift 2 ;;
    --dir) PAPERCTL_DIR="$2"; export PAPERCTL_DIR; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

load_config

echo "🔄 Full sync — pulling & pushing all repos..."
echo "   Conference: $CONF_NAME $CONF_YEAR ($CONF_SLUG)"
[[ "$PARALLEL" == "true" ]] && echo "   Mode: parallel"
[[ "$AUTO_RESOLVE" == "true" ]] && echo "   Auto-resolve: enabled"
echo ""

# --- Merge helper with conflict auto-resolution ---
_try_merge() {
  local repo_dir="$1" label="$2"
  shift 2
  if ! "$@" 2>/dev/null; then
    if git -C "$repo_dir" diff --name-only --diff-filter=U 2>/dev/null | grep -q .; then
      if [[ "$AUTO_RESOLVE" == "true" ]]; then
        echo "  ⚡ Auto-resolving conflicts ($label)..."
        git -C "$repo_dir" diff --name-only --diff-filter=U | while IFS= read -r _cf; do
          echo "    → taking theirs: $_cf"
          git -C "$repo_dir" checkout --theirs "$_cf"
          git -C "$repo_dir" add "$_cf"
        done
        git -C "$repo_dir" commit --no-edit 2>/dev/null
      else
        echo "  ❌ Merge conflict ($label) — use --auto-resolve or resolve manually"
        return 1
      fi
    else
      echo "  ⚠️  $label failed (non-conflict error)"
      return 1
    fi
  fi
}

# --- Large image warning ---
_check_large_figures() {
  local repo_dir="$1" name="$2"
  local figures_dir=""
  if [[ -d "$repo_dir/figures" ]]; then
    figures_dir="$repo_dir/figures"
  elif [[ -d "$repo_dir/Figures" ]]; then
    figures_dir="$repo_dir/Figures"
  else
    return
  fi

  local found=false
  while IFS= read -r -d '' img_file; do
    local size_bytes
    size_bytes=$(stat -f%z "$img_file" 2>/dev/null || stat -c%s "$img_file" 2>/dev/null || echo 0)
    local threshold=$((2 * 1024 * 1024))  # 2MB
    if [[ "$size_bytes" -gt "$threshold" ]]; then
      local size_mb
      size_mb=$(awk "BEGIN { printf \"%.1f\", $size_bytes / 1048576 }")
      local basename_file
      basename_file=$(basename "$img_file")
      echo "  ⚠️  Large files detected in $name: $basename_file (${size_mb}MB) — consider converting to PDF"
      found=true
    fi
  done < <(find "$figures_dir" -type f -print0 2>/dev/null)
}

# --- Per-paper sync callback ---
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
      _try_merge "$repo_dir" "upstream merge" \
        git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/$CONF_UPSTREAM_BRANCH" --no-edit || true
    else
      _try_merge "$repo_dir" "upstream merge (main)" \
        git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/main" --no-edit \
        || _try_merge "$repo_dir" "upstream merge (master)" \
          git -C "$repo_dir" merge "$CONF_UPSTREAM_REMOTE/master" --no-edit || true
    fi
  fi

  # Pull from origin + overleaf
  _try_merge "$repo_dir" "origin pull" \
    git -C "$repo_dir" pull origin "$branch" --no-rebase || true
  _try_merge "$repo_dir" "overleaf pull" \
    git -C "$repo_dir" pull "$CONF_OVERLEAF_REMOTE" "$CONF_OVERLEAF_BRANCH" --no-rebase || true

  # Push to origin + overleaf
  git -C "$repo_dir" push origin "$branch" 2>/dev/null
  git -C "$repo_dir" push "$CONF_OVERLEAF_REMOTE" "$branch:$CONF_OVERLEAF_BRANCH" 2>/dev/null

  # Check for large figure files
  _check_large_figures "$repo_dir" "$name"

  echo "✅ $repo synced ($branch)"
  echo ""
}

# --- Main execution: sequential vs parallel ---
if [[ "$PARALLEL" == "true" ]]; then
  _parallel_tmpdir=$(mktemp -d)
  _parallel_pids=()
  _parallel_names=()
  _parallel_idx=0

  _sync_paper_parallel() {
    local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
    local tmpfile="$_parallel_tmpdir/${_parallel_idx}_${name}.log"
    (
      _sync_paper "$repo" "$name" "$overleaf" "$upstream" "$repo_dir"
    ) > "$tmpfile" 2>&1 &
    _parallel_pids+=($!)
    _parallel_names+=("$name")
    _parallel_idx=$((_parallel_idx + 1))
  }

  for_each_paper _sync_paper_parallel

  # Wait for all background jobs and track failures
  _parallel_failures=()
  for _pi in "${!_parallel_pids[@]}"; do
    if ! wait "${_parallel_pids[$_pi]}"; then
      _parallel_failures+=("${_parallel_names[$_pi]}")
    fi
  done

  # Print all output sequentially
  for _logfile in $(ls "$_parallel_tmpdir"/*.log 2>/dev/null | sort); do
    cat "$_logfile"
  done

  # Clean up
  rm -rf "$_parallel_tmpdir"

  # Report failures
  if [[ ${#_parallel_failures[@]} -gt 0 ]]; then
    echo "⚠️  Some repos had errors: ${_parallel_failures[*]}"
  fi
else
  for_each_paper _sync_paper
fi

echo "🎉 All repos synced!"
