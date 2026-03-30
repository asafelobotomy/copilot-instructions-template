#!/usr/bin/env bash
# purpose:  Remind the agent to run the retrospective before stopping
# when:     Stop hook — fires when the agent session ends
# inputs:   JSON via stdin with stop_hook_active flag
# outputs:  JSON that can block stopping if retrospective was not run
# risk:     safe
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -f "$SCRIPT_DIR/pulse.sh" ]]; then
  printf '%s' "$INPUT" | bash "$SCRIPT_DIR/pulse.sh" --trigger stop
  exit 0
fi

echo '{"continue": true}'
