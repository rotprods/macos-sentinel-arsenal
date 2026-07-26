#!/bin/bash
# macOS Sentinel Arsenal — SAST Enforcer
# Hook-friendly secret + static-analysis guard for write-time checks.
# Usage: ./sast_enforcer.sh <file> [action]

TARGET_FILE="$1"
ACTION="$2"

if [ -z "$TARGET_FILE" ]; then
    echo "ERROR: Target file not specified."
    exit 1
fi

LOG_FILE="${SAST_LOG_FILE:-$HOME/.sentinel/logs/sast_enforcer.log}"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] SAST Enforcer triggered for $TARGET_FILE ($ACTION)" >> "$LOG_FILE"

# 1. Secret Scanning (TruffleHog / GitLeaks fallback)
if command -v trufflehog >/dev/null 2>&1; then
    TH_OUTPUT=$(trufflehog filesystem "$TARGET_FILE" --only-verified 2>&1)
    if [ $? -eq 0 ] && [ -n "$TH_OUTPUT" ]; then
        echo "🚨 [SAST: TRUFFLEHOG] Secrets detected in $TARGET_FILE!" >> "$LOG_FILE"
        echo "🚨 SECRETS DETECTED. WRITE BLOCKED BY SENTINEL ARSENAL."
        exit 1
    fi
else
    # Fallback regex if TruffleHog is not installed.
    # These patterns are intentionally strict to catch common tokens.
    if grep -q -E "sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|PGPASSWORD|AKIA[0-9A-Z]{16}" "$TARGET_FILE"; then
         echo "🚨 [SAST: FALLBACK] Secrets detected via regex in $TARGET_FILE!" >> "$LOG_FILE"
         echo "🚨 SECRETS DETECTED. WRITE BLOCKED."
         exit 1
    fi
fi

# 2. Static Analysis (Semgrep)
if command -v semgrep >/dev/null 2>&1; then
    SEMGREP_OUTPUT=$(semgrep --config "p/default" "$TARGET_FILE" --quiet --error 2>&1)
    if [ $? -ne 0 ]; then
        echo "🚨 [SAST: SEMGREP] Vulnerabilities found in $TARGET_FILE" >> "$LOG_FILE"
        echo "$SEMGREP_OUTPUT" >> "$LOG_FILE"
        echo "🚨 VULNERABILITY DETECTED. REVIEW YOUR CODE."
        exit 1
    fi
fi

echo "✅ [SAST] $TARGET_FILE is clean." >> "$LOG_FILE"
exit 0
