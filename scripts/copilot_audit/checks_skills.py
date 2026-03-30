"""Skill checks (S1–S2) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib

from .models import Finding, CheckResult, HIGH, WARN, INFO
from .helpers import parse_frontmatter, skill_dirs


def check_s1_skill_name_matches_dir(root: pathlib.Path) -> CheckResult:
    """S1 — SKILL.md: name in frontmatter must match parent directory name."""
    result = CheckResult("S1", "Skill name matches directory")
    dirs = skill_dirs(root)
    found = False
    for d in dirs:
        if not d.is_dir():
            continue
        for skill_file in sorted(d.rglob("SKILL.md")):
            found = True
            rel = str(skill_file.relative_to(root))
            dir_name = skill_file.parent.name
            text = skill_file.read_text(encoding="utf-8", errors="replace")
            fm = parse_frontmatter(text)
            name = fm.get("name", "")
            if not isinstance(name, str) or not name:
                result.findings.append(Finding("S1", rel, HIGH,
                                               "Missing 'name' field in frontmatter"))
            elif name != dir_name:
                result.findings.append(Finding("S1", rel, HIGH,
                                               f"name '{name}' does not match "
                                               f"directory '{dir_name}' (agentskills spec)"))
    if not found:
        result.findings.append(Finding("S1", ".github/skills/", INFO,
                                       "No SKILL.md files found"))
    return result


def check_s2_skill_size(root: pathlib.Path) -> CheckResult:
    """S2 — SKILL.md: body ≤ 500 lines; description ≤ 1024 chars."""
    result = CheckResult("S2", "Skill size constraints")
    dirs = skill_dirs(root)
    for d in dirs:
        if not d.is_dir():
            continue
        for skill_file in sorted(d.rglob("SKILL.md")):
            rel = str(skill_file.relative_to(root))
            text = skill_file.read_text(encoding="utf-8", errors="replace")
            lines = text.count("\n")
            if lines > 500:
                result.findings.append(Finding("S2", rel, WARN,
                                               f"File is {lines} lines (recommended ≤ 500)"))
            fm = parse_frontmatter(text)
            desc = fm.get("description", "")
            if isinstance(desc, str) and len(desc) > 1024:
                result.findings.append(Finding("S2", rel, HIGH,
                                               f"description is {len(desc)} chars "
                                               "(agentskills limit: 1024)"))
    return result
