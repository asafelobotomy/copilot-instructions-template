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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TRIGGER="$TRIGGER" HOOK_INPUT="$INPUT" SCRIPT_DIR="$SCRIPT_DIR" python3 - <<'PY'
import json
import os
import re
import subprocess
import time
from pathlib import Path


TRIGGER = os.environ.get("TRIGGER", "")
RAW_INPUT = os.environ.get("HOOK_INPUT", "")
SCRIPT_DIR = Path(os.environ.get("SCRIPT_DIR", "."))
NOW = int(time.time())

WORKSPACE = Path(".copilot/workspace")
STATE_PATH = WORKSPACE / "state.json"
SENTINEL_PATH = WORKSPACE / ".heartbeat-session"
EVENTS_PATH = WORKSPACE / ".heartbeat-events.jsonl"
HEARTBEAT_PATH = WORKSPACE / "HEARTBEAT.md"
POLICY_PATH = SCRIPT_DIR / "heartbeat-policy.json"

DEFAULT_POLICY = {
    "retrospective": {
        "thresholds": {
            "modified_files": {"supporting": 5, "strong": 8},
            "elapsed_minutes": {"supporting": 15, "strong": 30},
        },
        "messages": {
            "session_start_guidance": "Open .copilot/workspace/HEARTBEAT.md and run the Checks section. Retrospective is optional: only run it when explicitly requested, or after a medium/large task once the user agrees.",
            "explicit_system": "Heartbeat trigger detected. Run HEARTBEAT.md checks now. Retrospective is optional unless explicitly requested or the user agrees after a medium/large task.",
            "stop_prompt_question": "That was a large change to the codebase, would you like me to run a retrospective?",
            "accepted_reason": "The user agreed to a retrospective. Run HEARTBEAT.md Retrospective now, persist any insights, then stop normally.",
        },
        "transcript_complete_pattern": "Q[1-5].*SOUL|Q[1-5].*MEMORY|Q[1-5].*USER|heartbeat-session.*complete",
    }
}


def load_policy() -> dict:
    if not POLICY_PATH.exists():
        return DEFAULT_POLICY
    try:
        loaded = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
        if isinstance(loaded, dict):
            return loaded
    except Exception:
        pass
    return DEFAULT_POLICY


POLICY = load_policy()
RETRO_POLICY = POLICY.get("retrospective", DEFAULT_POLICY["retrospective"])
RETRO_THRESHOLDS = RETRO_POLICY.get("thresholds", DEFAULT_POLICY["retrospective"]["thresholds"])
RETRO_MODIFIED_THRESHOLDS = RETRO_THRESHOLDS.get(
    "modified_files", DEFAULT_POLICY["retrospective"]["thresholds"]["modified_files"]
)
RETRO_ELAPSED_THRESHOLDS = RETRO_THRESHOLDS.get(
    "elapsed_minutes", DEFAULT_POLICY["retrospective"]["thresholds"]["elapsed_minutes"]
)
RETRO_MESSAGES = RETRO_POLICY.get("messages", DEFAULT_POLICY["retrospective"]["messages"])
SESSION_START_GUIDANCE = str(
    RETRO_MESSAGES.get("session_start_guidance")
    or DEFAULT_POLICY["retrospective"]["messages"]["session_start_guidance"]
)
EXPLICIT_SYSTEM_MESSAGE = str(
    RETRO_MESSAGES.get("explicit_system")
    or DEFAULT_POLICY["retrospective"]["messages"]["explicit_system"]
)
STOP_PROMPT_QUESTION = str(
    RETRO_MESSAGES.get("stop_prompt_question")
    or DEFAULT_POLICY["retrospective"]["messages"]["stop_prompt_question"]
)
ACCEPTED_REASON = str(
    RETRO_MESSAGES.get("accepted_reason")
    or DEFAULT_POLICY["retrospective"]["messages"]["accepted_reason"]
)
RETRO_TRANSCRIPT_PATTERN = str(
    RETRO_POLICY.get("transcript_complete_pattern")
    or DEFAULT_POLICY["retrospective"]["transcript_complete_pattern"]
)


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
        "retrospective_state": "idle",
        "last_trigger": "",
        "last_write_epoch": 0,
        "last_soft_trigger_epoch": 0,
        "last_compaction_epoch": 0,
        "last_explicit_epoch": 0,
        "session_start_epoch": 0,
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


