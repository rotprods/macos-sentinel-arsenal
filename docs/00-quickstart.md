# Quickstart

Get the macOS Sentinel Arsenal running in under 5 minutes.

## Prerequisites

- macOS 13+
- Terminal access
- (Recommended) LuLu, BlockBlock, and Malwarebytes installed

## One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/rotprods/macos-sentinel-arsenal/main/install.sh | bash
```

## Step-by-step

```bash
# Clone
git clone https://github.com/rotprods/macos-sentinel-arsenal.git
cd macos-sentinel-arsenal

# See options
./install.sh --help

# Install everything
./install.sh --all --non-interactive

# Verify
launchctl list | grep com.sentinel
```

## What to expect

After install:

| Agent | What it does | Frequency |
|---|---|---|
| **Filesystem Tripwire** | Detects unexpected changes in critical files using SHA-256 baselines | Every 15 min |
| **MCP Zombie Killer** | Kills orphaned `node`/`mcp` processes running >4h and >5% CPU | Every 30 min |
| **BlockBlock Keepalive** | Ensures BlockBlock Helper.app stays running | Every 30 min |
| **LuLu Posture Monitor** | Verifies LuLu is active and warns on permissive rules | 10:00 + at login |
| **Port Sweep Monitor** | Alerts on wildcard-bound listeners | Every 10 min |
| **Canary Watch** | Monitors decoy canary files for tampering or deletion | At login, continuously |
| **Localhost-Only Guard** | Detects dev servers exposed to the LAN; optional enforcement | Every 30 s |
| **macOS Audit** | Posture audit of FileVault, firewall, users, SSH, etc. | Daily at 03:00 + every 6h |
| **YARA Monthly** | Scans a folder with YARA rules on the 1st of each month | Monthly at 03:00 |
| **Audit Log Rotate** | Rotates logs with SHA-256 manifests | Mondays at 09:00 |
| **Login Item Inspector** | Audits user LaunchAgents and login items for unexpected changes | Hourly |

All logs go to `~/.local/share/sentinel-arsenal/logs/`.

## Next steps

- Read the per-agent docs in `docs/`.
- Open the [visual guide](https://rotprods.github.io/macos-sentinel-arsenal/) in a browser.
- If you are using an AI assistant, point it to [`AGENTS.md`](../AGENTS.md).
