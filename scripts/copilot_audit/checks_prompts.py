"""Prompt checks (P1) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib

from .models import Finding, CheckResult, HIGH, WARN, INFO
from .helpers import parse_frontmatter, prompt_dirs


def check_p1_prompt_mode(root: pathlib.Path) -> CheckResult:
    """P1 — .prompt.md files: frontmatter matches VS Code prompt schema.

    Contract in this repo:
    - `description:` and `agent:` are required.
    - `mode:` is deprecated and must not appear.
    """
    result = CheckResult("P1", "Prompt file frontmatter")
    dirs = prompt_dirs(root)
    found = False
    for d in dirs:
        for pfile in sorted(d.glob("*.prompt.md")) if d.is_dir() else []:
            found = True
            rel = str(pfile.relative_to(root))
            text = pfile.read_text(encoding="utf-8", errors="replace")
            if not text.startswith("---"):
                result.findings.append(Finding("P1", rel, WARN,
                                               "No YAML frontmatter block"))
                continue
            fm = parse_frontmatter(text)
            desc = fm.get("description", "")
            agent = fm.get("agent", "")
            if not isinstance(desc, str) or not desc:
                result.findings.append(Finding("P1", rel, HIGH,
                                               "Missing 'description' field in frontmatter"))
            if not isinstance(agent, str) or not agent:
                result.findings.append(Finding("P1", rel, HIGH,
                                               "Missing 'agent' field in frontmatter"))
            if "mode" in fm and fm.get("mode"):
                result.findings.append(Finding("P1", rel, HIGH,
                                               "Deprecated 'mode' field present — use 'agent' instead"))
    if not found:
        result.findings.append(Finding("P1", ".github/prompts/", INFO,
                                       "No .prompt.md files found"))
    return result
