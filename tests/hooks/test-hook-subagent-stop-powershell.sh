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
output=$(run_ps_script "$SCRIPT" '{"agentName":"Explore-Agent_v2"}')
status=$?
assert_success "subagent-stop exits zero" "$status"
assert_valid_json "subagent-stop emits valid JSON" "$output"
assert_contains "hookEventName present" "$output" 'SubagentStop'
assert_contains "agent name is surfaced" "$output" 'Explore-Agent_v2'
assert_contains "completion guidance is included" "$output" 'Review results before continuing'
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
output=$(run_ps_script "$SCRIPT" '{"agentName":"Explore \"Quoted\""}')
status=$?
assert_success "quoted-name payload exits zero" "$status"
assert_valid_json "quoted-name payload stays valid JSON" "$output"
SUBAGENT_OUTPUT="$output" assert_python "quoted agent names survive JSON escaping" "payload = json.loads(os.environ['SUBAGENT_OUTPUT']); ctx = payload['hookSpecificOutput']['additionalContext']; assert 'Explore \"Quoted\"' in ctx"
echo ""

echo "5. Diary file is created when result exists"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
output=$(cd "$TMP" && printf '%s' '{"agentName":"Review","result":"Found unused import in auth.py"}' | "$PWSH" -NoLogo -NoProfile -File "$SCRIPT" 2>/dev/null)
status=$?
assert_success "diary-write exits zero" "$status"
assert_valid_json "diary-write emits valid JSON" "$output"
assert_file_exists "diary file created" "$TMP/.copilot/workspace/knowledge/diaries/review.md"
assert_file_contains "diary has agent header" "$TMP/.copilot/workspace/knowledge/diaries/review.md" '# Review Diary'
assert_file_contains "diary has result entry" "$TMP/.copilot/workspace/knowledge/diaries/review.md" 'Found unused import in auth.py'
echo ""

echo "6. Duplicate results are not written twice"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
cd "$TMP" || exit 1
printf '%s' '{"agentName":"Audit","result":"No secrets found"}' | "$PWSH" -NoLogo -NoProfile -File "$SCRIPT" >/dev/null 2>&1
printf '%s' '{"agentName":"Audit","result":"No secrets found"}' | "$PWSH" -NoLogo -NoProfile -File "$SCRIPT" >/dev/null 2>&1
DIARY="$TMP/.copilot/workspace/knowledge/diaries/audit.md"
MATCH_COUNT=$(grep -c 'No secrets found' "$DIARY")
if [[ "$MATCH_COUNT" -eq 1 ]]; then
	pass_note "duplicate dedup works (exactly 1 match)"
else
	fail_note "duplicate dedup failed" "     expected 1, got $MATCH_COUNT"
fi
cd "$REPO_ROOT" || exit 1
echo ""

echo "7. Empty result does not create diary file"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
output=$(cd "$TMP" && printf '%s' '{"agentName":"Fast","result":""}' | "$PWSH" -NoLogo -NoProfile -File "$SCRIPT" 2>/dev/null)
status=$?
assert_success "empty-result exits zero" "$status"
if [[ -f "$TMP/.copilot/workspace/knowledge/diaries/fast.md" ]]; then
	fail_note "empty result should not create diary file"
else
	pass_note "empty result does not create diary file"
fi
echo ""

echo "8. Diary respects 30-line cap"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
cd "$TMP" || exit 1
for i in $(seq 1 35); do
	printf '%s' "{\"agentName\":\"Code\",\"result\":\"Finding $i: item $i\"}" | "$PWSH" -NoLogo -NoProfile -File "$SCRIPT" >/dev/null 2>&1
done
DIARY="$TMP/.copilot/workspace/knowledge/diaries/code.md"
LINE_COUNT=$(wc -l < "$DIARY")
if (( LINE_COUNT <= 30 )); then
	pass_note "diary stays within 30-line cap (got $LINE_COUNT)"
else
	fail_note "diary exceeds 30-line cap" "     expected ≤30, got $LINE_COUNT"
fi
cd "$REPO_ROOT" || exit 1
echo ""

finish_tests