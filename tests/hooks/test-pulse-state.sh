#!/usr/bin/env bash
# tests/hooks/test-pulse-state.sh -- unit tests for template/hooks/scripts/pulse_state.py
# Run: bash tests/hooks/test-pulse-state.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
MODULE_PATH="$REPO_ROOT/template/hooks/scripts/pulse_state.py"
export MODULE_PATH
trap cleanup_dirs EXIT

echo "=== pulse_state.py ==="
echo ""

echo "1. default_state starts from the expected heartbeat baseline"
assert_python "default_state initializes baseline fields" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
state = module.default_state()
assert state["session_id"] == "unknown"
assert state["session_state"] == "pending"
assert state["retrospective_state"] == "idle"
assert state["intent_phase"] == "quiet"
assert state["tool_call_counter"] == 0
assert state["changed_path_families"] == []
assert state["touched_files_sample"] == []
'
echo ""

echo "2. load_state falls back to defaults when the state file is missing"
TMP_MISSING=$(mktemp -d); CLEANUP_DIRS+=("$TMP_MISSING")
assert_python_in_root "missing state file returns defaults" "$TMP_MISSING" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
state = module.load_state(root / ".copilot/workspace/state.json")
assert state == module.default_state()
'
echo ""

echo "3. load_state merges known fields and ignores unknown ones"
TMP_PARTIAL=$(mktemp -d); CLEANUP_DIRS+=("$TMP_PARTIAL")
mkdir -p "$TMP_PARTIAL/.copilot/workspace"
cat > "$TMP_PARTIAL/.copilot/workspace/state.json" <<'EOF'
{
  "session_id": "sess-partial",
  "tool_call_counter": 7,
  "unknown_key": "ignore-me"
}
EOF
assert_python_in_root "partial state overlays defaults without keeping unknown keys" "$TMP_PARTIAL" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
state = module.load_state(root / ".copilot/workspace/state.json")
assert state["session_id"] == "sess-partial"
assert state["tool_call_counter"] == 7
assert "unknown_key" not in state
assert state["intent_phase"] == "quiet"
'
echo ""

echo "4. corrupt state and policy files fall back safely to defaults"
TMP_CORRUPT=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CORRUPT")
mkdir -p "$TMP_CORRUPT/.copilot/workspace"
printf '{broken-json\n' > "$TMP_CORRUPT/.copilot/workspace/state.json"
printf '{broken-json\n' > "$TMP_CORRUPT/policy.json"
assert_python_in_root "corrupt files fall back to defaults" "$TMP_CORRUPT" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
state = module.load_state(root / ".copilot/workspace/state.json")
policy = module.load_policy(root / "policy.json")
assert state == module.default_state()
assert policy == module.DEFAULT_POLICY
'
echo ""

echo "5. save_state respects workspace existence and writes valid JSON when present"
TMP_SAVE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_SAVE")
assert_python_in_root "save_state skips missing workspaces and writes present ones" "$TMP_SAVE" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
workspace = root / ".copilot/workspace"
state_path = workspace / "state.json"
state = module.default_state()
state["session_id"] = "sess-save"
module.save_state(state, workspace, state_path)
assert not state_path.exists()
workspace.mkdir(parents=True)
module.save_state(state, workspace, state_path)
saved = json.loads(state_path.read_text(encoding="utf-8"))
assert saved["session_id"] == "sess-save"
assert saved["schema_version"] == 1
'
echo ""

