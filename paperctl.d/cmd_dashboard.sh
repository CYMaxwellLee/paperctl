#!/bin/bash
# paperctl.d/cmd_dashboard.sh -- Auto-generate README dashboard from conference.json
#
# Usage:
#   paperctl dashboard [--output <file>] [--format table|json]
#
# Flags:
#   --output <file>    Write dashboard to file instead of stdout
#   --format <fmt>     Output format: table (default) or json

# --- Parse flags (including global flags forwarded from CLI) ---
DASH_OUTPUT=""
DASH_FORMAT="table"

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --output) DASH_OUTPUT="$2"; shift 2 ;;
    --format) DASH_FORMAT="$2"; shift 2 ;;
    --paper)  PAPERCTL_PAPER="$2"; export PAPERCTL_PAPER; shift 2 ;;
    --dir)    PAPERCTL_DIR="$2"; export PAPERCTL_DIR; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

load_config

# --- Status emoji mapping ---
_status_emoji() {
  case "$1" in
    complete)       echo "🟢" ;;
    near-complete)  echo "🟡" ;;
    outline)        echo "🔴" ;;
    early)          echo "🔴" ;;
    cvpr-reject)    echo "🟡" ;;
    *)              echo "⚪" ;;
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
_dp "| # | Paper | OR ID | Domain | Status | Dirty | Overleaf |"
_dp "|:-:|-------|:-----:|--------|:------:|:-----:|:--------:|"

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

  local domain paper_id status
  domain=$(paper_field $i "domain")
  paper_id=$(paper_field $i "paper_id")
  status=$(paper_field $i "status")
  [[ "$domain" == "null" ]] && domain="-"
  [[ "$paper_id" == "null" ]] && paper_id="-"
  [[ "$status" == "null" ]] && status="-"

  local emoji
  emoji=$(_status_emoji "$status")

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

  _dp "| $_dash_row | $fork_icon$gh_link | $paper_id | $domain | $emoji | $dirty | $ol_link |"
}

_dash_row=0
for_each_paper _dashboard_paper

_dp ""
_dp "> 🟢 Complete / Review　🟡 In Progress / Near-Complete　🔴 Early / Outline　🔱 Fork"
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
