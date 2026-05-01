#!/usr/bin/env python3
"""Heartbeat MCP server — session reflection, diary, and test-runner tools.

Provides:
- `session_reflect`: reads heartbeat state, computes session metrics,
  returns structured reflection prompts
- `write_diary` / `read_diaries`: persist and retrieve per-agent insights
- `run_tests`: runs the repo's bash test suites via the suite-manifest
  harness; accepts targeted suite paths or runs the full suite

Output is compact (~200 tokens) so the model can process it silently
and surface only actionable findings to the user.

Transport: stdio  |  Run: uvx --from "mcp[cli]" mcp run <this-file>
"""
from __future__ import annotations

import sys
from pathlib import Path

# Ensure sibling helper module is importable regardless of how mcp run sets up
# sys.path (the script directory is not always on sys.path when run via uvx).
sys.path.insert(0, str(Path(__file__).resolve().parent))

from mcp_heartbeat_lib import (  # noqa: E402
    DIARIES_DIR,
    HEARTBEAT_MD_PATH,
    EVENTS_PATH,
    ROOT,
    STATE_PATH,
    WORKSPACE,
    append_event,
    ensure_writable_tempdir,
    git_modified_count,
    load_state,
    load_workspace_cues,
    read_diary_summaries,
    session_events,
    set_sentinel_complete,
)

# Must run before importing FastMCP; the mcp package uses tempfile internally.
ensure_writable_tempdir()

import datetime  # noqa: E402
import json  # noqa: E402
import shutil  # noqa: E402
import subprocess  # noqa: E402
import time  # noqa: E402
from typing import Optional  # noqa: E402

from mcp.server.fastmcp import FastMCP  # noqa: E402

mcp = FastMCP("Heartbeat")


# ---------------------------------------------------------------------------
# Tool: session_reflect
# ---------------------------------------------------------------------------


@mcp.tool()
def session_reflect() -> dict:
    """Reflect on the current coding session.

    Returns session metrics and reflection prompts. Call on significant
    sessions (1 strong: >=8 files/>=30min; 2 supporting: >=5 files/>=15min/
    compaction). Process silently — update identity files if warranted.
    Surface only actionable findings.
    """
    state = load_state()
    now = int(time.time())

    session_start = int(state.get("session_start_epoch") or 0)
    session_duration_s = max(0, now - session_start) if session_start else 0

    active_s = int(state.get("active_work_seconds") or 0)
    tw_start = int(state.get("task_window_start_epoch") or 0)
    last_tool = int(state.get("last_raw_tool_epoch") or 0)
    if tw_start > 0 and last_tool >= tw_start:
        active_s += max(0, last_tool - tw_start)

    delta_files = max(
        0,
        git_modified_count() - int(state.get("session_start_git_count") or 0),
    )
    edit_count = int(state.get("copilot_edit_count") or 0)
    effective_files = delta_files if delta_files > 0 else edit_count
    compactions = sum(
        1 for ev in session_events(state, 50) if ev.get("trigger") == "compaction"
    )

    active_min = active_s // 60
    if effective_files >= 8 or active_min >= 30:
        magnitude = "large"
    elif effective_files >= 5 or active_min >= 15:
        magnitude = "medium"
    else:
        magnitude = "small"

    prompts: list[str] = []
    if effective_files > 0:
        label = "files changed" if delta_files > 0 else "files edited (committed)"
        prompts.append(f"{effective_files} {label}, {active_min}min — check accuracy+scope")
    if compactions > 0:
        prompts.append("Compaction — verify no decisions lost")
    if effective_files >= 5:
        prompts.append("Test coverage and docs kept pace?")

    cues = load_workspace_cues()
    if cues["soul_values"]:
        values_str = ", ".join(cues["soul_values"][:3])
        prompts.append(f"SOUL values: {values_str} — honoured?")
    if cues["user_attributes"]:
        prompts.append(f"USER: {cues['user_attributes'][0]} — aligned?")

    ws = {
        "soul_exists": (WORKSPACE / "identity/SOUL.md").exists(),
        "memory_exists": (WORKSPACE / "knowledge/MEMORY.md").exists(),
        "user_exists": (WORKSPACE / "knowledge/USER.md").exists(),
    }

    session_id = state.get("session_id") or "unknown"
    append_event("session_reflect", "complete", session_id=str(session_id))
    set_sentinel_complete(session_id)

    today = datetime.date.today().isoformat()
    short_id = str(session_id)[:16]
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
        "memory_protocol": "See §14 Alignment Protocol.",
        "workspace_state": ws,
        "heartbeat_record": {
            "file": str(HEARTBEAT_MD_PATH),
            "instruction": "Append to ## History (keep last 5); set Result (PASS/WARN/FAIL) and Actions taken.",
            "row_template": f"| {today} | {short_id} | session_reflect | PASS | <actions taken> |",
        },
    }


