#!/usr/bin/env bash
# tests/test-sync-llms-context.sh -- direct tests for scripts/sync-llms-context.sh
# Run: bash tests/test-sync-llms-context.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/sync-llms-context.sh"

make_fixture() {
  local root="$1"
  mkdir -p "$root/.copilot/workspace"
  printf '9.9.9\n' > "$root/VERSION.md"
  cat > "$root/.copilot/workspace/DOC_INDEX.json" <<'EOF'
{
  "schemaVersion": "1.0",
  "updated": "2026-03-06",
  "purpose": "Canonical machine-readable inventory for repository documentation metadata.",
  "counts": {
    "agents": 6,
    "skillsRepo": 13,
    "skillsTemplate": 13,
    "hookScriptsShell": 5,
    "hookScriptsPowerShell": 5,
    "guides": 14
  },
  "agents": [],
  "skills": {
    "repo": [],
    "template": []
  },
  "hookScripts": {
    "shell": [],
    "powershell": []
  },
  "guides": [],
  "notes": []
}
EOF
}

echo "=== sync-llms-context.sh direct tests ==="
echo ""

echo "1. Invalid mode is rejected"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" --wat 2>&1)
status=$?
assert_failure "invalid mode exits non-zero" "$status"
assert_contains "invalid mode prints usage" "$output" "Usage: bash scripts/sync-llms-context.sh"
echo ""

echo "2. Write mode creates both context packs"
TMP_WRITE=$(mktemp -d)
make_fixture "$TMP_WRITE"
output=$(ROOT_DIR="$TMP_WRITE" bash "$SCRIPT" --write 2>&1)
status=$?
assert_success "write mode exits zero" "$status"
assert_contains "compact context written" "$output" "OK: wrote $TMP_WRITE/llms-ctx.txt"
assert_contains "expanded context written" "$output" "OK: wrote $TMP_WRITE/llms-ctx-full.txt"
assert_contains "compact pack has version" "$(cat "$TMP_WRITE/llms-ctx.txt")" "Version: 9.9.9"
assert_contains "compact pack has agent count" "$(cat "$TMP_WRITE/llms-ctx.txt")" "Agents: 6 model-pinned files"
assert_contains "compact pack has skill count" "$(cat "$TMP_WRITE/llms-ctx.txt")" "Skills: 13 workflow skills"
assert_contains "compact pack keeps GPT-5.4 guidance" "$(cat "$TMP_WRITE/llms-ctx.txt")" "GPT-5.4"
assert_contains "expanded pack mentions test-coverage-review" "$(cat "$TMP_WRITE/llms-ctx-full.txt")" "test-coverage-review"
assert_contains "expanded pack mentions sync command" "$(cat "$TMP_WRITE/llms-ctx-full.txt")" "bash scripts/sync-llms-context.sh --check"
echo ""

echo "3. Check mode passes when generated files are in sync"
output=$(ROOT_DIR="$TMP_WRITE" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "check mode exits zero" "$status"
assert_contains "compact pack reported in sync" "$output" "OK: llms-ctx.txt is in sync"
assert_contains "expanded pack reported in sync" "$output" "OK: llms-ctx-full.txt is in sync"
echo ""

echo "4. Drift in either output file is detected"
printf 'tampered\n' > "$TMP_WRITE/llms-ctx.txt"
output=$(ROOT_DIR="$TMP_WRITE" bash "$SCRIPT" --check 2>&1)
status=$?
assert_failure "check mode fails on compact drift" "$status"
assert_contains "compact drift message is printed" "$output" "FAIL: llms-ctx.txt is out of sync"
echo ""

echo "5. Write mode repairs drift and restores deterministic output"
output=$(ROOT_DIR="$TMP_WRITE" bash "$SCRIPT" --write 2>&1)
status=$?
assert_success "write mode repairs compact drift" "$status"
output=$(ROOT_DIR="$TMP_WRITE" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "check passes after repair" "$status"
echo ""

echo "6. Missing generated file is treated as out of sync"
rm -f "$TMP_WRITE/llms-ctx-full.txt"
output=$(ROOT_DIR="$TMP_WRITE" bash "$SCRIPT" --check 2>&1)
status=$?
assert_failure "missing expanded pack fails check" "$status"
assert_contains "missing file shows out-of-sync message" "$output" "FAIL: llms-ctx-full.txt is out of sync"
rm -rf "$TMP_WRITE"
echo ""

finish_tests
