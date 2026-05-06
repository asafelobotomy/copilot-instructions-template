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
import os  # noqa: E402
import re  # noqa: E402
import signal  # noqa: E402
import shutil  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402
import time  # noqa: E402
from concurrent.futures import ThreadPoolExecutor, as_completed  # noqa: E402
from typing import Optional  # noqa: E402

from mcp.server.fastmcp import FastMCP  # noqa: E402

mcp = FastMCP("Heartbeat")


def _safe_int(val: object, default: int = 0) -> int:
    """Coerce *val* to int; return *default* on any failure."""
    try:
        return int(val) if val is not None else default
    except (TypeError, ValueError):
        return default


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

    session_start = _safe_int(state.get("session_start_epoch"))
    session_duration_s = max(0, now - session_start) if session_start else 0

    active_s = _safe_int(state.get("active_work_seconds"))
    tw_start = _safe_int(state.get("task_window_start_epoch"))
    last_tool = _safe_int(state.get("last_raw_tool_epoch"))
    if tw_start > 0 and last_tool >= tw_start:
        active_s += max(0, last_tool - tw_start)

    delta_files = max(
        0,
        git_modified_count() - _safe_int(state.get("session_start_git_count")),
    )
    edit_count = _safe_int(state.get("copilot_edit_count"))
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
    if not re.fullmatch(r"[a-z0-9_-]+", agent_lower):
        return {"error": "agent_name must contain only letters, digits, hyphens, and underscores"}
    diary_file = DIARIES_DIR / f"{agent_lower}.md"

    if diary_file.exists():
        existing_lines = diary_file.read_text(encoding="utf-8").splitlines()
        if any(finding in line for line in existing_lines if line.startswith("- ")):
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
        if not re.fullmatch(r"[a-z0-9_-]+", agent_lower):
            return {"error": "agent_name must contain only letters, digits, hyphens, and underscores"}
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

# Ordered candidates for stack detection. Each entry is (indicator_file_or_cmd,
# label, shell_command). The first whose indicator exists wins.
_STACK_TEST_CANDIDATES: list[tuple[str, str, str]] = [
    # file-indicator       label           shell command
    ("Cargo.toml",        "cargo test",   "cargo test"),
    ("go.mod",            "go test",      "go test ./..."),
    ("pyproject.toml",    "pytest",       "python3 -m pytest"),
    ("setup.py",          "pytest",       "python3 -m pytest"),
    ("requirements.txt",  "pytest",       "python3 -m pytest"),
    ("package.json",      "npm test",     "npm test"),
    ("Makefile",          "make test",    "make test"),
    ("tests/run-all.sh",  "bash harness", "bash tests/run-all.sh"),
    ("test",              "bash test/",   "bash test/run.sh"),
]


def _detect_test_command(workspace: Path) -> Optional[str]:
    """Return a shell command string for the detected stack, or None."""
    for indicator, _label, cmd in _STACK_TEST_CANDIDATES:
        if indicator == "package.json":
            pkg = workspace / "package.json"
            if not pkg.exists():
                continue
            try:
                scripts_test = (
                    json.loads(pkg.read_text(encoding="utf-8"))
                    .get("scripts", {})
                    .get("test", "")
                )
            except (json.JSONDecodeError, OSError):
                continue
            # Skip the default npm placeholder or missing test script
            if not scripts_test or "no test specified" in scripts_test:
                continue
            return cmd
        if (workspace / indicator).exists():
            return cmd
    return None


