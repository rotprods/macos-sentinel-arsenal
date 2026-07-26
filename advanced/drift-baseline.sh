#!/bin/zsh
# macOS Sentinel Arsenal — Self-Integrity Baseline Generator
# Creates a snapshot of critical component hashes so drift-detect.sh can spot tampering.

SENTINEL_HOME="${SENTINEL_HOME:-$HOME/.sentinel}"
BASELINE_FILE="$SENTINEL_HOME/baselines/self-integrity-$(date +%Y%m%d_%H%M%S).json"
mkdir -p "$SENTINEL_HOME/baselines"

echo "🔐 Generating self-integrity baseline..."

python3 -c "
import json, os, subprocess, hashlib
from pathlib import Path
from datetime import datetime

sentinel = Path('$SENTINEL_HOME').expanduser()
baseline = {
    'timestamp': datetime.utcnow().isoformat() + 'Z',
    'type': 'self-integrity',
    'components': {}
}

# Hash core scripts in this directory
for script in ['harden.sh', 'drift-detect.sh', 'drift-baseline.sh']:
    path = sentinel / 'advanced' / script
    if path.exists():
        h = subprocess.getoutput(f'shasum -a 256 {path}').split()[0]
        baseline['components'][script] = {'sha256': h, 'size': path.stat().st_size}

# Hash YARA rules
yara_dir = sentinel / 'advanced' / 'yara-rules'
if yara_dir.exists():
    baseline['components']['yara'] = {}
    for f in sorted(yara_dir.glob('*.yar')):
        h = subprocess.getoutput(f'shasum -a 256 {f}').split()[0]
        size = f.stat().st_size
        baseline['components']['yara'][f.name] = {'sha256': h, 'size': size}

# Hash SAST/Python helpers
for helper in ['sast_enforcer.sh', 'entropy_scanner.py', 'audit_chain.py']:
    path = sentinel / 'advanced' / helper
    if path.exists():
        h = subprocess.getoutput(f'shasum -a 256 {path}').split()[0]
        baseline['components'][helper] = {'sha256': h, 'size': path.stat().st_size}

# Summary
total = sum(1 for v in baseline['components'].values() if isinstance(v, dict) and 'sha256' in v)
total += sum(len(v) for v in baseline['components'].values() if isinstance(v, dict) and 'sha256' not in v)
baseline['total_files_tracked'] = total

with open('$BASELINE_FILE', 'w') as f:
    json.dump(baseline, f, indent=2)

print(f'  ✅ Baseline saved: $BASELINE_FILE')
print(f'  📊 Files tracked: {total}')
" 2>/dev/null

echo "🔐 Done."
