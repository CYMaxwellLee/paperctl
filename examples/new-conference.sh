#!/bin/bash
# paperctl — New Conference Setup Guide
# Creates a new conference workspace with paperctl.
#
# Usage:
#   bash new-conference.sh
#
# What this script does:
#   1. Ask for conference details (name, year, template, org)
#   2. Create conference directory
#   3. Generate conference.json from template
#   4. Create meta repo on GitHub
#   5. Run paperctl init to bootstrap

set -euo pipefail

# ─── Colors ───
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

echo ""
bold "══════════════════════════════════════"
bold "  paperctl — New Conference Setup"
bold "══════════════════════════════════════"
echo ""

# ─── Step 1: Conference details ───
bold "Step 1/4: Conference details"

read -rp "  Conference name (e.g., ECCV, NeurIPS, CVPR): " CONF_NAME
read -rp "  Year (e.g., 2026): " CONF_YEAR
read -rp "  Template (eccv/cvpr/neurips): " CONF_TEMPLATE
read -rp "  GitHub org or user (e.g., ElsaLab-2026): " CONF_ORG
read -rp "  Deadline ISO 8601 (e.g., 2026-03-05T22:00:00Z, or empty): " CONF_DEADLINE

CONF_SLUG=$(echo "${CONF_NAME,,}${CONF_YEAR}" | tr -d ' ')
CONF_DIR="${HOME}/Project/Papers/${CONF_SLUG}"

echo ""
echo "  Slug: $CONF_SLUG"
echo "  Directory: $CONF_DIR"
echo ""

# ─── Step 2: Create directory ───
bold "Step 2/4: Create workspace"

if [[ -d "$CONF_DIR" ]]; then
  yellow "  Directory already exists: $CONF_DIR"
else
  mkdir -p "$CONF_DIR"
  green "  Created: $CONF_DIR"
fi
echo ""

# ─── Step 3: Generate conference.json ───
bold "Step 3/4: Generate conference.json"

CONF_FILE="$CONF_DIR/conference.json"
if [[ -f "$CONF_FILE" ]]; then
  yellow "  conference.json already exists. Skipping."
else
  # Build deadline field
  DEADLINE_FIELD=""
  if [[ -n "$CONF_DEADLINE" ]]; then
    DEADLINE_FIELD=",
    \"deadline\": \"$CONF_DEADLINE\""
  fi

  cat > "$CONF_FILE" << ENDJSON
{
  "conference": {
    "name": "$CONF_NAME",
    "year": $CONF_YEAR,
    "slug": "$CONF_SLUG",
    "template": "$CONF_TEMPLATE",
    "org": "$CONF_ORG"$DEADLINE_FIELD
  },
  "defaults": {
    "github_branch": "main",
    "overleaf_branch": "master",
    "overleaf_remote": "overleaf",
    "upstream_remote": "upstream",
    "upstream_branch": ""
  },
  "papers": [
  ]
}
ENDJSON

  green "  Generated: $CONF_FILE"
  echo ""
  echo "  Add your papers to the 'papers' array. Example:"
  echo ""
  echo '    {
      "name": "my-paper",
      "repo": "'$CONF_SLUG'-my-paper",
      "overleaf": "https://git.overleaf.com/YOUR_PROJECT_ID",
      "title": "My Paper Title",
      "domain": "Computer Vision",
      "status": "early"
    }'
  echo ""
  echo "  For fork repos, add:"
  echo '    "upstream": "student-user/their-repo"'
  echo ""
fi
echo ""

# ─── Step 4: Meta repo ───
bold "Step 4/4: Meta repo (optional)"

echo "  A meta repo tracks conference.json, STATUS.md, and README dashboard."
echo "  Recommended: create ${CONF_SLUG}-meta on GitHub."
echo ""
read -rp "  Create meta repo on GitHub now? (y/n): " CREATE_META

if [[ "$CREATE_META" == "y" || "$CREATE_META" == "Y" ]]; then
  if command -v gh &>/dev/null; then
    META_REPO="${CONF_SLUG}-meta"
    echo "  Creating $CONF_ORG/$META_REPO on GitHub..."
    gh repo create "$CONF_ORG/$META_REPO" --private --description "$CONF_NAME $CONF_YEAR paper management meta" 2>/dev/null || true

    cd "$CONF_DIR"
    mkdir -p "$META_REPO"
    cd "$META_REPO"
    git init
    cp "$CONF_FILE" conference.json

    # Point root conference.json to meta
    rm -f "$CONF_FILE"
    ln -sf "$META_REPO/conference.json" "$CONF_FILE"

    git add conference.json
    git commit -m "init: conference.json for $CONF_NAME $CONF_YEAR"
    git branch -M main
    git remote add origin "https://github.com/$CONF_ORG/$META_REPO.git"
    git push -u origin main

    green "  Meta repo created and pushed!"
    green "  conference.json is now tracked in $META_REPO"
  else
    yellow "  'gh' CLI not found. Install: brew install gh"
    echo "  Create the repo manually, then:"
    echo "    mkdir $CONF_DIR/${CONF_SLUG}-meta"
    echo "    mv $CONF_FILE ${CONF_SLUG}-meta/conference.json"
    echo "    ln -sf ${CONF_SLUG}-meta/conference.json $CONF_FILE"
  fi
fi

echo ""
green "══════════════════════════════════════"
green "  Conference workspace ready!"
green "══════════════════════════════════════"
echo ""
echo "  Next steps:"
echo "    1. Edit conference.json — add your papers"
echo "    2. cd $CONF_DIR && paperctl init"
echo "    3. paperctl start"
echo ""
echo "  Useful commands:"
echo "    paperctl status                     # overview"
echo "    paperctl sync --parallel            # sync all repos"
echo "    paperctl dashboard --output ${CONF_SLUG}-meta/README.md"
echo ""
