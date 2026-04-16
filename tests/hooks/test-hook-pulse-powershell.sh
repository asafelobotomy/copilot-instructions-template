#!/usr/bin/env bash
# tests/hooks/test-hook-pulse-powershell.sh -- proxy contract tests for pulse.ps1
# Validates that pulse.ps1 correctly proxies to pulse_runtime.py via Python.
# Business-logic coverage lives in test-hook-pulse.sh (bash); this suite tests
# only the PowerShell proxy mechanics: init, continue, block, routing, reflect,
# state persistence, corrupt recovery, and JSON compactness.
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

make_workspace_dirs() {
  local dir="$1"
  mkdir -p "$dir/.copilot/workspace/identity" \
           "$dir/.copilot/workspace/knowledge/diaries" \
           "$dir/.copilot/workspace/operations" \
           "$dir/.copilot/workspace/runtime"
}

echo "=== pulse.ps1 proxy contract tests ==="
echo ""

# ── 1. session_start: init produces valid JSON, writes sentinel and state ──
echo "1. session_start initializes sentinel, state, and routing roster"
TMP1=$(mktemp -d); CLEANUP_DIRS+=("$TMP1")
make_workspace_dirs "$TMP1"
output=$(run_pulse_in_dir "$TMP1" '{"sessionId":"ps-proxy-1"}' -Trigger session_start)
assert_contains "proxy session_start continues" "$output" '"continue":true'
assert_valid_json "proxy session_start output is valid JSON" "$output"
assert_matches "proxy session_start includes routing roster" "$output" 'Route:'
sentinel=$(cat "$TMP1/.copilot/workspace/runtime/.heartbeat-session" 2>/dev/null)
assert_contains "proxy sentinel contains session id" "$sentinel" "ps-proxy-1"
assert_contains "proxy sentinel starts pending" "$sentinel" "pending"
assert_python_in_root "proxy state.json initialized" "$TMP1" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "idle"
assert state.get("intent_phase") == "quiet"
'
echo ""

