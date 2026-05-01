#!/usr/bin/env bash
set -euo pipefail
# lib-hooks.sh — shared utilities for agent lifecycle hook scripts.
# Source this file at the top of each hook script:
#   source "$(dirname "$0")/lib-hooks.sh"
# Do NOT execute this file directly.

# json_escape <string>
#   Return the string with JSON special characters escaped, suitable for
#   embedding inside a double-quoted JSON value.  Falls back to the raw
#   string if python3 is unavailable so hooks never crash on a missing dep.
json_escape() {
  printf '%s' "$1" \
    | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()), end='')" 2>/dev/null \
    | sed 's/^"//;s/"$//' \
    || printf '%s' "$1"
}

# json_field <json_string> <field_name> [default]
#   Extract a top-level string field from a JSON object.
#   Returns the field value, or [default] (empty string if omitted) when the
#   field is absent, null, or python3 is unavailable.
json_field() {
  local json="$1" field="$2" default="${3:-}"
  local val
  val=$(printf '%s' "$json" | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    v=d.get('$field')
    print(v if isinstance(v,str) and v else '')
except Exception:
    print('')
" 2>/dev/null) || val=""
  printf '%s' "${val:-$default}"
}

# try_exec_in_container <cmd> [args...]
#   Attempt to exec <cmd> via distrobox then toolbox (for immutable desktops).
#   Does nothing and returns 1 if neither container manager is found.
try_exec_in_container() {
  local cmd="$1"; shift
  if command -v distrobox &>/dev/null; then
    exec distrobox enter -- "$cmd" "$@" 2>/dev/null
  elif command -v toolbox &>/dev/null; then
    exec toolbox run "$cmd" "$@" 2>/dev/null
  fi
  return 1
}
