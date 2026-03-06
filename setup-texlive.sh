#!/bin/bash
# setup-texlive.sh -- Cross-platform TeX Live installer for conference papers
#
# Supports: macOS (brew), Ubuntu/Debian (apt), Fedora/RHEL (dnf), Arch (pacman)
# Also handles: BasicTeX → full MacTeX upgrade, version mismatch auto-fix
#
# Usage:
#   sudo bash setup-texlive.sh              # install/upgrade TeX Live + packages
#   sudo bash setup-texlive.sh --minimal    # install only missing packages (skip full TL)
#   bash setup-texlive.sh --check           # check what's installed (no sudo needed)

set -euo pipefail

# --- Colors ---
_green() { printf '\033[32m%s\033[0m\n' "$*"; }
_yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
_red() { printf '\033[31m%s\033[0m\n' "$*"; }
_bold() { printf '\033[1m%s\033[0m\n' "$*"; }

# --- Platform detection ---
detect_platform() {
  case "$(uname -s)" in
    Darwin) PLATFORM="macos" ;;
    Linux)
      if [[ -f /etc/debian_version ]]; then
        PLATFORM="debian"
      elif [[ -f /etc/fedora-release ]] || [[ -f /etc/redhat-release ]]; then
        PLATFORM="fedora"
      elif [[ -f /etc/arch-release ]]; then
        PLATFORM="arch"
      else
        PLATFORM="linux-generic"
      fi
      ;;
    *) PLATFORM="unknown" ;;
  esac
  echo "$PLATFORM"
}

# --- Find TeX binaries ---
find_tex_binaries() {
  TLMGR="" KPSEWHICH="" PDFLATEX=""

  # macOS stable symlink
  if [[ -x "/Library/TeX/texbin/tlmgr" ]]; then
    TLMGR="/Library/TeX/texbin/tlmgr"
    KPSEWHICH="/Library/TeX/texbin/kpsewhich"
    PDFLATEX="/Library/TeX/texbin/pdflatex"
    return
  fi

  # Linux: search versioned dirs
  for _d in /usr/local/texlive/*/bin/*/; do
    if [[ -x "${_d}tlmgr" ]]; then
      TLMGR="${_d}tlmgr"
      KPSEWHICH="${_d}kpsewhich"
      PDFLATEX="${_d}pdflatex"
      return
    fi
  done

  # Fallback: PATH
  TLMGR=$(command -v tlmgr 2>/dev/null || true)
  KPSEWHICH=$(command -v kpsewhich 2>/dev/null || true)
  PDFLATEX=$(command -v pdflatex 2>/dev/null || true)
}

# --- TeX Live version detection (3 methods) ---
detect_tl_version() {
  local ver=""

  # Method 1: "version YYYY" in tlmgr output
  if [[ -n "$TLMGR" ]]; then
    ver=$("$TLMGR" --version 2>&1 | grep -o 'version [0-9]*' | grep -o '[0-9]*' | head -1) || true
  fi

  # Method 2: installation path year
  if [[ -z "$ver" && -n "$TLMGR" ]]; then
    ver=$("$TLMGR" --version 2>&1 | grep -o 'texlive/[0-9]*' | grep -o '[0-9]*' | head -1) || true
  fi

  # Method 3: kpsewhich
  if [[ -z "$ver" && -n "$KPSEWHICH" ]]; then
    ver=$("$KPSEWHICH" -var-value SELFAUTOPARENT 2>/dev/null | grep -o '[0-9]\{4\}' | head -1) || true
  fi

  echo "$ver"
}

# --- Check if full TeX Live or minimal ---
detect_tl_type() {
  if [[ -z "$KPSEWHICH" ]]; then
    echo "none"
    return
  fi

  # Check for a package only in full installs
  if "$KPSEWHICH" pgfplots.sty &>/dev/null && "$KPSEWHICH" siunitx.sty &>/dev/null; then
    echo "full"
  else
    echo "minimal"
  fi
}

