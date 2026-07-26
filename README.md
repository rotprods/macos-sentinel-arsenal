# 🛡️ macOS Sentinel Arsenal

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos)
[![launchd](https://img.shields.io/badge/powered%20by-launchd-black)](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
[![Shell](https://img.shields.io/badge/shell-bash%2Fzsh-green)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/python-3.11%2B-blue)](https://www.python.org/)
[![GitHub Pages](https://img.shields.io/badge/visual%20guide-GitHub%20Pages-222)](https://rotprods.github.io/macos-sentinel-arsenal/)

> **Open-source fleet of macOS LaunchAgents for personal endpoint hardening.**
>
> No EDR budget? No problem. Add file integrity monitoring, process hygiene, network posture checks, canary files, and local-only guards to any Mac — all running through `launchd`, the native macOS scheduler.

📖 **Visual install guide:** [rotprods.github.io/macos-sentinel-arsenal](https://rotprods.github.io/macos-sentinel-arsenal/)  
🤖 **For AI agents:** read [`AGENTS.md`](./AGENTS.md)  
⚡ **Quick install (clone first, then run):**

```bash
git clone https://github.com/rotprods/macos-sentinel-arsenal.git
cd macos-sentinel-arsenal
./install.sh --all --non-interactive
```

> **Security note:** this repo does not recommend `curl | bash`. Review `install.sh` before running it. For a preview, use `./install.sh --all --dry-run`.

---

## What’s included

| Agent | What it does | Frequency |
|---|---|---|
| **Filesystem Tripwire** | Detects unexpected changes in critical files using SHA-256 baselines | Every 15 min |
| **MCP Zombie Killer** | Kills orphaned `node`/`mcp` processes running >4h and consuming >5% CPU | Every 30 min |
| **BlockBlock Keepalive** | Ensures [Objective-See BlockBlock](https://objective-see.org/tools.html) Helper.app stays running | Every 30 min |
| **LuLu Posture Monitor** | Verifies [Objective-See LuLu](https://objective-see.org/tools.html) is active and warns on overly permissive defaults | 10:00 + at login |
| **Port Sweep Monitor** | Alerts when processes bind to wildcard interfaces (`0.0.0.0`/`::`) instead of localhost | Every 10 min |
| **Canary Watch** | Monitors decoy canary files for tampering or deletion | At login, continuously |
| **Localhost-Only Guard** | Detects dev servers (`node`/`vite`/`next`/…) exposed to the LAN; optional enforcement | Every 30 s |
| **macOS Audit** | Runs a posture audit of permissions, FileVault, firewall, users, and more | Daily at 03:00 + every 6h |
| **YARA Monthly** | Scans a configurable folder with YARA rules on the first of each month | Monthly at 03:00 |
| **Audit Log Rotate** | Rotates audit logs with SHA-256 manifests for tamper-evident evidence | Mondays at 09:00 |
| **Login Item Inspector** | Audits user LaunchAgents and login items for unexpected changes | Hourly |

---

## Recommended stack

This arsenal is designed to complement, not replace, these free/paid security tools:

- **[LuLu](https://objective-see.org/tools.html)** — outgoing firewall
- **[BlockBlock](https://objective-see.org/tools.html)** — persistence protection
- **[Malwarebytes](https://www.malwarebytes.com/)** — anti-malware / real-time protection
- **[OverSight](https://objective-see.org/tools.html)** — microphone & camera access monitor
- **Sentinel Arsenal** — automation, integrity, posture, and logging via `launchd`

Detailed install guides: [`install.md`](./install.md) · [`docs/install-lulu.md`](./docs/install-lulu.md) · [`docs/install-blockblock.md`](./docs/install-blockblock.md) · [`docs/install-malwarebytes.md`](./docs/install-malwarebytes.md) · [`docs/install-oversight.md`](./docs/install-oversight.md)

---

## Advanced toolkit

For optional, standalone hardening helpers see [`advanced/README.md`](./advanced/README.md):

- **Entropy scanner** + **YARA rules** for obfuscated payloads and macOS malware patterns.
- **SAST enforcer** write-time hook for secrets and Semgrep checks.
- **Tamper-evident audit chain** (`audit_chain.py`) with Merkle verification.
- **Drift detection** + baseline generator for LaunchAgents, ports, and binary hashes.
- **macOS audit, forensics, and threat-hunting playbooks**.

---

## Requirements

- macOS 13+ (Ventura/Sonoma/Sequoia/Tahoe)
- Terminal access
- `bash` or `zsh`
- Optional but recommended: `terminal-notifier` (notifications), `lsof` (port/localhost guards), `yara` (monthly scan)

---

## Quick start

```bash
# 1. Clone
git clone https://github.com/rotprods/macos-sentinel-arsenal.git
cd macos-sentinel-arsenal

# 2. Install interactively
./install.sh

# 3. Or install everything non-interactively
./install.sh --all --non-interactive
```

See [`install.md`](./install.md) for the manual, step-by-step version.

**New to Terminal?** Start with [`docs/primeros-pasos.md`](./docs/primeros-pasos.md) for a beginner-friendly walkthrough.

---

## For AI agents

If you are an AI assistant helping a human install or inspect this repo, read [`AGENTS.md`](./AGENTS.md) first. It contains the canonical commands, logs paths, rollback procedures, and safety rules.

---

## Disclaimer

This project is provided **as-is** for educational and personal hardening purposes. It does **not** replace a commercial endpoint detection and response (EDR) solution, nor does it guarantee security. Review every script before running it on your machine. The author is not responsible for data loss, downtime, or unintended system changes.

---

## Author

Maintained by **[@rotprods](https://github.com/rotprods)** · Infale Labs.

This repository is personal and owner-maintained. Pull requests and issues are disabled. Forks are welcome under the MIT license.
