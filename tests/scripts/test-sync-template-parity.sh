#!/usr/bin/env bash
# tests/scripts/test-sync-template-parity.sh -- tests for scripts/sync/sync-template-parity.sh
# Run: bash tests/scripts/test-sync-template-parity.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/sync/sync-template-parity.sh"
trap cleanup_dirs EXIT

make_fixture() {
  local dir="$1"
  mkdir -p "$dir/template/hooks/scripts" "$dir/.github/hooks/scripts"
  mkdir -p "$dir/template/skills/test-skill" "$dir/.github/skills/test-skill"
  mkdir -p "$dir/template/instructions" "$dir/.github/instructions"
  mkdir -p "$dir/template/prompts" "$dir/.github/prompts"

  # Hooks: matching pair
  echo '{"hooks":[]}' > "$dir/template/hooks/copilot-hooks.json"
  cp "$dir/template/hooks/copilot-hooks.json" "$dir/.github/hooks/copilot-hooks.json"
  echo "#!/bin/bash" > "$dir/template/hooks/scripts/test.sh"
  cp "$dir/template/hooks/scripts/test.sh" "$dir/.github/hooks/scripts/test.sh"
  echo '{"retrospective":{"thresholds":{"modified_files":{"supporting":5,"strong":8}}}' > "$dir/template/hooks/scripts/heartbeat-policy.json"
  cp "$dir/template/hooks/scripts/heartbeat-policy.json" "$dir/.github/hooks/scripts/heartbeat-policy.json"
  echo "print('hook helper')" > "$dir/template/hooks/scripts/helper.py"
  cp "$dir/template/hooks/scripts/helper.py" "$dir/.github/hooks/scripts/helper.py"

  # Skills: matching pair
  echo "# Test Skill" > "$dir/template/skills/test-skill/SKILL.md"
  cp "$dir/template/skills/test-skill/SKILL.md" "$dir/.github/skills/test-skill/SKILL.md"

  # Instructions: no placeholders (verbatim mirror)
  echo "# API docs" > "$dir/template/instructions/api.instructions.md"
  cp "$dir/template/instructions/api.instructions.md" "$dir/.github/instructions/api.instructions.md"

  # Prompts: with placeholder (should be skipped)
  echo "Run {{TEST_COMMAND}}" > "$dir/template/prompts/test-gen.prompt.md"
  echo "Run bash tests/run-all.sh" > "$dir/.github/prompts/test-gen.prompt.md"
}

echo "=== sync-template-parity.sh ==="
echo ""

echo "1. Invalid mode is rejected"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" --wat 2>&1) || true
assert_contains "invalid mode prints usage" "$output" "Usage:"
echo ""

echo "2. In-sync fixture passes --check"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "check mode exits zero" "$status"
assert_contains "check mode prints OK" "$output" "in sync"
echo ""

echo "3. Drifted hook helper is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
echo "print('changed helper')" > "$TMP/.github/hooks/scripts/helper.py"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "drift detected in hook" "$output" "helper.py"
echo ""

echo "4. Drifted skill is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
echo "# changed" >> "$TMP/.github/skills/test-skill/SKILL.md"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "drift detected in skill" "$output" "test-skill"
echo ""

echo "5. Template with placeholder tokens is skipped"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
# The prompt has {{}} in template, different in .github — should NOT be flagged
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "placeholder file is skipped" "$status"
echo ""

echo "6. --write repairs drifted files"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
echo '{"changed":true}' > "$TMP/.github/hooks/scripts/heartbeat-policy.json"
echo "# changed" >> "$TMP/.github/skills/test-skill/SKILL.md"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --write 2>&1)
status=$?
assert_success "--write exits zero" "$status"
assert_contains "reports repaired hook" "$output" "heartbeat-policy.json"
assert_contains "reports repaired skill" "$output" "test-skill"
# Verify --check now passes
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "check passes after write" "$status"
echo ""

echo "7. Idempotency — second --write is a no-op"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --write 2>&1)
assert_contains "already in sync" "$output" "in sync"
echo ""

echo "8. Real repo is in sync"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "real repo check exits zero" "$status"
assert_contains "real repo in sync" "$output" "in sync"
echo ""

echo "9. mcp-management divergence is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
mkdir -p "$TMP/template/skills/mcp-management" "$TMP/.github/skills/mcp-management"
echo "# template version" > "$TMP/template/skills/mcp-management/SKILL.md"
echo "# developer version (intentionally different)" > "$TMP/.github/skills/mcp-management/SKILL.md"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "mcp-management drift detected" "$output" "mcp-management"
echo ""

echo "10. Missing hook script is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
rm "$TMP/.github/hooks/scripts/test.sh"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "missing hook script detected" "$output" "test.sh"
echo ""

echo "11. Missing skill mirror is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
rm "$TMP/.github/skills/test-skill/SKILL.md"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "missing skill detected" "$output" "test-skill"
echo ""

echo "12. --write creates missing files"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
rm "$TMP/.github/hooks/scripts/test.sh"
rm "$TMP/.github/skills/test-skill/SKILL.md"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --write 2>&1)
status=$?
assert_success "--write exits zero for missing files" "$status"
assert_contains "reports created hook" "$output" "test.sh"
assert_contains "reports created skill" "$output" "test-skill"
# Verify --check now passes
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "check passes after write creates missing" "$status"
echo ""

finish_tests
