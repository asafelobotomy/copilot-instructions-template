#!/usr/bin/env bash
# scripts/lib.sh — shared utilities for sync scripts.
set -euo pipefail

# Validate that $mode is --check or --write; print usage and exit 1 otherwise.
# Usage: require_check_write_mode <script_name> <mode>
require_check_write_mode() {
  local script_name="$1" mode="$2"
  if [[ "$mode" != "--check" && "$mode" != "--write" ]]; then
    echo "Usage: bash scripts/${script_name} [--check|--write]"
    exit 1
  fi
}
