# Playbook — macOS Digital Forensics

## Principles

1. Preserve evidence before acting.
2. Document every step with a timestamp.
3. Do not modify the suspected system.
4. Separate real evidence from operational paranoia.

## Required Tools

| Tool | Purpose | Availability |
|------|---------|--------------|
| `log` / `log show` | System logs | Native |
| `netstat` / `lsof` | Network connections | Native |
| `ps aux` | Processes | Native |
| `codesign -dv` | Binary signature verification | Native |
| `mdfind` / Spotlight | File search | Native |
| `file` / `strings` | Binary analysis | Native |
| Malwarebytes | Anti-malware | Optional |
| OverSight | Microphone/camera monitor | Optional |
| LuLu | Outgoing firewall | Optional |

## Phase 1: Evidence Collection

### 1.1 System Snapshot
```bash
SNAP="$HOME/.sentinel/forensics/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$SNAP"

# Processes
ps aux > "$SNAP/ps-aux.txt"
ps -eo pid,ppid,comm,user,etime,args > "$SNAP/ps-tree.txt"

# Network
netstat -anv > "$SNAP/netstat.txt"
lsof -i -P > "$SNAP/lsof-network.txt"
ifconfig > "$SNAP/ifconfig.txt"
lsof -i -P | grep LISTEN > "$SNAP/ports-listen.txt"

# Recent logs (last hour)
log show --last 1h > "$SNAP/logs-1h.txt" 2>/dev/null
log show --predicate 'subsystem == "com.apple.security"' --last 1h > "$SNAP/logs-security.txt" 2>/dev/null

# Recent files
find ~/Documents -mtime -1 -type f > "$SNAP/recent-files.txt"
find ~/Downloads -mtime -1 -type f > "$SNAP/recent-downloads.txt"

# Launch agents / daemons
launchctl list > "$SNAP/launchctl.txt"
find ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons -type f > "$SNAP/launch-plists.txt"

# Sensitive permissions
ls -la ~/.ssh/ ~/.gnupg/ ~/.age/ > "$SNAP/sensitive-perms.txt"

# Firewall
system_profiler SPFirewallDataType > "$SNAP/firewall.txt" 2>/dev/null

# TCC database
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db ".dump" > "$SNAP/tcc-db.txt" 2>/dev/null

echo "[OK] Snapshot saved to $SNAP"
```

## Phase 2: Analysis

### 2.1 Suspicious Processes
```bash
# Unsigned binaries under /Applications and /usr/local/bin
find /Applications /usr/local/bin -type f -perm +111 | while read f; do
  codesign -v "$f" 2>/dev/null || echo "UNSIGNED: $f"
done

# External connections
lsof -i -P | grep -v 'localhost\|127.0.0.1' | grep ESTABLISHED

# High CPU / memory consumers
ps aux | awk '$3 > 50.0 || $4 > 50.0 {print}'
```

### 2.2 Suspicious Files
```bash
# Executables in user directories
find ~/Documents ~/Downloads -type f -perm +111

# Extended attributes of interest
find ~/Documents -type f -exec xattr -l {} \; 2>/dev/null | grep -i 'quarantine\|com.apple.provenance'

# Recent /tmp files
ls -lt /tmp /var/tmp | head -20
```

### 2.3 Suspicious Network Connections
```bash
# Established connections outside local ranges
netstat -anv | grep ESTABLISHED | grep -v '127.0.0.1\|::1\|192.168\|10\.\|172\.1[6-9]\|172\.2[0-9]\|172\.3[01]'

# Reverse DNS of active peers
lsof -i -P | grep ESTABLISHED | awk '{print $9}' | cut -d: -f1 | sort | uniq | while read ip; do
  host "$ip" 2>/dev/null || true
done
```

### 2.4 Security Logs
```bash
# Gatekeeper / quarantine
log show --predicate 'eventMessage CONTAINS "quarantine" OR eventMessage CONTAINS "gatekeeper"' --last 24h

# Installations
log show --predicate 'subsystem == "com.apple.install"' --last 24h

# Authentication
log show --predicate 'subsystem == "com.apple.auth"' --last 24h
```

## Phase 3: Timeline

```bash
# Files modified in the last 7 days
find ~/Documents ~/Downloads -type f -mtime -7 -exec ls -lt {} + | head -50

# Recent shell history
history | tail -100

# Recently launched applications
log show --predicate 'subsystem == "com.apple.LaunchServices"' --last 24h | grep -i 'open\|exec'
```

## Phase 4: Report Template

```markdown
# Forensic Report — [ID]
## Date: YYYY-MM-DD HH:MM

### Executive Summary
[What happened, when, impact]

### Evidence Collected
- Snapshot: [path]
- Suspicious processes: [list]
- Connections: [list]
- Files: [list]

### Analysis
[Technical findings]

### Conclusions
[Confirmed compromise / Not compromised / Undetermined]

### Recommendations
[Actions to take]

### Annexes
[Hashes, logs, screenshots]
```

## Phase 5: Preservation

```bash
cd "$SNAP/.."
tar czf "forensics-$(date +%Y%m%d-%H%M%S).tar.gz" "$(basename $SNAP)"
shasum -a 256 forensics-*.tar.gz > "forensics-$(date +%Y%m%d-%H%M%S).sha256"
# Move to cold storage, e.g. an encrypted external drive.
```
