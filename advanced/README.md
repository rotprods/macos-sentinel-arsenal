# Advanced macOS Security Toolkit

This directory contains extra, standalone components that you can layer on top of the core Sentinel Arsenal agents. They are **optional**, **self-contained**, and designed to be safe for third-party use.

> ⚠️ Review every script before running it. Some tools inspect or lock files under `$HOME` and may require `SENTINEL_HOME` to be set.

## Components

| File | Purpose |
|------|---------|
| `entropy_scanner.py` | Shannon-entropy scanner to spot obfuscated or encrypted payloads in files or `node_modules` trees. |
| `sast_enforcer.sh` | Write-time hook that blocks commits/edits containing likely secrets (TruffleHog or regex fallback) and runs Semgrep. |
| `audit_chain.py` | Tamper-evident Merkle audit chain (`~/.sentinel/audit/chain.jsonl`). |
| `drift-detect.sh` | Compares live macOS state against a saved baseline and reports drift. |
| `drift-baseline.sh` | Generates a self-integrity baseline of these toolkit files. |
| `harden.sh` | One-shot hardening script: `.env` permissions, SIP/Gatekeeper/FileVault checks, open ports, baseline creation. |
| `yara-rules/macos_security.yar` | macOS-focused YARA rules for reverse shells, persistence, infostealers, cryptominers, prompt injection, and MCP hijacking. |
| `docs/` | Playbooks for macOS audit, forensics, and threat hunting. |
| `skills/` | Claude Code skills (`/macaudit`, `/macforensics`, `/merge-train-safe`) that wrap the toolkit into reusable agent workflows. |

## Quick start

```bash
# 1. Generate a baseline
./advanced/harden.sh

# 2. Check for drift
./advanced/drift-detect.sh

# 3. Verify the audit chain
python3 advanced/audit_chain.py

# 4. Scan a suspicious folder with YARA
yara -r advanced/yara-rules/macos_security.yar ~/Downloads

# 5. Scan a suspicious folder for entropy
python3 advanced/entropy_scanner.py ~/Downloads/suspicious-package
```

## Data layout

All helpers default to writing under `$HOME/.sentinel`:

```
~/.sentinel/
├── audit/chain.jsonl       # tamper-evident audit log
├── baselines/              # drift + self-integrity baselines
├── evidence/               # hardening logs
├── logs/                   # per-tool logs
└── quarantine/             # suspicious files moved here
```

Override with:

```bash
export SENTINEL_HOME=/path/to/your/sentinel-data
```

## Claude Code skills

The `skills/` directory contains reusable Claude Code skill definitions. Copy any of them to `~/.claude/skills/<name>/SKILL.md` to make them invocable with `/` commands:

| Skill | Command | Purpose |
|---|---|---|
| `skills/macosaudit` | `/macaudit` | Run a posture audit using `harden.sh`, `drift-detect.sh`, and `audit_chain.py`. |
| `skills/macforensics` | `/macforensics` | Collect and preserve evidence after a suspected compromise. |
| `skills/merge-train-safe` | `/merge-train-safe` | Safe merge-train workflow with billing check, trap detection, and CI verification. |

Each skill includes the standard frontmatter, invocation triggers, protocol steps, guardrails, and anti-patterns.

## Hook usage example

Use `sast_enforcer.sh` as a pre-write or pre-commit guard:

```bash
./advanced/sast_enforcer.sh ./some-new-file.txt write_file
```

## License

Same as the parent repository: MIT.
