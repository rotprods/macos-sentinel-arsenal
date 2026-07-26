#!/usr/bin/env bash
set -euo pipefail

# macOS Sentinel Arsenal installer.
# Usage: ./install.sh [--all|--agents=a,b,c] [--non-interactive] [--dry-run] [--uninstall]

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
LAUNCH_AGENTS_DIR="$HOME_DIR/Library/LaunchAgents"
SENTINEL_HOME="$HOME_DIR/.local/share/sentinel-arsenal"
SCRIPT_DIR="$SENTINEL_HOME/scripts"
LOG_DIR="$SENTINEL_HOME/logs"

echo() { printf '%s\n' "$*"; }

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --all                Install every agent.
  --agents=LIST        Comma-separated list of agent names (e.g. tripwire,port-sweep).
  --non-interactive    Do not prompt; use defaults.
  --dry-run            Show what would be done without changing the system.
  --uninstall          Remove all Sentinel Arsenal plists and scripts.
  --help               Show this message.

Examples:
  $0 --all --non-interactive
  $0 --agents=tripwire,canary-watch
  $0 --dry-run
EOF
}

log() {
  printf '[installer] %s\n' "$*"
}

error() {
  printf '[installer] ERROR: %s\n' "$*" >&2
  exit 1
}

# Validate environment.
if [[ "$(uname -s)" != "Darwin" ]]; then
  error "This installer is for macOS only."
fi

# Parse arguments.
MODE="interactive"
AGENTS=""
DRY_RUN=0
UNINSTALL=0

for arg in "$@"; do
  case "$arg" in
    --all)
      AGENTS="all"
      ;;
    --non-interactive)
      MODE="non-interactive"
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --uninstall)
      UNINSTALL=1
      ;;
    --agents=*)
      AGENTS="${arg#--agents=}"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $arg"
      ;;
  esac
done

all_agent_names=(
  tripwire
  mcp-zombie-killer
  blockblock-keepalive
  lulu-posture
  port-sweep
  canary-watch
  localhost-only-guard
  macos-audit
  yara-monthly
  auditlog-rotate
  login-item-inspector
)

if [[ "$AGENTS" == "all" ]]; then
  selected=("${all_agent_names[@]}")
elif [[ -n "$AGENTS" ]]; then
  IFS=',' read -ra selected <<< "$AGENTS"
else
  selected=()
fi

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] would run: $*"
  else
    "$@"
  fi
}

run_or_warn() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] would run: $*"
  else
    "$@" || log "WARNING: command failed: $*"
  fi
}

ensure_dirs() {
  run mkdir -p "$SCRIPT_DIR" "$LOG_DIR" "$SENTINEL_HOME/baselines" \
    "$SENTINEL_HOME/canaries" "$SENTINEL_HOME/archive" \
    "$SENTINEL_HOME/reports" "$SENTINEL_HOME/yara-rules"
}

install_scripts() {
  for script in "$REPO_DIR"/scripts/*.sh; do
    [[ -e "$script" ]] || continue
    target="$SCRIPT_DIR/$(basename "$script")"
    run cp "$script" "$target"
    run chmod +x "$target"
  done
}

install_default_configs() {
  # Watchlist for tripwire.
  if [[ ! -f "$SENTINEL_HOME/watchlist.txt" ]]; then
    run cat > "$SENTINEL_HOME/watchlist.txt" <<'EOF'
# Sentinel Arsenal tripwire watchlist
# Add one absolute or $HOME-relative path per line.
# ~/.ssh/authorized_keys
EOF
  fi

  # Canary list.
  if [[ ! -f "$SENTINEL_HOME/canary-list.txt" ]]; then
    run cat > "$SENTINEL_HOME/canary-list.txt" <<'EOF'
# Sentinel Arsenal canary list
# Format: name|expected_content
# secret-token.txt|canary-placeholder
EOF
  fi

  # Allowlists.
  for f in port-allowlist.txt localhost-allowlist.txt login-items-allowlist.txt; do
    run touch "$SENTINEL_HOME/$f"
  done
}

render_plist() {
  local template="$1"
  local output="$2"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] would render $template -> $output"
    return
  fi
  sed \
    -e "s|{{HOME}}|$HOME_DIR|g" \
    -e "s|{{SCRIPT_DIR}}|$SCRIPT_DIR|g" \
    "$template" > "$output"
}

install_agent() {
  local name="$1"
  local template="$REPO_DIR/launchagents/com.sentinel.$name.plist.template"
  local output="$LAUNCH_AGENTS_DIR/com.sentinel.$name.plist"

  if [[ ! -f "$template" ]]; then
    log "Skipping unknown agent: $name (template not found)"
    return 1
  fi

  # Backup existing plist.
  if [[ -f "$output" ]]; then
    run cp "$output" "$output.bak.$(date +%Y%m%d%H%M%S)"
  fi

  render_plist "$template" "$output"

  if [[ "$DRY_RUN" -eq 0 ]]; then
    # Load or bootstrap the agent.
    if launchctl list "com.sentinel.$name" >/dev/null 2>&1; then
      run_or_warn launchctl bootout "gui/$(id -u)" "$output"
    fi
    run_or_warn launchctl bootstrap "gui/$(id -u)" "$output"
  fi
}

uninstall() {
  log "Uninstalling Sentinel Arsenal..."
  for name in "${all_agent_names[@]}"; do
    local plist="$LAUNCH_AGENTS_DIR/com.sentinel.$name.plist"
    if [[ -f "$plist" ]]; then
      if [[ "$DRY_RUN" -eq 0 ]]; then
        run_or_warn launchctl bootout "gui/$(id -u)" "$plist" || true
      else
        log "[dry-run] would unload $plist"
      fi
      run rm -f "$plist"
    fi
  done
  run rm -rf "$SCRIPT_DIR"
  log "Uninstall complete. Logs and data in $SENTINEL_HOME were preserved."
}

prompt_agents() {
  echo "Available agents:"
  local i=1
  for name in "${all_agent_names[@]}"; do
    echo "  $i. $name"
    i=$((i + 1))
  done
  echo "Enter comma-separated numbers or names, or 'all':"
  read -r answer
  if [[ "$answer" == "all" ]]; then
    selected=("${all_agent_names[@]}")
    return
  fi
  # Try numeric.
  if [[ "$answer" =~ ^[0-9,]+$ ]]; then
    local temp=()
    IFS=',' read -ra nums <<< "$answer"
    for n in "${nums[@]}"; do
      local idx=$((n - 1))
      if (( idx >= 0 && idx < ${#all_agent_names[@]} )); then
        temp+=("${all_agent_names[$idx]}")
      fi
    done
    selected=("${temp[@]}")
  else
    IFS=',' read -ra selected <<< "$answer"
  fi
}

# Main flow.
if [[ "$UNINSTALL" -eq 1 ]]; then
  uninstall
  exit 0
fi

# Interactive agent selection.
if [[ ${#selected[@]} -eq 0 && "$MODE" == "interactive" ]]; then
  prompt_agents
fi

if [[ ${#selected[@]} -eq 0 ]]; then
  error "No agents selected. Use --all, --agents=... or run interactively."
fi

log "Selected agents: ${selected[*]}"

ensure_dirs
install_scripts
install_default_configs

for name in "${selected[@]}"; do
  install_agent "$name"
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run complete. No changes were made."
else
  log "Installation complete. Verify with: launchctl list | grep com.sentinel"
fi
