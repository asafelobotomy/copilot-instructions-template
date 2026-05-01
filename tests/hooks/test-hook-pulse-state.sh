# shellcheck shell=bash
echo "15. session_start captures git baseline"
TMPDIR_BASE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_BASE")
printf '.copilot/\n' >> "$TMPDIR_BASE/.git/info/exclude"
mkdir -p "$TMPDIR_BASE/.copilot/workspace/identity" "$TMPDIR_BASE/.copilot/workspace/knowledge/diaries" "$TMPDIR_BASE/.copilot/workspace/operations" "$TMPDIR_BASE/.copilot/workspace/runtime"
# Create a dirty file BEFORE session_start — should be captured as baseline.
printf 'pre-existing\n' > "$TMPDIR_BASE/pre-existing.txt"
run_pulse "$TMPDIR_BASE" session_start '{"sessionId":"sess-base"}' >/dev/null
assert_python_in_root "session_start records git baseline count" "$TMPDIR_BASE" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["session_start_git_count"] >= 1
assert state["copilot_edit_count"] == 0
assert state["active_work_seconds"] == 0
assert state["task_window_start_epoch"] == 0
'
echo ""

echo "16. soft_post_tool increments edit count only for file-writing tools"
TMPDIR_EDIT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_EDIT")
mkdir -p "$TMPDIR_EDIT/.copilot/workspace/identity" "$TMPDIR_EDIT/.copilot/workspace/knowledge/diaries" "$TMPDIR_EDIT/.copilot/workspace/operations" "$TMPDIR_EDIT/.copilot/workspace/runtime"
run_pulse "$TMPDIR_EDIT" session_start '{"sessionId":"sess-11"}' >/dev/null
run_pulse "$TMPDIR_EDIT" soft_post_tool '{"tool_name":"run_in_terminal"}' >/dev/null
assert_python_in_root "non-file tool does not increment edit count" "$TMPDIR_EDIT" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["copilot_edit_count"] == 0
'
run_pulse "$TMPDIR_EDIT" soft_post_tool '{"tool_name":"create_file"}' >/dev/null
assert_python_in_root "create_file increments edit count to 1" "$TMPDIR_EDIT" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["copilot_edit_count"] == 1
'
run_pulse "$TMPDIR_EDIT" soft_post_tool '{"tool_name":"replace_string_in_file"}' >/dev/null
assert_python_in_root "replace_string_in_file increments edit count to 2" "$TMPDIR_EDIT" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["copilot_edit_count"] == 2
'
echo ""

