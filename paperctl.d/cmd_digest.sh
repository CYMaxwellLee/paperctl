#!/bin/bash
# paperctl.d/cmd_digest.sh -- Show recent changes (Overleaf/upstream) per paper
#
# Usage:
#   paperctl digest [--since <date>] [--todos-only] [--output <file>]
#
# Flags:
#   --since <date>     Only show commits after this date (default: auto-detect)
#   --todos-only       Only list TODO/FIXME markers
#   --output <file>    Write digest to file instead of stdout

# --- Parse flags (including global flags forwarded from CLI) ---
DIGEST_SINCE=""
DIGEST_TODOS_ONLY=false
DIGEST_OUTPUT=""

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --since)      DIGEST_SINCE="$2"; shift 2 ;;
    --todos-only) DIGEST_TODOS_ONLY=true; shift ;;
    --output)     DIGEST_OUTPUT="$2"; shift 2 ;;
    --paper)      PAPERCTL_PAPER="$2"; export PAPERCTL_PAPER; shift 2 ;;
    --dir)        PAPERCTL_DIR="$2"; export PAPERCTL_DIR; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

load_config

# --- Output buffering (to support --output) ---
_digest_buf=""
_dprint() {
  _digest_buf+="$*"$'\n'
}

# --- Deadline countdown ---
DEADLINE=$(_jq "$CONF_FILE" '.conference.deadline')
if [[ -n "$DEADLINE" && "$DEADLINE" != "null" ]]; then
  if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$DEADLINE" "+%s" &>/dev/null 2>&1; then
    # macOS
    _dl_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$DEADLINE" "+%s" 2>/dev/null)
  else
    # Linux
    _dl_epoch=$(date -d "$DEADLINE" "+%s" 2>/dev/null || echo "")
  fi
  if [[ -n "$_dl_epoch" ]]; then
    _now_epoch=$(date "+%s")
    _days_left=$(( (_dl_epoch - _now_epoch) / 86400 ))
    _deadline_str="$DEADLINE ($_days_left days remaining)"
  else
    _deadline_str="$DEADLINE"
  fi
else
  _deadline_str="N/A"
fi

# --- Header ---
_today=$(date "+%Y-%m-%d")
_dprint "📋 $CONF_NAME $CONF_YEAR — Change Digest ($_today)"
_dprint "══════════════════════════════════════════════════════"
_dprint "   Deadline: $_deadline_str"
_dprint ""

