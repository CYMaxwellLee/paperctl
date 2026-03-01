#!/bin/bash
# paperctl.d/cmd_strip.sh -- Strip \cyl{} wrappers for camera-ready
#
# Creates clean copies in _clean/ subdirectory (original files untouched).
# Stripping includes:
#   - \cyl{content}  -->  content  (unwrap, preserve inner text)
#   - \tingru{content}  -->  content  (same)
#   - Optionally remove commented-out blocks (--remove-comments)
#
# The _clean/ directory mirrors the file structure of sections/.
# Original files are NEVER modified (they serve as the editing record).
#
# Usage:
#   paperctl strip [--paper <name>]                    # create _clean/ copies
#   paperctl strip [--paper <name>] --remove-comments  # also strip % comment blocks
#   paperctl strip [--paper <name>] --diff             # show diff without writing

load_config
. "$PAPERCTL_LIB/lib_check.sh"

REMOVE_COMMENTS=false
DIFF_ONLY=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --remove-comments) REMOVE_COMMENTS=true; shift ;;
    --diff) DIFF_ONLY=true; shift ;;
    *) break ;;
  esac
done

# --- Python helper for brace-aware \cyl{} stripping ---
_strip_macros() {
  local input_file="$1"
  python3 -c "
import re, sys

MACROS = ['cyl', 'tingru']
remove_comments = sys.argv[2] == 'true'

with open(sys.argv[1], 'r') as f:
    text = f.read()

def strip_macro(text, macro):
    \"\"\"Remove \\\\macro{content} -> content, handling nested braces.\"\"\"
    pattern = '\\\\' + macro + '{'
    result = []
    i = 0
    while i < len(text):
        # Check for macro
        if text[i:i+len(pattern)] == pattern:
            # Skip \\macro{
            j = i + len(pattern)
            depth = 1
            start = j
            while j < len(text) and depth > 0:
                if text[j] == '{' and (j == 0 or text[j-1] != '\\\\'):
                    depth += 1
                elif text[j] == '}' and (j == 0 or text[j-1] != '\\\\'):
                    depth -= 1
                j += 1
            # text[start:j-1] is the content inside braces
            result.append(text[start:j-1])
            i = j
        else:
            result.append(text[i])
            i += 1
    return ''.join(result)

for macro in MACROS:
    text = strip_macro(text, macro)

if remove_comments:
    # Remove lines that are entirely comments (preserving blank lines)
    lines = text.split('\n')
    cleaned = []
    in_comment_block = False
    for line in lines:
        stripped = line.lstrip()
        if stripped.startswith('%'):
            # Check if this is a meaningful comment (like % --- Section Header ---)
            # Keep section markers, remove substantive commented-out content
            if re.match(r'^%\s*[-=]{3,}', stripped):
                cleaned.append(line)  # Keep section dividers
            # Skip other comment lines (commented-out content)
            continue
        cleaned.append(line)
    text = '\n'.join(cleaned)

print(text, end='')
" "$input_file" "$REMOVE_COMMENTS"
}

_strip_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  $name ($repo)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local main_tex
  main_tex=$(find_main_tex "$repo_dir")
  if [[ -z "$main_tex" ]]; then
    echo "  No main .tex found, skipping."
    echo ""
    return
  fi

  local tex_dir
  tex_dir=$(dirname "$main_tex")

  # Find all .tex files that contain \cyl or \tingru
  local target_files=()
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if grep -qE '\\(cyl|tingru)\{' "$f" 2>/dev/null; then
      target_files+=("$f")
    fi
  done < <(find "$tex_dir" -name "*.tex" -not -path "*/_clean/*" -not -path "*/.git/*" 2>/dev/null)

  if [[ ${#target_files[@]} -eq 0 ]]; then
    echo "  No \\cyl{} or \\tingru{} found, nothing to strip."
    echo ""
    return
  fi

  echo "  Found ${#target_files[@]} file(s) with \\cyl{}/\\tingru{}"

  if $DIFF_ONLY; then
    # Show diff preview
    for f in "${target_files[@]}"; do
      local rel_path="${f#$repo_dir/}"
      echo ""
      echo "  --- $rel_path ---"
      local stripped
      stripped=$(_strip_macros "$f")
      diff --color=auto <(cat "$f") <(echo "$stripped") | head -40 || true
    done
    echo ""
    echo "  (diff preview, no files written)"
  else
    # Create _clean/ directory
    local clean_dir="$repo_dir/_clean"
    mkdir -p "$clean_dir"

    local count=0
    for f in "${target_files[@]}"; do
      local rel_path="${f#$repo_dir/}"
      local out_dir="$clean_dir/$(dirname "$rel_path")"
      mkdir -p "$out_dir"
      local out_file="$clean_dir/$rel_path"

      _strip_macros "$f" > "$out_file"
      count=$((count + 1))

      # Count stripped macros
      local cyl_count tingru_count
      cyl_count=$(grep -oE '\\cyl\{' "$f" 2>/dev/null | wc -l | tr -d ' ')
      tingru_count=$(grep -oE '\\tingru\{' "$f" 2>/dev/null | wc -l | tr -d ' ')
      echo "  $rel_path  -->  _clean/$rel_path  (\\cyl: $cyl_count, \\tingru: $tingru_count)"
    done

    # Also copy non-macro files needed for compilation
    # (main.tex, preamble, bib, cls, sty, figures)
    for ext in tex cls sty bst bib; do
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        local rel_path="${f#$repo_dir/}"
        # Skip if already in _clean/ or if already processed
        [[ "$rel_path" == _clean/* ]] && continue
        local out_file="$clean_dir/$rel_path"
        if [[ ! -f "$out_file" ]]; then
          local out_dir="$clean_dir/$(dirname "$rel_path")"
          mkdir -p "$out_dir"
          cp "$f" "$out_file"
        fi
      done < <(find "$tex_dir" -maxdepth 1 -name "*.$ext" 2>/dev/null)
    done

    echo ""
    echo "  Clean files: $clean_dir/"
    echo "  Originals:   untouched"
    echo "  $count file(s) stripped"

    # Add _clean/ to .gitignore if not already there
    local gitignore="$repo_dir/.gitignore"
    if [[ -f "$gitignore" ]]; then
      if ! grep -qxF '_clean/' "$gitignore" 2>/dev/null; then
        echo '_clean/' >> "$gitignore"
        echo "  Added _clean/ to .gitignore"
      fi
    else
      echo '_clean/' > "$gitignore"
      echo "  Created .gitignore with _clean/"
    fi
  fi

  echo ""
}

echo ""
echo "=========================================="
if $DIFF_ONLY; then
  echo "  Strip Preview (dry run)"
elif $REMOVE_COMMENTS; then
  echo "  Strip \\cyl{}/\\tingru{} + Comments"
else
  echo "  Strip \\cyl{}/\\tingru{}"
fi
echo "=========================================="
echo ""

for_each_paper _strip_paper

echo "Done."
