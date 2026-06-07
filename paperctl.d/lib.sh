#!/bin/bash
# paperctl.d/lib.sh -- Core library for paperctl

# Never hang on an interactive credential prompt: background/parallel pushes have no TTY,
# so an un-seeded credential should fail fast (run `paperctl auth` to seed). Override by
# exporting GIT_TERMINAL_PROMPT=1 before invoking paperctl.
export GIT_TERMINAL_PROMPT="${GIT_TERMINAL_PROMPT:-0}"

# --- Universal --help handler ---
# If any remaining arg is --help or -h, show command usage and exit
for _arg in "$@"; do
  if [[ "$_arg" == "--help" || "$_arg" == "-h" ]]; then
    _cmd="${COMMAND:-paperctl}"
    echo "Usage: paperctl $_cmd [--paper <name>] [options]"
    echo ""
    # Extract examples from help.txt
    _section=$(sed -n "/paperctl $_cmd/p" "$PAPERCTL_LIB/help.txt" 2>/dev/null | head -6)
    if [[ -n "$_section" ]]; then
      echo "Examples:"
      echo "$_section" | sed 's/^/  /'
    fi
    echo ""
    echo "Run 'paperctl help' for full documentation."
    exit 0
  fi
done

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
# Searches upward from CWD to find conference.json (like git finds .git/)
find_config() {
  # Explicit --dir takes priority
  if [[ -n "${PAPERCTL_DIR:-}" ]]; then
    if [[ -f "$PAPERCTL_DIR/conference.json" ]]; then
      echo "$PAPERCTL_DIR/conference.json"
      return
    fi
    echo "ERROR: conference.json not found in $PAPERCTL_DIR" >&2
    echo "Run from a conference directory or use --dir <path>" >&2
    exit 1
  fi

  # Walk upward from CWD to find conference.json
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/conference.json" ]]; then
      echo "$dir/conference.json"
      return
    fi
    dir=$(dirname "$dir")
  done

  echo "ERROR: conference.json not found (searched upward from $PWD)" >&2
  echo "Run from a conference directory or use --dir <path>" >&2
  exit 1
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

# --- Paper Lookup ---
# Find paper index by name; returns index or empty string
paper_index_by_name() {
  local target="$1"
  local i=0
  while [[ $i -lt $CONF_PAPER_COUNT ]]; do
    local name
    name=$(paper_field $i "name")
    if [[ "$name" == "$target" ]]; then
      echo "$i"
      return
    fi
    i=$((i + 1))
  done
  echo ""
}

# Verify --paper flag points to a valid paper
require_paper_flag() {
  if [[ -z "${PAPERCTL_PAPER:-}" ]]; then
    echo "ERROR: --paper <name> is required for this command" >&2
    exit 1
  fi
  local idx
  idx=$(paper_index_by_name "$PAPERCTL_PAPER")
  if [[ -z "$idx" ]]; then
    echo "ERROR: unknown paper '$PAPERCTL_PAPER'" >&2
    echo "  Available: $(for_each_paper_name)" >&2
    exit 1
  fi
}

# List all paper names (one per line)
for_each_paper_name() {
  local i=0
  while [[ $i -lt $CONF_PAPER_COUNT ]]; do
    paper_field $i "name"
    i=$((i + 1))
  done
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

# --- Pre-push quality gate ---
# Returns 0 to allow the push, 1 to block it. The point is to make a summarized/broken
# appendix structurally unpushable. Honors:
#   PAPERCTL_NO_VERIFY=true   skip the gate entirely (set by `--force` / `--no-verify`)
#   PAPERCTL_GATE_COMPILE=true  also require a clean `compile --strict` (set by `--compile`)
# By default it runs only the fast read-only appendix verifier (no compile), so normal
# pushes stay quick.
prepush_gate() {
  local repo_dir="$1" name="$2"
  [[ "${PAPERCTL_NO_VERIFY:-false}" == "true" ]] && return 0
  local rc=0 glog
  glog=$(mktemp "/tmp/paperctl_gate_${name}.XXXXXX")
  if ! "$PAPERCTL_ROOT/paperctl" verify-appendix --paper "$name" --dir "$CONF_DIR" > "$glog" 2>&1; then
    echo "  ❌ appendix verifier FAILED for $name -- push blocked"
    grep -E 'FAIL' "$glog" | sed 's/^/     /' | head -20
    rc=1
  fi
  rm -f "$glog"
  if [[ "${PAPERCTL_GATE_COMPILE:-false}" == "true" ]]; then
    if ! "$PAPERCTL_ROOT/paperctl" compile --paper "$name" --strict --dir "$CONF_DIR" >/dev/null 2>&1; then
      echo "  ❌ compile --strict FAILED for $name -- push blocked"
      rc=1
    fi
  fi
  [[ $rc -ne 0 ]] && echo "     → override with: paperctl push --force   (or PAPERCTL_NO_VERIFY=true)"
  return $rc
}
