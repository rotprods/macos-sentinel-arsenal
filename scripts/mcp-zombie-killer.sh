#!/usr/bin/env bash
set -euo pipefail

# MCP Zombie Killer — kill orphaned node/mcp processes running too long and hot.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.local/share/sentinel-arsenal}"
LOG_DIR="$SENTINEL_HOME/logs"
LOG_FILE="$LOG_DIR/mcp-zombie-killer.log"
MAX_CPU="${MAX_CPU:-5.0}"
MAX_AGE_MIN="${MAX_AGE_MIN:-240}"

mkdir -p "$LOG_DIR"

log() {
  printf '%s [mcp-zombie] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

alert() {
  log "$*"
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Sentinel MCP Zombie" -message "$*" 2>/dev/null || true
  fi
}

if ! command -v ps >/dev/null 2>&1; then
  log "ERROR: ps not available"
  exit 1
fi

# List candidate processes: node, mcp, mcp-server, or similar.
candidates=$(ps -eo pid,etime,pcpu,comm,args | awk -v max_age="$MAX_AGE_MIN" '
  $4 ~ /^(node|mcp|mcp-server|mcp-|npm|npx)$/ {
    # Parse etime [DD-]HH:MM:SS
    t = $2
    days = 0; hours = 0; mins = 0; secs = 0
    if (match(t, /-/)) { days = substr(t, 1, RSTART-1); t = substr(t, RSTART+1) }
    n = split(t, parts, /:/)
    if (n == 3) { hours = parts[1]; mins = parts[2]; secs = parts[3] }
    else if (n == 2) { mins = parts[1]; secs = parts[2] }
    else if (n == 1) { secs = parts[1] }
    total_min = days*1440 + hours*60 + mins + secs/60
    if (total_min >= max_age) print $0
  }
')

killed=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  pid=$(printf '%s' "$line" | awk '{print $1}')
  cpu=$(printf '%s' "$line" | awk '{print $3}')
  if awk "BEGIN {exit !($cpu >= $MAX_CPU)}"; then
    if kill -TERM "$pid" 2>/dev/null; then
      log "Sent TERM to PID $pid (cpu $cpu%)"
      sleep 2
      if kill -0 "$pid" 2>/dev/null; then
        kill -KILL "$pid" 2>/dev/null || true
        log "Sent KILL to PID $pid"
      fi
      killed=$((killed + 1))
    else
      log "Could not signal PID $pid"
    fi
  fi
done <<< "$candidates"

if (( killed > 0 )); then
  alert "Terminated $killed long-running MCP/node processes"
else
  log "No zombies found"
fi
