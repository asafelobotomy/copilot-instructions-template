#!/usr/bin/env bash
# tests/test-hooks.sh — unit tests for session-start, post-edit-lint,
#                        enforce-retrospective, and save-context hook scripts
# Run: bash tests/test-hooks.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

PASS=0; FAIL=0

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPTS_DIR="$REPO_ROOT/template/hooks/scripts"

# ── Helpers ────────────────────────────────────────────────────────────────────

assert_json_key() {
  local desc="$1" output="$2" key="$3" value="$4"
  if echo "$output" | grep -q "\"$key\".*$value\|\"$key\": $value\|\"$key\":$value"; then
    echo "  ✅ PASS: $desc"
    ((PASS++))
  else
    echo "  ❌ FAIL: $desc"
    echo "     expected key '$key' with value matching '$value'"
    echo "     output: $output"
    ((FAIL++))
  fi
}

assert_contains() {
  local desc="$1" output="$2" pattern="$3"
  if echo "$output" | grep -q "$pattern"; then
    echo "  ✅ PASS: $desc"
    ((PASS++))
  else
    echo "  ❌ FAIL: $desc — '$pattern' not found"
    echo "     output: $output"
    ((FAIL++))
  fi
}

assert_no_crash() {
  local desc="$1" exit_code="$2"
  if [[ "$exit_code" -eq 0 ]]; then
    echo "  ✅ PASS: $desc"
    ((PASS++))
  else
    echo "  ❌ FAIL: $desc (exit $exit_code)"
    ((FAIL++))
  fi
}

assert_fail() {
  local desc="$1" exit_code="$2"
  if [[ "$exit_code" -ne 0 ]]; then
    echo "  ✅ PASS: $desc"
    ((PASS++))
  else
    echo "  ❌ FAIL: $desc (expected non-zero exit)"
    ((FAIL++))
  fi
}

is_valid_json() {
  python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null <<< "$1"
}

assert_valid_json() {
  local desc="$1" output="$2"
  if is_valid_json "$output"; then
    echo "  ✅ PASS: $desc"
    ((PASS++))
  else
    echo "  ❌ FAIL: $desc — output is not valid JSON"
    echo "     output: $output"
    ((FAIL++))
  fi
}

# ── session-start.sh ──────────────────────────────────────────────────────────
echo "=== session-start.sh ==="
echo ""
SESSION_START="$SCRIPTS_DIR/session-start.sh"

echo "1. Output is valid JSON"
output=$(echo '{}' | bash "$SESSION_START" 2>/dev/null)
assert_valid_json "valid JSON output" "$output"
echo ""

echo "2. Output contains hookEventName=SessionStart"
assert_contains "hookEventName present" "$output" "SessionStart"
echo ""

echo "3. Output contains additionalContext with project info"
assert_contains "additionalContext present" "$output" "additionalContext"
assert_contains "Branch field present"       "$output" "Branch:"
echo ""

echo "4. Script does not crash on empty stdin"
output=$(echo '' | bash "$SESSION_START" 2>/dev/null)
assert_no_crash "empty stdin" $?
assert_valid_json "valid JSON on empty stdin" "$output"
echo ""

# Run in a tmpdir without package.json/pyproject.toml/Cargo.toml to test fallback
echo "5. Fallback project name (no manifest) = directory name"
TMPDIR_PROJECT=$(mktemp -d)
TMPDIR_PARENT=$(dirname "$TMPDIR_PROJECT")
TMPDIR_NAME=$(basename "$TMPDIR_PROJECT")
output=$(cd "$TMPDIR_PROJECT" && echo '{}' | bash "$SESSION_START" 2>/dev/null)
assert_contains "project name fallback to dir name" "$output" "$TMPDIR_NAME"
rm -rf "$TMPDIR_PROJECT"
echo ""

echo "6. Detects package.json project"
TMPDIR_NPM=$(mktemp -d)
printf '{\n  "name": "my-npm-project",\n  "version": "9.9.9"\n}\n' > "$TMPDIR_NPM/package.json"
output=$(cd "$TMPDIR_NPM" && echo '{}' | bash "$SESSION_START" 2>/dev/null)
assert_contains "reads name from package.json"    "$output" "my-npm-project"
assert_contains "reads version from package.json" "$output" "9.9.9"
rm -rf "$TMPDIR_NPM"
echo ""

