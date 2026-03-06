#!/usr/bin/env bash
# tests/test-report-script-coverage.sh -- verify coverage-script bash suite discovery.
# Run: bash tests/test-report-script-coverage.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"

echo "=== report-script-coverage.sh discovery checks ==="
echo ""

echo "1. List mode emits the current behavioral bash suites"
output=$(bash "$REPO_ROOT/scripts/report-script-coverage.sh" --list-bash-tests)
status=$?
assert_success "list mode exits zero" "$status"
assert_contains "list mode includes doc discoverability suite" "$output" 'tests/test-doc-discoverability.sh'
assert_contains "list mode includes doc platform suite" "$output" 'tests/test-doc-platform-contracts.sh'
assert_contains "list mode includes hook behavior suite" "$output" 'tests/test-hook-session-start.sh'
assert_contains "list mode includes report coverage suite" "$output" 'tests/test-sync-llms-context.sh'
echo ""

echo "2. Non-behavior and self-referential suites stay excluded"
if ! grep -Fq 'tests/test-report-script-coverage.sh' <<< "$output"; then
  pass_note "list mode excludes self-test"
else
  fail_note "list mode excludes self-test" "     unexpected entry: tests/test-report-script-coverage.sh"
fi

if ! grep -Fq 'tests/test-hooks-powershell.sh' <<< "$output"; then
  pass_note "list mode excludes PowerShell parity suites"
else
  fail_note "list mode excludes PowerShell parity suites" "     unexpected entry: tests/test-hooks-powershell.sh"
fi

if ! grep -Fq 'tests/test-template-parity.sh' <<< "$output"; then
  pass_note "list mode excludes mirror-only contract suites"
else
  fail_note "list mode excludes mirror-only contract suites" "     unexpected entry: tests/test-template-parity.sh"
fi

if printf '%s\n' "$output" | python3 - <<'PY'
import sys

lines = [line.strip() for line in sys.stdin.read().splitlines() if line.strip()]
if lines != sorted(lines):
    raise SystemExit(lines)
if len(lines) != len(set(lines)):
    raise SystemExit("duplicates detected")
PY
then
  pass_note "list mode stays sorted and unique"
else
  fail_note "list mode stays sorted and unique"
fi
echo ""

finish_tests