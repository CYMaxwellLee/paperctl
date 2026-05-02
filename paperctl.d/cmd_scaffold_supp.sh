#!/bin/bash
# paperctl.d/cmd_scaffold_supp.sh -- Generate standalone supp.tex from template
#
# Standard: supp.tex is the ONLY accepted filename.
#
# Usage:
#   paperctl scaffold-supp --paper <name>           # generate supp.tex
#   paperctl scaffold-supp --paper <name> --force    # overwrite existing
#   paperctl scaffold-supp --paper <name> --preview  # print to stdout (don't write)
#   paperctl scaffold-supp --all                     # generate for all papers

load_config

# --- Parse flags ---
FORCE=false
PREVIEW=false
ALL=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --force)   FORCE=true; shift ;;
    --preview) PREVIEW=true; shift ;;
    --all)     ALL=true; shift ;;
    *) break ;;
  esac
done

# --- Resolve template ---
TEMPLATE_FILE="$PAPERCTL_LIB/templates/${CONF_TEMPLATE}.supp.tex"
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "ERROR: No supp template found for conference type '$CONF_TEMPLATE'" >&2
  echo "  Expected: $TEMPLATE_FILE" >&2
  echo "  Available:" >&2
  ls "$PAPERCTL_LIB/templates/"*.supp.tex 2>/dev/null | sed 's/.*\//    /' >&2
  exit 1
fi

# --- Scaffold one paper ---
_scaffold_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  # Get paper metadata
  local idx title paper_id
  idx=$(paper_index_by_name "$name")
  title=$(paper_field "$idx" "title")
  paper_id=$(paper_field "$idx" "paper_id")
  [[ "$title" == "null" || -z "$title" ]] && title="$name"
  [[ "$paper_id" == "null" ]] && paper_id=""

  # Determine where supp.tex should go (same dir as main.tex)
  local main_tex supp_dir supp_path
  main_tex=$(find "$repo_dir" -maxdepth 2 -name "main.tex" -not -path "*/.git/*" 2>/dev/null | head -1)
  if [[ -z "$main_tex" ]]; then
    supp_dir="$repo_dir"
  else
    supp_dir=$(dirname "$main_tex")
  fi
  supp_path="$supp_dir/supp.tex"

  # Check if supp.tex already exists
  if [[ -f "$supp_path" ]] && [[ "$FORCE" != "true" ]]; then
    echo "  ⏭️  $name: supp.tex already exists (use --force to overwrite)"
    return
  fi

  # Generate from template
  local content
  content=$(cat "$TEMPLATE_FILE")
  content="${content//__YEAR__/$CONF_YEAR}"
  content="${content//__TITLE__/$title}"
  content="${content//__PAPER_ID__/$paper_id}"
  content="${content//__CONF_NAME__/$CONF_NAME}"

  if [[ "$PREVIEW" == "true" ]]; then
    echo "═══ $name: supp.tex ═══"
    echo "$content"
    echo ""
    return
  fi

  echo "$content" > "$supp_path"
  echo "  ✅ $name: Generated supp.tex"
  echo "     📋 Standard sections: Notation Reference, Implementation Details,"
  echo "        Additional Experiments, Qualitative Results"
}

# --- Main ---
echo "📄 Scaffold Supplementary Material ($CONF_NAME $CONF_YEAR)"
echo "   Template: $(basename "$TEMPLATE_FILE")"
echo ""

if [[ "$ALL" == "true" ]]; then
  for_each_paper _scaffold_paper
elif [[ -n "${PAPERCTL_PAPER:-}" ]]; then
  require_paper_flag
  for_each_paper _scaffold_paper
else
  echo "ERROR: Specify --paper <name> or --all" >&2
  exit 1
fi
