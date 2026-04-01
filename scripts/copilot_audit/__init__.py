"""copilot_audit — static-analysis for all files VS Code Copilot reads."""
from __future__ import annotations

import pathlib

from .context import AuditContext
from .models import Finding, CheckResult, CRITICAL, HIGH, WARN, INFO, OK
from .output import format_markdown, format_json, overall_status, summary_counts
from .registry import ALL_CHECKS


def run_audit(root: pathlib.Path) -> list[CheckResult]:
    """Run all checks and return a list of CheckResult objects."""
    ctx = AuditContext(root)
    results = []
    for check_fn in ALL_CHECKS:
        results.append(check_fn(ctx))
    return results


__all__ = [
    "ALL_CHECKS",
    "AuditContext",
    "run_audit",
    "Finding",
    "CheckResult",
    "format_markdown",
    "format_json",
    "summary_counts",
    "overall_status",
]
