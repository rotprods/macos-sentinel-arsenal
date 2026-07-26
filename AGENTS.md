# 🤖 AGENTS.md — Guide for AI Assistants

> If you are an AI agent helping a human with this repo, read this first.

## What this repo is

A collection of **macOS LaunchAgent templates and scripts** for personal endpoint hardening. It is **not** an EDR, not a commercial product, and not a one-click "make my Mac secure" button.

## What this repo is NOT

- Not a place to commit new agents without human review.
- Not a source of secrets, API keys, or private vault paths.
- Not a replacement for the official tools: LuLu, BlockBlock, and Malwarebytes.

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
3. **Never disable LuLu, BlockBlock, or Malwarebytes** without explicit human confirmation.
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
| Per-agent docs | `docs/*.md` |

## Prompt examples you can answer

- *"Install the tripwire agent."* → Run `install.sh --agents=tripwire`.
- *"Is the localhost guard running?"* → Run `launchctl list | grep localhost-only-guard`.
- *"Show me the last tripwire alert."* → Read `~/.local/share/sentinel-arsenal/logs/tripwire.log`.
- *"Uninstall everything."* → Run `install.sh --uninstall` and confirm.

## If something is unclear

Stop and ask the human. Do not guess paths, do not hardcode home directories, and do not bypass the installer.
