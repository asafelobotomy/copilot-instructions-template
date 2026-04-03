#!/usr/bin/env bash
# tests/hooks/test-mcp-heartbeat-server.sh -- unit tests for template/hooks/scripts/mcp-heartbeat-server.py
# Run: bash tests/hooks/test-mcp-heartbeat-server.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/template/hooks/scripts/mcp-heartbeat-server.py"
trap cleanup_dirs EXIT

run_reflect() {
  local root_dir="$1"
  TEST_SCRIPT="$SCRIPT" TEST_ROOT="$root_dir" python3 - <<'PY'
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
print(json.dumps(module.session_reflect()))
PY
}

echo "=== mcp-heartbeat-server.py ==="
echo ""

echo "1. Empty workspace returns a small, safe reflection payload"
TMP_EMPTY=$(mktemp -d); CLEANUP_DIRS+=("$TMP_EMPTY")
output=$(run_reflect "$TMP_EMPTY")
status=$?
assert_success "empty workspace exits zero" "$status"
assert_valid_json "empty workspace output is valid JSON" "$output"
REFLECT_OUTPUT="$output" assert_python "empty workspace reports small magnitude and zero metrics" '
payload = json.loads(os.environ["REFLECT_OUTPUT"])
assert payload["magnitude"] == "small"
assert payload["metrics"]["files_changed"] == 0
assert payload["metrics"]["active_work_minutes"] == 0
assert payload["metrics"]["compactions"] == 0
assert payload["workspace_state"] == {
    "soul_exists": False,
    "memory_exists": False,
    "user_exists": False,
}
'
echo ""

echo "2. Significant session metrics produce reflection prompts and complete sentinel"
TMP_SESSION=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_SESSION")
printf '.copilot/\n' >> "$TMP_SESSION/.git/info/exclude"
mkdir -p "$TMP_SESSION/.copilot/workspace"
cat > "$TMP_SESSION/.copilot/workspace/state.json" <<'JSON'
{
  "session_id": "sess-heartbeat",
  "session_start_epoch": 1704067200,
  "session_start_git_count": 0,
  "active_work_seconds": 1800,
  "task_window_start_epoch": 0,
  "last_raw_tool_epoch": 0,
  "copilot_edit_count": 6
}
JSON
cat > "$TMP_SESSION/.copilot/workspace/.heartbeat-events.jsonl" <<'EOF'
{"trigger":"compaction","ts":1704068100,"ts_utc":"2024-01-01T00:15:00Z"}
EOF
printf 'heuristics\n' > "$TMP_SESSION/.copilot/workspace/SOUL.md"
printf 'memory\n' > "$TMP_SESSION/.copilot/workspace/MEMORY.md"
printf 'user\n' > "$TMP_SESSION/.copilot/workspace/USER.md"
output=$(run_reflect "$TMP_SESSION")
status=$?
assert_success "significant session exits zero" "$status"
assert_valid_json "significant session output is valid JSON" "$output"
REFLECT_OUTPUT="$output" assert_python "significant session reports large metrics and prompts" '
payload = json.loads(os.environ["REFLECT_OUTPUT"])
assert payload["magnitude"] == "large"
assert payload["metrics"]["files_changed"] == 6
assert payload["metrics"]["active_work_minutes"] == 30
assert payload["metrics"]["compactions"] == 1
assert payload["workspace_state"] == {
    "soul_exists": True,
    "memory_exists": True,
    "user_exists": True,
}
joined = " ".join(payload["reflection_prompts"])
assert "6 files edited (committed)" in joined
assert "Context compaction occurred" in joined
assert "test coverage and documentation kept pace" in joined
'
assert_matches "sentinel is marked complete" "$(cat "$TMP_SESSION/.copilot/workspace/.heartbeat-session")" 'sess-heartbeat\|.*\|complete'
echo ""

echo "3. Corrupt state falls back safely and still completes the sentinel"
TMP_CORRUPT=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CORRUPT")
mkdir -p "$TMP_CORRUPT/.copilot/workspace"
printf 'not json\n' > "$TMP_CORRUPT/.copilot/workspace/state.json"
output=$(run_reflect "$TMP_CORRUPT")
status=$?
assert_success "corrupt state exits zero" "$status"
assert_valid_json "corrupt state output is valid JSON" "$output"
REFLECT_OUTPUT="$output" assert_python "corrupt state falls back to small payload" '
payload = json.loads(os.environ["REFLECT_OUTPUT"])
assert payload["magnitude"] == "small"
assert payload["metrics"]["files_changed"] == 0
'
assert_matches "corrupt state sentinel uses unknown session id" "$(cat "$TMP_CORRUPT/.copilot/workspace/.heartbeat-session")" 'unknown\|.*\|complete'
echo ""

finish_tests