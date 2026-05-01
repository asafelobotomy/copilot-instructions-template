#!/usr/bin/env bash
# tests/hooks/test-hook-pulse.sh -- unit tests for hooks/scripts/pulse.sh
# Run: bash tests/hooks/test-hook-pulse.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/hooks/scripts/pulse.sh"
trap cleanup_dirs EXIT

run_pulse() {
  local dir="$1" trigger="$2" payload="$3"
  (
    cd "$dir" || exit 1
    printf '%s' "$payload" | bash "$SCRIPT" --trigger "$trigger"
  )
}

PARTS=(
  "test-hook-pulse-retrospective.sh"
  "test-hook-pulse-state.sh"
  "test-hook-pulse-routing.sh"
)

echo "=== pulse.sh ==="
echo ""

for part in "${PARTS[@]}"; do
  # shellcheck source=/dev/null
  source "$(dirname "$0")/$part"
done

finish_tests
