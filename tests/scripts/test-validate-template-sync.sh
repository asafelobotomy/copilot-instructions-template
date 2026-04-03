#!/usr/bin/env bash
# tests/scripts/test-validate-template-sync.sh -- tests for scripts/ci/validate-template-sync.sh
# Run: bash tests/scripts/test-validate-template-sync.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/ci/validate-template-sync.sh"
trap cleanup_dirs EXIT

make_fixture() {
  local dir="$1"
  mkdir -p "$dir/template/hooks/scripts" "$dir/.github/hooks/scripts"
  mkdir -p "$dir/template/skills/test-skill" "$dir/.github/skills/test-skill"
  mkdir -p "$dir/template/instructions" "$dir/.github/instructions"
  mkdir -p "$dir/template/prompts" "$dir/.github/prompts"

  echo '{"hooks":[]}' > "$dir/template/hooks/copilot-hooks.json"
  cp "$dir/template/hooks/copilot-hooks.json" "$dir/.github/hooks/copilot-hooks.json"

  echo "#!/bin/bash" > "$dir/template/hooks/scripts/test.sh"
  cp "$dir/template/hooks/scripts/test.sh" "$dir/.github/hooks/scripts/test.sh"

  echo '{"retrospective":{"thresholds":{"modified_files":{"supporting":5,"strong":8}}}}' > "$dir/template/hooks/scripts/heartbeat-policy.json"
  cp "$dir/template/hooks/scripts/heartbeat-policy.json" "$dir/.github/hooks/scripts/heartbeat-policy.json"

  echo "print('hook helper')" > "$dir/template/hooks/scripts/helper.py"
  cp "$dir/template/hooks/scripts/helper.py" "$dir/.github/hooks/scripts/helper.py"

  echo "# Test Skill" > "$dir/template/skills/test-skill/SKILL.md"
  cp "$dir/template/skills/test-skill/SKILL.md" "$dir/.github/skills/test-skill/SKILL.md"

  echo "# API docs" > "$dir/template/instructions/api.instructions.md"
  cp "$dir/template/instructions/api.instructions.md" "$dir/.github/instructions/api.instructions.md"

  echo "Explain the current file." > "$dir/template/prompts/explain.prompt.md"
  cp "$dir/template/prompts/explain.prompt.md" "$dir/.github/prompts/explain.prompt.md"

  echo "Run {{TEST_COMMAND}}" > "$dir/template/prompts/test-gen.prompt.md"
  echo "Run bash tests/run-all.sh" > "$dir/.github/prompts/test-gen.prompt.md"
}

echo "=== validate-template-sync.sh ==="
echo ""

echo "1. In-sync fixture passes"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1)
status=$?
assert_success "check exits zero for synced fixture" "$status"
assert_contains "reports synced fixture" "$output" "in sync"
echo ""

echo "2. Drifted instruction mirror is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
echo "# changed" >> "$TMP/.github/instructions/api.instructions.md"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1) || true
assert_contains "instruction drift is reported" "$output" "api.instructions.md"
echo ""

echo "3. Drifted exact prompt mirror is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
echo "Explain this other file." > "$TMP/.github/prompts/explain.prompt.md"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1) || true
assert_contains "exact prompt drift is reported" "$output" "explain.prompt.md"
echo ""

echo "4. Placeholder-bearing prompt stubs are skipped"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1)
status=$?
assert_success "placeholder prompt drift does not fail" "$status"
echo ""

echo "5. Hook JSON companions are checked"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
echo '{"changed":true}' > "$TMP/.github/hooks/scripts/heartbeat-policy.json"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1) || true
assert_contains "hook JSON drift is reported" "$output" "heartbeat-policy.json"
echo ""

echo "6. Hook Python companions are checked"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
echo "print('changed helper')" > "$TMP/.github/hooks/scripts/helper.py"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1) || true
assert_contains "hook Python drift is reported" "$output" "helper.py"
echo ""

echo "7. Real repo is in sync"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" 2>&1)
status=$?
assert_success "real repo check exits zero" "$status"
assert_contains "real repo is reported in sync" "$output" "in sync"
echo ""

finish_tests