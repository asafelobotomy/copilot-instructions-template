#!/usr/bin/env bash
# tests/hooks/test-hook-scan-secrets.sh -- unit tests for hooks/scripts/scan-secrets.sh
# Run: bash tests/hooks/test-hook-scan-secrets.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/hooks/scripts/scan-secrets.sh"
trap cleanup_dirs EXIT

echo "=== scan-secrets.sh unit tests ==="
echo ""

# ---------------------------------------------------------------------------
# 1. SKIP_SECRETS_SCAN bypasses scanning
# ---------------------------------------------------------------------------
echo "1. SKIP_SECRETS_SCAN=true skips scanning"
output=$(SKIP_SECRETS_SCAN=true echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_contains "outputs continue=true" "$output" '"continue": true'
echo ""

# ---------------------------------------------------------------------------
# 2. Non-git directory produces clean exit
# ---------------------------------------------------------------------------
echo "2. Non-git directory skips gracefully"
TMPDIR_NOGIT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_NOGIT")
output=$(cd "$TMPDIR_NOGIT" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_success "exits 0" $?
assert_contains "outputs continue=true" "$output" '"continue": true'
echo ""

# ---------------------------------------------------------------------------
# 3. Clean repo produces no findings
# ---------------------------------------------------------------------------
echo "3. Clean repo with no modified files"
TMPDIR_CLEAN=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_CLEAN")
output=$(cd "$TMPDIR_CLEAN" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_success "exits 0" $?
assert_contains "outputs continue=true" "$output" '"continue": true'
echo ""

# ---------------------------------------------------------------------------
# 4. AWS key in modified file is detected (warn mode)
# ---------------------------------------------------------------------------
echo "4. AWS key detected in warn mode"
TMPDIR_AWS=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_AWS")
echo "aws_key=AKIAZ3MGNRTWFD7GHXQL" > "$TMPDIR_AWS/config.env"
output=$(cd "$TMPDIR_AWS" && echo '{}' | SCAN_MODE=warn bash "$SCRIPT" 2>/dev/null)
assert_success "exits 0 in warn mode" $?
assert_contains "continues in warn mode" "$output" '"continue": true'
# Check stderr for finding
stderr_output=$(cd "$TMPDIR_AWS" && echo '{}' | SCAN_MODE=warn bash "$SCRIPT" 2>&1 1>/dev/null)
assert_matches "AWS key reported on stderr" "$stderr_output" "AWS_ACCESS_KEY"
echo ""

# ---------------------------------------------------------------------------
# 5. AWS key in modified file blocks in block mode
# ---------------------------------------------------------------------------
echo "5. AWS key blocks in block mode"
TMPDIR_BLOCK=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_BLOCK")
echo "aws_key=AKIAZ3MGNRTWFD7GHXQL" > "$TMPDIR_BLOCK/config.env"
output=$(cd "$TMPDIR_BLOCK" && echo '{}' | SCAN_MODE=block bash "$SCRIPT" 2>/dev/null)
assert_contains "blocks on findings" "$output" '"decision":"block"'
echo ""

# ---------------------------------------------------------------------------
# 6. stop_hook_active bypasses repeat blocking
# ---------------------------------------------------------------------------
echo "6. stop_hook_active=true bypasses repeat blocking"
TMPDIR_REPEAT=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_REPEAT")
echo "aws_key=AKIAZ3MGNRTWFD7GHXQL" > "$TMPDIR_REPEAT/config.env"
output=$(cd "$TMPDIR_REPEAT" && printf '{"stop_hook_active": true}' | SCAN_MODE=block bash "$SCRIPT" 2>/dev/null)
assert_contains "repeat stop continues" "$output" '"continue": true'
echo ""

# ---------------------------------------------------------------------------
# 7. Placeholder values are ignored
# ---------------------------------------------------------------------------
echo "7. Placeholder secrets are ignored"
TMPDIR_PLACEHOLDER=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_PLACEHOLDER")
echo "token=ghp_example000000000000000000000000000000" > "$TMPDIR_PLACEHOLDER/example.env"
output=$(cd "$TMPDIR_PLACEHOLDER" && echo '{}' | SCAN_MODE=block bash "$SCRIPT" 2>/dev/null)
assert_contains "placeholder continues" "$output" '"continue": true'
echo ""

# ---------------------------------------------------------------------------
# 8. Allowlist suppresses matching findings
# ---------------------------------------------------------------------------
echo "8. Allowlist suppresses findings"
TMPDIR_ALLOW=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_ALLOW")
echo "aws_key=AKIAZ3MGNRTWFD7GHXQL" > "$TMPDIR_ALLOW/config.env"
output=$(cd "$TMPDIR_ALLOW" && echo '{}' | SCAN_MODE=block SECRETS_ALLOWLIST="AKIAZ3MGNRTWFD7GHXQL" bash "$SCRIPT" 2>/dev/null)
assert_contains "allowlisted continues" "$output" '"continue": true'
echo ""

# ---------------------------------------------------------------------------
# 9. Lock files are skipped
# ---------------------------------------------------------------------------
echo "9. Lock files are skipped"
TMPDIR_LOCK=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_LOCK")
echo "aws_key=AKIAZ3MGNRTWFD7GHXQ2" > "$TMPDIR_LOCK/package-lock.json"
output=$(cd "$TMPDIR_LOCK" && echo '{}' | SCAN_MODE=block bash "$SCRIPT" 2>/dev/null)
assert_contains "lock file skipped" "$output" '"continue": true'
echo ""

# ---------------------------------------------------------------------------
# 10. Only JSON on stdout (no human text leaks)
# ---------------------------------------------------------------------------
echo "10. Only JSON on stdout"
TMPDIR_JSON=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_JSON")
echo "aws_key=AKIAZ3MGNRTWFD7GHXQ3" > "$TMPDIR_JSON/config.env"
stdout_output=$(cd "$TMPDIR_JSON" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
# stdout should not contain emoji/human text — only JSON
if echo "$stdout_output" | grep -qE '^[{]'; then
  pass_note "stdout starts with JSON"
else
  fail_note "stdout starts with JSON" "     output: $stdout_output"
fi
# Should not contain human log lines on stdout
if echo "$stdout_output" | grep -qE '🔍|⚠️|✅|✨|💡|🚫'; then
  fail_note "no emoji on stdout" "     output: $stdout_output"
else
  pass_note "no emoji on stdout"
fi
echo ""

# ---------------------------------------------------------------------------
# 11. GitHub PAT detection
# ---------------------------------------------------------------------------
echo "11. GitHub PAT detected"
TMPDIR_GH=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_GH")
echo "GITHUB_TOKEN=ghp_R7qZ3mGnRtWfD7GhXqL9pN2kJ5vB8cY4sA1w" > "$TMPDIR_GH/.env"
stderr_output=$(cd "$TMPDIR_GH" && echo '{}' | bash "$SCRIPT" 2>&1 1>/dev/null)
assert_matches "GitHub PAT reported" "$stderr_output" "GITHUB_PAT"
echo ""

# ---------------------------------------------------------------------------
# 12. Private key header detected
# ---------------------------------------------------------------------------
echo "12. Private key header detected"
TMPDIR_KEY=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_KEY")
printf '%s\n' '-----BEGIN RSA PRIVATE KEY-----' 'MIIEpAIBAAK' '-----END RSA PRIVATE KEY-----' > "$TMPDIR_KEY/key.pem"
stderr_output=$(cd "$TMPDIR_KEY" && echo '{}' | bash "$SCRIPT" 2>&1 1>/dev/null)
assert_matches "private key reported" "$stderr_output" "PRIVATE_KEY"
echo ""

# ---------------------------------------------------------------------------
# 13. Lockfile prevents concurrent scans
# ---------------------------------------------------------------------------
echo "13. Lockfile prevents concurrent scans"
TMPDIR_LOCK2=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_LOCK2")
echo "clean_file=ok" > "$TMPDIR_LOCK2/app.txt"
mkdir -p "$TMPDIR_LOCK2/logs/secrets"
# Write a lockfile with the current shell PID (which is alive)
printf '%s' "$$" > "$TMPDIR_LOCK2/logs/secrets/.scan-secrets.lock"
output=$(cd "$TMPDIR_LOCK2" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_contains "lockfile continues" "$output" '"continue": true'
stderr_output=$(cd "$TMPDIR_LOCK2" && echo '{}' | bash "$SCRIPT" 2>&1 1>/dev/null)
assert_contains "lockfile message" "$stderr_output" "Scan already in progress"
rm -f "$TMPDIR_LOCK2/logs/secrets/.scan-secrets.lock"
echo ""

# ---------------------------------------------------------------------------
# 14. Stale lockfile (dead PID) does not block
# ---------------------------------------------------------------------------
echo "14. Stale lockfile is cleaned up"
TMPDIR_STALE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_STALE")
mkdir -p "$TMPDIR_STALE/logs/secrets"
# Use PID 99999999 which is almost certainly not running
printf '99999999' > "$TMPDIR_STALE/logs/secrets/.scan-secrets.lock"
output=$(cd "$TMPDIR_STALE" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_contains "stale lock continues" "$output" '"continue": true'
# The stale lock should have been cleaned up (no "already in progress" message)
stderr_output=$(cd "$TMPDIR_STALE" && echo '{}' | bash "$SCRIPT" 2>&1 1>/dev/null)
if echo "$stderr_output" | grep -q "Scan already in progress"; then
  fail_note "stale lock was cleaned up" "     still blocked after stale PID"
else
  pass_note "stale lock was cleaned up"
fi
echo ""

# ---------------------------------------------------------------------------
# 15. Debounce skips scan when last was clean and recent
# ---------------------------------------------------------------------------
echo "15. Debounce skips scan when recent clean scan exists"
TMPDIR_DEB=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_DEB")
echo "clean_file=ok" > "$TMPDIR_DEB/app.txt"
# Pre-create log dir and gitignore it so the first scan's log files
# don't change the untracked file count between runs
mkdir -p "$TMPDIR_DEB/logs/secrets"
printf 'logs/\n' > "$TMPDIR_DEB/.gitignore"
# Run a first scan to populate the log
(cd "$TMPDIR_DEB" && echo '{}' | bash "$SCRIPT" 2>/dev/null) >/dev/null
# Run immediately again with debounce — should skip
stderr_output=$(cd "$TMPDIR_DEB" && echo '{}' | SCAN_DEBOUNCE_SECONDS=120 bash "$SCRIPT" 2>&1 1>/dev/null)
assert_contains "debounce skip message" "$stderr_output" "Scan skipped"
echo ""

# ---------------------------------------------------------------------------
# 16. Debounce does NOT skip when file count changed
# ---------------------------------------------------------------------------
echo "16. Debounce allows scan when file count changed"
TMPDIR_DEB2=$(make_git_sandbox); CLEANUP_DIRS+=("$TMPDIR_DEB2")
echo "clean_file=ok" > "$TMPDIR_DEB2/app.txt"
mkdir -p "$TMPDIR_DEB2/logs/secrets"
printf 'logs/\n' > "$TMPDIR_DEB2/.gitignore"
# Run a first scan
(cd "$TMPDIR_DEB2" && echo '{}' | bash "$SCRIPT" 2>/dev/null) >/dev/null
# Add another file to change the count
echo "new_file=ok" > "$TMPDIR_DEB2/new.txt"
stderr_output=$(cd "$TMPDIR_DEB2" && echo '{}' | SCAN_DEBOUNCE_SECONDS=120 bash "$SCRIPT" 2>&1 1>/dev/null)
if echo "$stderr_output" | grep -q "Scan skipped"; then
  fail_note "debounce re-scans on file count change" "     still skipped after file count changed"
else
  pass_note "debounce re-scans on file count change"
fi
echo ""

# ---------------------------------------------------------------------------
finish_tests
