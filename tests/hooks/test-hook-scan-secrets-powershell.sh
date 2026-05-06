#!/usr/bin/env bash
# tests/hooks/test-hook-scan-secrets-powershell.sh -- unit tests for scan-secrets.ps1
# Run: bash tests/hooks/test-hook-scan-secrets-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/powershell-hook-test-helpers.sh
source "$(dirname "$0")/../lib/powershell-hook-test-helpers.sh"
init_powershell_hook_test_context "$0"
trap cleanup_dirs EXIT
ensure_pwsh_available

SCRIPT="$SCRIPTS_DIR/scan-secrets.ps1"

run_scan_in_dir() {
  local dir="$1" payload="$2"
  local env_assignment var_name var_value
  shift 2
  (
    cd "$dir" || exit 1
    while [[ $# -gt 0 ]]; do
      env_assignment="$1"
      var_name=${env_assignment%%=*}
      var_value=${env_assignment#*=}
      printf -v "$var_name" '%s' "$var_value"
      export "${var_name?}"
      shift
    done
    run_ps_script "$SCRIPT" "$payload"
  )
}

echo "=== scan-secrets.ps1 (PowerShell) unit tests ==="
echo ""

echo "1. SKIP_SECRETS_SCAN=true skips scanning"
TMP_SKIP=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_SKIP")
output=$(run_scan_in_dir "$TMP_SKIP" '{}' 'SKIP_SECRETS_SCAN=true')
status=$?
assert_success "skip scan exits zero" "$status"
assert_contains "skip scan continues" "$output" '"continue": true'
echo ""

echo "2. Non-git directories skip gracefully"
TMP_NOGIT=$(mktemp -d); CLEANUP_DIRS+=("$TMP_NOGIT")
output=$(run_scan_in_dir "$TMP_NOGIT" '{}')
status=$?
assert_success "non-git scan exits zero" "$status"
assert_contains "non-git scan continues" "$output" '"continue": true'
echo ""

echo "3. Clean repos with no modified files continue"
TMP_CLEAN=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_CLEAN")
output=$(run_scan_in_dir "$TMP_CLEAN" '{}')
status=$?
assert_success "clean repo scan exits zero" "$status"
assert_contains "clean repo scan continues" "$output" '"continue": true'
echo ""

echo "4. AWS keys are reported in warn mode"
TMP_WARN=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_WARN")
printf 'aws_key=AKIAZ3MGNRTWFD7GHXQL\n' > "$TMP_WARN/config.env"
output=$(run_scan_in_dir "$TMP_WARN" '{}' 'SCAN_MODE=warn')
status=$?
assert_success "warn mode exits zero" "$status"
assert_contains "warn mode continues" "$output" '"continue": true'
# Findings go to stderr; verify stdout is clean JSON
if echo "$output" | grep -qE '^\{'; then
  pass_note "warn mode stdout is JSON"
else
  fail_note "warn mode stdout is JSON" "     output: $output"
fi
echo ""

echo "5. AWS keys block in block mode"
TMP_BLOCK=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_BLOCK")
printf 'aws_key=AKIAZ3MGNRTWFD7GHXQL\n' > "$TMP_BLOCK/config.env"
output=$(run_scan_in_dir "$TMP_BLOCK" '{}' 'SCAN_MODE=block')
status=$?
assert_success "block mode exits zero with hook decision" "$status"
assert_contains "block mode returns hookSpecificOutput block" "$output" '"decision":"block"'
echo ""

echo "6. stop_hook_active=true bypasses repeat blocking"
TMP_REPEAT=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_REPEAT")
printf 'aws_key=AKIAZ3MGNRTWFD7GHXQL\n' > "$TMP_REPEAT/config.env"
output=$(run_scan_in_dir "$TMP_REPEAT" '{"stop_hook_active": true}' 'SCAN_MODE=block')
status=$?
assert_success "repeat block scan exits zero" "$status"
assert_contains "repeat block scan continues" "$output" '"continue": true'
echo ""

echo "7. Placeholder values are ignored"
TMP_PLACEHOLDER=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_PLACEHOLDER")
printf 'token=ghp_example000000000000000000000000000000\n' > "$TMP_PLACEHOLDER/example.env"
output=$(run_scan_in_dir "$TMP_PLACEHOLDER" '{}' 'SCAN_MODE=block')
status=$?
assert_success "placeholder scan exits zero" "$status"
assert_contains "placeholder scan continues" "$output" '"continue": true'
echo ""

echo "8. Allowlist suppresses matching findings"
TMP_ALLOW=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_ALLOW")
printf 'aws_key=AKIAZ3MGNRTWFD7GHXQL\n' > "$TMP_ALLOW/config.env"
output=$(run_scan_in_dir "$TMP_ALLOW" '{}' 'SCAN_MODE=block' 'SECRETS_ALLOWLIST=AKIAZ3MGNRTWFD7GHXQL')
status=$?
assert_success "allowlisted scan exits zero" "$status"
assert_contains "allowlisted scan continues" "$output" '"continue": true'
echo ""

echo "9. Lock files are skipped"
TMP_LOCK=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_LOCK")
printf 'aws_key=AKIAZ3MGNRTWFD7GHXQ2\n' > "$TMP_LOCK/package-lock.json"
output=$(run_scan_in_dir "$TMP_LOCK" '{}' 'SCAN_MODE=block')
status=$?
assert_success "lock-file scan exits zero" "$status"
assert_contains "lock-file scan continues" "$output" '"continue": true'
echo ""

echo "10. Staged scope reads the git index blob, not the working-tree file"
TMP_STAGED=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_STAGED")
# Stage a file containing a GitHub token, then overwrite working tree with clean content
(cd "$TMP_STAGED" && printf 'token=ghp_TESTSTAGEDSCOPE0123456789ABCDEFGHIJ\n' > secret.env && git add secret.env && printf 'token=placeholder\n' > secret.env)
output=$(run_scan_in_dir "$TMP_STAGED" '{}' 'SCAN_SCOPE=staged' 'SCAN_MODE=block')
status=$?
assert_success "staged scope exits zero with hook decision" "$status"
assert_contains "staged scope blocks on secret in git index" "$output" '"decision":"block"'
echo ""

echo "11. Staged scope ignores working-tree-only secrets"
TMP_WTSTAGED=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_WTSTAGED")
# Write a secret only to the working tree without staging it
(cd "$TMP_WTSTAGED" && printf 'token=ghp_WORKTREEONLYSECRET0123456789ABCDEFGH\n' > untracked.env)
output=$(run_scan_in_dir "$TMP_WTSTAGED" '{}' 'SCAN_SCOPE=staged' 'SCAN_MODE=block')
status=$?
assert_success "staged scope skips working-tree-only file" "$status"
assert_contains "staged scope continues when nothing staged" "$output" '"continue": true'
echo ""

echo "12. Lockfile prevents concurrent scans"
TMP_LOCK2=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_LOCK2")
printf 'clean_file=ok\n' > "$TMP_LOCK2/app.txt"
mkdir -p "$TMP_LOCK2/logs/secrets"
# Write a lockfile with a PID that is alive (current shell)
printf '%s' "$$" > "$TMP_LOCK2/logs/secrets/.scan-secrets.lock"
output=$(run_scan_in_dir "$TMP_LOCK2" '{}')
status=$?
assert_success "lockfile scan exits zero" "$status"
assert_contains "lockfile continues" "$output" '"continue": true'
rm -f "$TMP_LOCK2/logs/secrets/.scan-secrets.lock"
echo ""

echo "13. Stale lockfile does not block"
TMP_STALE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_STALE")
mkdir -p "$TMP_STALE/logs/secrets"
printf '99999999' > "$TMP_STALE/logs/secrets/.scan-secrets.lock"
output=$(run_scan_in_dir "$TMP_STALE" '{}')
status=$?
assert_success "stale lock scan exits zero" "$status"
assert_contains "stale lock continues" "$output" '"continue": true'
echo ""

finish_tests