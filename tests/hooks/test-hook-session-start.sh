#!/usr/bin/env bash
# tests/hooks/test-hook-session-start.sh -- unit tests for hooks/scripts/session-start.sh
# Run: bash tests/hooks/test-hook-session-start.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/hooks/scripts/session-start.sh"
trap cleanup_dirs EXIT

echo "=== session-start.sh ==="
echo ""

echo "1. Output is valid JSON"
output=$(echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_valid_json "valid JSON output" "$output"
echo ""

echo "2. Output contains hookEventName=SessionStart"
assert_matches "hookEventName present" "$output" "SessionStart"
echo ""

echo "3. Output contains additionalContext with project info"
assert_matches "additionalContext present" "$output" "additionalContext"
assert_matches "Branch field present" "$output" "Branch:"
echo ""

echo "4. Script does not crash on empty stdin"
output=$(echo '' | bash "$SCRIPT" 2>/dev/null)
assert_success "empty stdin" $?
assert_valid_json "valid JSON on empty stdin" "$output"
echo ""

echo "5. Fallback project name (no manifest) = directory name"
TMPDIR_PROJECT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_PROJECT")
TMPDIR_NAME=$(basename "$TMPDIR_PROJECT")
output=$(cd "$TMPDIR_PROJECT" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "project name fallback to dir name" "$output" "$TMPDIR_NAME"
echo ""

echo "6. Detects package.json project"
TMPDIR_NPM=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_NPM")
printf '{\n  "name": "my-npm-project",\n  "version": "9.9.9"\n}\n' > "$TMPDIR_NPM/package.json"
output=$(cd "$TMPDIR_NPM" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "reads name from package.json" "$output" "my-npm-project"
assert_matches "reads version from package.json" "$output" "9.9.9"
echo ""

echo "7. Detects pyproject.toml (Python) project"
TMPDIR_PY=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_PY")
printf '[project]\nname = "my-python-project"\nversion = "2.3.4"\n' > "$TMPDIR_PY/pyproject.toml"
output=$(cd "$TMPDIR_PY" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "reads name from pyproject.toml" "$output" "my-python-project"
assert_matches "reads version from pyproject.toml" "$output" "2.3.4"
echo ""

echo "8. Detects Cargo.toml (Rust) project"
TMPDIR_RUST=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_RUST")
printf '[package]\nname = "my-rust-project"\nversion = "7.8.9"\n' > "$TMPDIR_RUST/Cargo.toml"
output=$(cd "$TMPDIR_RUST" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "reads name from Cargo.toml" "$output" "my-rust-project"
assert_matches "reads version from Cargo.toml" "$output" "7.8.9"
echo ""

echo "9. HEARTBEAT.md pulse is included in session context"
TMPDIR_HB=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_HB")
mkdir -p "$TMPDIR_HB/.copilot/workspace/identity" "$TMPDIR_HB/.copilot/workspace/knowledge/diaries" "$TMPDIR_HB/.copilot/workspace/operations" "$TMPDIR_HB/.copilot/workspace/runtime"
printf 'HEARTBEAT: green\n' > "$TMPDIR_HB/.copilot/workspace/operations/HEARTBEAT.md"
output=$(cd "$TMPDIR_HB" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "HEARTBEAT pulse in session context" "$output" "green"
echo ""

echo "10. Output contains Node and Python version fields"
output=$(echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "Node: field present" "$output" "Node:"
assert_matches "Py: field present" "$output" "Py:"
echo ""

echo "11. Output contains OS detection fields"
output=$(echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "OS: field present" "$output" "OS:"
assert_matches "Pkg: field present" "$output" "Pkg:"
assert_matches "Imm: field present" "$output" "Imm:"
echo ""

echo "12. Output contains compact routing roster"
output=$(echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "Routing roster field present" "$output" "Route:"
assert_matches "Routing roster includes guarded marker" "$output" "guarded:"
assert_matches "Routing roster includes Stage 4 surfaced code agent" "$output" "Code"
assert_matches "Routing roster includes Stage 4 surfaced fast agent" "$output" "Fast"

finish_tests
