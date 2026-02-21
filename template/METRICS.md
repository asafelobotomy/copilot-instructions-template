# Metrics — {{PROJECT_NAME}}

Kaizen baseline snapshots. One row is appended each time `{{METRICS_COMMAND}}` is run, or after any session that materially changes LOC, test count, or dependency count.

| Date | Phase | LOC (total) | Files | Tests | Assertions | Type errors | Runtime deps | Deploy Freq | Lead Time | CFR | MTTR | AI Accept Rate | Context Resets |
|------|-------|-------------|-------|-------|------------|-------------|--------------|-------------|-----------|-----|------|----------------|----------------|
| {{SETUP_DATE}} | Setup baseline | — | — | — | — | 0 | — | — | — | — | — | — | — |

---

## Baseline definitions

| Metric | Green | Warn | High |
|--------|-------|------|------|
| LOC per file | < {{LOC_WARN_THRESHOLD}} | {{LOC_WARN_THRESHOLD}}–{{LOC_HIGH_THRESHOLD}} | > {{LOC_HIGH_THRESHOLD}} |
| Runtime deps | ≤ {{DEP_BUDGET}} | {{DEP_BUDGET_WARN}} | — |
| Type errors | 0 | — | > 0 |
| Tests | growing | stable | declining |

---

## DORA definitions

| Metric | Green | Warn | High |
|--------|-------|------|------|
| Deploy Freq (deploys/week) | ≥ {{DEPLOY_FREQ_TARGET}} | < {{DEPLOY_FREQ_TARGET}} | — |
| Lead Time (commit-to-deploy hours) | ≤ {{LEAD_TIME_TARGET}} | > {{LEAD_TIME_TARGET}} | — |
| CFR (change failure rate %) | ≤ {{CFR_TARGET}} | > {{CFR_TARGET}} | — |
| MTTR (time to restore, hours) | ≤ {{MTTR_TARGET}} | > {{MTTR_TARGET}} | — |
| AI Accept Rate (suggestion %) | tracking | — | — |
| Context Resets (per session) | tracking | — | — |

---

*(Never edit existing rows. Only append new rows. This is an append-only log.)*
