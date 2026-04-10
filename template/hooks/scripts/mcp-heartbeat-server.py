#!/usr/bin/env python3
"""Heartbeat MCP server — session reflection and spatial navigation tools.

Provides `session_reflect` (reads heartbeat state, computes session metrics,
returns structured reflection prompts) and `spatial_status` (returns workspace
vocabulary, diary summaries, and clock).  The model calls session_reflect
autonomously when the periodic health digest indicates significant work.
Output is compact (~200 tokens) so the model can process it silently
and surface only actionable findings to the user.

Transport: stdio  |  Run: uvx --from "mcp[cli]" mcp run <this-file>
"""
from __future__ import annotations

import json
import os
import pwd
import subprocess
import tempfile
import time
import hashlib
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Heartbeat")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _find_workspace_root() -> Path:
    """Detect the git repository root (works regardless of cwd)."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0:
            return Path(result.stdout.strip())
    except Exception:
        pass
    return Path.cwd()


ROOT = _find_workspace_root()
WORKSPACE = ROOT / ".copilot" / "workspace"
STATE_PATH = WORKSPACE / "state.json"
EVENTS_PATH = WORKSPACE / ".heartbeat-events.jsonl"
SENTINEL_PATH = WORKSPACE / ".heartbeat-session"


def _fallback_artifact_roots() -> list[Path]:
    roots: list[Path] = []
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


def _fallback_artifact_path(path: Path) -> Path:
    roots = _fallback_artifact_roots()
    tmp_root = roots[0] if roots else Path(tempfile.gettempdir())
    repo_key = hashlib.sha256(str(ROOT).encode("utf-8")).hexdigest()[:12]
    return tmp_root / "copilot-heartbeat" / repo_key / path.name


def _fallback_artifact_paths(path: Path) -> list[Path]:
    repo_key = hashlib.sha256(str(ROOT).encode("utf-8")).hexdigest()[:12]
    return [root_path / "copilot-heartbeat" / repo_key / path.name for root_path in _fallback_artifact_roots()]


def _artifact_candidates(path: Path) -> list[Path]:
    candidates = [path]
    for fallback in _fallback_artifact_paths(path):
        if fallback != path and fallback not in candidates:
            candidates.append(fallback)
    return candidates


def _load_state() -> dict:
    if not STATE_PATH.exists():
        return {}
    try:
        data = json.loads(STATE_PATH.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _git_modified_count() -> int:
    try:
        proc = subprocess.run(
            ["git", "status", "--porcelain"],
            capture_output=True,
            text=True,
            timeout=5,
            cwd=str(ROOT),
        )
        if proc.returncode == 0:
            return len([l for l in proc.stdout.splitlines() if l.strip()])
    except Exception:
        pass
    return 0


def _recent_events(limit: int = 20) -> list[dict]:
    events: list[dict] = []
    for candidate in _artifact_candidates(EVENTS_PATH):
        if not candidate.exists():
            continue
        try:
            for line in candidate.read_text(encoding="utf-8").splitlines():
                if not line.strip():
                    continue
                try:
                    events.append(json.loads(line))
                except Exception:
                    continue
        except Exception:
            continue
    return events[-limit:]


def _append_event(trigger: str, detail: str = "", session_id: str = "", duration_s: int | None = None) -> None:
    if not WORKSPACE.exists():
        return
    event = {
        "ts": int(time.time()),
        "ts_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "trigger": trigger,
    }
    if detail:
        event["detail"] = detail
    if session_id:
        event["session_id"] = session_id
    if duration_s is not None:
        event["duration_s"] = int(duration_s)
    payload = json.dumps(event, sort_keys=True) + "\n"
    last_error = None
    for candidate in _artifact_candidates(EVENTS_PATH):
        try:
            candidate.parent.mkdir(parents=True, exist_ok=True)
            with candidate.open("a", encoding="utf-8") as handle:
                handle.write(payload)
            return
        except OSError as exc:
            last_error = exc
            continue
    if last_error is not None:
        raise last_error


def _session_events(state: dict, limit: int = 50) -> list[dict]:
    session_id = str(state.get("session_id") or "")
    session_start = int(state.get("session_start_epoch") or 0)
    scoped: list[dict] = []
    for event in _recent_events(limit):
        if not isinstance(event, dict):
            continue
        event_session_id = str(event.get("session_id") or "")
        if session_id and event_session_id:
            if event_session_id != session_id:
                continue
        else:
            event_ts = event.get("ts")
            if session_start > 0 and isinstance(event_ts, (int, float)) and int(event_ts) < session_start:
                continue
        scoped.append(event)
    return scoped


def _set_sentinel_complete(session_id: str) -> None:
    """Mark the session sentinel as complete so the Stop hook passes through."""
    if not WORKSPACE.exists():
        return
    ts = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    payload = f"{session_id}|{ts}|complete\n"
    last_error = None
    for candidate in _artifact_candidates(SENTINEL_PATH):
        tmp = candidate.with_suffix(".tmp")
        try:
            candidate.parent.mkdir(parents=True, exist_ok=True)
            tmp.write_text(payload, encoding="utf-8")
            os.replace(tmp, candidate)
            return
        except OSError as exc:
            last_error = exc
            try:
                tmp.unlink(missing_ok=True)
            except OSError:
                pass
            continue
    if last_error is not None:
        raise last_error


def _load_workspace_cues() -> dict:
    """Read lightweight cues from SOUL.md and USER.md for personalised prompts."""
    cues: dict = {"soul_values": [], "user_attributes": []}
    soul_path = WORKSPACE / "SOUL.md"
    if soul_path.exists():
        try:
            in_values = False
            for line in soul_path.read_text(encoding="utf-8").splitlines():
                stripped = line.strip()
                if stripped.startswith("## "):
                    if in_values:
                        break  # left the core values block
                    continue
                if stripped.startswith("- **") and "**" in stripped[4:]:
                    in_values = True
                    key = stripped[4:stripped.index("**", 4)]
                    cues["soul_values"].append(key)
                    if len(cues["soul_values"]) >= 5:
                        break
        except Exception:
            pass
    user_path = WORKSPACE / "USER.md"
    if user_path.exists():
        try:
            in_table = False
            for line in user_path.read_text(encoding="utf-8").splitlines():
                stripped = line.strip()
                if stripped.startswith("| Attribute"):
                    in_table = True
                    continue
                if in_table and stripped.startswith("|"):
                    if set(stripped.replace("|", "").strip()) <= {"-", " "}:
                        continue
                    cells = [c.strip() for c in stripped.strip("|").split("|")]
                    if len(cells) >= 2 and cells[1] and "to be discovered" not in cells[1]:
                        cues["user_attributes"].append(f"{cells[0]}: {cells[1][:80]}")
                        if len(cues["user_attributes"]) >= 3:
                            break
                elif in_table and not stripped.startswith("|"):
                    in_table = False
        except Exception:
            pass
    return cues


# ---------------------------------------------------------------------------
# Tool
# ---------------------------------------------------------------------------


@mcp.tool()
def session_reflect() -> dict:
    """Reflect on the current coding session.

    Returns structured session metrics (files changed, active work time, edit
    count, key events) and lean reflection prompts.

    Call before ending any session where the health digest indicates significant
    work (one strong signal: 8+ modified files or 30+ minutes active; or two
    supporting signals: 5+ modified files, 15+ minutes active, or context
    compaction). Process the output
    silently — update SOUL.md, MEMORY.md, USER.md only if insights warrant it.
    Surface findings to the user only for actionable items (security concerns,
    tech debt, coverage gaps, broken assumptions).
    """
    state = _load_state()
    now = int(time.time())

    # --- Metrics -----------------------------------------------------------
    session_start = int(state.get("session_start_epoch") or 0)
    session_duration_s = max(0, now - session_start) if session_start else 0

    # Close any still-open work window for accurate active seconds.
    active_s = int(state.get("active_work_seconds") or 0)
    tw_start = int(state.get("task_window_start_epoch") or 0)
    last_tool = int(state.get("last_raw_tool_epoch") or 0)
    if tw_start > 0 and last_tool >= tw_start:
        active_s += max(0, last_tool - tw_start)

    delta_files = max(
        0,
        _git_modified_count() - int(state.get("session_start_git_count") or 0),
    )
    edit_count = int(state.get("copilot_edit_count") or 0)
    effective_files = delta_files if delta_files > 0 else edit_count
    compactions = sum(
        1 for ev in _session_events(state, 50) if ev.get("trigger") == "compaction"
    )

    # --- Magnitude ---------------------------------------------------------
    active_min = active_s // 60
    if effective_files >= 8 or active_min >= 30:
        magnitude = "large"
    elif effective_files >= 5 or active_min >= 15:
        magnitude = "medium"
    else:
        magnitude = "small"

    # --- Reflection prompts ------------------------------------------------
    prompts: list[str] = []
    if effective_files > 0:
        label = "files changed" if delta_files > 0 else "files edited (committed)"
        prompts.append(
            f"{effective_files} {label} across {active_min}min active"
            " — review execution accuracy and scope completeness"
        )
    if compactions > 0:
        prompts.append(
            "Context compaction occurred"
            " — verify no key decisions were lost"
        )
    if effective_files >= 5:
        prompts.append(
            "Consider whether test coverage and documentation kept pace"
        )

    # --- Personalised cues from workspace files ----------------------------
    cues = _load_workspace_cues()
    if cues["soul_values"]:
        values_str = ", ".join(cues["soul_values"][:3])
        prompts.append(
            f"SOUL values in play: {values_str}"
            " — did this session honour them?"
        )
    if cues["user_attributes"]:
        prompts.append(
            f"USER cue: {cues['user_attributes'][0]}"
            " — did the session align with this preference?"
        )

    # --- Workspace state ---------------------------------------------------
    ws = {
        "soul_exists": (WORKSPACE / "SOUL.md").exists(),
        "memory_exists": (WORKSPACE / "MEMORY.md").exists(),
        "user_exists": (WORKSPACE / "USER.md").exists(),
    }

    # --- Set sentinel complete ---------------------------------------------
    session_id = state.get("session_id") or "unknown"
    _append_event("session_reflect", "complete", session_id=str(session_id))
    _set_sentinel_complete(session_id)

    return {
        "magnitude": magnitude,
        "metrics": {
            "active_work_minutes": active_min,
            "files_changed": effective_files,
            "edits_tracked": edit_count,
            "compactions": compactions,
            "session_duration_minutes": session_duration_s // 60,
        },
        "reflection_prompts": prompts,
        "memory_protocol": "See §14 Alignment Protocol in the instructions file.",
        "workspace_state": ws,
    }


# ---------------------------------------------------------------------------
# Tool: spatial_status — compact workspace navigation snapshot
# ---------------------------------------------------------------------------

DIARIES_DIR = WORKSPACE / "diaries"
LEDGER_PATH = WORKSPACE / "ledger.md"


def _read_diary_summaries(max_entries: int = 3) -> dict[str, list[str]]:
    """Read the most recent entries from each agent diary file."""
    summaries: dict[str, list[str]] = {}
    if not DIARIES_DIR.is_dir():
        return summaries
    for diary in sorted(DIARIES_DIR.glob("*.md")):
        if diary.name == "README.md":
            continue
        lines = [
            l.strip()
            for l in diary.read_text(encoding="utf-8").splitlines()
            if l.strip().startswith("- ")
        ]
        if lines:
            summaries[diary.stem] = lines[-max_entries:]
    return summaries


def _read_vocabulary() -> list[str]:
    """Extract the vocabulary table from the ledger file."""
    if not LEDGER_PATH.exists():
        return []
    lines = LEDGER_PATH.read_text(encoding="utf-8").splitlines()
    vocab: list[str] = []
    in_table = False
    for line in lines:
        if "|" in line and ("Term" in line or "Meaning" in line):
            in_table = True
            continue
        if in_table and line.startswith("|"):
            if line.replace("|", "").replace("-", "").strip():
                vocab.append(line.strip())
        elif in_table and not line.startswith("|"):
            break
    return vocab


@mcp.tool()
def spatial_status() -> dict:
    """Return a compact workspace navigation snapshot.

    Includes spatial vocabulary, recent diary entries per agent, and the
    current session clock summary. Call when you need a quick overview of
    the workspace state.
    """
    from heartbeat_clock_summary import build_clock_summary

    clock = ""
    try:
        clock = build_clock_summary(WORKSPACE)
    except Exception:
        clock = "clock unavailable"

    return {
        "vocabulary": _read_vocabulary(),
        "diaries": _read_diary_summaries(),
        "clock": clock,
    }


if __name__ == "__main__":
    mcp.run()
