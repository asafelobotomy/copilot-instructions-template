#!/usr/bin/env bash
# tests/scripts/test-run-all-captured.sh -- tests for scripts/harness/run-all-captured.sh
# Run: bash tests/scripts/test-run-all-captured.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/harness/run-all-captured.sh"
trap cleanup_dirs EXIT

make_fixture() {
  local root="$1"
  mkdir -p "$root/tests"
  cat > "$root/tests/run-all.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
for line in one two three four five six; do
  echo "$line"
done
EOF
  chmod +x "$root/tests/run-all.sh"
}

make_failure_fixture() {
  local root="$1"
  mkdir -p "$root/tests"
  cat > "$root/tests/run-all.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "about to fail"
echo "failing line"
exit 7
EOF
  chmod +x "$root/tests/run-all.sh"
}

echo "=== run-all-captured.sh ==="
echo ""

echo "1. Invalid usage is rejected"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" --tail-lines nope 2>&1) || true
assert_contains "invalid tail-lines are rejected" "$output" "tail-lines must be a non-negative integer"
echo ""

echo "2. Successful run writes full log and prints bounded tail"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_fixture "$TMP"
LOG_FILE="$TMP/run-all.log"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --log-file "$LOG_FILE" --tail-lines 3 2>&1)
status=$?
assert_success "wrapper exits zero on success" "$status"
assert_contains "log path is printed" "$output" "LOG_FILE=$LOG_FILE"
assert_contains "exit code is printed" "$output" "EXIT_CODE=0"
assert_contains "tail header is printed" "$output" "--- LOG TAIL START ---"
assert_contains "tail contains final line" "$output" "six"
assert_contains "tail contains bounded preceding line" "$output" "four"
if grep -Fq "one" <<< "$output"; then
  fail_note "bounded tail excludes earlier lines" "     unexpected early line in output: one"
else
  pass_note "bounded tail excludes earlier lines"
fi
assert_file_exists "log file is created" "$LOG_FILE"
assert_file_contains "full log keeps earlier lines" "$LOG_FILE" "one"
assert_file_contains "full log keeps final lines" "$LOG_FILE" "six"
echo ""

echo "3. Failure preserves the wrapped exit code and still prints the log tail"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_failure_fixture "$TMP"
LOG_FILE="$TMP/failing-run-all.log"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --log-file "$LOG_FILE" --tail-lines 5 2>&1)
status=$?
assert_failure "wrapper exits non-zero on failure" "$status"
if [[ "$status" -eq 7 ]]; then
  pass_note "wrapped exit code is preserved"
else
  fail_note "wrapped exit code is preserved" "     expected exit 7, got: $status"
fi
assert_contains "failure exit code is printed" "$output" "EXIT_CODE=7"
assert_contains "failure tail contains log output" "$output" "failing line"
assert_file_exists "failure log file is created" "$LOG_FILE"
assert_file_contains "failure log preserves transcript" "$LOG_FILE" "about to fail"
echo ""

echo "4. Default log path respects TMPDIR (sandbox-safe)"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
SAFE_TMPDIR=$(mktemp -d); CLEANUP_DIRS+=("$SAFE_TMPDIR")
make_fixture "$TMP"
# Run without --log-file; TMPDIR override must determine the log location.
output=$(ROOT_DIR="$TMP" TMPDIR="$SAFE_TMPDIR" bash "$SCRIPT" 2>&1)
status=$?
# Extract the actual log path from output (mktemp produces a unique suffix)
actual_log=$(printf '%s\n' "$output" | grep '^LOG_FILE=' | head -1 | sed 's/^LOG_FILE=//')
assert_success "wrapper exits zero with default log path" "$status"
assert_contains "log path is derived from TMPDIR" "$actual_log" "$SAFE_TMPDIR/copilot-run-all."
assert_file_exists "log file created under TMPDIR" "$actual_log"
echo ""

finish_tests