def _run_generic_command(cmd: str, workspace: Path, env: dict) -> dict:
    """Run an arbitrary shell command and return a run_tests-shaped dict."""
    start = time.monotonic()
    log_path: Optional[Path] = None
    timed_out = False
    try:
        fd, log_str = tempfile.mkstemp(suffix=".log", prefix="mcp-generic-test-")
        os.close(fd)
        log_path = Path(log_str)
        with log_path.open("w", encoding="utf-8", errors="replace") as log_fh:
            proc = subprocess.Popen(
                cmd,
                shell=True,
                cwd=workspace,
                stdin=subprocess.DEVNULL,
                stdout=log_fh,
                stderr=subprocess.STDOUT,
                env=env,
                start_new_session=True,
            )
            try:
                proc.wait(timeout=600)
            except subprocess.TimeoutExpired:
                timed_out = True
                pgid: Optional[int] = None
                try:
                    pgid = os.getpgid(proc.pid)
                except OSError:
                    pass
                if pgid is not None:
                    try:
                        os.killpg(pgid, signal.SIGTERM)
                    except (ProcessLookupError, OSError):
                        pass
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    if pgid is not None:
                        try:
                            os.killpg(pgid, signal.SIGKILL)
                        except (ProcessLookupError, OSError):
                            pass
                    proc.wait()
        elapsed = round(time.monotonic() - start, 1)
        output = log_path.read_text(encoding="utf-8", errors="replace").strip()
    finally:
        if log_path is not None:
            try:
                log_path.unlink(missing_ok=True)
            except OSError:
                pass

    lines = output.splitlines()
    tail = "\n".join(lines[-20:]) if lines else ""
    if timed_out:
        status = "error"
        output_tail = f"timed out after 600s\n{tail}"
        all_passed = False
    else:
        status = "passed" if proc.returncode == 0 else "failed"
        output_tail = tail
        all_passed = proc.returncode == 0

    return {
        "summary": {
            "total": 1,
            "passed": 1 if all_passed else 0,
            "failed": 0 if all_passed or status == "error" else 1,
            "errors": 1 if status == "error" else 0,
            "skipped": 0,
            "all_passed": all_passed,
        },
        "failed_suites": [] if all_passed else [cmd],
        "skipped_suites": [],
        "details": [{"suite": cmd, "status": status,
                     "elapsed_s": elapsed, "output_tail": output_tail}],
    }


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
        try:
            result = subprocess.run(
                [command, *probe_args],
                cwd=workspace,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
                timeout=10,
            )
            if result.returncode != 0:
                return f"{label} non-functional"
        except subprocess.TimeoutExpired:
            return f"{label} probe timed out"
    return None


SUITE_TIMEOUT_S: int = 120
_PARALLEL_MAX_WORKERS: int = 6


def _run_single_suite(suite_path: str, workspace: Path, env: Optional[dict] = None) -> dict:
    """Run one bash suite; return {suite, status, elapsed_s, output_tail}.

    Uses a temp file + start_new_session=True + pgid kill on timeout — the same
    pattern as _run_full_via_harness — so that grandchild processes cannot hold a
    pipe open past the deadline.
    """
    start = time.monotonic()
    log_path: Optional[Path] = None
    timed_out = False
    try:
        fd, log_str = tempfile.mkstemp(suffix=".log", prefix="mcp-suite-")
        os.close(fd)
        log_path = Path(log_str)
        with log_path.open("w", encoding="utf-8", errors="replace") as log_fh:
            proc = subprocess.Popen(
                ["bash", suite_path],
                cwd=workspace,
                stdin=subprocess.DEVNULL,
                stdout=log_fh,
                stderr=subprocess.STDOUT,
                env=env,
                start_new_session=True,
            )
            try:
                proc.wait(timeout=SUITE_TIMEOUT_S)
            except subprocess.TimeoutExpired:
                timed_out = True
                pgid: Optional[int] = None
                try:
                    pgid = os.getpgid(proc.pid)
                except OSError:
                    pass
                if pgid is not None:
                    try:
                        os.killpg(pgid, signal.SIGTERM)
                    except (ProcessLookupError, OSError):
                        pass
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    if pgid is not None:
                        try:
                            os.killpg(pgid, signal.SIGKILL)
                        except (ProcessLookupError, OSError):
                            pass
                    proc.wait()
        elapsed = round(time.monotonic() - start, 1)
        output = log_path.read_text(encoding="utf-8", errors="replace").strip()
    finally:
        if log_path is not None:
            try:
                log_path.unlink(missing_ok=True)
            except OSError:
                pass
    if timed_out:
        return {
            "suite": suite_path,
            "status": "error",
            "elapsed_s": elapsed,
            "output_tail": f"timed out after {SUITE_TIMEOUT_S}s",
        }
    lines = output.splitlines()
    status = "passed" if proc.returncode == 0 else "failed"
    # More context for failures; minimal for passes.
    tail_n = 15 if status == "failed" else 5
    tail = "\n".join(lines[-tail_n:]) if lines else ""
    return {"suite": suite_path, "status": status, "elapsed_s": elapsed, "output_tail": tail}


