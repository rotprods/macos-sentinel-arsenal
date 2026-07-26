# Changelog

All notable changes to `macos-sentinel-arsenal` are documented in this file.

## [1.0.0] - 2026-07-17

### Added

- 11 LaunchAgent templates under `launchagents/`:
  - `tripwire` — SHA-256 file integrity baseline monitor.
  - `mcp-zombie-killer` — kills orphaned `node`/`mcp` processes.
  - `blockblock-keepalive` — ensures BlockBlock Helper.app stays running.
  - `lulu-posture` — verifies LuLu firewall status.
  - `port-sweep` — detects wildcard-bound listening sockets.
  - `canary-watch` — monitors decoy canary files.
  - `localhost-only-guard` — detects dev servers exposed to LAN.
  - `macos-audit` — periodic macOS security posture report.
  - `yara-monthly` — scheduled YARA rule scan.
  - `auditlog-rotate` — rotates logs with SHA-256 manifests.
  - `login-item-inspector` — audits LaunchAgents and login items hourly.
- 11 matching shell scripts under `scripts/`.
- `install.sh` with `--all`, `--agents=`, `--non-interactive`, `--dry-run`, and `--uninstall` modes.
- `AGENTS.md` onboarding guide for AI assistants.
- `README.md` with shields, agent table, quickstart, and recommended stack.
- `index.html` visual guide using Tailwind CSS and Lucide icons.
- Per-agent documentation under `docs/` (00–10, 99-troubleshooting).
- Install guides for LuLu, BlockBlock, Malwarebytes, and OverSight.
- `docs/primeros-pasos.md` beginner Terminal guide.
- `SECURITY.md` vulnerability reporting policy.
- `CHANGELOG.md` (this file).
- `tools/verify.sh` local verification script.
- GitHub Pages deployment workflow.
- MIT `LICENSE`, `CODE_OF_CONDUCT.md`, and `CONTRIBUTING.md`.

### Security

- `gitleaks` pre-commit and pre-push hooks report zero leaks.
- No absolute user paths are committed; templates use `{{HOME}}` and `{{SCRIPT_DIR}}`.
- `.gitignore` excludes secrets, logs, backups, and rendered plists.

## [0.0.0] - 2026-07-17

- Initial repository scaffold.
