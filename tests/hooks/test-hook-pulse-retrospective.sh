# shellcheck shell=bash
set -euo pipefail
echo "1. session_start initializes sentinel and state"
TMPDIR_START=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_START")
mkdir -p "$TMPDIR_START/.copilot/workspace/identity" "$TMPDIR_START/.copilot/workspace/knowledge/diaries" "$TMPDIR_START/.copilot/workspace/operations" "$TMPDIR_START/.copilot/workspace/runtime"
output=$(run_pulse "$TMPDIR_START" session_start '{"sessionId":"sess-1"}')
assert_valid_json "session_start output is valid JSON" "$output"
assert_matches "session_start continues" "$output" '"continue": true'
assert_matches "session_start includes routing roster" "$output" 'Route:'
assert_matches "sentinel contains session id" "$(cat "$TMPDIR_START/.copilot/workspace/runtime/.heartbeat-session" 2>/dev/null)" 'sess-1'
assert_matches "sentinel starts pending" "$(cat "$TMPDIR_START/.copilot/workspace/runtime/.heartbeat-session" 2>/dev/null)" 'pending'
assert_python_in_root "state written with pending session" "$TMPDIR_START" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["session_state"] == "pending"
assert state["session_id"] == "sess-1"
assert state["retrospective_state"] == "idle"
'
assert_python_in_root "session_start event records UTC timestamp" "$TMPDIR_START" '
events = (root / ".copilot/workspace/runtime/.heartbeat-events.jsonl").read_text(encoding="utf-8").splitlines()
event = json.loads(events[0])
assert event["trigger"] == "session_start"
assert event["ts_utc"].endswith("Z")
'
echo ""

