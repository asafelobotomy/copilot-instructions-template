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

echo "5. stop trigger blocks with reflect instruction on strong signals"
TMPDIR_BLOCK=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_BLOCK")
printf '.copilot/\n' >> "$TMPDIR_BLOCK/.git/info/exclude"
mkdir -p "$TMPDIR_BLOCK/.copilot/workspace"
run_pulse "$TMPDIR_BLOCK" session_start '{"sessionId":"sess-5"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_BLOCK/file-$i.txt"
done
output=$(run_pulse "$TMPDIR_BLOCK" stop '{"stop_hook_active": false}')
assert_matches "large stop blocks" "$output" '"decision": "block"'
assert_matches "large stop instructs model to call session_reflect" "$output" 'session_reflect'
assert_python_in_root "large stop records retrospective suggested" "$TMPDIR_BLOCK" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "suggested"
'
echo ""

echo "6. stop passes when sentinel complete after reflect"
printf 'sess-5|2026-04-01T00:00:00Z|complete\n' > "$TMPDIR_BLOCK/.copilot/workspace/.heartbeat-session"
output=$(run_pulse "$TMPDIR_BLOCK" stop '{"stop_hook_active": false}')
assert_matches "sentinel-complete stop continues" "$output" '"continue": true'
assert_python_in_root "sentinel-complete updates state to complete" "$TMPDIR_BLOCK" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "complete"
assert state["session_state"] == "complete"
'
echo ""

echo "7. transcript mentions alone do not satisfy retrospective completion"
TMPDIR_TRANSCRIPT=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_TRANSCRIPT")
printf '.copilot/\n' >> "$TMPDIR_TRANSCRIPT/.git/info/exclude"
mkdir -p "$TMPDIR_TRANSCRIPT/.copilot/workspace"
run_pulse "$TMPDIR_TRANSCRIPT" session_start '{"sessionId":"sess-transcript"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_TRANSCRIPT/file-$i.txt"
done
printf 'Significant session detected. Call the session_reflect MCP tool now.\n' > "$TMPDIR_TRANSCRIPT/transcript.txt"
output=$(run_pulse "$TMPDIR_TRANSCRIPT" stop '{"stop_hook_active": false, "transcript_path":"transcript.txt"}')
assert_matches "transcript mention still blocks" "$output" '"decision": "block"'
assert_python_in_root "transcript mention keeps retrospective suggested" "$TMPDIR_TRANSCRIPT" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "suggested"
'
echo ""

echo "8. reflection completion event passes stop without a sentinel"
TMPDIR_EVENT=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_EVENT")
printf '.copilot/\n' >> "$TMPDIR_EVENT/.git/info/exclude"
mkdir -p "$TMPDIR_EVENT/.copilot/workspace"
run_pulse "$TMPDIR_EVENT" session_start '{"sessionId":"sess-event"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_EVENT/file-$i.txt"
done
rm -f "$TMPDIR_EVENT/.copilot/workspace/.heartbeat-session"
cat >> "$TMPDIR_EVENT/.copilot/workspace/.heartbeat-events.jsonl" <<'EOF'
{"detail":"complete","session_id":"sess-event","trigger":"session_reflect","ts":1704068400,"ts_utc":"2024-01-01T00:20:00Z"}
EOF
output=$(run_pulse "$TMPDIR_EVENT" stop '{"stop_hook_active": false}')
assert_matches "completion event without sentinel continues" "$output" '"continue": true'
assert_python_in_root "completion event updates state to complete" "$TMPDIR_EVENT" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "complete"
assert state["session_state"] == "complete"
'
echo ""

