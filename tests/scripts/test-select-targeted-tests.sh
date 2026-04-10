#!/usr/bin/env bash
# tests/scripts/test-select-targeted-tests.sh -- unit tests for scripts/harness/select-targeted-tests.sh
# Run: bash tests/scripts/test-select-targeted-tests.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
# shellcheck disable=SC2034
SCRIPT="$REPO_ROOT/scripts/harness/select-targeted-tests.sh"
# shellcheck disable=SC2034
MAP_FILE="$REPO_ROOT/scripts/harness/targeted-test-map.json"
# shellcheck disable=SC2034
MAP_SHARD_DIR="$REPO_ROOT/scripts/harness/targeted-test-map.d"
# shellcheck disable=SC2034
SUITE_MANIFEST_FILE="$REPO_ROOT/scripts/harness/suite-manifest.json"
PARTS_DIR="$REPO_ROOT/tests/scripts/test-select-targeted-tests.d"

echo "=== select-targeted-tests.sh ==="
echo ""
for part in "$PARTS_DIR"/*.sh; do
  # shellcheck source=/dev/null
  source "$part"
done

finish_tests