echo "7s. Detects pyproject.toml (Python) project"
TMPDIR_PY=$(mktemp -d)
printf '[project]\nname = "my-python-project"\nversion = "2.3.4"\n' > "$TMPDIR_PY/pyproject.toml"
output=$(cd "$TMPDIR_PY" && echo '{}' | bash "$SESSION_START" 2>/dev/null)
assert_contains "reads name from pyproject.toml"    "$output" "my-python-project"
assert_contains "reads version from pyproject.toml" "$output" "2.3.4"
rm -rf "$TMPDIR_PY"
echo ""

echo "8s. Detects Cargo.toml (Rust) project"
TMPDIR_RUST=$(mktemp -d)
printf '[package]\nname = "my-rust-project"\nversion = "7.8.9"\n' > "$TMPDIR_RUST/Cargo.toml"
output=$(cd "$TMPDIR_RUST" && echo '{}' | bash "$SESSION_START" 2>/dev/null)
assert_contains "reads name from Cargo.toml"    "$output" "my-rust-project"
assert_contains "reads version from Cargo.toml" "$output" "7.8.9"
rm -rf "$TMPDIR_RUST"
echo ""

echo "9s. HEARTBEAT.md pulse is included in session context"
TMPDIR_HB_SESS=$(mktemp -d)
mkdir -p "$TMPDIR_HB_SESS/.copilot/workspace"
printf 'HEARTBEAT: green 🟢\n' > "$TMPDIR_HB_SESS/.copilot/workspace/HEARTBEAT.md"
output=$(cd "$TMPDIR_HB_SESS" && echo '{}' | bash "$SESSION_START" 2>/dev/null)
assert_contains "HEARTBEAT pulse in session context" "$output" "green"
rm -rf "$TMPDIR_HB_SESS"
echo ""

echo "10s. Output contains Node and Python version fields"
output=$(echo '{}' | bash "$SESSION_START" 2>/dev/null)
assert_contains "Node: field present"   "$output" "Node:"
assert_contains "Python: field present" "$output" "Python:"
echo ""

# ── post-edit-lint.sh ─────────────────────────────────────────────────────────
echo "=== post-edit-lint.sh ==="
echo ""
POST_LINT="$SCRIPTS_DIR/post-edit-lint.sh"

echo "7. Non-edit tools pass through immediately"
output=$(printf '{"tool_name": "semantic_search", "tool_input": {}}' | bash "$POST_LINT" 2>/dev/null)
assert_contains "semantic_search passes through" "$output" '"continue": true'

output=$(printf '{"tool_name": "read_file", "tool_input": {}}' | bash "$POST_LINT" 2>/dev/null)
assert_contains "read_file passes through" "$output" '"continue": true'
echo ""

echo "8. Edit tool with no file paths passes through"
output=$(printf '{"tool_name": "insert_edit_into_file", "tool_input": {}}' | bash "$POST_LINT" 2>/dev/null)
assert_contains "no filePath passes through" "$output" '"continue": true'
echo ""

echo "9. Edit tool does not crash with valid file path"
TMPFILE=$(mktemp /tmp/test_XXXXXX.txt)
input=$(printf '{"tool_name": "replace_string_in_file", "tool_input": {"filePath": "%s"}}' "$TMPFILE")
echo "$input" | bash "$POST_LINT" 2>/dev/null
assert_no_crash "edit tool with valid .txt file" $?
rm -f "$TMPFILE"
echo ""

echo "10. Script handles empty/malformed JSON without crashing"
echo '' | bash "$POST_LINT" 2>/dev/null
assert_no_crash "empty input" $?
echo '{}' | bash "$POST_LINT" 2>/dev/null
assert_no_crash "empty JSON object" $?
echo ""

echo "11p. 'write' tool name variant triggers lint path"
TMPFILE_WRITE=$(mktemp /tmp/test_XXXXXX.txt)
output=$(printf '{"tool_name": "write_to_file", "tool_input": {"filePath": "%s"}}' "$TMPFILE_WRITE" | bash "$POST_LINT" 2>/dev/null)
assert_contains "write_to_file triggers and continues" "$output" '"continue": true'
rm -f "$TMPFILE_WRITE"
echo ""

