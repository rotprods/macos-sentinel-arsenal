# Audit Log Rotate

Rotates audit logs with SHA-256 manifests for tamper-evident evidence.

## What it does

- Archives logs larger than 1 KB every Monday at 09:00.
- Gzips archives and records SHA-256 hashes in a manifest.
- Deletes archives older than 90 days.

## Configure

- `LOG_RETAIN_DAYS` — retention period (default `90`).

## Logs

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/rotate.log
```

## Verify manifest

```bash
cat ~/.local/share/sentinel-arsenal/archive/manifest.txt
```
