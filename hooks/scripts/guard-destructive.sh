#!/usr/bin/env bash
# purpose:  Block dangerous terminal commands before execution
# when:     PreToolUse hook — fires before the agent invokes any tool
# inputs:   JSON via stdin with tool_name and tool_input
# outputs:  JSON with permissionDecision (allow/deny/ask)
# risk:     safe
# ESCALATION: ask
#
# This hook is complementary to VS Code's built-in terminal auto-approval
# (github.copilot.chat.agent.terminal.allowList / denyList). This hook runs
# at the PreToolUse level (before command dispatch); auto-approval runs at
# the terminal level (after dispatch, before execution). Use both for
# defense-in-depth.
set -euo pipefail

# shellcheck source=hooks/scripts/lib-hooks.sh
source "$(dirname "$0")/lib-hooks.sh"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\(.*\)"/\1/') || TOOL_NAME=""
TOOL_NAME_LOWER=${TOOL_NAME,,}
TOOL_NAME_CANON=$(printf '%s' "$TOOL_NAME_LOWER" | tr -d '_-')

# Only guard terminal/command tools plus create_and_run_task, which nests its
# executable command under tool_input.task.command.
if [[ "$TOOL_NAME" != *"terminal"* && "$TOOL_NAME" != *"command"* && "$TOOL_NAME" != *"bash"* && "$TOOL_NAME" != *"shell"* && "$TOOL_NAME_CANON" != "createandruntask" ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Read-only terminal observer tools do not execute commands and therefore
# legitimately omit tool_input.command.
if [[ "$TOOL_NAME_CANON" == "getterminaloutput" || "$TOOL_NAME_CANON" == "terminallastcommand" || "$TOOL_NAME_CANON" == "terminalselection" || "$TOOL_NAME_CANON" == "killterminal" ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Read-only terminal observation tools — never execute commands, always allow
# get_terminal_output / getTerminalOutput only reads stdout from an existing session
# run_vscode_command / vscode_run_command invokes VS Code UI commands, not shell commands
case "${TOOL_NAME,,}" in
  *get_terminal_output*|*getterminaloutput*|*terminal_last_command*|*terminalselection*|\
  *run_vscode_command*|*vscode_run_command*)
    echo '{"continue": true}'
    exit 0
    ;;
esac

# python3 is required to parse tool_input JSON reliably.
# Without it, TOOL_INPUT would be empty and all patterns would pass unchecked.
if ! command -v python3 >/dev/null 2>&1; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "python3 missing — cannot parse command. Manual confirmation."
  }
}
EOF
  exit 0
fi

TOOL_INPUT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    ti = data.get('tool_input', {})
    command = ti.get('command', '')
    tool_name = str(data.get('tool_name', '') or '').lower().replace('_', '').replace('-', '')
    if tool_name == 'createandruntask':
      task = ti.get('task', {}) if isinstance(ti, dict) else {}
      task_command = task.get('command', '') if isinstance(task, dict) else ''
      task_args = task.get('args', []) if isinstance(task, dict) else []
      if isinstance(task_command, str):
        parts = [task_command]
        if isinstance(task_args, list):
          parts.extend(arg for arg in task_args if isinstance(arg, str))
        command = ' '.join(part for part in parts if part)
    print(command if isinstance(command, str) else '')
except Exception:
    print('')
" 2>/dev/null || echo "")

if [[ -z "$TOOL_INPUT" ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Missing tool_input.command. Manual confirmation."
  }
}
EOF
  exit 0
fi

AGENT_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
  data = json.load(sys.stdin)
  candidates = [
    data.get('agent_name'),
    data.get('agentName'),
    (data.get('context') or {}).get('agentName'),
    (data.get('context') or {}).get('agent_name'),
    (data.get('session') or {}).get('agentName'),
    (data.get('session') or {}).get('agent_name'),
  ]
  for value in candidates:
    if isinstance(value, str) and value.strip():
      print(value.strip())
      break
  else:
    print('')
except Exception:
  print('')
" 2>/dev/null || echo "")

# Blocked patterns — dangerous commands that should never auto-execute
BLOCKED_PATTERNS=(
  'rm -rf /([^a-zA-Z0-9._-]|$)'
  'rm -rf ~([^a-zA-Z0-9._/-]|$)'
  'rm -rf \.([[:space:]]|$)'
  'DROP TABLE'
  'DROP DATABASE'
  'TRUNCATE TABLE'
  'DELETE FROM .* WHERE 1'
  'mkfs\.'
  'dd if=.* of=/dev/'
  ':\(\)\{:[|]:&\};:'
  'chmod -R 777 /([^a-zA-Z0-9._-]|$)'
  'curl .*[|].*sh'
  'wget .*[|].*sh'
)

# Allow pure read-only pattern searches so investigations can inspect the guard
# definitions without tripping on the blocked regex literals themselves.
is_readonly_pattern_search() {
  local command_text="$1"
  local lowered_command="$1"

  lowered_command=${lowered_command,,}

  if [[ ! "$command_text" =~ ^[[:space:]]*(rg|grep|findstr)($|[[:space:]]) && ! "$command_text" =~ ^[[:space:]]*git[[:space:]]+grep($|[[:space:]]) ]]; then
    return 1
  fi

  if [[ "$command_text" == *'&&'* || "$command_text" == *'||'* || "$command_text" == *';'* || "$command_text" == *'$('* || "$command_text" == *'`'* || "$command_text" == *'<'* || "$command_text" == *'>'* || "$command_text" == *' | '* ]]; then
    return 1
  fi

  local pattern
  for pattern in "${BLOCKED_PATTERNS[@]}"; do
    if [[ "$lowered_command" == *"${pattern,,}"* ]]; then
      return 0
    fi
  done

  return 1
}

if is_readonly_pattern_search "$TOOL_INPUT"; then
  echo '{"continue": true}'
  exit 0
fi

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$TOOL_INPUT" | grep -qiE "$pattern"; then
    PATTERN_ESC=$(json_escape "$pattern")
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked: destructive pattern '${PATTERN_ESC}'"
  }
}
EOF
    exit 0
  fi