echo "12p. 'create' tool name variant triggers lint path"
TMPFILE_CREATE=$(mktemp /tmp/test_XXXXXX.txt)
output=$(printf '{"tool_name": "create_file", "tool_input": {"filePath": "%s"}}' "$TMPFILE_CREATE" | bash "$POST_LINT" 2>/dev/null)
assert_contains "create_file triggers and continues" "$output" '"continue": true'
rm -f "$TMPFILE_CREATE"
echo ""

echo "13p. File path via alternate field name 'file'"
TMPFILE_ALT=$(mktemp /tmp/test_XXXXXX.txt)
output=$(printf '{"tool_name": "edit_file", "tool_input": {"file": "%s"}}' "$TMPFILE_ALT" | bash "$POST_LINT" 2>/dev/null)
assert_contains "alternate 'file' key continues" "$output" '"continue": true'
rm -f "$TMPFILE_ALT"
echo ""

# ── enforce-retrospective.sh ──────────────────────────────────────────────────
echo "=== enforce-retrospective.sh ==="
echo ""
ENFORCE_RETRO="$SCRIPTS_DIR/enforce-retrospective.sh"

echo "11. stop_hook_active=true passes through immediately"
output=$(printf '{"stop_hook_active": true}' | bash "$ENFORCE_RETRO" 2>/dev/null)
assert_contains "stop_hook_active=true → continue" "$output" '"continue": true'
assert_valid_json "valid JSON on active hook"        "$output"
echo ""

echo "12. No transcript → decision=block"
TMPDIR_NO_TX=$(mktemp -d)
output=$(cd "$TMPDIR_NO_TX" && printf '{"stop_hook_active": false}' | bash "$ENFORCE_RETRO" 2>/dev/null)
assert_contains "no transcript → block" "$output" '"decision": "block"'
assert_valid_json "valid JSON on block"  "$output"
rm -rf "$TMPDIR_NO_TX"
echo ""

echo "13. Transcript with retrospective keyword → passes through"
TMPDIR_RETRO=$(mktemp -d)
TRANSCRIPT="$TMPDIR_RETRO/transcript.txt"
printf 'The agent ran the retrospective successfully.\n' > "$TRANSCRIPT"
output=$(printf '{"stop_hook_active": false, "transcript_path": "%s"}' "$TRANSCRIPT" | bash "$ENFORCE_RETRO" 2>/dev/null)
assert_contains "retrospective found → continue or no block" "$output" '"continue": true'
rm -rf "$TMPDIR_RETRO"
echo ""

echo "14. HEARTBEAT.md modified <5 minutes ago → passes through"
TMPDIR_HB=$(mktemp -d)
mkdir -p "$TMPDIR_HB/.copilot/workspace"
touch "$TMPDIR_HB/.copilot/workspace/HEARTBEAT.md"  # freshly created = <5 min
output=$(cd "$TMPDIR_HB" && printf '{"stop_hook_active": false}' | bash "$ENFORCE_RETRO" 2>/dev/null)
assert_contains "fresh HEARTBEAT.md → continue" "$output" '"continue": true'
rm -rf "$TMPDIR_HB"
echo ""

echo "15. Malformed JSON input does not crash"
echo 'not-json' | bash "$ENFORCE_RETRO" 2>/dev/null
assert_no_crash "malformed JSON" $?
echo ""

echo "16r. Transcript WITHOUT retrospective keyword → still blocks"
TMPDIR_NO_RETRO=$(mktemp -d)
TRANSCRIPT_NORETRO="$TMPDIR_NO_RETRO/transcript.txt"
printf 'The agent coded features and committed changes.\n' > "$TRANSCRIPT_NORETRO"
output=$(cd "$TMPDIR_NO_RETRO" && printf '{"stop_hook_active": false, "transcript_path": "%s"}' "$TRANSCRIPT_NORETRO" | bash "$ENFORCE_RETRO" 2>/dev/null)
assert_contains "no retro keyword → block" "$output" '"decision": "block"'
assert_valid_json "valid JSON when blocking"  "$output"
rm -rf "$TMPDIR_NO_RETRO"
echo ""

echo "17r. HEARTBEAT.md older than 5 minutes → block"
TMPDIR_STALE=$(mktemp -d)
mkdir -p "$TMPDIR_STALE/.copilot/workspace"
STALE_HB="$TMPDIR_STALE/.copilot/workspace/HEARTBEAT.md"
touch "$STALE_HB"
# Set mtime to 10 minutes ago
touch -d "10 minutes ago" "$STALE_HB" 2>/dev/null \
  || python3 -c "import os,time; os.utime('$STALE_HB', (time.time()-600, time.time()-600))" 2>/dev/null \
  || true
