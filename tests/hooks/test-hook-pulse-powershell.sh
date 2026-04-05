#!/usr/bin/env bash
# tests/hooks/test-hook-pulse-powershell.sh -- unit tests for pulse.ps1
# Run: bash tests/hooks/test-hook-pulse-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/powershell-hook-test-helpers.sh
source "$(dirname "$0")/../lib/powershell-hook-test-helpers.sh"
init_powershell_hook_test_context "$0"
trap cleanup_dirs EXIT
ensure_pwsh_available

run_pulse_in_dir() {
  local dir="$1" payload="$2"
  shift 2
  (
    cd "$dir" || exit 1
    run_ps_script "$PULSE" "$payload" "$@"
  )
}

echo "=== pulse.ps1 (PowerShell) unit tests ==="
echo ""

echo "1. pulse.ps1 initializes heartbeat sentinel on session_start"
TMP_SENT_START=$(mktemp -d); CLEANUP_DIRS+=("$TMP_SENT_START")
mkdir -p "$TMP_SENT_START/.copilot/workspace"
output=$(run_pulse_in_dir "$TMP_SENT_START" '{"sessionId":"ps-sess-1"}' -Trigger session_start)
assert_contains "pulse session_start continues" "$output" '"continue":true'
assert_matches "pulse session_start includes UTC timestamp" "$output" 'Session started at [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z'
sentinel=$(cat "$TMP_SENT_START/.copilot/workspace/.heartbeat-session" 2>/dev/null)
assert_contains "powershell sentinel contains session id" "$sentinel" "ps-sess-1"
assert_contains "powershell sentinel starts pending" "$sentinel" "pending"
assert_python_in_root "powershell session_start event records UTC timestamp" "$TMP_SENT_START" '
events = (root / ".copilot/workspace/.heartbeat-events.jsonl").read_text(encoding="utf-8").splitlines()
event = json.loads(events[0])
assert event["trigger"] == "session_start"
assert event["ts_utc"].endswith("Z")
'
assert_python_in_root "powershell session_start initializes retrospective state" "$TMP_SENT_START" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "idle"
'
echo ""

