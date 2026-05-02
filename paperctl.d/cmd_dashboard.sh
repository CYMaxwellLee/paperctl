#!/bin/bash
# paperctl.d/cmd_dashboard.sh -- Auto-generate README dashboard from conference.json
#
# Usage:
#   paperctl dashboard [--output <file>] [--format table|json] [--status <file>]
#
# Flags:
#   --output <file>    Write README dashboard to file instead of stdout
#   --status <file>    Also generate STATUS.md progress table (auto from conference.json)
#   --format <fmt>     Output format: table (default) or json

# --- Parse flags (including global flags forwarded from CLI) ---
DASH_OUTPUT=""
DASH_STATUS=""
DASH_FORMAT="table"

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --output) DASH_OUTPUT="$2"; shift 2 ;;
    --status) DASH_STATUS="$2"; shift 2 ;;
    --format) DASH_FORMAT="$2"; shift 2 ;;
    --paper)  PAPERCTL_PAPER="$2"; export PAPERCTL_PAPER; shift 2 ;;
    --dir)    PAPERCTL_DIR="$2"; export PAPERCTL_DIR; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

load_config

# --- Status emoji mapping ---
_status_emoji() {
  # 5 distinct levels for clarity (was 3)
  case "$1" in
    complete)       echo "✅" ;;
    near-complete)  echo "🟢" ;;
    draft)          echo "🟡" ;;
    outline)        echo "🟠" ;;
    early)          echo "🔴" ;;
    cvpr-reject)    echo "♻️ " ;;
    *)              echo "⚪" ;;
  esac
}

_status_label() {
  case "$1" in
    complete)       echo "Complete" ;;
    near-complete)  echo "Near-Complete" ;;
    draft)          echo "Draft" ;;
    outline)        echo "Outline" ;;
    early)          echo "Early" ;;
    cvpr-reject)    echo "CVPR-Reject" ;;
    *)              echo "Unknown" ;;
  esac
}

# --- Deadline info ---
DEADLINE=$(_jq "$CONF_FILE" '.conference.deadline')
_deadline_display="N/A"
_days_left=""
if [[ -n "$DEADLINE" && "$DEADLINE" != "null" ]]; then
  # Parse deadline date portion
  _dl_date="${DEADLINE%%T*}"

  if TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$DEADLINE" "+%s" &>/dev/null 2>&1; then
    # macOS — parse in UTC to get correct epoch
    _dl_epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$DEADLINE" "+%s" 2>/dev/null)
    _dl_human=$(TZ=UTC date -r "$_dl_epoch" "+%Y-%m-%d %H:%M UTC" 2>/dev/null)
  else
    # Linux
    _dl_epoch=$(date -d "$DEADLINE" "+%s" 2>/dev/null || echo "")
    _dl_human=$(date -d "$DEADLINE" "+%Y-%m-%d %H:%M UTC" 2>/dev/null || echo "$DEADLINE")
  fi

  # Taiwan time (UTC+8)
  _dl_tw=""
  if [[ -n "${_dl_epoch:-}" ]]; then
    if date -r "$_dl_epoch" "+%s" &>/dev/null 2>&1; then
      _dl_tw=$(TZ=Asia/Taipei date -r "$_dl_epoch" "+%-m/%-d %H:%M" 2>/dev/null || echo "")
    else
      _dl_tw=$(TZ=Asia/Taipei date -d "@$_dl_epoch" "+%-m/%-d %H:%M" 2>/dev/null || echo "")
    fi
  fi

  if [[ -n "${_dl_epoch:-}" ]]; then
    _now_epoch=$(date "+%s")
    _days_left=$(( (_dl_epoch - _now_epoch) / 86400 ))
    if [[ -n "${_dl_tw:-}" ]]; then
      _deadline_display="$_dl_human（台灣 $_dl_tw）(**$_days_left days remaining**)"
    else
      _deadline_display="$_dl_human (**$_days_left days remaining**)"
    fi
  else
    _deadline_display="$DEADLINE"
  fi
fi

