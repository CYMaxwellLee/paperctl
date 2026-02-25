#!/bin/bash
# paperctl.d/cmd_status.sh -- Show conference & paper status

load_config

# Deadline info
DEADLINE=$(_jq "$CONF_FILE" '.conference.deadline')

echo "╔══════════════════════════════════════════════════════╗"
printf "║  %-52s║\n" "$CONF_NAME $CONF_YEAR — Paper Status"
echo "╠══════════════════════════════════════════════════════╣"
printf "║  Slug:     %-41s║\n" "$CONF_SLUG"
printf "║  Org:      %-41s║\n" "$CONF_ORG"
printf "║  Template: %-41s║\n" "$CONF_TEMPLATE"
printf "║  Papers:   %-41s║\n" "$CONF_PAPER_COUNT"
if [[ -n "$DEADLINE" && "$DEADLINE" != "null" ]]; then
  printf "║  Deadline: %-41s║\n" "$DEADLINE"
fi
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Table header
printf "%-20s %-8s %-30s %-15s %-6s\n" "NAME" "STATUS" "REPO" "DOMAIN" "DIRTY"
printf "%-20s %-8s %-30s %-15s %-6s\n" "----" "------" "----" "------" "-----"

_status_paper() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"

  # Read extra fields
  local i=0
  while [[ $i -lt $CONF_PAPER_COUNT ]]; do
    if [[ "$(paper_field $i "name")" == "$name" ]]; then
      break
    fi
    i=$((i + 1))
  done

  local status domain paper_id title dirty fork_marker
  status=$(paper_field $i "status")
  domain=$(paper_field $i "domain")
  paper_id=$(paper_field $i "paper_id")
  title=$(paper_field $i "title")

  # Check git dirty status
  if [[ -d "$repo_dir" ]]; then
    if [[ -n "$(git -C "$repo_dir" status --porcelain 2>/dev/null)" ]]; then
      dirty="*"
    else
      dirty=""
    fi
  else
    dirty="N/A"
  fi

  # Fork indicator
  if is_fork "$upstream"; then
    fork_marker="🔱"
  else
    fork_marker="  "
  fi

  [[ "$status" == "null" ]] && status="-"
  [[ "$domain" == "null" ]] && domain="-"

  printf "%-20s %-8s %-30s %-15s %-6s\n" \
    "$fork_marker$name" "$status" "$repo" "$domain" "$dirty"
}

for_each_paper _status_paper

echo ""

# Paper ID summary
echo "📋 Paper IDs:"
_i=0
while [[ $_i -lt $CONF_PAPER_COUNT ]]; do
  _name=$(paper_field $_i "name")
  _pid=$(paper_field $_i "paper_id")
  _title=$(paper_field $_i "title")
  [[ "$_pid" == "null" ]] && _pid="-"
  [[ "$_title" == "null" ]] && _title="-"
  printf "   %-15s #%-6s %s\n" "$_name" "$_pid" "$_title"
  _i=$((_i + 1))
done
echo ""
