#!/usr/bin/env bash
# tests/lib/test-helpers.sh -- shared assertions for shell-based test suites.

set -euo pipefail
init_test_context() {
  local script_path="$1"
  PASS=0
  FAIL=0
  FAIL_LINES=()
  SUITE_NAME=$(basename "$script_path")
  TESTS_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
  REPO_ROOT=$(cd "$TESTS_ROOT/.." && pwd)
}

pass_note() {
  local desc="$1"
  echo "  PASS: ${desc}"
  PASS=$((PASS + 1))
}

fail_note() {
  local desc="$1" details="${2:-}"
  echo "  FAIL: ${desc}"
  FAIL_LINES+=("  FAIL: ${desc}")
  if [[ -n "$details" ]]; then
    printf '%s\n' "$details"
    FAIL_LINES+=("$details")
  fi
  FAIL=$((FAIL + 1))
}

assert_success() {
  local desc="$1" status="$2"
  if [[ "$status" -eq 0 ]]; then
    pass_note "$desc"
  else
    fail_note "$desc" "     exit: $status"
  fi
}

assert_failure() {
  local desc="$1" status="$2"
  if [[ "$status" -ne 0 ]]; then
    pass_note "$desc"
  else
    fail_note "$desc" "     expected non-zero exit"
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if grep -Fq -- "$needle" <<< "$haystack"; then
    pass_note "$desc"
  else
    fail_note "$desc" "     expected to find: $needle
     output: $haystack"
  fi
}

assert_matches() {
  local desc="$1" haystack="$2" pattern="$3"
  if grep -Eq -- "$pattern" <<< "$haystack"; then
    pass_note "$desc"
  else
    fail_note "$desc" "     expected pattern: $pattern
     output: $haystack"
  fi
}

assert_file_contains() {
  local desc="$1" file_path="$2" pattern="$3"
  if grep -Eq -- "$pattern" "$file_path" 2>/dev/null; then
    pass_note "$desc"
  else
    fail_note "$desc" "     expected pattern: $pattern
     file: $file_path"
  fi
}

assert_file_not_contains() {
  local desc="$1" file_path="$2" pattern="$3"
  if ! grep -Eq -- "$pattern" "$file_path" 2>/dev/null; then
    pass_note "$desc"
  else
    fail_note "$desc" "     unexpected pattern: $pattern
     file: $file_path"
  fi
}

assert_file_exists() {
  local desc="$1" path="$2"
  if [[ -f "$path" ]]; then
    pass_note "$desc"
  else
    fail_note "$desc" "     file not found: $path"
  fi
}

assert_dir_exists() {
  local desc="$1" path="$2"
  if [[ -d "$path" ]]; then
    pass_note "$desc"
  else
    fail_note "$desc" "     dir not found: $path"
  fi
}

assert_valid_json() {
  local desc="$1" payload="$2"
  if python3 -c "import json,sys; json.load(sys.stdin)" <<< "$payload" 2>/dev/null; then
    pass_note "$desc"
  else
    fail_note "$desc" "     output: $payload"
  fi
}

assert_json_has() {
  local desc="$1" json="$2" key="$3"
  if KEY="$key" python3 -c "import json,os,sys; d=json.loads(sys.stdin.read()); assert os.environ['KEY'] in d" <<< "$json" 2>/dev/null; then
    pass_note "$desc"
  else
    fail_note "$desc" "     key '$key' not found in: $json"
  fi
}

# Guard-specific helpers are in tests/lib/guard-test-helpers.sh.
# Source that file in tests that exercise guard-destructive scripts.

# ── Git sandbox helper ─────────────────────────────────────────────────────────
# Creates a temp dir with a git repo containing one committed README.
# Prints the temp dir path. Caller should add it to CLEANUP_DIRS.

make_git_sandbox() {
  local dir
  dir=$(mktemp -d)
  (
    cd "$dir" || exit 1
    git init -q
    git config user.email "test@test.com"
    git config user.name "test"
    echo "clean" > README.md
    git add README.md && git commit -q -m "init"
  )
  echo "$dir"
}

# ── Cleanup helper ─────────────────────────────────────────────────────────────
# Tracks temp directories for automatic cleanup via trap.
# Usage: CLEANUP_DIRS=(); trap cleanup_dirs EXIT; dir=$(mktemp -d); CLEANUP_DIRS+=("$dir")

CLEANUP_DIRS=()

cleanup_dirs() {
  local d
  for d in "${CLEANUP_DIRS[@]:-}"; do
    if [[ -n "$d" ]]; then
      rm -rf "$d"
    fi
  done
}

_run_python() {
  # Internal helper: execute Python code with a 'root' path in scope.
  # Usage: _run_python <root_path> <code>
  local root_path="$1" code="$2"
  TEST_ROOT="$root_path" TEST_CODE="$code" python3 - <<'PY'
import filecmp
import json
import os
import pathlib
import re
import sys

root = pathlib.Path(os.environ['TEST_ROOT'])
code = os.environ['TEST_CODE']
ns = {
    "filecmp": filecmp,
    "json": json,
    "os": os,
    "pathlib": pathlib,
    "re": re,
    "root": root,
    "sys": sys,
}
exec(code, ns)
PY
}

assert_python() {
  local desc="$1" code="$2"
  if _run_python "$REPO_ROOT" "$code"; then
    pass_note "$desc"
  else
    fail_note "$desc"
  fi
}

assert_python_in_root() {
  local desc="$1" root_path="$2" code="$3"
  if _run_python "$root_path" "$code"; then
    pass_note "$desc"
  else
    fail_note "$desc"
  fi
}

finish_tests() {
  echo ""
  echo "Results: ${PASS} passed, ${FAIL} failed (${SUITE_NAME:-})"
  if [[ ${FAIL} -gt 0 ]]; then
    echo "--- Failures ---"
    for line in "${FAIL_LINES[@]}"; do
      echo "${line}"
    done
  fi
  [[ ${FAIL} -eq 0 ]]
}
