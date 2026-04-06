#!/usr/bin/env bash
# tests/hooks/test-hook-session-start-powershell.sh -- unit tests for session-start.ps1
# Run: bash tests/hooks/test-hook-session-start-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/powershell-hook-test-helpers.sh
source "$(dirname "$0")/../lib/powershell-hook-test-helpers.sh"
init_powershell_hook_test_context "$0"
trap cleanup_dirs EXIT
ensure_pwsh_available

echo "=== session-start.ps1 (PowerShell) unit tests ==="
echo ""

echo "1. session-start.ps1 returns valid SessionStart JSON"
output=$(run_ps_script "$SESSION_START" '{}')
status=$?
assert_success "session-start exits zero" "$status"
assert_valid_json "session-start emits valid JSON" "$output"
assert_contains "session-start hookEventName present" "$output" "SessionStart"
assert_contains "session-start includes branch context" "$output" "Branch:"
echo ""

echo "2. session-start.ps1 detects project manifests"
TMP_NPM=$(mktemp -d); CLEANUP_DIRS+=("$TMP_NPM")
printf '{"name":"pwsh-project","version":"1.2.3"}\n' > "$TMP_NPM/package.json"
output=$(cd "$TMP_NPM" && run_ps_script "$SESSION_START" '{}')
assert_contains "package.json name is surfaced" "$output" "pwsh-project"
assert_contains "package.json version is surfaced" "$output" "1.2.3"
echo ""

echo "3. session-start.ps1 includes compact routing roster"
output=$(run_ps_script "$SESSION_START" '{}')
assert_contains "routing field is surfaced" "$output" "Routing:"
assert_contains "routing guarded marker is surfaced" "$output" "guarded:"
assert_contains "routing includes Stage 4 surfaced code agent" "$output" "Code"
assert_contains "routing includes Stage 4 surfaced fast agent" "$output" "Fast"
echo ""

finish_tests