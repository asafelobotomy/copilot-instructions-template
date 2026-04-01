"""Output formatters (Markdown, JSON) for the Copilot Audit tool."""
from __future__ import annotations

import json
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .models import CheckResult

from .models import CRITICAL, HIGH, WARN, INFO, OK


def summary_counts(results: list[CheckResult]) -> dict[str, int]:
    counts: dict[str, int] = {CRITICAL: 0, HIGH: 0, WARN: 0, INFO: 0, OK: 0}
    for r in results:
        if not r.findings:
            counts[OK] += 1
        else:
            worst = r.worst()
            counts[worst] = counts.get(worst, 0) + 1
    return counts


def overall_status(counts: dict[str, int]) -> str:
    if counts[CRITICAL] > 0 or counts[HIGH] > 0:
        return "CRITICAL"
    if counts[WARN] > 0:
        return "DEGRADED"
    return "HEALTHY"


def format_markdown(results: list[CheckResult]) -> str:
    lines = ["# Copilot Audit Report", ""]
    counts = summary_counts(results)
    status = overall_status(counts)
    lines += [
        f"**Status**: {status}",
        "",
        "| Severity | Count |",
        "|----------|-------|",
        f"| CRITICAL | {counts[CRITICAL]} |",
        f"| HIGH     | {counts[HIGH]} |",
        f"| WARN     | {counts[WARN]} |",
        f"| INFO     | {counts[INFO]} |",
        f"| OK       | {counts[OK]} |",
        "",
        "---",
        "",
        "## Findings",
        "",
    ]
    has_findings = False
    for r in results:
        non_ok = [f for f in r.findings if f.severity != OK]
        if non_ok:
            has_findings = True
            lines.append(f"### {r.check_id} — {r.label}")
            for f in non_ok:
                badge = f"**[{f.severity}]**"
                lines.append(f"- {badge} `{f.file}`: {f.message}")
            lines.append("")
    if not has_findings:
        lines.append("No findings. All checks passed.")
        lines.append("")
    return "\n".join(lines)


def format_json(results: list[CheckResult]) -> str:
    counts = summary_counts(results)
    payload = {
        "status": overall_status(counts),
        "summary": counts,
        "checks": [
            {
                "id":     r.check_id,
                "label":  r.label,
                "status": r.worst(),
                "findings": [
                    {
                        "check_id": f.check_id,
                        "file":     f.file,
                        "severity": f.severity,
                        "message":  f.message,
                    }
                    for f in r.findings
                ],
            }
            for r in results
        ],
    }
    return json.dumps(payload, indent=2)


# Backward-compatible aliases for existing imports.
_summary_counts = summary_counts
_overall_status = overall_status