echo "9. reflection completion events from other sessions do not pass stop"
TMPDIR_EVENT_OTHER=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_EVENT_OTHER")
printf '.copilot/\n' >> "$TMPDIR_EVENT_OTHER/.git/info/exclude"
mkdir -p "$TMPDIR_EVENT_OTHER/.copilot/workspace"
run_pulse "$TMPDIR_EVENT_OTHER" session_start '{"sessionId":"sess-event-other"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_EVENT_OTHER/file-$i.txt"
done
rm -f "$TMPDIR_EVENT_OTHER/.copilot/workspace/.heartbeat-session"
cat >> "$TMPDIR_EVENT_OTHER/.copilot/workspace/.heartbeat-events.jsonl" <<'EOF'
{"detail":"complete","session_id":"different-session","trigger":"session_reflect","ts":1704068400,"ts_utc":"2024-01-01T00:20:00Z"}
EOF
output=$(run_pulse "$TMPDIR_EVENT_OTHER" stop '{"stop_hook_active": false}')
assert_matches "other-session completion event still blocks" "$output" '"decision": "block"'
echo ""

echo "10. user accepting retrospective keyword blocks at stop"
TMPDIR_ACCEPT=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_ACCEPT")
printf '.copilot/\n' >> "$TMPDIR_ACCEPT/.git/info/exclude"
mkdir -p "$TMPDIR_ACCEPT/.copilot/workspace"
run_pulse "$TMPDIR_ACCEPT" session_start '{"sessionId":"sess-7"}' >/dev/null
output=$(run_pulse "$TMPDIR_ACCEPT" user_prompt '{"prompt":"Run a retrospective please"}')
assert_matches "retrospective keyword continues" "$output" '"continue": true'
output=$(run_pulse "$TMPDIR_ACCEPT" stop '{"stop_hook_active": false}')
assert_matches "accepted stop blocks for retrospective" "$output" '"decision": "block"'
assert_matches "accepted stop explains retrospective run" "$output" 'session_reflect'
echo ""

echo "11. stop trigger passes when retrospective is complete"
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

echo "12. user_prompt heartbeat keyword emits system message"
TMPDIR_PROMPT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_PROMPT")
mkdir -p "$TMPDIR_PROMPT/.copilot/workspace"
output=$(run_pulse "$TMPDIR_PROMPT" user_prompt '{"prompt":"Can you check your heartbeat now?"}')
assert_matches "keyword prompt includes guidance" "$output" 'Heartbeat trigger detected'
echo ""

echo "13. policy discussion prompts do not arm heartbeat or retrospective"
TMPDIR_TOPIC=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_TOPIC")
mkdir -p "$TMPDIR_TOPIC/.copilot/workspace"
run_pulse "$TMPDIR_TOPIC" session_start '{"sessionId":"sess-topic"}' >/dev/null
output=$(run_pulse "$TMPDIR_TOPIC" user_prompt '{"prompt":"Let us review heartbeat and retrospective thresholds"}')
assert_valid_json "discussion-only prompt returns valid JSON" "$output"
if echo "$output" | grep -q 'systemMessage'; then
  fail_note "discussion-only prompt stays quiet" "     unexpected systemMessage in output: $output"
else
  pass_note "discussion-only prompt stays quiet"
fi
output=$(run_pulse "$TMPDIR_TOPIC" stop '{"stop_hook_active": false}')
assert_matches "discussion-only stop continues" "$output" '"continue": true'
assert_python_in_root "discussion-only prompt keeps retrospective idle" "$TMPDIR_TOPIC" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "14. explanation prompts stay informational"
TMPDIR_EXPLAIN=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_EXPLAIN")
mkdir -p "$TMPDIR_EXPLAIN/.copilot/workspace"
run_pulse "$TMPDIR_EXPLAIN" session_start '{"sessionId":"sess-explain"}' >/dev/null
output=$(run_pulse "$TMPDIR_EXPLAIN" user_prompt '{"prompt":"Could you explain the retrospective policy?"}')
assert_valid_json "retrospective policy prompt returns valid JSON" "$output"
if echo "$output" | grep -q 'systemMessage'; then
  fail_note "retrospective policy prompt stays informational" "     unexpected systemMessage in output: $output"
else
  pass_note "retrospective policy prompt stays informational"
fi
output=$(run_pulse "$TMPDIR_EXPLAIN" user_prompt '{"prompt":"Show the heartbeat policy"}')
assert_valid_json "heartbeat policy prompt returns valid JSON" "$output"
if echo "$output" | grep -q 'systemMessage'; then
  fail_note "heartbeat policy prompt stays informational" "     unexpected systemMessage in output: $output"
