#!/usr/bin/env bash
# tests/hooks/test-hook-subagent-start.sh -- unit tests for subagent-start.sh
# Run: bash tests/hooks/test-hook-subagent-start.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/hooks/scripts/subagent-start.sh"

echo "=== subagent-start.sh ==="
echo ""

echo "1. Named subagents receive governance context"
output=$(printf '%s' '{"agent_type":"Review-Agent_v2"}' | bash "$SCRIPT" 2>/dev/null)
status=$?
assert_success "subagent-start exits zero" "$status"
assert_valid_json "subagent-start emits valid JSON" "$output"
assert_contains "hookEventName present" "$output" 'SubagentStart'
assert_contains "agent name is surfaced" "$output" 'Review-Agent_v2'
assert_contains "governance context mentions protocols" "$output" 'PDCA, Tool, Skill'
echo ""

echo "2. Missing agent names fall back to unknown"
output=$(printf '%s' '{}' | bash "$SCRIPT" 2>/dev/null)
status=$?
assert_success "missing-name payload exits zero" "$status"
assert_valid_json "missing-name payload stays valid JSON" "$output"
assert_contains "missing agent names use unknown" "$output" 'unknown'
echo ""

echo "3. Malformed JSON falls back to unknown without crashing"
output=$(printf '%s' 'not-json' | bash "$SCRIPT" 2>/dev/null)
status=$?
assert_success "malformed payload exits zero" "$status"
assert_valid_json "malformed payload still emits valid JSON" "$output"
assert_contains "malformed payload uses unknown" "$output" 'unknown'
echo ""

echo "4. Quoted agent names remain JSON-safe"
payload='{"agent_type":"Review \"Quoted\""}'
output=$(printf '%s' "$payload" | bash "$SCRIPT" 2>/dev/null)
status=$?
assert_success "quoted-name payload exits zero" "$status"
assert_valid_json "quoted-name payload stays valid JSON" "$output"
SUBAGENT_OUTPUT="$output" assert_python "quoted agent names survive JSON escaping" "payload = json.loads(os.environ['SUBAGENT_OUTPUT']); ctx = payload['hookSpecificOutput']['additionalContext']; assert 'Review \"Quoted\"' in ctx"
echo ""

echo "5. Governance context includes protocol keywords"
output=$(printf '%s' '{"agent_type":"Explore"}' | bash "$SCRIPT" 2>/dev/null)
status=$?
assert_success "hint-check exits zero" "$status"
assert_valid_json "hint-check emits valid JSON" "$output"
assert_contains "context includes PDCA keyword" "$output" 'PDCA'
echo ""

finish_tests