# ---------------------------------------------------------------------------
# Tool: write_diary
# ---------------------------------------------------------------------------


@mcp.tool()
def write_diary(agent_name: str, finding: str) -> dict:
    """Record a durable finding in an agent's diary file.

    Call when you discover a workspace insight worth sharing across sessions.
    The entry is timestamped, deduplicated, and the file is capped at 30 lines.
    Diary files live at .copilot/workspace/knowledge/diaries/{agent_name}.md.

    Args:
        agent_name: The calling agent's name (e.g. "Explore", "Audit").
        finding:    A single-sentence insight to persist (truncated to 200 chars).
    """
    if not agent_name or not finding:
        return {"error": "agent_name and finding are required"}
    finding = finding[:200].strip()
    if not finding:
        return {"error": "finding is empty after trimming"}

    agent_lower = agent_name.lower()
    diary_file = DIARIES_DIR / f"{agent_lower}.md"

    if diary_file.exists() and finding in diary_file.read_text(encoding="utf-8"):
        return {"status": "skipped", "reason": "duplicate", "agent": agent_name}

    DIARIES_DIR.mkdir(parents=True, exist_ok=True)
    if not diary_file.exists():
        diary_file.write_text(f"# {agent_name} Diary\n\n", encoding="utf-8")

    timestamp = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    entry = f"- {timestamp} {finding}"
    with diary_file.open("a", encoding="utf-8") as fh:
        fh.write(entry + "\n")

    lines = diary_file.read_text(encoding="utf-8").splitlines()
    if len(lines) > 30:
        kept = lines[:2] + lines[-28:]
        diary_file.write_text("\n".join(kept) + "\n", encoding="utf-8")

    return {"status": "written", "agent": agent_name, "entry": entry}


# ---------------------------------------------------------------------------
# Tool: read_diaries
# ---------------------------------------------------------------------------


@mcp.tool()
def read_diaries(agent_name: str = "") -> dict:
    """Read diary entries for one agent or all agents.

    Diaries are per-agent files under .copilot/workspace/knowledge/diaries/.
    They record durable insights written explicitly via write_diary.

    Args:
        agent_name: Agent name to read (e.g. "Explore"). Omit to read all
                    agents (last 3 entries each).
    """
    if agent_name:
        agent_lower = agent_name.lower()
        diary_file = DIARIES_DIR / f"{agent_lower}.md"
        if not diary_file.exists():
            return {"agent": agent_name, "entries": [], "note": "no diary yet"}
        lines = [
            l.strip()
            for l in diary_file.read_text(encoding="utf-8").splitlines()
            if l.strip().startswith("- ")
        ]
        return {"agent": agent_name, "entries": lines}

    return {"diaries": read_diary_summaries(max_entries=3)}


# ---------------------------------------------------------------------------
# Tool: run_tests
# ---------------------------------------------------------------------------

_SUITE_MANIFEST_REL = "scripts/harness/suite-manifest.json"
_SUITE_MANIFEST_PY_REL = "scripts/harness/suite-manifest.py"


def _load_suite_manifest(workspace: Path) -> dict:
    manifest_path = workspace / _SUITE_MANIFEST_REL
    if not manifest_path.is_file():
        raise FileNotFoundError(f"suite manifest not found: {manifest_path}")
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def _command_available(command: str) -> bool:
    return shutil.which(command) is not None


