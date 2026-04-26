#!/usr/bin/env bash
# tests/hooks/test-hook-subagent-stop-powershell.sh -- unit tests for subagent-stop.ps1
# Run: bash tests/hooks/test-hook-subagent-stop-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/powershell-hook-test-helpers.sh
source "$(dirname "$0")/../lib/powershell-hook-test-helpers.sh"
init_powershell_hook_test_context "$0"
trap cleanup_dirs EXIT
ensure_pwsh_available
SCRIPT="$SCRIPTS_DIR/subagent-stop.ps1"

echo "=== subagent-stop.ps1 (PowerShell) unit tests ==="
echo ""

echo "1. Named subagents receive completion context"
output=$(run_ps_script "$SCRIPT" '{"agent_type":"Explore-Agent_v2"}')
status=$?
assert_success "subagent-stop exits zero" "$status"
assert_valid_json "subagent-stop emits valid JSON" "$output"
assert_contains "hookEventName present" "$output" 'SubagentStop'
assert_contains "agent name is surfaced" "$output" 'Explore-Agent_v2'
assert_contains "completion guidance is included" "$output" 'Review next step'
echo ""

echo "2. Missing agent names fall back to unknown"
output=$(run_ps_script "$SCRIPT" '{}')
status=$?
assert_success "missing-name payload exits zero" "$status"
assert_valid_json "missing-name payload stays valid JSON" "$output"
assert_contains "missing agent names use unknown" "$output" 'unknown'
echo ""

echo "3. Malformed JSON falls back to unknown without crashing"
output=$(run_ps_script "$SCRIPT" 'not-json')
status=$?
assert_success "malformed payload exits zero" "$status"
assert_valid_json "malformed payload still emits valid JSON" "$output"
assert_contains "malformed payload uses unknown" "$output" 'unknown'
echo ""

echo "4. Quoted agent names remain JSON-safe"
output=$(run_ps_script "$SCRIPT" '{"agent_type":"Explore \"Quoted\""}')
status=$?
assert_success "quoted-name payload exits zero" "$status"
assert_valid_json "quoted-name payload stays valid JSON" "$output"
SUBAGENT_OUTPUT="$output" assert_python "quoted agent names survive JSON escaping" "payload = json.loads(os.environ['SUBAGENT_OUTPUT']); ctx = payload['hookSpecificOutput']['additionalContext']; assert 'Explore \"Quoted\"' in ctx"
echo ""

finish_tests