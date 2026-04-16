#!/usr/bin/env python3
"""Shared filesystem and artifact utilities for the heartbeat pulse subsystem.

Provides path fallback resolution, file locking, atomic writes, and time
formatting used by pulse_state, heartbeat_clock_summary, and other pulse
modules.
"""
from __future__ import annotations

import hashlib
import os
import pwd
import tempfile
import time
from contextlib import contextmanager
from pathlib import Path

try:
    import fcntl
except ImportError:  # pragma: no cover - Windows does not provide fcntl.
    fcntl = None


def iso_utc(epoch: int) -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(epoch))


def lock_path(path: Path) -> Path:
    return path.parent / f"{path.name}.lock"


@contextmanager
def file_lock(path: Path):
    if fcntl is None:
        yield
        return
    target = lock_path(path)
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


def atomic_write(path: Path, text: str) -> None:
    last_error = None
    with file_lock(path):
        for _attempt in range(2):
            path.parent.mkdir(parents=True, exist_ok=True)
            file_descriptor, tmp_name = tempfile.mkstemp(
                prefix=f".{path.name}.",
                suffix=".tmp",
                dir=path.parent,
            )
            tmp_path = Path(tmp_name)
            try:
                with os.fdopen(file_descriptor, "w", encoding="utf-8") as handle:
                    handle.write(text)
                os.replace(tmp_path, path)
                return
            except FileNotFoundError as exc:
                last_error = exc
                tmp_path.unlink(missing_ok=True)
            except Exception:
                tmp_path.unlink(missing_ok=True)
                raise
    if last_error is not None:
        raise last_error


def fallback_artifact_roots() -> list[Path]:
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
        add(passwd_home / ".cache" / "uv" / ".copilot-tmp")
        add(passwd_home / ".cache" / "uv")
        add(passwd_home / ".local" / "share" / "uv")
    home = Path.home()
    add(home / ".cache" / "uv" / ".copilot-tmp")
    add(home / ".cache" / "uv")
    add(home / ".local" / "share" / "uv")
    return roots


def _copilot_repo_root(workspace_resolved: Path) -> Path:
    """Return the repo root (= parent of the .copilot directory) from a resolved path."""
    if workspace_resolved.name == ".copilot":
        return workspace_resolved.parent
    for candidate in workspace_resolved.parents:
        if candidate.name == ".copilot":
            return candidate.parent
    # Fallback: handle direct .copilot/workspace/ children
    if workspace_resolved.name == "workspace" and workspace_resolved.parent.name == ".copilot":
        return workspace_resolved.parent.parent
    return workspace_resolved.parent


def fallback_artifact_path(path: Path) -> Path:
    workspace = path.parent
    try:
        workspace_resolved = workspace.resolve()
    except Exception:
        workspace_resolved = workspace
    root = _copilot_repo_root(workspace_resolved)
    roots = fallback_artifact_roots()
    tmp_root = roots[0] if roots else Path(tempfile.gettempdir())
    repo_key = hashlib.sha256(str(root).encode("utf-8")).hexdigest()[:12]
    return tmp_root / "copilot-heartbeat" / repo_key / path.name


def fallback_artifact_paths(path: Path) -> list[Path]:
    workspace = path.parent
    try:
        workspace_resolved = workspace.resolve()
    except Exception:
        workspace_resolved = workspace
    root = _copilot_repo_root(workspace_resolved)
    repo_key = hashlib.sha256(str(root).encode("utf-8")).hexdigest()[:12]
    return [root_path / "copilot-heartbeat" / repo_key / path.name for root_path in fallback_artifact_roots()]


def heartbeat_artifact_paths(path: Path) -> list[Path]:
    candidates = [path]
    for fallback in fallback_artifact_paths(path):
        if fallback != path and fallback not in candidates:
            candidates.append(fallback)
    return candidates
