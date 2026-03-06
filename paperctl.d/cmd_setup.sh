#!/bin/bash
# paperctl.d/cmd_setup.sh -- Check environment & guide setup
#
# Platform-aware diagnostic: shows what's installed, what's missing,
# and gives exact commands to fix. No sudo required.
#
# Usage:
#   paperctl setup           # check environment + show fix commands
#   paperctl setup --install # also run setup-texlive.sh (needs sudo)

MODE="check"
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --install) MODE="install"; shift ;;
    *) break ;;
  esac
done

# Colors
_green() { printf '\033[32m%s\033[0m\n' "$*"; }
_yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
_red() { printf '\033[31m%s\033[0m\n' "$*"; }
_bold() { printf '\033[1m%s\033[0m\n' "$*"; }

# Platform detection
case "$(uname -s)" in
  Darwin) PLATFORM="macOS" ;;
  Linux)
    if [[ -f /etc/debian_version ]]; then PLATFORM="Linux (Debian/Ubuntu)"
    elif [[ -f /etc/fedora-release ]]; then PLATFORM="Linux (Fedora)"
    elif [[ -f /etc/arch-release ]]; then PLATFORM="Linux (Arch)"
    else PLATFORM="Linux"; fi
    ;;
  *) PLATFORM="Unknown ($(uname -s))" ;;
esac

echo ""
_bold "=== paperctl Environment Check ==="
echo "  Platform:  $PLATFORM"
echo "  paperctl:  $PAPERCTL_ROOT/paperctl"
echo ""

# --- 1. Required tools ---
_bold "1. Required Tools"
ALL_OK=true

# git
if command -v git &>/dev/null; then
  _green "  ✅ git $(git --version 2>&1 | grep -o '[0-9.]*' | head -1)"
else
  _red "  ❌ git — install from https://git-scm.com/"
  ALL_OK=false
fi

# jq or python3
if command -v jq &>/dev/null; then
  _green "  ✅ jq $(jq --version 2>&1)"
elif command -v python3 &>/dev/null; then
  _yellow "  ⚠️  jq not found (python3 fallback: $(python3 --version 2>&1 | grep -o '[0-9.]*'))"
else
  _red "  ❌ jq or python3 — install: brew install jq (macOS) / apt install jq (Linux)"
  ALL_OK=false
fi

echo ""

# --- 2. TeX Live ---
_bold "2. TeX Live"

PDFLATEX=""
TLMGR=""
KPSEWHICH=""

# Find binaries
if [[ -x "/Library/TeX/texbin/pdflatex" ]]; then
  PDFLATEX="/Library/TeX/texbin/pdflatex"
  TLMGR="/Library/TeX/texbin/tlmgr"
  KPSEWHICH="/Library/TeX/texbin/kpsewhich"
else
  for _d in /usr/local/texlive/*/bin/*/; do
    [[ -x "${_d}pdflatex" ]] && { PDFLATEX="${_d}pdflatex"; TLMGR="${_d}tlmgr"; KPSEWHICH="${_d}kpsewhich"; break; }
  done
fi
[[ -z "$PDFLATEX" ]] && PDFLATEX=$(command -v pdflatex 2>/dev/null || true)
[[ -z "$TLMGR" ]] && TLMGR=$(command -v tlmgr 2>/dev/null || true)
[[ -z "$KPSEWHICH" ]] && KPSEWHICH=$(command -v kpsewhich 2>/dev/null || true)

if [[ -n "$PDFLATEX" ]]; then
  local_ver=$("$PDFLATEX" --version 2>&1 | head -1 | grep -o 'TeX Live [0-9]*' || echo "unknown")
  _green "  ✅ pdflatex ($local_ver)"
  echo "      $PDFLATEX"

  # Check full vs minimal
  missing_count=0
  for pkg in siunitx pgfplots comment cleveref; do
    if ! "$KPSEWHICH" "${pkg}.sty" &>/dev/null 2>&1; then
      missing_count=$((missing_count + 1))
    fi
  done

  if [[ $missing_count -eq 0 ]]; then
    _green "  ✅ Full TeX Live (all key packages present)"
  else
    _yellow "  ⚠️  Minimal install ($missing_count key packages missing)"
    echo "      Fix: sudo bash $PAPERCTL_ROOT/setup-texlive.sh"
    ALL_OK=false
  fi
