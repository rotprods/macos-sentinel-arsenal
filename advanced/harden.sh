#!/bin/zsh
# macOS Sentinel Arsenal — Hardening Script
# One-shot posture hardening + baseline generator.
# Review before running; adjust SENTINEL_HOME if you store data elsewhere.
set -e

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.sentinel}"
EVIDENCE_DIR="$SENTINEL_HOME/evidence"
LOG_FILE="$EVIDENCE_DIR/hardening_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$EVIDENCE_DIR"

log() { echo "[$(date -u +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }

log "🛡️ Starting security hardening..."

# ── 1. FIX .ENV PERMISSIONS ──────────────────────────────────
log "=== 1. Fixing .env permissions ==="
find ~/Documents -name ".env*" -not -path "*/node_modules/*" 2>/dev/null | while read f; do
    CURRENT=$(stat -f "%Sp" "$f")
    if [ "$CURRENT" != "-rw-------" ]; then
        chmod 600 "$f"
        log "  FIXED: $f ($CURRENT → -rw-------)"
    else
        log "  OK: $f"
    fi
done

# ── 2. CHECK SYSTEM INTEGRITY ───────────────────────────────
log "=== 2. System integrity ==="
SIP=$(csrutil status 2>/dev/null || true)
log "  SIP: $SIP"
GK=$(spctl --status 2>/dev/null || true)
log "  Gatekeeper: $GK"

# ── 3. CHECK FILEVAULT ──────────────────────────────────────
log "=== 3. FileVault ==="
FV=$(fdesetup status 2>/dev/null | head -1 || true)
log "  FileVault: $FV"
if [[ "$FV" != *"On"* ]]; then
    log "  🟠 WARNING: FileVault is not enabled"
fi

# ── 4. CHECK LISTENING PORTS ───────────────────────────────
log "=== 4. Open ports ==="
WILDCARD_PORTS=$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep "\*:" | awk '{print $1, $9}' | sort -u)
if [ -n "$WILDCARD_PORTS" ]; then
    log "  🟠 Ports open to ALL interfaces:"
    echo "$WILDCARD_PORTS" | while read line; do
        log "    $line"
    done
else
    log "  ✅ No ports open to all interfaces"
fi

# ── 5. EVIDENCE VAULT INTEGRITY ─────────────────────────────
log "=== 5. Evidence vault ==="
log "  Directory: $EVIDENCE_DIR"
log "  Files: $(ls $EVIDENCE_DIR 2>/dev/null | wc -l | tr -d ' ')"
chmod 700 "$EVIDENCE_DIR"
log "  Permissions set to 700 (owner only)"

# ── 6. GENERATE BASELINE ───────────────────────────────────
log "=== 6. Generating baseline ==="
BASELINE="$SENTINEL_HOME/baselines/baseline_$(date +%Y%m%d).json"
mkdir -p "$SENTINEL_HOME/baselines"
python3 -c "
import json, subprocess, os, datetime

baseline = {
    'timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
    'hostname': os.uname().nodename,
    'sip_enabled': 'enabled' in subprocess.getoutput('csrutil status'),
    'launch_agents': os.listdir(os.path.expanduser('~/Library/LaunchAgents')),
    'listening_ports': subprocess.getoutput('lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep \"*:\" | awk \"{print \\\\$1, \\\\$9}\"').strip().split('\\n'),
    'env_files': subprocess.getoutput('find ~/Documents -name \".env*\" -not -path \"*/node_modules/*\" 2>/dev/null').strip().split('\\n'),
    'critical_binary_hashes': {},
}

for b in ['/usr/bin/ssh', '/usr/bin/curl', '/bin/zsh', '/bin/bash']:
    if os.path.exists(b):
        h = subprocess.getoutput(f'shasum -a 256 {b} 2>/dev/null').split()[0]
        baseline['critical_binary_hashes'][b] = h

with open('$BASELINE', 'w') as f:
    json.dump(baseline, f, indent=2)
print(f'  Baseline saved: $BASELINE')
" 2>/dev/null

log ""
log "══════════════════════════════════════"
log "🛡️ HARDENING COMPLETE"
log "  Log: $LOG_FILE"
log "══════════════════════════════════════"
