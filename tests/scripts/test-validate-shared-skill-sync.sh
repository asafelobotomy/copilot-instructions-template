#!/usr/bin/env bash
# tests/scripts/test-validate-shared-skill-sync.sh -- tests for scripts/ci/validate-shared-skill-sync.sh
# Run: bash tests/scripts/test-validate-shared-skill-sync.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/ci/validate-shared-skill-sync.sh"
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

echo "=== validate-shared-skill-sync.sh ==="
echo ""

echo "1. Real repo passes"
output=$(bash "$SCRIPT" 2>&1)
status=$?
assert_success "real repo exits zero" "$status"
assert_contains "real repo reports shared sync OK" "$output" "Shared skill sync OK"
echo ""

echo "2. Drift in a shared template skill is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_repo_copy "$TMP/repo"
echo "drift marker" >> "$TMP/repo/template/skills/commit-preflight/SKILL.md"
if output=$(cd "$TMP/repo" && bash scripts/ci/validate-shared-skill-sync.sh 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "shared template drift exits non-zero" "$status"
assert_contains "template drift output reports shared skill drift" "$output" "SHARED SKILL DRIFT"
assert_contains "template drift names the shared skill" "$output" "skills/commit-preflight/SKILL.md"
echo ""

echo "3. Missing consumer mirror for a shared root skill is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_repo_copy "$TMP/repo"
rm "$TMP/repo/.github/skills/commit-preflight/SKILL.md"
if output=$(cd "$TMP/repo" && bash scripts/ci/validate-shared-skill-sync.sh 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "missing shared mirror exits non-zero" "$status"
assert_contains "missing mirror reports drift" "$output" "missing .github/skills/commit-preflight/SKILL.md"
echo ""

finish_tests