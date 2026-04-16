#!/usr/bin/env python3
"""Routing and classification functions for the heartbeat pulse subsystem.

Provides prompt/behavior-based agent routing, manifest loading, and
request-type detection used by pulse_runtime.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from pulse_paths import extract_tool_paths


_EMPTY_MANIFEST: dict = {"version": 1, "agents": []}


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


def find_routing_manifest(relative: Path, script_dir: Path) -> Path | None:
    """Try CWD-relative first, then walk up from script_dir to repo root."""
    if relative.exists():
        return relative
    anchor = script_dir
    for _ in range(6):
        candidate = anchor / relative
        if candidate.exists():
            return candidate
        if anchor.parent == anchor:
            break
        anchor = anchor.parent
    return None


def load_routing_manifest(path: Path, script_dir: Path) -> dict:
    resolved = find_routing_manifest(path, script_dir)
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


def should_emit_route_hint(state: dict, entry: dict, now: int, agent_name: str, default_cooldown: int = 900) -> bool:
    emitted_agents = state.get("route_emitted_agents") or []
    if agent_name in emitted_agents:
        return False
    cooldown = int(entry.get("cooldown_seconds") or 0)
    if cooldown <= 0:
        cooldown = default_cooldown
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
        parts.append(", ".join(direct))
    if internal:
        parts.append("internal: " + ", ".join(internal))
    if guarded:
        parts.append("guarded: " + ", ".join(guarded))
    return " | ".join(parts)
