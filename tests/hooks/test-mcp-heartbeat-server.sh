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
assert_python_in_root "session_reflect appends a completion event" "$TMP_SESSION" '
events = [json.loads(line) for line in (root / ".copilot/workspace/.heartbeat-events.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
event = events[-1]
assert event["trigger"] == "session_reflect"
assert event["detail"] == "complete"
assert event["session_id"] == "sess-heartbeat"
'
echo ""

echo "3. Reflection metrics ignore compactions from other sessions"
TMP_SCOPE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_SCOPE")
printf '.copilot/\n' >> "$TMP_SCOPE/.git/info/exclude"
mkdir -p "$TMP_SCOPE/.copilot/workspace"
cat > "$TMP_SCOPE/.copilot/workspace/state.json" <<'JSON'
{
    "session_id": "sess-current",
    "session_start_epoch": 1704067200,
    "session_start_git_count": 0,
    "active_work_seconds": 1800,
    "task_window_start_epoch": 0,
    "last_raw_tool_epoch": 0,
    "copilot_edit_count": 6
}
JSON
cat > "$TMP_SCOPE/.copilot/workspace/.heartbeat-events.jsonl" <<'EOF'
{"detail":"complete","session_id":"sess-old","trigger":"session_reflect","ts":1704067000,"ts_utc":"2023-12-31T23:56:40Z"}
{"session_id":"sess-old","trigger":"compaction","ts":1704067100,"ts_utc":"2023-12-31T23:58:20Z"}
{"session_id":"sess-current","trigger":"compaction","ts":1704068100,"ts_utc":"2024-01-01T00:15:00Z"}
EOF
output=$(run_reflect "$TMP_SCOPE")
status=$?
assert_success "scoped reflection exits zero" "$status"
assert_valid_json "scoped reflection output is valid JSON" "$output"
REFLECT_OUTPUT="$output" assert_python "scoped reflection only counts current-session compactions" '
payload = json.loads(os.environ["REFLECT_OUTPUT"])
assert payload["metrics"]["compactions"] == 1
'
echo ""

echo "4. Source guidance uses the strong or supporting threshold contract"
assert_contains "mcp heartbeat server docstring matches threshold contract" "$(cat "$SCRIPT")" 'one strong signal: 8+ modified files or 30+ minutes active; or two'
echo ""

echo "5. Corrupt state falls back safely and still completes the sentinel"
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

echo "6. memory_protocol key is always present in response"
REFLECT_OUTPUT="$output" assert_python "memory_protocol is a non-empty string" '
payload = json.loads(os.environ["REFLECT_OUTPUT"])
assert "memory_protocol" in payload
assert isinstance(payload["memory_protocol"], str)
assert "check MEMORY.md" in payload["memory_protocol"]
assert "check SOUL.md" in payload["memory_protocol"]
assert "provenance convention" in payload["memory_protocol"]
'
echo ""

echo "7. _load_workspace_cues extracts SOUL.md values and stops at section heading"
TMP_CUES=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CUES")
mkdir -p "$TMP_CUES/.copilot/workspace"
cat > "$TMP_CUES/.copilot/workspace/state.json" <<'JSON'
{
  "session_id": "sess-cues",
  "session_start_epoch": 1704067200,
  "session_start_git_count": 0,
  "active_work_seconds": 2400,
  "task_window_start_epoch": 0,
  "last_raw_tool_epoch": 0,
  "copilot_edit_count": 10
}
JSON
cat > "$TMP_CUES/.copilot/workspace/SOUL.md" <<'EOF'
# Values

- **YAGNI** — do not build unneeded.
- **Small batches** — prefer smaller PRs.

## Session 2026-04-09

- **Leaky heuristic** — this should NOT appear.
EOF
cat > "$TMP_CUES/.copilot/workspace/USER.md" <<'EOF'
# User Profile

| Attribute | Observed value |
|-----------|---------------|
| Style | Analytical and structured |
| Autonomy | High |
| Empty | *(to be discovered)* |
EOF
cat > "$TMP_CUES/.copilot/workspace/MEMORY.md" <<'EOF'
memory
EOF
output=$(run_reflect "$TMP_CUES")
status=$?
assert_success "_load_workspace_cues exits zero" "$status"
assert_valid_json "_load_workspace_cues output is valid JSON" "$output"
REFLECT_OUTPUT="$output" assert_python "SOUL values extracted with section boundary and USER attributes parsed" '
payload = json.loads(os.environ["REFLECT_OUTPUT"])
prompts = " ".join(payload["reflection_prompts"])
# SOUL values should include core values only
assert "YAGNI" in prompts, f"YAGNI missing from prompts: {prompts}"
assert "Small batches" in prompts, f"Small batches missing from prompts: {prompts}"
# Session heuristic must NOT leak
assert "Leaky heuristic" not in prompts, f"Session heuristic leaked: {prompts}"
# USER attribute should appear
assert "Style: Analytical" in prompts, f"USER attribute missing: {prompts}"
# to-be-discovered should be filtered
assert "to be discovered" not in prompts, f"Placeholder leaked: {prompts}"
'
echo ""

echo "8. _load_workspace_cues gracefully handles missing workspace files"
TMP_NOCUES=$(mktemp -d); CLEANUP_DIRS+=("$TMP_NOCUES")
mkdir -p "$TMP_NOCUES/.copilot/workspace"
cat > "$TMP_NOCUES/.copilot/workspace/state.json" <<'JSON'
{
  "session_id": "sess-nocues",
  "session_start_epoch": 1704067200,
  "session_start_git_count": 0,
  "active_work_seconds": 2400,
  "task_window_start_epoch": 0,
  "last_raw_tool_epoch": 0,
  "copilot_edit_count": 10
}
JSON
output=$(run_reflect "$TMP_NOCUES")
status=$?
assert_success "no cues files exits zero" "$status"
REFLECT_OUTPUT="$output" assert_python "no personalised prompts when files missing" '
payload = json.loads(os.environ["REFLECT_OUTPUT"])
prompts = " ".join(payload["reflection_prompts"])
assert "SOUL values" not in prompts
assert "USER cue" not in prompts
'
echo ""

finish_tests