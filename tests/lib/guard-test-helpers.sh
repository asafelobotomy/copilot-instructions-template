#!/usr/bin/env bash
# tests/lib/guard-test-helpers.sh — Guard-destructive-specific test helpers.
# Source this file in tests that exercise guard-destructive.sh or guard-destructive.ps1.
# Requires GUARD_SCRIPT to be set to the guard script path before using run_guard / assert_guard_*.
#
# Usage:
#   source "$(dirname "$0")/../lib/guard-test-helpers.sh"

# ── Guard-destructive test helpers ─────────────────────────────────────────────
# Require GUARD_SCRIPT to be set before calling.

make_guard_input() {
  local tool_name="$1" command="$2"
  printf '{"tool_name": "%s", "tool_input": {"command": "%s"}}' "$tool_name" "$command"
}

make_guard_input_with_agent() {
  local tool_name="$1" command="$2" agent_name="$3"
  printf '{"tool_name": "%s", "tool_input": {"command": "%s"}, "agentName": "%s"}' "$tool_name" "$command" "$agent_name"
}

run_guard() {
  echo "$1" | bash "${GUARD_SCRIPT:?GUARD_SCRIPT must be set}" 2>/dev/null
}

assert_guard_decision() {
  local desc="$1" input="$2" expected_decision="$3"
  local output
  output=$(run_guard "$input")
  if grep -q "\"permissionDecision\": \"$expected_decision\"" <<< "$output"; then
    pass_note "$desc"
  else
    fail_note "$desc" "     expected permissionDecision=$expected_decision
     got: $output"
  fi
}

assert_guard_continue() {
  local desc="$1" input="$2"
  local output
  output=$(run_guard "$input")
  assert_matches "$desc" "$output" '"continue": true'
}