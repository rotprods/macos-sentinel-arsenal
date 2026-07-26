# Filesystem Tripwire

Detects unexpected changes in files you mark as critical.

## What it does

- Creates a SHA-256 baseline the first time it runs.
- Compares current hashes against the baseline every 15 minutes.
- Alerts when a watched file or directory changes or disappears.

## Configure

Edit `~/.local/share/sentinel-arsenal/watchlist.txt`:

```text
# one path per line
~/.ssh/config
~/Documents/important
```

Use `~` or `$HOME`; the script expands them.

## Logs

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/tripwire.log
```

## Reset baseline

```bash
rm ~/.local/share/sentinel-arsenal/baselines/.initialized
```

The next run recreates all baselines.
