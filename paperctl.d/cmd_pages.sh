#!/bin/bash
# paperctl.d/cmd_pages.sh -- Extract page counts from compiled PDFs and update conference.json

# Parse flags
UPDATE=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --update) UPDATE=true; shift ;;
    --paper) PAPERCTL_PAPER="$2"; export PAPERCTL_PAPER; shift 2 ;;
    --dir) PAPERCTL_DIR="$2"; export PAPERCTL_DIR; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

load_config

echo "📄 Page counts from compiled PDFs"
echo ""
printf "%-20s %6s  %s\n" "PAPER" "PAGES" "PDF"
printf "%-20s %6s  %s\n" "-----" "-----" "---"

_pages_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  # Find main.tex location (may be in subdirectory)
  local tex_dir="$repo_dir"
  if [[ -f "$repo_dir/main.tex" ]]; then
    tex_dir="$repo_dir"
  else
    # Search common subdirectories
    for _sub in ECCV_submission submission CVPR_submission; do
      if [[ -f "$repo_dir/$_sub/main.tex" ]]; then
        tex_dir="$repo_dir/$_sub"
        break
      fi
    done
    # Fallback: find first main.tex
    if [[ ! -f "$tex_dir/main.tex" ]]; then
      local _found_tex
      _found_tex=$(find "$repo_dir" -name "main.tex" -not -path "*/.git/*" -print -quit 2>/dev/null || true)
      [[ -n "$_found_tex" ]] && tex_dir=$(dirname "$_found_tex")
    fi
  fi

  # Find main.pdf — check tex_dir first, then repo root (some compile from root)
  local pdf=""
  [[ -f "$tex_dir/main.pdf" ]] && pdf="$tex_dir/main.pdf"
  [[ -z "$pdf" && -f "$repo_dir/main.pdf" ]] && pdf="$repo_dir/main.pdf"

  # If no PDF found, try to compile
  if [[ -z "$pdf" ]]; then
    local _pdflatex=""
    for _tbin in "/Library/TeX/texbin/pdflatex" \
                 "/usr/local/texlive/2025/bin/universal-darwin/pdflatex" \
                 "/usr/local/texlive/2024/bin/universal-darwin/pdflatex"; do
      [[ -x "$_tbin" ]] && { _pdflatex="$_tbin"; break; }
    done
    [[ -z "$_pdflatex" ]] && _pdflatex=$(command -v pdflatex 2>/dev/null || echo "")

    if [[ -n "$_pdflatex" && -f "$tex_dir/main.tex" ]]; then
      if [[ "$tex_dir" == "$repo_dir" ]]; then
        # main.tex in repo root — compile directly
        (cd "$repo_dir" && "$_pdflatex" -interaction=batchmode main.tex) &>/dev/null || true
      else
        # main.tex in subdirectory — compile from repo root with TEXINPUTS
        # This handles cross-directory references like \input{ECCV_submission/common_macros}
        local _rel_tex="${tex_dir#$repo_dir/}/main.tex"
        (cd "$repo_dir" && TEXINPUTS=".:${tex_dir#$repo_dir/}/:" "$_pdflatex" -interaction=batchmode "$_rel_tex") &>/dev/null || true
      fi
      # PDF may appear in repo root or tex_dir depending on compile location
      if [[ -f "$repo_dir/main.pdf" ]]; then
        pdf="$repo_dir/main.pdf"
      elif [[ -f "$tex_dir/main.pdf" ]]; then
        pdf="$tex_dir/main.pdf"
      fi
    fi
  fi

  if [[ -z "$pdf" || ! -f "$pdf" ]]; then
    printf "%-20s %6s  %s\n" "$name" "-" "(no main.tex or compile failed)"
    return
  fi
  
  # Get page count
  local pages=""
  if command -v mdls &>/dev/null; then
    pages=$(mdls -name kMDItemNumberOfPages "$pdf" 2>/dev/null | awk '{print $3}')
    [[ "$pages" == "(null)" ]] && pages=""
  fi
  if [[ -z "$pages" ]] && command -v pdfinfo &>/dev/null; then
    pages=$(pdfinfo "$pdf" 2>/dev/null | grep "^Pages:" | awk '{print $2}')
  fi
  if [[ -z "$pages" ]] && command -v python3 &>/dev/null; then
    # Fallback: count PDF page objects
    pages=$(python3 -c "
import subprocess, re
r = subprocess.run(['strings', '$pdf'], capture_output=True, text=True)
matches = re.findall(r'/Type\s*/Page[^s]', r.stdout)
print(len(matches))
" 2>/dev/null)
  fi
  
  [[ -z "$pages" || "$pages" == "0" ]] && pages="-"
  
  local pdf_name
  pdf_name=$(basename "$pdf")
  printf "%-20s %6s  %s\n" "$name" "$pages" "$pdf_name"
  
  # Update conference.json if --update
  if [[ "$UPDATE" == "true" && "$pages" != "-" ]]; then
    if command -v jq &>/dev/null; then
      local i=0
      while [[ $i -lt $CONF_PAPER_COUNT ]]; do
        if [[ "$(paper_field $i "name")" == "$name" ]]; then
          break
        fi
        i=$((i + 1))
      done
      local tmp
      tmp=$(mktemp)
      jq ".papers[$i].pages = $pages" "$CONF_FILE" > "$tmp" && mv "$tmp" "$CONF_FILE"
    else
      python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for p in data['papers']:
    if p['name'] == sys.argv[2]:
        p['pages'] = int(sys.argv[3])
        break
with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
" "$CONF_FILE" "$name" "$pages"
    fi
  fi
}

for_each_paper _pages_paper

echo ""
if [[ "$UPDATE" == "true" ]]; then
  echo "✅ conference.json updated with page counts"
else
  echo "💡 Use --update to write page counts to conference.json"
fi
