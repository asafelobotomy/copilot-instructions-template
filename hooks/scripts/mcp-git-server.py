#!/usr/bin/env python3
"""Local git MCP server — safe replacement for upstream mcp-server-git.

Fixes over upstream:
  - git_show: decode with errors='replace' (no crash on binary/non-UTF-8 diffs)
  - git_log: timestamps validated; max_count enforced at git level
  - git_branch: contains/not_contains validated before passing to git
  - git_create_branch: branch_name and base_branch validated against flag injection
  - git_commit: message bounded and non-empty enforced
  - All outputs capped at _MAX_OUTPUT_CHARS
"""
from __future__ import annotations

import logging
import os
import re
from pathlib import Path
from typing import Literal, Optional

import git
from mcp.server.fastmcp import FastMCP

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

_DEFAULT_REPO: Path = Path(
    os.environ.get("GIT_MCP_REPOSITORY", str(Path(__file__).resolve().parent.parent.parent))
).resolve()

_MAX_OUTPUT_CHARS: int = 32_768
_MAX_COMMIT_MSG: int = 4_096
_MAX_COUNT_CAP: int = 1_000

_SAFE_REF_RE = re.compile(r"[a-zA-Z0-9/_.@\-]+")
_SAFE_DATE_RE = re.compile(r"[a-zA-Z0-9:.+/ \-]+")

logging.basicConfig(level=logging.WARNING)
mcp = FastMCP("GitMCP")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _repo(repo_path: str) -> git.Repo:
    """Open repo, rejecting paths outside _DEFAULT_REPO.

    Also validates that the repository's git_dir, common_dir, and
    working_tree_dir all resolve under _DEFAULT_REPO so that .git file
    indirection or linked worktrees cannot escape the allowed root.
    """
    p = Path(repo_path).resolve()
    try:
        p.relative_to(_DEFAULT_REPO)
    except ValueError:
        raise ValueError(
            f"repo_path '{repo_path}' is outside allowed repository '{_DEFAULT_REPO}'"
        )
    repo = git.Repo(p)
    for _attr in ("git_dir", "common_dir", "working_tree_dir"):
        _dir = getattr(repo, _attr, None)
        if _dir is None:
            continue
        try:
            Path(_dir).resolve().relative_to(_DEFAULT_REPO)
        except ValueError:
            raise ValueError(
                f"repo {_attr} is outside allowed root: {_dir!r}"
            )
    return repo


def _safe_ref(value: str, label: str) -> str:
    """Reject ref values that look like flags or contain unsafe characters."""
    if value.startswith("-"):
        raise ValueError(f"{label} must not start with '-'")
    if not _SAFE_REF_RE.fullmatch(value):
        raise ValueError(f"{label} contains invalid characters: {value!r}")
    return value


def _safe_date(value: str, label: str) -> str:
    """Reject timestamp strings that could be interpreted as git flags."""
    if value.startswith("-"):
        raise ValueError(f"{label} must not start with '-'")
    if not _SAFE_DATE_RE.fullmatch(value):
        raise ValueError(f"{label} contains invalid characters: {value!r}")
    return value


def _cap(text: str) -> str:
    if len(text) > _MAX_OUTPUT_CHARS:
        return text[:_MAX_OUTPUT_CHARS] + f"\n[output truncated at {_MAX_OUTPUT_CHARS} chars]"
    return text


# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------

@mcp.tool()
def git_status(repo_path: str) -> str:
    """Show the working tree status."""
    return _cap(_repo(repo_path).git.status())


@mcp.tool()
def git_diff_unstaged(repo_path: str, context_lines: int = 3) -> str:
    """Show unstaged changes in the working tree."""
    if not 0 <= context_lines <= 100:
        raise ValueError("context_lines must be 0-100")
    return _cap(_repo(repo_path).git.diff(f"--unified={context_lines}"))


@mcp.tool()
def git_diff_staged(repo_path: str, context_lines: int = 3) -> str:
    """Show staged changes (index vs HEAD)."""
    if not 0 <= context_lines <= 100:
        raise ValueError("context_lines must be 0-100")
    return _cap(_repo(repo_path).git.diff("--cached", f"--unified={context_lines}"))


@mcp.tool()
def git_diff(repo_path: str, target: str, context_lines: int = 3) -> str:
    """Show changes between HEAD and a target commit or branch."""
    if not 0 <= context_lines <= 100:
        raise ValueError("context_lines must be 0-100")
    _safe_ref(target, "target")
    repo = _repo(repo_path)
    repo.rev_parse(target)
    return _cap(repo.git.diff(f"--unified={context_lines}", target))


