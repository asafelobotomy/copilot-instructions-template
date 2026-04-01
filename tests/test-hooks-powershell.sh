#!/usr/bin/env bash
# tests/test-hooks-powershell.sh -- unit tests for PowerShell hook scripts
# Run: bash tests/test-hooks-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"
SCRIPTS_DIR="$REPO_ROOT/template/hooks/scripts"
PWSH=$(command -v pwsh || true)
trap cleanup_dirs EXIT

if [[ -z "$PWSH" ]]; then
  echo "pwsh is required for tests/test-hooks-powershell.sh"
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
sentinel=$(cat "$TMP_SENT_START/.copilot/workspace/.heartbeat-session" 2>/dev/null)
assert_contains "powershell sentinel contains session id" "$sentinel" "ps-sess-1"
assert_contains "powershell sentinel starts pending" "$sentinel" "pending"
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

echo "6b. pulse.ps1 blocks stop when retrospective is incomplete"
TMP_BLOCK_PULSE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_BLOCK_PULSE")
mkdir -p "$TMP_BLOCK_PULSE/.copilot/workspace"
output=$(cd "$TMP_BLOCK_PULSE" && run_ps_script "$PULSE" '{"stop_hook_active": false}' -Trigger stop)
assert_contains "pulse stop blocks" "$output" '"decision":"block"'
echo ""

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

finish_tests
