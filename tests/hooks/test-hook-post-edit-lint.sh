#!/usr/bin/env bash
# tests/hooks/test-hook-post-edit-lint.sh -- unit tests for hooks/scripts/post-edit-lint.sh
# Run: bash tests/hooks/test-hook-post-edit-lint.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/hooks/scripts/post-edit-lint.sh"
TMPDIR_LINT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_LINT")
trap cleanup_dirs EXIT

echo "=== post-edit-lint.sh ==="
echo ""

echo "1. Non-edit tools pass through immediately"
output=$(printf '{"tool_name": "semantic_search", "tool_input": {}}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "semantic_search passes through" "$output" '"continue": true'
output=$(printf '{"tool_name": "read_file", "tool_input": {}}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "read_file passes through" "$output" '"continue": true'
echo ""

echo "2. Edit tool with no file paths passes through"
output=$(printf '{"tool_name": "insert_edit_into_file", "tool_input": {}}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "no filePath passes through" "$output" '"continue": true'
echo ""

echo "3. Edit tool does not crash with valid file path"
TMPFILE="$TMPDIR_LINT/test_edit.txt"
touch "$TMPFILE"
input=$(printf '{"tool_name": "replace_string_in_file", "tool_input": {"filePath": "%s"}}' "$TMPFILE")
echo "$input" | bash "$SCRIPT" 2>/dev/null
assert_success "edit tool with valid .txt file" $?
echo ""

echo "4. Script handles empty and malformed JSON without crashing"
echo '' | bash "$SCRIPT" 2>/dev/null
assert_success "empty input" $?
echo '{}' | bash "$SCRIPT" 2>/dev/null
assert_success "empty JSON object" $?
echo ""

echo "5. Write and create tool name variants trigger the lint path"
TMPFILE_WRITE="$TMPDIR_LINT/test_write.txt"
touch "$TMPFILE_WRITE"
output=$(printf '{"tool_name": "write_to_file", "tool_input": {"filePath": "%s"}}' "$TMPFILE_WRITE" | bash "$SCRIPT" 2>/dev/null)
assert_matches "write_to_file triggers and continues" "$output" '"continue": true'
TMPFILE_CREATE="$TMPDIR_LINT/test_create.txt"
touch "$TMPFILE_CREATE"
output=$(printf '{"tool_name": "create_file", "tool_input": {"filePath": "%s"}}' "$TMPFILE_CREATE" | bash "$SCRIPT" 2>/dev/null)
assert_matches "create_file triggers and continues" "$output" '"continue": true'
echo ""

echo "6. Alternate file key is accepted"
TMPFILE_ALT="$TMPDIR_LINT/test_alt.txt"
touch "$TMPFILE_ALT"
output=$(printf '{"tool_name": "edit_file", "tool_input": {"file": "%s"}}' "$TMPFILE_ALT" | bash "$SCRIPT" 2>/dev/null)
assert_matches "alternate file key continues" "$output" '"continue": true'

echo ""

echo "7. Formatter failures emit hookSpecificOutput.additionalContext"
TMPDIR_FMT=$(mktemp -d "$REPO_ROOT/.tmp-post-edit-lint.XXXXXX"); CLEANUP_DIRS+=("$TMPDIR_FMT")
TMPFILE_GO="$TMPDIR_FMT/test.go"
touch "$TMPFILE_GO"
cat > "$TMPDIR_FMT/gofmt" <<'EOF'
#!/usr/bin/env bash
echo "synthetic gofmt failure" >&2
exit 1
EOF
chmod +x "$TMPDIR_FMT/gofmt"
output=$(printf '{"tool_name": "write_to_file", "tool_input": {"filePath": "%s"}}' "$TMPFILE_GO" | PATH="$TMPDIR_FMT:$PATH" bash "$SCRIPT" 2>/dev/null)
assert_matches "formatter failure keeps continue=true" "$output" '"continue": ?true'
assert_matches "formatter failure uses hookSpecificOutput" "$output" '"hookSpecificOutput"'
assert_matches "formatter failure includes additionalContext" "$output" '"additionalContext"'

finish_tests
