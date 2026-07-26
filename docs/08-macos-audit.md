# macOS Audit

Runs a posture audit of macOS security settings.

## What it does

- Checks FileVault, firewall, Gatekeeper, SIP, SSH remote login, and admin group membership.
- Writes a timestamped report to `~/.local/share/sentinel-arsenal/reports/`.
- Alerts on findings that reduce security posture.

## Schedule

Runs daily at 03:00 and every 6 hours.

## Logs and reports

```bash
ls ~/.local/share/sentinel-arsenal/reports/
tail -f ~/.local/share/sentinel-arsenal/logs/macos-audit.log
```
