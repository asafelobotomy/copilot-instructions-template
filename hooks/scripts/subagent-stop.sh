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

# Extract agent type from VS Code SubagentStop payload (field: agent_type)
AGENT_NAME=$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('agent_type','unknown'))" 2>/dev/null) || AGENT_NAME="unknown"
[[ -z "$AGENT_NAME" ]] && AGENT_NAME="unknown"

# Build summary context
CONTEXT="${AGENT_NAME} done. Review next step."

# JSON-escape the context
CONTEXT_ESC=$(json_escape "$CONTEXT")

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStop",
    "additionalContext": "${CONTEXT_ESC}"
  }
}
EOF
