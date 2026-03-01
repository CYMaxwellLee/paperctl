#!/bin/bash
# paperctl installer
# Usage: curl -sL https://raw.githubusercontent.com/CYMaxwellLee/paperctl/main/install.sh | bash
#    or: bash install.sh

set -euo pipefail

# Colors
_green() { printf '\033[32m%s\033[0m\n' "$*"; }
_yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
_red() { printf '\033[31m%s\033[0m\n' "$*"; }

echo ""
echo "==================================="
echo "  paperctl installer"
echo "==================================="
echo ""

# --- 1. Check dependencies ---
echo "Checking dependencies..."

if ! command -v git &>/dev/null; then
  _red "ERROR: git is required. Install from https://git-scm.com/"
  exit 1
fi
_green "  git: $(git --version)"

if command -v jq &>/dev/null; then
  _green "  jq: $(jq --version)"
elif command -v python3 &>/dev/null; then
  _yellow "  jq: not found (python3 will be used as fallback)"
  _green "  python3: $(python3 --version 2>&1)"
else
  _red "ERROR: Either 'jq' or 'python3' is required."
  _red "  Install jq:  brew install jq (macOS) / apt install jq (Linux)"
  exit 1
fi

# --- 2. Determine install path ---
DEFAULT_PATH="$HOME/Project/paperctl"
if [[ -d "$DEFAULT_PATH" ]]; then
  INSTALL_PATH="$DEFAULT_PATH"
  _yellow "  Found existing install at $INSTALL_PATH"
else
  INSTALL_PATH="$DEFAULT_PATH"
fi

# Allow override
if [[ -n "${PAPERCTL_INSTALL_PATH:-}" ]]; then
  INSTALL_PATH="$PAPERCTL_INSTALL_PATH"
fi

# --- 3. Clone or update ---
if [[ -d "$INSTALL_PATH/.git" ]]; then
  echo ""
  echo "Updating existing installation..."
  git -C "$INSTALL_PATH" pull --ff-only
else
  echo ""
  echo "Cloning paperctl to $INSTALL_PATH ..."
  git clone https://github.com/CYMaxwellLee/paperctl.git "$INSTALL_PATH"
fi

# --- 4. Symlink ---
echo ""
SYMLINK_DIR="/usr/local/bin"
if [[ ! -d "$SYMLINK_DIR" ]]; then
  echo "Creating $SYMLINK_DIR ..."
  sudo mkdir -p "$SYMLINK_DIR"
fi

if [[ -L "$SYMLINK_DIR/paperctl" ]]; then
  echo "Updating symlink..."
  ln -sf "$INSTALL_PATH/paperctl" "$SYMLINK_DIR/paperctl"
elif [[ -e "$SYMLINK_DIR/paperctl" ]]; then
  _yellow "  $SYMLINK_DIR/paperctl exists but is not a symlink. Skipping."
  _yellow "  You may want to: ln -sf $INSTALL_PATH/paperctl $SYMLINK_DIR/paperctl"
else
  echo "Creating symlink..."
  ln -sf "$INSTALL_PATH/paperctl" "$SYMLINK_DIR/paperctl" 2>/dev/null \
    || sudo ln -sf "$INSTALL_PATH/paperctl" "$SYMLINK_DIR/paperctl"
fi

# --- 5. Make executable ---
chmod +x "$INSTALL_PATH/paperctl"

# --- 6. Verify ---
echo ""
if command -v paperctl &>/dev/null; then
  _green "paperctl installed successfully!"
  echo ""
  echo "  Location: $INSTALL_PATH"
  echo "  Symlink:  $(which paperctl)"
  echo ""
  echo "Next steps:"
  echo "  1. Create a conference directory:"
  echo "     mkdir ~/Project/Papers/eccv2026"
  echo ""
  echo "  2. Copy the example config:"
  echo "     cp $INSTALL_PATH/examples/conference.json.example \\"
  echo "        ~/Project/Papers/eccv2026/conference.json"
  echo ""
  echo "  3. Edit conference.json with your papers"
  echo ""
  echo "  4. Bootstrap:"
  echo "     cd ~/Project/Papers/eccv2026 && paperctl init"
  echo ""
else
  _yellow "Installed but not in PATH. Add to your shell:"
  echo "  export PATH=\"$SYMLINK_DIR:\$PATH\""
fi
