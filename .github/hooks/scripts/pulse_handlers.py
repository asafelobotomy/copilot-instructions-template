"""Heartbeat pulse — trigger handler functions.

Each public handle_* function processes one hook trigger type and exits.
Shared runtime configuration is passed via PulseContext to avoid tight
coupling to pulse_runtime module globals.
"""
from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable

from pulse_intent import update_intent_engine
from pulse_routing import (
    classify_behavior_route,
    classify_prompt_route,
    is_template_repo,
    prompt_requests_heartbeat_check,
    prompt_requests_retrospective,
    route_roster_text,
    should_emit_route_hint,
)
from pulse_state import (
    append_event,
    close_work_window,
    compute_session_medians,
    get_git_modified_file_count,
    load_session_priors,
    prune_events,
    reflection_event_complete,
    save_state,
    sentinel_is_complete,
    set_sentinel,
)


# ---------------------------------------------------------------------------
# Runtime context — holds all policy constants and path singletons
# ---------------------------------------------------------------------------


@dataclass
class PulseContext:
    NOW: int
    session_id: str
    TRIGGER: str
    STATE_PATH: Path
    SENTINEL_PATH: Path
    EVENTS_PATH: Path
    WORKSPACE: Path
    ROUTING_MANIFEST: dict
    ROUTING_INDEX: dict
    RETRO_MODIFIED_THRESHOLDS: dict
    RETRO_ELAPSED_THRESHOLDS: dict
    IDLE_GAP_MINUTES: int
    HEALTH_DIGEST_MIN_SPACING_SECONDS: int
    SESSION_START_GUIDANCE: str
    EXPLICIT_SYSTEM_MESSAGE: str
    STOP_REFLECT_INSTRUCTION: str
    ACCEPTED_REASON: str
    POST_TOOL_REFLECT_INSTRUCTION: str
    build_recommendation: Callable[..., tuple[bool, str]]


# ---------------------------------------------------------------------------
# Shared utilities
# ---------------------------------------------------------------------------


def _print_json(payload: dict) -> None:
    print(json.dumps(payload, ensure_ascii=True))


def _retro_state(state: dict) -> str:
    return str(state.get("retrospective_state") or "idle")


# ---------------------------------------------------------------------------
# Handlers
# ---------------------------------------------------------------------------


def handle_session_start(state: dict, payload: dict, ctx: PulseContext) -> None:
    state.update(load_session_priors(ctx.WORKSPACE))
    state["session_state"] = "pending"
    state["retrospective_state"] = "idle"
    state["last_write_epoch"] = ctx.NOW
    state["session_start_epoch"] = ctx.NOW
    state["session_start_git_count"] = get_git_modified_file_count()
    state.update({
        "task_window_start_epoch": 0, "last_raw_tool_epoch": 0,
        "active_work_seconds": 0, "copilot_edit_count": 0, "tool_call_counter": 0,
        "intent_phase": "quiet", "intent_phase_epoch": ctx.NOW, "intent_phase_version": 1,
        "last_digest_key": "", "last_digest_epoch": 0, "digest_emit_count": 0,
        "overlay_sensitive_surface": False, "overlay_parity_required": False,
        "overlay_verification_expected": False, "overlay_decision_capture_needed": False,
        "overlay_retro_requested": False,
        "signal_edit_started": False, "signal_scope_supporting": False,
        "signal_scope_strong": False, "signal_work_supporting": False,
        "signal_work_strong": False, "signal_compaction_seen": False,
        "signal_idle_reset_seen": False, "signal_cross_cutting": False,
        "signal_scope_widening": False, "signal_reflection_likely": False,
        "reflect_instruction_emitted": False,
        "route_candidate": "", "route_reason": "", "route_confidence": 0.0,
        "route_source": "", "route_emitted": False, "route_epoch": 0,
        "route_last_hint_epoch": 0, "route_emitted_agents": [],
        "route_signal_counts": {}, "changed_path_families": [],
        "touched_files_sample": [], "unique_touched_file_count": 0,
    })
    set_sentinel(ctx.SENTINEL_PATH, ctx.WORKSPACE, ctx.NOW, ctx.session_id, "pending")
    append_event(ctx.EVENTS_PATH, ctx.WORKSPACE, ctx.NOW, ctx.TRIGGER, session_id=ctx.session_id)
    prune_events(ctx.EVENTS_PATH)
    save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
    ctx_parts = [
        *([compute_session_medians(ctx.EVENTS_PATH)] if compute_session_medians(ctx.EVENTS_PATH) else []),
        f"Route: {route_roster_text(ctx.ROUTING_MANIFEST)}.",
        ctx.SESSION_START_GUIDANCE,
    ]
    _print_json({
        "continue": True,
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": " ".join(ctx_parts),
        },
    })
    raise SystemExit(0)


