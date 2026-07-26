#!/usr/bin/env bash
set -euo pipefail

# Audit Log Rotate — rotate logs with SHA-256 manifests for tamper-evident evidence.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.local/share/sentinel-arsenal}"
LOG_DIR="$SENTINEL_HOME/logs"
ARCHIVE_DIR="$SENTINEL_HOME/archive"
MANIFEST="$ARCHIVE_DIR/manifest.txt"
MAX_DAYS="${LOG_RETAIN_DAYS:-90}"

mkdir -p "$LOG_DIR" "$ARCHIVE_DIR"
touch "$MANIFEST"

log() {
  printf '%s [rotate] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_DIR/rotate.log"
}

stamp=$(date +%Y%m%d-%H%M%S)

for f in "$LOG_DIR"/*.log; do
  [[ -e "$f" ]] || continue
  size=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null || echo 0)
  if [[ "$size" -lt 1024 ]]; then
    continue
  fi
  bn=$(basename "$f")
  archive="$ARCHIVE_DIR/${bn%.log}-$stamp.log"
  cp "$f" "$archive"
  gzip "$archive"
  hash=$(shasum -a 256 "${archive}.gz" | awk '{print $1}')
  printf '%s %s %s\n' "$stamp" "$bn" "$hash" >> "$MANIFEST"
  : > "$f"
  log "Archived $bn -> ${archive}.gz ($hash)"
done

# Clean old archives.
find "$ARCHIVE_DIR" -name '*.log.gz' -mtime +"$MAX_DAYS" -delete || true

log "Rotation completed"
