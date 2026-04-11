#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import time
from pathlib import Path

from pulse_intent import update_intent_engine
from pulse_paths import extract_tool_paths
from pulse_state import (
    DEFAULT_POLICY,
    append_event,
    close_work_window,
    compute_session_medians,
    get_git_modified_file_count,
    iso_utc,
    load_policy,
    load_session_priors,
    load_state,
    prune_events,
    reflection_event_complete,
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
STATE_PATH = WORKSPACE / "runtime/state.json"
SENTINEL_PATH = WORKSPACE / "runtime/.heartbeat-session"
EVENTS_PATH = WORKSPACE / "runtime/.heartbeat-events.jsonl"
HEARTBEAT_PATH = WORKSPACE / "operations/HEARTBEAT.md"
POLICY_PATH = SCRIPT_DIR / "heartbeat-policy.json"
ROUTING_MANIFEST_PATH = Path(".github/agents/routing-manifest.json")


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
    if re.search(
        r"\b(explain|review|describe|summari[sz]e|discuss|compare|analy[sz]e|policy|threshold|logic|docs?|documentation|rules?)\b",
        prompt,
        flags=re.IGNORECASE,
    ):
        return False
    patterns = (
        r"^\s*retrospective(?:\s+(?:now|please))?\s*[?.!]*$",
        r"^\s*(?:run|do|start|perform)\s+(?:a\s+)?retrospective\b",
        r"\b(run|do|start|perform)\b.*\bretrospective\b",
        r"\b(can|could|would)\s+you\b.*\b(run|do|start|perform)\b.*\bretrospective\b",
        r"\bplease\b.*\b(run|do|start|perform)\b.*\bretrospective\b",
    )
    return any(re.search(pattern, prompt, flags=re.IGNORECASE) for pattern in patterns)


def prompt_requests_heartbeat_check(prompt: str) -> bool:
    if re.search(r"\b(no|skip|don't|do not)\b.*\b(heartbeat|health check)\b", prompt, flags=re.IGNORECASE):
        return False
    if re.search(
        r"\b(explain|review|describe|summari[sz]e|discuss|compare|analy[sz]e|policy|threshold|logic|docs?|documentation|rules?)\b",
        prompt,
        flags=re.IGNORECASE,
    ):
        return False
    patterns = (
        r"^\s*heartbeat(?:\s+now)?\s*[?.!]*$",
        r"^\s*(?:check|run)\s+(?:your\s+)?heartbeat\b",
        r"\b(check|run)\b.*\bheartbeat\b",
        r"\b(run|do)\b.*\bhealth check\b",
        r"\b(can|could|would)\s+you\b.*\b(check|run|do)\b.*\b(heartbeat|health check)\b",
    )
    return any(re.search(pattern, prompt, flags=re.IGNORECASE) for pattern in patterns)


_EMPTY_MANIFEST: dict = {"version": 1, "agents": []}


def _find_routing_manifest(relative: Path) -> Path | None:
    """Try CWD-relative first, then walk up from SCRIPT_DIR to repo root."""
    if relative.exists():
        return relative
    anchor = SCRIPT_DIR
    for _ in range(6):
        candidate = anchor / relative
        if candidate.exists():
            return candidate
        if anchor.parent == anchor:
            break
        anchor = anchor.parent
    return None


def load_routing_manifest(path: Path) -> dict:
    resolved = _find_routing_manifest(path)
    if resolved is None:
        return _EMPTY_MANIFEST
    try:
        loaded = json.loads(resolved.read_text(encoding="utf-8"))
        if isinstance(loaded, dict) and isinstance(loaded.get("agents"), list):
            return loaded
    except Exception:
        pass
    return _EMPTY_MANIFEST


def routing_index(manifest: dict) -> dict[str, dict]:
    index: dict[str, dict] = {}
    for entry in manifest.get("agents", []):
        if isinstance(entry, dict) and isinstance(entry.get("name"), str):
            index[entry["name"]] = entry
    return index


def is_template_repo() -> bool:
    return Path("template/copilot-instructions.md").exists() and Path(".github/copilot-instructions.md").exists()


def extract_command_text(payload: dict) -> str:
    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        return ""
    for key in ("command", "cmd", "script", "query", "goal", "explanation"):
        value = tool_input.get(key)
        if isinstance(value, str) and value.strip():
            return value
    return ""


def compile_patterns(patterns) -> list[re.Pattern]:
    compiled = []
    for pattern in patterns or []:
        if not isinstance(pattern, str) or not pattern.strip():
            continue
        try:
            compiled.append(re.compile(pattern, re.IGNORECASE))
        except Exception:
            continue
    return compiled


def classify_prompt_route(prompt: str, manifest: dict) -> dict | None:
    if not prompt.strip():
        return None
    best = None
    for entry in manifest.get("agents", []):
        route_mode = str(entry.get("route") or "inactive")
        if route_mode not in {"active", "guarded"}:
            continue
        suppressors = compile_patterns(entry.get("suppress_patterns"))
        if any(regex.search(prompt) for regex in suppressors):
            continue
        patterns = compile_patterns(entry.get("prompt_patterns"))
        matches = [regex.pattern for regex in patterns if regex.search(prompt)]
        if not matches:
            continue
        confidence = min(0.99, 0.62 + 0.14 * len(matches))
        if route_mode == "guarded":
            confidence = min(0.99, confidence + 0.08)
        minimum = float(entry.get("min_prompt_confidence") or 0.75)
        if confidence < minimum:
            continue
        candidate = {
            "agent": entry["name"],
            "confidence": confidence,
            "reason": f"prompt:{matches[0]}",
            "route": route_mode,
        }
        if not best or candidate["confidence"] > best["confidence"]:
            best = candidate
    return best


def classify_behavior_route(payload: dict, state: dict, manifest: dict) -> dict | None:
    tool_name = str(payload.get("tool_name") or "")
    command_text = extract_command_text(payload)
    touched_paths = extract_tool_paths(payload)
    current_candidate = str(state.get("route_candidate") or "")
    best = None
    for entry in manifest.get("agents", []):
        route_mode = str(entry.get("route") or "inactive")
        if route_mode not in {"active", "guarded"}:
            continue
        if bool(entry.get("require_prompt_and_behavior")) and current_candidate and entry.get("name") != current_candidate:
            continue
        behavior = entry.get("behavior") or {}
        score = 0.0
        reasons: list[str] = []

        tool_names = {str(item) for item in behavior.get("tool_names") or [] if isinstance(item, str)}
        if tool_name and tool_name in tool_names:
            score += 0.48
            reasons.append(f"tool:{tool_name}")

        command_patterns = compile_patterns(behavior.get("command_patterns"))
        command_matched = False
        for regex in command_patterns:
            if command_text and regex.search(command_text):
                score += 0.32
                reasons.append(f"command:{regex.pattern}")
                command_matched = True
                break

        path_patterns = compile_patterns(behavior.get("path_patterns"))
        path_matched = False
        for regex in path_patterns:
            if any(regex.search(path_text) for path_text in touched_paths):
                score += 0.24
                reasons.append(f"path:{regex.pattern}")
                path_matched = True
                break

        if command_patterns and not command_matched and not path_matched:
            continue

        if score <= 0:
            continue
        signal_counts = state.get("route_signal_counts") or {}
        signal_key = entry["name"]
        seen_count = int(signal_counts.get(signal_key) or 0) + 1
        minimum_events = int(entry.get("min_behavior_events") or 1)
        confidence = min(0.99, 0.52 + score)
        minimum = float(entry.get("min_behavior_confidence") or 0.7)
        if seen_count < minimum_events or confidence < minimum:
            continue
        candidate = {
            "agent": entry["name"],
            "confidence": confidence,
            "reason": reasons[0],
            "seen_count": seen_count,
            "route": route_mode,
        }
        if not best or candidate["confidence"] > best["confidence"]:
            best = candidate
    return best


def should_emit_route_hint(state: dict, entry: dict, now: int, agent_name: str) -> bool:
    emitted_agents = state.get("route_emitted_agents") or []
    if agent_name in emitted_agents:
        return False
    cooldown = int(entry.get("cooldown_seconds") or 0)
    if cooldown <= 0:
        cooldown = int((ROUTING_MANIFEST.get("default_cooldown_seconds") or 900))
    last_hint_epoch = int(state.get("route_last_hint_epoch") or 0)
    if last_hint_epoch > 0 and (now - last_hint_epoch) < cooldown:
        return False
    if bool(state.get("route_emitted")) and str(state.get("route_candidate") or "") == agent_name:
        return False
    return True


def route_roster_text(manifest: dict) -> str:
    direct = []
    internal = []
    guarded = []
    for entry in manifest.get("agents", []):
        route_mode = str(entry.get("route") or "inactive")
        if route_mode not in {"active", "guarded"}:
            continue
        name = str(entry.get("name") or "")
        visibility = str(entry.get("visibility") or "internal")
        if route_mode == "guarded":
            guarded.append(name)
        elif visibility == "picker-visible":
            direct.append(name)
        else:
            internal.append(name)
    parts = []
    if direct:
        parts.append("specialists: " + ", ".join(direct))
    if internal:
        parts.append("internal: " + ", ".join(internal))
    if guarded:
        parts.append("guarded: " + ", ".join(guarded))
    return " | ".join(parts)


def print_json(payload: dict) -> None:
    print(json.dumps(payload, ensure_ascii=True))


POLICY = load_policy(POLICY_PATH)
ROUTING_MANIFEST = load_routing_manifest(ROUTING_MANIFEST_PATH)
ROUTING_INDEX = routing_index(ROUTING_MANIFEST)
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
    state["route_candidate"] = ""
    state["route_reason"] = ""
    state["route_confidence"] = 0.0
    state["route_source"] = ""
    state["route_emitted"] = False
    state["route_epoch"] = 0
    state["route_last_hint_epoch"] = 0
    state["route_emitted_agents"] = []
    state["route_signal_counts"] = {}
    state["changed_path_families"] = []
    state["touched_files_sample"] = []
    state["unique_touched_file_count"] = 0
    set_sentinel(SENTINEL_PATH, WORKSPACE, NOW, session_id, "pending")
    append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER, session_id=session_id)
    prune_events(EVENTS_PATH)
    save_state(state, WORKSPACE, STATE_PATH)
    ctx_parts = [
        f"Session started at {iso_utc(NOW)}.",
        *([compute_session_medians(EVENTS_PATH)] if compute_session_medians(EVENTS_PATH) else []),
        f"Routing roster: {route_roster_text(ROUTING_MANIFEST)}.",
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

if TRIGGER == "pre_tool":
    signal_counts = state.get("route_signal_counts") or {}
    behavior_candidate = classify_behavior_route(payload, state, ROUTING_MANIFEST)
    if behavior_candidate:
        signal_counts[behavior_candidate["agent"]] = int(signal_counts.get(behavior_candidate["agent"]) or 0) + 1
        state["route_signal_counts"] = signal_counts

    current_candidate = str(state.get("route_candidate") or "")
    current_conf = float(state.get("route_confidence") or 0.0)
    if behavior_candidate:
        agent_name = behavior_candidate["agent"]
        entry = ROUTING_INDEX.get(agent_name, {})
        requires_prompt_and_behavior = bool(entry.get("require_prompt_and_behavior"))
        guarded = str(entry.get("route") or "") == "guarded"
        if requires_prompt_and_behavior:
            if str(state.get("route_candidate") or "") != agent_name:
                save_state(state, WORKSPACE, STATE_PATH)
                print_json({"continue": True})
                raise SystemExit(0)
        if guarded:
            if bool(entry.get("block_in_template_repo")) and is_template_repo():
                save_state(state, WORKSPACE, STATE_PATH)
                print_json({"continue": True})
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
            state["route_epoch"] = NOW

        candidate_name = str(state.get("route_candidate") or "")
        candidate_entry = ROUTING_INDEX.get(candidate_name, {})
        candidate_conf = float(state.get("route_confidence") or 0.0)
        min_behavior = float(candidate_entry.get("min_behavior_confidence") or 0.7)
        if (
            candidate_name
            and behavior_candidate["agent"] == candidate_name
            and candidate_conf >= min_behavior
            and should_emit_route_hint(state, candidate_entry, NOW, candidate_name)
        ):
            hint = str(candidate_entry.get("hint") or f"Routing hint: {candidate_name} specialist may be the best fit.")
            emitted_agents = list(state.get("route_emitted_agents") or [])
            emitted_agents.append(candidate_name)
            state["route_emitted_agents"] = emitted_agents
            state["route_emitted"] = True
            state["route_last_hint_epoch"] = NOW
            state["last_write_epoch"] = NOW
            save_state(state, WORKSPACE, STATE_PATH)
            print_json({
                "continue": True,
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "additionalContext": f"{hint} Confidence {candidate_conf:.2f} ({state.get('route_source')}).",
                },
            })
            raise SystemExit(0)

    state["last_write_epoch"] = NOW
    save_state(state, WORKSPACE, STATE_PATH)
    print_json({"continue": True})
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
        append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER, session_id=session_id)

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
    append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER, session_id=session_id)
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
    prompt_candidate = classify_prompt_route(prompt, ROUTING_MANIFEST)
    if prompt_candidate:
        state["route_candidate"] = prompt_candidate["agent"]
        state["route_reason"] = prompt_candidate["reason"]
        state["route_confidence"] = float(prompt_candidate["confidence"])
        state["route_source"] = "prompt"
        state["route_emitted"] = False
        state["route_epoch"] = NOW
        state["route_signal_counts"] = {}
    else:
        state["route_candidate"] = ""
        state["route_reason"] = ""
        state["route_confidence"] = 0.0
        state["route_source"] = ""
        state["route_emitted"] = False
        state["route_epoch"] = 0
        state["route_signal_counts"] = {}
    retrospective_requested = prompt_requests_retrospective(prompt)
    heartbeat_requested = prompt_requests_heartbeat_check(prompt)
    if retrospective_requested:
        state["retrospective_state"] = "accepted"

    if heartbeat_requested or retrospective_requested:
        state["last_explicit_epoch"] = NOW
        state["last_write_epoch"] = NOW
        append_event(
            EVENTS_PATH,
            WORKSPACE,
            NOW,
            "explicit_prompt",
            "heartbeat" if heartbeat_requested else "retrospective",
            session_id=session_id,
        )
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
        state["last_write_epoch"] = NOW
        save_state(state, WORKSPACE, STATE_PATH)
        print_json({"continue": True})
    raise SystemExit(0)