echo "6. sentinel and reflection completion helpers recognize completed sessions"
TMP_EVENTS=$(mktemp -d); CLEANUP_DIRS+=("$TMP_EVENTS")
mkdir -p "$TMP_EVENTS/.copilot/workspace"
assert_python_in_root "sentinel and event helpers detect completed sessions" "$TMP_EVENTS" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
workspace = root / ".copilot/workspace"
sentinel_path = workspace / ".heartbeat-session"
events_path = workspace / ".heartbeat-events.jsonl"
module.set_sentinel(sentinel_path, workspace, 1704067200, "sess-complete", "pending")
assert module.sentinel_is_complete(sentinel_path) is False
module.set_sentinel(sentinel_path, workspace, 1704067200, "sess-complete", "complete")
assert module.sentinel_is_complete(sentinel_path) is True
events_path.write_text(
    json.dumps({"trigger": "session_reflect", "detail": "complete", "session_id": "sess-complete", "ts": 1704068400}) + "\n"
    + json.dumps({"trigger": "session_reflect", "detail": "complete", "ts": 1704068500}) + "\n",
    encoding="utf-8",
)
assert module.reflection_event_complete(events_path, "sess-complete", 1704067200) is True
assert module.reflection_event_complete(events_path, "other-session", 1704069000) is False
assert module.reflection_event_complete(events_path, "fallback-session", 1704067200) is True
'
echo ""

echo "6b. sentinel and event helpers fall back to TMPDIR storage when workspace artifacts are absent"
TMP_FALLBACK=$(mktemp -d); CLEANUP_DIRS+=("$TMP_FALLBACK")
mkdir -p "$TMP_FALLBACK/.copilot/workspace"
assert_python_in_root "helpers read heartbeat completion from fallback storage" "$TMP_FALLBACK" '
import importlib.util

os.environ.pop("CLAUDE_TMPDIR", None)
os.environ["TMPDIR"] = str(root / "runtime-tmp")
spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
workspace = root / ".copilot/workspace"
sentinel_path = workspace / ".heartbeat-session"
events_path = workspace / ".heartbeat-events.jsonl"
fallback_sentinel = module.fallback_artifact_path(sentinel_path)
fallback_events = module.fallback_artifact_path(events_path)
fallback_sentinel.parent.mkdir(parents=True, exist_ok=True)
fallback_sentinel.write_text("sess-fallback|2024-01-01T00:00:00Z|complete\n", encoding="utf-8")
fallback_events.write_text(
  json.dumps({"trigger": "session_reflect", "detail": "complete", "session_id": "sess-fallback", "ts": 1704068400}) + "\n",
  encoding="utf-8",
)
assert module.sentinel_is_complete(sentinel_path) is True
assert module.reflection_event_complete(events_path, "sess-fallback", 1704067200) is True
'
echo ""

echo "6c. writes fall through to home cache when TMPDIR is unavailable"
TMP_CACHE_FALLBACK=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CACHE_FALLBACK")
mkdir -p "$TMP_CACHE_FALLBACK/.copilot/workspace"
mkdir -p "$TMP_CACHE_FALLBACK/blocked-tmp"
chmod 0555 "$TMP_CACHE_FALLBACK/blocked-tmp"
assert_python_in_root "helpers write heartbeat artifacts into home cache when TMPDIR is blocked" "$TMP_CACHE_FALLBACK" '
import importlib.util

os.environ.pop("CLAUDE_TMPDIR", None)
os.environ["TMPDIR"] = str(root / "blocked-tmp")
os.environ["XDG_CACHE_HOME"] = str(root / ".cache")
spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.tempfile.gettempdir = lambda: str(root / "blocked-tmp")
workspace = root / ".copilot/workspace"
sentinel_path = workspace / ".heartbeat-session"
events_path = workspace / ".heartbeat-events.jsonl"
workspace.chmod(0o555)
try:
  module.set_sentinel(sentinel_path, workspace, 1704067200, "sess-cache", "complete")
  module.append_event(events_path, workspace, 1704068400, "session_reflect", "complete", session_id="sess-cache")
finally:
  workspace.chmod(0o755)