def handle_pre_tool(state: dict, payload: dict, ctx: PulseContext) -> None:
    signal_counts = state.get("route_signal_counts") or {}
    behavior_candidate = classify_behavior_route(payload, state, ctx.ROUTING_MANIFEST)
    if behavior_candidate:
        signal_counts[behavior_candidate["agent"]] = int(signal_counts.get(behavior_candidate["agent"]) or 0) + 1
        state["route_signal_counts"] = signal_counts

    current_candidate = str(state.get("route_candidate") or "")
    current_conf = float(state.get("route_confidence") or 0.0)
    if behavior_candidate:
        agent_name = behavior_candidate["agent"]
        entry = ctx.ROUTING_INDEX.get(agent_name, {})
        requires_prompt_and_behavior = bool(entry.get("require_prompt_and_behavior"))
        guarded = str(entry.get("route") or "") == "guarded"
        if requires_prompt_and_behavior:
            if str(state.get("route_candidate") or "") != agent_name:
                save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
                _print_json({"continue": True})
                raise SystemExit(0)
        if guarded:
            if bool(entry.get("block_in_template_repo")) and is_template_repo():
                save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
                _print_json({"continue": True})
                raise SystemExit(0)

        if current_candidate == agent_name:
            state["route_confidence"] = max(current_conf, float(behavior_candidate["confidence"]))
            state["route_reason"] = f"{state.get('route_reason')}; behavior:{behavior_candidate['reason']}"
            state["route_source"] = "prompt+behavior"
        elif not current_candidate:
            state["route_candidate"] = agent_name
            state["route_confidence"] = float(behavior_candidate["confidence"])
            state["route_reason"] = f"behavior:{behavior_candidate['reason']}"
            state["route_source"] = "behavior"
            state["route_emitted"] = False
            state["route_epoch"] = ctx.NOW

        candidate_name = str(state.get("route_candidate") or "")
        candidate_entry = ctx.ROUTING_INDEX.get(candidate_name, {})
        candidate_conf = float(state.get("route_confidence") or 0.0)
        min_behavior = float(candidate_entry.get("min_behavior_confidence") or 0.7)
        cooldown = int(ctx.ROUTING_MANIFEST.get("default_cooldown_seconds") or 900)
        if (
            candidate_name
            and behavior_candidate["agent"] == candidate_name
            and candidate_conf >= min_behavior
            and should_emit_route_hint(state, candidate_entry, ctx.NOW, candidate_name, cooldown)
        ):
            hint = str(candidate_entry.get("hint") or f"Routing hint: {candidate_name} specialist may be the best fit.")
            emitted_agents = list(state.get("route_emitted_agents") or [])
            emitted_agents.append(candidate_name)
            state["route_emitted_agents"] = emitted_agents
            state["route_emitted"] = True
            state["route_last_hint_epoch"] = ctx.NOW
            state["last_write_epoch"] = ctx.NOW
            save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
            _print_json({
                "continue": True,
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "additionalContext": f"{hint} Confidence {candidate_conf:.2f} ({state.get('route_source')}).",
                },
            })
            raise SystemExit(0)

    state["last_write_epoch"] = ctx.NOW
    save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
    _print_json({"continue": True})
    raise SystemExit(0)


