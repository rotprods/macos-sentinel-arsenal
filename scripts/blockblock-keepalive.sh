#!/usr/bin/env bash
set -euo pipefail

# BlockBlock Keepalive — make sure Objective-See BlockBlock Helper.app is running.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.local/share/sentinel-arsenal}"
LOG_DIR="$SENTINEL_HOME/logs"
LOG_FILE="$LOG_DIR/blockblock-keepalive.log"

mkdir -p "$LOG_DIR"

log() {
  printf '%s [blockblock] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

alert() {
  log "$*"
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Sentinel BlockBlock" -message "$*" 2>/dev/null || true
  fi
}

HELPER="/Applications/BlockBlock Helper.app"

if [[ ! -d "$HELPER" ]]; then
  log "BlockBlock Helper.app not found at $HELPER"
  exit 0
fi

if pgrep -f "BlockBlock Helper" >/dev/null 2>&1; then
  log "BlockBlock Helper is running"
  exit 0
fi

alert "BlockBlock Helper not running; attempting restart"
open "$HELPER" 2>/dev/null || true
sleep 2

if pgrep -f "BlockBlock Helper" >/dev/null 2>&1; then
  log "BlockBlock Helper restarted"
else
  alert "Failed to restart BlockBlock Helper"
fi