if TRIGGER == "stop":
    if bool(payload.get("stop_hook_active", False)):
        print_json({"continue": True})
        raise SystemExit(0)

    state = close_work_window(state)
    session_start_epoch = int(state.get("session_start_epoch") or 0)
    retro_ran = (
        state.get("retrospective_state") == "complete"
        or sentinel_is_complete(SENTINEL_PATH, session_id)
        or reflection_event_complete(
            EVENTS_PATH,
            session_id,
            session_start_epoch,
        )
    )

    duration_seconds = max(0, NOW - session_start_epoch)
    if retro_ran:
        state["session_state"] = "complete"
        state["retrospective_state"] = "complete"
        state["last_write_epoch"] = NOW
        set_sentinel(SENTINEL_PATH, WORKSPACE, NOW, session_id, "complete")
        append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER, "complete", duration_seconds, session_id=session_id)
        save_state(state, WORKSPACE, STATE_PATH)
        print_json({"continue": True})
        raise SystemExit(0)

    if retrospective_state(state) == "accepted":
        state["session_state"] = "pending"
        state["last_write_epoch"] = NOW
        append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER, "accepted-pending", session_id=session_id)
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
        append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER, "reflect-needed", session_id=session_id)
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
    append_event(EVENTS_PATH, WORKSPACE, NOW, TRIGGER, "not-needed", duration_seconds, session_id=session_id)
    save_state(state, WORKSPACE, STATE_PATH)
    print_json({"continue": True})
    raise SystemExit(0)

print_json({"continue": True})