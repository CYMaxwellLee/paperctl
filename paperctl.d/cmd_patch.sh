#!/bin/bash
# paperctl.d/cmd_patch.sh -- Apply SEARCH/REPLACE patch files to papers
#
# Reads a markdown patch file containing SEARCH/REPLACE hunks and applies
# them to the specified paper. Supports dry-run mode to preview changes.
#
# Patch file format (markdown):
#   ## Patch Name
#   **File:** `sections/method.tex`
#
#   **SEARCH:**
#   ```
#   old text to find
#   ```
#
#   **REPLACE:**
#   ```
#   new text to replace with
#   ```
#
# Usage:
#   paperctl patch --paper ewm /path/to/patch.md          # apply
#   paperctl patch --paper ewm --dry-run /path/to/patch.md # preview
#   paperctl patch --paper ewm --reverse /path/to/patch.md # reverse

load_config
. "$PAPERCTL_LIB/lib_check.sh"

DRY_RUN=false
REVERSE=false
PATCH_FILE=""
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --reverse) REVERSE=true; shift ;;
    *) break ;;
  esac
done
PATCH_FILE="${1:-}"

if [[ -z "$PATCH_FILE" ]]; then
  echo "ERROR: Patch file path required." >&2
  echo "Usage: paperctl patch --paper <name> [--dry-run] <patch.md>" >&2
  exit 1
fi

if [[ ! -f "$PATCH_FILE" ]]; then
  echo "ERROR: Patch file not found: $PATCH_FILE" >&2
  exit 1
fi

if [[ -z "${PAPERCTL_PAPER:-}" ]]; then
  echo "ERROR: --paper <name> is required for patch command." >&2
  exit 1
fi

# Parse patch file using Python
_parse_and_apply() {
  local patch_file="$1" repo_dir="$2" dry_run="$3" reverse="$4"

  python3 - "$patch_file" "$repo_dir" "$dry_run" "$reverse" << 'PYEOF'
import re, os, sys

patch_file = sys.argv[1]
repo_dir = sys.argv[2]
dry_run = sys.argv[3] == 'true'
reverse = sys.argv[4] == 'true'

with open(patch_file, 'r') as f:
    content = f.read()

# Parse hunks
# Look for patterns: **File:** `path`, **SEARCH:** ```...```, **REPLACE:** ```...```
hunks = []
# Split by ## headers or --- separators
sections = re.split(r'^(?:##\s+|---\s*$)', content, flags=re.MULTILINE)

for section in sections:
    if not section.strip():
        continue

    # Extract patch name (first line)
    lines = section.strip().split('\n')
    patch_name = lines[0].strip().rstrip('#').strip() if lines else 'unnamed'

    # Find file path
    file_match = re.search(r'\*\*(?:File|TARGET)\s*:?\*\*\s*`([^`]+)`', section, re.IGNORECASE)
    if not file_match:
        # Also try: File: `path` without bold
        file_match = re.search(r'(?:File|TARGET)\s*:\s*`([^`]+)`', section, re.IGNORECASE)
    if not file_match:
        continue

    target_file = file_match.group(1)

    # Find SEARCH block
    search_match = re.search(
        r'\*\*SEARCH\s*:?\*\*\s*\n```[^\n]*\n(.*?)```',
        section, re.DOTALL | re.IGNORECASE
    )
    if not search_match:
        # Alt format: SEARCH: without bold
        search_match = re.search(
            r'SEARCH\s*:\s*\n```[^\n]*\n(.*?)```',
            section, re.DOTALL | re.IGNORECASE
        )
    if not search_match:
        continue

    search_text = search_match.group(1)
    # Strip trailing newline (fence artifact)
    if search_text.endswith('\n'):
        search_text = search_text[:-1]

    # Find REPLACE block
    replace_match = re.search(
        r'\*\*REPLACE\s*:?\*\*\s*\n```[^\n]*\n(.*?)```',
        section, re.DOTALL | re.IGNORECASE
    )
    if not replace_match:
        replace_match = re.search(
            r'REPLACE\s*:\s*\n```[^\n]*\n(.*?)```',
            section, re.DOTALL | re.IGNORECASE
        )

    replace_text = ''
    if replace_match:
        replace_text = replace_match.group(1)
        if replace_text.endswith('\n'):
            replace_text = replace_text[:-1]

    hunks.append({
        'name': patch_name,
        'file': target_file,
        'search': search_text,
        'replace': replace_text
    })

if not hunks:
    print("  ⚠️  No valid SEARCH/REPLACE hunks found in patch file.")
    sys.exit(0)

print(f"  Found {len(hunks)} hunk(s) in patch file\n")

applied = 0
skipped = 0
failed = 0

for i, hunk in enumerate(hunks, 1):
    name = hunk['name']
    target = os.path.join(repo_dir, hunk['file'])
    search = hunk['search']
    replace = hunk['replace']

    if reverse:
        search, replace = replace, search

    prefix = f"  [{i}/{len(hunks)}] {name}"

    if not os.path.exists(target):
        print(f"{prefix}")
        print(f"    ❌ File not found: {hunk['file']}")
        failed += 1
        continue

    with open(target, 'r', errors='replace') as f:
        file_content = f.read()

    if search not in file_content:
        # Try with normalized whitespace
        normalized_search = re.sub(r'\s+', ' ', search.strip())
        normalized_content = re.sub(r'\s+', ' ', file_content)
        if normalized_search in normalized_content:
            print(f"{prefix}")
            print(f"    ⚠️  SEARCH found with whitespace differences — skipping (needs manual)")
            skipped += 1
        elif replace and replace in file_content:
            print(f"{prefix}")
            print(f"    ⏭️  Already applied")
            skipped += 1
        else:
            print(f"{prefix}")
            print(f"    ❌ SEARCH not found in {hunk['file']}")
            # Show first 60 chars of search
            preview = search[:60].replace('\n', '↵')
            print(f"       Looking for: \"{preview}...\"")
            failed += 1
        continue

    if dry_run:
        print(f"{prefix}")
        print(f"    🔍 Would apply to {hunk['file']}")
        search_preview = search[:80].replace('\n', '↵')
        replace_preview = replace[:80].replace('\n', '↵') if replace else '(delete)'
        print(f"       - \"{search_preview}\"")
        print(f"       + \"{replace_preview}\"")
        applied += 1
    else:
        new_content = file_content.replace(search, replace, 1)
        with open(target, 'w') as f:
            f.write(new_content)
        print(f"{prefix}")
        print(f"    ✅ Applied to {hunk['file']}")
        applied += 1

print(f"\n  📊 Result: ✅ {applied} applied | ⏭️ {skipped} skipped | ❌ {failed} failed")
if dry_run:
    print("  ℹ️  Dry-run mode — no files modified")
PYEOF
}

# Find the paper's repo dir
_patch_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  echo ""
  echo "🩹 Applying patch to $name"
  echo "   Source: $(basename "$PATCH_FILE")"
  echo ""

  _parse_and_apply "$PATCH_FILE" "$repo_dir" "$DRY_RUN" "$REVERSE"
}

for_each_paper _patch_paper
echo ""