else
  pass_note "heartbeat policy prompt stays informational"
fi
output=$(run_pulse "$TMPDIR_EXPLAIN" stop '{"stop_hook_active": false}')
assert_matches "explanation prompts do not arm stop" "$output" '"continue": true'
echo ""

echo "15. session_start captures git baseline"
TMPDIR_BASE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_BASE")
printf '.copilot/\n' >> "$TMPDIR_BASE/.git/info/exclude"
mkdir -p "$TMPDIR_BASE/.copilot/workspace"
# Create a dirty file BEFORE session_start — should be captured as baseline.
printf 'pre-existing\n' > "$TMPDIR_BASE/pre-existing.txt"
run_pulse "$TMPDIR_BASE" session_start '{"sessionId":"sess-base"}' >/dev/null
assert_python_in_root "session_start records git baseline count" "$TMPDIR_BASE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["session_start_git_count"] >= 1
assert state["copilot_edit_count"] == 0
assert state["active_work_seconds"] == 0
assert state["task_window_start_epoch"] == 0
'
echo ""

echo "16. soft_post_tool increments edit count only for file-writing tools"
TMPDIR_EDIT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_EDIT")
mkdir -p "$TMPDIR_EDIT/.copilot/workspace"
run_pulse "$TMPDIR_EDIT" session_start '{"sessionId":"sess-11"}' >/dev/null
run_pulse "$TMPDIR_EDIT" soft_post_tool '{"tool_name":"run_in_terminal"}' >/dev/null
assert_python_in_root "non-file tool does not increment edit count" "$TMPDIR_EDIT" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["copilot_edit_count"] == 0
'
run_pulse "$TMPDIR_EDIT" soft_post_tool '{"tool_name":"create_file"}' >/dev/null
assert_python_in_root "create_file increments edit count to 1" "$TMPDIR_EDIT" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["copilot_edit_count"] == 1
'
run_pulse "$TMPDIR_EDIT" soft_post_tool '{"tool_name":"replace_string_in_file"}' >/dev/null
assert_python_in_root "replace_string_in_file increments edit count to 2" "$TMPDIR_EDIT" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["copilot_edit_count"] == 2
'
echo ""

