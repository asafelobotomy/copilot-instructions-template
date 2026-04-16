#!/usr/bin/env bash
# tests/hooks/test-lib-hooks.sh -- unit tests for hooks/scripts/lib-hooks.sh
# Run: bash tests/hooks/test-lib-hooks.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/hooks/scripts/lib-hooks.sh"
trap cleanup_dirs EXIT

run_json_escape() {
  local value="$1"
  TEST_VALUE="$value" "$(command -v bash)" -c 'source "$1"; json_escape "$TEST_VALUE"' _ "$SCRIPT"
}

run_json_escape_without_python() {
  local value="$1"
  local tmpbin
  tmpbin=$(mktemp -d)
  CLEANUP_DIRS+=("$tmpbin")
  ln -s "$(command -v sed)" "$tmpbin/sed"
  TEST_VALUE="$value" PATH="$tmpbin" "$(command -v bash)" -c 'source "$1"; json_escape "$TEST_VALUE"' _ "$SCRIPT"
}

echo "=== lib-hooks.sh ==="
echo ""

echo "1. json_escape returns an empty string unchanged"
output=$(run_json_escape '')
if [[ -z "$output" ]]; then
  pass_note "empty string stays empty"
else
  fail_note "empty string stays empty" "     output: $output"
fi
echo ""

echo "2. json_escape round-trips quotes, backslashes, and newlines"
raw=$'line "one"\npath\\two'
output=$(run_json_escape "$raw")
export ESCAPED_VALUE="$output" RAW_VALUE="$raw"
assert_python "escaped content decodes back to the original value" '
decoded = json.loads("\"" + os.environ["ESCAPED_VALUE"] + "\"")
assert decoded == os.environ["RAW_VALUE"]
assert not os.environ["ESCAPED_VALUE"].startswith("\"")
assert not os.environ["ESCAPED_VALUE"].endswith("\"")
'
unset ESCAPED_VALUE RAW_VALUE
echo ""

echo "3. json_escape escapes tabs as JSON control characters"
raw=$'tab\tseparated'
output=$(run_json_escape "$raw")
export ESCAPED_VALUE="$output" RAW_VALUE="$raw"
assert_python "tab content decodes back to the original value" '
decoded = json.loads("\"" + os.environ["ESCAPED_VALUE"] + "\"")
assert decoded == os.environ["RAW_VALUE"]
assert "\\t" in os.environ["ESCAPED_VALUE"]
'
unset ESCAPED_VALUE RAW_VALUE
echo ""

echo "4. json_escape falls back to the raw string when python3 is unavailable"
raw='plain "quoted" value'
output=$(run_json_escape_without_python "$raw")
if [[ "$output" == "$raw" ]]; then
  pass_note "missing python3 falls back to raw output"
else
  fail_note "missing python3 falls back to raw output" "     expected: $raw
     output: $output"
fi
echo ""

finish_tests