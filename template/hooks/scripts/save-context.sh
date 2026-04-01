#!/usr/bin/env bash
# purpose:  Save critical workspace context before conversation compaction
# when:     PreCompact hook — fires when context is about to be truncated
# inputs:   JSON via stdin with trigger field
# outputs:  JSON with additionalContext summarising saved state
# risk:     safe
set -euo pipefail

# shellcheck source=.github/hooks/scripts/lib-hooks.sh
source "$(dirname "$0")/lib-hooks.sh"

clock_summary() {
  local script_dir
  command -v python3 >/dev/null 2>&1 || return 0
  [[ -f .copilot/workspace/state.json || -f .copilot/workspace/.heartbeat-events.jsonl ]] || return 0

  script_dir="$(cd "$(dirname "$0")" && pwd)"
  python3 "$script_dir/heartbeat_clock_summary.py" 2>/dev/null || true
}

# Read workspace files and create a compact summary to survive compaction
SUMMARY=""

# Heartbeat pulse
if [[ -f .copilot/workspace/HEARTBEAT.md ]]; then
  PULSE=$(grep -m1 'HEARTBEAT' .copilot/workspace/HEARTBEAT.md 2>/dev/null || echo "unknown")
  SUMMARY="${SUMMARY}Heartbeat: ${PULSE}. "
fi

CLOCK_SUMMARY=$(clock_summary 2>/dev/null || echo "")
if [[ -n "$CLOCK_SUMMARY" ]]; then
  SUMMARY="${SUMMARY}Clock: ${CLOCK_SUMMARY}. "
fi

# Recent MEMORY.md entries
if [[ -f .copilot/workspace/MEMORY.md ]]; then
  RECENT_MEMORY=$(tail -20 .copilot/workspace/MEMORY.md 2>/dev/null | head -c 500 || echo "")
  if [[ -n "$RECENT_MEMORY" ]]; then
    SUMMARY="${SUMMARY}Recent memory: ${RECENT_MEMORY}. "
  fi
fi

# Current SOUL.md heuristics
if [[ -f .copilot/workspace/SOUL.md ]]; then
  HEURISTICS=$(grep -A1 'heuristic\|principle\|rule\|pattern' .copilot/workspace/SOUL.md 2>/dev/null | head -c 300 || echo "")
  if [[ -n "$HEURISTICS" ]]; then
    SUMMARY="${SUMMARY}Key heuristics: ${HEURISTICS}. "
  fi
fi

# Git status snapshot
GIT_STATUS=$(git status --porcelain 2>/dev/null | head -10 || echo "")
if [[ -n "$GIT_STATUS" ]]; then
  MODIFIED_COUNT=$(echo "$GIT_STATUS" | wc -l | tr -d ' ')
  SUMMARY="${SUMMARY}Git: ${MODIFIED_COUNT} modified files. "
fi

# Truncate to a safe length
SUMMARY=$(echo "$SUMMARY" | head -c 2000)

if [[ -n "$SUMMARY" ]]; then
  # Escape for JSON
  SUMMARY_ESCAPED=$(json_escape "$SUMMARY")

  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "additionalContext": "Pre-compaction workspace snapshot: ${SUMMARY_ESCAPED}"
  }
}
EOF
else
  echo '{"continue": true}'
fi
