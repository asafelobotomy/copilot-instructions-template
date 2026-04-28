"""Heartbeat MCP server — helper library.

All workspace resolution, I/O helpers, and diary utilities used by
mcp-heartbeat-server.py.  Kept in a separate module so the server entrypoint
stays within the 400-line hard budget while preserving single-file deployment
compatibility: mcp-heartbeat-server.py inserts its own directory onto sys.path
before importing this module, so no package structure is required.
"""
from __future__ import annotations

import datetime
import hashlib
import json
import os
import pwd
import subprocess
import tempfile
import time
from contextlib import contextmanager
from pathlib import Path

try:
    import fcntl
except ImportError:  # pragma: no cover — Windows does not provide fcntl.
    fcntl = None

# ---------------------------------------------------------------------------
# Workspace resolution
# ---------------------------------------------------------------------------


def _find_workspace_root() -> Path:
    """Detect the git repository root.

    Resolution order:
    1. HEARTBEAT_WORKSPACE env var (set by MCP config for deterministic launch)
    2. ``git rev-parse --show-toplevel`` from cwd
    3. Walk up cwd looking for ``.copilot/workspace``
    4. cwd fallback
    """
    explicit = os.environ.get("HEARTBEAT_WORKSPACE")
    if explicit:
        return Path(explicit)
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
    anchor = Path.cwd()
    for _ in range(8):
        if (anchor / ".copilot" / "workspace").exists():
            return anchor
        if anchor.parent == anchor:
            break
        anchor = anchor.parent
    return Path.cwd()


ROOT = _find_workspace_root()
WORKSPACE = ROOT / ".copilot" / "workspace"
STATE_PATH = WORKSPACE / "runtime/state.json"
EVENTS_PATH = WORKSPACE / "runtime/.heartbeat-events.jsonl"
SENTINEL_PATH = WORKSPACE / "runtime/.heartbeat-session"
HEARTBEAT_MD_PATH = WORKSPACE / "operations/HEARTBEAT.md"
DIARIES_DIR = WORKSPACE / "knowledge/diaries"

# ---------------------------------------------------------------------------
# Fallback artifact path helpers
# ---------------------------------------------------------------------------


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

    for env_name in ("CLAUDE_TMPDIR", "TMPDIR"):
        value = os.environ.get(env_name)
        if value:
            add(Path(value))
    try:
        add(Path(tempfile.gettempdir()))
    except OSError:
        pass
    xdg = os.environ.get("XDG_CACHE_HOME")
    if xdg:
        add(Path(xdg) / "uv")
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


def _fallback_artifact_paths(path: Path) -> list[Path]:
    repo_key = hashlib.sha256(str(ROOT).encode("utf-8")).hexdigest()[:12]
    return [
        root_path / "copilot-heartbeat" / repo_key / path.name
        for root_path in _fallback_artifact_roots()
    ]


def _artifact_candidates(path: Path) -> list[Path]:
    candidates = [path]
    for fallback in _fallback_artifact_paths(path):
        if fallback != path and fallback not in candidates:
            candidates.append(fallback)
    return candidates


# ---------------------------------------------------------------------------
# File locking
# ---------------------------------------------------------------------------


def _lock_path(path: Path) -> Path:
    return path.parent / f"{path.name}.lock"


@contextmanager
def _file_lock(path: Path):
    if fcntl is None:
        yield
        return
    target = _lock_path(path)
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("a+", encoding="utf-8") as handle:
            fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
            try:
                yield
            finally:
                fcntl.flock(handle.fileno(), fcntl.LOCK_UN)
    except OSError:
        yield


# ---------------------------------------------------------------------------
# Writable temp directory setup (call before importing FastMCP)
# ---------------------------------------------------------------------------


def ensure_writable_tempdir() -> None:
    """Force a writable temp root before importing FastMCP dependencies."""
    candidates: list[Path] = []
    for env_name in ("TMPDIR", "TEMP", "TMP"):
        value = os.environ.get(env_name)
        if value:
            candidates.append(Path(value).expanduser())
    candidates.extend(
        [
            WORKSPACE / ".tmp",
            ROOT / ".copilot" / ".tmp",
            ROOT / ".git" / "copilot-tmp",
            ROOT / ".tmp",
            Path.cwd() / ".tmp",
        ]
    )
    for candidate in candidates:
        try:
            candidate.mkdir(parents=True, exist_ok=True)
            fd, test_path = tempfile.mkstemp(dir=str(candidate), prefix="._test_")
            os.close(fd)
            os.unlink(test_path)
        except OSError:
            continue
        tempfile.tempdir = str(candidate)
        return


# ---------------------------------------------------------------------------
# State and event helpers
# ---------------------------------------------------------------------------


def load_state() -> dict:
    with _file_lock(STATE_PATH):
        if not STATE_PATH.exists():
            return {}
        try:
            data = json.loads(STATE_PATH.read_text(encoding="utf-8"))
            return data if isinstance(data, dict) else {}
        except Exception:
            return {}


def git_modified_count() -> int:
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


def recent_events(limit: int = 20) -> list[dict]:
    events: list[dict] = []
    for candidate in _artifact_candidates(EVENTS_PATH):
        with _file_lock(candidate):
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


def append_event(trigger: str, detail: str = "", session_id: str = "", duration_s: int | None = None) -> None:
    if not WORKSPACE.exists():
        return
    event: dict = {
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
            with _file_lock(candidate):
                with candidate.open("a", encoding="utf-8") as handle:
                    handle.write(payload)
            return
        except OSError as exc:
            last_error = exc
            continue
    if last_error is not None:
        raise last_error


def session_events(state: dict, limit: int = 50) -> list[dict]:
    session_id = str(state.get("session_id") or "")
    session_start = int(state.get("session_start_epoch") or 0)
    scoped: list[dict] = []
    for event in recent_events(limit):
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


def set_sentinel_complete(session_id: str) -> None:
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
            with _file_lock(candidate):
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


# ---------------------------------------------------------------------------
# Workspace cues and diary helpers
# ---------------------------------------------------------------------------


def load_workspace_cues() -> dict:
    """Read lightweight cues from SOUL.md and USER.md for personalised prompts."""
    cues: dict = {"soul_values": [], "user_attributes": []}
    soul_path = WORKSPACE / "identity/SOUL.md"
    if soul_path.exists():
        try:
            in_values = False
            for line in soul_path.read_text(encoding="utf-8").splitlines():
                stripped = line.strip()
                if stripped.startswith("## "):
                    if in_values:
                        break
                    continue
                if stripped.startswith("- **") and "**" in stripped[4:]:
                    in_values = True
                    key = stripped[4:stripped.index("**", 4)]
                    cues["soul_values"].append(key)
                    if len(cues["soul_values"]) >= 5:
                        break
        except Exception:
            pass
    user_path = WORKSPACE / "knowledge/USER.md"
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


def read_diary_summaries(max_entries: int = 3) -> dict[str, list[str]]:
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