def handle_soft_post_tool(state: dict, payload: dict, ctx: PulseContext) -> None:
    file_writing_tools = {
        "create_file", "replace_string_in_file", "multi_replace_string_in_file",
        "editFiles", "writeFile",
    }
    if str(payload.get("tool_name") or "") in file_writing_tools:
        state["copilot_edit_count"] = int(state.get("copilot_edit_count") or 0) + 1

    idle_gap_seconds = ctx.IDLE_GAP_MINUTES * 60
    task_window_start = int(state.get("task_window_start_epoch") or 0)
    last_tool = int(state.get("last_raw_tool_epoch") or 0)
    if task_window_start == 0:
        state["task_window_start_epoch"] = ctx.NOW
    elif last_tool > 0 and (ctx.NOW - last_tool) > idle_gap_seconds:
        state["active_work_seconds"] = int(state.get("active_work_seconds") or 0) + max(0, last_tool - task_window_start)
        state["task_window_start_epoch"] = ctx.NOW
        state["signal_idle_reset_seen"] = True
    state["last_raw_tool_epoch"] = ctx.NOW
    state["last_write_epoch"] = ctx.NOW
    state["tool_call_counter"] = int(state.get("tool_call_counter") or 0) + 1

    if ctx.NOW - int(state.get("last_soft_trigger_epoch") or 0) >= 300:
        state["last_soft_trigger_epoch"] = ctx.NOW
        append_event(ctx.EVENTS_PATH, ctx.WORKSPACE, ctx.NOW, ctx.TRIGGER, session_id=ctx.session_id)

    state, digest = update_intent_engine(
        state, payload, ctx.NOW,
        ctx.RETRO_MODIFIED_THRESHOLDS, ctx.RETRO_ELAPSED_THRESHOLDS,
        ctx.HEALTH_DIGEST_MIN_SPACING_SECONDS, ctx.build_recommendation, emit=True,
    )

    # VS Code-first retrospective: emit reflect instruction via PostToolUse
    # when thresholds are met, since VS Code does not fire the Stop hook.
    reflect_instruction = ""
    if (
        bool(state.get("signal_reflection_likely"))
        and not bool(state.get("reflect_instruction_emitted"))
        and _retro_state(state) not in ("complete", "accepted")
    ):
        state["reflect_instruction_emitted"] = True
        state["retrospective_state"] = "suggested"
        reflect_instruction = ctx.POST_TOOL_REFLECT_INSTRUCTION
        append_event(ctx.EVENTS_PATH, ctx.WORKSPACE, ctx.NOW, "post_tool_reflect", "reflect-needed", session_id=ctx.session_id)

    save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
    context_parts = [p for p in (digest, reflect_instruction) if p]
    if context_parts:
        _print_json({
            "continue": True,
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": " ".join(context_parts),
            },
        })
    else:
        _print_json({"continue": True})
    raise SystemExit(0)


def handle_compaction(state: dict, payload: dict, ctx: PulseContext) -> None:
    state = close_work_window(state)
    state["last_compaction_epoch"] = ctx.NOW
    state["last_write_epoch"] = ctx.NOW
    append_event(ctx.EVENTS_PATH, ctx.WORKSPACE, ctx.NOW, ctx.TRIGGER, session_id=ctx.session_id)
    state, _digest = update_intent_engine(
        state, None, ctx.NOW,
        ctx.RETRO_MODIFIED_THRESHOLDS, ctx.RETRO_ELAPSED_THRESHOLDS,
        ctx.HEALTH_DIGEST_MIN_SPACING_SECONDS, ctx.build_recommendation, emit=False,
    )
    save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
    _print_json({"continue": True})
    raise SystemExit(0)


