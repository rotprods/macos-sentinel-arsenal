# Install Guide

This guide walks you through installing the macOS Sentinel Arsenal manually.

## 1. Install the recommended external tools

Before the LaunchAgents, install these if you have not already:

- **LuLu** — https://objective-see.org/tools.html
- **BlockBlock** — https://objective-see.org/tools.html
- **Malwarebytes** — https://www.malwarebytes.com/
- **OverSight** — https://objective-see.org/tools.html

Each needs a one-time approval in **System Settings > Privacy & Security** and, for LuLu, **System Settings > Network**.

> **New to Terminal?** Read [`docs/primeros-pasos.md`](./docs/primeros-pasos.md) first — it explains how to open Terminal, run a command, and handle Gatekeeper.

## 2. Clone the repo

```bash
git clone https://github.com/rotprods/macos-sentinel-arsenal.git
cd macos-sentinel-arsenal
```

## 3. Run the installer

### Interactive (recommended first time)

```bash
./install.sh
```

You will be asked which agents to enable and whether to install optional dependencies.

### Non-interactive / all agents

```bash
./install.sh --all --non-interactive
```

### Dry run (see what it would do)

```bash
./install.sh --all --dry-run
```

## 4. Verify agents are loaded

```bash
launchctl list | grep com.sentinel
launchctl list | grep com.threathunter
launchctl list | grep com.roberto
```

You should see one entry per installed agent with no `-` in the second column.

## 5. Check logs

Logs live under:

```bash
~/.local/share/sentinel-arsenal/logs/
```

For example:

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/tripwire.log
```

## 6. Rollback an agent

If you want to stop one agent:

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.sentinel.tripwire.plist
```

To remove it permanently:

```bash
rm ~/Library/LaunchAgents/com.sentinel.tripwire.plist
```

## 7. Uninstall everything

```bash
./install.sh --uninstall
```

This removes all Sentinel Arsenal plists and scripts from `~/Library/LaunchAgents/` and `~/.local/share/sentinel-arsenal/`. It does **not** uninstall LuLu, BlockBlock, Malwarebytes, or OverSight.
