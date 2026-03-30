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

# ── Guard-destructive test helpers ─────────────────────────────────────────────
# Shared by test-guard-destructive.sh, test-security-edge-cases.sh, etc.
# Require GUARD_SCRIPT to be set before calling.

make_guard_input() {
  local tool_name="$1" command="$2"
  printf '{"tool_name": "%s", "tool_input": {"command": "%s"}}' "$tool_name" "$command"
}

make_guard_input_with_agent() {
  local tool_name="$1" command="$2" agent_name="$3"
  printf '{"tool_name": "%s", "tool_input": {"command": "%s"}, "agentName": "%s"}' "$tool_name" "$command" "$agent_name"
}

make_guard_input_key() {
  local tool_name="$1" command="$2"
  printf '{"tool_name": "%s", "tool_input": {"input": "%s"}}' "$tool_name" "$command"
}

run_guard() {
  echo "$1" | bash "${GUARD_SCRIPT:?GUARD_SCRIPT must be set}" 2>/dev/null
}

assert_guard_decision() {
  local desc="$1" input="$2" expected_decision="$3"
  local output
  output=$(run_guard "$input")
  if grep -q "\"permissionDecision\": \"$expected_decision\"" <<< "$output"; then
    pass_note "$desc"
  else
    fail_note "$desc" "     expected permissionDecision=$expected_decision
     got: $output"
  fi
}

assert_guard_continue() {
  local desc="$1" input="$2"
  local output
  output=$(run_guard "$input")
  assert_matches "$desc" "$output" '"continue": true'
}

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
  for d in "${CLEANUP_DIRS[@]:-}"; do
    [[ -n "$d" ]] && rm -rf "$d"
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
  echo "Results: $PASS passed, $FAIL failed"
  [[ $FAIL -eq 0 ]]
}
