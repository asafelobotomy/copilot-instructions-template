#!/usr/bin/env bash
# purpose:  Add governance context when a subagent starts
# when:     SubagentStart
# inputs:   JSON via stdin with subagent details (agent_type, agent_id)
# outputs:  JSON with additionalContext
# risk:     safe
# ESCALATION: none
set -euo pipefail

# shellcheck source=hooks/scripts/lib-hooks.sh
source "$(dirname "$0")/lib-hooks.sh"

INPUT=$(cat)

# Extract agent type from VS Code SubagentStart payload (field: agent_type)
AGENT_NAME=$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('agent_type','unknown'))" 2>/dev/null) || AGENT_NAME="unknown"
[[ -z "$AGENT_NAME" ]] && AGENT_NAME="unknown"

# Build governance context; spatial status is via the extension tool
CONTEXT="Depth≤3. PDCA, Tool, Skill. Agent: ${AGENT_NAME}. Use asafelobotomy_spatial_status for context."

# JSON-escape the context
CONTEXT_ESC=$(json_escape "$CONTEXT")

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStart",
    "additionalContext": "${CONTEXT_ESC}"
  }
}
EOF
