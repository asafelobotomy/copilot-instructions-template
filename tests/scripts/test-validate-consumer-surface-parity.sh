#!/usr/bin/env bash
# tests/scripts/test-validate-consumer-surface-parity.sh -- tests for scripts/ci/validate-consumer-surface-parity.sh
# Run: bash tests/scripts/test-validate-consumer-surface-parity.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/ci/validate-consumer-surface-parity.sh"
trap cleanup_dirs EXIT

make_repo_copy() {
  local destination="$1"
  SOURCE_REPO="$REPO_ROOT" DESTINATION_REPO="$destination" python3 - <<'PY'
import os
import pathlib
import shutil

source = pathlib.Path(os.environ["SOURCE_REPO"])
destination = pathlib.Path(os.environ["DESTINATION_REPO"])
shutil.copytree(
    source,
    destination,
    dirs_exist_ok=True,
    ignore=shutil.ignore_patterns(".git", "__pycache__", "*.pyc", "logs", "node_modules"),
)
PY
}

echo "=== validate-consumer-surface-parity.sh ==="
echo ""

echo "1. Real repo passes"
output=$(bash "$SCRIPT" 2>&1)
status=$?
assert_success "real repo exits zero" "$status"
assert_contains "real repo reports parity OK" "$output" "Consumer-surface parity OK"
echo ""

echo "2. Drift in template/skills is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_repo_copy "$TMP/repo"
SKILL_FILE=$(find "$TMP/repo/template/skills" -name SKILL.md | head -1)
echo "drift marker" >> "$SKILL_FILE"
if output=$(cd "$TMP/repo" && bash scripts/ci/validate-consumer-surface-parity.sh 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "drift exits non-zero" "$status"
assert_contains "drift output reports parity drift" "$output" "PARITY DRIFT"
echo ""

finish_tests
