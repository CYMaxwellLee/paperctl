#!/bin/bash
# paperctl.d/lib.sh -- Core library for paperctl

# --- JSON query helper (jq preferred, python3 fallback) ---
_jq() {
  local file="$1" query="$2"
  if command -v jq &>/dev/null; then
    jq -r "$query" "$file"
  else
    python3 -c "
import json, sys, functools
data = json.load(open(sys.argv[1]))
path = sys.argv[2]
# Simple jq-like path evaluator
result = data
for key in path.lstrip('.').split('.'):
    if key == '': continue
    if '[' in key:
        name, idx = key.split('[')
        idx = int(idx.rstrip(']'))
        if name: result = result[name]
        result = result[idx]
    else:
        result = result.get(key) if isinstance(result, dict) else None
    if result is None:
        print('null')
        sys.exit(0)
print(result if not isinstance(result, bool) else str(result).lower())
" "$file" "$query"
  fi
}

_jq_raw() {
  local file="$1" query="$2"
  if command -v jq &>/dev/null; then
    jq "$query" "$file"
  else
    python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
print(json.dumps(data))
" "$file"
  fi
}

# --- Config Location ---
find_config() {
  local search_dir="${PAPERCTL_DIR:-$PWD}"
  if [[ -f "$search_dir/conference.json" ]]; then
    echo "$search_dir/conference.json"
  elif [[ -f "$PWD/conference.json" ]]; then
    echo "$PWD/conference.json"
  else
    echo "ERROR: conference.json not found in $search_dir" >&2
    echo "Run from a conference directory or use --dir <path>" >&2
    exit 1
  fi
}

# --- Load Config ---
load_config() {
  CONF_FILE=$(find_config)
  CONF_DIR=$(cd "$(dirname "$CONF_FILE")" && pwd)

  CONF_NAME=$(_jq "$CONF_FILE" '.conference.name')
  CONF_YEAR=$(_jq "$CONF_FILE" '.conference.year')
  CONF_SLUG=$(_jq "$CONF_FILE" '.conference.slug')
  CONF_TEMPLATE=$(_jq "$CONF_FILE" '.conference.template')
  CONF_ORG=$(_jq "$CONF_FILE" '.conference.org')

  CONF_GITHUB_BRANCH=$(_jq "$CONF_FILE" '.defaults.github_branch')
  CONF_OVERLEAF_BRANCH=$(_jq "$CONF_FILE" '.defaults.overleaf_branch')
  CONF_OVERLEAF_REMOTE=$(_jq "$CONF_FILE" '.defaults.overleaf_remote')
  CONF_UPSTREAM_REMOTE=$(_jq "$CONF_FILE" '.defaults.upstream_remote')
  CONF_UPSTREAM_BRANCH=$(_jq "$CONF_FILE" '.defaults.upstream_branch')
  [[ "$CONF_UPSTREAM_BRANCH" == "null" || -z "$CONF_UPSTREAM_BRANCH" ]] && CONF_UPSTREAM_BRANCH=""

  if command -v jq &>/dev/null; then
    CONF_PAPER_COUNT=$(jq '.papers | length' "$CONF_FILE")
  else
    CONF_PAPER_COUNT=$(python3 -c "import json; print(len(json.load(open('$CONF_FILE'))['papers']))")
  fi
}

# --- Paper Field Accessors ---
paper_field() {
  local idx="$1" field="$2"
  _jq "$CONF_FILE" ".papers[$idx].$field"
}

# --- Branch Detection ---
get_local_branch() {
  local repo_dir="$1"
  git -C "$repo_dir" symbolic-ref --short HEAD 2>/dev/null || echo "$CONF_GITHUB_BRANCH"
}

# --- Fork Detection ---
is_fork() {
  local upstream="$1"
  [[ -n "$upstream" && "$upstream" != "null" ]]
}

# --- State Management ---
STATE_FILE=""

_state_file_path() {
  echo "${CONF_DIR}/.paperctl_state.json"
}

# Save current HEAD SHA of all papers to state file (call before sync)
save_pre_sync_state() {
  local sf
  sf=$(_state_file_path)
  local ts
  ts=$(date "+%Y-%m-%dT%H:%M:%S%z")

  # Build JSON using python3 (works everywhere, jq may not have -n on all systems)
  local papers_json="{"
  local first=true
  local i=0
  while [[ $i -lt $CONF_PAPER_COUNT ]]; do
    local name=$(paper_field $i "name")
    local repo=$(paper_field $i "repo")
    local repo_dir="$CONF_DIR/$repo"
    if [[ -d "$repo_dir" ]]; then
      local sha
      sha=$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null || echo "unknown")
      if [[ "$first" == "true" ]]; then
        first=false
      else
        papers_json+=","
      fi
      papers_json+="\"$name\":\"$sha\""
    fi
    i=$((i + 1))
  done
  papers_json+="}"

  python3 -c "
import json, sys
data = {
    'timestamp': sys.argv[1],
    'papers': json.loads(sys.argv[2])
}
with open(sys.argv[3], 'w') as f:
    json.dump(data, f, indent=2)
" "$ts" "$papers_json" "$sf"

  echo "📌 Pre-sync state saved to $(basename "$sf")"
}

# Read saved state; sets STATE_FILE and returns 0 if exists, 1 if not
load_sync_state() {
  STATE_FILE=$(_state_file_path)
  if [[ -f "$STATE_FILE" ]]; then
    return 0
  else
    return 1
  fi
}

# Get saved SHA for a paper name from state file
get_saved_sha() {
  local name="$1"
  if [[ -z "$STATE_FILE" || ! -f "$STATE_FILE" ]]; then
    echo ""
    return
  fi
  # Use bracket notation to handle hyphens in paper names (e.g. pnr-fungraph)
  if command -v jq &>/dev/null; then
    jq -r ".papers[\"$name\"]" "$STATE_FILE"
  else
    python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
print(data.get('papers', {}).get(sys.argv[2], 'null'))
" "$STATE_FILE" "$name"
  fi
}

# Get saved timestamp from state file
get_saved_timestamp() {
  if [[ -z "$STATE_FILE" || ! -f "$STATE_FILE" ]]; then
    echo ""
    return
  fi
  _jq "$STATE_FILE" ".timestamp"
}

# --- Iterate Over Papers ---
for_each_paper() {
  local callback="$1"
  shift
  local i=0
  while [[ $i -lt $CONF_PAPER_COUNT ]]; do
    local repo=$(paper_field $i "repo")
    local name=$(paper_field $i "name")
    local overleaf=$(paper_field $i "overleaf")
    local upstream=$(paper_field $i "upstream")
    local repo_dir="$CONF_DIR/$repo"

    # If --paper filter is set, skip non-matching
    if [[ -n "${PAPERCTL_PAPER:-}" && "$name" != "$PAPERCTL_PAPER" ]]; then
      i=$((i + 1))
      continue
    fi

    if [[ ! -d "$repo_dir" ]]; then
      echo "  SKIP: $repo (not cloned)"
      i=$((i + 1))
      continue
    fi

    "$callback" "$repo" "$name" "$overleaf" "$upstream" "$repo_dir"
    i=$((i + 1))
  done
}
