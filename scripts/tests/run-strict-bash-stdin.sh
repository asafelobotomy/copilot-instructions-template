#!/usr/bin/env bash
# purpose: Run a multi-line shell snippet from stdin inside an isolated bash process with strict mode enabled.
# when: Use from terminal tools in zsh workspaces when a multi-line snippet is easier to express as a here-doc or pipe; do not use when an existing repo script already covers the task.
# inputs: Optional --cwd <dir> plus shell snippet on stdin.
# outputs: Streams the child bash stdout/stderr and exits with the child command status.
# risk: safe
# source: original
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)

usage() {
  echo "Usage: bash scripts/tests/run-strict-bash-stdin.sh [--cwd <dir>] <<'EOF'"
  echo "         <shell-snippet>"
  echo "EOF"
  echo "   or: <shell-snippet> | bash scripts/tests/run-strict-bash-stdin.sh [--cwd <dir>]"
}

cwd=""
stdin_payload=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd)
      cwd="$2"
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

if [[ -t 0 ]]; then
  usage
  exit 1
fi

stdin_payload=$(cat)
if [[ -z "$stdin_payload" ]]; then
  usage
  exit 1
fi

args=()
if [[ -n "$cwd" ]]; then
  args+=(--cwd "$cwd")
fi

exec bash "$script_dir/run-strict-bash.sh" "${args[@]}" --command "$stdin_payload"