def _run_full_via_harness(workspace: Path, env: dict) -> dict:
    """Run the full suite by reading the manifest and running all eligible
    suites in parallel — same code path as targeted mode, no external
    bash/python3 subprocess chain required.
    """
    manifest = _load_suite_manifest(workspace)
    phases: list[dict] = manifest.get("phases", [])
    suites: list[dict] = manifest.get("suites", [])
    phases_by_id = {str(p["id"]): p for p in phases}

    to_run: list[str] = []
    skipped: list[str] = []
    for suite in suites:
        rel = str(suite["path"])
        phase = phases_by_id.get(str(suite["phase"]), {})
        skip_reason = _phase_skip_reason(phase, workspace)
        if skip_reason is not None:
            skipped.append(f"{rel}: {skip_reason}")
        else:
            to_run.append(rel)

    details: list[dict] = []
    if to_run:
        workers = min(len(to_run), _PARALLEL_MAX_WORKERS)
        with ThreadPoolExecutor(max_workers=workers) as pool:
            futures = {
                pool.submit(_run_single_suite, path, workspace, env): path
                for path in to_run
            }
            for fut in as_completed(futures):
                path = futures[fut]
                try:
                    details.append(fut.result())
                except Exception as exc:  # noqa: BLE001
                    details.append({"suite": path, "status": "error",
                                    "elapsed_s": 0,
                                    "output_tail": f"unexpected error: {exc}"})

    passed = sum(1 for d in details if d["status"] == "passed")
    failed_list = [d["suite"] for d in details if d["status"] == "failed"]
    errors = [d["suite"] for d in details if d["status"] == "error"]
    total = len(details)
    all_passed = total > 0 and passed == total

    return {
        "summary": {
            "total": total,
            "passed": passed,
            "failed": len(failed_list),
            "errors": len(errors),
            "skipped": len(skipped),
            "all_passed": all_passed,
        },
        "failed_suites": failed_list,
        "skipped_suites": skipped,
        "details": [d for d in details if d["status"] != "passed"],
    }


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

    # Create a shared PWSH_CACHE_FILE so all suite subprocesses share the
    # PowerShell binary probe result, matching the behaviour of tests/run-all.sh.
    pwsh_cache = tempfile.NamedTemporaryFile(delete=False)
    pwsh_cache.close()
    env = {**os.environ, "PWSH_CACHE_FILE": pwsh_cache.name}
    try:
        return _run_tests_impl(workspace, files, mode, env)
    finally:
        try:
            Path(pwsh_cache.name).unlink(missing_ok=True)
        except OSError:
            pass


def _run_tests_impl(
    workspace: Path,
    files: Optional[list[str]],
    mode: str,
    env: dict,
) -> dict:
    # Repos without the suite-manifest harness fall back to stack detection.
    try:
        manifest = _load_suite_manifest(workspace)
    except FileNotFoundError:
        cmd = _detect_test_command(workspace)
        if cmd is None:
            return {
                "summary": {"total": 0, "passed": 0, "failed": 0, "errors": 1,
                            "skipped": 0, "all_passed": False},
                "failed_suites": [],
                "skipped_suites": [],
                "details": [{"suite": "auto-detect", "status": "error",
                             "elapsed_s": 0,
                             "output_tail": "no suite manifest and no recognised "
                                            "test stack found in workspace"}],
            }
        try:
            return _run_generic_command(cmd, workspace, env)
        except Exception as exc:  # noqa: BLE001
            return {
                "summary": {"total": 0, "passed": 0, "failed": 0, "errors": 1,
                            "skipped": 0, "all_passed": False},
                "failed_suites": [],
                "skipped_suites": [],
                "details": [{"suite": cmd, "status": "error", "elapsed_s": 0,
                             "output_tail": f"failed to launch test command: {exc}"}],
            }
    except json.JSONDecodeError as exc:
        return {
            "summary": {"total": 0, "passed": 0, "failed": 0, "errors": 1,
                        "skipped": 0, "all_passed": False},
            "failed_suites": [],
            "skipped_suites": [],
            "details": [{"suite": "suite-manifest", "status": "error",
                         "elapsed_s": 0,
                         "output_tail": f"corrupt suite manifest: {exc}"}],
        }

    phases: list[dict] = manifest.get("phases", [])
    suites: list[dict] = manifest.get("suites", [])

    phases_by_id = {str(p["id"]): p for p in phases}
    suite_by_path = {str(s["path"]): s for s in suites}

    details: list[dict] = []
    skipped: list[str] = []

    if mode == "full" or not files:
        # Full run: use the manifest-parallel path.
        return _run_full_via_harness(workspace, env)

    # Targeted run: validate paths, check phase requirements, then run in
    # parallel (suites are independent bash processes).
    to_run: list[str] = []
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
        to_run.append(rel)

    if to_run:
        workers = min(len(to_run), _PARALLEL_MAX_WORKERS)
        with ThreadPoolExecutor(max_workers=workers) as pool:
            futures = {
                pool.submit(_run_single_suite, path, workspace, env): path
                for path in to_run
            }
            for fut in as_completed(futures):
                path = futures[fut]
                try:
                    details.append(fut.result())
                except Exception as exc:  # noqa: BLE001
                    details.append({"suite": path, "status": "error",
                                    "elapsed_s": 0,
                                    "output_tail": f"unexpected error: {exc}"})

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


