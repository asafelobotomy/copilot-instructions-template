#!/usr/bin/env bash
# tests/scripts/test-run-strict-bash.sh -- tests for scripts/tests/run-strict-bash.sh
# Run: bash tests/scripts/test-run-strict-bash.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/tests/run-strict-bash.sh"
trap cleanup_dirs EXIT

echo "=== run-strict-bash.sh ==="
echo ""

echo "1. Invalid usage is rejected"
output=$(bash "$SCRIPT" 2>&1) || true
assert_contains "usage is printed" "$output" "Usage: bash scripts/tests/run-strict-bash.sh"
echo ""

echo "2. Command argument runs inside isolated strict bash"
output=$(bash "$SCRIPT" --command 'printf "strict-ok\\n"')
status=$?
assert_success "command form exits zero" "$status"
assert_contains "command form prints output" "$output" "strict-ok"
echo ""

echo "3. Stdin form runs inside isolated strict bash"
output=$(printf 'printf "stdin-ok\\n"\n' | bash "$SCRIPT")
status=$?
assert_success "stdin form exits zero" "$status"
assert_contains "stdin form prints output" "$output" "stdin-ok"
echo ""

echo "4. Strict mode stops on failure and preserves the child exit code"
output=$(bash "$SCRIPT" --command $'printf "before\\n"\nfalse\nprintf "after\\n"' 2>&1)
status=$?
assert_failure "failing command exits non-zero" "$status"
if [[ "$status" -eq 1 ]]; then
  pass_note "child exit code is preserved"
else
  fail_note "child exit code is preserved" "     expected exit 1, got: $status"
fi
assert_contains "output includes commands before failure" "$output" "before"
if grep -Fq -- "after" <<< "$output"; then
  fail_note "strict mode prevents later commands" "     unexpected output after failure: after"
else
  pass_note "strict mode prevents later commands"
fi
echo ""

echo "5. --cwd changes the child working directory"
TMP=$(mktemp -d)
CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/nested"
output=$(bash "$SCRIPT" --cwd "$TMP/nested" --command 'pwd')
status=$?
assert_success "cwd form exits zero" "$status"
assert_contains "cwd form prints requested directory" "$output" "$TMP/nested"
echo ""

echo "6. Missing --cwd target fails clearly"
output=$(bash "$SCRIPT" --cwd /definitely/missing --command 'pwd' 2>&1)
status=$?
assert_failure "missing cwd exits non-zero" "$status"
assert_contains "missing cwd is reported" "$output" "Directory not found"
echo ""

finish_tests