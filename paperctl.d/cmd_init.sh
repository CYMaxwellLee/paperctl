#!/bin/bash
# paperctl.d/cmd_init.sh -- Bootstrap repos from conference.json

load_config

echo "🏗️  Initializing conference: $CONF_NAME $CONF_YEAR"
echo "   Directory: $CONF_DIR"
echo "   Org: $CONF_ORG"
echo ""

# Check for template_repo in config
TEMPLATE_REPO=$(_jq "$CONF_FILE" '.conference.template_repo')

_init_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  echo "=== $repo ($name) ==="

  # 1. Clone or skip
  if [[ -d "$repo_dir" ]]; then
    echo "  ⏭️  Already cloned"
  else
    if is_fork "$upstream"; then
      # Fork: clone from upstream, add origin as ElsaLab fork
      echo "  📦 Cloning from upstream: $upstream ..."
      git clone "https://github.com/$upstream.git" "$repo_dir"
      git -C "$repo_dir" remote rename origin "$CONF_UPSTREAM_REMOTE"
      git -C "$repo_dir" remote add origin "https://github.com/$CONF_ORG/$repo.git"
    else
      # Normal: clone from org
      echo "  📦 Cloning from $CONF_ORG/$repo ..."
      git clone "https://github.com/$CONF_ORG/$repo.git" "$repo_dir" 2>/dev/null || {
        echo "  🆕 Repo not found on GitHub. Creating empty repo..."
        mkdir -p "$repo_dir"
        git -C "$repo_dir" init
        git -C "$repo_dir" remote add origin "https://github.com/$CONF_ORG/$repo.git"
      }
    fi
  fi

  # 2. Ensure overleaf remote
  if [[ -n "$overleaf" && "$overleaf" != "null" ]]; then
    if ! git -C "$repo_dir" remote get-url "$CONF_OVERLEAF_REMOTE" &>/dev/null; then
      echo "  🔗 Adding overleaf remote..."
      git -C "$repo_dir" remote add "$CONF_OVERLEAF_REMOTE" "$overleaf"
    else
      echo "  ✅ Overleaf remote exists"
    fi
  fi

  # 3. Ensure upstream remote (fork repos)
  if is_fork "$upstream"; then
    if ! git -C "$repo_dir" remote get-url "$CONF_UPSTREAM_REMOTE" &>/dev/null; then
      echo "  🔗 Adding upstream remote..."
      git -C "$repo_dir" remote add "$CONF_UPSTREAM_REMOTE" "https://github.com/$upstream.git"
    else
      echo "  ✅ Upstream remote exists"
    fi
  fi

  # 4. Fetch all remotes
  echo "  📡 Fetching all remotes..."
  git -C "$repo_dir" fetch --all 2>/dev/null

  # 5. Copy template files if template_repo is configured
  if [[ -n "$TEMPLATE_REPO" && "$TEMPLATE_REPO" != "null" ]]; then
    local template_dir="${TMPDIR:-/tmp}/paperctl-template-$$"
    if [[ ! -d "$template_dir" ]]; then
      git clone --depth 1 "$TEMPLATE_REPO" "$template_dir" 2>/dev/null
    fi
    # Copy essential template files if missing
    for tfile in eccv.sty llncs.cls splncs04.bst; do
      if [[ -f "$template_dir/$tfile" && ! -f "$repo_dir/$tfile" ]]; then
        cp "$template_dir/$tfile" "$repo_dir/"
        echo "  📄 Copied template: $tfile"
      fi
    done
  fi

  local branch
  branch=$(get_local_branch "$repo_dir")
  echo "  ✅ $repo ready ($branch)"
  echo ""
}

for_each_paper _init_paper

# Cleanup template cache
rm -rf "${TMPDIR:-/tmp}/paperctl-template-$$" 2>/dev/null

echo "🎉 Conference initialized! Run 'paperctl start' to begin."