echo "2. soft_post_tool trigger is debounced"
TMPDIR_DEB=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_DEB")
mkdir -p "$TMPDIR_DEB/.copilot/workspace/identity" "$TMPDIR_DEB/.copilot/workspace/knowledge/diaries" "$TMPDIR_DEB/.copilot/workspace/operations" "$TMPDIR_DEB/.copilot/workspace/runtime"
run_pulse "$TMPDIR_DEB" session_start '{"sessionId":"sess-2"}' >/dev/null
run_pulse "$TMPDIR_DEB" soft_post_tool '{}' >/dev/null
first_epoch=$(python3 - <<PY
import json
from pathlib import Path
state = json.loads(Path("$TMPDIR_DEB/.copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
print(state.get("last_soft_trigger_epoch", 0))
PY
)
run_pulse "$TMPDIR_DEB" soft_post_tool '{}' >/dev/null
second_epoch=$(python3 - <<PY
import json
from pathlib import Path
state = json.loads(Path("$TMPDIR_DEB/.copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
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
mkdir -p "$TMPDIR_SMALL/.copilot/workspace/identity" "$TMPDIR_SMALL/.copilot/workspace/knowledge/diaries" "$TMPDIR_SMALL/.copilot/workspace/operations" "$TMPDIR_SMALL/.copilot/workspace/runtime"
run_pulse "$TMPDIR_SMALL" session_start '{"sessionId":"sess-3"}' >/dev/null
output=$(run_pulse "$TMPDIR_SMALL" stop '{"stop_hook_active": false}')
assert_matches "small stop continues" "$output" '"continue": true'
assert_python_in_root "small stop records retrospective not-needed" "$TMPDIR_SMALL" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "4. stop trigger skips retrospective for borderline file churn"
TMPDIR_BORDERLINE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_BORDERLINE")
printf '.copilot/\n' >> "$TMPDIR_BORDERLINE/.git/info/exclude"
mkdir -p "$TMPDIR_BORDERLINE/.copilot/workspace/identity" "$TMPDIR_BORDERLINE/.copilot/workspace/knowledge/diaries" "$TMPDIR_BORDERLINE/.copilot/workspace/operations" "$TMPDIR_BORDERLINE/.copilot/workspace/runtime"
run_pulse "$TMPDIR_BORDERLINE" session_start '{"sessionId":"sess-4"}' >/dev/null
for i in 1 2 3 4 5; do
  printf 'change %s\n' "$i" > "$TMPDIR_BORDERLINE/file-$i.txt"
done
output=$(run_pulse "$TMPDIR_BORDERLINE" stop '{"stop_hook_active": false}')
assert_matches "borderline stop continues" "$output" '"continue": true'
assert_python_in_root "borderline stop records retrospective not-needed" "$TMPDIR_BORDERLINE" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "5. stop trigger blocks with reflect instruction on strong signals"
TMPDIR_BLOCK=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_BLOCK")
printf '.copilot/\n' >> "$TMPDIR_BLOCK/.git/info/exclude"
mkdir -p "$TMPDIR_BLOCK/.copilot/workspace/identity" "$TMPDIR_BLOCK/.copilot/workspace/knowledge/diaries" "$TMPDIR_BLOCK/.copilot/workspace/operations" "$TMPDIR_BLOCK/.copilot/workspace/runtime"
run_pulse "$TMPDIR_BLOCK" session_start '{"sessionId":"sess-5"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_BLOCK/file-$i.txt"
done
output=$(run_pulse "$TMPDIR_BLOCK" stop '{"stop_hook_active": false}')
assert_matches "large stop blocks" "$output" '"decision": "block"'
assert_matches "large stop instructs model to call session_reflect" "$output" 'session_reflect'
assert_python_in_root "large stop records retrospective suggested" "$TMPDIR_BLOCK" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "suggested"
'
echo ""

echo "6. stop passes when sentinel complete after reflect"
printf 'sess-5|2026-04-01T00:00:00Z|complete\n' > "$TMPDIR_BLOCK/.copilot/workspace/runtime/.heartbeat-session"
output=$(run_pulse "$TMPDIR_BLOCK" stop '{"stop_hook_active": false}')
assert_matches "sentinel-complete stop continues" "$output" '"continue": true'
assert_python_in_root "sentinel-complete updates state to complete" "$TMPDIR_BLOCK" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "complete"
assert state["session_state"] == "complete"
'
echo ""

echo "7. transcript mentions alone do not satisfy retrospective completion"
TMPDIR_TRANSCRIPT=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_TRANSCRIPT")
printf '.copilot/\n' >> "$TMPDIR_TRANSCRIPT/.git/info/exclude"
mkdir -p "$TMPDIR_TRANSCRIPT/.copilot/workspace/identity" "$TMPDIR_TRANSCRIPT/.copilot/workspace/knowledge/diaries" "$TMPDIR_TRANSCRIPT/.copilot/workspace/operations" "$TMPDIR_TRANSCRIPT/.copilot/workspace/runtime"
run_pulse "$TMPDIR_TRANSCRIPT" session_start '{"sessionId":"sess-transcript"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_TRANSCRIPT/file-$i.txt"
done
printf 'Significant session detected. Call the session_reflect MCP tool now.\n' > "$TMPDIR_TRANSCRIPT/transcript.txt"
output=$(run_pulse "$TMPDIR_TRANSCRIPT" stop '{"stop_hook_active": false, "transcript_path":"transcript.txt"}')
assert_matches "transcript mention still blocks" "$output" '"decision": "block"'
assert_python_in_root "transcript mention keeps retrospective suggested" "$TMPDIR_TRANSCRIPT" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "suggested"
'
echo ""

echo "8. reflection completion event passes stop without a sentinel"
TMPDIR_EVENT=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_EVENT")
printf '.copilot/\n' >> "$TMPDIR_EVENT/.git/info/exclude"
mkdir -p "$TMPDIR_EVENT/.copilot/workspace/identity" "$TMPDIR_EVENT/.copilot/workspace/knowledge/diaries" "$TMPDIR_EVENT/.copilot/workspace/operations" "$TMPDIR_EVENT/.copilot/workspace/runtime"
run_pulse "$TMPDIR_EVENT" session_start '{"sessionId":"sess-event"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_EVENT/file-$i.txt"
done
rm -f "$TMPDIR_EVENT/.copilot/workspace/runtime/.heartbeat-session"
cat >> "$TMPDIR_EVENT/.copilot/workspace/runtime/.heartbeat-events.jsonl" <<'EOF'
{"detail":"complete","session_id":"sess-event","trigger":"session_reflect","ts":1704068400,"ts_utc":"2024-01-01T00:20:00Z"}
EOF
output=$(run_pulse "$TMPDIR_EVENT" stop '{"stop_hook_active": false}')
assert_matches "completion event without sentinel continues" "$output" '"continue": true'
assert_python_in_root "completion event updates state to complete" "$TMPDIR_EVENT" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "complete"
assert state["session_state"] == "complete"
'
echo ""

echo "9. reflection completion events from other sessions do not pass stop"
TMPDIR_EVENT_OTHER=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_EVENT_OTHER")
printf '.copilot/\n' >> "$TMPDIR_EVENT_OTHER/.git/info/exclude"
mkdir -p "$TMPDIR_EVENT_OTHER/.copilot/workspace/identity" "$TMPDIR_EVENT_OTHER/.copilot/workspace/knowledge/diaries" "$TMPDIR_EVENT_OTHER/.copilot/workspace/operations" "$TMPDIR_EVENT_OTHER/.copilot/workspace/runtime"
run_pulse "$TMPDIR_EVENT_OTHER" session_start '{"sessionId":"sess-event-other"}' >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMPDIR_EVENT_OTHER/file-$i.txt"
done
rm -f "$TMPDIR_EVENT_OTHER/.copilot/workspace/runtime/.heartbeat-session"
cat >> "$TMPDIR_EVENT_OTHER/.copilot/workspace/runtime/.heartbeat-events.jsonl" <<'EOF'
{"detail":"complete","session_id":"different-session","trigger":"session_reflect","ts":1704068400,"ts_utc":"2024-01-01T00:20:00Z"}
EOF
output=$(run_pulse "$TMPDIR_EVENT_OTHER" stop '{"stop_hook_active": false}')
assert_matches "other-session completion event still blocks" "$output" '"decision": "block"'
echo ""

echo "10. user accepting retrospective keyword blocks at stop"
TMPDIR_ACCEPT=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_ACCEPT")
printf '.copilot/\n' >> "$TMPDIR_ACCEPT/.git/info/exclude"
mkdir -p "$TMPDIR_ACCEPT/.copilot/workspace/identity" "$TMPDIR_ACCEPT/.copilot/workspace/knowledge/diaries" "$TMPDIR_ACCEPT/.copilot/workspace/operations" "$TMPDIR_ACCEPT/.copilot/workspace/runtime"
run_pulse "$TMPDIR_ACCEPT" session_start '{"sessionId":"sess-7"}' >/dev/null
output=$(run_pulse "$TMPDIR_ACCEPT" user_prompt '{"prompt":"Run a retrospective please"}')
assert_matches "retrospective keyword continues" "$output" '"continue": true'
output=$(run_pulse "$TMPDIR_ACCEPT" stop '{"stop_hook_active": false}')
assert_matches "accepted stop blocks for retrospective" "$output" '"decision": "block"'
assert_matches "accepted stop explains retrospective run" "$output" 'session_reflect'
assert_matches "accepted stop mentions direct fallback helper" "$output" 'session_reflect_fallback.py'
assert_matches "accepted stop mentions tool_search fallback" "$output" 'tool_search'
echo ""

echo "11. stop trigger passes when retrospective is complete"
TMPDIR_PASS=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_PASS")
mkdir -p "$TMPDIR_PASS/.copilot/workspace/identity" "$TMPDIR_PASS/.copilot/workspace/knowledge/diaries" "$TMPDIR_PASS/.copilot/workspace/operations" "$TMPDIR_PASS/.copilot/workspace/runtime"
run_pulse "$TMPDIR_PASS" session_start '{"sessionId":"sess-8"}' >/dev/null
printf 'sess-8|2026-03-30T00:00:00Z|complete\n' > "$TMPDIR_PASS/.copilot/workspace/runtime/.heartbeat-session"
output=$(run_pulse "$TMPDIR_PASS" stop '{"stop_hook_active": false}')
assert_matches "stop continues when complete" "$output" '"continue": true'
assert_python_in_root "state transitions to complete" "$TMPDIR_PASS" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["session_state"] == "complete"
assert state["retrospective_state"] == "complete"
'
assert_python_in_root "stop completion event records duration and UTC timestamp" "$TMPDIR_PASS" '
events = [json.loads(line) for line in (root / ".copilot/workspace/runtime/.heartbeat-events.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
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
mkdir -p "$TMPDIR_PROMPT/.copilot/workspace/identity" "$TMPDIR_PROMPT/.copilot/workspace/knowledge/diaries" "$TMPDIR_PROMPT/.copilot/workspace/operations" "$TMPDIR_PROMPT/.copilot/workspace/runtime"
output=$(run_pulse "$TMPDIR_PROMPT" user_prompt '{"prompt":"Can you check your heartbeat now?"}')
assert_matches "keyword prompt includes guidance" "$output" 'Heartbeat: run HEARTBEAT'
echo ""

echo "13. policy discussion prompts do not arm heartbeat or retrospective"
TMPDIR_TOPIC=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_TOPIC")
mkdir -p "$TMPDIR_TOPIC/.copilot/workspace/identity" "$TMPDIR_TOPIC/.copilot/workspace/knowledge/diaries" "$TMPDIR_TOPIC/.copilot/workspace/operations" "$TMPDIR_TOPIC/.copilot/workspace/runtime"
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
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "14. explanation prompts stay informational"
TMPDIR_EXPLAIN=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_EXPLAIN")
mkdir -p "$TMPDIR_EXPLAIN/.copilot/workspace/identity" "$TMPDIR_EXPLAIN/.copilot/workspace/knowledge/diaries" "$TMPDIR_EXPLAIN/.copilot/workspace/operations" "$TMPDIR_EXPLAIN/.copilot/workspace/runtime"
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