echo "17. soft_post_tool opens and accumulates work windows"
TMPDIR_WIN=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_WIN")
mkdir -p "$TMPDIR_WIN/.copilot/workspace"
run_pulse "$TMPDIR_WIN" session_start '{"sessionId":"sess-12"}' >/dev/null
run_pulse "$TMPDIR_WIN" soft_post_tool '{"tool_name":"create_file"}' >/dev/null
assert_python_in_root "first tool use opens work window" "$TMPDIR_WIN" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["task_window_start_epoch"] > 0
assert state["last_raw_tool_epoch"] > 0
'
# Simulate an idle gap by backdating last_raw_tool_epoch > idle_gap_s (600s) ago.
python3 - <<PY
import json, time
from pathlib import Path
p = Path("$TMPDIR_WIN/.copilot/workspace/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
now = int(time.time())
state["task_window_start_epoch"] = now - 900  # 15m ago
state["last_raw_tool_epoch"] = now - 700       # 700s ago (> 600s idle gap)
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
run_pulse "$TMPDIR_WIN" soft_post_tool '{"tool_name":"replace_string_in_file"}' >/dev/null
assert_python_in_root "idle gap closes old window and accumulates time" "$TMPDIR_WIN" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
# Window from 900s-ago to 700s-ago = 200s accumulated
assert state["active_work_seconds"] >= 190
assert state["task_window_start_epoch"] > 0  # new window opened
'
echo ""

echo "18. pure planning session (0 file changes) never triggers retrospective"
TMPDIR_PLAN=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_PLAN")
printf '.copilot/\n' >> "$TMPDIR_PLAN/.git/info/exclude"
mkdir -p "$TMPDIR_PLAN/.copilot/workspace"
run_pulse "$TMPDIR_PLAN" session_start '{"sessionId":"sess-13"}' >/dev/null
# Simulate a 40-minute session with tool activity but no file changes.
python3 - <<PY
import json, time
from pathlib import Path
p = Path("$TMPDIR_PLAN/.copilot/workspace/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
now = int(time.time())
state["session_start_epoch"] = now - 2400  # 40m ago
state["active_work_seconds"] = 2100        # 35m of active tool use
state["last_raw_tool_epoch"] = now - 30
state["task_window_start_epoch"] = now - 30
state["copilot_edit_count"] = 0
# session_start_git_count and current git status are both 0 (clean sandbox)
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
output=$(run_pulse "$TMPDIR_PLAN" stop '{"stop_hook_active": false}')
assert_matches "planning-only session continues (no retro)" "$output" '"continue": true'
assert_python_in_root "planning session records not-needed" "$TMPDIR_PLAN" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "19. pre-existing dirty files do not inflate the delta count"
TMPDIR_DELTA=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_DELTA")
printf '.copilot/\n' >> "$TMPDIR_DELTA/.git/info/exclude"
mkdir -p "$TMPDIR_DELTA/.copilot/workspace"
# Create 8 dirty files BEFORE session_start.
for i in 1 2 3 4 5 6 7 8; do
  printf 'pre-existing %s\n' "$i" > "$TMPDIR_DELTA/pre-$i.txt"
done
run_pulse "$TMPDIR_DELTA" session_start '{"sessionId":"sess-14"}' >/dev/null
# No new files created — delta should be 0 even though 8 dirty files exist.
output=$(run_pulse "$TMPDIR_DELTA" stop '{"stop_hook_active": false}')
assert_matches "pre-existing dirty files do not trigger retro" "$output" '"continue": true'
assert_python_in_root "state is not-needed due to zero delta" "$TMPDIR_DELTA" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "20. corrupt state file is recovered safely"
TMPDIR_CORRUPT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_CORRUPT")
mkdir -p "$TMPDIR_CORRUPT/.copilot/workspace"
printf '{broken-json\n' > "$TMPDIR_CORRUPT/.copilot/workspace/state.json"
output=$(run_pulse "$TMPDIR_CORRUPT" session_start '{"sessionId":"sess-8"}')
assert_valid_json "session_start still returns valid JSON" "$output"
assert_python_in_root "state file becomes valid JSON" "$TMPDIR_CORRUPT" '
import json
json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
'
echo ""

echo "21. transition digest stays quiet while the session is only orienting"
TMPDIR_DIGEST_QUIET=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_DIGEST_QUIET")
mkdir -p "$TMPDIR_DIGEST_QUIET/.copilot/workspace"
run_pulse "$TMPDIR_DIGEST_QUIET" session_start '{"sessionId":"sess-17-quiet"}' >/dev/null
python3 - <<PY
import json
from pathlib import Path
p = Path("$TMPDIR_DIGEST_QUIET/.copilot/workspace/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
state["tool_call_counter"] = 14
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
output=$(run_pulse "$TMPDIR_DIGEST_QUIET" soft_post_tool '{"tool_name":"run_in_terminal"}')
assert_valid_json "orienting call output is valid JSON" "$output"
if echo "$output" | grep -q 'additionalContext'; then
  fail_note "orienting call has no additionalContext" "     unexpected additionalContext in output: $output"
else
  pass_note "orienting call has no additionalContext"
fi
assert_python_in_root "orienting call records phase without digest emission" "$TMPDIR_DIGEST_QUIET" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["tool_call_counter"] == 15
assert state["intent_phase"] == "orienting"
assert state["digest_emit_count"] == 0
'
echo ""

echo "22. transition digest appears when work crosses into consolidating"
TMPDIR_DIGEST=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_DIGEST")
mkdir -p "$TMPDIR_DIGEST/.copilot/workspace"
run_pulse "$TMPDIR_DIGEST" session_start '{"sessionId":"sess-16"}' >/dev/null
python3 - <<PY
import json
from pathlib import Path
p = Path("$TMPDIR_DIGEST/.copilot/workspace/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
state["tool_call_counter"] = 14
state["copilot_edit_count"] = 4
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
output=$(run_pulse "$TMPDIR_DIGEST" soft_post_tool '{"tool_name":"create_file","tool_input":{"filePath":"scripts/example.sh"}}')
assert_matches "consolidating call includes digest" "$output" 'additionalContext'
assert_matches "digest reports validation intent" "$output" 'Session intent: tests and validation likely next'
assert_python_in_root "consolidating call records runtime family and digest state" "$TMPDIR_DIGEST" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["tool_call_counter"] == 15, "expected 15 got %d" % state["tool_call_counter"]
assert state["intent_phase"] == "consolidating"
assert state["digest_emit_count"] == 1
assert "runtime" in state["changed_path_families"]
'
output=$(run_pulse "$TMPDIR_DIGEST" soft_post_tool '{"tool_name":"run_in_terminal"}')
assert_valid_json "follow-up consolidating call output is valid JSON" "$output"
if echo "$output" | grep -q 'additionalContext'; then
  fail_note "follow-up consolidating call has no additionalContext" "     unexpected additionalContext in output: $output"
else
  pass_note "follow-up consolidating call has no additionalContext"
fi
echo ""

echo "23. session_start initializes transition state"
TMPDIR_COUNTER=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_COUNTER")
mkdir -p "$TMPDIR_COUNTER/.copilot/workspace"
run_pulse "$TMPDIR_COUNTER" session_start '{"sessionId":"sess-17"}' >/dev/null
assert_python_in_root "transition state initialised on session_start" "$TMPDIR_COUNTER" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state.get("tool_call_counter", -1) == 0
assert state.get("intent_phase") == "quiet"
assert state.get("digest_emit_count") == 0
assert state.get("changed_path_families") == []
'

echo ""

echo "24. stop_hook_active=true bypasses repeat blocking"
TMPDIR_STOP_LOOP=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_STOP_LOOP")
printf '.copilot/\n' >> "$TMPDIR_STOP_LOOP/.git/info/exclude"
mkdir -p "$TMPDIR_STOP_LOOP/.copilot/workspace"
run_pulse "$TMPDIR_STOP_LOOP" session_start '{"sessionId":"sess-stop-loop"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_STOP_LOOP/stop-loop-$i.txt"
done
output=$(run_pulse "$TMPDIR_STOP_LOOP" stop '{"stop_hook_active": true}')
assert_matches "repeat stop continues" "$output" '"continue": true'
assert_python_in_root "repeat stop preserves pending state and avoids new events" "$TMPDIR_STOP_LOOP" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
events = [json.loads(line) for line in (root / ".copilot/workspace/.heartbeat-events.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
assert state["retrospective_state"] == "idle"
assert state["session_state"] == "pending"
assert len(events) == 1
'

echo ""

echo "25. user_prompt captures high-confidence Commit route candidate"
TMPDIR_ROUTE_COMMIT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_ROUTE_COMMIT")
mkdir -p "$TMPDIR_ROUTE_COMMIT/.copilot/workspace"
run_pulse "$TMPDIR_ROUTE_COMMIT" session_start '{"sessionId":"sess-route-commit"}' >/dev/null
run_pulse "$TMPDIR_ROUTE_COMMIT" user_prompt '{"prompt":"Please stage and commit my changes"}' >/dev/null
assert_python_in_root "commit route candidate captured from prompt" "$TMPDIR_ROUTE_COMMIT" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["route_candidate"] == "Commit"
assert state["route_source"] == "prompt"
assert state["route_confidence"] >= 0.74
'
echo ""

echo "26. pre_tool emits sparse Commit routing hint once"
output=$(run_pulse "$TMPDIR_ROUTE_COMMIT" pre_tool '{"tool_name":"run_in_terminal","tool_input":{"command":"git commit -m \"wip\""}}')
assert_matches "commit pre_tool emits routing hint" "$output" 'Routing hint: Commit specialist'
output=$(run_pulse "$TMPDIR_ROUTE_COMMIT" pre_tool '{"tool_name":"run_in_terminal","tool_input":{"command":"git push"}}')
if echo "$output" | grep -q 'Routing hint:'; then
  fail_note "commit hint is not repeated" "     unexpected repeated hint: $output"
else
  pass_note "commit hint is not repeated"
fi
assert_python_in_root "commit hint marks emitted state" "$TMPDIR_ROUTE_COMMIT" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["route_emitted"] is True
assert "Commit" in state["route_emitted_agents"]
'
echo ""

echo "27. guarded Setup does not auto-route from behavior without strict prompt candidate"
TMPDIR_ROUTE_SETUP=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_ROUTE_SETUP")
mkdir -p "$TMPDIR_ROUTE_SETUP/.copilot/workspace"
run_pulse "$TMPDIR_ROUTE_SETUP" session_start '{"sessionId":"sess-route-setup"}' >/dev/null
output=$(run_pulse "$TMPDIR_ROUTE_SETUP" pre_tool '{"tool_name":"run_in_terminal","tool_input":{"command":"bash SETUP.md"}}')
assert_valid_json "setup behavior-only output is valid JSON" "$output"
if echo "$output" | grep -q 'Routing hint:'; then
  fail_note "setup behavior-only does not emit hint" "     unexpected hint: $output"
else
  pass_note "setup behavior-only does not emit hint"
fi
assert_python_in_root "setup behavior-only leaves candidate empty" "$TMPDIR_ROUTE_SETUP" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["route_candidate"] == ""
'
echo ""

echo "28. guarded Setup is blocked when running in template repo"
TMPDIR_ROUTE_TEMPLATE=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_ROUTE_TEMPLATE")
mkdir -p "$TMPDIR_ROUTE_TEMPLATE/.copilot/workspace" "$TMPDIR_ROUTE_TEMPLATE/.github" "$TMPDIR_ROUTE_TEMPLATE/template"
printf '# test\n' > "$TMPDIR_ROUTE_TEMPLATE/.github/copilot-instructions.md"
printf '# test\n' > "$TMPDIR_ROUTE_TEMPLATE/template/copilot-instructions.md"
run_pulse "$TMPDIR_ROUTE_TEMPLATE" session_start '{"sessionId":"sess-route-template"}' >/dev/null
run_pulse "$TMPDIR_ROUTE_TEMPLATE" user_prompt '{"prompt":"Update your instructions"}' >/dev/null
output=$(run_pulse "$TMPDIR_ROUTE_TEMPLATE" pre_tool '{"tool_name":"run_in_terminal","tool_input":{"command":"bash UPDATE.md"}}')
if echo "$output" | grep -q 'Routing hint: Setup'; then
  fail_note "setup hint is blocked in template repo" "     unexpected setup hint: $output"
else
  pass_note "setup hint is blocked in template repo"
fi

echo ""

echo "29. Stage 3 prompt+behavior routes are deterministic for newly active specialists"
for agent in Planner Docs Debugger Review Audit Extensions Organise; do
  tmpdir_agent=$(mktemp -d); CLEANUP_DIRS+=("$tmpdir_agent")
  mkdir -p "$tmpdir_agent/.copilot/workspace"
  run_pulse "$tmpdir_agent" session_start '{"sessionId":"sess-route-stage3"}' >/dev/null
  case "$agent" in
    Planner)
      prompt='Please break this down into an execution plan'
      pre_payload='{"tool_name":"read_file"}'
      ;;
    Docs)
      prompt='Please document this in the README'
      pre_payload='{"tool_name":"create_file","tool_input":{"path":"README.md"}}'
      ;;
    Debugger)
      prompt='Please debug this failing test regression and find the root cause'
      pre_payload='{"tool_name":"run_in_terminal","tool_input":{"command":"pytest tests/hooks/test-hook-pulse.sh"}}'
      ;;
    Review)
      prompt='Please run a formal code review and provide findings'
      pre_payload='{"tool_name":"get_changed_files"}'
      ;;
    Audit)
      prompt='Run a security audit and check for residual risk'
      pre_payload='{"tool_name":"run_in_terminal","tool_input":{"command":"python scripts/copilot_audit.py --help"}}'
      ;;
    Extensions)
      prompt='Review my VS Code extensions profile and sync recommendations'
      pre_payload='{"tool_name":"get_active_profile"}'
      ;;
    Organise)
      prompt='Reorganize this repo and move files to fix paths'
      pre_payload='{"tool_name":"run_in_terminal","tool_input":{"command":"git mv old.md new.md"}}'
      ;;
  esac

  run_pulse "$tmpdir_agent" user_prompt "{\"prompt\":\"$prompt\"}" >/dev/null
  assert_python_in_root "$agent prompt candidate captured" "$tmpdir_agent" "
