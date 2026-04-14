"""Agent checks (A1–A4) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib
import re

from .context import AuditContext, ensure_context
from .models import Finding, CheckResult, HIGH, WARN, INFO, CRITICAL
from .helpers import strip_code_spans, PLACEHOLDER_RE


AGENT_DELEGATION_POLICY: dict[str, set[str]] = {
    "audit.agent.md": {"Code", "Setup", "Researcher", "Extensions", "Organise", "Planner", "Cleaner"},
    "cleaner.agent.md": {"Code", "Audit", "Organise", "Docs", "Commit"},
    "code.agent.md": {"Review", "Audit", "Researcher", "Explore", "Commit", "Organise", "Planner", "Docs", "Debugger", "Cleaner"},
    "coding.agent.md": {"Review", "Audit", "Researcher", "Explore", "Commit", "Organise", "Planner", "Docs", "Debugger", "Cleaner"},
    "commit.agent.md": {"Code", "Review", "Audit", "Debugger", "Organise", "Cleaner"},
    "debugger.agent.md": {"Code", "Researcher", "Audit", "Planner"},
    "docs.agent.md": {"Code", "Researcher", "Review", "Explore"},
    "explore.agent.md": {"Researcher"},
    "extensions.agent.md": {"Code", "Audit", "Organise", "Researcher"},
    "fast.agent.md": {"Code", "Explore", "Commit"},
    "organise.agent.md": {"Code", "Explore", "Docs"},
    "planner.agent.md": {"Code", "Explore", "Researcher", "Debugger", "Docs"},
    "researcher.agent.md": {"Code", "Audit", "Explore", "Docs", "Planner"},
    "review.agent.md": {"Code", "Audit", "Organise", "Docs", "Debugger", "Cleaner"},
    "setup.agent.md": {"Audit", "Extensions", "Organise", "Researcher"},
}


def _parse_inline_list(frontmatter: str, field: str) -> set[str]:
    match = re.search(rf"^{field}:\s*\[(.*)\]\s*$", frontmatter, re.M)
    if not match:
        return set()
    return {
        item.strip().strip("\"").strip("'")
        for item in match.group(1).split(",")
        if item.strip()
    }


def check_a1_agent_frontmatter(root: pathlib.Path | AuditContext) -> CheckResult:
    """A1 — Agent files: frontmatter present; name, description, model fields set."""
    ctx = ensure_context(root)
    result = CheckResult("A1", "Agent frontmatter completeness")
    if not ctx.agents_dir.is_dir():
        result.findings.append(Finding("A1", ".github/agents/", INFO,
                                       "No agents directory — skip"))
        return result
    for agent_file in ctx.agent_files:
        rel = ctx.rel(agent_file)
        text = ctx.read_text(agent_file)
        if not text.startswith("---"):
            result.findings.append(Finding("A1", rel, HIGH,
                                           "No YAML frontmatter block found"))
            continue
        fm = ctx.load_frontmatter(agent_file)
        for required in ("name", "description"):
            if not fm.get(required):
                result.findings.append(Finding("A1", rel, HIGH,
                                               f"Missing required field: {required}"))
        if not fm.get("model"):
            result.findings.append(Finding("A1", rel, WARN,
                                           "Missing 'model' field — will use picker default"))
    return result


def check_a2_agent_handoffs(root: pathlib.Path | AuditContext) -> CheckResult:
    """A2 — Agent handoffs: every handoff agent target resolves to a known agent name."""
    ctx = ensure_context(root)
    result = CheckResult("A2", "Agent handoff targets")
    if not ctx.agents_dir.is_dir():
        return result

    known_names: set[str] = set()
    for agent_file in ctx.agent_files:
        fm = ctx.load_frontmatter(agent_file)
        name = fm.get("name", "")
        if isinstance(name, str) and name:
            known_names.add(name)

    for agent_file in ctx.agent_files:
        rel = ctx.rel(agent_file)
        text = ctx.read_text(agent_file)
        for m in re.finditer(r"^\s+agent:\s+(.+)$", text, re.MULTILINE):
            target = m.group(1).strip().strip('"').strip("'")
            if target and target not in known_names:
                result.findings.append(Finding("A2", rel, CRITICAL,
                                               f"Handoff targets unknown agent: '{target}'"))
    return result


def check_a3_agent_no_placeholders(root: pathlib.Path | AuditContext) -> CheckResult:
    """A3 — Agent files must not contain {{PLACEHOLDER}} template tokens."""
    ctx = ensure_context(root)
    result = CheckResult("A3", "Agent files: no placeholder tokens")
    if not ctx.agents_dir.is_dir():
        return result
    for agent_file in ctx.agent_files:
        rel = ctx.rel(agent_file)
        text = strip_code_spans(ctx.read_text(agent_file))
        matches = PLACEHOLDER_RE.findall(text)
        if matches:
            result.findings.append(Finding("A3", rel, HIGH,
                                           f"Contains {len(matches)} placeholder token(s): "
                                           + ", ".join(matches[:3])))
    return result


def check_a4_agent_delegation_matrix(root: pathlib.Path | AuditContext) -> CheckResult:
    """A4 — Agent allow-lists must match the repo delegation matrix."""
    ctx = ensure_context(root)
    result = CheckResult("A4", "Agent delegation matrix")
    if not ctx.agents_dir.is_dir():
        return result

    for agent_file in ctx.agent_files:
        expected = AGENT_DELEGATION_POLICY.get(agent_file.name)
        if expected is None:
            continue
        text = ctx.read_text(agent_file)
        if not text.startswith("---\n"):
            continue
        end = text.find("\n---\n", 4)
        if end == -1:
            continue

        rel = ctx.rel(agent_file)
        actual = _parse_inline_list(text[4:end], "agents")
        missing = sorted(expected - actual)
        extra = sorted(actual - expected)

        if missing:
            result.findings.append(Finding(
                "A4",
                rel,
                HIGH,
                "Missing required delegate(s): " + ", ".join(missing),
            ))
        if extra:
            result.findings.append(Finding(
                "A4",
                rel,
                WARN,
                "Unexpected delegate(s) outside policy: " + ", ".join(extra),
            ))

    return result
