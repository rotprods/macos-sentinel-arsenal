# 🤖 AGENTS.md — Guide for AI Assistants

> If you are an AI agent helping a human with this repo, read this first.

## What this repo is

A collection of **macOS LaunchAgent templates and scripts** for personal endpoint hardening. It is **not** an EDR, not a commercial product, and not a one-click "make my Mac secure" button.

## What this repo is NOT

- Not a place to commit new agents without human review.
- Not a source of secrets, API keys, or private vault paths.
- Not a replacement for the official tools: LuLu, BlockBlock, Malwarebytes, and OverSight.

## Agent onboarding workflow (read this before acting)

When a human opens this repo, **do not install anything silently**. Follow this walkthrough:

### Step 0 — Open the visual guide

If you are running in a desktop/macOS environment, open the HTML guide for the human:

```bash
open index.html
```

On Linux, use `xdg-open index.html`. In a web-only environment, share the GitHub Pages URL or tell them to double-click `index.html` in Finder.

```
https://rotprods.github.io/macos-sentinel-arsenal/
```

### Step 1 — Explain what they are looking at

Tell the human, in plain language:

1. This is a **free, local hardening toolkit** for macOS.
2. It adds **11 small background agents** that watch files, processes, network ports, and startup items.
3. It works best alongside **LuLu** (outgoing firewall), **BlockBlock** (persistence protection), **Malwarebytes** (anti-malware), and **OverSight** (mic/camera monitor).
4. Everything is **optional** and can be uninstalled.

Point them to the sections in `index.html`: stack, agents, install steps, docs.

### Step 2 — Check prerequisites

Ask the human:

> **"Do you have macOS 13 or newer, and are you comfortable running Terminal commands?"**

If they are not comfortable, open `docs/primeros-pasos.md` first and walk them through it.

### Step 3 — Ask what they want to install

Ask one thing at a time. Use the exact wording below, and wait for an answer before continuing.

#### Question A — External security tools

> **"Before the Sentinel agents, I recommend installing four free/paid tools that form the foundation. Which ones do you already have, and which ones do you want me to guide you through?"**

- **LuLu** — outgoing firewall (blocks apps from phoning home).
- **BlockBlock** — persistence monitor (alerts if malware tries to set itself to start automatically).
- **Malwarebytes** — anti-malware scanner and real-time protection.
- **OverSight** — alerts when any app uses your microphone or camera.
- **None — I only want the Sentinel LaunchAgents.**

For each tool the human wants, open the matching install guide:

| Tool | Guide |
|---|---|
| LuLu | `docs/install-lulu.md` |
| BlockBlock | `docs/install-blockblock.md` |
| Malwarebytes | `docs/install-malwarebytes.md` |
| OverSight | `docs/install-oversight.md` |

#### Question B — Sentinel LaunchAgents

> **"Now, which Sentinel agents do you want to install?"**

Show the table from `index.html` or `README.md`. Then recommend a starter set:

- **Beginner / just browsing:** `tripwire`, `mcp-zombie-killer`, `login-item-inspector`.
- **Standard hardening:** all 11 agents with `--all`.
- **Custom:** ask them to pick from the list.

### Step 4 — Install what they chose

If they want the whole fleet, run:

```bash
./install.sh --all --non-interactive
```

If they want a subset, run each agent by name (comma-separated if supported, otherwise one by one):

```bash
./install.sh --agents=tripwire
./install.sh --agents=mcp-zombie-killer
./install.sh --agents=login-item-inspector
```

If they only want to preview changes:

```bash
./install.sh --all --dry-run
```

### Step 5 — Verify

After install, run:

```bash
launchctl list | grep com.sentinel
ls ~/.local/share/sentinel-arsenal/logs/
```

Explain the output. If any agent shows a `-` in the second column, read its log and report the issue.

### Step 6 — Teach them to check logs

Show them one relevant log:

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/tripwire.log
```

Or point them to `docs/99-troubleshooting.md`.

## Canonical commands

### Install everything non-interactively

```bash
./install.sh --all --non-interactive
```

### Install a single agent

```bash
./install.sh --agents=tripwire
```

### Check if an agent is loaded

```bash
launchctl list | grep com.sentinel
launchctl print gui/$(id -u)/com.sentinel.tripwire
```

### View logs

```bash
ls ~/.local/share/sentinel-arsenal/logs/
tail -f ~/.local/share/sentinel-arsenal/logs/tripwire.log
```

### Unload an agent (rollback)

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.sentinel.tripwire.plist
```

## Safety rules

1. **Never run scripts as root** unless a specific hardening step explicitly requires `sudo` and the human has confirmed.
2. **Always back up** existing `~/Library/LaunchAgents/` files before overwriting. The installer does this automatically.
3. **Never disable LuLu, BlockBlock, Malwarebytes, or OverSight** without explicit human confirmation.
4. **If an agent fails three times in a row**, stop and report the exact exit code and last 20 lines of its stderr log.
5. **Do not add new agents** to the repo without updating `README.md`, `index.html`, `install.sh`, and the corresponding `docs/` file.

## Where things live

| Asset | Path in repo |
|---|---|
| LaunchAgent templates | `launchagents/*.plist.template` |
| Scripts | `scripts/*.sh` |
| Installer | `install.sh` |
| Human guide | `install.md` |
| Visual guide | `index.html` |
| Beginner guide | `docs/primeros-pasos.md` |
| Per-agent docs | `docs/*.md` |

## Prompt examples you can answer

- *"Install the tripwire agent."* → Run `install.sh --agents=tripwire`.
- *"Is the localhost guard running?"* → Run `launchctl list | grep localhost-only-guard`.
- *"Show me the last tripwire alert."* → Read `~/.local/share/sentinel-arsenal/logs/tripwire.log`.
- *"Uninstall everything."* → Run `install.sh --uninstall` and confirm.
- *"I don't know where to start."* → Open `index.html`, then follow the onboarding workflow above.

## If something is unclear

Stop and ask the human. Do not guess paths, do not hardcode home directories, and do not bypass the installer.
