# LuLu Posture Monitor

Verifies that the LuLu outgoing firewall is active and warns on overly permissive defaults.

## What it does

- Confirms `LuLu.app` is installed and its process is running.
- Warns if LuLu is not running.
- Flags any LuLu rule containing the literal word `any`.

## Requirements

Install LuLu from https://objective-see.org/tools.html first.

## Logs

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/lulu-posture.log
```
