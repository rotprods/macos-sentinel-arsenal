# MCP Zombie Killer

Kills orphaned `node`/`mcp` processes that run too long and consume too much CPU.

## What it does

- Scans for processes matching `node`, `mcp`, `mcp-server`, `npm`, or `npx`.
- Targets processes older than 4 hours and using at least 5% CPU.
- Sends `TERM`, waits 2 seconds, then `KILL` if still alive.

## Tuning

Set environment variables in the LaunchAgent plist or in your shell:

- `MAX_CPU` — minimum CPU percentage (default `5.0`).
- `MAX_AGE_MIN` — minimum age in minutes (default `240`).

## Logs

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/mcp-zombie-killer.log
```
