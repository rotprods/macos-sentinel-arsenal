# Install BlockBlock

BlockBlock is a free persistence monitor from Objective-See.

## Steps

1. Download the latest release from https://objective-see.org/tools.html.
2. Open the `.dmg` and drag `BlockBlock.app` to `/Applications`.
3. Launch `BlockBlock.app` and follow the setup assistant.
4. Grant permissions in **System Settings > Privacy & Security**.
5. Make sure `BlockBlock Helper.app` is set to start at login.

## Verify

```bash
pgrep -f "BlockBlock Helper"
```

## Sentinel integration

The `com.sentinel.blockblock-keepalive` agent restarts the helper if it stops.
