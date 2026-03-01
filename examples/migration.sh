#!/bin/bash
# paperctl — New Machine Migration Guide
# Run this script on a fresh machine to set up paperctl + an existing conference.
#
# Usage:
#   bash migration.sh
#
# Prerequisites:
#   - git installed
#   - GitHub account with access to your org's repos
#   - Overleaf account with Git Integration token
#
# What this script does:
#   1. Install paperctl (clone + symlink)
#   2. Set up Git credential storage
#   3. Prompt for GitHub PAT + Overleaf token
#   4. Clone meta repo → get conference.json
#   5. Run paperctl init + start to bootstrap all paper repos

set -euo pipefail

# ─── Colors ───
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

echo ""
bold "══════════════════════════════════════"
bold "  paperctl — New Machine Migration"
bold "══════════════════════════════════════"
echo ""

# ─── Step 1: Install paperctl ───
bold "Step 1/5: Install paperctl"

if command -v paperctl &>/dev/null; then
  yellow "  paperctl already installed at $(which paperctl)"
  echo "  Updating..."
  PAPERCTL_DIR=$(dirname "$(readlink "$(which paperctl)" || which paperctl)")
  git -C "$PAPERCTL_DIR" pull --ff-only 2>/dev/null || true
else
  INSTALL_DIR="${HOME}/Project/paperctl"
  echo "  Cloning to $INSTALL_DIR ..."
  git clone https://github.com/CYMaxwellLee/paperctl.git "$INSTALL_DIR"
  ln -sf "$INSTALL_DIR/paperctl" /usr/local/bin/paperctl 2>/dev/null \
    || sudo ln -sf "$INSTALL_DIR/paperctl" /usr/local/bin/paperctl
  chmod +x "$INSTALL_DIR/paperctl"
fi
green "  Done"
echo ""

# ─── Step 2: Git credential storage ───
bold "Step 2/5: Git credential storage"

CURRENT_HELPER=$(git config --global credential.helper 2>/dev/null || echo "")
if [[ -n "$CURRENT_HELPER" ]]; then
  yellow "  Already set: $CURRENT_HELPER"
else
  if [[ "$(uname)" == "Darwin" ]]; then
    git config --global credential.helper osxkeychain
    green "  Set to: osxkeychain"
  else
    git config --global credential.helper store
    green "  Set to: store (~/.git-credentials)"
  fi
fi
echo ""

# ─── Step 3: Credential reminders ───
bold "Step 3/5: Credentials"

echo "  You'll need these credentials (entered on first git push/pull):"
echo ""
echo "  GitHub PAT:"
echo "    1. Go to: https://github.com/settings/tokens"
echo "    2. Generate a token with 'repo' scope"
echo "    3. It will be cached on first push"
echo ""
echo "  Overleaf token:"
echo "    1. Go to: Overleaf > Account Settings > Git Integration"
echo "    2. Generate a 'Git Authentication Token' (starts with olp_)"
echo "    3. When git prompts: username = 'git', password = your olp_ token"
echo ""

read -rp "  Press Enter to continue (or Ctrl-C to set up credentials first)..."
echo ""

# ─── Step 4: Conference setup ───
bold "Step 4/5: Conference setup"

read -rp "  Conference directory path (e.g., ~/Project/Papers/eccv2026): " CONF_DIR
CONF_DIR="${CONF_DIR/#\~/$HOME}"

if [[ -f "$CONF_DIR/conference.json" ]]; then
  yellow "  conference.json already exists at $CONF_DIR"
else
  mkdir -p "$CONF_DIR"
  cd "$CONF_DIR"

  read -rp "  Meta repo Git URL (e.g., https://github.com/YourOrg/eccv2026-meta.git): " META_URL

  if [[ -n "$META_URL" ]]; then
    echo "  Cloning meta repo..."
    META_DIR=$(basename "$META_URL" .git)
    git clone "$META_URL" "$META_DIR"

    if [[ -f "$META_DIR/conference.json" ]]; then
      ln -sf "$META_DIR/conference.json" conference.json
      green "  conference.json linked from meta repo"
    else
      red "  conference.json not found in meta repo!"
      echo "  Copy it manually or create from template:"
      echo "    cp \$(dirname \$(which paperctl))/examples/conference.json.example conference.json"
      exit 1
    fi
  else
    echo "  No meta repo. Copying template..."
    PAPERCTL_DIR=$(dirname "$(readlink "$(which paperctl)" || which paperctl)")
    cp "$PAPERCTL_DIR/examples/conference.json.example" conference.json
    yellow "  Edit conference.json before proceeding!"
    exit 0
  fi
fi
echo ""

# ─── Step 5: Bootstrap ───
bold "Step 5/5: Bootstrap"

cd "$CONF_DIR"
echo "  Running paperctl init (cloning all paper repos + setting remotes)..."
paperctl init --dir "$CONF_DIR"

echo ""
echo "  Running paperctl start (syncing from GitHub + Overleaf)..."
paperctl start --dir "$CONF_DIR"

echo ""
green "══════════════════════════════════════"
green "  Migration complete!"
green "══════════════════════════════════════"
echo ""
echo "  Directory: $CONF_DIR"
echo "  Papers:    $(paperctl status --dir "$CONF_DIR" 2>/dev/null | grep -c '^\s*[🔱 ]' || echo '?')"
echo ""
echo "  Next steps:"
echo "    cd $CONF_DIR"
echo "    paperctl status        # check everything"
echo "    paperctl sync          # daily sync"
echo ""
