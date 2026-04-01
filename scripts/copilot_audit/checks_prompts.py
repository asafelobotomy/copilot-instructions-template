"""Prompt checks (P1) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib

from .context import AuditContext, ensure_context
from .models import Finding, CheckResult, HIGH, WARN, INFO


def check_p1_prompt_mode(root: pathlib.Path | AuditContext) -> CheckResult:
    """P1 — .prompt.md files: frontmatter matches VS Code prompt schema.

    Contract in this repo:
    - `description:` and `agent:` are required.
    - `mode:` is deprecated and must not appear.
    """
    ctx = ensure_context(root)
    result = CheckResult("P1", "Prompt file frontmatter")
    if not ctx.prompt_files:
        result.findings.append(Finding("P1", ".github/prompts/", INFO,
                                       "No .prompt.md files found"))
        return result
    for pfile in ctx.prompt_files:
        rel = ctx.rel(pfile)
        text = ctx.read_text(pfile)
        if not text.startswith("---"):
            result.findings.append(Finding("P1", rel, WARN,
                                           "No YAML frontmatter block"))
            continue
        fm = ctx.load_frontmatter(pfile)
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
    return result
