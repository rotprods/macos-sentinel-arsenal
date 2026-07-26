# Port Sweep Monitor

Alerts when processes bind to wildcard interfaces (`0.0.0.0` or `::`) instead of localhost.

## What it does

- Runs `lsof -nP -iTCP -sTCP:LISTEN` every 10 minutes.
- Ignores localhost-only listeners.
- Supports an allowlist file for intentional wildcard services.

## Configure

Edit `~/.local/share/sentinel-arsenal/port-allowlist.txt`:

```text
22
443
```

One port per line.

## Logs

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/port-sweep.log
```
