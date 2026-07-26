# YARA Monthly

Scans a configurable folder with YARA rules on the first of each month.

## What it does

- Runs only on the 1st of the month unless `YARA_FORCE=1` is set.
- Scans `~/Downloads` by default (override with `YARA_SCAN_TARGET`).
- Requires `yara` binary and at least one `.yar*` rule in `~/.local/share/sentinel-arsenal/yara-rules/`.

## Configure

Add rules:

```bash
cp my-rule.yar ~/.local/share/sentinel-arsenal/yara-rules/
```

Override target:

```bash
export YARA_SCAN_TARGET="$HOME/Downloads"
```

## Logs

```bash
tail -f ~/.local/share/sentinel-arsenal/logs/yara.log
```
