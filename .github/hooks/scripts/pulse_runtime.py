#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import time
from pathlib import Path

from pulse_intent import update_intent_engine
from pulse_state import (
    DEFAULT_POLICY,
    append_event,
    close_work_window,
    compute_session_medians,
    get_git_modified_file_count,
    heartbeat_fresh,
    iso_utc,
    load_policy,
    load_session_priors,
    load_state,
    prune_events,
    recommend_retrospective,
    save_state,
    sentinel_is_complete,
    set_sentinel,
)


TRIGGER = os.environ.get("TRIGGER", "")
RAW_INPUT = os.environ.get("HOOK_INPUT", "")
NOW = int(time.time())
SCRIPT_DIR = Path(__file__).resolve().parent

WORKSPACE = Path(".copilot/workspace")
STATE_PATH = WORKSPACE / "state.json"
SENTINEL_PATH = WORKSPACE / ".heartbeat-session"
EVENTS_PATH = WORKSPACE / ".heartbeat-events.jsonl"
HEARTBEAT_PATH = WORKSPACE / "HEARTBEAT.md"
POLICY_PATH = SCRIPT_DIR / "heartbeat-policy.json"


def parse_input(raw: str) -> dict:
    try:
        data = json.loads(raw) if raw.strip() else {}
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def retrospective_state(state: dict) -> str:
    return str(state.get("retrospective_state") or "idle")


def prompt_requests_retrospective(prompt: str) -> bool:
    if not re.search(r"\bretrospective\b", prompt, flags=re.IGNORECASE):
        return False
    if re.search(r"\b(no|skip|don't|do not|not now)\b.*\bretrospective\b", prompt, flags=re.IGNORECASE):
        return False
    patterns = (
        r"^\s*retrospective\b",
        r"\b(run|do|start|perform)\b.*\bretrospective\b",
        r"\b(can|could|would)\s+you\b.*\bretrospective\b",
        r"\bplease\b.*\bretrospective\b",
    )
    return any(re.search(pattern, prompt, flags=re.IGNORECASE) for pattern in patterns)


def prompt_requests_heartbeat_check(prompt: str) -> bool:
    if re.search(r"\b(no|skip|don't|do not)\b.*\b(heartbeat|health check)\b", prompt, flags=re.IGNORECASE):
        return False
    patterns = (
        r"^\s*heartbeat(?:\s+now)?\s*[?.!]*$",
        r"\b(check|run|show)\b.*\bheartbeat\b",
        r"\b(run|do|show)\b.*\bhealth check\b",
        r"\b(can|could|would)\s+you\b.*\b(heartbeat|health check)\b",
    )
    return any(re.search(pattern, prompt, flags=re.IGNORECASE) for pattern in patterns)


def print_json(payload: dict) -> None:
    print(json.dumps(payload, ensure_ascii=True))


POLICY = load_policy(POLICY_PATH)
RETRO_POLICY = POLICY.get("retrospective", DEFAULT_POLICY["retrospective"])
RETRO_THRESHOLDS = RETRO_POLICY.get("thresholds", DEFAULT_POLICY["retrospective"]["thresholds"])
RETRO_MODIFIED_THRESHOLDS = RETRO_THRESHOLDS.get(
    "modified_files", DEFAULT_POLICY["retrospective"]["thresholds"]["modified_files"]
)
RETRO_ELAPSED_THRESHOLDS = RETRO_THRESHOLDS.get(
    "elapsed_minutes", DEFAULT_POLICY["retrospective"]["thresholds"]["elapsed_minutes"]
)
IDLE_GAP_MINUTES = int(RETRO_THRESHOLDS.get("idle_gap_minutes") or 10)
HEALTH_DIGEST_CONFIG = RETRO_POLICY.get("health_digest", DEFAULT_POLICY["retrospective"]["health_digest"])
HEALTH_DIGEST_MIN_SPACING_SECONDS = int(HEALTH_DIGEST_CONFIG.get("min_emit_spacing_seconds") or 120)
RETRO_MESSAGES = RETRO_POLICY.get("messages", DEFAULT_POLICY["retrospective"]["messages"])
SESSION_START_GUIDANCE = str(
    RETRO_MESSAGES.get("session_start_guidance")
    or DEFAULT_POLICY["retrospective"]["messages"]["session_start_guidance"]
)
EXPLICIT_SYSTEM_MESSAGE = str(
    RETRO_MESSAGES.get("explicit_system")
    or DEFAULT_POLICY["retrospective"]["messages"]["explicit_system"]
)
STOP_REFLECT_INSTRUCTION = str(
    RETRO_MESSAGES.get("stop_reflect_instruction")
    or DEFAULT_POLICY["retrospective"]["messages"]["stop_reflect_instruction"]
)
ACCEPTED_REASON = str(
    RETRO_MESSAGES.get("accepted_reason")
    or DEFAULT_POLICY["retrospective"]["messages"]["accepted_reason"]
)
RETRO_TRANSCRIPT_PATTERN = str(
    RETRO_POLICY.get("transcript_complete_pattern")
    or DEFAULT_POLICY["retrospective"]["transcript_complete_pattern"]
)


