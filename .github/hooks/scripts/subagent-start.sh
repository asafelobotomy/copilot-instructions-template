#!/usr/bin/env bash
# purpose:  Add governance context when a subagent starts
# when:     SubagentStart
# inputs:   JSON via stdin with subagent details (agent_type, agent_id)
# outputs:  JSON with hookSpecificOutput.additionalContext
# risk:     safe
# ESCALATION: none
set -euo pipefail

# shellcheck source=hooks/scripts/lib-hooks.sh
source "$(dirname "$0")/lib-hooks.sh"

INPUT=$(cat)

AGENT_NAME=$(json_field "$INPUT" "agent_type" "unknown")
[[ -z "$AGENT_NAME" ]] && AGENT_NAME="unknown"
CONTEXT_ESC=$(json_escape "Depth≤3. PDCA, Tool, Skill. Agent: ${AGENT_NAME}.")

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStart",
    "additionalContext": "${CONTEXT_ESC}"
  }
}
EOF
