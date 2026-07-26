# Install LuLu

LuLu is a free, open-source outgoing firewall from Objective-See.

## Steps

1. Download the latest release from https://objective-see.org/tools.html.
2. Open the `.dmg` and drag `LuLu.app` to `/Applications`.
3. Launch `LuLu.app`.
4. Grant permissions in **System Settings > Privacy & Security**.
5. Allow the network extension in **System Settings > Network**.
6. Review default rules and remove any overly permissive `any` rules.

## Verify

```bash
pgrep -f LuLu
```

## Sentinel integration

The `com.sentinel.lulu-posture` agent checks LuLu daily at 10:00.
