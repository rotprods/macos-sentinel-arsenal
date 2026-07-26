#!/usr/bin/env bash
set -euo pipefail

# macOS Audit — posture audit of permissions, FileVault, firewall, users, etc.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.local/share/sentinel-arsenal}"
LOG_DIR="$SENTINEL_HOME/logs"
LOG_FILE="$LOG_DIR/macos-audit.log"
REPORT_DIR="$SENTINEL_HOME/reports"

mkdir -p "$LOG_DIR" "$REPORT_DIR"

log() {
  printf '%s [audit] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

alert() {
  log "WARN: $*"
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "Sentinel macOS Audit" -message "$*" 2>/dev/null || true
  fi
}

report_file="$REPORT_DIR/macos-audit-$(date +%Y%m%d-%H%M%S).txt"
{
  echo "# macOS Posture Audit — $(date)"
  echo

  echo "## FileVault"
  fde_status=$(fdesetup status 2>/dev/null | head -1 || true)
  echo "FileVault: $fde_status"
  if [[ "$fde_status" != *"On"* ]]; then
    alert "FileVault is not enabled"
  fi

  echo "## Firewall"
  fw_status=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo "unknown")
  echo "Firewall state: $fw_status"
  if [[ "$fw_status" != "1" && "$fw_status" != "2" ]]; then
    alert "Firewall is not enabled"
  fi

  echo "## Gatekeeper"
  gk_status=$(spctl --status 2>&1 || true)
  echo "Gatekeeper: $gk_status"

  echo "## SIP"
  sip_status=$(csrutil status 2>&1 || true)
  echo "SIP: $sip_status"

  echo "## Users with UID >= 500"
  dscl . list /Users UniqueID 2>/dev/null | awk '$2 >= 500 {print $1, $2}' || true

  echo "## Admin users"
  dscl . read /Groups/admin GroupMembership 2>/dev/null || true

  echo "## SSH remote login"
  ssh_status=$(systemsetup -getremotelogin 2>/dev/null || true)
  echo "Remote login: $ssh_status"
  if [[ "$ssh_status" == *"On"* ]]; then
    alert "Remote login (SSH) is enabled"
  fi

  echo "## Current user admin"
  if groups "$USER" 2>/dev/null | grep -q admin; then
    echo "Current user is in admin group"
  else
    echo "Current user is NOT in admin group"
  fi
} > "$report_file"

log "Audit report written to $report_file"
