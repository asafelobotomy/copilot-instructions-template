#!/usr/bin/env python3
"""Sequential-thinking MCP server — per-session stateful thought chains.

Provides:
- `sequentialthinking`: accepts numbered thought steps, maintains a validated
  thought history and branch map, enforces input bounds, and returns structured
  progress metadata.
- `reset_thinking_session`: clears all thought history and branches so a fresh
  reasoning chain can start without restarting the MCP process.

Improvements over the upstream @modelcontextprotocol/server-sequential-thinking:
- Bounded inputs: thought content capped at MAX_THOUGHT_CHARS (32 KB),
  history capped at MAX_HISTORY (500 entries), branch_id must be a safe
  identifier string of at most MAX_BRANCH_ID_LEN (64) characters.
- History-aware validation: revises_thought and branch_from_thought are
  checked against the actual recorded thought numbers, not just numeric bounds.
- No input mutation: effective_total is computed on a local copy; the caller's
  dict is never modified (fixes upstream implicit mutation of total_thoughts).
- Explicit reset tool: call reset_thinking_session to start a new reasoning
  chain without restarting the process.
- Per-lifecycle state: FastMCP lifespan initialises a fresh ThinkingSession on
  each MCP process start so no stale state survives process restarts.

Transport: stdio  |  Run: uvx --from "mcp[cli]" mcp run <this-file>
"""
from __future__ import annotations

import re
from contextlib import asynccontextmanager
from typing import Optional

from mcp.server.fastmcp import FastMCP

# ---------------------------------------------------------------------------
# Limits
# ---------------------------------------------------------------------------

MAX_THOUGHT_CHARS: int = 32_768  # 32 KB per thought
MAX_HISTORY: int = 500           # entries before the session must be reset
MAX_BRANCH_ID_LEN: int = 64
_BRANCH_ID_RE: re.Pattern[str] = re.compile(r"[a-zA-Z0-9_\-]+")

# ---------------------------------------------------------------------------
# Per-session state
# ---------------------------------------------------------------------------


class ThinkingSession:
    """Holds thought history and branch map for one reasoning session."""

    def __init__(self) -> None:
        self.thought_history: list[dict] = []
        self.branches: dict[str, list[dict]] = {}


_session: ThinkingSession = ThinkingSession()


@asynccontextmanager
async def _lifespan(server: FastMCP):  # noqa: ARG001
    """Initialise a fresh session on each MCP process lifecycle."""
    global _session
    _session = ThinkingSession()
    yield
    _session = ThinkingSession()


mcp = FastMCP("SequentialThinking", lifespan=_lifespan)

# ---------------------------------------------------------------------------
# Tool: reset_thinking_session
# ---------------------------------------------------------------------------


@mcp.tool()
def reset_thinking_session() -> dict:
    """Clear all thought history and branches to start a fresh reasoning chain.

    Call this at the beginning of each new reasoning problem when the MCP
    process has been running across multiple conversations, or whenever the
    previous chain's context should not influence the new one.
    """
    global _session
    _session = ThinkingSession()
    return {"status": "ok", "message": "Thought history and branches cleared."}


# ---------------------------------------------------------------------------
# Tool: sequentialthinking
# ---------------------------------------------------------------------------


