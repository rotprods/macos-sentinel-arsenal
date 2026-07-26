# Playbook — macOS Audit

A lightweight, repeatable posture audit for macOS endpoints.

## What it checks

- FileVault full-disk encryption
- Application firewall state
- Gatekeeper / SIP status
- SSH remote login setting
- Local admin group membership
- Open ports bound to all interfaces
- `.env` file permissions
- Critical binary hashes (baseline drift)

## Quick run

```bash
./advanced/harden.sh
./advanced/drift-detect.sh
```

## Manual checks

```bash
# FileVault
fdesetup status

# Firewall
defaults read /Library/Preferences/com.apple.alf globalstate

# Gatekeeper
spctl --status

# SIP
csrutil status

# SSH remote login
systemsetup -getremotelogin

# Admin users
dscl . read /Groups/admin GroupMembership

# Open wildcard ports
lsof -nP -iTCP -sTCP:LISTEN | grep '\*:'

# .env permissions
find ~/Documents -name ".env*" -not -path "*/node_modules/*" -exec ls -l {} \;
```

## Frequency

| Check | Suggested frequency |
|-------|---------------------|
| Full `harden.sh` | Weekly |
| `drift-detect.sh` | Daily |
| Manual spot checks | After major installs / updates |

## Findings matrix

| Severity | Example | Action |
|----------|---------|--------|
| Critical | SIP disabled, unknown admin account | Investigate immediately |
| High | New wildcard listener, `.env` world-readable | Remediate same day |
| Medium | FileVault off on portable Mac | Schedule enable |
| Low | Firewall logging off | Track in baseline |

## Outputs

- `~/.sentinel/evidence/hardening_YYYYMMDD_HHMMSS.log`
- `~/.sentinel/baselines/baseline_YYYYMMDD.json`
- `~/.sentinel/baselines/self-integrity-YYYYMMDD_HHMMSS.json`
