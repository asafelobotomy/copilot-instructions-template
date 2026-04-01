#!/usr/bin/env bash
# purpose:  Orchestrate heartbeat trigger state and retrospective gating.
# when:     Invoked by lifecycle hooks (SessionStart/PostToolUse/PreCompact/Stop/UserPromptSubmit).
# inputs:   JSON on stdin + --trigger <session_start|soft_post_tool|compaction|stop|user_prompt|explicit>.
# outputs:  JSON hook response (`continue` or Stop `decision:block`).
# risk:     safe
# source:   original
set -euo pipefail

TRIGGER=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --trigger)
      TRIGGER="${2:-}"
      shift 2
      ;;
    *)
      echo '{"continue": true}'
      exit 0
      ;;
  esac
done

INPUT=$(cat)

if [[ -z "$TRIGGER" ]]; then
  echo '{"continue": true}'
  exit 0
fi

TRIGGER="$TRIGGER" HOOK_INPUT="$INPUT" python3 - <<'PY'
import json
import os
import re
import time
from pathlib import Path


TRIGGER = os.environ.get("TRIGGER", "")
RAW_INPUT = os.environ.get("HOOK_INPUT", "")
NOW = int(time.time())

WORKSPACE = Path(".copilot/workspace")
STATE_PATH = WORKSPACE / "state.json"
SENTINEL_PATH = WORKSPACE / ".heartbeat-session"
EVENTS_PATH = WORKSPACE / ".heartbeat-events.jsonl"
HEARTBEAT_PATH = WORKSPACE / "HEARTBEAT.md"


def parse_input(raw: str) -> dict:
    try:
        data = json.loads(raw) if raw.strip() else {}
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def default_state() -> dict:
    return {
        "schema_version": 1,
        "session_id": "unknown",
        "session_state": "pending",
        "last_trigger": "",
        "last_write_epoch": 0,
        "last_soft_trigger_epoch": 0,
        "last_compaction_epoch": 0,
        "last_explicit_epoch": 0,
    }


def load_state() -> dict:
    state = default_state()
    if not STATE_PATH.exists():
        return state
    try:
        loaded = json.loads(STATE_PATH.read_text(encoding="utf-8"))
        if isinstance(loaded, dict):
            state.update({k: loaded[k] for k in state.keys() if k in loaded})
    except Exception:
        # Corrupt state must not block hooks.
        pass
    return state


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, path)


def save_state(state: dict) -> None:
    if not WORKSPACE.exists():
        return
    atomic_write(STATE_PATH, json.dumps(state, indent=2, sort_keys=True) + "\n")


def append_event(trigger: str, detail: str = "") -> None:
    if not WORKSPACE.exists():
        return
    event = {"ts": NOW, "trigger": trigger}
    if detail:
        event["detail"] = detail
    with EVENTS_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(event, sort_keys=True) + "\n")


def set_sentinel(session_id: str, status: str) -> None:
    if not WORKSPACE.exists():
        return
    ts = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(NOW))
    atomic_write(SENTINEL_PATH, f"{session_id}|{ts}|{status}\n")


def sentinel_is_complete() -> bool:
    if not SENTINEL_PATH.exists():
        return False
    try:
        parts = SENTINEL_PATH.read_text(encoding="utf-8").strip().split("|")
        return len(parts) >= 3 and parts[2].strip() == "complete"
    except Exception:
        return False


def heartbeat_fresh(minutes: int) -> bool:
    if not HEARTBEAT_PATH.exists():
        return False
    try:
        age = NOW - int(HEARTBEAT_PATH.stat().st_mtime)
        return age < (minutes * 60)
    except Exception:
        return False


def print_json(payload: dict) -> None:
    print(json.dumps(payload, ensure_ascii=True))


payload = parse_input(RAW_INPUT)
state = load_state()

_provided_id = str(payload.get("sessionId") or "")
if _provided_id:
    session_id = _provided_id
elif TRIGGER == "session_start":
    # Fallback: generate a local ID if VS Code does not provide one (should be rare).
    session_id = f"local-{os.urandom(4).hex()}"
