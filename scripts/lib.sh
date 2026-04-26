#!/usr/bin/env bash
# scripts/lib.sh — shared utilities for sync scripts.
set -euo pipefail

# err() — timestamped error to stderr.
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ERROR: $*" >&2
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

# require_file <path> [error_prefix]
#   Fail fast if a required file is missing.
#   error_prefix defaults to ROOT_DIR for relative path display.
# Usage: require_file "template/copilot-instructions.md"
require_file() {
  local path="$1" prefix="${2:-${ROOT_DIR:-}}"
  local full_path
  if [[ "$path" = /* ]]; then
    full_path="$path"
  else
    full_path="${prefix:+$prefix/}$path"
  fi
  if [[ ! -f "$full_path" ]]; then
    err "Required file not found: $full_path"
    exit 1
  fi
}

# find_repo_root
#   Walk up from the script's own directory until .git is found.
#   Prints the repo root path. Exits 1 if not found.
find_repo_root() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  while [[ "$dir" != "/" ]]; do
    [[ -d "$dir/.git" ]] && { echo "$dir"; return 0; }
    dir="$(dirname "$dir")"
  done
  err "Could not find repo root (no .git directory found)"
  exit 1
}
