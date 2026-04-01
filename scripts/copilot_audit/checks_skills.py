"""Skill checks (S1–S2) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib

from .context import AuditContext, ensure_context
from .models import Finding, CheckResult, HIGH, WARN, INFO


def check_s1_skill_name_matches_dir(root: pathlib.Path | AuditContext) -> CheckResult:
    """S1 — SKILL.md: name in frontmatter must match parent directory name."""
    ctx = ensure_context(root)
    result = CheckResult("S1", "Skill name matches directory")
    if not ctx.skill_files:
        result.findings.append(Finding("S1", ".github/skills/", INFO,
                                       "No SKILL.md files found"))
        return result
    for skill_file in ctx.skill_files:
        rel = ctx.rel(skill_file)
        dir_name = skill_file.parent.name
        fm = ctx.load_frontmatter(skill_file)
        name = fm.get("name", "")
        if not isinstance(name, str) or not name:
            result.findings.append(Finding("S1", rel, HIGH,
                                           "Missing 'name' field in frontmatter"))
        elif name != dir_name:
            result.findings.append(Finding("S1", rel, HIGH,
                                           f"name '{name}' does not match "
                                           f"directory '{dir_name}' (agentskills spec)"))
    return result


def check_s2_skill_size(root: pathlib.Path | AuditContext) -> CheckResult:
    """S2 — SKILL.md: body ≤ 500 lines; description ≤ 1024 chars."""
    ctx = ensure_context(root)
    result = CheckResult("S2", "Skill size constraints")
    for skill_file in ctx.skill_files:
        rel = ctx.rel(skill_file)
        text = ctx.read_text(skill_file)
        lines = text.count("\n")
        if lines > 500:
            result.findings.append(Finding("S2", rel, WARN,
                                           f"File is {lines} lines (recommended ≤ 500)"))
        fm = ctx.load_frontmatter(skill_file)
        desc = fm.get("description", "")
        if isinstance(desc, str) and len(desc) > 1024:
            result.findings.append(Finding("S2", rel, HIGH,
                                           f"description is {len(desc)} chars "
                                           "(agentskills limit: 1024)"))
    return result
