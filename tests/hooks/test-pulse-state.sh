#!/usr/bin/env bash
# tests/hooks/test-pulse-state.sh -- unit tests for hooks/scripts/pulse_state.py
# Run: bash tests/hooks/test-pulse-state.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
MODULE_PATH="$REPO_ROOT/hooks/scripts/pulse_state.py"
export MODULE_PATH
PYTHONPATH="$(dirname "$MODULE_PATH")${PYTHONPATH:+:$PYTHONPATH}"
export PYTHONPATH
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
TMP_MISSING=$(mktemp -d)
CLEANUP_DIRS+=("$TMP_MISSING")
assert_python_in_root "missing state file returns defaults" "$TMP_MISSING" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
state = module.load_state(root / ".copilot/workspace/runtime/state.json")
assert state == module.default_state()
'
echo ""

echo "3. load_state merges known fields and ignores unknown ones"
TMP_PARTIAL=$(mktemp -d); CLEANUP_DIRS+=("$TMP_PARTIAL")
mkdir -p "$TMP_PARTIAL/.copilot/workspace/identity" "$TMP_PARTIAL/.copilot/workspace/knowledge/diaries" "$TMP_PARTIAL/.copilot/workspace/operations" "$TMP_PARTIAL/.copilot/workspace/runtime"
cat > "$TMP_PARTIAL/.copilot/workspace/runtime/state.json" <<'EOF'
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
state = module.load_state(root / ".copilot/workspace/runtime/state.json")
assert state["session_id"] == "sess-partial"
assert state["tool_call_counter"] == 7
assert "unknown_key" not in state
assert state["intent_phase"] == "quiet"
'
echo ""

echo "4. corrupt state and policy files fall back safely to defaults"
TMP_CORRUPT=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CORRUPT")
mkdir -p "$TMP_CORRUPT/.copilot/workspace/identity" "$TMP_CORRUPT/.copilot/workspace/knowledge/diaries" "$TMP_CORRUPT/.copilot/workspace/operations" "$TMP_CORRUPT/.copilot/workspace/runtime"
printf '{broken-json\n' > "$TMP_CORRUPT/.copilot/workspace/runtime/state.json"
printf '{broken-json\n' > "$TMP_CORRUPT/policy.json"
assert_python_in_root "corrupt files fall back to defaults" "$TMP_CORRUPT" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
state = module.load_state(root / ".copilot/workspace/runtime/state.json")
policy = module.load_policy(root / "policy.json")
assert state == module.default_state()
assert policy == module.DEFAULT_POLICY
'
echo ""

echo "5. save_state always writes valid JSON (creates parent dirs if needed)"
TMP_SAVE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_SAVE")
assert_python_in_root "save_state creates missing workspace dirs and writes valid JSON" "$TMP_SAVE" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
workspace = root / ".copilot/workspace"
state_path = workspace / "runtime/state.json"
state = module.default_state()
state["session_id"] = "sess-save"
# save_state creates parent dirs via atomic_write and writes to primary path
module.save_state(state, workspace, state_path)
assert state_path.exists(), f"save_state should write to primary path (got nothing at {state_path})"
saved = json.loads(state_path.read_text(encoding="utf-8"))
assert saved["session_id"] == "sess-save", "expected sess-save, got %s" % saved.get("session_id")
assert saved["schema_version"] == 1, "expected schema_version 1, got %s" % saved.get("schema_version")
# load_state round-trips correctly
loaded = module.load_state(state_path)
assert loaded["session_id"] == "sess-save", "load_state expected sess-save, got %s" % loaded.get("session_id")
'
echo ""