def build_recommendation(state: dict) -> tuple[bool, str]:
    return recommend_retrospective(state, RETRO_MODIFIED_THRESHOLDS, RETRO_ELAPSED_THRESHOLDS)


payload = parse_input(RAW_INPUT)
state = load_state(STATE_PATH)

provided_id = str(payload.get("sessionId") or "")
if provided_id:
    session_id = provided_id
elif TRIGGER == "session_start":
    session_id = f"local-{os.urandom(4).hex()}"
else:
    session_id = state.get("session_id") or "unknown"
state["session_id"] = session_id
state["last_trigger"] = TRIGGER

if TRIGGER == "session_start":
    state.update(load_session_priors(WORKSPACE))
    state["session_state"] = "pending"
    state["retrospective_state"] = "idle"
    state["last_write_epoch"] = NOW
    state["session_start_epoch"] = NOW
    state["session_start_git_count"] = get_git_modified_file_count()
    state["task_window_start_epoch"] = 0
    state["last_raw_tool_epoch"] = 0
    state["active_work_seconds"] = 0
    state["copilot_edit_count"] = 0
    state["tool_call_counter"] = 0
    state["intent_phase"] = "quiet"
    state["intent_phase_epoch"] = NOW
    state["intent_phase_version"] = 1
    state["last_digest_key"] = ""
    state["last_digest_epoch"] = 0
    state["digest_emit_count"] = 0
    state["overlay_sensitive_surface"] = False
    state["overlay_parity_required"] = False
    state["overlay_verification_expected"] = False
    state["overlay_decision_capture_needed"] = False
    state["overlay_retro_requested"] = False
    state["signal_edit_started"] = False
    state["signal_scope_supporting"] = False
    state["signal_scope_strong"] = False
    state["signal_work_supporting"] = False
    state["signal_work_strong"] = False
    state["signal_compaction_seen"] = False
    state["signal_idle_reset_seen"] = False
    state["signal_cross_cutting"] = False
    state["signal_scope_widening"] = False
    state["signal_reflection_likely"] = False
    state["changed_path_families"] = []
    state["touched_files_sample"] = []
    state["unique_touched_file_count"] = 0
    set_sentinel(SENTINEL_PATH, WORKSPACE, NOW, session_id, "pending")
    append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER)
    prune_events(EVENTS_PATH)
    save_state(state, WORKSPACE, STATE_PATH)
    ctx_parts = [
        f"Session started at {iso_utc(NOW)}.",
        *([compute_session_medians(EVENTS_PATH)] if compute_session_medians(EVENTS_PATH) else []),
        SESSION_START_GUIDANCE,
    ]
    print_json({
        "continue": True,
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": " ".join(ctx_parts),
        },
    })
    raise SystemExit(0)

if TRIGGER == "soft_post_tool":
    file_writing_tools = {
        "create_file",
        "replace_string_in_file",
        "multi_replace_string_in_file",
        "editFiles",
        "writeFile",
    }
    if str(payload.get("tool_name") or "") in file_writing_tools:
        state["copilot_edit_count"] = int(state.get("copilot_edit_count") or 0) + 1

    idle_gap_seconds = IDLE_GAP_MINUTES * 60
    task_window_start = int(state.get("task_window_start_epoch") or 0)
    last_tool = int(state.get("last_raw_tool_epoch") or 0)
    if task_window_start == 0:
        state["task_window_start_epoch"] = NOW
    elif last_tool > 0 and (NOW - last_tool) > idle_gap_seconds:
        state["active_work_seconds"] = int(state.get("active_work_seconds") or 0) + max(0, last_tool - task_window_start)
        state["task_window_start_epoch"] = NOW
        state["signal_idle_reset_seen"] = True
    state["last_raw_tool_epoch"] = NOW
    state["last_write_epoch"] = NOW
    state["tool_call_counter"] = int(state.get("tool_call_counter") or 0) + 1

    if NOW - int(state.get("last_soft_trigger_epoch") or 0) >= 300:
        state["last_soft_trigger_epoch"] = NOW
        append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER)

    state, digest = update_intent_engine(
        state,
        payload,
        NOW,
        RETRO_MODIFIED_THRESHOLDS,
        RETRO_ELAPSED_THRESHOLDS,
        HEALTH_DIGEST_MIN_SPACING_SECONDS,
        build_recommendation,
        emit=True,
    )
    save_state(state, WORKSPACE, STATE_PATH)
    if digest:
        print_json({
            "continue": True,
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": digest,
            },
        })
    else:
        print_json({"continue": True})
    raise SystemExit(0)

