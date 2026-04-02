#!/usr/bin/env bash
# tests/hooks/test-hook-post-edit-lint-powershell.sh -- unit tests for post-edit-lint.ps1
# Run: bash tests/hooks/test-hook-post-edit-lint-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/powershell-hook-test-helpers.sh
source "$(dirname "$0")/../lib/powershell-hook-test-helpers.sh"
init_powershell_hook_test_context "$0"
trap cleanup_dirs EXIT
ensure_pwsh_available

echo "=== post-edit-lint.ps1 (PowerShell) unit tests ==="
echo ""

echo "1. post-edit-lint.ps1 safely passes through non-edit and malformed input"
output=$(run_ps_script "$POST_LINT" '{"tool_name":"read_file","tool_input":{}}')
status=$?
assert_success "post-edit-lint non-edit exits zero" "$status"
assert_contains "post-edit-lint non-edit continues" "$output" '"continue": true'
output=$(run_ps_script "$POST_LINT" 'not-json')
status=$?
assert_success "post-edit-lint malformed JSON exits zero" "$status"
assert_contains "post-edit-lint malformed JSON continues" "$output" '"continue": true'
echo ""

echo "2. post-edit-lint.ps1 accepts edit tool payloads with filePath"
TMP_FILE=$(mktemp); CLEANUP_DIRS+=("$TMP_FILE")
output=$(run_ps_script "$POST_LINT" "{\"tool_name\":\"edit_file\",\"tool_input\":{\"filePath\":\"$TMP_FILE\"}}")
status=$?
assert_success "post-edit-lint edit payload exits zero" "$status"
assert_contains "post-edit-lint edit payload continues" "$output" '"continue": true'
echo ""

finish_tests