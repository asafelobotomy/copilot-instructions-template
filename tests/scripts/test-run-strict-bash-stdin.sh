#!/usr/bin/env bash
# tests/scripts/test-run-strict-bash-stdin.sh -- tests for scripts/tests/run-strict-bash-stdin.sh
# Run: bash tests/scripts/test-run-strict-bash-stdin.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/tests/run-strict-bash-stdin.sh"
trap cleanup_dirs EXIT

echo "=== run-strict-bash-stdin.sh ==="
echo ""

echo "1. Invalid usage without stdin is rejected"
output=$(bash "$SCRIPT" 2>&1) || true
assert_contains "usage is printed" "$output" "Usage: bash scripts/tests/run-strict-bash-stdin.sh"
echo ""

echo "2. Here-doc form runs inside isolated strict bash"
output=$(bash "$SCRIPT" <<'EOF'
printf 'heredoc-ok\n'
EOF
)
status=$?
assert_success "here-doc form exits zero" "$status"
assert_contains "here-doc form prints output" "$output" "heredoc-ok"
echo ""

echo "3. Pipe form also works"
output=$(printf 'printf "pipe-ok\\n"\n' | bash "$SCRIPT")
status=$?
assert_success "pipe form exits zero" "$status"
assert_contains "pipe form prints output" "$output" "pipe-ok"
echo ""

echo "4. Strict mode stops on failure and preserves the child exit code"
output=$(bash "$SCRIPT" 2>&1 <<'EOF'
printf 'before\n'
false
printf 'after\n'
EOF
)
status=$?
assert_failure "failing snippet exits non-zero" "$status"
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
output=$(bash "$SCRIPT" --cwd "$TMP/nested" <<'EOF'
pwd
EOF
)
status=$?
assert_success "cwd form exits zero" "$status"
assert_contains "cwd form prints requested directory" "$output" "$TMP/nested"
echo ""

finish_tests