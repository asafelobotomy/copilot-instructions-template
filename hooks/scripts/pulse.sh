#!/usr/bin/env bash
# purpose:  Run heartbeat state and retrospective gating.
# when:     Invoked by lifecycle hooks.
# inputs:   JSON on stdin + --trigger <session_start|pre_tool|soft_post_tool|compaction|stop|user_prompt|explicit>.
# outputs:  JSON hook response.
# risk:     safe
# source:   original
# ESCALATION: none
# STOP LOOP: if stop_hook_active is true, do not re-enter blocking Stop logic.
set -euo pipefail

TRIGGER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --trigger)
      TRIGGER="${2:-}"
      shift 2
      ;;
    *)
      echo '{"continue": true}'
      exit 0
      ;;
  esac
done

if [[ -z "$TRIGGER" ]]; then
  echo '{"continue": true}'
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT=$(cat)

# Resolve Python executable (mirror pulse.ps1 fallback logic)
PYTHON_CMD=""
if command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_CMD="python"
fi

if [[ -z "$PYTHON_CMD" ]]; then
  echo '{"continue":true,"hookSpecificOutput":{"additionalContext":"Pulse: python missing; heartbeat skipped."}}'
  exit 0
fi

RUNTIME_SCRIPT="$SCRIPT_DIR/pulse_runtime.py"
if [[ ! -f "$RUNTIME_SCRIPT" ]]; then
  echo '{"continue":true,"hookSpecificOutput":{"additionalContext":"Pulse: pulse_runtime.py missing; heartbeat skipped."}}'
  exit 0
fi

printf '%s' "$INPUT" | "$PYTHON_CMD" "$RUNTIME_SCRIPT" "$TRIGGER"