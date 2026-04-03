#!/usr/bin/env bash
# purpose:  Run the full repository test suite while capturing verbose output to a log file and printing only a bounded tail.
# when:     Use from terminal tools or zsh sessions when `bash tests/run-all.sh` would produce too much output; not needed when the caller already captures the full log.
# inputs:   Optional --log-file PATH and --tail-lines N.
# outputs:  Prints LOG_FILE, EXIT_CODE, and the final N log lines to stdout; writes the full suite transcript to the log file.
# risk:     safe
# source:   original
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
LOG_FILE="${LOG_FILE:-/tmp/copilot-run-all.log}"
TAIL_LINES="${TAIL_LINES:-120}"

usage() {
  echo "Usage: bash scripts/tests/run-all-captured.sh [--log-file <path>] [--tail-lines <n>]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --log-file)
      [[ $# -ge 2 ]] || { usage; exit 1; }
      LOG_FILE="$2"
      shift 2
      ;;
    --tail-lines)
      [[ $# -ge 2 ]] || { usage; exit 1; }
      TAIL_LINES="$2"
      shift 2
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
done

[[ "$TAIL_LINES" =~ ^[0-9]+$ ]] || {
  echo "tail-lines must be a non-negative integer: $TAIL_LINES" >&2
  exit 1
}

mkdir -p "$(dirname "$LOG_FILE")"

set +e
bash "$ROOT_DIR/tests/run-all.sh" >"$LOG_FILE" 2>&1
command_rc=$?
set -e

echo "LOG_FILE=$LOG_FILE"
echo "EXIT_CODE=$command_rc"
echo "TAIL_LINES=$TAIL_LINES"
echo "--- LOG TAIL START ---"
tail -n "$TAIL_LINES" "$LOG_FILE"
echo "--- LOG TAIL END ---"

exit "$command_rc"