#!/usr/bin/env bash
set -euo pipefail

# YARA Monthly — scan a configurable folder with YARA rules on the first of each month.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.local/share/sentinel-arsenal}"
LOG_DIR="$SENTINEL_HOME/logs"
LOG_FILE="$LOG_DIR/yara.log"
RULES_DIR="$SENTINEL_HOME/yara-rules"
SCAN_TARGET="${YARA_SCAN_TARGET:-$HOME/Downloads}"

mkdir -p "$LOG_DIR" "$RULES_DIR"

log() {
  printf '%s [yara] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

alert() {
  log "MATCH: $*"
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Sentinel YARA" -message "$*" 2>/dev/null || true
  fi
}

if ! command -v yara >/dev/null 2>&1; then
  log "WARNING: yara binary not installed; skipping scan"
  exit 0
fi

# Only run on the first day of the month, or when forced.
day=$(date +%d)
if [[ "$day" != "01" && "${YARA_FORCE:-0}" != "1" ]]; then
  log "Not first of month; skipping"
  exit 0
fi

if [[ ! -d "$SCAN_TARGET" ]]; then
  log "Scan target missing: $SCAN_TARGET"
  exit 0
fi

rule_count=$(find "$RULES_DIR" -maxdepth 1 -name '*.yar*' | wc -l | tr -d ' ')
if [[ "$rule_count" -eq 0 ]]; then
  log "No YARA rules in $RULES_DIR"
  exit 0
fi

results=$(yara -r "$RULES_DIR" "$SCAN_TARGET" 2>/dev/null || true)
if [[ -z "$results" ]]; then
  log "No YARA matches in $SCAN_TARGET"
  exit 0
fi

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  alert "$line"
done <<< "$results"
