#!/usr/bin/env bash
# purpose: Run an ad hoc shell snippet inside an isolated bash process with strict mode enabled.
# when: Use from terminal tools in zsh workspaces when a one-off command needs strict mode, redirection, or tempfile plumbing; do not use for existing repo scripts that already set strict mode internally.
# inputs: Optional --cwd <dir> plus either --command <shell-snippet> or shell snippet on stdin.
# outputs: Streams the child bash stdout/stderr and exits with the child command status.
# risk: safe
# source: original
set -euo pipefail

source "$(dirname "$0")/../lib.sh"

usage() {
  echo "Usage: bash scripts/tests/run-strict-bash.sh [--cwd <dir>] [--command <shell-snippet>]"
  echo "   or: <shell-snippet> | bash scripts/tests/run-strict-bash.sh [--cwd <dir>]"
}

cwd=""
command_text=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd)
      cwd="$2"
      shift 2
      ;;
    --command)
      command_text="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$command_text" && ! -t 0 ]]; then
  command_text=$(cat)
fi

if [[ -z "$command_text" ]]; then
  usage
  exit 1
fi

if [[ -n "$cwd" && ! -d "$cwd" ]]; then
  err "Directory not found: $cwd"
  exit 1
fi

tmp_script=$(mktemp)
cleanup() {
  rm -f "$tmp_script"
}
trap cleanup EXIT

printf '%s\n' "$command_text" > "$tmp_script"

if [[ -n "$cwd" ]]; then
  cd "$cwd"
fi

exec bash -euo pipefail "$tmp_script"