#!/usr/bin/env bash
# tests/hooks/test-pulse-paths-powershell.sh -- unit tests for pulse_paths.ps1
# Run: bash tests/hooks/test-pulse-paths-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/powershell-hook-test-helpers.sh
source "$(dirname "$0")/../lib/powershell-hook-test-helpers.sh"
init_powershell_hook_test_context "$0"
ensure_pwsh_available

TEMPLATE_PULSE_PATHS="$SCRIPTS_DIR/pulse_paths.ps1"
REPO_PULSE_PATHS="$REPO_ROOT/.github/hooks/scripts/pulse_paths.ps1"

echo "=== pulse_paths.ps1 (PowerShell) unit tests ==="
echo ""

echo "1. template pulse_paths.ps1 classifies scripts/ci paths as ci_release"
output=$("$PWSH" -NoLogo -NoProfile -Command ". '$TEMPLATE_PULSE_PATHS'; Get-PathFamily 'scripts/ci/validate-agent-frontmatter.sh'" 2>/dev/null)
status=$?
assert_success "template Get-PathFamily exits zero" "$status"
assert_contains "template scripts/ci classified as ci_release" "$output" "ci_release"
echo ""

echo "2. repo-live pulse_paths.ps1 classifies scripts/ci paths as ci_release"
output=$("$PWSH" -NoLogo -NoProfile -Command ". '$REPO_PULSE_PATHS'; Get-PathFamily 'scripts/ci/validate-agent-frontmatter.sh'" 2>/dev/null)
status=$?
assert_success "repo-live Get-PathFamily exits zero" "$status"
assert_contains "repo-live scripts/ci classified as ci_release" "$output" "ci_release"
echo ""

echo "3. template pulse_paths.ps1 keeps nested workspace parity checks"
output=$("$PWSH" -NoLogo -NoProfile -Command ". '$TEMPLATE_PULSE_PATHS'; Test-PathRequiresParity '.copilot/workspace/operations/workspace-index.json'" 2>/dev/null)
status=$?
assert_success "template Test-PathRequiresParity exits zero" "$status"
assert_contains "template workspace-index requires parity" "$output" "True"
echo ""

echo "4. repo-live pulse_paths.ps1 keeps nested workspace parity checks"
output=$("$PWSH" -NoLogo -NoProfile -Command ". '$REPO_PULSE_PATHS'; Test-PathRequiresParity '.copilot/workspace/operations/workspace-index.json'" 2>/dev/null)
status=$?
assert_success "repo-live Test-PathRequiresParity exits zero" "$status"
assert_contains "repo-live workspace-index requires parity" "$output" "True"
echo ""

finish_tests