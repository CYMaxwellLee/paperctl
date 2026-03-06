#!/bin/bash
# auto-sync.sh -- Automated periodic sync for paperctl
#
# Runs paperctl sync at regular intervals, logging results.
# Designed to be run via cron or launchd.
#
# Usage:
#   # One-shot sync with logging
#   bash auto-sync.sh /path/to/conference/dir
#
#   # Install as cron job (every 30 minutes)
#   bash auto-sync.sh --install /path/to/conference/dir
#
#   # Install as macOS launchd agent (every 30 minutes)
#   bash auto-sync.sh --install-launchd /path/to/conference/dir
#
#   # Uninstall
#   bash auto-sync.sh --uninstall
#
#   # Show sync log
#   bash auto-sync.sh --log

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PAPERCTL="$SCRIPT_DIR/paperctl"
LOG_DIR="$HOME/.paperctl/logs"
LOG_FILE="$LOG_DIR/auto-sync.log"
LAUNCHD_LABEL="com.paperctl.auto-sync"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/${LAUNCHD_LABEL}.plist"
SYNC_INTERVAL=1800  # 30 minutes

mkdir -p "$LOG_DIR"

_log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

_install_cron() {
  local conf_dir="$1"
  local script_path
  script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

  # Remove existing paperctl cron entries
  crontab -l 2>/dev/null | grep -v "auto-sync.sh" | crontab -

  # Add new entry (every 30 minutes)
  (crontab -l 2>/dev/null; echo "*/30 * * * * bash \"$script_path\" \"$conf_dir\" >> \"$LOG_FILE\" 2>&1") | crontab -

  echo "✅ Cron job installed (every 30 minutes)"
  echo "   Logs: $LOG_FILE"
  echo "   Edit: crontab -e"
  echo "   Remove: bash $0 --uninstall"
}

_install_launchd() {
  local conf_dir="$1"
  local script_path
  script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

  mkdir -p "$(dirname "$LAUNCHD_PLIST")"

  cat > "$LAUNCHD_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LAUNCHD_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${script_path}</string>
        <string>${conf_dir}</string>
    </array>
    <key>StartInterval</key>
    <integer>${SYNC_INTERVAL}</integer>
    <key>StandardOutPath</key>
    <string>${LOG_FILE}</string>
    <key>StandardErrorPath</key>
    <string>${LOG_FILE}</string>
    <key>RunAtLoad</key>
    <false/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/Library/TeX/texbin</string>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>
</dict>
</plist>
EOF

  launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
  launchctl load "$LAUNCHD_PLIST"

  echo "✅ launchd agent installed (every 30 minutes)"
  echo "   Plist: $LAUNCHD_PLIST"
  echo "   Logs: $LOG_FILE"
  echo "   Stop: launchctl unload $LAUNCHD_PLIST"
  echo "   Remove: bash $0 --uninstall"
}

_uninstall() {
  # Remove cron
  if crontab -l 2>/dev/null | grep -q "auto-sync.sh"; then
    crontab -l 2>/dev/null | grep -v "auto-sync.sh" | crontab -
    echo "✅ Cron job removed"
  fi

  # Remove launchd
  if [[ -f "$LAUNCHD_PLIST" ]]; then
    launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
    rm -f "$LAUNCHD_PLIST"
    echo "✅ launchd agent removed"
  fi

  echo "Done."
}

_show_log() {
  if [[ -f "$LOG_FILE" ]]; then
    echo "=== Last 50 lines of auto-sync log ==="
    tail -50 "$LOG_FILE"
  else
    echo "No log file found at $LOG_FILE"
  fi
}

_run_sync() {
  local conf_dir="$1"

  if [[ ! -d "$conf_dir" ]]; then
    _log "ERROR: Directory not found: $conf_dir"
    exit 1
  fi

  if [[ ! -f "$conf_dir/conference.json" ]]; then
    _log "ERROR: conference.json not found in $conf_dir"
    exit 1
  fi

  _log "Starting auto-sync for $conf_dir"

  # Check if git credentials are available
  if ! git -C "$conf_dir" remote -v &>/dev/null; then
    _log "ERROR: Git not configured or not a git-managed directory"
    exit 1
  fi

  # Run sync
  local start_time
  start_time=$(date +%s)

  "$PAPERCTL" sync --parallel --auto-resolve --dir "$conf_dir" 2>&1 | while IFS= read -r line; do
    _log "  $line"
  done

  local end_time elapsed
  end_time=$(date +%s)
  elapsed=$((end_time - start_time))

  _log "Auto-sync completed in ${elapsed}s"

  # Generate dashboard if template exists
  local meta_dir="$conf_dir/$(_get_slug "$conf_dir")-meta"
  if [[ -d "$meta_dir" ]]; then
    "$PAPERCTL" dashboard --output "$meta_dir/README.md" --dir "$conf_dir" 2>&1 | while IFS= read -r line; do
      _log "  $line"
    done
    _log "Dashboard updated"
  fi
}

_get_slug() {
  local conf_dir="$1"
  if command -v jq &>/dev/null; then
    jq -r '.conference.slug' "$conf_dir/conference.json"
  else
    python3 -c "import json; print(json.load(open('$conf_dir/conference.json'))['conference']['slug'])"
  fi
}

# --- Main ---
case "${1:-}" in
  --install)
    [[ -z "${2:-}" ]] && { echo "Usage: $0 --install <conference-dir>"; exit 1; }
    _install_cron "$2"
    ;;
  --install-launchd)
    [[ -z "${2:-}" ]] && { echo "Usage: $0 --install-launchd <conference-dir>"; exit 1; }
    _install_launchd "$2"
    ;;
  --uninstall)
    _uninstall
    ;;
  --log)
    _show_log
    ;;
  *)
    if [[ -z "${1:-}" ]]; then
      echo "Usage:"
      echo "  $0 <conference-dir>                 # one-shot sync"
      echo "  $0 --install <conference-dir>        # install cron (30min)"
      echo "  $0 --install-launchd <conference-dir> # install launchd (30min)"
      echo "  $0 --uninstall                       # remove cron/launchd"
      echo "  $0 --log                             # show sync log"
      exit 1
    fi
    _run_sync "$1"
    ;;
esac
