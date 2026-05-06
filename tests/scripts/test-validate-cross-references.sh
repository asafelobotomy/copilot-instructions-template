#!/usr/bin/env bash
# tests/scripts/test-validate-cross-references.sh -- tests for scripts/ci/validate-cross-references.sh
# Run: bash tests/scripts/test-validate-cross-references.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/ci/validate-cross-references.sh"
trap cleanup_dirs EXIT

write_sections() {
  local file="$1" max_section="$2"
  : > "$file"
  local section
  for section in $(seq 1 "$max_section"); do
    printf '## §%s — Section %s\n\nBody text.\n\n' "$section" "$section" >> "$file"
  done
}

make_fixture() {
  local dir="$1"
  mkdir -p "$dir/template"
  write_sections "$dir/template/copilot-instructions.md" 14
}

echo "=== validate-cross-references.sh ==="
echo ""

echo "1. Consistent references pass"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1)
status=$?
assert_success "consistent fixture exits zero" "$status"
assert_contains "consistent fixture reports success" "$output" "Cross-references consistent"
echo ""

echo "2. Stale section range is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
printf 'See §1-§12 for the full section set.\n' > "$TMP/README.md"
if output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "stale section range exits non-zero" "$status"
assert_contains "stale section range is reported" "$output" "Stale section range"
assert_contains "stale section path is reported" "$output" "README.md"
echo ""

echo "3. Stale numbered-section prose is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
printf 'This template has twelve numbered sections.\n' > "$TMP/README.md"
if output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "stale numbered prose exits non-zero" "$status"
assert_contains "stale numbered prose is reported" "$output" "Stale prose"
assert_contains "stale numbered prose path is reported" "$output" "README.md"
echo ""

echo "4. Real repo passes integration"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" 2>&1)
status=$?
assert_success "real repo exits zero" "$status"
assert_contains "real repo reports success" "$output" "Cross-references consistent"
echo ""

finish_tests