done

# Caution patterns — require user confirmation
CAUTION_PATTERNS=(
  'rm -rf'
  'rm -r '
  'chmod -R 777'
  'DROP '
  'DELETE FROM'
  'git push.*--force'
  'git reset --hard'
  'git clean -fd'
  'npm publish'
  'cargo publish'
  'pip install --'
)

for pattern in "${CAUTION_PATTERNS[@]}"; do
  if echo "$TOOL_INPUT" | grep -qiE "$pattern"; then
    PATTERN_ESC=$(json_escape "$pattern")
    COMMAND_ESC=$(json_escape "$(echo "$TOOL_INPUT" | head -c 200)")
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Caution pattern '${PATTERN_ESC}' matched. Confirm to proceed.",
    "additionalContext": "Command: '${COMMAND_ESC}'"
  }
}
EOF
    exit 0
  fi
done

# Read-only agent guardrails — Audit, Review, and Explore should not perform
# mutating terminal operations without explicit user approval.
if [[ "$AGENT_NAME" =~ ^(Audit|Review|Explore)$ ]]; then
  READONLY_WRITE_PATTERNS=(
    '(^|[;&|][[:space:]]*)(mkdir|touch|cp|mv|truncate|install)[[:space:]]'
    '(^|[;&|][[:space:]]*)(sed[[:space:]]+-i|perl[[:space:]]+-i|tee[[:space:]])'
    '(^|[;&|][[:space:]]*)(echo|printf).*>+'
    '(^|[;&|][[:space:]]*)(git[[:space:]]+(add|commit|push|reset|checkout|switch|merge|rebase|cherry-pick|revert|tag|stash))'
    '(^|[;&|][[:space:]]*)((npm|pnpm|yarn|bun)[[:space:]]+(install|add|remove|update|upgrade|publish))'
    '(^|[;&|][[:space:]]*)(pip|uv[[:space:]]+pip)[[:space:]]+install'
  )

  for pattern in "${READONLY_WRITE_PATTERNS[@]}"; do
    if echo "$TOOL_INPUT" | grep -qiE "$pattern"; then
      AGENT_ESC=$(json_escape "$AGENT_NAME")
      COMMAND_ESC=$(json_escape "$(echo "$TOOL_INPUT" | head -c 200)")
      cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "${AGENT_ESC} is read-only. Mutations need confirmation.",
    "additionalContext": "Command '${COMMAND_ESC}' mutates state. Use Code agent or confirm."
  }
}
EOF
      exit 0
    fi
  done
fi

# Safe — allow execution
echo '{"continue": true}'
