# Localhost-Only Guard

Detects development servers exposed to the LAN.

## What it does

- Scans listening TCP sockets every 30 seconds.
- Looks for common dev server processes: `node`, `python`, `vite`, `next`, `nuxt`, `remix`, `astro`, `php`, `ruby`, `bundle`, `cargo`, `go`.
- Ignores `127.0.0.1` and `[::1]`.
- Optional kill mode via `LOCALHOST_ENFORCE=1`.

## Configure

Edit `~/.local/share/sentinel-arsenal/localhost-allowlist.txt`:

```text
3000
5173
```

One port per line.

To enable enforcement, set `LOCALHOST_ENFORCE=1` in the agent environment.

## Logs

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/localhost-only.log
```
