#!/usr/bin/env bash
set -euo pipefail

# Login Item Inspector — audit Login Items and LaunchAgents/LoginItems for unexpected entries.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.local/share/sentinel-arsenal}"
LOG_DIR="$SENTINEL_HOME/logs"
LOG_FILE="$LOG_DIR/login-item-inspector.log"
BASELINE="$SENTINEL_HOME/baselines/login-items.baseline"
ALLOWLIST="$SENTINEL_HOME/login-items-allowlist.txt"

mkdir -p "$LOG_DIR" "$SENTINEL_HOME/baselines"
touch "$ALLOWLIST"

log() {
  printf '%s [login] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

alert() {
  log "ALERT: $*"
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Sentinel Login Items" -message "$*" 2>/dev/null || true
  fi
}

current=$(mktemp)
trap 'rm -f "$current"' EXIT

# User LaunchAgents.
if [[ -d "$HOME/Library/LaunchAgents" ]]; then
  find "$HOME/Library/LaunchAgents" -maxdepth 1 -type f -name '*.plist' 2>/dev/null | sort >> "$current" || true
fi

# LoginItems via osascript (user-level, safe, no secrets).
if command -v osascript >/dev/null 2>&1; then
  osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | tr ',' '\n' | sed 's/^ *//' | while IFS= read -r item; do
    [[ -n "$item" ]] && printf 'loginitem:%s\n' "$item" >> "$current"
  done || true
fi

# First run: establish baseline.
if [[ ! -f "$BASELINE" ]]; then
  cp "$current" "$BASELINE"
  log "Baseline established"
  exit 0
fi

new_entries=$(comm -23 <(sort "$current") <(sort "$BASELINE"))
while IFS= read -r entry; do
  [[ -z "$entry" ]] && continue
  bn=$(basename "$entry")
  if grep -qx "$bn" "$ALLOWLIST" 2>/dev/null; then
    log "Allowlisted new entry: $bn"
    continue
  fi
  alert "New login item/LaunchAgent: $entry"
done <<< "$new_entries"

removed_entries=$(comm -13 <(sort "$current") <(sort "$BASELINE"))
while IFS= read -r entry; do
  [[ -z "$entry" ]] && continue
  alert "Removed login item/LaunchAgent: $entry"
done <<< "$removed_entries"

cp "$current" "$BASELINE"
log "Login item inspection completed"