# --- Overleaf project URL from git URL ---
_overleaf_url() {
  local git_url="$1"
  # https://git.overleaf.com/699d59207af0587a27747469 → https://www.overleaf.com/project/699d59207af0587a27747469
  if [[ "$git_url" == https://git.overleaf.com/* ]]; then
    local id="${git_url##*/}"
    echo "https://www.overleaf.com/project/$id"
  else
    echo "$git_url"
  fi
}

# --- Output buffer ---
_dash_buf=""
_dp() {
  _dash_buf+="$*"$'\n'
}

if [[ "$DASH_FORMAT" == "json" ]]; then
  # JSON output: dump conference.json papers with live dirty status
  echo "["
  _ji=0
  while [[ $_ji -lt $CONF_PAPER_COUNT ]]; do
    _jname=$(paper_field $_ji "name")
    _jrepo=$(paper_field $_ji "repo")
    _jrepo_dir="$CONF_DIR/$_jrepo"
    if [[ -d "$_jrepo_dir" && -n "$(git -C "$_jrepo_dir" status --porcelain 2>/dev/null)" ]]; then
      _jdirty="true"
    else
      _jdirty="false"
    fi
    if command -v jq &>/dev/null; then
      jq ".papers[$_ji] + {dirty: $_jdirty}" "$CONF_FILE"
    else
      python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
p = data['papers'][$_ji]
p['dirty'] = $_jdirty
print(json.dumps(p, indent=2))
" "$CONF_FILE"
    fi
    _ji=$((_ji + 1))
    [[ $_ji -lt $CONF_PAPER_COUNT ]] && echo ","
  done
  echo "]"
  exit 0
fi

# --- Markdown table output ---
_dp "# $CONF_NAME $CONF_YEAR — Dashboard"
_dp ""
_dp "> **Org:** [\`$CONF_ORG\`](https://github.com/$CONF_ORG) | **Deadline:** $_deadline_display | **Papers:** $CONF_PAPER_COUNT"
_dp ""
_dp "---"
_dp ""
_dp "## 📊 進度總覽"
_dp ""
_dp "| # | Paper | OR ID | Pages | Domain | Status | Dirty | Overleaf |"
_dp "|:-:|-------|:-----:|:-----:|--------|:------:|:-----:|:--------:|"

_dashboard_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  # Read extra fields via index lookup
  local i=0
  while [[ $i -lt $CONF_PAPER_COUNT ]]; do
    if [[ "$(paper_field $i "name")" == "$name" ]]; then
      break
    fi
    i=$((i + 1))
  done

  local domain paper_id status pages
  domain=$(paper_field $i "domain")
  paper_id=$(paper_field $i "paper_id")
  status=$(paper_field $i "status")
  pages=$(paper_field $i "pages")
  [[ "$domain" == "null" ]] && domain="-"
  [[ "$paper_id" == "null" ]] && paper_id="-"
  [[ "$status" == "null" ]] && status="-"
  [[ "$pages" == "null" || "$pages" == "0" ]] && pages="-"

  local emoji label
  emoji=$(_status_emoji "$status")
  label=$(_status_label "$status")

  # Dirty check
  local dirty=""
  if [[ -d "$repo_dir" ]]; then
    if [[ -n "$(git -C "$repo_dir" status --porcelain 2>/dev/null)" ]]; then
      dirty="\\*"
    fi
  else
    dirty="N/A"
  fi

  # Fork indicator
  local fork_icon=""
  is_fork "$upstream" && fork_icon="🔱"

  # Overleaf link
  local ol_link=""
  if [[ -n "$overleaf" && "$overleaf" != "null" ]]; then
    local ol_url
    ol_url=$(_overleaf_url "$overleaf")
    ol_link="[✏️]($ol_url)"
  fi

  # GitHub link
  local gh_link="[**$name**](https://github.com/$CONF_ORG/$repo)"

  # Row number (using global counter)
  _dash_row=$((_dash_row + 1))

  _dp "| $_dash_row | $fork_icon$gh_link | $paper_id | $pages | $domain | $emoji $label | $dirty | $ol_link |"
}

_dash_row=0
for_each_paper _dashboard_paper

_dp ""
_dp "> ✅ Complete　🟢 Near-Complete　🟡 Draft　🟠 Outline　🔴 Early　♻️ CVPR-Reject　🔱 Fork"
_dp ""
_dp "---"
_dp ""

# --- Heatmap summary (embedded) ---
_HEAT_SINCE="3 days ago"

_dashboard_heatmap() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  local since_sha
  since_sha=$(git -C "$repo_dir" log --until="$_HEAT_SINCE" --format="%H" -1 2>/dev/null || echo "")
  [[ -z "$since_sha" ]] && since_sha=$(git -C "$repo_dir" rev-list --max-parents=0 HEAD 2>/dev/null | head -1)

  local total_add=0 total_del=0
  if [[ -n "$since_sha" ]]; then
    while IFS= read -r _hl; do
      [[ -z "$_hl" ]] && continue
      local _hi _hd _hf
      _hi=$(echo "$_hl" | awk '{print $1}')
      _hd=$(echo "$_hl" | awk '{print $2}')
      _hf=$(echo "$_hl" | awk '{print $3}')
      [[ "$_hi" == "-" ]] && continue
      [[ "$_hf" != *.tex && "$_hf" != *.bib ]] && continue
      total_add=$(( total_add + _hi ))
      total_del=$(( total_del + _hd ))
    done < <(git -C "$repo_dir" diff --numstat "$since_sha"..HEAD 2>/dev/null)
  fi

  local total=$(( total_add + total_del ))

  # Bar: 15 chars, scale 1500
  local bar_len=0
  if [[ "$total" -gt 0 ]]; then
    bar_len=$(( (total * 15) / 1500 ))
    [[ "$bar_len" -lt 1 ]] && bar_len=1
    [[ "$bar_len" -gt 15 ]] && bar_len=15
  fi
  local bar="" i=0
  while [[ $i -lt $bar_len ]]; do bar+="█"; i=$((i+1)); done
  while [[ $i -lt 15 ]]; do bar+="░"; i=$((i+1)); done

  # Figures
  local figs=0
  if [[ -n "$since_sha" ]]; then
    figs=$(git -C "$repo_dir" diff --name-only "$since_sha"..HEAD 2>/dev/null \
      | grep -cE '\.(pdf|png|jpg|jpeg|eps|svg)$' || true)
    [[ -z "$figs" ]] && figs=0
  fi
  local fig_col="-"
  [[ "$figs" -gt 0 ]] && fig_col="$figs"

  _dp "| $name | \`$bar\` | +$total_add | -$total_del | **$total** | $fig_col |"
}

