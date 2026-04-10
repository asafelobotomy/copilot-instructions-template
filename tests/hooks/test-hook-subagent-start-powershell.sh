#!/usr/bin/env bash
# tests/hooks/test-hook-subagent-start-powershell.sh -- unit tests for subagent-start.ps1
# Run: bash tests/hooks/test-hook-subagent-start-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/powershell-hook-test-helpers.sh
source "$(dirname "$0")/../lib/powershell-hook-test-helpers.sh"
init_powershell_hook_test_context "$0"
trap cleanup_dirs EXIT
ensure_pwsh_available
SCRIPT="$SCRIPTS_DIR/subagent-start.ps1"

echo "=== subagent-start.ps1 (PowerShell) unit tests ==="
echo ""

echo "1. Named subagents receive governance context"
output=$(run_ps_script "$SCRIPT" '{"agentName":"Review-Agent_v2"}')
status=$?
assert_success "subagent-start exits zero" "$status"
assert_valid_json "subagent-start emits valid JSON" "$output"
assert_contains "hookEventName present" "$output" 'SubagentStart'
assert_contains "agent name is surfaced" "$output" 'Review-Agent_v2'
assert_contains "governance context mentions inherited protocols" "$output" 'Tool Protocol'
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
output=$(run_ps_script "$SCRIPT" '{"agentName":"Review \"Quoted\""}')
status=$?
assert_success "quoted-name payload exits zero" "$status"
assert_valid_json "quoted-name payload stays valid JSON" "$output"
SUBAGENT_OUTPUT="$output" assert_python "quoted agent names survive JSON escaping" "payload = json.loads(os.environ['SUBAGENT_OUTPUT']); ctx = payload['hookSpecificOutput']['additionalContext']; assert 'Review \"Quoted\"' in ctx"
echo ""

echo "5. Diary injection when diary file exists"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/.copilot/workspace/diaries"
printf '# Explore Diary\n\n- 2026-01-01T00:00:00Z Found auth bug in handler\n- 2026-01-02T00:00:00Z Refactored cache layer\n' > "$TMP/.copilot/workspace/diaries/explore.md"
output=$(cd "$TMP" && printf '%s' '{"agentName":"Explore"}' | "$PWSH" -NoLogo -NoProfile -File "$SCRIPT" 2>/dev/null)
status=$?
assert_success "diary injection exits zero" "$status"
assert_valid_json "diary injection emits valid JSON" "$output"
assert_contains "diary content injected" "$output" 'Found auth bug'
assert_contains "diary includes multiple entries" "$output" 'Refactored cache layer'
echo ""

echo "6. No diary file produces no diary context"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
output=$(cd "$TMP" && printf '%s' '{"agentName":"Code"}' | "$PWSH" -NoLogo -NoProfile -File "$SCRIPT" 2>/dev/null)
status=$?
assert_success "no-diary exits zero" "$status"
assert_valid_json "no-diary emits valid JSON" "$output"
if printf '%s' "$output" | grep -q 'Recent diary entries'; then
	fail_note "no-diary should not mention diary entries"
else
	pass_note "no-diary has no diary entries mention"
fi
echo ""

finish_tests