def handle_user_prompt_explicit(state: dict, payload: dict, ctx: PulseContext) -> None:
    prompt = str(payload.get("prompt") or "")
    prompt_candidate = classify_prompt_route(prompt, ctx.ROUTING_MANIFEST)
    if prompt_candidate:
        state["route_candidate"] = prompt_candidate["agent"]
        state["route_reason"] = prompt_candidate["reason"]
        state["route_confidence"] = float(prompt_candidate["confidence"])
        state["route_source"] = "prompt"
        state["route_emitted"] = False
        state["route_epoch"] = ctx.NOW
        state["route_signal_counts"] = {}
    else:
        state.update({
            "route_candidate": "", "route_reason": "", "route_confidence": 0.0,
            "route_source": "", "route_emitted": False, "route_epoch": 0,
            "route_signal_counts": {},
        })
    retrospective_requested = prompt_requests_retrospective(prompt)
    heartbeat_requested = prompt_requests_heartbeat_check(prompt)
    if retrospective_requested:
        state["retrospective_state"] = "accepted"

    if heartbeat_requested or retrospective_requested:
        state["last_explicit_epoch"] = ctx.NOW
        state["last_write_epoch"] = ctx.NOW
        append_event(
            ctx.EVENTS_PATH, ctx.WORKSPACE, ctx.NOW, "explicit_prompt",
            "heartbeat" if heartbeat_requested else "retrospective",
            session_id=ctx.session_id,
        )
        state, _digest = update_intent_engine(
            state, None, ctx.NOW,
            ctx.RETRO_MODIFIED_THRESHOLDS, ctx.RETRO_ELAPSED_THRESHOLDS,
            ctx.HEALTH_DIGEST_MIN_SPACING_SECONDS, ctx.build_recommendation, emit=False,
        )
        save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
        if heartbeat_requested:
            _print_json({"continue": True, "systemMessage": ctx.EXPLICIT_SYSTEM_MESSAGE})
        else:
            _print_json({"continue": True})
    else:
        state["last_write_epoch"] = ctx.NOW
        save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
        _print_json({"continue": True})
    raise SystemExit(0)


def handle_stop(state: dict, payload: dict, ctx: PulseContext) -> None:
    # Claude Code / CLI fallback: the Stop hook is not fired by VS Code Copilot Chat.
    # The primary retrospective path is PostToolUse (handle_soft_post_tool above).
    if bool(payload.get("stop_hook_active", False)):
        _print_json({"continue": True})
        raise SystemExit(0)

    state = close_work_window(state)
    session_start_epoch = int(state.get("session_start_epoch") or 0)
    retro_ran = (
        state.get("retrospective_state") == "complete"
        or sentinel_is_complete(ctx.SENTINEL_PATH, ctx.session_id)
        or reflection_event_complete(ctx.EVENTS_PATH, ctx.session_id, session_start_epoch)
    )

    duration_seconds = max(0, ctx.NOW - session_start_epoch)
    if retro_ran:
        state["session_state"] = "complete"
        state["retrospective_state"] = "complete"
        state["last_write_epoch"] = ctx.NOW
        set_sentinel(ctx.SENTINEL_PATH, ctx.WORKSPACE, ctx.NOW, ctx.session_id, "complete")
        append_event(ctx.EVENTS_PATH, ctx.WORKSPACE, ctx.NOW, ctx.TRIGGER, "complete", duration_seconds, session_id=ctx.session_id)
        save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
        _print_json({"continue": True})
        raise SystemExit(0)

    if _retro_state(state) == "accepted":
        state["session_state"] = "pending"
        state["last_write_epoch"] = ctx.NOW
        append_event(ctx.EVENTS_PATH, ctx.WORKSPACE, ctx.NOW, ctx.TRIGGER, "accepted-pending", session_id=ctx.session_id)
        save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
        _print_json({
            "hookSpecificOutput": {
                "hookEventName": "Stop",
                "decision": "block",
                "reason": ctx.ACCEPTED_REASON,
            }
        })
        raise SystemExit(0)

    should_reflect, basis = ctx.build_recommendation(state)
    if should_reflect:
        state["session_state"] = "pending"
        state["retrospective_state"] = "suggested"
        state["last_write_epoch"] = ctx.NOW
        append_event(ctx.EVENTS_PATH, ctx.WORKSPACE, ctx.NOW, ctx.TRIGGER, "reflect-needed", session_id=ctx.session_id)
        save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
        _print_json({
            "hookSpecificOutput": {
                "hookEventName": "Stop",
                "decision": "block",
                "reason": f"Significant session ({basis}). {ctx.STOP_REFLECT_INSTRUCTION}",
            }
        })
        raise SystemExit(0)

    state["session_state"] = "complete"
    state["retrospective_state"] = "not-needed"
    state["last_write_epoch"] = ctx.NOW
    append_event(ctx.EVENTS_PATH, ctx.WORKSPACE, ctx.NOW, ctx.TRIGGER, "not-needed", duration_seconds, session_id=ctx.session_id)
    save_state(state, ctx.WORKSPACE, ctx.STATE_PATH)
    _print_json({"continue": True})
    raise SystemExit(0)
