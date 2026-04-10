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
import tempfile
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

forced_tmp = os.environ.get("TEST_FORCE_GETTEMPDIR")
if forced_tmp:
  tempfile.gettempdir = lambda: forced_tmp

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
mkdir -p "$TMP_SESSION/.copilot/workspace/identity" "$TMP_SESSION/.copilot/workspace/knowledge/diaries" "$TMP_SESSION/.copilot/workspace/operations" "$TMP_SESSION/.copilot/workspace/runtime"
cat > "$TMP_SESSION/.copilot/workspace/runtime/state.json" <<'JSON'
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
cat > "$TMP_SESSION/.copilot/workspace/runtime/.heartbeat-events.jsonl" <<'EOF'
{"trigger":"compaction","ts":1704068100,"ts_utc":"2024-01-01T00:15:00Z"}
EOF
printf 'heuristics\n' > "$TMP_SESSION/.copilot/workspace/identity/SOUL.md"
printf 'memory\n' > "$TMP_SESSION/.copilot/workspace/knowledge/MEMORY.md"
printf 'user\n' > "$TMP_SESSION/.copilot/workspace/knowledge/USER.md"
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
assert_matches "sentinel is marked complete" "$(cat "$TMP_SESSION/.copilot/workspace/runtime/.heartbeat-session")" 'sess-heartbeat\|.*\|complete'
assert_python_in_root "session_reflect appends a completion event" "$TMP_SESSION" '
events = [json.loads(line) for line in (root / ".copilot/workspace/runtime/.heartbeat-events.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
event = events[-1]
assert event["trigger"] == "session_reflect"
assert event["detail"] == "complete"
assert event["session_id"] == "sess-heartbeat"
'
echo ""

echo "3. Reflection metrics ignore compactions from other sessions"
TMP_SCOPE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_SCOPE")
printf '.copilot/\n' >> "$TMP_SCOPE/.git/info/exclude"
mkdir -p "$TMP_SCOPE/.copilot/workspace/identity" "$TMP_SCOPE/.copilot/workspace/knowledge/diaries" "$TMP_SCOPE/.copilot/workspace/operations" "$TMP_SCOPE/.copilot/workspace/runtime"
cat > "$TMP_SCOPE/.copilot/workspace/runtime/state.json" <<'JSON'
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
cat > "$TMP_SCOPE/.copilot/workspace/runtime/.heartbeat-events.jsonl" <<'EOF'
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
mkdir -p "$TMP_CORRUPT/.copilot/workspace/identity" "$TMP_CORRUPT/.copilot/workspace/knowledge/diaries" "$TMP_CORRUPT/.copilot/workspace/operations" "$TMP_CORRUPT/.copilot/workspace/runtime"
printf 'not json\n' > "$TMP_CORRUPT/.copilot/workspace/runtime/state.json"
output=$(run_reflect "$TMP_CORRUPT")
status=$?
assert_success "corrupt state exits zero" "$status"
assert_valid_json "corrupt state output is valid JSON" "$output"
REFLECT_OUTPUT="$output" assert_python "corrupt state falls back to small payload" '
payload = json.loads(os.environ["REFLECT_OUTPUT"])
assert payload["magnitude"] == "small"
assert payload["metrics"]["files_changed"] == 0
'
assert_matches "corrupt state sentinel uses unknown session id" "$(cat "$TMP_CORRUPT/.copilot/workspace/runtime/.heartbeat-session")" 'unknown\|.*\|complete'
echo ""

echo "6. memory_protocol key is always present in response"
REFLECT_OUTPUT="$output" assert_python "memory_protocol is a non-empty string" '
payload = json.loads(os.environ["REFLECT_OUTPUT"])
assert "memory_protocol" in payload
assert isinstance(payload["memory_protocol"], str)
assert len(payload["memory_protocol"]) > 0
assert "§14" in payload["memory_protocol"]
'
echo ""

echo "7. _load_workspace_cues extracts SOUL.md values and stops at section heading"
TMP_CUES=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CUES")
mkdir -p "$TMP_CUES/.copilot/workspace/identity" "$TMP_CUES/.copilot/workspace/knowledge/diaries" "$TMP_CUES/.copilot/workspace/operations" "$TMP_CUES/.copilot/workspace/runtime"
cat > "$TMP_CUES/.copilot/workspace/runtime/state.json" <<'JSON'
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
cat > "$TMP_CUES/.copilot/workspace/identity/SOUL.md" <<'EOF'
# Values

- **YAGNI** — do not build unneeded.
- **Small batches** — prefer smaller PRs.

## Session 2026-04-09

- **Leaky heuristic** — this should NOT appear.
EOF
cat > "$TMP_CUES/.copilot/workspace/knowledge/USER.md" <<'EOF'
# User Profile

| Attribute | Observed value |
|-----------|---------------|
| Style | Analytical and structured |
| Autonomy | High |
| Empty | *(to be discovered)* |
EOF
cat > "$TMP_CUES/.copilot/workspace/knowledge/MEMORY.md" <<'EOF'
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
mkdir -p "$TMP_NOCUES/.copilot/workspace/identity" "$TMP_NOCUES/.copilot/workspace/knowledge/diaries" "$TMP_NOCUES/.copilot/workspace/operations" "$TMP_NOCUES/.copilot/workspace/runtime"
cat > "$TMP_NOCUES/.copilot/workspace/runtime/state.json" <<'JSON'
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

echo "9. Read-only workspace artifacts fall back to TMPDIR storage"
TMP_READONLY=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_READONLY")
printf '.copilot/\n' >> "$TMP_READONLY/.git/info/exclude"
mkdir -p "$TMP_READONLY/.copilot/workspace/identity" "$TMP_READONLY/.copilot/workspace/knowledge/diaries" "$TMP_READONLY/.copilot/workspace/operations" "$TMP_READONLY/.copilot/workspace/runtime"
mkdir -p "$TMP_READONLY/runtime-tmp"
cat > "$TMP_READONLY/.copilot/workspace/runtime/state.json" <<'JSON'
{
  "session_id": "sess-readonly",
  "session_start_epoch": 1704067200,
  "session_start_git_count": 0,
  "active_work_seconds": 1800,
  "task_window_start_epoch": 0,
  "last_raw_tool_epoch": 0,
  "copilot_edit_count": 6
}
JSON
chmod 0555 "$TMP_READONLY/.copilot/workspace/runtime"
chmod 0555 "$TMP_READONLY/.copilot/workspace"
output=$(CLAUDE_TMPDIR='' TMPDIR="$TMP_READONLY/runtime-tmp" run_reflect "$TMP_READONLY")
status=$?
chmod 0755 "$TMP_READONLY/.copilot/workspace"
chmod 0755 "$TMP_READONLY/.copilot/workspace/runtime"
assert_success "read-only workspace exits zero" "$status"
assert_valid_json "read-only workspace output is valid JSON" "$output"
REFLECT_OUTPUT="$output" assert_python "read-only workspace still reports the session" '
payload = json.loads(os.environ["REFLECT_OUTPUT"])
assert payload["magnitude"] == "large"
assert payload["metrics"]["files_changed"] == 6
'
assert_python_in_root "read-only workspace writes sentinel and events into fallback storage" "$TMP_READONLY" '
import hashlib
import tempfile
from pathlib import Path

tmp_root = Path(root / "runtime-tmp")
repo_key = hashlib.sha256(str(root).encode("utf-8")).hexdigest()[:12]
runtime_dir = tmp_root / "copilot-heartbeat" / repo_key
sentinel = runtime_dir / ".heartbeat-session"
events = runtime_dir / ".heartbeat-events.jsonl"
assert sentinel.exists(), sentinel
assert events.exists(), events
assert "|complete" in sentinel.read_text(encoding="utf-8")
lines = [json.loads(line) for line in events.read_text(encoding="utf-8").splitlines() if line.strip()]
assert lines[-1]["trigger"] == "session_reflect"
assert lines[-1]["session_id"] == "sess-readonly"
'
echo ""

echo "10. Read-only TMPDIR falls through to home cache storage"
TMP_HOMECACHE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_HOMECACHE")
printf '.copilot/\n' >> "$TMP_HOMECACHE/.git/info/exclude"
mkdir -p "$TMP_HOMECACHE/.copilot/workspace/identity" "$TMP_HOMECACHE/.copilot/workspace/knowledge/diaries" "$TMP_HOMECACHE/.copilot/workspace/operations" "$TMP_HOMECACHE/.copilot/workspace/runtime"
mkdir -p "$TMP_HOMECACHE/blocked-tmp"
cat > "$TMP_HOMECACHE/.copilot/workspace/runtime/state.json" <<'JSON'
{
  "session_id": "sess-homecache",
  "session_start_epoch": 1704067200,
  "session_start_git_count": 0,
  "active_work_seconds": 1800,
  "task_window_start_epoch": 0,
  "last_raw_tool_epoch": 0,
  "copilot_edit_count": 6
}
JSON
chmod 0555 "$TMP_HOMECACHE/.copilot/workspace/runtime"
chmod 0555 "$TMP_HOMECACHE/.copilot/workspace"
chmod 0555 "$TMP_HOMECACHE/blocked-tmp"
output=$(CLAUDE_TMPDIR='' XDG_CACHE_HOME="$TMP_HOMECACHE/.cache" HOME="$TMP_HOMECACHE" TMPDIR="$TMP_HOMECACHE/blocked-tmp" TEST_FORCE_GETTEMPDIR="$TMP_HOMECACHE/blocked-tmp" run_reflect "$TMP_HOMECACHE")
status=$?
chmod 0755 "$TMP_HOMECACHE/.copilot/workspace"
chmod 0755 "$TMP_HOMECACHE/.copilot/workspace/runtime"
chmod 0755 "$TMP_HOMECACHE/blocked-tmp"
assert_success "blocked TMPDIR exits zero" "$status"
assert_valid_json "blocked TMPDIR output is valid JSON" "$output"
assert_python_in_root "blocked TMPDIR writes heartbeat artifacts into home cache" "$TMP_HOMECACHE" '
import hashlib
from pathlib import Path

repo_key = hashlib.sha256(str(root).encode("utf-8")).hexdigest()[:12]
runtime_dir = root / ".cache/uv/copilot-heartbeat" / repo_key
sentinel = runtime_dir / ".heartbeat-session"
events = runtime_dir / ".heartbeat-events.jsonl"
assert sentinel.exists(), sentinel
assert events.exists(), events
assert "|complete" in sentinel.read_text(encoding="utf-8")
lines = [json.loads(line) for line in events.read_text(encoding="utf-8").splitlines() if line.strip()]
assert lines[-1]["trigger"] == "session_reflect"
assert lines[-1]["session_id"] == "sess-homecache"
'
echo ""

echo "11. CLAUDE_TMPDIR is preferred when TMPDIR is blocked"
TMP_CLAUDE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_CLAUDE")
printf '.copilot/\n' >> "$TMP_CLAUDE/.git/info/exclude"
mkdir -p "$TMP_CLAUDE/.copilot/workspace/identity" "$TMP_CLAUDE/.copilot/workspace/knowledge/diaries" "$TMP_CLAUDE/.copilot/workspace/operations" "$TMP_CLAUDE/.copilot/workspace/runtime" "$TMP_CLAUDE/blocked-tmp" "$TMP_CLAUDE/claude-tmp"
cat > "$TMP_CLAUDE/.copilot/workspace/runtime/state.json" <<'JSON'
{
  "session_id": "sess-claude",
  "session_start_epoch": 1704067200,
  "session_start_git_count": 0,
  "active_work_seconds": 1800,
  "task_window_start_epoch": 0,
  "last_raw_tool_epoch": 0,
  "copilot_edit_count": 6
}
JSON
chmod 0555 "$TMP_CLAUDE/.copilot/workspace/runtime"
chmod 0555 "$TMP_CLAUDE/.copilot/workspace"
chmod 0555 "$TMP_CLAUDE/blocked-tmp"
output=$(CLAUDE_TMPDIR="$TMP_CLAUDE/claude-tmp" TMPDIR="$TMP_CLAUDE/blocked-tmp" TEST_FORCE_GETTEMPDIR="$TMP_CLAUDE/blocked-tmp" run_reflect "$TMP_CLAUDE")
status=$?
chmod 0755 "$TMP_CLAUDE/.copilot/workspace"
chmod 0755 "$TMP_CLAUDE/.copilot/workspace/runtime"
chmod 0755 "$TMP_CLAUDE/blocked-tmp"
assert_success "blocked TMPDIR with CLAUDE_TMPDIR exits zero" "$status"
assert_valid_json "blocked TMPDIR with CLAUDE_TMPDIR output is valid JSON" "$output"
assert_python_in_root "CLAUDE_TMPDIR receives heartbeat artifacts" "$TMP_CLAUDE" '
import hashlib
from pathlib import Path

repo_key = hashlib.sha256(str(root).encode("utf-8")).hexdigest()[:12]
runtime_dir = root / "claude-tmp/copilot-heartbeat" / repo_key
sentinel = runtime_dir / ".heartbeat-session"
events = runtime_dir / ".heartbeat-events.jsonl"
assert sentinel.exists(), sentinel
assert events.exists(), events
assert "|complete" in sentinel.read_text(encoding="utf-8")
lines = [json.loads(line) for line in events.read_text(encoding="utf-8").splitlines() if line.strip()]
assert lines[-1]["trigger"] == "session_reflect"
assert lines[-1]["session_id"] == "sess-claude"
'
echo ""

echo "12. Stale sentinel temp files do not block fallback storage"
TMP_STALE=$(make_git_sandbox); CLEANUP_DIRS+=("$TMP_STALE")
printf '.copilot/\n' >> "$TMP_STALE/.git/info/exclude"
mkdir -p "$TMP_STALE/.copilot/workspace/identity" "$TMP_STALE/.copilot/workspace/knowledge/diaries" "$TMP_STALE/.copilot/workspace/operations" "$TMP_STALE/.copilot/workspace/runtime" "$TMP_STALE/runtime-tmp"
cat > "$TMP_STALE/.copilot/workspace/runtime/state.json" <<'JSON'
{
  "session_id": "sess-stale",
  "session_start_epoch": 1704067200,
  "session_start_git_count": 0,
  "active_work_seconds": 1800,
  "task_window_start_epoch": 0,
  "last_raw_tool_epoch": 0,
  "copilot_edit_count": 6
}
JSON
printf 'stale\n' > "$TMP_STALE/.copilot/workspace/runtime/.heartbeat-session.tmp"
chmod 0555 "$TMP_STALE/.copilot/workspace/runtime"
chmod 0555 "$TMP_STALE/.copilot/workspace"
output=$(CLAUDE_TMPDIR='' TMPDIR="$TMP_STALE/runtime-tmp" run_reflect "$TMP_STALE")
status=$?
chmod 0755 "$TMP_STALE/.copilot/workspace"
chmod 0755 "$TMP_STALE/.copilot/workspace/runtime"
assert_success "stale sentinel temp exits zero" "$status"
assert_valid_json "stale sentinel temp output is valid JSON" "$output"
assert_python_in_root "stale sentinel temp still falls back to runtime storage" "$TMP_STALE" '
import hashlib
from pathlib import Path

tmp_root = Path(root / "runtime-tmp")
repo_key = hashlib.sha256(str(root).encode("utf-8")).hexdigest()[:12]
runtime_dir = tmp_root / "copilot-heartbeat" / repo_key
sentinel = runtime_dir / ".heartbeat-session"
events = runtime_dir / ".heartbeat-events.jsonl"
assert sentinel.exists(), sentinel
assert events.exists(), events
assert "|complete" in sentinel.read_text(encoding="utf-8")
lines = [json.loads(line) for line in events.read_text(encoding="utf-8").splitlines() if line.strip()]
assert lines[-1]["trigger"] == "session_reflect"
assert lines[-1]["session_id"] == "sess-stale"
'
echo ""

finish_tests