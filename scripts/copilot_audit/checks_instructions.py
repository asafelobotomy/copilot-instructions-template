"""Instruction checks (I1–I3) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib

from .models import Finding, CheckResult, HIGH, WARN, INFO, CRITICAL
from .helpers import (parse_frontmatter, estimate_tokens, strip_code_spans,
                      PLACEHOLDER_RE, instruction_dirs)


def check_i1_instructions_placeholders(root: pathlib.Path) -> CheckResult:
    """I1 — copilot-instructions.md placeholder separation."""
    result = CheckResult("I1", "Instructions placeholder separation")
    dev_file      = root / ".github" / "copilot-instructions.md"
    consumer_file = root / "template" / "copilot-instructions.md"

    for path, must_be_zero in ((dev_file, True), (consumer_file, False)):
        if not path.exists():
            result.findings.append(Finding("I1", str(path.relative_to(root)),
                                           INFO, "File not found — skip"))
            continue
        rel = str(path.relative_to(root))
        count = len(PLACEHOLDER_RE.findall(
            strip_code_spans(path.read_text(encoding="utf-8", errors="replace"))
        ))
        if must_be_zero and count > 0:
            result.findings.append(Finding("I1", rel, CRITICAL,
                                           f"Developer file has {count} placeholder token(s) "
                                           "(must be zero — file may be unresolved)"))
        elif not must_be_zero and count < 3:
            result.findings.append(Finding("I1", rel, HIGH,
                                           f"Consumer template has only {count} placeholder "
                                           "token(s) (expected ≥ 3 — may have been resolved)"))
    return result


def check_i2_instructions_length(root: pathlib.Path) -> CheckResult:
    """I2 — consumer template line count ≤ 800; token budget awareness."""
    result = CheckResult("I2", "Instructions length / token budget")
    consumer_file = root / "template" / "copilot-instructions.md"
    if not consumer_file.exists():
        return result
    text  = consumer_file.read_text(encoding="utf-8", errors="replace")
    lines = text.count("\n")
    tokens = estimate_tokens(text)
    rel = str(consumer_file.relative_to(root))
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


def check_i3_instruction_stubs(root: pathlib.Path) -> CheckResult:
    """I3 — .instructions.md files: frontmatter present; applyTo non-empty."""
    result = CheckResult("I3", "Instruction stub frontmatter")
    dirs = instruction_dirs(root)
    found = False
    for d in dirs:
        for ifile in sorted(d.glob("*.instructions.md")) if d.is_dir() else []:
            found = True
            rel = str(ifile.relative_to(root))
            text = ifile.read_text(encoding="utf-8", errors="replace")
            if not text.startswith("---"):
                result.findings.append(Finding("I3", rel, HIGH,
                                               "No YAML frontmatter block"))
                continue
            fm = parse_frontmatter(text)
            if not fm.get("applyTo"):
                result.findings.append(Finding("I3", rel, WARN,
                                               "Missing or empty 'applyTo' field — "
                                               "instructions will not auto-attach to files"))
    if not found:
        result.findings.append(Finding("I3", ".github/instructions/", INFO,
                                       "No .instructions.md files found"))
    return result