echo "6. sentinel and reflection completion helpers recognize completed sessions"
TMP_EVENTS=$(mktemp -d); CLEANUP_DIRS+=("$TMP_EVENTS")
mkdir -p "$TMP_EVENTS/.copilot/workspace/identity" "$TMP_EVENTS/.copilot/workspace/knowledge/diaries" "$TMP_EVENTS/.copilot/workspace/operations" "$TMP_EVENTS/.copilot/workspace/runtime"
assert_python_in_root "sentinel and event helpers detect completed sessions" "$TMP_EVENTS" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
workspace = root / ".copilot/workspace"
sentinel_path = workspace / "runtime/.heartbeat-session"
events_path = workspace / "runtime/.heartbeat-events.jsonl"
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
mkdir -p "$TMP_FALLBACK/.copilot/workspace/identity" "$TMP_FALLBACK/.copilot/workspace/knowledge/diaries" "$TMP_FALLBACK/.copilot/workspace/operations" "$TMP_FALLBACK/.copilot/workspace/runtime"
assert_python_in_root "helpers read heartbeat completion from fallback storage" "$TMP_FALLBACK" '
import importlib.util

os.environ.pop("CLAUDE_TMPDIR", None)
os.environ["TMPDIR"] = str(root / "runtime-tmp")
spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
workspace = root / ".copilot/workspace"
sentinel_path = workspace / "runtime/.heartbeat-session"
events_path = workspace / "runtime/.heartbeat-events.jsonl"
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
mkdir -p "$TMP_CACHE_FALLBACK/.copilot/workspace/identity" "$TMP_CACHE_FALLBACK/.copilot/workspace/knowledge/diaries" "$TMP_CACHE_FALLBACK/.copilot/workspace/operations" "$TMP_CACHE_FALLBACK/.copilot/workspace/runtime"
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
import pulse_artifacts
pulse_artifacts.tempfile.gettempdir = lambda: str(root / "blocked-tmp")
workspace = root / ".copilot/workspace"
sentinel_path = workspace / "runtime/.heartbeat-session"
events_path = workspace / "runtime/.heartbeat-events.jsonl"
(workspace / "runtime").chmod(0o555)
workspace.chmod(0o555)
try:
  module.set_sentinel(sentinel_path, workspace, 1704067200, "sess-cache", "complete")
  module.append_event(events_path, workspace, 1704068400, "session_reflect", "complete", session_id="sess-cache")
finally:
  workspace.chmod(0o755)
  (workspace / "runtime").chmod(0o755)
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
mkdir -p "$TMP_CLAUDE_TMP/.copilot/workspace/identity" "$TMP_CLAUDE_TMP/.copilot/workspace/knowledge/diaries" "$TMP_CLAUDE_TMP/.copilot/workspace/operations" "$TMP_CLAUDE_TMP/.copilot/workspace/runtime"
mkdir -p "$TMP_CLAUDE_TMP/blocked-tmp" "$TMP_CLAUDE_TMP/claude-tmp"
chmod 0555 "$TMP_CLAUDE_TMP/blocked-tmp"
assert_python_in_root "helpers write heartbeat artifacts into CLAUDE_TMPDIR when TMPDIR is blocked" "$TMP_CLAUDE_TMP" '
import importlib.util

os.environ["TMPDIR"] = str(root / "blocked-tmp")
os.environ["CLAUDE_TMPDIR"] = str(root / "claude-tmp")
spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
import pulse_artifacts
pulse_artifacts.tempfile.gettempdir = lambda: str(root / "blocked-tmp")
workspace = root / ".copilot/workspace"
sentinel_path = workspace / "runtime/.heartbeat-session"
events_path = workspace / "runtime/.heartbeat-events.jsonl"
(workspace / "runtime").chmod(0o555)
workspace.chmod(0o555)
try:
  module.set_sentinel(sentinel_path, workspace, 1704067200, "sess-claude", "complete")
  module.append_event(events_path, workspace, 1704068400, "session_reflect", "complete", session_id="sess-claude")
finally:
  workspace.chmod(0o755)
  (workspace / "runtime").chmod(0o755)
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
mkdir -p "$TMP_ATOMIC/.copilot/workspace/identity" "$TMP_ATOMIC/.copilot/workspace/knowledge/diaries" "$TMP_ATOMIC/.copilot/workspace/operations" "$TMP_ATOMIC/.copilot/workspace/runtime"
assert_python_in_root "atomic_write retries once with a unique temp file" "$TMP_ATOMIC" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
state_path = root / ".copilot/workspace/runtime/state.json"
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

