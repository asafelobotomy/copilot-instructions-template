#!/usr/bin/env bash
# tests/hooks/test-hook-scan-secrets-powershell.sh -- unit tests for scan-secrets.ps1
# Run: bash tests/hooks/test-hook-scan-secrets-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

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
assert_contains "warn mode reports the AWS finding" "$output" 'AWS_ACCESS_KEY'
assert_contains "warn mode continues" "$output" '"continue": true'
echo ""

echo "5. AWS keys block in block mode"
TMP_BLOCK=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_BLOCK")
printf 'aws_key=AKIAZ3MGNRTWFD7GHXQL\n' > "$TMP_BLOCK/config.env"
output=$(run_scan_in_dir "$TMP_BLOCK" '{}' 'SCAN_MODE=block')
status=$?
assert_success "block mode exits zero with hook decision" "$status"
assert_contains "block mode reports the AWS finding" "$output" 'AWS_ACCESS_KEY'
assert_contains "block mode returns continue=false" "$output" '"continue": false'
echo ""

echo "6. Placeholder values are ignored"
TMP_PLACEHOLDER=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_PLACEHOLDER")
printf 'token=ghp_example000000000000000000000000000000\n' > "$TMP_PLACEHOLDER/example.env"
output=$(run_scan_in_dir "$TMP_PLACEHOLDER" '{}' 'SCAN_MODE=block')
status=$?
assert_success "placeholder scan exits zero" "$status"
assert_contains "placeholder scan continues" "$output" '"continue": true'
echo ""

echo "7. Allowlist suppresses matching findings"
TMP_ALLOW=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_ALLOW")
printf 'aws_key=AKIAZ3MGNRTWFD7GHXQL\n' > "$TMP_ALLOW/config.env"
output=$(run_scan_in_dir "$TMP_ALLOW" '{}' 'SCAN_MODE=block' 'SECRETS_ALLOWLIST=AKIAZ3MGNRTWFD7GHXQL')
status=$?
assert_success "allowlisted scan exits zero" "$status"
assert_contains "allowlisted scan continues" "$output" '"continue": true'
echo ""

echo "8. Lock files are skipped"
TMP_LOCK=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_LOCK")
printf 'aws_key=AKIAZ3MGNRTWFD7GHXQ2\n' > "$TMP_LOCK/package-lock.json"
output=$(run_scan_in_dir "$TMP_LOCK" '{}' 'SCAN_MODE=block')
status=$?
assert_success "lock-file scan exits zero" "$status"
assert_contains "lock-file scan continues" "$output" '"continue": true'
echo ""

finish_tests