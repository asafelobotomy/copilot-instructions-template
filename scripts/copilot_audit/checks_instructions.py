"""Instruction checks (I1–I4) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib

from .context import AuditContext, ensure_context
from .models import Finding, CheckResult, HIGH, WARN, INFO, CRITICAL
from .helpers import estimate_tokens, strip_code_spans, PLACEHOLDER_RE


DELEGATION_POLICY_SNIPPETS: dict[str, tuple[str, ...]] = {
    ".github/copilot-instructions.md": (
        "Main/default agent delegation:",
        "delegate instead of absorbing",
        "Preferred specialist map:",
        "`Explore` for read-only repo scans",
        "`Researcher` for current external docs",
        "`Review` for formal code review or architectural critique",
        "`Audit` for health, security, or residual-risk checks",
        "`Extensions` for VS Code extension, profile, or workspace recommendation",
        "`Commit` for staging, commits, pushes, tags, or releases",
        "`Setup` for template bootstrap, instruction update, or backup restore",
        "`Organise` for file moves, path repair, or repository reshaping",
    ),
    "template/copilot-instructions.md": (
        "The parent/default agent follows this protocol too:",
        "delegate to the matching agent instead of absorbing",
        "Preferred specialist map:",
        "`Explore` for read-only repo scans",
        "`Researcher` for current external docs",
        "`Review` for formal code review or architectural critique",
        "`Audit` for health, security, or residual-risk checks",
        "`Extensions` for VS Code extension, profile, or workspace recommendation",
        "`Commit` for staging, commits, pushes, tags, or releases",
        "`Setup` for template bootstrap, instruction update, or backup restore",
        "`Organise` for file moves, path repair, or repository reshaping",
    ),
}


def check_i1_instructions_placeholders(root: pathlib.Path | AuditContext) -> CheckResult:
    """I1 — copilot-instructions.md placeholder separation."""
    ctx = ensure_context(root)
    result = CheckResult("I1", "Instructions placeholder separation")
    dev_file = ctx.root / ".github" / "copilot-instructions.md"
    consumer_file = ctx.root / "template" / "copilot-instructions.md"

    for path, must_be_zero in ((dev_file, True), (consumer_file, False)):
        if not path.exists():
            result.findings.append(Finding("I1", ctx.rel(path),
                                           INFO, "File not found — skip"))
            continue
        rel = ctx.rel(path)
        count = len(PLACEHOLDER_RE.findall(strip_code_spans(ctx.read_text(path))))
        if must_be_zero and count > 0:
            result.findings.append(Finding("I1", rel, CRITICAL,
                                           f"Developer file has {count} placeholder token(s) "
                                           "(must be zero — file may be unresolved)"))
        elif not must_be_zero and count < 3:
            result.findings.append(Finding("I1", rel, HIGH,
                                           f"Consumer template has only {count} placeholder "
                                           "token(s) (expected ≥ 3 — may have been resolved)"))
    return result


def check_i2_instructions_length(root: pathlib.Path | AuditContext) -> CheckResult:
    """I2 — consumer template line count ≤ 800; token budget awareness."""
    ctx = ensure_context(root)
    result = CheckResult("I2", "Instructions length / token budget")
    consumer_file = ctx.root / "template" / "copilot-instructions.md"
    if not consumer_file.exists():
        return result
    text = ctx.read_text(consumer_file)
    lines = text.count("\n")
    tokens = estimate_tokens(text)
    rel = ctx.rel(consumer_file)
    if lines > 800:
        result.findings.append(Finding("I2", rel, CRITICAL,
                                       f"File is {lines} lines (limit: 800)"))
    elif lines > 720:
        result.findings.append(Finding("I2", rel, WARN,
                                       f"File is {lines} lines (within 80 of 800-line limit)"))
    if tokens > 8000:
        result.findings.append(Finding("I2", rel, WARN,
                                       f"Estimated token count {tokens} is high "
                                       "(target ≤ 8000 for attention budget)"))
    return result


def check_i3_instruction_stubs(root: pathlib.Path | AuditContext) -> CheckResult:
    """I3 — .instructions.md files: frontmatter present; applyTo non-empty."""
    ctx = ensure_context(root)
    result = CheckResult("I3", "Instruction stub frontmatter")
    if not ctx.instruction_files:
        result.findings.append(Finding("I3", ".github/instructions/", INFO,
                                       "No .instructions.md files found"))
        return result
    for ifile in ctx.instruction_files:
        rel = ctx.rel(ifile)
        text = ctx.read_text(ifile)
        if not text.startswith("---"):
            result.findings.append(Finding("I3", rel, HIGH,
                                           "No YAML frontmatter block"))
            continue
        fm = ctx.load_frontmatter(ifile)
        if not fm.get("applyTo"):
            result.findings.append(Finding("I3", rel, WARN,
                                           "Missing or empty 'applyTo' field — "
                                           "instructions will not auto-attach to files"))
    return result


def check_i4_delegation_policy(root: pathlib.Path | AuditContext) -> CheckResult:
    """I4 — main instruction files must define specialist-first delegation."""
    ctx = ensure_context(root)
    result = CheckResult("I4", "Main-agent delegation policy")
    files = (
        ctx.root / ".github" / "copilot-instructions.md",
        ctx.root / "template" / "copilot-instructions.md",
    )

    for path in files:
        if not path.exists():
            result.findings.append(Finding("I4", ctx.rel(path), INFO, "File not found — skip"))
            continue
        rel = ctx.rel(path)
        text = " ".join(ctx.read_text(path).split())
        snippets = DELEGATION_POLICY_SNIPPETS.get(rel, ())
        missing = [snippet for snippet in snippets if " ".join(snippet.split()) not in text]
        if missing:
            result.findings.append(Finding(
                "I4",
                rel,
                HIGH,
                "Missing delegation policy guidance: " + ", ".join(missing[:3]),
            ))

    return result
