#!/usr/bin/env bash
# tests/contracts/test-customization-contracts.sh -- aggregator for customization contract suites.
# Run: bash tests/contracts/test-customization-contracts.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

CONTRACTS_DIR=$(cd "$(dirname "$0")" && pwd)
SUITES=(
  "$CONTRACTS_DIR/test-customization-contracts-surfaces.sh"
  "$CONTRACTS_DIR/test-customization-contracts-agents.sh"
  "$CONTRACTS_DIR/test-customization-contracts-policies.sh"
)

echo "=== Customization file contract checks ==="
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