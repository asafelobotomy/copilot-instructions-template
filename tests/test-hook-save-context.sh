#!/usr/bin/env bash
# tests/test-hook-save-context.sh -- unit tests for template/hooks/scripts/save-context.sh
# Run: bash tests/test-hook-save-context.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/template/hooks/scripts/save-context.sh"

echo "=== save-context.sh ==="
echo ""

echo "1. Output is valid JSON"
output=$(echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_success "exits 0" $?
assert_valid_json "valid JSON output" "$output"
echo ""

echo "2. Output contains hookEventName=PreCompact"
assert_matches "hookEventName present" "$output" "PreCompact"
echo ""

echo "3. HEARTBEAT.md content appears in additionalContext when present"
TMPDIR_CTX=$(mktemp -d)
mkdir -p "$TMPDIR_CTX/.copilot/workspace"
printf 'HEARTBEAT_OK - all checks pass\n' > "$TMPDIR_CTX/.copilot/workspace/HEARTBEAT.md"
output=$(cd "$TMPDIR_CTX" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "heartbeat pulse in context" "$output" "HEARTBEAT"
rm -rf "$TMPDIR_CTX"
echo ""

echo "4. No workspace files does not crash"
TMPDIR_EMPTY=$(mktemp -d)
(
  cd "$TMPDIR_EMPTY"
  echo '{}' | bash "$SCRIPT" 2>/dev/null
)
assert_success "no workspace files" $?
rm -rf "$TMPDIR_EMPTY"
echo ""

echo "5. MEMORY.md recent entries appear in additionalContext"
TMPDIR_MEM=$(mktemp -d)
mkdir -p "$TMPDIR_MEM/.copilot/workspace"
printf 'HEARTBEAT: ok\n' > "$TMPDIR_MEM/.copilot/workspace/HEARTBEAT.md"
printf 'Learned: always prefer small commits over large ones.\n' > "$TMPDIR_MEM/.copilot/workspace/MEMORY.md"
output=$(cd "$TMPDIR_MEM" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "MEMORY content in context" "$output" "small commits"
assert_valid_json "valid JSON with MEMORY.md" "$output"
rm -rf "$TMPDIR_MEM"
echo ""

echo "6. SOUL.md heuristics appear in additionalContext"
TMPDIR_SOUL=$(mktemp -d)
mkdir -p "$TMPDIR_SOUL/.copilot/workspace"
printf 'HEARTBEAT: ok\n' > "$TMPDIR_SOUL/.copilot/workspace/HEARTBEAT.md"
printf '## Key heuristics\npattern: test before committing\n' > "$TMPDIR_SOUL/.copilot/workspace/SOUL.md"
output=$(cd "$TMPDIR_SOUL" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "SOUL heuristics in context" "$output" "test before committing"
assert_valid_json "valid JSON with SOUL.md" "$output"
rm -rf "$TMPDIR_SOUL"
echo ""

echo "7. Workspace summaries include additionalContext key"
TMPDIR_KEYS=$(mktemp -d)
mkdir -p "$TMPDIR_KEYS/.copilot/workspace"
printf 'HEARTBEAT: running\n' > "$TMPDIR_KEYS/.copilot/workspace/HEARTBEAT.md"
output=$(cd "$TMPDIR_KEYS" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "additionalContext key present" "$output" "additionalContext"
assert_matches "PreCompact hookEventName present" "$output" "PreCompact"
rm -rf "$TMPDIR_KEYS"

finish_tests