_dp "## 🔥 近期活動 (since: $_HEAT_SINCE)"
_dp ""
_dp "| Paper | Heatmap | +Add | -Del | Total | 📊 Fig |"
_dp "|-------|:-------:|-----:|-----:|------:|:------:|"
for_each_paper _dashboard_heatmap
_dp ""
_dp "---"
_dp ""

# --- Per-paper notes (student activity narrative from conference.json) ---
# Notes field accumulates entries separated by " | " — each entry usually starts
# with a [MM/DD] timestamp. We split on " | " and render as a bullet list with
# the date highlighted, so it scans top-to-bottom instead of as a wall of text.
_dashboard_notes() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
  local notes student_lead authors paper_id status pages
  notes=$(paper_field $i "notes")
  student_lead=$(paper_field $i "student_lead")
  authors=$(paper_field $i "authors")
  paper_id=$(paper_field $i "paper_id")
  status=$(paper_field $i "status")
  pages=$(paper_field $i "pages")
  [[ "$notes" == "null" || -z "$notes" ]] && return

  local emoji label
  emoji=$(_status_emoji "$status")
  label=$(_status_label "$status")

  # Pick GitHub alert-block color by status (renders as colored vertical bar)
  local alert_kind
  case "$status" in
    complete)       alert_kind="TIP" ;;        # green
    near-complete)  alert_kind="IMPORTANT" ;;  # purple
    draft)          alert_kind="IMPORTANT" ;;  # purple
    outline)        alert_kind="WARNING" ;;    # yellow
    early)          alert_kind="CAUTION" ;;    # red
    cvpr-reject)    alert_kind="NOTE" ;;       # blue
    *)              alert_kind="NOTE" ;;
  esac

  _dp ""
  _dp "### $emoji $name &nbsp;·&nbsp; \`#${paper_id:--}\` &nbsp;·&nbsp; ${pages:-?}p &nbsp;·&nbsp; *$label*"
  _dp ""
  _dp "> [!${alert_kind}]"
  if [[ -n "$student_lead" && "$student_lead" != "null" ]]; then
    _dp "> **Student lead:** $student_lead"
  fi
  if [[ -n "$authors" && "$authors" != "null" ]]; then
    _dp "> **Authors:** $authors"
  fi
  _dp ""
  # Render activity log as a 2-column table: Date | Activity.
  # Split notes on " | ", parse [MM/DD] prefix as Date column, rest as Activity.
  # Long file lists (>6 commas) get truncated to first 5 files + "…(N more)".
  _dp "| Date | Activity |"
  _dp "|:----:|----------|"
  local rows
  rows=$(python3 -c "
import sys, re
notes = sys.argv[1]
for entry in notes.split(' | '):
    entry = entry.strip()
    if not entry:
        continue
    m = re.match(r'^\[(\d{1,2}/\d{1,2})\]\s*(.*)', entry)
    if m:
        date, body = m.group(1), m.group(2)
    else:
        date, body = '—', entry
    # Truncate huge file lists for readability
    fl = re.search(r'更新了 ([\w_\-,]+)', body)
    if fl and fl.group(1).count(',') > 6:
        files = fl.group(1).split(',')
        truncated = ', '.join(files[:5]) + f' ...(+{len(files)-5} more)'
        body = body.replace(fl.group(1), truncated)
    fl = re.search(r'Sections: \`([^\`]+)\`', body)
    if fl and fl.group(1).count(',') > 6:
        files = fl.group(1).split(',')
        body = body.replace(fl.group(1), f'{len(files)} files')
    # Escape pipe chars so they don't break the markdown table
    body = body.replace('|', '\\\\|')
    print(f'| \`{date}\` | {body} |')
" "$notes")
  while IFS= read -r line; do
    [[ -n "$line" ]] && _dp "$line"
  done <<< "$rows"
}

