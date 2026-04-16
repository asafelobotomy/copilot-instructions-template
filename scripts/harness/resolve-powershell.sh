#!/usr/bin/env bash
# purpose:  Resolve a working PowerShell executable for hook tests, coverage, and audit checks.
# when:     Use when PowerShell may be installed as pwsh, powershell, or via an explicit override path; not for Windows hook command strings.
# inputs:   Optional --check to return only an exit code; optional env vars PWSH_BIN, POWERSHELL_BIN, or PWSH_CACHE_FILE.
# outputs:  Prints the resolved executable path on stdout and exits 0, or exits 1 if no usable PowerShell executable is available.
# risk:     safe
# source:   original
set -euo pipefail

usage() {
  echo "Usage: bash scripts/harness/resolve-powershell.sh [--check]" >&2
}

cache_signature() {
  printf '%s\n%s\n%s\n' "${PATH:-}" "${PWSH_BIN:-}" "${POWERSHELL_BIN:-}"
}

cache_file_path() {
  if [[ -n "${PWSH_CACHE_FILE:-}" ]]; then
    printf '%s\n' "$PWSH_CACHE_FILE"
    return 0
  fi
  if [[ -n "${PWSH_RESOLUTION_CACHE_FILE:-}" ]]; then
    printf '%s\n' "$PWSH_RESOLUTION_CACHE_FILE"
    return 0
  fi

  return 1
}

read_cache() {
  if [[ "${PWSH_RESOLUTION_DISABLE_CACHE:-0}" == "1" ]]; then
    return 1
  fi

  local cache_file signature_path signature_pwsh signature_powershell
  cache_file=$(cache_file_path) || return 1
  [[ -r "$cache_file" ]] || return 1

  local -a cache_lines=()
  mapfile -t cache_lines < "$cache_file" 2>/dev/null || return 1
  [[ ${#cache_lines[@]} -ge 4 ]] || return 1

  signature_path="${PATH:-}"
  signature_pwsh="${PWSH_BIN:-}"
  signature_powershell="${POWERSHELL_BIN:-}"

  [[ "${cache_lines[0]}" == "$signature_path" ]] || return 1
  [[ "${cache_lines[1]}" == "$signature_pwsh" ]] || return 1
  [[ "${cache_lines[2]}" == "$signature_powershell" ]] || return 1

  case "${cache_lines[3]}" in
    ok)
      if [[ ${#cache_lines[@]} -ge 5 && -x "${cache_lines[4]}" ]]; then
        printf '%s\n' "${cache_lines[4]}"
        return 0
      fi
      return 1
      ;;
    none)
      return 2
      ;;
    *)
      return 1
      ;;
  esac
}

write_cache() {
  if [[ "${PWSH_RESOLUTION_DISABLE_CACHE:-0}" == "1" ]]; then
    return 0
  fi

  local status="$1"
  local value="${2:-}"
  local cache_file cache_dir
  cache_file=$(cache_file_path) || return 0
  cache_dir="${cache_file%/*}"
  if [[ "$cache_dir" != "$cache_file" && ! -d "$cache_dir" ]]; then
    return 0
  fi

  {
    printf '%s\n' "${PATH:-}"
    printf '%s\n' "${PWSH_BIN:-}"
    printf '%s\n' "${POWERSHELL_BIN:-}"
    printf '%s\n' "$status"
    if [[ "$status" == "ok" ]]; then
      printf '%s\n' "$value"
    fi
  } > "$cache_file"
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
  local candidate resolved cached

  if cached=$(read_cache); then
    printf '%s\n' "$cached"
    return 0
  else
    local cache_rc=$?
    if [[ $cache_rc -eq 2 ]]; then
      return 1
    fi
  fi

  for candidate in "${PWSH_BIN:-}" "${POWERSHELL_BIN:-}" pwsh powershell; do
    resolved=$(resolve_candidate "$candidate") || continue
    if probe_candidate "$resolved"; then
      write_cache ok "$resolved"
      printf '%s\n' "$resolved"
      return 0
    fi
  done

  write_cache none
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