# --- Version mismatch fix ---
fix_version_mismatch() {
  [[ -z "$TLMGR" ]] && return

  local tl_ver
  tl_ver=$(detect_tl_version)
  [[ -z "$tl_ver" ]] && return

  echo "  Local TeX Live: $tl_ver"

  local update_out
  update_out=$("$TLMGR" update --self 2>&1) || true

  if echo "$update_out" | grep -qi "is older than remote\|cross release\|mismatch"; then
    _yellow "  Version mismatch — switching to historic repo for $tl_ver"
    local url="https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${tl_ver}/tlnet-final"
    "$TLMGR" option repository "$url" 2>&1 || true
    "$TLMGR" update --self 2>&1 | tail -2 || true
    _green "  Repository fixed: $url"
  fi
}

# --- Install TeX Live from scratch ---
install_texlive() {
  local platform="$1"

  case "$platform" in
    macos)
      if ! command -v brew &>/dev/null; then
        _red "ERROR: Homebrew not found. Install from https://brew.sh/"
        exit 1
      fi
      _bold "Installing MacTeX (full TeX Live + GUI tools) via Homebrew..."
      echo "  This downloads ~5GB. Please wait..."
      # Remove BasicTeX if present
      if brew list --cask basictex &>/dev/null; then
        _yellow "  Removing BasicTeX first..."
        brew uninstall --cask basictex || true
      fi
      brew install --cask mactex
      ;;

    debian)
      _bold "Installing TeX Live (full) via apt..."
      apt-get update -qq
      apt-get install -y texlive-full poppler-utils
      ;;

    fedora)
      _bold "Installing TeX Live (full) via dnf..."
      dnf install -y texlive-scheme-full poppler-utils
      ;;

    arch)
      _bold "Installing TeX Live (full) via pacman..."
      pacman -Syu --noconfirm texlive-most texlive-lang poppler
      ;;

    linux-generic)
      _bold "Installing TeX Live via official installer..."
      echo "  Downloading installer..."
      local tmp_dir
      tmp_dir=$(mktemp -d)
      cd "$tmp_dir"
      wget -q https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
      tar -xzf install-tl-unx.tar.gz
      cd install-tl-*/
      echo "  Running installer (scheme-full)... this may take 30+ minutes"
      ./install-tl --no-interaction --scheme=full
      cd /
      rm -rf "$tmp_dir"
      # Add to PATH hint
      _yellow "  Add to PATH: export PATH=/usr/local/texlive/\$(ls /usr/local/texlive/ | head -1)/bin/\$(uname -m)-linux:\$PATH"
      ;;

    *)
      _red "ERROR: Unsupported platform. Install TeX Live manually:"
      echo "  https://tug.org/texlive/acquire.html"
      exit 1
      ;;
  esac
}

# --- Install individual packages via tlmgr ---
install_packages() {
  [[ -z "$TLMGR" ]] && { _red "tlmgr not available"; return 1; }

  local PACKAGES=(
    # Critical
    siunitx pgfplots comment

    # Cross-references & formatting
    cleveref xcolor multirow booktabs wrapfig subcaption caption
    float enumitem pdfpages geometry fancyhdr titlesec

    # Bibliography
    natbib

    # Math
    mathtools amssymb amsmath amsthm bbm bm cancel cases dsfont empheq nicefrac units wasysym

    # Algorithms & code
    algorithm2e algorithmicx listings

    # Typography
    microtype hyperref url breakurl xurl

    # Graphics & diagrams
    tikz-cd pgf tcolorbox mdframed todonotes

    # Text formatting
    soul ulem

    # Tables
    arydshln colortbl makecell threeparttable adjustbox

    # Layout
    placeins sttools cuted flushend balance

    # Fonts
    cm-super ec lm newtx times txfonts

    # Supplementary
    appendix standalone
  )

  echo ""
  _bold "Installing ${#PACKAGES[@]} LaTeX packages..."
  "$TLMGR" install "${PACKAGES[@]}" 2>&1 | grep -E "install:|already|not found" || true
}