else:
    session_id = state.get("session_id") or "unknown"
state["session_id"] = session_id
state["last_trigger"] = TRIGGER

if TRIGGER == "session_start":
    state["session_state"] = "pending"
    state["last_write_epoch"] = NOW
    set_sentinel(session_id, "pending")
    append_event(TRIGGER)
    save_state(state)
    print_json({
        "continue": True,
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": "Session started. Open .copilot/workspace/HEARTBEAT.md, run all checks, answer Retrospective Q1-Q8, persist insights to SOUL.md / MEMORY.md / USER.md, mark the sentinel complete, and append a History row."
        }
    })
    raise SystemExit(0)

if TRIGGER == "soft_post_tool":
    last_soft = int(state.get("last_soft_trigger_epoch", 0) or 0)
    # Debounce soft triggers to avoid churn from edit-heavy tasks.
    if NOW - last_soft < 300:
        print_json({"continue": True})
        raise SystemExit(0)
    state["last_soft_trigger_epoch"] = NOW
    state["last_write_epoch"] = NOW
    append_event(TRIGGER)
    save_state(state)
    print_json({"continue": True})
    raise SystemExit(0)

if TRIGGER == "compaction":
    state["last_compaction_epoch"] = NOW
    state["last_write_epoch"] = NOW
    append_event(TRIGGER)
    save_state(state)
    print_json({"continue": True})
    raise SystemExit(0)

if TRIGGER in ("user_prompt", "explicit"):
    prompt = str(payload.get("prompt", ""))
    if re.search(r"\b(heartbeat|retrospective|health check)\b", prompt, flags=re.IGNORECASE):
        state["last_explicit_epoch"] = NOW
        state["last_write_epoch"] = NOW
        append_event("explicit_prompt")
        save_state(state)
        # Note: UserPromptSubmit has no hookSpecificOutput injection — systemMessage is a
        # UI-only chat banner; the model does not receive it. Model context injection is
        # only available on SessionStart via hookSpecificOutput.additionalContext.
        print_json({
            "continue": True,
            "systemMessage": "Heartbeat trigger detected. Run HEARTBEAT.md protocol now: run all checks, answer Retrospective Q1-Q8, persist insights to SOUL.md / MEMORY.md / USER.md, mark the sentinel complete, and append a History row.",
        })
    else:
        print_json({"continue": True})
    raise SystemExit(0)

if TRIGGER == "stop":
    if bool(payload.get("stop_hook_active", False)):
        print_json({"continue": True})
        raise SystemExit(0)

    retro_ran = sentinel_is_complete()

    transcript_path = str(payload.get("transcript_path", "") or "")
    if not retro_ran and transcript_path:
        tpath = Path(transcript_path)
        if tpath.exists():
            try:
                transcript = tpath.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                transcript = ""
            if re.search(r"Q[1-8].*SOUL|Q[1-8].*MEMORY|Q[1-8].*USER|heartbeat-session.*complete", transcript, flags=re.IGNORECASE):
                retro_ran = True

    # Backward-compatible fallback for repos that do not have sentinel state.
    if not retro_ran and not SENTINEL_PATH.exists() and heartbeat_fresh(120):
        retro_ran = True

    if retro_ran:
        state["session_state"] = "complete"
        state["last_write_epoch"] = NOW
        set_sentinel(session_id, "complete")
        append_event(TRIGGER, "complete")
        save_state(state)
        print_json({"continue": True})
        raise SystemExit(0)

    state["session_state"] = "pending"
    state["last_write_epoch"] = NOW
    append_event(TRIGGER, "blocked")
    save_state(state)
    print_json(
        {
            "hookSpecificOutput": {
                "hookEventName": "Stop",
                "decision": "block",
                "reason": "The retrospective has not been run this session. Before stopping, run HEARTBEAT.md Retrospective, persist insights, then mark .copilot/workspace/.heartbeat-session as complete.",
            }
        }
    )
    raise SystemExit(0)

print_json({"continue": True})
PY