# --- Per-paper digest ---
_digest_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  # Read extra fields via index lookup
  local i=0
  while [[ $i -lt $CONF_PAPER_COUNT ]]; do
    if [[ "$(paper_field $i "name")" == "$name" ]]; then
      break
    fi
    i=$((i + 1))
  done

  local domain paper_id status
  domain=$(paper_field $i "domain")
  paper_id=$(paper_field $i "paper_id")
  status=$(paper_field $i "status")
  [[ "$domain" == "null" ]] && domain=""
  [[ "$paper_id" == "null" ]] && paper_id=""
  [[ "$status" == "null" ]] && status=""

  # Build header line: 📄 name (domain) #ID
  local header="📄 $name"
  [[ -n "$domain" ]] && header+=" ($domain)"
  [[ -n "$paper_id" ]] && header+=" #$paper_id"
  _dprint "$header"

  local branch
  branch=$(get_local_branch "$repo_dir")
  local since_flag=""
  [[ -n "$DIGEST_SINCE" ]] && since_flag="--since=$DIGEST_SINCE"

  # --- Overleaf changes ---
  if [[ "$DIGEST_TODOS_ONLY" != "true" ]]; then
    # Fetch silently
    git -C "$repo_dir" fetch "$CONF_OVERLEAF_REMOTE" 2>/dev/null || true
    git -C "$repo_dir" fetch origin 2>/dev/null || true

    # Overleaf vs local branch
    local ol_ref="$CONF_OVERLEAF_REMOTE/$CONF_OVERLEAF_BRANCH"
    local local_ref="origin/$branch"

    if git -C "$repo_dir" rev-parse "$ol_ref" &>/dev/null; then
      local ol_commits
      ol_commits=$(git -C "$repo_dir" log "$local_ref..$ol_ref" --oneline $since_flag 2>/dev/null || echo "")
      local ol_count
      ol_count=$(echo "$ol_commits" | grep -c '.' 2>/dev/null || echo "0")

      if [[ -n "$ol_commits" && "$ol_count" -gt 0 ]]; then
        _dprint "   🟢 Overleaf → $ol_count new commit(s) since last sync"
        while IFS= read -r line; do
          [[ -n "$line" ]] && _dprint "      - $line"
        done <<< "$ol_commits"

        # Diffstat
        local diffstat
        diffstat=$(git -C "$repo_dir" diff "$local_ref..$ol_ref" --stat --stat-width=60 2>/dev/null | tail -1)
        [[ -n "$diffstat" ]] && _dprint "   📊 $diffstat"
      else
        _dprint "   ✅ No new Overleaf changes since last sync"
      fi
    else
      _dprint "   ⚪ Overleaf remote not available"
    fi

    # --- Upstream changes (fork repos only) ---
    if is_fork "$upstream"; then
      git -C "$repo_dir" fetch "$CONF_UPSTREAM_REMOTE" 2>/dev/null || true

      # Try configured branch, then main, then master
      local up_branch=""
      if [[ -n "$CONF_UPSTREAM_BRANCH" ]]; then
        up_branch="$CONF_UPSTREAM_BRANCH"
      elif git -C "$repo_dir" rev-parse "$CONF_UPSTREAM_REMOTE/main" &>/dev/null 2>&1; then
        up_branch="main"
      elif git -C "$repo_dir" rev-parse "$CONF_UPSTREAM_REMOTE/master" &>/dev/null 2>&1; then
        up_branch="master"
      fi

      if [[ -n "$up_branch" ]]; then
        local up_ref="$CONF_UPSTREAM_REMOTE/$up_branch"
        local up_commits
        up_commits=$(git -C "$repo_dir" log "$local_ref..$up_ref" --oneline $since_flag 2>/dev/null || echo "")
        local up_count
        up_count=$(echo "$up_commits" | grep -c '.' 2>/dev/null || echo "0")

        if [[ -n "$up_commits" && "$up_count" -gt 0 ]]; then
          _dprint "   🔱 Upstream → $up_count new commit(s)"
          while IFS= read -r line; do
            [[ -n "$line" ]] && _dprint "      - $line"
          done <<< "$up_commits"
        fi
      fi
    fi

    # --- Local uncommitted changes ---
    local dirty
    dirty=$(git -C "$repo_dir" status --porcelain 2>/dev/null)
    if [[ -n "$dirty" ]]; then
      local dirty_count
      dirty_count=$(echo "$dirty" | wc -l | tr -d ' ')
      _dprint "   📝 Local → $dirty_count uncommitted file(s)"
    fi
  fi

  # --- TODO/FIXME/XXX markers ---
  local todo_lines
  todo_lines=$(grep -rn 'TODO\|FIXME\|XXX\|\\textcolor{red}' --include='*.tex' "$repo_dir" 2>/dev/null \
    | grep -v '\.git/' \
    | grep -v 'node_modules' \
    | sed "s|$repo_dir/||" \
    || echo "")
  local todo_count
  if [[ -n "$todo_lines" ]]; then
    todo_count=$(echo "$todo_lines" | wc -l | tr -d ' ')
  else
    todo_count=0
  fi

  if [[ "$todo_count" -gt 0 ]]; then
    _dprint "   ⚠️  TODOs: $todo_count"
    # Show up to 5 TODO lines
    local shown=0
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      _dprint "      $line"
      shown=$((shown + 1))
      [[ $shown -ge 5 ]] && break
    done <<< "$todo_lines"
    if [[ "$todo_count" -gt 5 ]]; then
      _dprint "      ... and $((todo_count - 5)) more"
    fi
  else
    _dprint "   ⚠️  TODOs: 0"
  fi

  _dprint ""
}

for_each_paper _digest_paper

# --- Summary footer ---
_dprint "══════════════════════════════════════════════════════"
_dprint "Generated by paperctl digest · $(date '+%Y-%m-%d %H:%M')"

# --- Output ---
if [[ -n "$DIGEST_OUTPUT" ]]; then
  echo "$_digest_buf" > "$DIGEST_OUTPUT"
  echo "✅ Digest written to $DIGEST_OUTPUT"
else
  echo "$_digest_buf"
fi