@mcp.tool()
def git_commit(repo_path: str, message: str) -> str:
    """Record staged changes as a commit."""
    if not message.strip():
        raise ValueError("message must not be empty")
    if len(message) > _MAX_COMMIT_MSG:
        raise ValueError(f"message exceeds {_MAX_COMMIT_MSG} character limit")
    commit = _repo(repo_path).index.commit(message)
    return f"Created commit {commit.hexsha}"


@mcp.tool()
def git_add(repo_path: str, files: list[str]) -> str:
    """Stage files for the next commit."""
    if not files:
        raise ValueError("files must not be empty")
    _repo(repo_path).git.add("--", *files)
    return f"Staged {len(files)} file(s)"


@mcp.tool()
def git_reset(repo_path: str) -> str:
    """Unstage all staged changes (mixed reset to HEAD)."""
    _repo(repo_path).index.reset()
    return "Unstaged all changes"


@mcp.tool()
def git_log(
    repo_path: str,
    max_count: int = 10,
    start_timestamp: Optional[str] = None,
    end_timestamp: Optional[str] = None,
) -> str:
    """Show commit log, optionally filtered by date range."""
    if not 1 <= max_count <= _MAX_COUNT_CAP:
        raise ValueError(f"max_count must be 1-{_MAX_COUNT_CAP}")
    args = [f"--max-count={max_count}", "--format=%H%n%an%n%ae%n%ad%n%s%n"]
    if start_timestamp is not None:
        args.append(f"--since={_safe_date(start_timestamp, 'start_timestamp')}")
    if end_timestamp is not None:
        args.append(f"--until={_safe_date(end_timestamp, 'end_timestamp')}")
    return _cap(_repo(repo_path).git.log(*args))


@mcp.tool()
def git_create_branch(repo_path: str, branch_name: str, base_branch: Optional[str] = None) -> str:
    """Create a new branch, optionally from a named base branch."""
    _safe_ref(branch_name, "branch_name")
    repo = _repo(repo_path)
    if base_branch is not None:
        _safe_ref(base_branch, "base_branch")
        try:
            base = repo.commit(base_branch)
        except git.exc.BadName:
            raise ValueError(f"base_branch not found: {base_branch!r}")
    else:
        base = repo.active_branch.commit
    new_branch = repo.create_head(branch_name, base)
    return f"Created branch '{new_branch.name}'"


@mcp.tool()
def git_checkout(repo_path: str, branch_name: str) -> str:
    """Switch to an existing local branch.

    Only local branches are accepted; commit SHAs, tags, and remote refs
    are rejected to prevent accidental detached-HEAD state.
    """
    _safe_ref(branch_name, "branch_name")
    repo = _repo(repo_path)
    try:
        repo.heads[branch_name]
    except IndexError:
        raise ValueError(f"branch not found: {branch_name!r}")
    repo.git.checkout(branch_name)
    return f"Switched to '{branch_name}'"


@mcp.tool()
def git_show(repo_path: str, revision: str) -> str:
    """Show details of a commit including its diff."""
    _safe_ref(revision, "revision")
    repo = _repo(repo_path)
    commit = repo.commit(revision)
    parts = [
        f"Commit: {commit.hexsha}\n",
        f"Author: {commit.author.name} <{commit.author.email}>\n",
        f"Date:   {commit.authored_datetime}\n",
        f"\n    {commit.message.strip()}\n",
    ]
    diff = (
        commit.parents[0].diff(commit, create_patch=True)
        if commit.parents
        else commit.diff(git.NULL_TREE, create_patch=True)
    )
    for d in diff:
        parts.append(f"\n--- {d.a_path}\n+++ {d.b_path}\n")
        if d.diff is None:
            continue
        parts.append(
            d.diff.decode("utf-8", errors="replace") if isinstance(d.diff, bytes) else d.diff
        )
    return _cap("".join(parts))


@mcp.tool()
def git_branch(
    repo_path: str,
    branch_type: Literal["local", "remote", "all"] = "local",
    contains: Optional[str] = None,
    not_contains: Optional[str] = None,
) -> str:
    """List branches filtered by type and optional commit containment."""
    args: list[str] = []
    if branch_type == "remote":
        args.append("-r")
    elif branch_type == "all":
        args.append("-a")
    if contains is not None:
        args.extend(["--contains", _safe_ref(contains, "contains")])
    if not_contains is not None:
        args.extend(["--no-contains", _safe_ref(not_contains, "not_contains")])
    return _cap(_repo(repo_path).git.branch(*args))


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
