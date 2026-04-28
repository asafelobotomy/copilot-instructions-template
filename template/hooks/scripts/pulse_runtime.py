#!/usr/bin/env python3
"""Heartbeat pulse — runtime dispatcher.

Reads the hook trigger from argv[1] (or $TRIGGER), deserialises the JSON
payload from stdin (or $HOOK_INPUT), initialises session state, then
delegates to the appropriate handler in pulse_handlers.py.
"""
from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

from pulse_routing import load_routing_manifest, routing_index
from pulse_state import DEFAULT_POLICY, load_policy, load_state, recommend_retrospective
from pulse_handlers import (
    PulseContext,
    handle_compaction,
    handle_pre_tool,
    handle_session_start,
    handle_soft_post_tool,
    handle_stop,
    handle_user_prompt_explicit,
)


# ---------------------------------------------------------------------------
# Resolve inputs
# ---------------------------------------------------------------------------


def resolve_trigger(argv: list[str]) -> str:
    if len(argv) > 1 and argv[1]:
        return argv[1]
    return os.environ.get("TRIGGER", "")


def resolve_raw_input(argv: list[str]) -> str:
    if len(argv) > 1:
        try:
            return sys.stdin.read()
        except Exception:
            return ""
    return os.environ.get("HOOK_INPUT", "")


def parse_input(raw: str) -> dict:
    try:
        data = json.loads(raw) if raw.strip() else {}
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


TRIGGER = resolve_trigger(sys.argv)
RAW_INPUT = resolve_raw_input(sys.argv)
NOW = int(time.time())
SCRIPT_DIR = Path(__file__).resolve().parent

WORKSPACE = Path(".copilot/workspace")
STATE_PATH = WORKSPACE / "runtime/state.json"
SENTINEL_PATH = WORKSPACE / "runtime/.heartbeat-session"
EVENTS_PATH = WORKSPACE / "runtime/.heartbeat-events.jsonl"
POLICY_PATH = SCRIPT_DIR / "heartbeat-policy.json"
ROUTING_MANIFEST_PATH = Path("agents/routing-manifest.json")

# ---------------------------------------------------------------------------
# Policy constants
# ---------------------------------------------------------------------------

POLICY = load_policy(POLICY_PATH)
ROUTING_MANIFEST = load_routing_manifest(ROUTING_MANIFEST_PATH, SCRIPT_DIR)
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
POST_TOOL_REFLECT_INSTRUCTION = str(
    RETRO_MESSAGES.get("post_tool_reflect_instruction")
    or DEFAULT_POLICY["retrospective"]["messages"]["post_tool_reflect_instruction"]
)


def build_recommendation(state: dict) -> tuple[bool, str]:
    return recommend_retrospective(state, RETRO_MODIFIED_THRESHOLDS, RETRO_ELAPSED_THRESHOLDS)


# ---------------------------------------------------------------------------
# State initialisation
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

ctx = PulseContext(
    NOW=NOW, session_id=session_id, TRIGGER=TRIGGER,
    STATE_PATH=STATE_PATH, SENTINEL_PATH=SENTINEL_PATH,
    EVENTS_PATH=EVENTS_PATH, WORKSPACE=WORKSPACE,
    ROUTING_MANIFEST=ROUTING_MANIFEST, ROUTING_INDEX=ROUTING_INDEX,
    RETRO_MODIFIED_THRESHOLDS=RETRO_MODIFIED_THRESHOLDS,
    RETRO_ELAPSED_THRESHOLDS=RETRO_ELAPSED_THRESHOLDS,
    IDLE_GAP_MINUTES=IDLE_GAP_MINUTES,
    HEALTH_DIGEST_MIN_SPACING_SECONDS=HEALTH_DIGEST_MIN_SPACING_SECONDS,
    SESSION_START_GUIDANCE=SESSION_START_GUIDANCE,
    EXPLICIT_SYSTEM_MESSAGE=EXPLICIT_SYSTEM_MESSAGE,
    STOP_REFLECT_INSTRUCTION=STOP_REFLECT_INSTRUCTION,
    ACCEPTED_REASON=ACCEPTED_REASON,
    POST_TOOL_REFLECT_INSTRUCTION=POST_TOOL_REFLECT_INSTRUCTION,
    build_recommendation=build_recommendation,
)

if TRIGGER == "session_start":
    handle_session_start(state, payload, ctx)
elif TRIGGER == "pre_tool":
    handle_pre_tool(state, payload, ctx)
elif TRIGGER == "soft_post_tool":
    handle_soft_post_tool(state, payload, ctx)
elif TRIGGER == "compaction":
    handle_compaction(state, payload, ctx)
elif TRIGGER in ("user_prompt", "explicit"):
    handle_user_prompt_explicit(state, payload, ctx)
elif TRIGGER == "stop":
    handle_stop(state, payload, ctx)
