#!/usr/bin/env bash
# tests/hooks/test-hooks-powershell.sh -- aggregator for split PowerShell hook suites
# Run: bash tests/hooks/test-hooks-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/powershell-hook-test-helpers.sh
source "$(dirname "$0")/../lib/powershell-hook-test-helpers.sh"
init_powershell_hook_test_context "$0"
ensure_pwsh_available

HOOKS_DIR=$(cd "$(dirname "$0")" && pwd)
SUITES=(
  "$HOOKS_DIR/test-hook-session-start-powershell.sh"
  "$HOOKS_DIR/test-hook-post-edit-lint-powershell.sh"
  "$HOOKS_DIR/test-hook-pulse-powershell.sh"
  "$HOOKS_DIR/test-hook-save-context-powershell.sh"
)

echo "=== PowerShell hook script unit tests ==="
echo ""

for suite in "${SUITES[@]}"; do
  if bash "$suite"; then
    pass_note "$(basename "$suite")"
  else
    fail_note "$(basename "$suite")" "     suite failed: $suite"
  fi
  echo ""
done

finish_tests
