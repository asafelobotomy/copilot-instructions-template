#!/usr/bin/env bash
# tests/test-mcp-launchers.sh -- unit tests for MCP launcher wrapper scripts
# Run: bash tests/test-mcp-launchers.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"
trap cleanup_dirs EXIT

NPX_SCRIPT="$REPO_ROOT/template/hooks/scripts/mcp-npx.sh"
UVX_SCRIPT="$REPO_ROOT/template/hooks/scripts/mcp-uvx.sh"

echo "=== MCP launcher wrapper tests ==="
echo ""

echo "1. mcp-npx.sh exists and is executable"
assert_file_exists "mcp-npx.sh exists" "$NPX_SCRIPT"
if [[ -x "$NPX_SCRIPT" ]]; then pass_note "mcp-npx.sh is executable"; else fail_note "mcp-npx.sh is executable" "not executable"; fi
echo ""

echo "2. mcp-uvx.sh exists and is executable"
assert_file_exists "mcp-uvx.sh exists" "$UVX_SCRIPT"
if [[ -x "$UVX_SCRIPT" ]]; then pass_note "mcp-uvx.sh is executable"; else fail_note "mcp-uvx.sh is executable" "not executable"; fi
echo ""

echo "3. mcp-npx.sh starts with set -euo pipefail"
assert_contains "mcp-npx.sh strict mode" "$(cat "$NPX_SCRIPT")" "set -euo pipefail"
echo ""

echo "4. mcp-uvx.sh starts with set -euo pipefail"
assert_contains "mcp-uvx.sh strict mode" "$(cat "$UVX_SCRIPT")" "set -euo pipefail"
echo ""

echo "5. mcp-npx.sh respects NPX_BIN override"
TMPDIR_NPX=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_NPX")
printf '#!/usr/bin/env bash\necho "mock-npx $*"\n' > "$TMPDIR_NPX/mock-npx"
chmod +x "$TMPDIR_NPX/mock-npx"
output=$(NPX_BIN="$TMPDIR_NPX/mock-npx" bash "$NPX_SCRIPT" -y test-pkg 2>/dev/null)
assert_contains "NPX_BIN override works" "$output" "mock-npx -y test-pkg"
echo ""

echo "6. mcp-uvx.sh respects UVX_BIN override"
TMPDIR_UVX=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_UVX")
printf '#!/usr/bin/env bash\necho "mock-uvx $*"\n' > "$TMPDIR_UVX/mock-uvx"
chmod +x "$TMPDIR_UVX/mock-uvx"
output=$(UVX_BIN="$TMPDIR_UVX/mock-uvx" bash "$UVX_SCRIPT" mcp-server-git 2>/dev/null)
assert_contains "UVX_BIN override works" "$output" "mock-uvx mcp-server-git"
echo ""

echo "7. mcp-npx.sh contains not-found error message"
assert_file_contains "npx not-found error in source" "$NPX_SCRIPT" "ERROR: npx not found"
echo ""

echo "8. mcp-uvx.sh contains not-found error message"
assert_file_contains "uvx not-found error in source" "$UVX_SCRIPT" "ERROR: uvx not found"
echo ""

echo "9. mcp-npx.sh documents install URL"
assert_file_contains "npx install URL in source" "$NPX_SCRIPT" "nodejs.org"
echo ""

echo "10. mcp-uvx.sh documents install URL"
assert_file_contains "uvx install URL in source" "$UVX_SCRIPT" "astral.sh"
echo ""

echo "11. .github parity copies match template"
assert_file_exists ".github mcp-npx.sh exists" "$REPO_ROOT/.github/hooks/scripts/mcp-npx.sh"
assert_file_exists ".github mcp-uvx.sh exists" "$REPO_ROOT/.github/hooks/scripts/mcp-uvx.sh"
if diff -q "$NPX_SCRIPT" "$REPO_ROOT/.github/hooks/scripts/mcp-npx.sh" >/dev/null; then pass_note "mcp-npx.sh parity"; else fail_note "mcp-npx.sh parity" "files differ"; fi
if diff -q "$UVX_SCRIPT" "$REPO_ROOT/.github/hooks/scripts/mcp-uvx.sh" >/dev/null; then pass_note "mcp-uvx.sh parity"; else fail_note "mcp-uvx.sh parity" "files differ"; fi
echo ""

echo "12. dev repo mcp.json references launcher scripts"
MCP_JSON="$REPO_ROOT/.vscode/mcp.json"
assert_contains "mcp.json uses mcp-npx.sh" "$(cat "$MCP_JSON")" "mcp-npx.sh"
assert_contains "mcp.json uses mcp-uvx.sh" "$(cat "$MCP_JSON")" "mcp-uvx.sh"

finish_tests