echo "17. soft_post_tool opens and accumulates work windows"
TMPDIR_WIN=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_WIN")
mkdir -p "$TMPDIR_WIN/.copilot/workspace/identity" "$TMPDIR_WIN/.copilot/workspace/knowledge/diaries" "$TMPDIR_WIN/.copilot/workspace/operations" "$TMPDIR_WIN/.copilot/workspace/runtime"
run_pulse "$TMPDIR_WIN" session_start '{"sessionId":"sess-12"}' >/dev/null
run_pulse "$TMPDIR_WIN" soft_post_tool '{"tool_name":"create_file"}' >/dev/null
assert_python_in_root "first tool use opens work window" "$TMPDIR_WIN" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["task_window_start_epoch"] > 0
assert state["last_raw_tool_epoch"] > 0
'
# Simulate an idle gap by backdating last_raw_tool_epoch > idle_gap_s (600s) ago.
python3 - <<PY
import json, time
from pathlib import Path
p = Path("$TMPDIR_WIN/.copilot/workspace/runtime/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
now = int(time.time())
state["task_window_start_epoch"] = now - 900  # 15m ago
state["last_raw_tool_epoch"] = now - 700       # 700s ago (> 600s idle gap)
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
run_pulse "$TMPDIR_WIN" soft_post_tool '{"tool_name":"replace_string_in_file"}' >/dev/null
assert_python_in_root "idle gap closes old window and accumulates time" "$TMPDIR_WIN" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
# Window from 900s-ago to 700s-ago = 200s accumulated
assert state["active_work_seconds"] >= 190
assert state["task_window_start_epoch"] > 0  # new window opened
'
echo ""

echo "18. pure planning session (0 file changes) never triggers retrospective"
TMPDIR_PLAN=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_PLAN")
printf '.copilot/\n' >> "$TMPDIR_PLAN/.git/info/exclude"
mkdir -p "$TMPDIR_PLAN/.copilot/workspace/identity" "$TMPDIR_PLAN/.copilot/workspace/knowledge/diaries" "$TMPDIR_PLAN/.copilot/workspace/operations" "$TMPDIR_PLAN/.copilot/workspace/runtime"
run_pulse "$TMPDIR_PLAN" session_start '{"sessionId":"sess-13"}' >/dev/null
# Simulate a 40-minute session with tool activity but no file changes.
python3 - <<PY
import json, time
from pathlib import Path
p = Path("$TMPDIR_PLAN/.copilot/workspace/runtime/state.json")
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
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "19. pre-existing dirty files do not inflate the delta count"
TMPDIR_DELTA=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_DELTA")
printf '.copilot/\n' >> "$TMPDIR_DELTA/.git/info/exclude"
mkdir -p "$TMPDIR_DELTA/.copilot/workspace/identity" "$TMPDIR_DELTA/.copilot/workspace/knowledge/diaries" "$TMPDIR_DELTA/.copilot/workspace/operations" "$TMPDIR_DELTA/.copilot/workspace/runtime"
# Create 8 dirty files BEFORE session_start.
for i in 1 2 3 4 5 6 7 8; do
  printf 'pre-existing %s\n' "$i" > "$TMPDIR_DELTA/pre-$i.txt"
done
run_pulse "$TMPDIR_DELTA" session_start '{"sessionId":"sess-14"}' >/dev/null
# No new files created — delta should be 0 even though 8 dirty files exist.
output=$(run_pulse "$TMPDIR_DELTA" stop '{"stop_hook_active": false}')
assert_matches "pre-existing dirty files do not trigger retro" "$output" '"continue": true'
assert_python_in_root "state is not-needed due to zero delta" "$TMPDIR_DELTA" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "20. corrupt state file is recovered safely"
TMPDIR_CORRUPT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_CORRUPT")
mkdir -p "$TMPDIR_CORRUPT/.copilot/workspace/identity" "$TMPDIR_CORRUPT/.copilot/workspace/knowledge/diaries" "$TMPDIR_CORRUPT/.copilot/workspace/operations" "$TMPDIR_CORRUPT/.copilot/workspace/runtime"
printf '{broken-json\n' > "$TMPDIR_CORRUPT/.copilot/workspace/runtime/state.json"
output=$(run_pulse "$TMPDIR_CORRUPT" session_start '{"sessionId":"sess-8"}')
assert_valid_json "session_start still returns valid JSON" "$output"
assert_python_in_root "state file becomes valid JSON" "$TMPDIR_CORRUPT" '
import json
json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
'
echo ""

echo "21. transition digest stays quiet while the session is only orienting"
TMPDIR_DIGEST_QUIET=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_DIGEST_QUIET")
mkdir -p "$TMPDIR_DIGEST_QUIET/.copilot/workspace/identity" "$TMPDIR_DIGEST_QUIET/.copilot/workspace/knowledge/diaries" "$TMPDIR_DIGEST_QUIET/.copilot/workspace/operations" "$TMPDIR_DIGEST_QUIET/.copilot/workspace/runtime"
run_pulse "$TMPDIR_DIGEST_QUIET" session_start '{"sessionId":"sess-17-quiet"}' >/dev/null
python3 - <<PY
import json
from pathlib import Path
p = Path("$TMPDIR_DIGEST_QUIET/.copilot/workspace/runtime/state.json")
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
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["tool_call_counter"] == 15
assert state["intent_phase"] == "orienting"
assert state["digest_emit_count"] == 0
'
echo ""

echo "22. transition digest appears when work crosses into consolidating"
TMPDIR_DIGEST=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_DIGEST")
mkdir -p "$TMPDIR_DIGEST/.copilot/workspace/identity" "$TMPDIR_DIGEST/.copilot/workspace/knowledge/diaries" "$TMPDIR_DIGEST/.copilot/workspace/operations" "$TMPDIR_DIGEST/.copilot/workspace/runtime"
run_pulse "$TMPDIR_DIGEST" session_start '{"sessionId":"sess-16"}' >/dev/null
python3 - <<PY
import json
from pathlib import Path
p = Path("$TMPDIR_DIGEST/.copilot/workspace/runtime/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
state["tool_call_counter"] = 14
state["copilot_edit_count"] = 4
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
output=$(run_pulse "$TMPDIR_DIGEST" soft_post_tool '{"tool_name":"create_file","tool_input":{"filePath":"scripts/example.sh"}}')
assert_matches "consolidating call includes digest" "$output" 'additionalContext'
assert_matches "digest reports validation intent" "$output" 'Session intent: tests and validation likely next'
assert_python_in_root "consolidating call records runtime family and digest state" "$TMPDIR_DIGEST" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
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
mkdir -p "$TMPDIR_COUNTER/.copilot/workspace/identity" "$TMPDIR_COUNTER/.copilot/workspace/knowledge/diaries" "$TMPDIR_COUNTER/.copilot/workspace/operations" "$TMPDIR_COUNTER/.copilot/workspace/runtime"
run_pulse "$TMPDIR_COUNTER" session_start '{"sessionId":"sess-17"}' >/dev/null
assert_python_in_root "transition state initialised on session_start" "$TMPDIR_COUNTER" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state.get("tool_call_counter", -1) == 0
assert state.get("intent_phase") == "quiet"
assert state.get("digest_emit_count") == 0
assert state.get("changed_path_families") == []
'

echo ""

echo "24. stop_hook_active=true bypasses repeat blocking"
TMPDIR_STOP_LOOP=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_STOP_LOOP")
printf '.copilot/\n' >> "$TMPDIR_STOP_LOOP/.git/info/exclude"
mkdir -p "$TMPDIR_STOP_LOOP/.copilot/workspace/identity" "$TMPDIR_STOP_LOOP/.copilot/workspace/knowledge/diaries" "$TMPDIR_STOP_LOOP/.copilot/workspace/operations" "$TMPDIR_STOP_LOOP/.copilot/workspace/runtime"
run_pulse "$TMPDIR_STOP_LOOP" session_start '{"sessionId":"sess-stop-loop"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_STOP_LOOP/stop-loop-$i.txt"
done
output=$(run_pulse "$TMPDIR_STOP_LOOP" stop '{"stop_hook_active": true}')
assert_matches "repeat stop continues" "$output" '"continue": true'
assert_python_in_root "repeat stop preserves pending state and avoids new events" "$TMPDIR_STOP_LOOP" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
events = [json.loads(line) for line in (root / ".copilot/workspace/runtime/.heartbeat-events.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
assert state["retrospective_state"] == "idle"
assert state["session_state"] == "pending"
assert len(events) == 1
'

echo ""

