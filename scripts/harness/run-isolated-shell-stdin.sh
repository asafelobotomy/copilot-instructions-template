#!/usr/bin/env bash
# purpose: Run a multi-line shell snippet from stdin inside an isolated child shell without mutating the persistent terminal session.
# when: Use from terminal tools when a here-doc or piped snippet is clearer than a one-liner and the command needs shell-specific syntax or strict mode.
# inputs: Optional --cwd <dir>, optional --shell <bash|sh|zsh|pwsh>, optional --strict, plus shell snippet on stdin.
# outputs: Streams the child shell stdout/stderr and exits with the child command status.
# risk: safe
# source: original
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)

usage() {
  echo "Usage: bash scripts/harness/run-isolated-shell-stdin.sh [--cwd <dir>] [--shell <bash|sh|zsh|pwsh>] [--strict] <<'EOF'"
  echo "         <shell-snippet>"
  echo "EOF"
  echo "   or: <shell-snippet> | bash scripts/harness/run-isolated-shell-stdin.sh [--cwd <dir>] [--shell <bash|sh|zsh|pwsh>] [--strict]"
}

cwd=""
shell_name="bash"
strict_mode="false"
stdin_payload=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd)
      cwd="$2"
      shift 2
      ;;
    --shell)
      shell_name="$2"
      shift 2
      ;;
    --strict)
      strict_mode="true"
      shift
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

args=(--shell "$shell_name")
if [[ -n "$cwd" ]]; then
  args+=(--cwd "$cwd")
fi
if [[ "$strict_mode" == "true" ]]; then
  args+=(--strict)
fi

exec bash "$script_dir/run-isolated-shell.sh" "${args[@]}" --command "$stdin_payload"