@mcp.tool()
def sequentialthinking(
    thought: str,
    next_thought_needed: bool,
    thought_number: int,
    total_thoughts: int,
    is_revision: Optional[bool] = None,
    revises_thought: Optional[int] = None,
    branch_from_thought: Optional[int] = None,
    branch_id: Optional[str] = None,
    needs_more_thoughts: Optional[bool] = None,  # advisory — not acted upon
) -> dict:
    """Dynamic and reflective problem-solving through a sequence of thought steps.

    Use for: breaking down complex problems, planning with room for revision,
    analysis that might need course correction, problems where the full scope
    is unclear initially, multi-step tasks requiring context persistence, and
    situations where irrelevant information needs to be filtered out.

    Key features:
    - Adjust total_thoughts up or down as you progress.
    - Revise or question previous thoughts by setting is_revision.
    - Branch the reasoning chain by providing branch_from_thought and branch_id.
    - Add more thoughts even after reaching what seemed like the end.
    - Express uncertainty and explore alternative approaches freely.
    - Set next_thought_needed to false only when a satisfactory answer is reached.

    Guidance:
    1. Start with an initial estimate of needed thoughts; adjust freely.
    2. Revise previous thoughts when understanding changes.
    3. Use branches to explore alternatives without discarding prior work.
    4. Generate and verify a solution hypothesis before finalising.
    5. Call reset_thinking_session before starting a new unrelated problem.

    Parameters:
    - thought: current thinking step — max 32 KB.
    - next_thought_needed: true if more thinking is needed after this step.
    - thought_number: 1-based index of this thought in the chain.
    - total_thoughts: current estimate of total thoughts needed (adjustable).
    - is_revision: true if this step revises a previous thought.
    - revises_thought: 1-based index of the thought being revised.
    - branch_from_thought: 1-based index of the branching-point thought.
    - branch_id: safe identifier for this branch (alphanumeric, hyphens,
      underscores only; max 64 characters).
    - needs_more_thoughts: advisory flag only; has no functional effect.
    """
    errors: list[str] = []
    history_numbers = {e["thought_number"] for e in _session.thought_history}

    # Thought content length
    if len(thought) > MAX_THOUGHT_CHARS:
        errors.append(
            f"thought exceeds maximum length "
            f"({len(thought)} > {MAX_THOUGHT_CHARS} chars)"
        )

    # Numeric bounds
    if thought_number < 1:
        errors.append("thought_number must be >= 1")
    if total_thoughts < 1:
        errors.append("total_thoughts must be >= 1")

    # revises_thought must reference a recorded thought with a lower index
    if revises_thought is not None:
        if revises_thought < 1 or revises_thought >= thought_number:
            errors.append(
                f"revises_thought ({revises_thought}) must be >= 1 and "
                f"< thought_number ({thought_number})"
            )
        elif revises_thought not in history_numbers:
            errors.append(
                f"revises_thought ({revises_thought}) does not match any "
                "recorded thought number in the current session"
            )

    # branch_from_thought must reference a recorded thought with a lower index
    if branch_from_thought is not None:
        if branch_from_thought < 1 or branch_from_thought >= thought_number:
            errors.append(
                f"branch_from_thought ({branch_from_thought}) must be >= 1 and "
                f"< thought_number ({thought_number})"
            )
        elif branch_from_thought not in history_numbers:
            errors.append(
                f"branch_from_thought ({branch_from_thought}) does not match any "
                "recorded thought number in the current session"
            )

    # branch_id must be a safe identifier string
    if branch_id is not None:
        if len(branch_id) > MAX_BRANCH_ID_LEN:
            errors.append(
                f"branch_id exceeds maximum length "
                f"({len(branch_id)} > {MAX_BRANCH_ID_LEN} chars)"
            )
        elif not _BRANCH_ID_RE.fullmatch(branch_id):
            errors.append(
                "branch_id must contain only alphanumeric characters, "
                "hyphens, and underscores"
            )

    if errors:
        return {"error": "; ".join(errors), "status": "failed"}

    # History cap — surface a clear message rather than silently dropping data
    if len(_session.thought_history) >= MAX_HISTORY:
        return {
            "error": (
                f"thought history limit ({MAX_HISTORY}) reached; "
                "call reset_thinking_session to start a new chain"
            ),
            "status": "failed",
        }

    # Compute adjusted total without mutating the caller's arguments (#5 fix)
    effective_total = max(total_thoughts, thought_number)

    entry: dict = {
        "thought": thought,
        "thought_number": thought_number,
        "total_thoughts": effective_total,
        "next_thought_needed": next_thought_needed,
    }
    if is_revision is not None:
        entry["is_revision"] = is_revision
    if revises_thought is not None:
        entry["revises_thought"] = revises_thought
    if branch_from_thought is not None:
        entry["branch_from_thought"] = branch_from_thought
    if branch_id is not None:
        entry["branch_id"] = branch_id

    _session.thought_history.append(entry)

    if branch_from_thought is not None and branch_id is not None:
        if branch_id not in _session.branches:
            _session.branches[branch_id] = []
        _session.branches[branch_id].append(entry)

    return {
        "thought_number": thought_number,
        "total_thoughts": effective_total,
        "next_thought_needed": next_thought_needed,
        "branches": list(_session.branches.keys()),
        "thought_history_length": len(_session.thought_history),
    }


if __name__ == "__main__":
    mcp.run(transport="stdio")
