#!/usr/bin/env bash
set -euo pipefail

# Filesystem Tripwire — detect unexpected changes in critical files.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.local/share/sentinel-arsenal}"
BASELINE_DIR="$SENTINEL_HOME/baselines"
LOG_DIR="$SENTINEL_HOME/logs"
WATCH_FILE="${SENTINEL_HOME}/watchlist.txt"
LOG_FILE="$LOG_DIR/tripwire.log"

mkdir -p "$BASELINE_DIR" "$LOG_DIR"
touch "$WATCH_FILE"

log() {
  printf '%s [tripwire] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

alert() {
  log "ALERT: $*"
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Sentinel Tripwire" -message "$*" -sound default 2>/dev/null || true
  fi
}

# Build or refresh baseline for a watched path.
refresh_baseline() {
  local path="$1"
  local base
  base=$(printf '%s' "$path" | shasum -a 256 | awk '{print $1}')
  if [[ ! -e "$path" ]]; then
    rm -f "$BASELINE_DIR/$base.baseline"
    return
  fi
  if [[ -f "$path" ]]; then
    shasum -a 256 "$path" > "$BASELINE_DIR/$base.baseline"
  elif [[ -d "$path" ]]; then
    find "$path" -type f -print0 2>/dev/null | xargs -0 shasum -a 256 2>/dev/null > "$BASELINE_DIR/$base.baseline" || true
  fi
}

# First run: create baselines for every watched path.
if [[ ! -f "$BASELINE_DIR/.initialized" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    refresh_baseline "$line"
  done < "$WATCH_FILE"
  touch "$BASELINE_DIR/.initialized"
  log "Baseline initialized"
  exit 0
fi

# Compare current state against baseline.
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  base=$(printf '%s' "$line" | shasum -a 256 | awk '{print $1}')
  baseline="$BASELINE_DIR/$base.baseline"
  if [[ ! -e "$line" ]]; then
    if [[ -f "$baseline" ]]; then
      alert "Missing: $line"
      rm -f "$baseline"
    fi
    continue
  fi
  if [[ ! -f "$baseline" ]]; then
    alert "New watched path: $line (baseline created)"
    refresh_baseline "$line"
    continue
  fi
  tmp_current="$BASELINE_DIR/$base.current"
  if [[ -f "$line" ]]; then
    shasum -a 256 "$line" > "$tmp_current"
  elif [[ -d "$line" ]]; then
    find "$line" -type f -print0 2>/dev/null | xargs -0 shasum -a 256 2>/dev/null > "$tmp_current" || true
  fi
  if ! diff -q "$baseline" "$tmp_current" >/dev/null 2>&1; then
    alert "Changed: $line"
  fi
  mv "$tmp_current" "$baseline"
done < "$WATCH_FILE"

log "Tripwire check completed"
