#!/usr/bin/env bash
set -euo pipefail

# Localhost-Only Guard — detect dev servers exposed to the LAN.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.local/share/sentinel-arsenal}"
LOG_DIR="$SENTINEL_HOME/logs"
LOG_FILE="$LOG_DIR/localhost-only.log"
ALLOWLIST_FILE="$SENTINEL_HOME/localhost-allowlist.txt"
ENFORCE="${LOCALHOST_ENFORCE:-0}"

mkdir -p "$LOG_DIR"
touch "$ALLOWLIST_FILE"

log() {
  printf '%s [localhost] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

alert() {
  log "ALERT: $*"
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Sentinel Localhost Guard" -message "$*" -sound default 2>/dev/null || true
  fi
}

if ! command -v lsof >/dev/null 2>&1; then
  log "WARNING: lsof not installed; cannot scan"
  exit 0
fi

# Common dev server binaries.
listeners=$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk '
  $1 ~ /^(node|python|python3|vite|next|nuxt|remix|astro|php|ruby|bundle|cargo|go)$/ {
    print $1 " " $2 " " $9
  }
')

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  addr=$(printf '%s' "$line" | awk '{print $3}')
  # Wildcard or LAN addresses (exclude 127.0.0.1 and ::1).
  if [[ "$addr" == *"127.0.0.1"* ]] || [[ "$addr" == *"[::1]"* ]]; then
    continue
  fi
  port=$(printf '%s' "$addr" | grep -oE ':[0-9]+$' | tr -d ':')
  if grep -qx "$port" "$ALLOWLIST_FILE" 2>/dev/null; then
    log "Allowlisted LAN port $port"
    continue
  fi
  pid=$(printf '%s' "$line" | awk '{print $2}')
  alert "LAN-exposed dev server: $line"
  if [[ "$ENFORCE" == "1" ]]; then
    if kill -TERM "$pid" 2>/dev/null; then
      log "Enforced: terminated PID $pid"
    fi
  fi
done <<< "$listeners"

log "Localhost-only check completed"
