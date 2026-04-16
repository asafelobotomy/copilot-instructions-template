#!/usr/bin/env bash
# purpose: Run an ad hoc shell snippet inside an isolated child shell without mutating the persistent terminal session.
# when: Use from terminal tools whenever a command needs shell-specific syntax, strict mode, redirection, retries, tempfiles, or multi-step control flow.
# inputs: Optional --cwd <dir>, optional --shell <bash|sh|zsh|pwsh>, optional --strict, plus either --command <shell-snippet> or shell snippet on stdin.
# outputs: Streams the child shell stdout/stderr and exits with the child command status.
# risk: safe
# source: original
set -euo pipefail

source "$(dirname "$0")/../lib.sh"

usage() {
  echo "Usage: bash scripts/harness/run-isolated-shell.sh [--cwd <dir>] [--shell <bash|sh|zsh|pwsh>] [--strict] [--command <shell-snippet>]"
  echo "   or: <shell-snippet> | bash scripts/harness/run-isolated-shell.sh [--cwd <dir>] [--shell <bash|sh|zsh|pwsh>] [--strict]"
}

cwd=""
shell_name="bash"
strict_mode="false"
command_text=""

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

case "$shell_name" in
  bash|sh|zsh)
    shell_exec=$(command -v "$shell_name" 2>/dev/null || true)
    ;;
  pwsh|powershell)
    shell_exec=$(bash "$(dirname "$0")/resolve-powershell.sh" 2>/dev/null || true)
    shell_name="pwsh"
    ;;
  *)
    err "Unsupported shell: $shell_name"
    usage
    exit 1
    ;;
esac

if [[ -z "$shell_exec" ]]; then
  err "Shell executable not found or unusable: $shell_name"
  exit 1
fi

tmp_script=$(mktemp)
cleanup() {
  rm -f "$tmp_script"
}
trap cleanup EXIT

case "$shell_name" in
  bash)
    {
      echo '#!/usr/bin/env bash'
      printf '%s\n' "$command_text"
    } > "$tmp_script"
    chmod +x "$tmp_script"
    if [[ -n "$cwd" ]]; then
      cd "$cwd"
    fi
    if [[ "$strict_mode" == "true" ]]; then
      exec "$shell_exec" --noprofile --norc -euo pipefail "$tmp_script"
    fi
    exec "$shell_exec" --noprofile --norc "$tmp_script"
    ;;
  sh)
    {
      echo '#!/usr/bin/env sh'
      if [[ "$strict_mode" == "true" ]]; then
        echo 'set -eu'
      fi
      printf '%s\n' "$command_text"
    } > "$tmp_script"
    chmod +x "$tmp_script"
    if [[ -n "$cwd" ]]; then
      cd "$cwd"
    fi
    exec "$shell_exec" "$tmp_script"
    ;;
  zsh)
    {
      echo '#!/usr/bin/env zsh'
      echo 'emulate -L zsh'
      if [[ "$strict_mode" == "true" ]]; then
        echo 'setopt errexit nounset pipefail'
      fi
      printf '%s\n' "$command_text"
    } > "$tmp_script"
    chmod +x "$tmp_script"
    if [[ -n "$cwd" ]]; then
      cd "$cwd"
    fi
    exec "$shell_exec" -f "$tmp_script"
    ;;
  pwsh)
    {
      if [[ "$strict_mode" == "true" ]]; then
        echo '$ErrorActionPreference = "Stop"'
        echo 'Set-StrictMode -Version Latest'
      fi
      printf '%s\n' "$command_text"
    } > "$tmp_script"
    if [[ -n "$cwd" ]]; then
      cd "$cwd"
    fi
    exec "$shell_exec" -NoLogo -NoProfile -NonInteractive -File "$tmp_script"
    ;;
esac