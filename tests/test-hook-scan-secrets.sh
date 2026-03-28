#!/usr/bin/env bash
# tests/test-hook-scan-secrets.sh -- unit tests for template/hooks/scripts/scan-secrets.sh
# Run: bash tests/test-hook-scan-secrets.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/template/hooks/scripts/scan-secrets.sh"

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
TMPDIR_NOGIT=$(mktemp -d)
output=$(cd "$TMPDIR_NOGIT" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_success "exits 0" $?
assert_contains "outputs continue=true" "$output" '"continue": true'
rm -rf "$TMPDIR_NOGIT"
echo ""

# ---------------------------------------------------------------------------
# 3. Clean repo produces no findings
# ---------------------------------------------------------------------------
echo "3. Clean repo with no modified files"
TMPDIR_CLEAN=$(mktemp -d)
(
  cd "$TMPDIR_CLEAN" || exit
  git init -q
  git config user.email "test@test.com"
  git config user.name "test"
  echo "clean file" > README.md
  git add README.md && git commit -q -m "init"
)
output=$(cd "$TMPDIR_CLEAN" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_success "exits 0" $?
assert_contains "outputs continue=true" "$output" '"continue": true'
rm -rf "$TMPDIR_CLEAN"
echo ""

# ---------------------------------------------------------------------------
# 4. AWS key in modified file is detected (warn mode)
# ---------------------------------------------------------------------------
echo "4. AWS key detected in warn mode"
TMPDIR_AWS=$(mktemp -d)
(
  cd "$TMPDIR_AWS" || exit
  git init -q
  git config user.email "test@test.com"
  git config user.name "test"
  echo "clean" > README.md
  git add README.md && git commit -q -m "init"
  echo "aws_key=AKIAZ3MGNRTWFD7GHXQL" > config.env
)
output=$(cd "$TMPDIR_AWS" && echo '{}' | SCAN_MODE=warn bash "$SCRIPT" 2>/dev/null)
assert_success "exits 0 in warn mode" $?
assert_contains "continues in warn mode" "$output" '"continue": true'
# Check stderr for finding
stderr_output=$(cd "$TMPDIR_AWS" && echo '{}' | SCAN_MODE=warn bash "$SCRIPT" 2>&1 1>/dev/null)
assert_matches "AWS key reported on stderr" "$stderr_output" "AWS_ACCESS_KEY"
rm -rf "$TMPDIR_AWS"
echo ""

# ---------------------------------------------------------------------------
# 5. AWS key in modified file blocks in block mode
# ---------------------------------------------------------------------------
echo "5. AWS key blocks in block mode"
TMPDIR_BLOCK=$(mktemp -d)
(
  cd "$TMPDIR_BLOCK" || exit
  git init -q
  git config user.email "test@test.com"
  git config user.name "test"
  echo "clean" > README.md
  git add README.md && git commit -q -m "init"
  echo "aws_key=AKIAZ3MGNRTWFD7GHXQL" > config.env
)
output=$(cd "$TMPDIR_BLOCK" && echo '{}' | SCAN_MODE=block bash "$SCRIPT" 2>/dev/null)
assert_contains "blocks on findings" "$output" '"continue": false'
rm -rf "$TMPDIR_BLOCK"
echo ""

# ---------------------------------------------------------------------------
# 6. Placeholder values are ignored
# ---------------------------------------------------------------------------
echo "6. Placeholder secrets are ignored"
TMPDIR_PLACEHOLDER=$(mktemp -d)
(
  cd "$TMPDIR_PLACEHOLDER" || exit
  git init -q
  git config user.email "test@test.com"
  git config user.name "test"
  echo "clean" > README.md
  git add README.md && git commit -q -m "init"
  echo "token=ghp_example000000000000000000000000000000" > example.env
)
output=$(cd "$TMPDIR_PLACEHOLDER" && echo '{}' | SCAN_MODE=block bash "$SCRIPT" 2>/dev/null)
assert_contains "placeholder continues" "$output" '"continue": true'
rm -rf "$TMPDIR_PLACEHOLDER"
echo ""

# ---------------------------------------------------------------------------
# 7. Allowlist suppresses matching findings
# ---------------------------------------------------------------------------
echo "7. Allowlist suppresses findings"
TMPDIR_ALLOW=$(mktemp -d)
(
  cd "$TMPDIR_ALLOW" || exit
  git init -q
  git config user.email "test@test.com"
  git config user.name "test"
  echo "clean" > README.md
  git add README.md && git commit -q -m "init"
  echo "aws_key=AKIAZ3MGNRTWFD7GHXQL" > config.env
)
output=$(cd "$TMPDIR_ALLOW" && echo '{}' | SCAN_MODE=block SECRETS_ALLOWLIST="AKIAZ3MGNRTWFD7GHXQL" bash "$SCRIPT" 2>/dev/null)
assert_contains "allowlisted continues" "$output" '"continue": true'
rm -rf "$TMPDIR_ALLOW"
echo ""

# ---------------------------------------------------------------------------
# 8. Lock files are skipped
# ---------------------------------------------------------------------------
echo "8. Lock files are skipped"
TMPDIR_LOCK=$(mktemp -d)
(
  cd "$TMPDIR_LOCK" || exit
  git init -q
  git config user.email "test@test.com"
  git config user.name "test"
  echo "clean" > README.md
  git add README.md && git commit -q -m "init"
  echo "aws_key=AKIAZ3MGNRTWFD7GHXQ2" > package-lock.json
)
output=$(cd "$TMPDIR_LOCK" && echo '{}' | SCAN_MODE=block bash "$SCRIPT" 2>/dev/null)
assert_contains "lock file skipped" "$output" '"continue": true'
rm -rf "$TMPDIR_LOCK"
echo ""

# ---------------------------------------------------------------------------
# 9. Only JSON on stdout (no human text leaks)
# ---------------------------------------------------------------------------
echo "9. Only JSON on stdout"
TMPDIR_JSON=$(mktemp -d)
(
  cd "$TMPDIR_JSON" || exit
  git init -q
  git config user.email "test@test.com"
  git config user.name "test"
  echo "clean" > README.md
  git add README.md && git commit -q -m "init"
  echo "aws_key=AKIAZ3MGNRTWFD7GHXQ3" > config.env
)
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
rm -rf "$TMPDIR_JSON"
echo ""

# ---------------------------------------------------------------------------
# 10. GitHub PAT detection
# ---------------------------------------------------------------------------
echo "10. GitHub PAT detected"
TMPDIR_GH=$(mktemp -d)
(
  cd "$TMPDIR_GH" || exit
  git init -q
  git config user.email "test@test.com"
  git config user.name "test"
  echo "clean" > README.md
  git add README.md && git commit -q -m "init"
  echo "GITHUB_TOKEN=ghp_R7qZ3mGnRtWfD7GhXqL9pN2kJ5vB8cY4sA1w" > .env
)
stderr_output=$(cd "$TMPDIR_GH" && echo '{}' | bash "$SCRIPT" 2>&1 1>/dev/null)
assert_matches "GitHub PAT reported" "$stderr_output" "GITHUB_PAT"
rm -rf "$TMPDIR_GH"
echo ""

# ---------------------------------------------------------------------------
# 11. Private key header detected
# ---------------------------------------------------------------------------
echo "11. Private key header detected"
TMPDIR_KEY=$(mktemp -d)
(
  cd "$TMPDIR_KEY" || exit
  git init -q
  git config user.email "test@test.com"
  git config user.name "test"
  echo "clean" > README.md
  git add README.md && git commit -q -m "init"
  printf '%s\n' '-----BEGIN RSA PRIVATE KEY-----' 'MIIEpAIBAAK' '-----END RSA PRIVATE KEY-----' > key.pem
)
stderr_output=$(cd "$TMPDIR_KEY" && echo '{}' | bash "$SCRIPT" 2>&1 1>/dev/null)
assert_matches "private key reported" "$stderr_output" "PRIVATE_KEY"
rm -rf "$TMPDIR_KEY"
echo ""

# ---------------------------------------------------------------------------
finish_tests
