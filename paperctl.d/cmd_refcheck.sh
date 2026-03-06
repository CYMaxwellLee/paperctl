#!/bin/bash
# paperctl.d/cmd_refcheck.sh -- Check cross-references (labels, refs, cites)
#
# Checks:
#   1. Undefined \ref/\cref/\Cref/\eqref references
#   2. Unused \label definitions
#   3. Missing figure/table files referenced in LaTeX
#   4. \ref used instead of \cref (style violation)
#
# Usage:
#   paperctl ref-check                      # all papers
#   paperctl ref-check --paper <name>       # single paper

load_config
. "$PAPERCTL_LIB/lib_check.sh"

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    *) break ;;
  esac
done

_refcheck_one() {
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

  python3 - "$repo_dir" "$main_tex" << 'PYEOF'
import re, os, sys

repo_dir = sys.argv[1]
main_tex = sys.argv[2]
tex_dir = os.path.dirname(main_tex)

# Collect all tex recursively
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

# Strip comments
lines = []
for line in all_tex.split('\n'):
    i = 0
    result_chars = []
    while i < len(line):
        if line[i] == '%' and (i == 0 or line[i-1] != '\\'):
            break
        result_chars.append(line[i])
        i += 1
    lines.append(''.join(result_chars))
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

pass_count = 0
warn_count = 0
fail_count = 0

# 1. Extract all labels
labels = set()
for m in re.finditer(r'\\label\{([^}]+)\}', active_tex):
    labels.add(m.group(1))

# 2. Extract all references
ref_cmds = re.findall(r'\\(?:c?ref|Cref|eqref|autoref)\{([^}]+)\}', active_tex)
referenced = set()
for refs_str in ref_cmds:
    for r in refs_str.split(','):
        r = r.strip()
        if r:
            referenced.add(r)

# 3. Check undefined references
undefined_refs = referenced - labels
if undefined_refs:
    for r in sorted(undefined_refs):
        print(f"  ❌ FAIL: Undefined reference: \\cref{{{r}}}")
        fail_count += 1
else:
    print(f"  ✅ All {len(referenced)} cross-references resolve")
    pass_count += 1

# 4. Check unused labels
unused_labels = labels - referenced
if unused_labels:
    # Only warn for non-equation labels (equations may be referenced later)
    important_unused = [l for l in unused_labels if not l.startswith('eq:')]
    eq_unused = [l for l in unused_labels if l.startswith('eq:')]
    if important_unused:
        for l in sorted(important_unused)[:8]:
            print(f"  ⚠️  WARN: Unused label: \\label{{{l}}}")
            warn_count += 1
        if len(important_unused) > 8:
            print(f"  ⚠️  WARN: ... and {len(important_unused) - 8} more unused labels")
            warn_count += 1
    if eq_unused:
        print(f"  ℹ️  {len(eq_unused)} unused equation labels (may be intentional)")
else:
    print(f"  ✅ All labels are referenced")
    pass_count += 1

# 5. Check \ref vs \cref (style check)
bare_refs = re.findall(r'(?<!c)(?<!C)(?<!auto)(?<!eq)\\ref\{([^}]+)\}', active_tex)
if bare_refs:
    unique_bare = set(bare_refs)
    print(f"  ⚠️  WARN: {len(unique_bare)} uses of \\ref{{}} instead of \\cref{{}}")
    for r in sorted(unique_bare)[:5]:
        print(f"       \\ref{{{r}}} → should be \\cref{{{r}}}")
    warn_count += 1
else:
    print(f"  ✅ All references use \\cref (good style)")
    pass_count += 1

# 6. Check \includegraphics files exist
graphics_pattern = re.compile(r'\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}')
missing_graphics = []
for m in graphics_pattern.finditer(active_tex):
    path = m.group(1)
    # Check with common extensions
    found = False
    for base in [tex_dir, repo_dir]:
        for ext in ['', '.pdf', '.png', '.jpg', '.jpeg', '.eps']:
            full = os.path.join(base, path + ext)
            if os.path.exists(full):
                found = True
                break
        if found:
            break
    if not found:
        missing_graphics.append(path)

if missing_graphics:
    for p in missing_graphics[:5]:
        print(f"  ❌ FAIL: Missing figure: {p}")
        fail_count += 1
    if len(missing_graphics) > 5:
        print(f"  ❌ FAIL: ... and {len(missing_graphics) - 5} more missing figures")
        fail_count += 1
else:
    total_graphics = len(graphics_pattern.findall(active_tex))
    if total_graphics > 0:
        print(f"  ✅ All {total_graphics} figure files exist")
        pass_count += 1

print(f"")
print(f"  📊 Result: ✅ {pass_count} pass | ⚠️  {warn_count} warn | ❌ {fail_count} fail")
print(f"  🏷️  {len(labels)} labels | {len(referenced)} references")
PYEOF

  echo ""
}

echo ""
print_check_banner "Cross-Reference Check"
for_each_paper _refcheck_one
echo ""
echo "Done."
