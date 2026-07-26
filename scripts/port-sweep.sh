#!/usr/bin/env bash
set -euo pipefail

# Port Sweep Monitor — alert when processes bind to wildcard interfaces.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.local/share/sentinel-arsenal}"
LOG_DIR="$SENTINEL_HOME/logs"
LOG_FILE="$LOG_DIR/port-sweep.log"
ALLOWLIST_FILE="$SENTINEL_HOME/port-allowlist.txt"

mkdir -p "$LOG_DIR"
touch "$ALLOWLIST_FILE"

log() {
  printf '%s [portsweep] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

alert() {
  log "ALERT: $*"
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Sentinel Port Sweep" -message "$*" -sound default 2>/dev/null || true
  fi
}

if ! command -v lsof >/dev/null 2>&1; then
  log "WARNING: lsof not installed; cannot scan ports"
  exit 0
fi

# Find listeners on 0.0.0.0 or :: (IPv4/IPv6 wildcards).
listeners=$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk '
  $9 ~ /\*:([0-9]+)$/ || $9 ~ /\[::\]:([0-9]+)$/ {
    print $1 " " $2 " " $9
  }
')

if [[ -z "$listeners" ]]; then
  log "No wildcard listeners found"
  exit 0
fi

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  port=$(printf '%s' "$line" | grep -oE ':[0-9]+$' | tr -d ':')
  if grep -qx "$port" "$ALLOWLIST_FILE" 2>/dev/null; then
    log "Allowlisted wildcard port $port"
    continue
  fi
  alert "Wildcard listener: $line"
done <<< "$listeners"
