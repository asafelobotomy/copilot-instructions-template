#!/usr/bin/env bash
# tests/scripts/test-validate-no-generated-artifacts.sh -- tests for scripts/ci/validate-no-generated-artifacts.sh
# Run: bash tests/scripts/test-validate-no-generated-artifacts.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/ci/validate-no-generated-artifacts.sh"
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
  git -C "$destination" init -q
}

echo "=== validate-no-generated-artifacts.sh ==="
echo ""

echo "1. Real repo passes"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" 2>&1)
rc=$?
assert_success "real repo exits zero" "$rc"
assert_contains "real repo reports success" "$output" "No committed generated artefacts found"
echo ""

echo "2. Committed .pyc is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_repo_copy "$TMP/repo"
mkdir -p "$TMP/repo/hooks/scripts/__pycache__"
printf 'placeholder' > "$TMP/repo/hooks/scripts/__pycache__/pulse_state.cpython-314.pyc"
git -C "$TMP/repo" add -f hooks/scripts/__pycache__/pulse_state.cpython-314.pyc
if output=$(ROOT_DIR="$TMP/repo" bash "$TMP/repo/scripts/ci/validate-no-generated-artifacts.sh" 2>&1); then
  rc=0
else
  rc=$?
fi
assert_failure "committed generated artefact exits non-zero" "$rc"
assert_contains "committed artefact is reported" "$output" "hooks/scripts/__pycache__/pulse_state.cpython-314.pyc"
echo ""

finish_tests