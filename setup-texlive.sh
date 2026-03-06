#!/bin/bash
# setup-texlive.sh -- Install commonly needed LaTeX packages for conference papers
# Run with: sudo bash setup-texlive.sh
#
# Handles TeX Live version mismatch automatically (e.g. local 2025 vs remote 2026)
# by pointing tlmgr to the correct historic repository.

set -euo pipefail

TLMGR="/Library/TeX/texbin/tlmgr"
KPSEWHICH="/Library/TeX/texbin/kpsewhich"

# Fallback: check PATH
if [[ ! -x "$TLMGR" ]]; then
  TLMGR=$(command -v tlmgr 2>/dev/null || true)
  KPSEWHICH=$(command -v kpsewhich 2>/dev/null || true)
fi

if [[ -z "$TLMGR" ]]; then
  echo "ERROR: tlmgr not found. Install TeX Live first:" >&2
  echo "  macOS: brew install --cask basictex" >&2
  echo "  Linux: apt install texlive-base" >&2
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run with sudo:"
  echo "  sudo bash $0"
  exit 1
fi

# --- Detect and fix TeX Live version mismatch ---
echo "=== Checking TeX Live version ==="

# Multiple detection methods (the grep pattern varies across TeX Live versions)
TL_VERSION=""

# Method 1: "version YYYY" at end of tlmgr --version output
if [[ -z "$TL_VERSION" ]]; then
  TL_VERSION=$("$TLMGR" --version 2>&1 | grep -o 'version [0-9]*' | grep -o '[0-9]*' | head -1) || true
fi

# Method 2: installation path contains year (e.g. /usr/local/texlive/2025basic)
if [[ -z "$TL_VERSION" ]]; then
  TL_VERSION=$("$TLMGR" --version 2>&1 | grep -o 'texlive/[0-9]*' | grep -o '[0-9]*' | head -1) || true
fi

# Method 3: kpsewhich SELFAUTOPARENT (e.g. /usr/local/texlive/2025basic)
if [[ -z "$TL_VERSION" && -n "$KPSEWHICH" ]]; then
  TL_VERSION=$("$KPSEWHICH" -var-value SELFAUTOPARENT 2>/dev/null | grep -o '[0-9]\{4\}' | head -1) || true
fi

if [[ -z "$TL_VERSION" ]]; then
  echo "  ⚠️  Could not detect TeX Live version."
  echo "  Trying default repository..."
  "$TLMGR" update --self 2>&1 | tail -2 || true
else
  echo "  Local TeX Live version: $TL_VERSION"

  # Try update; capture output to detect version mismatch
  UPDATE_OUTPUT=$("$TLMGR" update --self 2>&1) || true
  UPDATE_RC=$?

  if echo "$UPDATE_OUTPUT" | grep -qi "is older than remote\|repository version.*does not match\|cross release\|mismatch"; then
    echo "  ⚠️  Version mismatch detected (local $TL_VERSION vs newer remote)."
    echo "  Switching to historic repository..."
    HISTORIC_URL="https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${TL_VERSION}/tlnet-final"
    echo "  Setting repository: $HISTORIC_URL"
    "$TLMGR" option repository "$HISTORIC_URL" 2>&1
    echo "  ✅ Repository updated to $TL_VERSION historic"
    echo ""
    echo "  Retrying tlmgr update..."
    "$TLMGR" update --self 2>&1 | tail -3 || true
  elif [[ $UPDATE_RC -ne 0 ]]; then
    # tlmgr update failed for another reason — try historic as fallback
    echo "  ⚠️  tlmgr update failed. Trying historic repository as fallback..."
    HISTORIC_URL="https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${TL_VERSION}/tlnet-final"
    echo "  Setting repository: $HISTORIC_URL"
    "$TLMGR" option repository "$HISTORIC_URL" 2>&1
    echo "  ✅ Repository updated to $TL_VERSION historic"
    "$TLMGR" update --self 2>&1 | tail -3 || true
  else
    echo "  ✅ tlmgr is up to date"
  fi
fi

PACKAGES=(
  # Critical: missing from many BasicTeX installs
  siunitx
  pgfplots
  comment

  # Cross-references & formatting
  cleveref
  xcolor
  multirow
  booktabs
  wrapfig
  subcaption
  caption
  float
  enumitem
  pdfpages
  geometry
  fancyhdr
  titlesec

  # Bibliography
  natbib

  # Math
  mathtools
  amssymb
  amsmath
  amsthm
  bbm
  bm
  cancel
  cases
  dsfont
  empheq
  nicefrac
  units
  wasysym

  # Algorithms & code
  algorithm2e
  algorithmicx
  listings

  # Typography
  microtype
  hyperref
  url
  breakurl
  xurl

  # Graphics & diagrams
  tikz-cd
  pgf
  tcolorbox
  mdframed
  todonotes

  # Text formatting
  soul
  ulem

  # Tables
  arydshln
  colortbl
  makecell
  threeparttable
  adjustbox

  # Layout
  placeins
  sttools
  cuted
  flushend
  balance

  # Fonts
  cm-super
  ec
  lm
  newtx
  times
  txfonts

  # Supplementary
  appendix
  standalone
)

echo ""
echo "=== Installing ${#PACKAGES[@]} packages ==="
"$TLMGR" install "${PACKAGES[@]}" 2>&1 | grep -E "install:|already|not found" || true

echo ""
echo "=== Verifying key packages ==="
ALL_OK=true
for pkg in siunitx pgfplots comment cleveref natbib hyperref microtype booktabs; do
  if "$KPSEWHICH" "${pkg}.sty" &>/dev/null; then
    echo "  ✅ $pkg"
  else
    echo "  ❌ $pkg -- FAILED"
    ALL_OK=false
  fi
done

echo ""
if $ALL_OK; then
  echo "✅ All packages installed. Conference papers should now compile locally."
else
  echo "⚠️  Some packages failed to install. Check errors above."
  echo "  If version mismatch persists, consider upgrading TeX Live:"
  echo "  https://tug.org/texlive/upgrade.html"
fi