_dp "## 📝 Per-Paper Notes (Student Activity)"
_dp ""
for_each_paper _dashboard_notes
_dp ""
_dp "---"
_dp ""

# --- Key dates ---
if [[ -n "$DEADLINE" && "$DEADLINE" != "null" ]]; then
  _dp "## 🔥 Key Dates"
  _dp ""
  _dp "| Date | Event |"
  _dp "|------|-------|"
  if [[ -n "${_dl_date:-}" ]]; then
    _dl_time_str="⏰ **Deadline**"
    [[ -n "${_dl_tw:-}" ]] && _dl_time_str+=" (台灣 $_dl_tw)"
    _dp "| **${_dl_date}** | $_dl_time_str |"
  fi
  _dp ""
  _dp "---"
  _dp ""
fi

_dp "_Auto-generated by \`paperctl dashboard\` · $(date '+%Y-%m-%d %H:%M')_"

# --- Output ---
if [[ -n "$DASH_OUTPUT" ]]; then
  echo "$_dash_buf" > "$DASH_OUTPUT"
  echo "✅ Dashboard written to $DASH_OUTPUT"
else
  echo "$_dash_buf"
fi

# --- STATUS.md generation (optional) ---
if [[ -n "$DASH_STATUS" ]]; then
  _st=""
  _stp() { _st+="$*"$'\n'; }

  _stp "# $CONF_NAME $CONF_YEAR — 戰況儀表板"
  _stp "> 🕐 Last updated: $(date '+%Y-%m-%d %H:%M') (auto-generated)"
  _stp "> ⏰ Deadline: $_deadline_display"
  _stp ""
  _stp "---"
  _stp ""
  _stp "## 進度總覽"
  _stp ""
  _stp "| # | Batch | Paper | OR ID | 頁數 | 進度 | 編譯 | Claude | 下一步 |"
  _stp "|---|-------|-------|-------|:----:|:----:|:----:|:-:|--------|"

  _st_row=0
  _status_row() {
    local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
    local i=0
    while [[ $i -lt $CONF_PAPER_COUNT ]]; do
      [[ "$(paper_field $i "name")" == "$name" ]] && break
      i=$((i + 1))
    done

    local status domain paper_id batch pages notes claude_proj know_up
    status=$(paper_field $i "status")
    domain=$(paper_field $i "domain")
    paper_id=$(paper_field $i "paper_id")
    batch=$(paper_field $i "batch")
    pages=$(paper_field $i "pages")
    notes=$(paper_field $i "notes")
    claude_proj=$(paper_field $i "claude_project")
    know_up=$(paper_field $i "knowledge_uploaded")

    [[ "$status" == "null" ]] && status="-"
    [[ "$domain" == "null" ]] && domain="-"
    [[ "$paper_id" == "null" ]] && paper_id="-"
    [[ "$batch" == "null" ]] && batch="-"
    [[ "$pages" == "null" || "$pages" == "0" ]] && pages="-"
    [[ "$notes" == "null" ]] && notes=""

    # Status emoji + label
    local emoji label
    case "$status" in
      complete)       emoji="🟢"; label="完稿" ;;
      near-complete)  emoji="🟡"; label="近完稿" ;;
      draft)          emoji="🟡"; label="Draft" ;;
      outline)        emoji="🟡"; label="Outline" ;;
      early)          emoji="🔴"; label="Early" ;;
      *)              emoji="⚪"; label="$status" ;;
    esac

    # Compile check (look for main.pdf in repo root or subdirectories)
    local compile="-"
    if [[ -f "$repo_dir/main.pdf" ]]; then
      compile="✅"
    else
      # Check common subdirectories
      for _csub in ECCV_submission submission CVPR_submission; do
        [[ -f "$repo_dir/$_csub/main.pdf" ]] && { compile="✅"; break; }
      done
    fi

    # Claude status
    local claude="⬜"
    [[ "$claude_proj" == "true" ]] && claude="✅"

    # Fork
    local fork_icon=""
    is_fork "$upstream" && fork_icon="🔱"

    # Batch circle
    local batch_icon="$batch"
    case "$batch" in
      1) batch_icon="①" ;; 2) batch_icon="②" ;; 3) batch_icon="③" ;;
      4) batch_icon="④" ;; 5) batch_icon="⑤" ;; 6) batch_icon="⑥" ;;
      7) batch_icon="⑦" ;; 8) batch_icon="⑧" ;; 9) batch_icon="⑨" ;;
    esac

    # Next step (from notes, take after → if present)
    local next_step="$notes"
    if [[ "$notes" == *"→"* ]]; then
      next_step="${notes##*→ }"
    fi
    # Truncate to 40 chars
    [[ ${#next_step} -gt 40 ]] && next_step="${next_step:0:37}..."

    _st_row=$((_st_row + 1))
    _stp "| $_st_row | $batch_icon | $fork_icon**$name** | $paper_id | $pages | $emoji $label | $compile | $claude | $next_step |"
  }

  for_each_paper _status_row

  _stp ""
  _stp "> ✅ Complete　🟢 Near-Complete　🟡 Draft　🟠 Outline　🔴 Early　♻️ CVPR-Reject　🔱 Fork"

  # Checklist: Claude project count
  _cp_count=0; _kn_count=0
  _ci=0
  while [[ $_ci -lt $CONF_PAPER_COUNT ]]; do
    [[ "$(paper_field $_ci "claude_project")" == "true" ]] && _cp_count=$((_cp_count + 1))
    [[ "$(paper_field $_ci "knowledge_uploaded")" == "true" ]] && _kn_count=$((_kn_count + 1))
    _ci=$((_ci + 1))
  done

  _stp ""
  _stp "---"
  _stp ""
  _stp "## Quick Stats"
  _stp ""
  _stp "- Claude Projects: **$_cp_count/$CONF_PAPER_COUNT**"
  _stp "- Knowledge uploaded: **$_kn_count/$CONF_PAPER_COUNT**"
  _stp ""
  _stp "---"
  _stp ""
  _stp "_Auto-generated by \`paperctl dashboard --status\` · $(date '+%Y-%m-%d %H:%M')_"

  echo "$_st" > "$DASH_STATUS"
  echo "✅ STATUS.md written to $DASH_STATUS"
fi
