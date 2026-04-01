#!/usr/bin/env bash
# tests/hooks/test-hooks-powershell.sh -- unit tests for PowerShell hook scripts
# Run: bash tests/hooks/test-hooks-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPTS_DIR="$REPO_ROOT/template/hooks/scripts"
PWSH=$(command -v pwsh || true)
trap cleanup_dirs EXIT

if [[ -z "$PWSH" ]]; then
  echo "pwsh is required for tests/hooks/test-hooks-powershell.sh"
  exit 1
fi

run_ps_script() {
  local script_path="$1" payload="$2"
  shift 2
  if [[ -n "${PWSH_COVERAGE_TRACE:-}" ]]; then
    if [[ $# -eq 0 ]]; then
      printf '%s' "$payload" | "$PWSH" -NoLogo -NoProfile -File "$REPO_ROOT/tests/coverage/invoke-powershell-with-coverage.ps1" -ScriptPath "$script_path" -TracePath "$PWSH_COVERAGE_TRACE" 2>/dev/null
      return
    fi
    # Coverage wrapper supports only ScriptPath/TracePath, so run direct when args are needed.
    printf '%s' "$payload" | "$PWSH" -NoLogo -NoProfile -File "$script_path" "$@" 2>/dev/null
    return
  fi

  printf '%s' "$payload" | "$PWSH" -NoLogo -NoProfile -File "$script_path" "$@" 2>/dev/null
}

echo "=== PowerShell hook script unit tests ==="
echo ""

SESSION_START="$SCRIPTS_DIR/session-start.ps1"
POST_LINT="$SCRIPTS_DIR/post-edit-lint.ps1"
SAVE_CTX="$SCRIPTS_DIR/save-context.ps1"
PULSE="$SCRIPTS_DIR/pulse.ps1"

echo "1. session-start.ps1 returns valid SessionStart JSON"
output=$(run_ps_script "$SESSION_START" '{}')
status=$?
assert_success "session-start exits zero" "$status"
assert_valid_json "session-start emits valid JSON" "$output"
assert_contains "session-start hookEventName present" "$output" "SessionStart"
assert_contains "session-start includes branch context" "$output" "Branch:"
echo ""

echo "2. session-start.ps1 detects project manifests"
TMP_NPM=$(mktemp -d); CLEANUP_DIRS+=("$TMP_NPM")
printf '{"name":"pwsh-project","version":"1.2.3"}\n' > "$TMP_NPM/package.json"
output=$(cd "$TMP_NPM" && run_ps_script "$SESSION_START" '{}')
assert_contains "package.json name is surfaced" "$output" "pwsh-project"
assert_contains "package.json version is surfaced" "$output" "1.2.3"
echo ""

echo "2a. pulse.ps1 initializes heartbeat sentinel on session_start"
TMP_SENT_START=$(mktemp -d); CLEANUP_DIRS+=("$TMP_SENT_START")
mkdir -p "$TMP_SENT_START/.copilot/workspace"
output=$(cd "$TMP_SENT_START" && run_ps_script "$PULSE" '{"sessionId":"ps-sess-1"}' -Trigger session_start)
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

echo "3. post-edit-lint.ps1 safely passes through non-edit and malformed input"
output=$(run_ps_script "$POST_LINT" '{"tool_name":"read_file","tool_input":{}}')
status=$?
assert_success "post-edit-lint non-edit exits zero" "$status"
assert_contains "post-edit-lint non-edit continues" "$output" '"continue": true'
output=$(run_ps_script "$POST_LINT" 'not-json')
status=$?
assert_success "post-edit-lint malformed JSON exits zero" "$status"
assert_contains "post-edit-lint malformed JSON continues" "$output" '"continue": true'
echo ""

echo "4. post-edit-lint.ps1 accepts edit tool payloads with filePath"
TMP_FILE=$(mktemp); CLEANUP_DIRS+=("$TMP_FILE")
output=$(run_ps_script "$POST_LINT" "{\"tool_name\":\"edit_file\",\"tool_input\":{\"filePath\":\"$TMP_FILE\"}}")
status=$?
assert_success "post-edit-lint edit payload exits zero" "$status"
assert_contains "post-edit-lint edit payload continues" "$output" '"continue": true'
echo ""

echo "6b. pulse.ps1 continues for small tasks"
TMP_SMALL_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_SMALL_PULSE")
mkdir -p "$TMP_SMALL_PULSE/.copilot/workspace"
cd "$TMP_SMALL_PULSE" && run_ps_script "$PULSE" '{"sessionId":"ps-sess-small"}' -Trigger session_start >/dev/null
output=$(cd "$TMP_SMALL_PULSE" && run_ps_script "$PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "pulse small stop continues" "$output" '"continue":true'
assert_python_in_root "powershell small stop records retrospective not-needed" "$TMP_SMALL_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "6c. pulse.ps1 skips retrospective for borderline file churn"
TMP_BORDERLINE_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_BORDERLINE_PULSE")
printf '.copilot/\n' >> "$TMP_BORDERLINE_PULSE/.git/info/exclude"
mkdir -p "$TMP_BORDERLINE_PULSE/.copilot/workspace"
cd "$TMP_BORDERLINE_PULSE" && run_ps_script "$PULSE" '{"sessionId":"ps-sess-borderline"}' -Trigger session_start >/dev/null
for i in 1 2 3 4 5; do
  printf 'change %s\n' "$i" > "$TMP_BORDERLINE_PULSE/ps-borderline-$i.txt"
done
output=$(cd "$TMP_BORDERLINE_PULSE" && run_ps_script "$PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "pulse borderline stop continues" "$output" '"continue":true'
assert_python_in_root "powershell borderline stop records retrospective not-needed" "$TMP_BORDERLINE_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "not-needed"
'
echo ""

echo "6d. pulse.ps1 asks before retrospective on strong signals"
TMP_BLOCK_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_BLOCK_PULSE")
printf '.copilot/\n' >> "$TMP_BLOCK_PULSE/.git/info/exclude"
mkdir -p "$TMP_BLOCK_PULSE/.copilot/workspace"
cd "$TMP_BLOCK_PULSE" && run_ps_script "$PULSE" '{"sessionId":"ps-sess-2"}' -Trigger session_start >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMP_BLOCK_PULSE/ps-file-$i.txt"
done
output=$(cd "$TMP_BLOCK_PULSE" && run_ps_script "$PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "pulse large stop blocks" "$output" '"decision":"block"'
assert_contains "pulse large stop asks user question" "$output" 'would you like me to run a retrospective'
assert_python_in_root "powershell large stop records retrospective suggested" "$TMP_BLOCK_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "suggested"
'
echo ""

echo "6e. user can decline a suggested retrospective"
output=$(cd "$TMP_BLOCK_PULSE" && run_ps_script "$PULSE" '{"prompt":"No thanks"}' -Trigger user_prompt)
assert_contains "decline prompt continues" "$output" '"continue":true'
assert_python_in_root "powershell decline updates retrospective state" "$TMP_BLOCK_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "declined"
'
output=$(cd "$TMP_BLOCK_PULSE" && run_ps_script "$PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "declined stop continues" "$output" '"continue":true'
echo ""

echo "6f. user can accept a suggested retrospective"
TMP_ACCEPT_PULSE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_ACCEPT_PULSE")
printf '.copilot/\n' >> "$TMP_ACCEPT_PULSE/.git/info/exclude"
mkdir -p "$TMP_ACCEPT_PULSE/.copilot/workspace"
cd "$TMP_ACCEPT_PULSE" && run_ps_script "$PULSE" '{"sessionId":"ps-sess-accept"}' -Trigger session_start >/dev/null
for i in 1 2 3 4 5 6 7 8; do
  printf 'change %s\n' "$i" > "$TMP_ACCEPT_PULSE/ps-accept-$i.txt"
done
cd "$TMP_ACCEPT_PULSE" && run_ps_script "$PULSE" '{"stop_hook_active": false}' -Trigger stop >/dev/null
output=$(cd "$TMP_ACCEPT_PULSE" && run_ps_script "$PULSE" '{"prompt":"Yes please"}' -Trigger user_prompt)
assert_contains "accept prompt continues" "$output" '"continue":true'
assert_python_in_root "powershell accept updates retrospective state" "$TMP_ACCEPT_PULSE" '
state = json.loads((root / ".copilot/workspace/state.json").read_text(encoding="utf-8"))
assert state["retrospective_state"] == "accepted"
'
output=$(cd "$TMP_ACCEPT_PULSE" && run_ps_script "$PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "accepted stop blocks for retrospective" "$output" '"decision":"block"'
assert_contains "accepted stop explains retrospective run" "$output" 'The user agreed to a retrospective'
echo ""

echo "6g. pulse.ps1 records duration and UTC timestamp when stop completes"
TMP_DONE_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_DONE_PULSE")
mkdir -p "$TMP_DONE_PULSE/.copilot/workspace"
cd "$TMP_DONE_PULSE" && run_ps_script "$PULSE" '{"sessionId":"ps-sess-3"}' -Trigger session_start >/dev/null
printf 'ps-sess-3|2026-03-30T00:00:00Z|complete\n' > "$TMP_DONE_PULSE/.copilot/workspace/.heartbeat-session"
output=$(cd "$TMP_DONE_PULSE" && run_ps_script "$PULSE" '{"stop_hook_active": false}' -Trigger stop)
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

echo "7. save-context.ps1 emits JSON and includes workspace summaries when present"
TMP_CTX=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CTX")
mkdir -p "$TMP_CTX/.copilot/workspace"
printf 'HEARTBEAT_OK\n' > "$TMP_CTX/.copilot/workspace/HEARTBEAT.md"
printf 'recent memory entry\n' > "$TMP_CTX/.copilot/workspace/MEMORY.md"
printf 'heuristic: verify before commit\n' > "$TMP_CTX/.copilot/workspace/SOUL.md"
output=$(cd "$TMP_CTX" && run_ps_script "$SAVE_CTX" '{}')
status=$?
assert_success "save-context exits zero" "$status"
assert_valid_json "save-context emits valid JSON" "$output"
assert_contains "save-context hookEventName present" "$output" "PreCompact"
assert_contains "save-context includes heartbeat" "$output" "HEARTBEAT_OK"
assert_contains "save-context includes memory summary" "$output" "recent memory entry"
assert_contains "save-context includes heuristics summary" "$output" "verify before commit"
echo ""

echo "8. save-context.ps1 includes clock summary when timing files exist"
TMP_CTX_CLOCK=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CTX_CLOCK")
mkdir -p "$TMP_CTX_CLOCK/.copilot/workspace"
printf 'HEARTBEAT_OK\n' > "$TMP_CTX_CLOCK/.copilot/workspace/HEARTBEAT.md"
cat > "$TMP_CTX_CLOCK/.copilot/workspace/state.json" <<'EOF'
{
  "session_id": "ps-clock",
  "session_state": "pending",
  "session_start_epoch": 1704067200
}
EOF
cat > "$TMP_CTX_CLOCK/.copilot/workspace/.heartbeat-events.jsonl" <<'EOF'
{"detail":"complete","duration_s":125,"trigger":"stop","ts":1704067325,"ts_utc":"2024-01-01T00:02:05Z"}
{"detail":"complete","duration_s":185,"trigger":"stop","ts":1704067485,"ts_utc":"2024-01-01T00:04:45Z"}
EOF
output=$(cd "$TMP_CTX_CLOCK" && run_ps_script "$SAVE_CTX" '{}')
assert_contains "save-context includes clock summary" "$output" "Clock:"
assert_contains "save-context includes active session id" "$output" "ps-clock"
assert_contains "save-context includes last completion UTC timestamp" "$output" "2024-01-01T00:04:45Z"
assert_contains "save-context includes median wording" "$output" "median of 2"
echo ""

finish_tests
