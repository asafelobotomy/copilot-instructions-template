#!/usr/bin/env bash
# tests/scripts/test-validate-required-files.sh -- tests for scripts/ci/validate-required-files.sh
# Run: bash tests/scripts/test-validate-required-files.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/ci/validate-required-files.sh"
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

echo "=== validate-required-files.sh ==="
echo ""

echo "1. Real repo passes"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" 2>&1)
status=$?
assert_success "real repo exits zero" "$status"
assert_contains "real repo reports success" "$output" "All required files present"
echo ""

echo "2. Missing setup manifest is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_repo_copy "$TMP/repo"
rm "$TMP/repo/template/setup/manifests.md"
if output=$(ROOT_DIR="$TMP/repo" bash "$SCRIPT" 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "missing setup manifest exits non-zero" "$status"
assert_contains "missing setup manifest is reported" "$output" "template/setup/manifests.md"
echo ""

echo "3. Missing workspace-index hook script is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_repo_copy "$TMP/repo"
rm "$TMP/repo/template/hooks/scripts/pulse_runtime.py"
if output=$(ROOT_DIR="$TMP/repo" bash "$SCRIPT" 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "missing hook script exits non-zero" "$status"
assert_contains "missing hook script is reported" "$output" "template/hooks/scripts/pulse_runtime.py"
echo ""

echo "4. Missing workspace-index skill file is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_repo_copy "$TMP/repo"
rm "$TMP/repo/template/skills/commit-preflight/SKILL.md"
if output=$(ROOT_DIR="$TMP/repo" bash "$SCRIPT" 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "missing skill exits non-zero" "$status"
assert_contains "missing skill is reported" "$output" "template/skills/commit-preflight/SKILL.md"
echo ""

echo "5. Missing workspace-index agent file is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_repo_copy "$TMP/repo"
rm "$TMP/repo/.github/agents/commit.agent.md"
if output=$(ROOT_DIR="$TMP/repo" bash "$SCRIPT" 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "missing agent exits non-zero" "$status"
assert_contains "missing agent is reported" "$output" ".github/agents/commit.agent.md"
echo ""

finish_tests