#!/usr/bin/env bash
# purpose:  Mark subagent completion
# when:     SubagentStop
# inputs:   JSON via stdin with subagent details (agent_type, agent_id, stop_hook_active)
# outputs:  JSON with additionalContext
# risk:     safe
# ESCALATION: none
set -euo pipefail

# shellcheck source=hooks/scripts/lib-hooks.sh
source "$(dirname "$0")/lib-hooks.sh"

INPUT=$(cat)

AGENT_NAME=$(json_field "$INPUT" "agent_type" "unknown")
[[ -z "$AGENT_NAME" ]] && AGENT_NAME="unknown"
CONTEXT_ESC=$(json_escape "${AGENT_NAME} done. Review next step.")

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStop",
    "additionalContext": "${CONTEXT_ESC}"
  }
}
EOF