if TRIGGER == "compaction":
    state = close_work_window(state)
    state["last_compaction_epoch"] = NOW
    state["last_write_epoch"] = NOW
    append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER)
    state, _digest = update_intent_engine(
        state,
        None,
        NOW,
        RETRO_MODIFIED_THRESHOLDS,
        RETRO_ELAPSED_THRESHOLDS,
        HEALTH_DIGEST_MIN_SPACING_SECONDS,
        build_recommendation,
        emit=False,
    )
    save_state(state, WORKSPACE, STATE_PATH)
    print_json({"continue": True})
    raise SystemExit(0)

if TRIGGER in ("user_prompt", "explicit"):
    prompt = str(payload.get("prompt") or "")
    retrospective_requested = prompt_requests_retrospective(prompt)
    heartbeat_requested = prompt_requests_heartbeat_check(prompt)
    if retrospective_requested:
        state["retrospective_state"] = "accepted"

    if heartbeat_requested or retrospective_requested:
        state["last_explicit_epoch"] = NOW
        state["last_write_epoch"] = NOW
        append_event(EVENTS_PATH, WORKSPACE, NOW, "explicit_prompt", "heartbeat" if heartbeat_requested else "retrospective")
        state, _digest = update_intent_engine(
            state,
            None,
            NOW,
            RETRO_MODIFIED_THRESHOLDS,
            RETRO_ELAPSED_THRESHOLDS,
            HEALTH_DIGEST_MIN_SPACING_SECONDS,
            build_recommendation,
            emit=False,
        )
        save_state(state, WORKSPACE, STATE_PATH)
        if heartbeat_requested:
            print_json({"continue": True, "systemMessage": EXPLICIT_SYSTEM_MESSAGE})
        else:
            print_json({"continue": True})
    else:
        print_json({"continue": True})
    raise SystemExit(0)

if TRIGGER == "stop":
    if bool(payload.get("stop_hook_active", False)):
        print_json({"continue": True})
        raise SystemExit(0)

    state = close_work_window(state)
    retro_ran = sentinel_is_complete(SENTINEL_PATH)

    transcript_path = str(payload.get("transcript_path") or "")
    if not retro_ran and transcript_path:
        tpath = Path(transcript_path)
        if tpath.exists():
            try:
                transcript = tpath.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                transcript = ""
            if re.search(RETRO_TRANSCRIPT_PATTERN, transcript, flags=re.IGNORECASE):
                retro_ran = True

    if not retro_ran and not SENTINEL_PATH.exists() and heartbeat_fresh(HEARTBEAT_PATH, NOW, 120):
        retro_ran = True

    duration_seconds = max(0, NOW - int(state.get("session_start_epoch") or 0))
    if retro_ran:
        state["session_state"] = "complete"
        state["retrospective_state"] = "complete"
        state["last_write_epoch"] = NOW
        set_sentinel(SENTINEL_PATH, WORKSPACE, NOW, session_id, "complete")
        append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER, "complete", duration_seconds)
        save_state(state, WORKSPACE, STATE_PATH)
        print_json({"continue": True})
        raise SystemExit(0)

    if retrospective_state(state) == "accepted":
        state["session_state"] = "pending"
        state["last_write_epoch"] = NOW
        append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER, "accepted-pending")
        save_state(state, WORKSPACE, STATE_PATH)
        print_json({
            "hookSpecificOutput": {
                "hookEventName": "Stop",
                "decision": "block",
                "reason": ACCEPTED_REASON,
            }
        })
        raise SystemExit(0)

    should_reflect, basis = build_recommendation(state)
    if should_reflect:
        state["session_state"] = "pending"
        state["retrospective_state"] = "suggested"
        state["last_write_epoch"] = NOW
        append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER, "reflect-needed")
        save_state(state, WORKSPACE, STATE_PATH)
        print_json({
            "hookSpecificOutput": {
                "hookEventName": "Stop",
                "decision": "block",
                "reason": f"Significant session ({basis}). {STOP_REFLECT_INSTRUCTION}",
            }
        })
        raise SystemExit(0)

    state["session_state"] = "complete"
    state["retrospective_state"] = "not-needed"
    state["last_write_epoch"] = NOW
    append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER, "not-needed", duration_seconds)
    save_state(state, WORKSPACE, STATE_PATH)
    print_json({"continue": True})
    raise SystemExit(0)

print_json({"continue": True})