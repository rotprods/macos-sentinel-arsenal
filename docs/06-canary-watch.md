# Canary Watch

Monitors decoy canary files for tampering or deletion.

## What it does

- Creates canary files defined in `canary-list.txt` if they do not exist.
- Compares each canary against its expected SHA-256 hash.
- Alerts on tampering, deletion, or unexpected files inside the canary directory.

## Configure

Edit `~/.local/share/sentinel-arsenal/canary-list.txt`:

```text
# name|expected_content
invoice.pdf|canary-value-42
```

Set `CANARY_STRICT=1` to also flag unknown files in the canary directory.

## Logs

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/canary.log
```