def _phase_skip_reason(phase: dict, workspace: Path) -> Optional[str]:
    req = phase.get("optionalRequirement")
    if not isinstance(req, dict):
        return None
    command = str(req.get("command", ""))
    label = str(req.get("label", command))
    probe_args = [str(a) for a in req.get("probeArgs", [])]
    if not _command_available(command):
        return f"missing {label}"
    if probe_args:
        result = subprocess.run(
            [command, *probe_args],
            cwd=workspace,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if result.returncode != 0:
            return f"{label} non-functional"
    return None


def _run_single_suite(suite_path: str, workspace: Path) -> dict:
    """Run one bash suite; return {status, elapsed_s, output_tail}."""
    start = time.monotonic()
    result = subprocess.run(
        ["bash", suite_path],
        cwd=workspace,
        capture_output=True,
        text=True,
        check=False,
    )
    elapsed = round(time.monotonic() - start, 1)
    output = (result.stdout + result.stderr).strip()
    # Keep last 8 lines to stay within token budget.
    tail = "\n".join(output.splitlines()[-8:]) if output else ""
    status = "passed" if result.returncode == 0 else "failed"
    return {"suite": suite_path, "status": status, "elapsed_s": elapsed, "output_tail": tail}


@mcp.tool()
def run_tests(
    files: Optional[list[str]] = None,
    mode: str = "targeted",
) -> dict:
    """Run the repo's bash test suites via the suite-manifest harness.

    Prefer this tool over running terminal commands to execute tests.
    Runs one or more targeted suites, or the full suite when mode is "full".
    Returns a structured summary with per-suite pass/fail status.

    Args:
        files: Repo-relative paths to specific suite scripts to run
               (e.g. ["tests/scripts/test-suite-manifest.sh"]).
               If empty or omitted, behaviour depends on mode.
        mode:  "targeted" — run only the suites listed in `files` (required).
               "full"     — run all suites in all phases via suite-manifest.
    """
    workspace = ROOT

    manifest = _load_suite_manifest(workspace)
    phases: list[dict] = manifest.get("phases", [])
    suites: list[dict] = manifest.get("suites", [])

    phases_by_id = {str(p["id"]): p for p in phases}
    suite_by_path = {str(s["path"]): s for s in suites}

    details: list[dict] = []
    skipped: list[str] = []

    if mode == "full" or not files:
        # Full run: iterate phases in order, respect optionalRequirement.
        suites_by_phase: dict[str, list[dict]] = {str(p["id"]): [] for p in phases}
        for s in suites:
            suites_by_phase[str(s["phase"])].append(s)

        for phase in phases:
            phase_id = str(phase["id"])
            skip_reason = _phase_skip_reason(phase, workspace)
            if skip_reason is not None:
                phase_suites = [str(s["path"]) for s in suites_by_phase[phase_id]]
                skipped.extend(phase_suites)
                continue
            for s in suites_by_phase[phase_id]:
                details.append(_run_single_suite(str(s["path"]), workspace))
    else:
        # Targeted run: run exactly the requested suites.
        for f in files:
            # Normalise: strip leading "./" or workspace prefix.
            rel = f.replace(str(workspace) + "/", "").lstrip("./")
            suite_entry = suite_by_path.get(rel)
            if suite_entry is None:
                details.append({
                    "suite": rel,
                    "status": "error",
                    "elapsed_s": 0,
                    "output_tail": f"suite path not found in manifest: {rel}",
                })
                continue
            phase = phases_by_id.get(str(suite_entry["phase"]), {})
            skip_reason = _phase_skip_reason(phase, workspace)
            if skip_reason is not None:
                skipped.append(rel)
                continue
            details.append(_run_single_suite(rel, workspace))

    passed = sum(1 for d in details if d["status"] == "passed")
    failed_list = [d["suite"] for d in details if d["status"] not in ("passed", "error")]
    errors = [d["suite"] for d in details if d["status"] == "error"]
    total = len(details)

    return {
        "summary": {
            "total": total,
            "passed": passed,
            "failed": len(failed_list),
            "errors": len(errors),
            "skipped": len(skipped),
            "all_passed": total > 0 and passed == total,
        },
        "failed_suites": failed_list,
        "skipped_suites": skipped,
        "details": details,
    }


if __name__ == "__main__":
    mcp.run()