home_sentinel = root / ".cache/uv/copilot-heartbeat"
matches = list(home_sentinel.glob("*/.heartbeat-session"))
event_matches = list(home_sentinel.glob("*/.heartbeat-events.jsonl"))
assert len(matches) == 1, matches
assert len(event_matches) == 1, event_matches
assert "|complete" in matches[0].read_text(encoding="utf-8")
assert module.sentinel_is_complete(sentinel_path) is True
assert module.reflection_event_complete(events_path, "sess-cache", 1704067200) is True
'
chmod 0755 "$TMP_CACHE_FALLBACK/blocked-tmp"
echo ""

echo "6d. CLAUDE_TMPDIR is preferred over blocked TMPDIR"
TMP_CLAUDE_TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CLAUDE_TMP")
mkdir -p "$TMP_CLAUDE_TMP/.copilot/workspace"
mkdir -p "$TMP_CLAUDE_TMP/blocked-tmp" "$TMP_CLAUDE_TMP/claude-tmp"
chmod 0555 "$TMP_CLAUDE_TMP/blocked-tmp"
assert_python_in_root "helpers write heartbeat artifacts into CLAUDE_TMPDIR when TMPDIR is blocked" "$TMP_CLAUDE_TMP" '
import importlib.util

os.environ["TMPDIR"] = str(root / "blocked-tmp")
os.environ["CLAUDE_TMPDIR"] = str(root / "claude-tmp")
spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.tempfile.gettempdir = lambda: str(root / "blocked-tmp")
workspace = root / ".copilot/workspace"
sentinel_path = workspace / ".heartbeat-session"
events_path = workspace / ".heartbeat-events.jsonl"
workspace.chmod(0o555)
try:
  module.set_sentinel(sentinel_path, workspace, 1704067200, "sess-claude", "complete")
  module.append_event(events_path, workspace, 1704068400, "session_reflect", "complete", session_id="sess-claude")
finally:
  workspace.chmod(0o755)
claude_sentinel = root / "claude-tmp/copilot-heartbeat"
matches = list(claude_sentinel.glob("*/.heartbeat-session"))
event_matches = list(claude_sentinel.glob("*/.heartbeat-events.jsonl"))
assert len(matches) == 1, matches
assert len(event_matches) == 1, event_matches
assert "|complete" in matches[0].read_text(encoding="utf-8")
assert module.sentinel_is_complete(sentinel_path) is True
assert module.reflection_event_complete(events_path, "sess-claude", 1704067200) is True
'
chmod 0755 "$TMP_CLAUDE_TMP/blocked-tmp"
echo ""

echo "7. close_work_window accumulates tracked active time and resets the window"
assert_python "close_work_window rolls elapsed time into active_work_seconds" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
state = module.default_state()
state["active_work_seconds"] = 30
state["task_window_start_epoch"] = 100
state["last_raw_tool_epoch"] = 340
state = module.close_work_window(state)
assert state["active_work_seconds"] == 270
assert state["task_window_start_epoch"] == 0
'
echo ""

echo "8. atomic_write retries with a fresh temp path after a transient replace failure"
TMP_ATOMIC=$(mktemp -d); CLEANUP_DIRS+=("$TMP_ATOMIC")
mkdir -p "$TMP_ATOMIC/.copilot/workspace"
assert_python_in_root "atomic_write retries once with a unique temp file" "$TMP_ATOMIC" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
state_path = root / ".copilot/workspace/state.json"
replace_calls = []
original_replace = module.os.replace

def flaky_replace(src, dst):
  replace_calls.append(pathlib.Path(src).name)
  if len(replace_calls) == 1:
    raise FileNotFoundError(2, "simulated transient replace failure", str(src), str(dst))
  return original_replace(src, dst)

module.os.replace = flaky_replace
module.atomic_write(state_path, "payload")
assert state_path.read_text(encoding="utf-8") == "payload"
assert len(replace_calls) == 2
assert replace_calls[0] != replace_calls[1]
assert not list((root / ".copilot/workspace").glob("*.tmp"))
'
echo ""

finish_tests