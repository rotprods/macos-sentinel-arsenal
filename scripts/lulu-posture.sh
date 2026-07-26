#!/usr/bin/env bash
set -euo pipefail

# LuLu Posture Monitor — verify LuLu firewall is active and not too permissive.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.local/share/sentinel-arsenal}"
LOG_DIR="$SENTINEL_HOME/logs"
LOG_FILE="$LOG_DIR/lulu-posture.log"

mkdir -p "$LOG_DIR"

log() {
  printf '%s [lulu] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

alert() {
  log "$*"
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Sentinel LuLu" -message "$*" 2>/dev/null || true
  fi
}

# LuLu kernel extension / system extension presence.
LULU_KEXT="/Library/Extensions/LuLu.kext"
LULU_APP="/Applications/LuLu.app"

if [[ ! -d "$LULU_APP" ]]; then
  log "LuLu.app not installed"
  exit 0
fi

if [[ ! -d "$LULU_KEXT" ]]; then
  # Modern versions use a system extension; kext is legacy.
  log "LuLu kext not present; assuming system extension mode"
fi

# Check if LuLu process is alive.
if ! pgrep -f "LuLu" >/dev/null 2>&1; then
  alert "LuLu process not running"
  exit 0
fi

# Look for overly permissive rules: any rule matching *all* destinations.
LULU_RULES="$HOME/Library/Preferences/com.objective-see.lulu.plist"
if [[ -f "$LULU_RULES" ]]; then
  if plutil -p "$LULU_RULES" 2>/dev/null | grep -q "any"; then
    alert "LuLu has an 'any' rule — review firewall rules"
  fi
fi

log "LuLu posture OK"
