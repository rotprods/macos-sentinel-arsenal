#!/usr/bin/env bash
set -euo pipefail

# Local verification suite for macOS Sentinel Arsenal.
# Usage: ./tools/verify.sh

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

log() { printf '[verify] %s\n' "$*"; }
fail() { printf '[verify] FAIL: %s\n' "$*" >&2; ERRORS=$((ERRORS + 1)); }

log "Running local verification..."

# 1. Shell syntax for all scripts.
log "Checking shell script syntax..."
for script in "$REPO_DIR"/scripts/*.sh "$REPO_DIR"/install.sh "$REPO_DIR"/tools/verify.sh; do
  if ! bash -n "$script"; then
    fail "bash syntax error in $script"
  fi
done
log "Shell syntax OK."

# 2. Every template has a matching script.
log "Checking template/script parity..."
for template in "$REPO_DIR"/launchagents/*.plist.template; do
  name=$(basename "$template" .plist.template)
  script="$REPO_DIR/scripts/${name#com.sentinel.}.sh"
  if [[ ! -f "$script" ]]; then
    fail "No matching script for $template (expected $script)"
  fi
done
for script in "$REPO_DIR"/scripts/*.sh; do
  name=$(basename "$script" .sh)
  template="$REPO_DIR/launchagents/com.sentinel.$name.plist.template"
  if [[ ! -f "$template" ]]; then
    fail "No matching template for $script (expected $template)"
  fi
done
log "Template/script parity OK."

# 3. Every template contains required placeholders.
log "Checking template placeholders..."
for template in "$REPO_DIR"/launchagents/*.plist.template; do
  if ! grep -q '{{HOME}}' "$template"; then
    fail "$template missing {{HOME}} placeholder"
  fi
  if ! grep -q '{{SCRIPT_DIR}}' "$template"; then
    fail "$template missing {{SCRIPT_DIR}} placeholder"
  fi
  # No absolute user paths should be present.
  if grep -qE '/Users/[A-Za-z0-9._-]+|/home/[A-Za-z0-9._-]+' "$template"; then
    fail "$template contains an absolute user path"
  fi
done
log "Template placeholders OK."

# 4. Every agent has documentation.
log "Checking documentation coverage..."
for script in "$REPO_DIR"/scripts/*.sh; do
  name=$(basename "$script" .sh)
  doc="$REPO_DIR/docs/${name}.md"
  if [[ ! -f "$doc" ]]; then
    fail "No docs/$name.md for $script"
  fi
done
log "Documentation coverage OK."

# 5. gitleaks.
if command -v gitleaks >/dev/null 2>&1; then
  log "Running gitleaks..."
  if ! gitleaks detect --source "$REPO_DIR" --no-git --verbose; then
    fail "gitleaks found potential secrets"
  fi
  log "gitleaks OK."
else
  log "gitleaks not installed; skipping secret scan."
fi

# 6. Required top-level files.
log "Checking required top-level files..."
for file in README.md LICENSE SECURITY.md CHANGELOG.md AGENTS.md install.md install.sh index.html; do
  if [[ ! -f "$REPO_DIR/$file" ]]; then
    fail "Missing $file"
  fi
done
log "Top-level files OK."

if [[ "$ERRORS" -eq 0 ]]; then
  log "✅ All checks passed."
  exit 0
else
  log "❌ $ERRORS check(s) failed."
  exit 1
fi
