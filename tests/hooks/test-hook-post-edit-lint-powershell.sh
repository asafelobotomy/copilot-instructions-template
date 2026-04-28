#!/usr/bin/env bash
# tests/hooks/test-hook-post-edit-lint-powershell.sh -- unit tests for post-edit-lint.ps1
# Run: bash tests/hooks/test-hook-post-edit-lint-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/powershell-hook-test-helpers.sh
source "$(dirname "$0")/../lib/powershell-hook-test-helpers.sh"
init_powershell_hook_test_context "$0"
trap cleanup_dirs EXIT
ensure_pwsh_available

echo "=== post-edit-lint.ps1 (PowerShell) unit tests ==="
echo ""

echo "1. post-edit-lint.ps1 safely passes through non-edit and malformed input"
output=$(run_ps_script "$POST_LINT" '{"tool_name":"read_file","tool_input":{}}')
status=$?
assert_success "post-edit-lint non-edit exits zero" "$status"
assert_contains "post-edit-lint non-edit continues" "$output" '"continue": true'
output=$(run_ps_script "$POST_LINT" 'not-json')
status=$?
assert_success "post-edit-lint malformed JSON exits zero" "$status"
assert_contains "post-edit-lint malformed JSON continues" "$output" '"continue": true'
echo ""

echo "2. post-edit-lint.ps1 accepts edit tool payloads with filePath"
TMP_FILE=$(mktemp); CLEANUP_DIRS+=("$TMP_FILE")
output=$(run_ps_script "$POST_LINT" "{\"tool_name\":\"edit_file\",\"tool_input\":{\"filePath\":\"$TMP_FILE\"}}")
status=$?
assert_success "post-edit-lint edit payload exits zero" "$status"
assert_contains "post-edit-lint edit payload continues" "$output" '"continue": true'

echo ""

echo "3. post-edit-lint.ps1 formatter failures emit hookSpecificOutput.additionalContext"
TMP_DIR=$(mktemp -d "$REPO_ROOT/.tmp-post-edit-lint-ps1.XXXXXX"); CLEANUP_DIRS+=("$TMP_DIR")
TMP_GO="$TMP_DIR/test.go"
touch "$TMP_GO"
cat > "$TMP_DIR/gofmt" <<'EOF'
#!/usr/bin/env bash
echo "synthetic gofmt failure" >&2
exit 1
EOF
chmod +x "$TMP_DIR/gofmt"
output=$(PATH="$TMP_DIR:$PATH" run_ps_script "$POST_LINT" "{\"tool_name\":\"write_to_file\",\"tool_input\":{\"filePath\":\"$TMP_GO\"}}")
status=$?
assert_success "post-edit-lint formatter failure exits zero" "$status"
assert_contains "post-edit-lint formatter failure keeps continue=true" "$output" '"continue": true'
assert_contains "post-edit-lint formatter failure uses hookSpecificOutput" "$output" '"hookSpecificOutput"'
assert_contains "post-edit-lint formatter failure includes additionalContext" "$output" '"additionalContext"'
echo ""

finish_tests