echo "2. pulse.ps1 continues for small tasks"
TMP_SMALL_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_SMALL_PULSE")
mkdir -p "$TMP_SMALL_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_SMALL_PULSE" '{"sessionId":"ps-sess-small"}' -Trigger session_start >/dev/null
output=$(run_pulse_in_dir "$TMP_SMALL_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "pulse small stop continues" "$output" '"continue":true'
assert_python_in_root "powershell small stop records retrospective not-needed" "$TMP_SMALL_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "3. pulse.ps1 skips retrospective for borderline file churn"
TMP_BORDERLINE_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_BORDERLINE_PULSE")
printf '.copilot/\n' >> "$TMP_BORDERLINE_PULSE/.git/info/exclude"
mkdir -p "$TMP_BORDERLINE_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_BORDERLINE_PULSE" '{"sessionId":"ps-sess-borderline"}' -Trigger session_start >/dev/null
for i in 1 2 3 4 5; do
  printf 'change %s\n' "$i" > "$TMP_BORDERLINE_PULSE/ps-borderline-$i.txt"
done
output=$(run_pulse_in_dir "$TMP_BORDERLINE_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "pulse borderline stop continues" "$output" '"continue":true'
assert_python_in_root "powershell borderline stop records retrospective not-needed" "$TMP_BORDERLINE_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "4. pulse.ps1 blocks with reflect instruction on strong signals"
TMP_BLOCK_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_BLOCK_PULSE")
printf '.copilot/\n' >> "$TMP_BLOCK_PULSE/.git/info/exclude"
mkdir -p "$TMP_BLOCK_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_BLOCK_PULSE" '{"sessionId":"ps-sess-2"}' -Trigger session_start >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMP_BLOCK_PULSE/ps-file-$i.txt"
done
output=$(run_pulse_in_dir "$TMP_BLOCK_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "pulse large stop blocks" "$output" '"decision":"block"'
assert_contains "pulse large stop instructs session_reflect" "$output" 'session_reflect'
assert_python_in_root "powershell large stop records retrospective suggested" "$TMP_BLOCK_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "suggested"
'
echo ""

echo "5. stop passes when sentinel complete after reflect"
printf 'ps-sess-2|2026-04-01T00:00:00Z|complete\n' > "$TMP_BLOCK_PULSE/.copilot/workspace/.heartbeat-session"
output=$(run_pulse_in_dir "$TMP_BLOCK_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "sentinel-complete stop continues" "$output" '"continue":true'
assert_python_in_root "powershell sentinel-complete updates state" "$TMP_BLOCK_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "complete"
assert state["session_state"] == "complete"
'
echo ""

echo "6. transcript mentions alone do not satisfy retrospective completion"
TMP_TRANSCRIPT_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_TRANSCRIPT_PULSE")
printf '.copilot/\n' >> "$TMP_TRANSCRIPT_PULSE/.git/info/exclude"
mkdir -p "$TMP_TRANSCRIPT_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_TRANSCRIPT_PULSE" '{"sessionId":"ps-sess-transcript"}' -Trigger session_start >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMP_TRANSCRIPT_PULSE/ps-transcript-$i.txt"
done
printf 'Significant session detected. Call the session_reflect MCP tool now.\n' > "$TMP_TRANSCRIPT_PULSE/transcript.txt"
output=$(run_pulse_in_dir "$TMP_TRANSCRIPT_PULSE" '{"stop_hook_active": false, "transcript_path":"transcript.txt"}' -Trigger stop)
assert_contains "powershell transcript mention still blocks" "$output" '"decision":"block"'
assert_python_in_root "powershell transcript mention keeps retrospective suggested" "$TMP_TRANSCRIPT_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "suggested"
'
echo ""

echo "7. reflection completion event passes stop without a sentinel"
TMP_EVENT_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_EVENT_PULSE")
printf '.copilot/\n' >> "$TMP_EVENT_PULSE/.git/info/exclude"
mkdir -p "$TMP_EVENT_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_EVENT_PULSE" '{"sessionId":"ps-sess-event"}' -Trigger session_start >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMP_EVENT_PULSE/ps-event-$i.txt"
done
rm -f "$TMP_EVENT_PULSE/.copilot/workspace/.heartbeat-session"
cat >> "$TMP_EVENT_PULSE/.copilot/workspace/.heartbeat-events.jsonl" <<'EOF'
{"detail":"complete","session_id":"ps-sess-event","trigger":"session_reflect","ts":1704068400,"ts_utc":"2024-01-01T00:20:00Z"}
EOF
output=$(run_pulse_in_dir "$TMP_EVENT_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "powershell completion event without sentinel continues" "$output" '"continue":true'
assert_python_in_root "powershell completion event updates state" "$TMP_EVENT_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "complete"
assert state["session_state"] == "complete"
'
echo ""

echo "8. reflection completion events from other sessions do not pass stop"
TMP_OTHER_EVENT_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_OTHER_EVENT_PULSE")
printf '.copilot/\n' >> "$TMP_OTHER_EVENT_PULSE/.git/info/exclude"
mkdir -p "$TMP_OTHER_EVENT_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_OTHER_EVENT_PULSE" '{"sessionId":"ps-sess-other-event"}' -Trigger session_start >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMP_OTHER_EVENT_PULSE/ps-other-event-$i.txt"
done
rm -f "$TMP_OTHER_EVENT_PULSE/.copilot/workspace/.heartbeat-session"
cat >> "$TMP_OTHER_EVENT_PULSE/.copilot/workspace/.heartbeat-events.jsonl" <<'EOF'
{"detail":"complete","session_id":"different-session","trigger":"session_reflect","ts":1704068400,"ts_utc":"2024-01-01T00:20:00Z"}
EOF
output=$(run_pulse_in_dir "$TMP_OTHER_EVENT_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "powershell other-session completion event still blocks" "$output" '"decision":"block"'
echo ""

echo "9. user accepting retrospective keyword blocks at stop"
TMP_ACCEPT_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_ACCEPT_PULSE")
printf '.copilot/\n' >> "$TMP_ACCEPT_PULSE/.git/info/exclude"
mkdir -p "$TMP_ACCEPT_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_ACCEPT_PULSE" '{"sessionId":"ps-sess-accept"}' -Trigger session_start >/dev/null
output=$(run_pulse_in_dir "$TMP_ACCEPT_PULSE" '{"prompt":"Run a retrospective please"}' -Trigger user_prompt)
assert_contains "retrospective keyword continues" "$output" '"continue":true'
output=$(run_pulse_in_dir "$TMP_ACCEPT_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "accepted stop blocks for retrospective" "$output" '"decision":"block"'
assert_contains "accepted stop explains retrospective run" "$output" 'session_reflect'
echo ""

echo "10. pulse.ps1 records duration and UTC timestamp when stop completes"
TMP_DONE_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_DONE_PULSE")
mkdir -p "$TMP_DONE_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_DONE_PULSE" '{"sessionId":"ps-sess-3"}' -Trigger session_start >/dev/null
printf 'ps-sess-3|2026-03-30T00:00:00Z|complete\n' > "$TMP_DONE_PULSE/.copilot/workspace/.heartbeat-session"
output=$(run_pulse_in_dir "$TMP_DONE_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "pulse stop complete continues" "$output" '"continue":true'
assert_python_in_root "powershell stop completion event records duration and UTC timestamp" "$TMP_DONE_PULSE" '
events = [json.loads(line) for line in (root / ".copilot/workspace/.heartbeat-events.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
event = events[-1]
assert event["trigger"] == "stop"
assert event["detail"] == "complete"
assert isinstance(event["duration_s"], int)
assert event["duration_s"] >= 0
assert event["ts_utc"].endswith("Z")
'
assert_python_in_root "powershell complete stop records retrospective complete" "$TMP_DONE_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "complete"
'
echo ""

echo "11. user_prompt heartbeat keyword emits system message"
TMP_PROMPT_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_PROMPT_PULSE")
mkdir -p "$TMP_PROMPT_PULSE/.copilot/workspace"
output=$(run_pulse_in_dir "$TMP_PROMPT_PULSE" '{"prompt":"Can you check your heartbeat now?"}' -Trigger user_prompt)
assert_contains "powershell keyword prompt includes guidance" "$output" 'Heartbeat trigger detected'
echo ""

echo "12. discussion-only prompt does not arm heartbeat or retrospective"
TMP_TOPIC_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_TOPIC_PULSE")
mkdir -p "$TMP_TOPIC_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_TOPIC_PULSE" '{"sessionId":"ps-sess-topic"}' -Trigger session_start >/dev/null
output=$(run_pulse_in_dir "$TMP_TOPIC_PULSE" '{"prompt":"Let us review heartbeat and retrospective thresholds"}' -Trigger user_prompt)
assert_valid_json "powershell discussion-only prompt returns valid JSON" "$output"
if echo "$output" | grep -q 'systemMessage'; then
  fail_note "powershell discussion-only prompt stays quiet" "     unexpected systemMessage in output: $output"
else
  pass_note "powershell discussion-only prompt stays quiet"
fi
output=$(run_pulse_in_dir "$TMP_TOPIC_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "powershell discussion-only stop continues" "$output" '"continue":true'
assert_python_in_root "powershell discussion-only prompt keeps retrospective idle" "$TMP_TOPIC_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "13. explanation prompts stay informational"
TMP_EXPLAIN_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_EXPLAIN_PULSE")
mkdir -p "$TMP_EXPLAIN_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_EXPLAIN_PULSE" '{"sessionId":"ps-sess-explain"}' -Trigger session_start >/dev/null
output=$(run_pulse_in_dir "$TMP_EXPLAIN_PULSE" '{"prompt":"Could you explain the retrospective policy?"}' -Trigger user_prompt)
assert_valid_json "powershell retrospective policy prompt returns valid JSON" "$output"
if echo "$output" | grep -q 'systemMessage'; then
  fail_note "powershell retrospective policy prompt stays informational" "     unexpected systemMessage in output: $output"
else
  pass_note "powershell retrospective policy prompt stays informational"
fi
output=$(run_pulse_in_dir "$TMP_EXPLAIN_PULSE" '{"prompt":"Show the heartbeat policy"}' -Trigger user_prompt)
assert_valid_json "powershell heartbeat policy prompt returns valid JSON" "$output"
if echo "$output" | grep -q 'systemMessage'; then
  fail_note "powershell heartbeat policy prompt stays informational" "     unexpected systemMessage in output: $output"
else
  pass_note "powershell heartbeat policy prompt stays informational"
fi
output=$(run_pulse_in_dir "$TMP_EXPLAIN_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "powershell explanation prompts do not arm stop" "$output" '"continue":true'
echo ""

echo "14. session_start captures git baseline"
TMP_BASE_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_BASE_PULSE")
printf '.copilot/\n' >> "$TMP_BASE_PULSE/.git/info/exclude"
mkdir -p "$TMP_BASE_PULSE/.copilot/workspace"
printf 'pre-existing\n' > "$TMP_BASE_PULSE/pre-existing.txt"
run_pulse_in_dir "$TMP_BASE_PULSE" '{"sessionId":"ps-sess-base"}' -Trigger session_start >/dev/null
assert_python_in_root "powershell session_start records git baseline count" "$TMP_BASE_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["session_start_git_count"] >= 1
assert state["copilot_edit_count"] == 0
assert state["active_work_seconds"] == 0
assert state["task_window_start_epoch"] == 0
'
echo ""

echo "15. soft_post_tool increments edit count only for file-writing tools"
TMP_EDIT_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_EDIT_PULSE")
mkdir -p "$TMP_EDIT_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_EDIT_PULSE" '{"sessionId":"ps-sess-edit"}' -Trigger session_start >/dev/null
run_pulse_in_dir "$TMP_EDIT_PULSE" '{"tool_name":"run_in_terminal"}' -Trigger soft_post_tool >/dev/null
assert_python_in_root "powershell non-file tool does not increment edit count" "$TMP_EDIT_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["copilot_edit_count"] == 0
'
run_pulse_in_dir "$TMP_EDIT_PULSE" '{"tool_name":"create_file"}' -Trigger soft_post_tool >/dev/null
assert_python_in_root "powershell create_file increments edit count" "$TMP_EDIT_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["copilot_edit_count"] == 1
'
run_pulse_in_dir "$TMP_EDIT_PULSE" '{"tool_name":"replace_string_in_file"}' -Trigger soft_post_tool >/dev/null
assert_python_in_root "powershell replace_string_in_file increments edit count" "$TMP_EDIT_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["copilot_edit_count"] == 2
'
echo ""

echo "16. soft_post_tool opens and accumulates work windows"
TMP_WIN_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_WIN_PULSE")
mkdir -p "$TMP_WIN_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_WIN_PULSE" '{"sessionId":"ps-sess-win"}' -Trigger session_start >/dev/null
run_pulse_in_dir "$TMP_WIN_PULSE" '{"tool_name":"create_file"}' -Trigger soft_post_tool >/dev/null
assert_python_in_root "powershell first tool use opens work window" "$TMP_WIN_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["task_window_start_epoch"] > 0
assert state["last_raw_tool_epoch"] > 0
'
python3 - <<PY
import json, time
from pathlib import Path
p = Path("$TMP_WIN_PULSE/.copilot/workspace/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
now = int(time.time())
state["task_window_start_epoch"] = now - 900
state["last_raw_tool_epoch"] = now - 700
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
run_pulse_in_dir "$TMP_WIN_PULSE" '{"tool_name":"replace_string_in_file"}' -Trigger soft_post_tool >/dev/null
assert_python_in_root "powershell idle gap closes old window and accumulates time" "$TMP_WIN_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["active_work_seconds"] >= 190
assert state["task_window_start_epoch"] > 0
'
echo ""

echo "17. pure planning session never triggers retrospective"
TMP_PLAN_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_PLAN_PULSE")
printf '.copilot/\n' >> "$TMP_PLAN_PULSE/.git/info/exclude"
mkdir -p "$TMP_PLAN_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_PLAN_PULSE" '{"sessionId":"ps-sess-plan"}' -Trigger session_start >/dev/null
python3 - <<PY
import json, time
from pathlib import Path
p = Path("$TMP_PLAN_PULSE/.copilot/workspace/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
now = int(time.time())
state["session_start_epoch"] = now - 2400
state["active_work_seconds"] = 2100
state["last_raw_tool_epoch"] = now - 30
state["task_window_start_epoch"] = now - 30
state["copilot_edit_count"] = 0
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
output=$(run_pulse_in_dir "$TMP_PLAN_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "powershell planning-only session continues" "$output" '"continue":true'
assert_python_in_root "powershell planning session records not-needed" "$TMP_PLAN_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "18. pre-existing dirty files do not inflate the delta count"
TMP_DELTA_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_DELTA_PULSE")
printf '.copilot/\n' >> "$TMP_DELTA_PULSE/.git/info/exclude"
mkdir -p "$TMP_DELTA_PULSE/.copilot/workspace"
for i in 1 2 3 4 5 6 7 8; do
  printf 'pre-existing %s\n' "$i" > "$TMP_DELTA_PULSE/ps-pre-$i.txt"
done
run_pulse_in_dir "$TMP_DELTA_PULSE" '{"sessionId":"ps-sess-delta"}' -Trigger session_start >/dev/null
output=$(run_pulse_in_dir "$TMP_DELTA_PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "powershell pre-existing dirty files do not trigger retro" "$output" '"continue":true'
assert_python_in_root "powershell state is not-needed due to zero delta" "$TMP_DELTA_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "19. corrupt state file is recovered safely"
TMP_CORRUPT_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CORRUPT_PULSE")
mkdir -p "$TMP_CORRUPT_PULSE/.copilot/workspace"
printf '{broken-json\n' > "$TMP_CORRUPT_PULSE/.copilot/workspace/state.json"
output=$(run_pulse_in_dir "$TMP_CORRUPT_PULSE" '{"sessionId":"ps-sess-corrupt"}' -Trigger session_start)
assert_valid_json "powershell session_start still returns valid JSON" "$output"
assert_python_in_root "powershell state file becomes valid JSON" "$TMP_CORRUPT_PULSE" '
json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
'
echo ""

echo "20. transition digest stays quiet while the session is only orienting"
TMP_DIGEST_QUIET_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_DIGEST_QUIET_PULSE")
mkdir -p "$TMP_DIGEST_QUIET_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_DIGEST_QUIET_PULSE" '{"sessionId":"ps-sess-digest-quiet"}' -Trigger session_start >/dev/null
python3 - <<PY
import json
from pathlib import Path
p = Path("$TMP_DIGEST_QUIET_PULSE/.copilot/workspace/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
state["tool_call_counter"] = 14
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
output=$(run_pulse_in_dir "$TMP_DIGEST_QUIET_PULSE" '{"tool_name":"run_in_terminal"}' -Trigger soft_post_tool)
assert_valid_json "powershell orienting call output is valid JSON" "$output"
if echo "$output" | grep -q 'additionalContext'; then
  fail_note "powershell orienting call has no additionalContext" "     unexpected additionalContext in output: $output"
else
  pass_note "powershell orienting call has no additionalContext"
fi
assert_python_in_root "powershell orienting call records phase without digest emission" "$TMP_DIGEST_QUIET_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["tool_call_counter"] == 15
assert state["intent_phase"] == "orienting"
assert state["digest_emit_count"] == 0
'
echo ""

echo "21. transition digest appears when work crosses into consolidating"
TMP_DIGEST_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_DIGEST_PULSE")
mkdir -p "$TMP_DIGEST_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_DIGEST_PULSE" '{"sessionId":"ps-sess-digest"}' -Trigger session_start >/dev/null
python3 - <<PY
import json
from pathlib import Path
p = Path("$TMP_DIGEST_PULSE/.copilot/workspace/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
state["tool_call_counter"] = 14
state["copilot_edit_count"] = 4
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
output=$(run_pulse_in_dir "$TMP_DIGEST_PULSE" '{"tool_name":"create_file","tool_input":{"filePath":"scripts/example.sh"}}' -Trigger soft_post_tool)
assert_contains "powershell consolidating call includes digest" "$output" 'additionalContext'
assert_contains "powershell digest reports validation intent" "$output" 'Session intent: tests and validation likely next'
assert_python_in_root "powershell consolidating call records runtime family and digest state" "$TMP_DIGEST_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["tool_call_counter"] == 15
assert state["intent_phase"] == "consolidating"
assert state["digest_emit_count"] == 1
assert "runtime" in state["changed_path_families"]
'
output=$(run_pulse_in_dir "$TMP_DIGEST_PULSE" '{"tool_name":"run_in_terminal"}' -Trigger soft_post_tool)
assert_valid_json "powershell follow-up consolidating call output is valid JSON" "$output"
if echo "$output" | grep -q 'additionalContext'; then
  fail_note "powershell follow-up consolidating call has no additionalContext" "     unexpected additionalContext in output: $output"
else
  pass_note "powershell follow-up consolidating call has no additionalContext"
fi
echo ""

echo "22. session_start initializes transition state"
TMP_COUNTER_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_COUNTER_PULSE")
mkdir -p "$TMP_COUNTER_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_COUNTER_PULSE" '{"sessionId":"ps-sess-counter"}' -Trigger session_start >/dev/null
assert_python_in_root "powershell transition state initialised on session_start" "$TMP_COUNTER_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state.get("tool_call_counter", -1) == 0
assert state.get("intent_phase") == "quiet"
assert state.get("digest_emit_count") == 0
assert state.get("changed_path_families") == []
'
echo ""

echo "23. stop_hook_active=true bypasses repeat blocking"
TMP_STOP_LOOP_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_STOP_LOOP_PULSE")
printf '.copilot/\n' >> "$TMP_STOP_LOOP_PULSE/.git/info/exclude"
mkdir -p "$TMP_STOP_LOOP_PULSE/.copilot/workspace"
run_pulse_in_dir "$TMP_STOP_LOOP_PULSE" '{"sessionId":"ps-sess-stop-loop"}' -Trigger session_start >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMP_STOP_LOOP_PULSE/ps-stop-loop-$i.txt"
done
output=$(run_pulse_in_dir "$TMP_STOP_LOOP_PULSE" '{"stop_hook_active": true}' -Trigger stop)
assert_contains "powershell repeat stop continues" "$output" '"continue":true'
assert_python_in_root "powershell repeat stop preserves pending state and avoids new events" "$TMP_STOP_LOOP_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
events = [json.loads(line) for line in (root / ".copilot/workspace/.heartbeat-events.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
assert state["retrospective_state"] == "idle"
assert state["session_state"] == "pending"
assert len(events) == 1
'
echo ""

finish_tests