#!/usr/bin/env bash
# tests/scripts/test-validate-attention-budget.sh -- tests for scripts/ci/validate-attention-budget.sh
# Run: bash tests/scripts/test-validate-attention-budget.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/ci/validate-attention-budget.sh"
trap cleanup_dirs EXIT

write_template() {
  local file="$1"
  shift
  local counts=("$@")
  mkdir -p "$(dirname "$file")"
  : > "$file"

  local section line_count line_number
  for section in $(seq 1 14); do
    line_count="${counts[$((section - 1))]}"
    printf '## §%s — Section %s\n' "$section" "$section" >> "$file"
    for line_number in $(seq 1 "$line_count"); do
      printf 'Line %s.%s\n' "$section" "$line_number" >> "$file"
    done
    printf '\n' >> "$file"
  done
}

echo "=== validate-attention-budget.sh ==="
echo ""

echo "1. Within-budget fixture passes"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
write_template "$TMP/template/copilot-instructions.md" 5 5 5 5 5 5 5 5 5 5 5 5 5 5
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1)
status=$?
assert_success "within-budget fixture exits zero" "$status"
assert_contains "within-budget fixture reports success" "$output" "Attention budget OK"
echo ""

echo "2. Oversized regular section is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
write_template "$TMP/template/copilot-instructions.md" 130 5 5 5 5 5 5 5 5 5 5 5 5 5
if output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "oversized regular section exits non-zero" "$status"
assert_contains "oversized regular section is reported" "$output" "§1 is"
echo ""

echo "3. Oversized §10 remains exempt"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
write_template "$TMP/template/copilot-instructions.md" 5 5 5 5 5 5 5 5 5 250 5 5 5 5
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1)
status=$?
assert_success "oversized §10 still exits zero" "$status"
assert_contains "oversized §10 still reports success" "$output" "Attention budget OK"
echo ""

echo "4. Oversized total file is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
write_template "$TMP/template/copilot-instructions.md" 65 65 65 65 65 65 65 65 65 65 65 65 65 65
if output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "oversized total file exits non-zero" "$status"
assert_contains "oversized total file is reported" "$output" "File exceeds 800-line budget"
echo ""

echo "5. Real repo passes integration"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" 2>&1)
status=$?
assert_success "real repo exits zero" "$status"
assert_contains "real repo reports success" "$output" "Attention budget OK"
echo ""

finish_tests