output=$(cd "$TMPDIR_STALE" && printf '{"stop_hook_active": false}' | bash "$ENFORCE_RETRO" 2>/dev/null)
assert_contains "stale HEARTBEAT.md → block" "$output" '"decision": "block"'
rm -rf "$TMPDIR_STALE"
echo ""

# ── save-context.sh ───────────────────────────────────────────────────────────
echo "=== save-context.sh ==="
echo ""
SAVE_CTX="$SCRIPTS_DIR/save-context.sh"

echo "16. Output is valid JSON"
output=$(echo '{}' | bash "$SAVE_CTX" 2>/dev/null)
assert_no_crash "exits 0" $?
assert_valid_json "valid JSON output" "$output"
echo ""

echo "17. Output contains hookEventName=PreCompact"
assert_contains "hookEventName present" "$output" "PreCompact"
echo ""

echo "18. HEARTBEAT.md content appears in additionalContext when present"
TMPDIR_CTX=$(mktemp -d)
mkdir -p "$TMPDIR_CTX/.copilot/workspace"
printf 'HEARTBEAT_OK — all checks pass\n' > "$TMPDIR_CTX/.copilot/workspace/HEARTBEAT.md"
output=$(cd "$TMPDIR_CTX" && echo '{}' | bash "$SAVE_CTX" 2>/dev/null)
assert_contains "heartbeat pulse in context" "$output" "HEARTBEAT"
rm -rf "$TMPDIR_CTX"
echo ""

echo "19. Does not crash when no workspace files exist"
TMPDIR_EMPTY=$(mktemp -d)
cd "$TMPDIR_EMPTY"
echo '{}' | bash "$SAVE_CTX" 2>/dev/null
assert_no_crash "no workspace files" $?
cd "$REPO_ROOT"
rm -rf "$TMPDIR_EMPTY"
echo ""

echo "20c. MEMORY.md recent entries appear in additionalContext"
TMPDIR_MEM=$(mktemp -d)
mkdir -p "$TMPDIR_MEM/.copilot/workspace"
printf 'HEARTBEAT: ok\n' > "$TMPDIR_MEM/.copilot/workspace/HEARTBEAT.md"
printf 'Learned: always prefer small commits over large ones.\n' > "$TMPDIR_MEM/.copilot/workspace/MEMORY.md"
output=$(cd "$TMPDIR_MEM" && echo '{}' | bash "$SAVE_CTX" 2>/dev/null)
assert_contains "MEMORY.md content in context" "$output" "small commits"
assert_valid_json "valid JSON with MEMORY.md" "$output"
rm -rf "$TMPDIR_MEM"
echo ""

echo "21c. SOUL.md heuristics appear in additionalContext"
TMPDIR_SOUL=$(mktemp -d)
mkdir -p "$TMPDIR_SOUL/.copilot/workspace"
printf 'HEARTBEAT: ok\n' > "$TMPDIR_SOUL/.copilot/workspace/HEARTBEAT.md"
printf '## Key heuristics\npattern: test before committing\n' > "$TMPDIR_SOUL/.copilot/workspace/SOUL.md"
output=$(cd "$TMPDIR_SOUL" && echo '{}' | bash "$SAVE_CTX" 2>/dev/null)
assert_contains "SOUL.md heuristics in context" "$output" "test before committing"
assert_valid_json "valid JSON with SOUL.md" "$output"
rm -rf "$TMPDIR_SOUL"
echo ""

echo "22c. Output contains 'additionalContext' key when workspace files exist"
TMPDIR_KEYS=$(mktemp -d)
mkdir -p "$TMPDIR_KEYS/.copilot/workspace"
printf 'HEARTBEAT: running\n' > "$TMPDIR_KEYS/.copilot/workspace/HEARTBEAT.md"
output=$(cd "$TMPDIR_KEYS" && echo '{}' | bash "$SAVE_CTX" 2>/dev/null)
assert_contains "additionalContext key present" "$output" "additionalContext"
assert_contains "PreCompact hookEventName present" "$output" "PreCompact"
rm -rf "$TMPDIR_KEYS"
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
