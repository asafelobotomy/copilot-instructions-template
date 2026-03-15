#!/usr/bin/env bash
# tests/lib/test-helpers.sh -- shared assertions for shell-based test suites.

init_test_context() {
  local script_path="$1"
  PASS=0
  FAIL=0
  REPO_ROOT=$(cd "$(dirname "$script_path")/.." && pwd)
}

pass_note() {
  local desc="$1"
  echo "  PASS: ${desc}"
  ((PASS++))
}

fail_note() {
  local desc="$1" details="${2:-}"
  echo "  FAIL: ${desc}"
  if [[ -n "$details" ]]; then
    printf '%s\n' "$details"
  fi
  ((FAIL++))
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
  if grep -Fq "$needle" <<< "$haystack"; then
    pass_note "$desc"
  else
    fail_note "$desc" "     expected to find: $needle
     output: $haystack"
  fi
}

assert_matches() {
  local desc="$1" haystack="$2" pattern="$3"
  if grep -Eq "$pattern" <<< "$haystack"; then
    pass_note "$desc"
  else
    fail_note "$desc" "     expected pattern: $pattern
     output: $haystack"
  fi
}

assert_file_contains() {
  local desc="$1" file_path="$2" pattern="$3"
  if grep -Eq "$pattern" "$file_path" 2>/dev/null; then
    pass_note "$desc"
  else
    fail_note "$desc" "     expected pattern: $pattern
     file: $file_path"
  fi
}

assert_file_not_contains() {
  local desc="$1" file_path="$2" pattern="$3"
  if ! grep -Eq "$pattern" "$file_path" 2>/dev/null; then
    pass_note "$desc"
  else
    fail_note "$desc" "     unexpected pattern: $pattern
     file: $file_path"
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

assert_python() {
  local desc="$1" code="$2"
  if REPO_ROOT="$REPO_ROOT" TEST_CODE="$code" python3 - <<'PY'
import filecmp
import json
import os
import pathlib
import re
import sys

root = pathlib.Path(os.environ['REPO_ROOT'])
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
  then
    pass_note "$desc"
  else
    fail_note "$desc"
  fi
}

assert_python_in_root() {
  local desc="$1" root_path="$2" code="$3"
  if TEST_ROOT="$root_path" TEST_CODE="$code" python3 - <<'PY'
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
  then
    pass_note "$desc"
  else
    fail_note "$desc"
  fi
}

finish_tests() {
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  [[ $FAIL -eq 0 ]]
}
