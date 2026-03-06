#!/bin/bash
# paperctl.d/cmd_wordcount.sh -- Word count per section for all papers
#
# Reports word counts per section, total content words, and
# identifies thin sections. Uses Python to strip LaTeX commands
# and count actual prose words.
#
# Usage:
#   paperctl wordcount                    # all papers
#   paperctl wordcount --paper <name>     # single paper
#   paperctl wordcount --sections         # section-level breakdown (default)
#   paperctl wordcount --summary          # totals only

load_config
. "$PAPERCTL_LIB/lib_check.sh"

SHOW_SECTIONS=true
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --summary) SHOW_SECTIONS=false; shift ;;
    --sections) SHOW_SECTIONS=true; shift ;;
    *) break ;;
  esac
done

# Python helper for word counting
_wordcount_py() {
  python3 - "$@" << 'PYEOF'
import re, os, sys, json

def strip_comments(text):
    """Remove LaTeX comments (lines starting with %) but keep \\%."""
    lines = []
    for line in text.split('\n'):
        # Remove comments: find unescaped %
        result = []
        i = 0
        while i < len(line):
            if line[i] == '%' and (i == 0 or line[i-1] != '\\'):
                break
            result.append(line[i])
            i += 1
        lines.append(''.join(result))
    return '\n'.join(lines)

def strip_latex(text):
    """Strip LaTeX commands, environments, math to get prose words."""
    # Remove \ignore{...} blocks (nested braces)
    depth = 0
    result = []
    i = 0
    ignore_start = text.find('\\ignore{')
    while ignore_start >= 0:
        result.append(text[i:ignore_start])
        depth = 1
        j = ignore_start + 8
        while j < len(text) and depth > 0:
            if text[j] == '{': depth += 1
            elif text[j] == '}': depth -= 1
            j += 1
        i = j
        ignore_start = text.find('\\ignore{', i)
    result.append(text[i:])
    text = ''.join(result)

    # Remove display math
    text = re.sub(r'\$\$.*?\$\$', ' ', text, flags=re.DOTALL)
    text = re.sub(r'\\\[.*?\\\]', ' ', text, flags=re.DOTALL)
    text = re.sub(r'\\begin\{(equation|align|gather|multline)\*?\}.*?\\end\{\1\*?\}', ' ', text, flags=re.DOTALL)
    # Remove inline math
    text = re.sub(r'\$[^$]+\$', ' MATH ', text)
    # Remove figures/tables environments
    text = re.sub(r'\\begin\{(figure|table|tabular|algorithm)\*?\}.*?\\end\{\1\*?\}', ' ', text, flags=re.DOTALL)
    # Remove common commands but keep their text arguments
    text = re.sub(r'\\(textbf|textit|emph|cyl|kwns|yang|tingru|textcolor)\{[^}]*\}\{', ' ', text)
    text = re.sub(r'\\(textbf|textit|emph|cyl|kwns|yang|tingru)\{', ' ', text)
    # Remove \cite, \ref, \cref, \label commands
    text = re.sub(r'\\(cite|ref|cref|Cref|eqref|label|autoref)\{[^}]*\}', ' ', text)
    # Remove remaining commands
    text = re.sub(r'\\[a-zA-Z]+(\[[^\]]*\])?(\{[^}]*\})?', ' ', text)
    # Remove braces
    text = re.sub(r'[{}]', ' ', text)
    # Remove special chars
    text = re.sub(r'[~\\&%#_^]', ' ', text)
    return text

def count_words(text):
    """Count actual words (no numbers-only tokens, no single chars)."""
    text = strip_latex(strip_comments(text))
    words = text.split()
    # Filter out pure numbers, single chars, etc.
    return len([w for w in words if len(w) > 1 or w.isalpha()])

def find_sections(tex_dir, main_tex):
    """Parse main.tex to find sections via \\input or inline."""
    sections = []
    try:
        with open(main_tex, 'r', errors='replace') as f:
            content = f.read()
    except:
        return sections

    # Find \input references
    inputs = re.findall(r'\\input\{([^}]+)\}', content)

    for inp in inputs:
        # Resolve path
        path = inp
        if not path.endswith('.tex'):
            path += '.tex'
        full = os.path.join(tex_dir, path)
        if not os.path.exists(full):
            full = os.path.join(os.path.dirname(main_tex), path)
        if os.path.exists(full):
            try:
                with open(full, 'r', errors='replace') as f:
                    sec_content = f.read()
                # Find section title
                m = re.search(r'\\section\{([^}]+)\}', sec_content)
                title = m.group(1) if m else os.path.basename(inp).replace('.tex', '').replace('_', ' ').title()
                wc = count_words(sec_content)
                sections.append({
                    'file': os.path.basename(inp),
                    'title': title[:30],
                    'words': wc
                })
            except:
                pass

    # Also count words in main.tex itself (inline content)
    main_wc = count_words(content)
    if main_wc > 50:  # Only if main.tex has substantial inline content
        sections.insert(0, {
            'file': 'main.tex',
            'title': '(main file)',
            'words': main_wc
        })

    return sections

# --- Main ---
tex_dir = sys.argv[1]
main_tex = sys.argv[2]
mode = sys.argv[3] if len(sys.argv) > 3 else 'sections'

sections = find_sections(tex_dir, main_tex)
total = sum(s['words'] for s in sections)

output = {'sections': sections, 'total': total}
print(json.dumps(output))
PYEOF
}

_wordcount_one() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  # Find main.tex
  local main_tex
  main_tex=$(find_main_tex "$repo_dir")
  if [[ -z "$main_tex" ]]; then
    printf "  %-18s  ❌ no main.tex\n" "$name"
    return
  fi

  local tex_dir
  tex_dir=$(dirname "$main_tex")

  local result
  result=$(_wordcount_py "$tex_dir" "$main_tex" 2>/dev/null) || true

  if [[ -z "$result" ]]; then
    printf "  %-18s  ❌ parse error\n" "$name"
    return
  fi

  local total
  total=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['total'])")

  if $SHOW_SECTIONS; then
    echo "  📄 $name ($total words total)"
    echo "$result" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for s in data['sections']:
    flag = '⚠️' if s['words'] < 100 else '  '
    print(f'     {flag} {s[\"title\"]:<30s}  {s[\"words\"]:>5d} words  ({s[\"file\"]})')
"
    echo ""
  else
    local status="✅"
    [[ $total -lt 2000 ]] && status="⚠️ "
    [[ $total -lt 500 ]] && status="❌"
    printf "  %-18s  %s %5d words\n" "$name" "$status" "$total"
  fi
}

echo ""
echo "📊 Word Count Analysis"
echo ""

if $SHOW_SECTIONS; then
  for_each_paper _wordcount_one
else
  printf "  %-18s  %s\n" "PAPER" "WORDS"
  printf "  %-18s  %s\n" "-----" "-----"
  for_each_paper _wordcount_one
fi

echo "Done."