state = json.loads((root / '.copilot/workspace/state.json').read_text(encoding='utf-8'))
assert state['route_candidate'] == '$agent'
assert state['route_source'] == 'prompt'
"

  output=$(run_pulse "$tmpdir_agent" pre_tool "$pre_payload")
  assert_matches "$agent pre_tool emits routing hint" "$output" "Routing hint: $agent specialist"
  assert_python_in_root "$agent hint records emitted state" "$tmpdir_agent" "
state = json.loads((root / '.copilot/workspace/state.json').read_text(encoding='utf-8'))
assert state['route_emitted'] is True
assert '$agent' in state['route_emitted_agents']
"
done

echo ""

echo "30. overlap-sensitive Fast and Code do not auto-route from behavior alone"
for agent in Fast Code; do
  tmpdir_agent=$(mktemp -d); CLEANUP_DIRS+=("$tmpdir_agent")
  mkdir -p "$tmpdir_agent/.copilot/workspace"
  run_pulse "$tmpdir_agent" session_start '{"sessionId":"sess-route-stage4-behavior-only"}' >/dev/null
  case "$agent" in
    Fast)
      pre_payload='{"tool_name":"run_in_terminal","tool_input":{"command":"wc -l CHANGELOG.md"}}'
      ;;
    Code)
      pre_payload='{"tool_name":"create_file","tool_input":{"path":"feature.py"}}'
      ;;
  esac

  output=$(run_pulse "$tmpdir_agent" pre_tool "$pre_payload")
  assert_valid_json "$agent behavior-only output is valid JSON" "$output"
  if echo "$output" | grep -q 'Routing hint:'; then
    fail_note "$agent behavior-only does not emit hint" "     unexpected hint: $output"
  else
    pass_note "$agent behavior-only does not emit hint"
  fi
  assert_python_in_root "$agent behavior-only leaves candidate empty" "$tmpdir_agent" "
