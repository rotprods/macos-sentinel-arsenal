#!/bin/zsh
# macOS Sentinel Arsenal — Drift Detector
# Compares the current macOS state against a previously generated baseline.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.sentinel}"
BASELINE_DIR="$SENTINEL_HOME/baselines"

LATEST=$(ls -t "$BASELINE_DIR"/baseline_*.json 2>/dev/null | head -1)
if [ -z "$LATEST" ]; then
    echo "❌ No baseline found. Run harden.sh first."
    exit 1
fi

echo "🔍 Comparing against baseline: $(basename $LATEST)"
echo ""

python3 -c "
import json, subprocess, os

with open('$LATEST') as f:
    baseline = json.load(f)

drifts = []

# 1. Check SIP
sip_now = 'enabled' in subprocess.getoutput('csrutil status')
if sip_now != baseline.get('sip_enabled', True):
    drifts.append(('CRITICAL', 'SIP status changed!'))

# 2. Check LaunchAgents
agents_now = set(os.listdir(os.path.expanduser('~/Library/LaunchAgents')))
agents_before = set(baseline.get('launch_agents', []))
new_agents = agents_now - agents_before
removed_agents = agents_before - agents_now
for a in new_agents:
    drifts.append(('HIGH', f'NEW LaunchAgent: {a}'))
for a in removed_agents:
    drifts.append(('INFO', f'Removed LaunchAgent: {a}'))

# 3. Check binary hashes
for binary, old_hash in baseline.get('critical_binary_hashes', {}).items():
    if os.path.exists(binary):
        new_hash = subprocess.getoutput(f'shasum -a 256 {binary} 2>/dev/null').split()[0]
        if new_hash != old_hash:
            drifts.append(('CRITICAL', f'Binary hash changed: {binary}'))

# 4. Check listening ports
ports_now = subprocess.getoutput('lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep \"*:\" | awk \"{print \\\$1, \\\$9}\"').strip().split('\\n')
ports_before = baseline.get('listening_ports', [])
new_ports = set(ports_now) - set(ports_before)
for p in new_ports:
    if p.strip():
        drifts.append(('HIGH', f'NEW open port: {p}'))

# 5. Check .env permissions
env_files = subprocess.getoutput('find ~/Documents -name \".env*\" -not -path \"*/node_modules/*\" 2>/dev/null').strip().split('\\n')
for f in env_files:
    if f and os.path.exists(f):
        perms = oct(os.stat(f).st_mode)[-3:]
        if perms != '600':
            drifts.append(('HIGH', f'.env permissions changed: {f} ({perms})'))

# Report
if not drifts:
    print('✅ No drift detected. System matches baseline.')
else:
    print(f'⚠️  {len(drifts)} drift(s) detected:')
    print()
    for severity, msg in sorted(drifts, key=lambda x: {'CRITICAL':0,'HIGH':1,'MEDIUM':2,'LOW':3,'INFO':4}.get(x[0],5)):
        icon = {'CRITICAL':'🔴','HIGH':'🟠','MEDIUM':'🟡','LOW':'🔵','INFO':'ℹ️'}.get(severity,'❓')
        print(f'  {icon} [{severity}] {msg}')
" 2>/dev/null
