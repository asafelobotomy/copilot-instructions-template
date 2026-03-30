#!/usr/bin/env bash
# tests/test-hook-pulse.sh -- unit tests for template/hooks/scripts/pulse.sh
# Run: bash tests/test-hook-pulse.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/template/hooks/scripts/pulse.sh"
trap cleanup_dirs EXIT

run_pulse() {
  local dir="$1" trigger="$2" payload="$3"
  (
    cd "$dir" || exit 1
    printf '%s' "$payload" | bash "$SCRIPT" --trigger "$trigger"
  )
}

echo "=== pulse.sh ==="
echo ""

echo "1. session_start initializes sentinel and state"
TMPDIR_START=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_START")
mkdir -p "$TMPDIR_START/.copilot/workspace"
output=$(run_pulse "$TMPDIR_START" session_start '{"sessionId":"sess-1"}')
assert_valid_json "session_start output is valid JSON" "$output"
assert_matches "session_start continues" "$output" '"continue": true'
assert_matches "sentinel contains session id" "$(cat "$TMPDIR_START/.copilot/workspace/.heartbeat-session" 2>/dev/null)" 'sess-1'
assert_matches "sentinel starts pending" "$(cat "$TMPDIR_START/.copilot/workspace/.heartbeat-session" 2>/dev/null)" 'pending'
assert_python_in_root "state written with pending session" "$TMPDIR_START" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["session_state"] == "pending"
assert state["session_id"] == "sess-1"
'
echo ""

echo "2. soft_post_tool trigger is debounced"
TMPDIR_DEB=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_DEB")
mkdir -p "$TMPDIR_DEB/.copilot/workspace"
run_pulse "$TMPDIR_DEB" session_start '{"sessionId":"sess-2"}' >/dev/null
run_pulse "$TMPDIR_DEB" soft_post_tool '{}' >/dev/null
first_epoch=$(python3 - <<PY
import json
from pathlib import Path
state = json.loads(Path("$TMPDIR_DEB/.copilot/workspace/state.json").read_text(encoding="utf-8"))
print(state.get("last_soft_trigger_epoch", 0))
PY
)
run_pulse "$TMPDIR_DEB" soft_post_tool '{}' >/dev/null
second_epoch=$(python3 - <<PY
import json
from pathlib import Path
state = json.loads(Path("$TMPDIR_DEB/.copilot/workspace/state.json").read_text(encoding="utf-8"))
print(state.get("last_soft_trigger_epoch", 0))
PY
)
if [[ "$first_epoch" == "$second_epoch" ]]; then
  pass_note "debounced soft trigger keeps same epoch"
else
  fail_note "debounced soft trigger keeps same epoch" "     first=$first_epoch second=$second_epoch"
fi
echo ""

echo "3. stop trigger blocks when retrospective is incomplete"
TMPDIR_BLOCK=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_BLOCK")
mkdir -p "$TMPDIR_BLOCK/.copilot/workspace"
run_pulse "$TMPDIR_BLOCK" session_start '{"sessionId":"sess-3"}' >/dev/null
output=$(run_pulse "$TMPDIR_BLOCK" stop '{"stop_hook_active": false}')
assert_matches "stop blocks when pending" "$output" '"decision": "block"'
echo ""

echo "4. stop trigger passes when sentinel is complete"
TMPDIR_PASS=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_PASS")
mkdir -p "$TMPDIR_PASS/.copilot/workspace"
run_pulse "$TMPDIR_PASS" session_start '{"sessionId":"sess-4"}' >/dev/null
printf 'sess-4|2026-03-30T00:00:00Z|complete\n' > "$TMPDIR_PASS/.copilot/workspace/.heartbeat-session"
output=$(run_pulse "$TMPDIR_PASS" stop '{"stop_hook_active": false}')
assert_matches "stop continues when complete" "$output" '"continue": true'
assert_python_in_root "state transitions to complete" "$TMPDIR_PASS" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["session_state"] == "complete"
'
echo ""

echo "5. user_prompt heartbeat keyword emits system message"
TMPDIR_PROMPT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_PROMPT")
mkdir -p "$TMPDIR_PROMPT/.copilot/workspace"
output=$(run_pulse "$TMPDIR_PROMPT" user_prompt '{"prompt":"Can you check your heartbeat now?"}')
assert_matches "keyword prompt includes guidance" "$output" 'Heartbeat trigger detected'
echo ""

echo "6. corrupt state file is recovered safely"
TMPDIR_CORRUPT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_CORRUPT")
mkdir -p "$TMPDIR_CORRUPT/.copilot/workspace"
printf '{broken-json\n' > "$TMPDIR_CORRUPT/.copilot/workspace/state.json"
output=$(run_pulse "$TMPDIR_CORRUPT" session_start '{"sessionId":"sess-6"}')
assert_valid_json "session_start still returns valid JSON" "$output"
assert_python_in_root "state file becomes valid JSON" "$TMPDIR_CORRUPT" '
import json
json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
'

finish_tests