state = json.loads((root / '.copilot/workspace/state.json').read_text(encoding='utf-8'))
assert state['route_candidate'] == ''
"
done

echo ""

echo "31. Stage 4 prompt+behavior routes are deterministic for overlap-sensitive specialists"
for agent in Fast Code; do
  tmpdir_agent=$(mktemp -d); CLEANUP_DIRS+=("$tmpdir_agent")
  mkdir -p "$tmpdir_agent/.copilot/workspace"
  run_pulse "$tmpdir_agent" session_start '{"sessionId":"sess-route-stage4"}' >/dev/null
  case "$agent" in
    Fast)
      prompt='This is a quick question: what does this regex match?'
      pre_payload='{"tool_name":"run_in_terminal","tool_input":{"command":"wc -l CHANGELOG.md"}}'
      ;;
    Code)
      prompt='Implement this feature and write tests for it'
      pre_payload='{"tool_name":"create_file","tool_input":{"path":"feature.py"}}'
      ;;
  esac

  run_pulse "$tmpdir_agent" user_prompt "{\"prompt\":\"$prompt\"}" >/dev/null
  assert_python_in_root "$agent prompt candidate captured" "$tmpdir_agent" "
state = json.loads((root / '.copilot/workspace/state.json').read_text(encoding='utf-8'))
assert state['route_candidate'] == '$agent'
assert state['route_source'] == 'prompt'
"

  output=$(run_pulse "$tmpdir_agent" pre_tool "$pre_payload")
  assert_matches "$agent pre_tool emits routing hint" "$output" "Routing hint: $agent specialist"
  assert_python_in_root "$agent hint records emitted state" "$tmpdir_agent" "
state = json.loads((root / '.copilot/workspace/state.json').read_text(encoding='utf-8'))
assert state['route_emitted'] is True
assert '$agent' in state['route_emitted_agents']
assert state['route_source'] == 'prompt+behavior'
"
done

finish_tests