echo "8b. sentinel_is_complete filters by session_id — rejects a prior-session sentinel"
TMP_SESSION_FILTER=$(mktemp -d); CLEANUP_DIRS+=("$TMP_SESSION_FILTER")
mkdir -p "$TMP_SESSION_FILTER/.copilot/workspace/identity" "$TMP_SESSION_FILTER/.copilot/workspace/knowledge/diaries" "$TMP_SESSION_FILTER/.copilot/workspace/operations" "$TMP_SESSION_FILTER/.copilot/workspace/runtime"
assert_python_in_root "session-aware sentinel check isolates cross-session completions" "$TMP_SESSION_FILTER" '
import importlib.util

spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
workspace = root / ".copilot/workspace"
sentinel_path = workspace / "runtime/.heartbeat-session"

# Write a complete sentinel from a prior session
module.set_sentinel(sentinel_path, workspace, 1704067200, "sess-old", "complete")

# Without session filter — legacy path still returns True (backward compat)
assert module.sentinel_is_complete(sentinel_path) is True, "no-filter should return True"

# Matching session id — should return True
assert module.sentinel_is_complete(sentinel_path, "sess-old") is True, "matching session should return True"

# Different (current) session id — prior-session complete must be ignored
assert module.sentinel_is_complete(sentinel_path, "sess-new") is False, "cross-session complete should return False"

# Overwrite sentinel with current session complete
module.set_sentinel(sentinel_path, workspace, 1704068400, "sess-new", "complete")

# Current session now matches
assert module.sentinel_is_complete(sentinel_path, "sess-new") is True, "current session should now return True"
'
echo ""

echo "9. file_lock serializes append_event while another process holds the lock"
TMP_LOCKED=$(mktemp -d); CLEANUP_DIRS+=("$TMP_LOCKED")
mkdir -p "$TMP_LOCKED/.copilot/workspace/identity" "$TMP_LOCKED/.copilot/workspace/knowledge/diaries" "$TMP_LOCKED/.copilot/workspace/operations" "$TMP_LOCKED/.copilot/workspace/runtime"
assert_python_in_root "append_event waits for the active file lock before writing" "$TMP_LOCKED" '
import importlib.util
import multiprocessing
import time
from pathlib import Path


def worker(module_path, root_path, started, finished):
  import importlib.util
  import os
  from pathlib import Path

  os.chdir(root_path)
  spec = importlib.util.spec_from_file_location("pulse_state_child", module_path)
  module = importlib.util.module_from_spec(spec)
  spec.loader.exec_module(module)
  workspace = Path(root_path) / ".copilot/workspace"
  events_path = workspace / "runtime/.heartbeat-events.jsonl"
  started.set()
  module.append_event(events_path, workspace, 1704068400, "session_reflect", "complete", session_id="sess-lock")
  finished.set()


spec = importlib.util.spec_from_file_location("pulse_state", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
workspace = root / ".copilot/workspace"
events_path = workspace / "runtime/.heartbeat-events.jsonl"
ctx = multiprocessing.get_context("fork")
started = ctx.Event()
finished = ctx.Event()
proc = ctx.Process(target=worker, args=(os.environ["MODULE_PATH"], str(root), started, finished))
with module.file_lock(events_path):
  proc.start()
  assert started.wait(5), "child process never reached append_event"
  time.sleep(0.2)
  assert not finished.is_set(), "child write completed before the lock was released"
proc.join(5)
assert proc.exitcode == 0, proc.exitcode
lines = events_path.read_text(encoding="utf-8").splitlines()
assert len(lines) == 1, lines
event = json.loads(lines[0])
assert event["trigger"] == "session_reflect"
assert event["session_id"] == "sess-lock"
'
echo ""

finish_tests