def iso_utc(epoch: int) -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(epoch))


def append_event(trigger: str, detail: str = "", duration_s=None) -> None:
    if not WORKSPACE.exists():
        return
    event = {"ts": NOW, "ts_utc": iso_utc(NOW), "trigger": trigger}
    if detail:
        event["detail"] = detail
    if duration_s is not None:
        event["duration_s"] = duration_s
    with EVENTS_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(event, sort_keys=True) + "\n")


def compute_session_medians() -> str:
    """Return a human-readable timing hint based on historical stop events."""
    if not EVENTS_PATH.exists():
        return ""
    durations = []
    try:
        for line in EVENTS_PATH.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            try:
                ev = json.loads(line)
                if ev.get("trigger") == "stop" and isinstance(ev.get("duration_s"), (int, float)):
                    durations.append(int(ev["duration_s"]))
            except Exception:
                pass
    except Exception:
        return ""
    if not durations:
        return ""
    sorted_d = sorted(durations)
    n = len(sorted_d)
    mid = n // 2
    median = sorted_d[mid] if n % 2 else (sorted_d[mid - 1] + sorted_d[mid]) // 2
    mins = median // 60
    secs = median % 60
    if mins >= 1:
        label = f"~{mins}m" if secs < 30 else f"~{mins + 1}m"
    else:
        label = f"~{secs}s"
    return f"Typical session: {label} (median of {n})."


def prune_events(keep: int = 100) -> None:
    """Trim the events log to the most recent `keep` entries."""
    if not EVENTS_PATH.exists():
        return
    try:
        lines = [l for l in EVENTS_PATH.read_text(encoding="utf-8").splitlines() if l.strip()]
        if len(lines) > keep:
            atomic_write(EVENTS_PATH, "\n".join(lines[-keep:]) + "\n")
    except Exception:
        pass


def set_sentinel(session_id: str, status: str) -> None:
    if not WORKSPACE.exists():
        return
    ts = iso_utc(NOW)
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


