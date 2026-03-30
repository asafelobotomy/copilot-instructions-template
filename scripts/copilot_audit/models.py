"""Severity constants and data model for the Copilot Audit tool."""
from __future__ import annotations

from dataclasses import dataclass, field

# ── Severity constants ────────────────────────────────────────────────────────

CRITICAL = "CRITICAL"
HIGH     = "HIGH"
WARN     = "WARN"
INFO     = "INFO"
OK       = "OK"

SEVERITY_ORDER = {CRITICAL: 0, HIGH: 1, WARN: 2, INFO: 3, OK: 4}


# ── Data model ────────────────────────────────────────────────────────────────

@dataclass
class Finding:
    check_id:  str
    file:      str
    severity:  str
    message:   str


@dataclass
class CheckResult:
    check_id:   str
    label:      str
    findings:   list[Finding] = field(default_factory=list)

    def ok(self) -> bool:
        return not any(f.severity in (CRITICAL, HIGH, WARN) for f in self.findings)

    def worst(self) -> str:
        if not self.findings:
            return OK
        return min((f.severity for f in self.findings), key=lambda s: SEVERITY_ORDER[s])
