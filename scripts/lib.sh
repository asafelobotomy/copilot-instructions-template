#!/usr/bin/env bash
# scripts/lib.sh — shared utilities for sync scripts.
set -euo pipefail

# err() — timestamped error to stderr.
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ERROR: $*" >&2
}

# log_step() — progress output to stdout.
log_step() {
  echo "→ $*"
}

# require_command() — fail fast if required binaries are missing.
# Usage: require_command python3 jq
require_command() {
  local missing=()
  for cmd in "$@"; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    err "Required command(s) not found: ${missing[*]}"
    exit 1
  fi
}

# setup_tmpdir() — create a temp dir and register an EXIT trap to remove it.
# Sets global TMPDIR_WORK; callers use it directly.
setup_tmpdir() {
  TMPDIR_WORK=$(mktemp -d)
  trap 'rm -rf "$TMPDIR_WORK"' EXIT
}

# Validate that $mode is --check or --write; print usage and exit 1 otherwise.
# Usage: require_check_write_mode <script_name> <mode>
require_check_write_mode() {
  local script_name="$1" mode="$2"
  if [[ "$mode" != "--check" && "$mode" != "--write" ]]; then
    echo "Usage: bash scripts/${script_name} [--check|--write]"
    exit 1
  fi
}

# require_python_check_write() — validate mode and require python3 in one call.
# Combines require_check_write_mode + require_command python3.
# Usage: require_python_check_write <script_name> <mode>
require_python_check_write() {
  require_check_write_mode "$1" "$2"
  require_command python3
}