# ---------------------------------------------------------------------------
# Tool: suggest_delegation
# ---------------------------------------------------------------------------

_ROUTING_MANIFEST_PATH = ROOT / "agents" / "routing-manifest.json"


@mcp.tool()
def suggest_delegation(
    task: str,
    calling_agent: str = "",
) -> dict:
    """Match a task description against the agent routing manifest.

    Call this before starting any non-trivial task. If a specialist agent
    matches, delegate to it instead of handling the work inline.

    Args:
        task:          One-sentence description of the work to be done.
        calling_agent: Name of the calling agent (e.g. "Code"), used to
                       avoid self-routing in sub-agent delegation.
    """
    if not task or not task.strip():
        return {"match": False, "recommendation": "No specialist match — handle inline.", "error": "task description is required"}

    task_lower = task.lower()

    try:
        manifest = json.loads(_ROUTING_MANIFEST_PATH.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        return {"match": False, "recommendation": "No specialist match — handle inline.", "error": f"could not load routing manifest: {exc}"}

    agents = manifest.get("agents", [])
    matches: list[dict] = []

    for agent in agents:
        name = agent.get("name", "")
        # Skip if this is the calling agent (avoid self-routing).
        if calling_agent and name.lower() == calling_agent.lower():
            continue
        # Skip inactive routes only (active and guarded are both eligible).
        route = agent.get("route", "active")
        if route not in ("active", "guarded"):
            continue

        prompt_patterns: list[str] = agent.get("prompt_patterns", [])
        suppress_patterns: list[str] = agent.get("suppress_patterns", [])

        # Check if any suppress pattern fires — if so, skip.
        try:
            suppressed = any(
                re.search(p, task_lower, re.IGNORECASE) for p in suppress_patterns
            )
        except re.error:
            suppressed = False
        if suppressed:
            continue

        # Count how many prompt_patterns match (for ranking).
        try:
            hit_count = sum(
                1 for p in prompt_patterns
                if re.search(p, task_lower, re.IGNORECASE)
            )
        except re.error:
            hit_count = 0
        if hit_count > 0:
            matches.append({
                "name": name,
                "summary": agent.get("summary", ""),
                "hint": agent.get("hint", ""),
                "hit_count": hit_count,
                "route": route,
                "visibility": agent.get("visibility", ""),
            })

    if not matches:
        return {
            "match": False,
            "recommendation": "No specialist match — handle inline.",
        }

    # Sort by hit count descending; break ties by manifest order (stable sort).
    matches.sort(key=lambda m: m["hit_count"], reverse=True)
    top = matches[0]

    return {
        "match": True,
        "agent": top["name"],
        "route": top["route"],
        "summary": top["summary"],
        "hint": top["hint"],
        "delegate_instruction": (
            f"Delegate to the {top['name']} agent. "
            f"Do not absorb this workflow inline. "
            f"Pass a one-sentence objective, scope, and acceptance criteria."
        ),
        "other_candidates": [
            {"agent": m["name"], "summary": m["summary"]}
            for m in matches[1:3]
        ],
    }


# ---------------------------------------------------------------------------
# Tool: run_check
# ---------------------------------------------------------------------------

# Maximum characters returned from run_check stdout/stderr.
_MAX_OUTPUT_CHARS: int = 8000

# Allow-list of safe commands (linters, formatters, read-only git).
_SAFE_CMDS: frozenset[str] = frozenset({
    "shellcheck", "markdownlint", "markdownlint-cli2", "jq", "yamllint",
})
_SAFE_GIT_SUBCMDS: frozenset[str] = frozenset({
    "diff", "diff-index", "log", "show", "status", "branch",
    "ls-files", "rev-parse", "describe",
})


@mcp.tool()
def run_check(
    command: str,
    args: Optional[list[str]] = None,
    cwd: str = "",
) -> dict:
    """Run a safe lint/check command and return structured output.

    Only commands in the pre-approved allow-list are permitted:
    shellcheck, markdownlint, markdownlint-cli2, jq, yamllint, and
    read-only git subcommands (diff, log, show, status, branch, ls-files,
    rev-parse, describe).

    Args:
        command: Command to run (must be in allow-list).
        args:    Arguments to pass to the command.
        cwd:     Working directory (defaults to repo root).
    """
    args = list(args or [])
    if command == "git":
        sub = args[0] if args else ""
        if sub not in _SAFE_GIT_SUBCMDS:
            return {"error": f"git subcommand not in allow-list: {sub!r}"}
    elif command not in _SAFE_CMDS:
        return {"error": f"command not in allow-list: {command!r}"}
    if not _command_available(command):
        return {"error": f"command not found: {command}"}
    work_dir = Path(cwd).resolve() if cwd else ROOT
    if not work_dir.is_relative_to(ROOT):
        return {"error": f"cwd must be within the repo root: {cwd!r}"}
    result = subprocess.run(
        [command, *args],
        cwd=work_dir,
        capture_output=True,
        text=True,
        check=False,
        timeout=60,
    )
    stdout = result.stdout.strip()
    stderr = result.stderr.strip()
    truncated = len(stdout) > _MAX_OUTPUT_CHARS or len(stderr) > _MAX_OUTPUT_CHARS
    return {
        "ok": result.returncode == 0,
        "exit_code": result.returncode,
        "stdout": stdout[:_MAX_OUTPUT_CHARS],
        "stderr": stderr[:_MAX_OUTPUT_CHARS],
        "truncated": truncated,
    }


# ---------------------------------------------------------------------------
# Tool: run_grep
# ---------------------------------------------------------------------------


@mcp.tool()
def run_grep(
    pattern: str,
    path: str = ".",
    is_regex: bool = False,
    include_glob: str = "",
    max_results: int = 50,
) -> dict:
    """Search for text or a regex pattern in repo files using ripgrep.

    Returns structured match results with file path, line number, and
    matched content. Faster than semantic search for exact-text or
    regex queries and requires no index build.

    Args:
        pattern:      Text or regex pattern to search for.
        path:         Repo-relative path to search in (default: repo root).
        is_regex:     Treat pattern as a regular expression (default: false).
        include_glob: Limit search to files matching this glob (e.g. "*.md").
        max_results:  Maximum number of matches to return (default: 50).
    """
    if not pattern:
        return {"error": "pattern is required"}
    max_results = max(1, min(max_results, 500))
    if not _command_available("rg"):
        return {"error": "ripgrep (rg) not available; install via package manager"}
    search_root = (ROOT / path).resolve()
    if not search_root.is_relative_to(ROOT):
        return {"error": f"path must be within the repo root: {path!r}"}
    cmd: list[str] = ["rg", "--json"]
    if not is_regex:
        cmd.append("--fixed-strings")
    if include_glob:
        cmd += ["--glob", include_glob]
    cmd += [pattern, str(search_root)]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=False, timeout=30)
    except subprocess.TimeoutExpired:
        return {"error": "ripgrep timed out after 30s", "pattern": pattern, "matches": []}
    matches: list[dict] = []
    for line in result.stdout.splitlines():
        if len(matches) >= max_results:
            break
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if obj.get("type") != "match":
            continue
        data = obj["data"]
        matches.append({
            "file": data["path"]["text"],
            "line": data["line_number"],
            "content": data["lines"]["text"].rstrip(),
        })

    return {
        "pattern": pattern,
        "matches": matches,
        "total_matches": len(matches),
        "truncated": len(matches) == max_results,
    }


if __name__ == "__main__":
    mcp.run()
