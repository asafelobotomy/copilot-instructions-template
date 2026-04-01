#!/usr/bin/env bash
# tests/hooks/test-hook-pulse.sh -- unit tests for template/hooks/scripts/pulse.sh
# Run: bash tests/hooks/test-hook-pulse.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
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
assert_matches "session_start includes UTC timestamp" "$output" 'Session started at [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
assert_matches "sentinel contains session id" "$(cat "$TMPDIR_START/.copilot/workspace/.heartbeat-session" 2>/dev/null)" 'sess-1'
assert_matches "sentinel starts pending" "$(cat "$TMPDIR_START/.copilot/workspace/.heartbeat-session" 2>/dev/null)" 'pending'
assert_python_in_root "state written with pending session" "$TMPDIR_START" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["session_state"] == "pending"
assert state["session_id"] == "sess-1"
assert state["retrospective_state"] == "idle"
'
assert_python_in_root "session_start event records UTC timestamp" "$TMPDIR_START" '
events = (root / ".copilot/workspace/.heartbeat-events.jsonl").read_text(encoding="utf-8").splitlines()
event = json.loads(events[0])
assert event["trigger"] == "session_start"
assert event["ts_utc"].endswith("Z")
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

echo "3. stop trigger continues for small tasks"
TMPDIR_SMALL=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_SMALL")
mkdir -p "$TMPDIR_SMALL/.copilot/workspace"
run_pulse "$TMPDIR_SMALL" session_start '{"sessionId":"sess-3"}' >/dev/null
output=$(run_pulse "$TMPDIR_SMALL" stop '{"stop_hook_active": false}')
assert_matches "small stop continues" "$output" '"continue": true'
assert_python_in_root "small stop records retrospective not-needed" "$TMPDIR_SMALL" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "4. stop trigger skips retrospective for borderline file churn"
TMPDIR_BORDERLINE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_BORDERLINE")
printf '.copilot/\n' >> "$TMPDIR_BORDERLINE/.git/info/exclude"
mkdir -p "$TMPDIR_BORDERLINE/.copilot/workspace"
run_pulse "$TMPDIR_BORDERLINE" session_start '{"sessionId":"sess-4"}' >/dev/null
for i in 1 2 3 4 5; do
  printf 'change %s\n' "$i" > "$TMPDIR_BORDERLINE/file-$i.txt"
done
output=$(run_pulse "$TMPDIR_BORDERLINE" stop '{"stop_hook_active": false}')
assert_matches "borderline stop continues" "$output" '"continue": true'
assert_python_in_root "borderline stop records retrospective not-needed" "$TMPDIR_BORDERLINE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "5. stop trigger asks before retrospective on strong signals"
TMPDIR_BLOCK=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_BLOCK")
printf '.copilot/\n' >> "$TMPDIR_BLOCK/.git/info/exclude"
mkdir -p "$TMPDIR_BLOCK/.copilot/workspace"
run_pulse "$TMPDIR_BLOCK" session_start '{"sessionId":"sess-5"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_BLOCK/file-$i.txt"
done
output=$(run_pulse "$TMPDIR_BLOCK" stop '{"stop_hook_active": false}')
assert_matches "large stop blocks" "$output" '"decision": "block"'
assert_matches "large stop asks user question" "$output" 'would you like me to run a retrospective'
assert_python_in_root "large stop records retrospective suggested" "$TMPDIR_BLOCK" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "suggested"
'
echo ""

echo "6. user can decline a suggested retrospective"
output=$(run_pulse "$TMPDIR_BLOCK" user_prompt '{"prompt":"No thanks"}')
assert_matches "decline response continues" "$output" '"continue": true'
assert_python_in_root "decline updates retrospective state" "$TMPDIR_BLOCK" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "declined"
'
output=$(run_pulse "$TMPDIR_BLOCK" stop '{"stop_hook_active": false}')
assert_matches "declined stop continues" "$output" '"continue": true'
echo ""

echo "7. user can accept a suggested retrospective"
TMPDIR_ACCEPT=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_ACCEPT")
printf '.copilot/\n' >> "$TMPDIR_ACCEPT/.git/info/exclude"
mkdir -p "$TMPDIR_ACCEPT/.copilot/workspace"
run_pulse "$TMPDIR_ACCEPT" session_start '{"sessionId":"sess-7"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_ACCEPT/accept-file-$i.txt"
done
run_pulse "$TMPDIR_ACCEPT" stop '{"stop_hook_active": false}' >/dev/null
output=$(run_pulse "$TMPDIR_ACCEPT" user_prompt '{"prompt":"Yes please"}')
assert_matches "accept response continues" "$output" '"continue": true'
assert_python_in_root "accept updates retrospective state" "$TMPDIR_ACCEPT" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "accepted"
'
output=$(run_pulse "$TMPDIR_ACCEPT" stop '{"stop_hook_active": false}')
assert_matches "accepted stop blocks for retrospective" "$output" '"decision": "block"'
assert_matches "accepted stop explains retrospective run" "$output" 'The user agreed to a retrospective'
echo ""

echo "8. stop trigger passes when retrospective is complete"
TMPDIR_PASS=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_PASS")
mkdir -p "$TMPDIR_PASS/.copilot/workspace"
run_pulse "$TMPDIR_PASS" session_start '{"sessionId":"sess-8"}' >/dev/null
printf 'sess-8|2026-03-30T00:00:00Z|complete\n' > "$TMPDIR_PASS/.copilot/workspace/.heartbeat-session"
output=$(run_pulse "$TMPDIR_PASS" stop '{"stop_hook_active": false}')
assert_matches "stop continues when complete" "$output" '"continue": true'
assert_python_in_root "state transitions to complete" "$TMPDIR_PASS" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["session_state"] == "complete"
assert state["retrospective_state"] == "complete"
'
assert_python_in_root "stop completion event records duration and UTC timestamp" "$TMPDIR_PASS" '
events = [json.loads(line) for line in (root / ".copilot/workspace/.heartbeat-events.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
event = events[-1]
assert event["trigger"] == "stop"
assert event["detail"] == "complete"
assert isinstance(event["duration_s"], int)
assert event["duration_s"] >= 0
assert event["ts_utc"].endswith("Z")
'
echo ""

echo "9. user_prompt heartbeat keyword emits system message"
TMPDIR_PROMPT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_PROMPT")
mkdir -p "$TMPDIR_PROMPT/.copilot/workspace"
output=$(run_pulse "$TMPDIR_PROMPT" user_prompt '{"prompt":"Can you check your heartbeat now?"}')
assert_matches "keyword prompt includes guidance" "$output" 'Heartbeat trigger detected'
echo ""

echo "10. corrupt state file is recovered safely"
TMPDIR_CORRUPT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_CORRUPT")
mkdir -p "$TMPDIR_CORRUPT/.copilot/workspace"
printf '{broken-json\n' > "$TMPDIR_CORRUPT/.copilot/workspace/state.json"
output=$(run_pulse "$TMPDIR_CORRUPT" session_start '{"sessionId":"sess-8"}')
assert_valid_json "session_start still returns valid JSON" "$output"
assert_python_in_root "state file becomes valid JSON" "$TMPDIR_CORRUPT" '
import json
json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
'

finish_tests