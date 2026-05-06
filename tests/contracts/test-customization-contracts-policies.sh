#!/usr/bin/env bash
# tests/contracts/test-customization-contracts-policies.sh -- commit, inventory, and allow-list contract checks.
# Run: bash tests/contracts/test-customization-contracts-policies.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

PARTS=(
  "test-customization-contracts-policies-entrypoints.sh"
  "test-customization-contracts-policies-execution-core.sh"
  "test-customization-contracts-policies-execution-agents.sh"
  "test-customization-contracts-policies-plugin.sh"
)

echo "=== Customization policy contract checks ==="
echo ""

for part in "${PARTS[@]}"; do
  # shellcheck source=/dev/null
  source "$(dirname "$0")/$part"
done

finish_tests
