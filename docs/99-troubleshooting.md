# Troubleshooting

## An agent exits with code 78

`EX_CONFIG` (78) usually means launchd cannot read the plist or the script path is wrong.

1. Check that the rendered plist exists in `~/Library/LaunchAgents/`.
2. Run `plutil -lint` on it.
3. Verify the script path inside the plist points to `~/.local/share/sentinel-arsenal/scripts/`.

## An agent exits with code 1 repeatedly

1. Read the `.err` log:
   ```bash
   tail ~/.local/share/sentinel-arsenal/logs/AGENT_NAME.err
   ```
2. Try running the script directly:
   ```bash
   ~/.local/share/sentinel-arsenal/scripts/AGENT_NAME.sh
   ```
3. If it fails three times in a row, unload it and report the exit code and last 20 lines.

## No terminal notifications

Install `terminal-notifier`:

```bash
brew install terminal-notifier
```

Notifications are best-effort; alerts still appear in the log files.

## lsof / yara not found

Some agents degrade gracefully when optional dependencies are missing. Install them if you want full behavior:

```bash
brew install lsof yara
```

## Uninstall

```bash
./install.sh --uninstall
```

This removes Sentinel Arsenal plists and scripts. It does **not** remove LuLu, BlockBlock, Malwarebytes, or OverSight.
