#!/usr/bin/env python3
"""Emit a one-line heartbeat timing summary for save-context hooks."""

from __future__ import annotations

import json
import hashlib
import os
import pwd
import sys
import tempfile
import time
from pathlib import Path
from typing import Dict, List, Sequence


MAX_SUMMARY_LENGTH = 400


def iso_utc(epoch: int) -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(int(epoch)))


def format_duration(seconds: int) -> str:
    seconds = max(0, int(seconds))
    hours, remainder = divmod(seconds, 3600)
    minutes, secs = divmod(remainder, 60)
    if hours:
        return f"{hours}h {minutes}m"
    if minutes:
        return f"{minutes}m {secs}s" if minutes < 10 else f"{minutes}m"
    return f"{secs}s"


def load_json_object(path: Path) -> Dict[str, object]:
    if not path.exists():
        return {}
    try:
        loaded = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}
    return loaded if isinstance(loaded, dict) else {}


def fallback_artifact_roots() -> List[Path]:
    roots: List[Path] = []
    seen: set[str] = set()

    def add(candidate: Path | None) -> None:
        if candidate is None:
            return
        key = str(candidate)
        if key in seen:
            return
        seen.add(key)
        roots.append(candidate)

    claude_tmp = os.environ.get("CLAUDE_TMPDIR")
    if claude_tmp:
        add(Path(claude_tmp))
    env_tmp = os.environ.get("TMPDIR")
    if env_tmp:
        add(Path(env_tmp))
    add(Path(tempfile.gettempdir()))
    xdg_cache_home = os.environ.get("XDG_CACHE_HOME")
    if xdg_cache_home:
        add(Path(xdg_cache_home) / "uv")
    try:
        passwd_home = Path(pwd.getpwuid(os.getuid()).pw_dir)
    except Exception:
        passwd_home = None
    if passwd_home is not None:
        add(passwd_home / ".cache" / "uv")
        add(passwd_home / ".local" / "share" / "uv")
    home = Path.home()
    add(home / ".cache" / "uv")
    add(home / ".local" / "share" / "uv")
    return roots


def fallback_artifact_path(path: Path) -> Path:
    workspace = path.parent
    try:
        workspace_resolved = workspace.resolve()
    except Exception:
        workspace_resolved = workspace
    if workspace_resolved.name == "workspace" and workspace_resolved.parent.name == ".copilot":
        root = workspace_resolved.parent.parent
    else:
        root = workspace_resolved.parent
    roots = fallback_artifact_roots()
    tmp_root = roots[0] if roots else Path(tempfile.gettempdir())
    repo_key = hashlib.sha256(str(root).encode("utf-8")).hexdigest()[:12]
    return tmp_root / "copilot-heartbeat" / repo_key / path.name


def fallback_artifact_paths(path: Path) -> List[Path]:
    workspace = path.parent
    try:
        workspace_resolved = workspace.resolve()
    except Exception:
        workspace_resolved = workspace
    if workspace_resolved.name == "workspace" and workspace_resolved.parent.name == ".copilot":
        root = workspace_resolved.parent.parent
    else:
        root = workspace_resolved.parent
    repo_key = hashlib.sha256(str(root).encode("utf-8")).hexdigest()[:12]
    return [root_path / "copilot-heartbeat" / repo_key / path.name for root_path in fallback_artifact_roots()]


def heartbeat_artifact_paths(path: Path) -> List[Path]:
    candidates = [path]
    for fallback in fallback_artifact_paths(path):
        if fallback != path and fallback not in candidates:
            candidates.append(fallback)
    return candidates


def iter_completed_events(path: Path) -> List[Dict[str, object]]:
    events = []
    for candidate in heartbeat_artifact_paths(path):
        if not candidate.exists():
            continue
        try:
            lines = candidate.read_text(encoding="utf-8").splitlines()
        except Exception:
            continue
        for line in lines:
            if not line.strip():
                continue
            try:
                event = json.loads(line)
            except Exception:
                continue
            if not isinstance(event, dict):
                continue
            if event.get("trigger") == "stop" and event.get("detail") == "complete":
                events.append(event)
    return events


def build_clock_summary(workspace: Path) -> str:
    state = load_json_object(workspace / "state.json")
    events = iter_completed_events(workspace / ".heartbeat-events.jsonl")
    now = int(time.time())
    parts = []

    start_epoch = int(state.get("session_start_epoch") or 0)
    session_id = str(state.get("session_id") or "unknown")
    session_state = str(state.get("session_state") or "")
    if start_epoch and session_state != "complete":
        active_for = format_duration(now - start_epoch)
        started_at = iso_utc(start_epoch)
        parts.append(
            f"session {session_id} active for {active_for} since {started_at} UTC"
        )

    durations = []
    for event in events:
        duration = event.get("duration_s")
        if isinstance(duration, (int, float)):
            durations.append(int(duration))

    if durations:
        sorted_durations = sorted(durations)
        count = len(sorted_durations)
        middle = count // 2
        if count % 2:
            median = sorted_durations[middle]
        else:
            median = (sorted_durations[middle - 1] + sorted_durations[middle]) // 2
        parts.append(f"typical session {format_duration(median)} (median of {count})")

    if events:
        last_complete = events[-1]
        ended_at = str(last_complete.get("ts_utc") or "")
        if not ended_at and isinstance(last_complete.get("ts"), (int, float)):
            ended_at = iso_utc(int(last_complete["ts"]))
        duration = last_complete.get("duration_s")
        if ended_at and isinstance(duration, (int, float)):
            parts.append(
                "last completed session ended "
                f"{ended_at} after {format_duration(int(duration))}"
            )

    return "; ".join(parts)[:MAX_SUMMARY_LENGTH]


def main(argv: Sequence[str]) -> int:
    workspace = Path(argv[1]) if len(argv) > 1 else Path(".copilot/workspace")
    workspace = workspace.resolve()
    if not workspace.is_dir():
        return 0
    state_path = workspace / "state.json"
    events_path = workspace / ".heartbeat-events.jsonl"
    if not state_path.exists() and not events_path.exists():
        fallback_events = fallback_artifact_path(events_path)
        if not fallback_events.exists():
            return 0
    summary = build_clock_summary(workspace)
    if summary:
        sys.stdout.write(summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))