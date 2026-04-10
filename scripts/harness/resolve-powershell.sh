#!/usr/bin/env bash
# purpose:  Resolve a working PowerShell executable for hook tests, coverage, and audit checks.
# when:     Use when PowerShell may be installed as pwsh, powershell, or via an explicit override path; not for Windows hook command strings.
# inputs:   Optional --check to return only an exit code; optional env vars PWSH_BIN or POWERSHELL_BIN.
# outputs:  Prints the resolved executable path on stdout and exits 0, or exits 1 if no usable PowerShell executable is available.
# risk:     safe
# source:   original
set -euo pipefail

usage() {
  echo "Usage: bash scripts/harness/resolve-powershell.sh [--check]" >&2
}

resolve_candidate() {
  local candidate="$1"
  if [[ -z "$candidate" ]]; then
    return 1
  fi

  if [[ "$candidate" == */* ]]; then
    [[ -x "$candidate" ]] || return 1
    printf '%s\n' "$candidate"
    return 0
  fi

  command -v "$candidate" 2>/dev/null || return 1
}

probe_candidate() {
  local executable="$1"
  "$executable" -NoLogo -NoProfile -Command "exit 0" >/dev/null 2>&1
}

resolve_powershell() {
  local candidate resolved
  for candidate in "${PWSH_BIN:-}" "${POWERSHELL_BIN:-}" pwsh powershell; do
    resolved=$(resolve_candidate "$candidate") || continue
    if probe_candidate "$resolved"; then
      printf '%s\n' "$resolved"
      return 0
    fi
  done

  return 1
}

case "${1:-}" in
  "")
    resolve_powershell
    ;;
  --check)
    resolve_powershell >/dev/null
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  *)
    usage
    exit 1
    ;;
esac