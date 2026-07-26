#!/usr/bin/env bash
set -euo pipefail

# Canary Watch — monitor decoy files for tampering or deletion.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.local/share/sentinel-arsenal}"
LOG_DIR="$SENTINEL_HOME/logs"
LOG_FILE="$LOG_DIR/canary.log"
CANARY_DIR="$SENTINEL_HOME/canaries"
CANARY_LIST="$SENTINEL_HOME/canary-list.txt"

mkdir -p "$LOG_DIR" "$CANARY_DIR"
touch "$CANARY_LIST"

log() {
  printf '%s [canary] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

alert() {
  log "ALERT: $*"
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Sentinel Canary" -message "$*" -sound default 2>/dev/null || true
  fi
}

# Ensure every configured canary exists with expected content.
while IFS='|' read -r name content || [[ -n "$name" ]]; do
  [[ -z "$name" || "$name" =~ ^# ]] && continue
  path="$CANARY_DIR/$name"
  if [[ ! -f "$path" ]]; then
    printf '%s' "$content" > "$path"
    log "Created canary $name"
    continue
  fi
  expected_hash=$(printf '%s' "$content" | shasum -a 256 | awk '{print $1}')
  actual_hash=$(shasum -a 256 "$path" 2>/dev/null | awk '{print $1}')
  if [[ "$expected_hash" != "$actual_hash" ]]; then
    alert "Canary tampered: $name"
  fi
done < "$CANARY_LIST"

# Detect unknown files inside the canary directory (optional strict mode).
if [[ "${CANARY_STRICT:-0}" == "1" ]]; then
  for f in "$CANARY_DIR"/*; do
    [[ -f "$f" ]] || continue
    bn=$(basename "$f")
    if ! grep -qF "${bn}|" "$CANARY_LIST" 2>/dev/null; then
      alert "Unknown file in canary dir: $bn"
    fi
  done
fi

log "Canary check completed"
