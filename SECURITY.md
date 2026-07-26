# Security Policy

## Supported versions

Only the latest release of `macos-sentinel-arsenal` receives security updates. This is a personal, owner-maintained project; there are no LTS branches.

| Version | Supported |
|---------|-----------|
| `main` (latest) | ✅ |
| older commits | ❌ |

## Reporting a vulnerability

If you find a security problem in this repo — for example, a script that exposes secrets, bypasses macOS sandboxing, or introduces privilege escalation — please report it privately.

**Do not open a public issue or pull request.** PRs and issues are disabled by design.

Contact the maintainer directly:

- GitHub: [@rotprods](https://github.com/rotprods)

Include:

1. Affected file and line number.
2. Steps to reproduce.
3. Impact (what could go wrong).
4. Suggested fix, if you have one.

## Scope

In scope:

- Any script under `scripts/`.
- Any template under `launchagents/`.
- `install.sh`.
- `index.html` and documentation that could lead users to unsafe behavior.

Out of scope:

- Third-party tools (LuLu, BlockBlock, Malwarebytes, OverSight). Report those to their vendors.
- macOS itself. Report to Apple.
- User misconfiguration after install.

## Security design principles

1. **No secrets in the repo.** Every commit is scanned with `gitleaks` in a pre-commit and pre-push hook.
2. **No absolute user paths.** Templates use `{{HOME}}` and `{{SCRIPT_DIR}}` placeholders rendered at install time.
3. **No root by default.** Agents run as the logged-in user.
4. **Audit log integrity.** Rotated logs keep a SHA-256 manifest in `~/.local/share/sentinel-arsenal/archive/`.
5. **Transparency.** Every agent has its own documentation under `docs/` explaining exactly what it does.

## Hardening recommendations

- Review `install.sh` before running it.
- Run `./install.sh --all --dry-run` first to see exactly what will change.
- Keep LuLu, BlockBlock, Malwarebytes, and OverSight enabled.
- Back up your existing `~/Library/LaunchAgents/` before installing (the installer also backs them up automatically).

## Acknowledgments

We thank anyone who reports vulnerabilities responsibly.