# ── 2. stop continue: small session passes through ──
echo "2. stop continues for small session"
TMP2=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP2")
make_workspace_dirs "$TMP2"
run_pulse_in_dir "$TMP2" '{"sessionId":"ps-proxy-small"}' -Trigger session_start >/dev/null
output=$(run_pulse_in_dir "$TMP2" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "proxy small stop continues" "$output" '"continue":true'
assert_valid_json "proxy small stop is valid JSON" "$output"
echo ""

# ── 3. stop block: large session blocks with decision:block ──
echo "3. stop blocks on strong signal (8+ file changes)"
TMP3=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP3")
printf '.copilot/\n' >> "$TMP3/.git/info/exclude"
make_workspace_dirs "$TMP3"
run_pulse_in_dir "$TMP3" '{"sessionId":"ps-proxy-block"}' -Trigger session_start >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMP3/ps-proxy-$i.txt"
done
output=$(run_pulse_in_dir "$TMP3" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "proxy large stop blocks" "$output" '"decision":"block"'
assert_contains "proxy block instructs session_reflect" "$output" 'session_reflect'
assert_valid_json "proxy block output is valid JSON" "$output"
echo ""

# ── 4. routing: user_prompt captures route candidate and pre_tool emits hint ──
echo "4. routing: prompt captures candidate and pre_tool emits hint"
TMP4=$(mktemp -d); CLEANUP_DIRS+=("$TMP4")
make_workspace_dirs "$TMP4"
run_pulse_in_dir "$TMP4" '{"sessionId":"ps-proxy-route"}' -Trigger session_start >/dev/null
output=$(run_pulse_in_dir "$TMP4" '{"prompt":"Please stage and commit my changes"}' -Trigger user_prompt)
assert_valid_json "proxy commit prompt is valid JSON" "$output"
assert_python_in_root "proxy commit route candidate captured" "$TMP4" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["route_candidate"] == "Commit", "got %s" % state.get("route_candidate")
'
output=$(run_pulse_in_dir "$TMP4" '{"tool_name":"run_in_terminal","tool_input":{"command":"git commit -m wip"}}' -Trigger pre_tool)
assert_contains "proxy commit pre_tool emits routing hint" "$output" 'Routing hint: Commit'
assert_python_in_root "proxy commit hint marks emitted" "$TMP4" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["route_emitted"] is True
'
echo ""

# ── 5. user_prompt heartbeat keyword emits system message ──
echo "5. heartbeat keyword emits system message"
TMP5=$(mktemp -d); CLEANUP_DIRS+=("$TMP5")
make_workspace_dirs "$TMP5"
output=$(run_pulse_in_dir "$TMP5" '{"prompt":"Can you check your heartbeat now?"}' -Trigger user_prompt)
assert_contains "proxy heartbeat keyword includes guidance" "$output" 'Heartbeat: run HEARTBEAT'
assert_valid_json "proxy heartbeat keyword is valid JSON" "$output"
echo ""

# ── 6. corrupt state file is recovered safely ──
echo "6. corrupt state file is recovered safely"
TMP6=$(mktemp -d); CLEANUP_DIRS+=("$TMP6")
make_workspace_dirs "$TMP6"
printf 'NOT{JSON' > "$TMP6/.copilot/workspace/runtime/state.json"
output=$(run_pulse_in_dir "$TMP6" '{"sessionId":"ps-proxy-corrupt"}' -Trigger session_start)
assert_valid_json "proxy corrupt recovery output is valid JSON" "$output"
assert_python_in_root "proxy state file becomes valid JSON" "$TMP6" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert "retrospective_state" in state
'
echo ""

# ── 7. reflect instruction emitted once on significant edit count ──
echo "7. reflect instruction emitted once on significant edit count"
TMP7=$(mktemp -d); CLEANUP_DIRS+=("$TMP7")
make_workspace_dirs "$TMP7"
run_pulse_in_dir "$TMP7" '{"sessionId":"ps-proxy-reflect"}' -Trigger session_start >/dev/null
python3 - <<PY
import json
from pathlib import Path
p = Path("$TMP7/.copilot/workspace/runtime/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
state["copilot_edit_count"] = 10
state["reflect_instruction_emitted"] = False
state["retrospective_state"] = "idle"
state["last_soft_trigger_epoch"] = 0
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
output=$(run_pulse_in_dir "$TMP7" '{"tool_name":"run_in_terminal"}' -Trigger soft_post_tool)
assert_valid_json "proxy reflect instruction output is valid JSON" "$output"
assert_contains "proxy reflect instruction appears in additionalContext" "$output" 'session_reflect'
echo "8. proxy does not re-emit reflect instruction after first emission"
output2=$(run_pulse_in_dir "$TMP7" '{"tool_name":"run_in_terminal"}' -Trigger soft_post_tool)
assert_valid_json "proxy second soft_post_tool is valid JSON" "$output2"
if echo "$output2" | grep -q 'session_reflect'; then
  fail_note "proxy second call must not re-emit reflect instruction" "     unexpected session_reflect in output: $output2"
else
  pass_note "proxy second call must not re-emit reflect instruction"
fi
echo ""

# ── 9. stop_hook_active=true bypasses repeat blocking ──
echo "9. stop_hook_active bypasses repeat blocking"
TMP9=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP9")
printf '.copilot/\n' >> "$TMP9/.git/info/exclude"
make_workspace_dirs "$TMP9"
run_pulse_in_dir "$TMP9" '{"sessionId":"ps-proxy-repeat"}' -Trigger session_start >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMP9/ps-repeat-$i.txt"
done
output=$(run_pulse_in_dir "$TMP9" '{"stop_hook_active": true}' -Trigger stop)
assert_contains "proxy repeat stop continues" "$output" '"continue":true'
echo ""

# ── 10. transition digest appears when work crosses into consolidating ──
echo "10. transition digest on phase change"
TMP10=$(mktemp -d); CLEANUP_DIRS+=("$TMP10")
make_workspace_dirs "$TMP10"
run_pulse_in_dir "$TMP10" '{"sessionId":"ps-proxy-phase"}' -Trigger session_start >/dev/null
output=$(run_pulse_in_dir "$TMP10" '{"tool_name":"read_file"}' -Trigger soft_post_tool)
assert_valid_json "proxy orienting call is valid JSON" "$output"
python3 - <<PY
import json
from pathlib import Path
p = Path("$TMP10/.copilot/workspace/runtime/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
state["tool_call_counter"] = 14
state["copilot_edit_count"] = 4
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
output=$(run_pulse_in_dir "$TMP10" '{"tool_name":"create_file","tool_input":{"filePath":"scripts/example.sh"}}' -Trigger soft_post_tool)
assert_valid_json "proxy consolidating call is valid JSON" "$output"
assert_contains "proxy consolidating includes digest" "$output" 'Session intent'
echo ""

# ── Summary ──
finish_tests