def get_git_modified_file_count() -> int:
    try:
        proc = subprocess.run(
            ["git", "status", "--porcelain"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if proc.returncode != 0:
            return 0
        return len([line for line in proc.stdout.splitlines() if line.strip()])
    except Exception:
        return 0


def retrospective_state(state: dict) -> str:
    return str(state.get("retrospective_state") or "idle")


def recommend_retrospective(state: dict) -> tuple[bool, str]:
    strong_signals = []
    supporting_signals = []
    strong_modified = int(RETRO_MODIFIED_THRESHOLDS.get("strong") or 8)
    supporting_modified = int(RETRO_MODIFIED_THRESHOLDS.get("supporting") or 5)
    strong_elapsed_seconds = int(RETRO_ELAPSED_THRESHOLDS.get("strong") or 30) * 60
    supporting_elapsed_seconds = int(RETRO_ELAPSED_THRESHOLDS.get("supporting") or 15) * 60
    modified_count = get_git_modified_file_count()
    if modified_count >= strong_modified:
        strong_signals.append(f"{modified_count} modified files")
    elif modified_count >= supporting_modified:
        supporting_signals.append(f"{modified_count} modified files")

    start_epoch = int(state.get("session_start_epoch") or 0)
    if start_epoch:
        duration_s = max(0, NOW - start_epoch)
        if duration_s >= strong_elapsed_seconds:
            strong_signals.append(f"{duration_s // 60}m elapsed")
        elif duration_s >= supporting_elapsed_seconds:
            supporting_signals.append(f"{duration_s // 60}m elapsed")
        if int(state.get("last_compaction_epoch") or 0) >= start_epoch:
            supporting_signals.append("context compaction occurred")

    signals = strong_signals + supporting_signals
    return (bool(strong_signals) or len(supporting_signals) >= 2, ", ".join(signals))


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
    state["retrospective_state"] = "idle"
    state["last_write_epoch"] = NOW
    state["session_start_epoch"] = NOW
    set_sentinel(session_id, "pending")
    append_event(TRIGGER)
    prune_events()
    save_state(state)
    dt_str = iso_utc(NOW)
    timing_hint = compute_session_medians()
    ctx_parts = [
        f"Session started at {dt_str}.",
        *([timing_hint] if timing_hint else []),
        SESSION_START_GUIDANCE,
    ]
    print_json({
        "continue": True,
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": " ".join(ctx_parts),
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
    retro_state = retrospective_state(state)

    if retro_state == "suggested":
        if re.search(r"^\s*(yes|yep|yeah|sure|ok|okay|please do|go ahead|do it|run it)\b", prompt, flags=re.IGNORECASE):
            state["retrospective_state"] = "accepted"
            state["last_write_epoch"] = NOW
            append_event("retrospective_response", "accepted")
            save_state(state)
            print_json({"continue": True})
            raise SystemExit(0)
        if re.search(r"^\s*(no|nope|nah|skip|not now|no thanks|don't|do not)\b", prompt, flags=re.IGNORECASE):
            state["retrospective_state"] = "declined"
            state["session_state"] = "complete"
            state["last_write_epoch"] = NOW
            append_event("retrospective_response", "declined")
            save_state(state)
            print_json({"continue": True})
            raise SystemExit(0)

    if re.search(r"\bretrospective\b", prompt, flags=re.IGNORECASE) and not re.search(r"\b(no|skip|don't|do not)\b.*\bretrospective\b", prompt, flags=re.IGNORECASE):
        state["retrospective_state"] = "accepted"

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
            "systemMessage": EXPLICIT_SYSTEM_MESSAGE,
        })
    else:
        print_json({"continue": True})
    raise SystemExit(0)

if TRIGGER == "stop":
    if bool(payload.get("stop_hook_active", False)):
        print_json({"continue": True})
        raise SystemExit(0)

    retro_state = retrospective_state(state)
    retro_ran = sentinel_is_complete()

    transcript_path = str(payload.get("transcript_path", "") or "")
    if not retro_ran and transcript_path:
        tpath = Path(transcript_path)
        if tpath.exists():
            try:
                transcript = tpath.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                transcript = ""
            if re.search(RETRO_TRANSCRIPT_PATTERN, transcript, flags=re.IGNORECASE):
                retro_ran = True

    # Backward-compatible fallback for repos that do not have sentinel state.
    if not retro_ran and not SENTINEL_PATH.exists() and heartbeat_fresh(120):
        retro_ran = True

    duration_s = max(0, NOW - int(state.get("session_start_epoch") or 0))

    if retro_state == "declined":
        state["session_state"] = "complete"
        state["last_write_epoch"] = NOW
        append_event(TRIGGER, "declined", duration_s=duration_s)
        save_state(state)
        print_json({"continue": True})
        raise SystemExit(0)

    if retro_ran:
        state["session_state"] = "complete"
        state["retrospective_state"] = "complete"
        state["last_write_epoch"] = NOW
        set_sentinel(session_id, "complete")
        append_event(TRIGGER, "complete", duration_s=duration_s)
        save_state(state)
        print_json({"continue": True})
        raise SystemExit(0)

    if retro_state == "accepted":
        state["session_state"] = "pending"
        state["last_write_epoch"] = NOW
        append_event(TRIGGER, "accepted-pending")
        save_state(state)
        print_json(
            {
                "hookSpecificOutput": {
                    "hookEventName": "Stop",
                    "decision": "block",
                    "reason": ACCEPTED_REASON,
                }
            }
        )
        raise SystemExit(0)

    should_prompt, basis = recommend_retrospective(state)
    if should_prompt:
        state["session_state"] = "pending"
        state["retrospective_state"] = "suggested"
        state["last_write_epoch"] = NOW
        append_event(TRIGGER, "suggested")
        save_state(state)
        print_json(
            {
                "hookSpecificOutput": {
                    "hookEventName": "Stop",
                    "decision": "block",
                    "reason": f"This looks like a medium/large task ({basis}). Ask the user: \"{STOP_PROMPT_QUESTION}\" Run HEARTBEAT.md Retrospective only if they agree.",
                }
            }
        )
        raise SystemExit(0)

    state["session_state"] = "complete"
    state["retrospective_state"] = "not-needed"
    state["last_write_epoch"] = NOW
    append_event(TRIGGER, "not-needed", duration_s=duration_s)
    save_state(state)
    print_json({"continue": True})
    raise SystemExit(0)

print_json({"continue": True})
PY