# --- Verify key packages ---
verify_packages() {
  find_tex_binaries  # refresh paths
  [[ -z "$KPSEWHICH" ]] && { _red "kpsewhich not found"; return 1; }

  echo ""
  _bold "Verifying key packages:"
  local all_ok=true
  for pkg in siunitx pgfplots comment cleveref natbib hyperref microtype booktabs pdfinfo; do
    if [[ "$pkg" == "pdfinfo" ]]; then
      if command -v pdfinfo &>/dev/null; then
        _green "  ✅ pdfinfo ($(pdfinfo -v 2>&1 | head -1))"
      else
        _yellow "  ⚠️  pdfinfo (optional, install poppler-utils for page counts)"
      fi
    elif "$KPSEWHICH" "${pkg}.sty" &>/dev/null; then
      _green "  ✅ $pkg"
    else
      _red "  ❌ $pkg"
      all_ok=false
    fi
  done

  echo ""
  if $all_ok; then
    _green "✅ TeX Live is ready. All papers should compile."
  else
    _yellow "⚠️  Some packages missing. Run: sudo bash setup-texlive.sh"
  fi
  return 0
}

# ========================
# Main
# ========================

MODE="full"
for arg in "$@"; do
  case "$arg" in
    --minimal) MODE="minimal" ;;
    --check)   MODE="check" ;;
    --help|-h)
      echo "Usage: sudo bash setup-texlive.sh [--minimal|--check]"
      echo ""
      echo "  (default)   Install full TeX Live + all packages"
      echo "  --minimal   Only install missing packages (requires existing TeX Live)"
      echo "  --check     Show what's installed (no sudo needed)"
      exit 0
      ;;
  esac
done

PLATFORM=$(detect_platform)
find_tex_binaries

echo ""
_bold "=== paperctl TeX Live Setup ==="
echo "  Platform: $PLATFORM"
echo "  Mode:     $MODE"
echo ""

# --- Check-only mode ---
if [[ "$MODE" == "check" ]]; then
  if [[ -n "$PDFLATEX" ]]; then
    local_ver=$(detect_tl_version)
    tl_type=$(detect_tl_type)
    _green "  TeX Live: $local_ver ($tl_type)"
    echo "  pdflatex: $PDFLATEX"
    echo "  tlmgr:    $TLMGR"
  else
    _red "  TeX Live: not installed"
  fi
  verify_packages
  exit 0
fi

# --- Sudo check for install modes ---
if [[ "$PLATFORM" != "macos" && $EUID -ne 0 ]]; then
  _red "This script must be run with sudo (except --check mode)"
  echo "  sudo bash $0 $*"
  exit 1
fi

# --- Full install ---
if [[ "$MODE" == "full" ]]; then
  tl_type=$(detect_tl_type)

  if [[ "$tl_type" == "full" ]]; then
    _green "Full TeX Live already installed."
    fix_version_mismatch
  elif [[ "$tl_type" == "minimal" ]]; then
    _yellow "Minimal TeX Live detected. Upgrading to full..."
    install_texlive "$PLATFORM"
    find_tex_binaries
  else
    _yellow "No TeX Live found. Installing full version..."
    install_texlive "$PLATFORM"
    find_tex_binaries
  fi
fi

# --- Minimal: just add packages ---
if [[ "$MODE" == "minimal" ]]; then
  if [[ -z "$TLMGR" ]]; then
    _red "No TeX Live found. Use full mode: sudo bash setup-texlive.sh"
    exit 1
  fi
  fix_version_mismatch
  install_packages
fi

# --- Always verify ---
verify_packages

echo ""
_green "Done. Run 'paperctl compile' to verify all papers compile."
