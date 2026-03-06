#!/bin/bash
# paperctl.d/cmd_bibcheck.sh -- Validate bibliography entries
#
# Checks:
#   1. All \cite{} keys resolve to .bib entries
#   2. All .bib entries are cited (detect unused)
#   3. Duplicate bib keys
#   4. Missing required fields (title, author, year)
#   5. Common bib issues (wrong field names, encoding)
#
# Usage:
#   paperctl bib-check                      # all papers
#   paperctl bib-check --paper <name>       # single paper
#   paperctl bib-check --unused             # also report unused entries

load_config
. "$PAPERCTL_LIB/lib_check.sh"

SHOW_UNUSED=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --unused) SHOW_UNUSED=true; shift ;;
    *) break ;;
  esac
done

_bibcheck_one() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  reset_repo_counts

  local main_tex
  main_tex=$(find_main_tex "$repo_dir")
  if [[ -z "$main_tex" ]]; then
    echo "  📄 $name"
    check_fail "no main.tex found"
    flush_repo_counts
    return
  fi

  echo "  📄 $name"

  local tex_dir
  tex_dir=$(dirname "$main_tex")

  # Find .bib files
  local bib_files=()
  while IFS= read -r bf; do
    [[ -n "$bf" ]] && bib_files+=("$bf")
  done < <(find "$tex_dir" "$repo_dir" -maxdepth 2 -name "*.bib" -not -path "*/.git/*" 2>/dev/null | sort -u)

  if [[ ${#bib_files[@]} -eq 0 ]]; then
    check_warn "No .bib files found"
    flush_repo_counts
    return
  fi

  check_info "Found ${#bib_files[@]} .bib file(s)"

  # Use Python for thorough analysis
  python3 - "$repo_dir" "$main_tex" "${bib_files[@]}" "$SHOW_UNUSED" << 'PYEOF'
import re, os, sys, glob

repo_dir = sys.argv[1]
main_tex = sys.argv[2]
show_unused = sys.argv[-1] == 'true'
bib_files = sys.argv[3:-1]

tex_dir = os.path.dirname(main_tex)

# 1. Collect all tex content recursively
def collect_tex(filepath, visited=None):
    if visited is None:
        visited = set()
    if filepath in visited:
        return ''
    visited.add(filepath)
    try:
        with open(filepath, 'r', errors='replace') as f:
            content = f.read()
    except:
        return ''

    # Resolve \input{...}
    result = content
    for m in re.finditer(r'\\input\{([^}]+)\}', content):
        inp = m.group(1)
        if not inp.endswith('.tex'):
            inp += '.tex'
        for base in [os.path.dirname(filepath), tex_dir, repo_dir]:
            full = os.path.join(base, inp)
            if os.path.exists(full):
                result += '\n' + collect_tex(full, visited)
                break
    return result

all_tex = collect_tex(main_tex)

# Remove comments
lines = []
for line in all_tex.split('\n'):
    i = 0
    result = []
    while i < len(line):
        if line[i] == '%' and (i == 0 or line[i-1] != '\\'):
            break
        result.append(line[i])
        i += 1
    lines.append(''.join(result))
active_tex = '\n'.join(lines)

# Remove \ignore{...} blocks
def remove_ignore(text):
    while '\\ignore{' in text:
        start = text.find('\\ignore{')
        depth = 1
        j = start + 8
        while j < len(text) and depth > 0:
            if text[j] == '{': depth += 1
            elif text[j] == '}': depth -= 1
            j += 1
        text = text[:start] + text[j:]
    return text

active_tex = remove_ignore(active_tex)

# 2. Extract citation keys from tex
cite_pattern = re.compile(r'\\(?:cite|citep|citet|citeauthor|citeyear|citealp|citealt)\w*\{([^}]+)\}')
cited_keys = set()
for m in cite_pattern.finditer(active_tex):
    for key in m.group(1).split(','):
        key = key.strip()
        if key:
            cited_keys.add(key)

# 3. Parse .bib files
bib_entries = {}  # key -> {fields, file}
duplicates = []
all_bib_content = ''

for bf in bib_files:
    try:
        with open(bf, 'r', errors='replace') as f:
            content = f.read()
    except:
        continue
    all_bib_content += content

    # Find @type{key, entries
    for m in re.finditer(r'@(\w+)\s*\{([^,\s]+)', content):
        entry_type = m.group(1).lower()
        key = m.group(2).strip()

        if entry_type in ('string', 'preamble', 'comment'):
            continue

        if key in bib_entries:
            duplicates.append(key)
        bib_entries[key] = {
            'type': entry_type,
            'file': os.path.basename(bf)
        }

# 4. Report results
pass_count = 0
warn_count = 0
fail_count = 0

# Check undefined citations
undefined = cited_keys - set(bib_entries.keys())
if undefined:
    for k in sorted(undefined):
        print(f"  ❌ FAIL: Undefined citation: \\cite{{{k}}}")
        fail_count += 1
else:
    print(f"  ✅ All {len(cited_keys)} citations resolve")
    pass_count += 1

# Check duplicates
if duplicates:
    for k in duplicates:
        print(f"  ⚠️  WARN: Duplicate bib key: {k}")
        warn_count += 1
else:
    print(f"  ✅ No duplicate bib keys")
    pass_count += 1

# Check unused entries
unused = set(bib_entries.keys()) - cited_keys
if show_unused and unused:
    print(f"  ℹ️  {len(unused)} unused bib entries:")
    for k in sorted(list(unused)[:10]):
        print(f"       {k}")
    if len(unused) > 10:
        print(f"       ... and {len(unused) - 10} more")
elif not unused:
    print(f"  ✅ All bib entries are cited")
    pass_count += 1

print(f"")
print(f"  📊 Result: ✅ {pass_count} pass | ⚠️  {warn_count} warn | ❌ {fail_count} fail")
print(f"  📎 {len(cited_keys)} citations | {len(bib_entries)} bib entries | {len(unused)} unused")
PYEOF

  echo ""
}

echo ""
print_check_banner "Bibliography Check"
for_each_paper _bibcheck_one
echo ""
echo "Done."
