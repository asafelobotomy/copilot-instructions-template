#!/usr/bin/env bash
# tests/test-sync-template-parity.sh -- tests for scripts/sync-template-parity.sh
# Run: bash tests/test-sync-template-parity.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/sync-template-parity.sh"

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
TMP=$(mktemp -d)
make_fixture "$TMP"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "check mode exits zero" "$status"
assert_contains "check mode prints OK" "$output" "in sync"
rm -rf "$TMP"
echo ""

echo "3. Drifted hook script is detected"
TMP=$(mktemp -d)
make_fixture "$TMP"
echo "# changed" >> "$TMP/.github/hooks/scripts/test.sh"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "drift detected in hook" "$output" "test.sh"
rm -rf "$TMP"
echo ""

echo "4. Drifted skill is detected"
TMP=$(mktemp -d)
make_fixture "$TMP"
echo "# changed" >> "$TMP/.github/skills/test-skill/SKILL.md"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "drift detected in skill" "$output" "test-skill"
rm -rf "$TMP"
echo ""

echo "5. Template with placeholder tokens is skipped"
TMP=$(mktemp -d)
make_fixture "$TMP"
# The prompt has {{}} in template, different in .github — should NOT be flagged
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "placeholder file is skipped" "$status"
rm -rf "$TMP"
echo ""

echo "6. --write repairs drifted files"
TMP=$(mktemp -d)
make_fixture "$TMP"
echo "# changed" >> "$TMP/.github/hooks/scripts/test.sh"
echo "# changed" >> "$TMP/.github/skills/test-skill/SKILL.md"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --write 2>&1)
status=$?
assert_success "--write exits zero" "$status"
assert_contains "reports repaired hook" "$output" "test.sh"
assert_contains "reports repaired skill" "$output" "test-skill"
# Verify --check now passes
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "check passes after write" "$status"
rm -rf "$TMP"
echo ""

echo "7. Idempotency — second --write is a no-op"
TMP=$(mktemp -d)
make_fixture "$TMP"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --write 2>&1)
assert_contains "already in sync" "$output" "in sync"
rm -rf "$TMP"
echo ""

echo "8. Real repo is in sync"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "real repo check exits zero" "$status"
assert_contains "real repo in sync" "$output" "in sync"
echo ""

echo "9. mcp-management divergence is not flagged"
TMP=$(mktemp -d)
make_fixture "$TMP"
mkdir -p "$TMP/template/skills/mcp-management" "$TMP/.github/skills/mcp-management"
echo "# template version" > "$TMP/template/skills/mcp-management/SKILL.md"
echo "# developer version (intentionally different)" > "$TMP/.github/skills/mcp-management/SKILL.md"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "mcp-management divergence allowed" "$status"
rm -rf "$TMP"
echo ""

finish_tests
