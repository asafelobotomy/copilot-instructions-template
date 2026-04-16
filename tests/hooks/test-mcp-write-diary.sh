#!/usr/bin/env bash
# tests/hooks/test-mcp-write-diary.sh -- unit tests for write_diary and read_diaries MCP tools
# Run: bash tests/hooks/test-mcp-write-diary.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/hooks/scripts/mcp-heartbeat-server.py"
CLOCK_SCRIPT="$REPO_ROOT/hooks/scripts/heartbeat_clock_summary.py"
trap cleanup_dirs EXIT

# ---------------------------------------------------------------------------
# Loader helper: import the MCP module with a stubbed FastMCP so mcp.run()
# is a no-op. Exposes write_diary and read_diaries as plain Python functions.
# ---------------------------------------------------------------------------
run_diary_py() {
  local root_dir="$1"
  shift
  TEST_SCRIPT="$SCRIPT" TEST_ROOT="$root_dir" PYTHONPATH="$(dirname "$CLOCK_SCRIPT")" \
    python3 - "$@" <<'PY'
import importlib.util
import json
import os
import sys
import types

class FakeMCP:
    def __init__(self, name):
        self.name = name
    def tool(self):
        def decorator(fn):
            return fn
        return decorator
    def run(self):
        return None

mcp_mod = types.ModuleType("mcp")
server_mod = types.ModuleType("mcp.server")
fastmcp_mod = types.ModuleType("mcp.server.fastmcp")
fastmcp_mod.FastMCP = FakeMCP
sys.modules["mcp"] = mcp_mod
sys.modules["mcp.server"] = server_mod
sys.modules["mcp.server.fastmcp"] = fastmcp_mod

os.chdir(os.environ["TEST_ROOT"])
spec = importlib.util.spec_from_file_location("heartbeat_mcp", os.environ["TEST_SCRIPT"])
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

cmd = sys.argv[1]
if cmd == "write":
    result = module.write_diary(sys.argv[2], sys.argv[3])
elif cmd == "read":
    result = module.read_diaries(sys.argv[2] if len(sys.argv) > 2 else "")
else:
    result = {"error": f"unknown cmd {cmd}"}
print(json.dumps(result))
PY
}

echo "=== write_diary + read_diaries tools ==="
echo ""

echo "1. write_diary creates file and returns written status"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
output=$(run_diary_py "$TMP" write "Explore" "Found auth pattern in handler")
status=$?
assert_success "write_diary exits zero" "$status"
assert_valid_json "write_diary emits valid JSON" "$output"
DIARY_OUT="$output" assert_python "status is written" \
  "payload = json.loads(os.environ['DIARY_OUT']); assert payload['status'] == 'written'"
assert_file_exists "diary file created" "$TMP/.copilot/workspace/knowledge/diaries/explore.md"
assert_file_contains "diary has header" "$TMP/.copilot/workspace/knowledge/diaries/explore.md" "# Explore Diary"
assert_file_contains "diary has finding" "$TMP/.copilot/workspace/knowledge/diaries/explore.md" "Found auth pattern in handler"
echo ""

echo "2. write_diary deduplicates identical findings"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
run_diary_py "$TMP" write "Audit" "No secrets found" >/dev/null
output=$(run_diary_py "$TMP" write "Audit" "No secrets found")
status=$?
assert_success "dedup exits zero" "$status"
assert_valid_json "dedup emits valid JSON" "$output"
DIARY_OUT="$output" assert_python "status is skipped" \
  "payload = json.loads(os.environ['DIARY_OUT']); assert payload['status'] == 'skipped'"
DIARY="$TMP/.copilot/workspace/knowledge/diaries/audit.md"
MATCH_COUNT=$(grep -c "No secrets found" "$DIARY")
if [[ "$MATCH_COUNT" -eq 1 ]]; then
  pass_note "duplicate written exactly once (count=$MATCH_COUNT)"
else
  fail_note "dedup failed" "  expected 1, got $MATCH_COUNT"
fi
echo ""

echo "3. write_diary enforces 30-line cap"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
for i in $(seq 1 35); do
  run_diary_py "$TMP" write "Code" "Unique finding number $i in the codebase" >/dev/null
done
DIARY="$TMP/.copilot/workspace/knowledge/diaries/code.md"
LINE_COUNT=$(wc -l < "$DIARY")
if (( LINE_COUNT <= 30 )); then
  pass_note "diary stays within 30-line cap (got $LINE_COUNT)"
else
  fail_note "diary exceeds 30-line cap" "  expected ≤30, got $LINE_COUNT"
fi
echo ""

echo "4. write_diary rejects empty agent_name"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
output=$(run_diary_py "$TMP" write "" "some finding")
status=$?
assert_success "empty agent_name exits zero" "$status"
assert_valid_json "empty agent_name emits valid JSON" "$output"
DIARY_OUT="$output" assert_python "error returned" \
  "payload = json.loads(os.environ['DIARY_OUT']); assert 'error' in payload"
echo ""

echo "5. read_diaries returns entries for a specific agent"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
run_diary_py "$TMP" write "Review" "Cache layer refactored" >/dev/null
run_diary_py "$TMP" write "Review" "Auth module has no tests" >/dev/null
output=$(run_diary_py "$TMP" read "Review")
status=$?
assert_success "read_diaries exits zero" "$status"
assert_valid_json "read_diaries emits valid JSON" "$output"
DIARY_OUT="$output" assert_python "entries returned" \
  "payload = json.loads(os.environ['DIARY_OUT']); assert len(payload['entries']) == 2"
assert_contains "first finding present" "$output" "Cache layer refactored"
assert_contains "second finding present" "$output" "Auth module has no tests"
echo ""

echo "6. read_diaries returns note when agent has no diary"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
output=$(run_diary_py "$TMP" read "Explore")
status=$?
assert_success "no-diary read exits zero" "$status"
assert_valid_json "no-diary read emits valid JSON" "$output"
DIARY_OUT="$output" assert_python "no-diary note returned" \
  "payload = json.loads(os.environ['DIARY_OUT']); assert payload.get('note') == 'no diary yet'"
echo ""

echo "7. read_diaries with no agent_name returns all agents"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
run_diary_py "$TMP" write "Explore" "Entry for Explore" >/dev/null
run_diary_py "$TMP" write "Audit" "Entry for Audit" >/dev/null
output=$(run_diary_py "$TMP" read)
status=$?
assert_success "all-agents read exits zero" "$status"
assert_valid_json "all-agents read emits valid JSON" "$output"
DIARY_OUT="$output" assert_python "both agents present" '
payload = json.loads(os.environ["DIARY_OUT"])
assert "diaries" in payload
assert "explore" in payload["diaries"]
assert "audit" in payload["diaries"]
'
echo ""

finish_tests