else
  _red "  ❌ pdflatex not found"
  case "$PLATFORM" in
    macOS*)  echo "      Fix: brew install --cask mactex" ;;
    *Debian*|*Ubuntu*) echo "      Fix: sudo apt install texlive-full" ;;
    *Fedora*) echo "      Fix: sudo dnf install texlive-scheme-full" ;;
    *Arch*)  echo "      Fix: sudo pacman -S texlive-most" ;;
    *)       echo "      Fix: https://tug.org/texlive/acquire.html" ;;
  esac
  ALL_OK=false
fi

echo ""

# --- 3. Optional tools ---
_bold "3. Optional Tools"

if command -v pdfinfo &>/dev/null; then
  _green "  ✅ pdfinfo (page count extraction)"
else
  _yellow "  ⚠️  pdfinfo — install poppler-utils for PDF page counts"
fi

if command -v docker &>/dev/null; then
  _green "  ✅ docker $(docker --version 2>&1 | grep -o '[0-9.]*' | head -1)"
else
  echo "  ℹ️  docker (optional, for CI/reproducible builds)"
fi

if command -v gh &>/dev/null; then
  _green "  ✅ gh CLI $(gh --version 2>&1 | grep -o '[0-9.]*' | head -1)"
else
  echo "  ℹ️  gh CLI (optional, for GitHub integration)"
fi

echo ""

# --- 4. Conference config ---
_bold "4. Conference Config"

# Try to find conference.json
CONF_JSON=""
_dir="$PWD"
while [[ "$_dir" != "/" ]]; do
  if [[ -f "$_dir/conference.json" ]]; then
    CONF_JSON="$_dir/conference.json"
    break
  fi
  _dir=$(dirname "$_dir")
done

if [[ -n "$CONF_JSON" ]]; then
  if command -v jq &>/dev/null; then
    conf_name=$(jq -r '.conference.name' "$CONF_JSON")
    conf_year=$(jq -r '.conference.year' "$CONF_JSON")
    paper_count=$(jq '.papers | length' "$CONF_JSON")
  else
    conf_name=$(python3 -c "import json; print(json.load(open('$CONF_JSON'))['conference']['name'])")
    conf_year=$(python3 -c "import json; print(json.load(open('$CONF_JSON'))['conference']['year'])")
    paper_count=$(python3 -c "import json; print(len(json.load(open('$CONF_JSON'))['papers']))")
  fi
  _green "  ✅ $conf_name $conf_year ($paper_count papers)"
  echo "      $CONF_JSON"
else
  _yellow "  ⚠️  No conference.json found (run from a conference directory)"
fi

echo ""

# --- Summary ---
_bold "=== Summary ==="
if $ALL_OK; then
  _green "✅ Environment is ready! Run 'paperctl compile' to test."
else
  _yellow "⚠️  Some issues found. See fix commands above."
  echo ""
  echo "  Quick fix (all-in-one):"
  echo "    sudo bash $PAPERCTL_ROOT/setup-texlive.sh"
fi
echo ""

# --- Install mode ---
if [[ "$MODE" == "install" ]]; then
  echo "Running TeX Live setup..."
  echo ""
  if [[ $EUID -ne 0 && "$PLATFORM" != "macOS" ]]; then
    _red "Install mode requires sudo on Linux:"
    echo "  sudo paperctl setup --install"
    exit 1
  fi
  exec bash "$PAPERCTL_ROOT/setup-texlive.sh"
fi
