"""Agent checks (A1–A3) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib
import re

from .models import Finding, CheckResult, HIGH, WARN, INFO, CRITICAL
from .helpers import parse_frontmatter, strip_code_spans, PLACEHOLDER_RE


def check_a1_agent_frontmatter(root: pathlib.Path) -> CheckResult:
    """A1 — Agent files: frontmatter present; name, description, model fields set."""
    result = CheckResult("A1", "Agent frontmatter completeness")
    agents_dir = root / ".github" / "agents"
    if not agents_dir.is_dir():
        result.findings.append(Finding("A1", ".github/agents/", INFO,
                                       "No agents directory — skip"))
        return result
    for agent_file in sorted(agents_dir.glob("*.agent.md")):
        rel = str(agent_file.relative_to(root))
        text = agent_file.read_text(encoding="utf-8", errors="replace")
        if not text.startswith("---"):
            result.findings.append(Finding("A1", rel, HIGH,
                                           "No YAML frontmatter block found"))
            continue
        fm = parse_frontmatter(text)
        for required in ("name", "description"):
            if not fm.get(required):
                result.findings.append(Finding("A1", rel, HIGH,
                                               f"Missing required field: {required}"))
        if not fm.get("model"):
            result.findings.append(Finding("A1", rel, WARN,
                                           "Missing 'model' field — will use picker default"))
    return result


def check_a2_agent_handoffs(root: pathlib.Path) -> CheckResult:
    """A2 — Agent handoffs: every handoff agent target resolves to a known agent name."""
    result = CheckResult("A2", "Agent handoff targets")
    agents_dir = root / ".github" / "agents"
    if not agents_dir.is_dir():
        return result

    known_names: set[str] = set()
    for agent_file in agents_dir.glob("*.agent.md"):
        fm = parse_frontmatter(agent_file.read_text(encoding="utf-8", errors="replace"))
        name = fm.get("name", "")
        if isinstance(name, str) and name:
            known_names.add(name)

    for agent_file in sorted(agents_dir.glob("*.agent.md")):
        rel = str(agent_file.relative_to(root))
        text = agent_file.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r"^\s+agent:\s+(.+)$", text, re.MULTILINE):
            target = m.group(1).strip().strip('"').strip("'")
            if target and target not in known_names:
                result.findings.append(Finding("A2", rel, CRITICAL,
                                               f"Handoff targets unknown agent: '{target}'"))
    return result


def check_a3_agent_no_placeholders(root: pathlib.Path) -> CheckResult:
    """A3 — Agent files must not contain {{PLACEHOLDER}} template tokens."""
    result = CheckResult("A3", "Agent files: no placeholder tokens")
    agents_dir = root / ".github" / "agents"
    if not agents_dir.is_dir():
        return result
    for agent_file in sorted(agents_dir.glob("*.agent.md")):
        rel = str(agent_file.relative_to(root))
        text = strip_code_spans(
            agent_file.read_text(encoding="utf-8", errors="replace")
        )
        matches = PLACEHOLDER_RE.findall(text)
        if matches:
            result.findings.append(Finding("A3", rel, HIGH,
                                           f"Contains {len(matches)} placeholder token(s): "
                                           + ", ".join(matches[:3])))
    return result
