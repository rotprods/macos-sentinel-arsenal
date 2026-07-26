# Playbook — macOS Threat Hunting

A practical workflow for hunting persistence, suspicious egress, and anomalous behavior on a personal Mac.

## Severity Levels

| Level | Description | Example |
|-------|-------------|---------|
| P0 | Active breach / data exfiltration | Secrets compromised, unauthorized access |
| P1 | Critical vulnerability in active use | CVE CVSS ≥ 8.0 in production app |
| P2 | Suspicious anomaly | New `.env` in Downloads, unexpected connection |
| P3 | Monitoring alert | `/etc/hosts` modified, SSH permissions changed |

## Daily Hunt (5 minutes)

```bash
# Latest LaunchAgent changes
ls -lt ~/Library/LaunchAgents | head -10

# New listening ports since yesterday
lsof -nP -iTCP -sTCP:LISTEN | grep '\*:'

# High CPU processes
ps aux | awk '$3 > 30.0 {print $0}'

# Recent network connections outside localhost
lsof -i -P | grep ESTABLISHED | grep -v '127.0.0.1\|::1'
```

## Weekly Hunt (30 minutes)

1. **Persistence**
   - Review `~/Library/LaunchAgents`, `/Library/LaunchAgents`, `/Library/LaunchDaemons`.
   - Compare current plists with `~/.sentinel/baselines/baseline_*.json`.

2. **Integrity**
   - Run `./advanced/drift-detect.sh`.
   - Verify critical binaries with `./advanced/drift-baseline.sh`.
   - Check the audit chain: `python3 advanced/audit_chain.py`.

3. **Egress**
   - Enumerate established connections.
   - Identify new destinations or beacons to unknown IPs.

4. **Filesystem**
   - Scan recent downloads and documents for executables.
   - Run YARA rules: `yara advanced/yara-rules/macos_security.yar ~/Downloads`.
   - Run entropy scan on suspicious packages: `python3 advanced/entropy_scanner.py ~/Downloads/suspicious`.

## P0 — Active Breach

1. **Isolate** (1 min)
   ```bash
   # Turn off Wi-Fi / enable Airplane Mode
   # Quit all untrusted coding assistant / IDE windows
   # Stop exposed services
   ```

2. **Contain** (5 min)
   - Rotate every credential that may be exposed.
   - Revoke tokens in dashboards.
   - Change critical account passwords.

3. **Preserve** (10 min)
   ```bash
   mkdir -p /tmp/evidence-$(date +%s)
   cp -r ~/.sentinel/logs /tmp/evidence-$(date +%s)/
   netstat -an > /tmp/evidence-$(date +%s)/netstat.txt
   tar czf /tmp/quarantine-evidence.tar.gz ~/.sentinel/quarantine/
   ```

4. **Evaluate** (30 min)
   - Review `~/.sentinel/logs/*`.
   - Inspect network connections and recent file modifications.
   - Look for unknown processes.

5. **Recover** (1–4 h)
   - Restore from a clean, encrypted backup.
   - Reinstall from trusted sources.
   - Reconfigure with new credentials.

## P1 — Critical CVE

1. Confirm whether the CVE affects code in active use.
2. Document as "risk accepted" or apply the patch.
3. If patching:
   - Backup the lockfile.
   - Run the vendor-provided fix command.
   - Verify the build / behavior.
   - Commit with a clear message.

## P2 — Suspicious Anomaly

1. Verify the origin of the file or process.
2. If legitimate: document and add to the baseline.
3. If suspicious: quarantine or move to `~/.sentinel/quarantine/`.
4. If malicious: escalate to P0.

## P3 — Monitoring Alert

1. Read the relevant log.
2. Determine if it is a false positive.
3. If real: escalate to P2 or P1.

## Useful Commands

```bash
# Audit chain integrity
python3 advanced/audit_chain.py

# Drift vs baseline
./advanced/drift-detect.sh

# YARA scan
yara -r advanced/yara-rules/macos_security.yar ~/Downloads

# Entropy scan
python3 advanced/entropy_scanner.py ~/Downloads

# Binary signatures
codesign -dv --verbose=4 /Applications/Some.app
```

## Outputs & References

- Logs: `~/.sentinel/logs/`
- Alerts: `~/.sentinel/alerts/`
- Baselines: `~/.sentinel/baselines/`
- Audit chain: `~/.sentinel/audit/chain.jsonl`
