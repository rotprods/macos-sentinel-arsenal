# BlockBlock Keepalive

Ensures the Objective-See BlockBlock Helper.app is running.

## What it does

- Checks whether `BlockBlock Helper.app` is running every 30 minutes.
- If not, attempts to reopen it with `open`.
- Alerts on failure.

## Requirements

Install BlockBlock from https://objective-see.org/tools.html first.

## Logs

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/blockblock-keepalive.log
```
