# Metrics — {{PROJECT_NAME}}

Kaizen baseline snapshots. One row is appended each time `{{METRICS_COMMAND}}` is run, or after any session that materially changes LOC, test count, or dependency count.

| Date | Phase | LOC (total) | Files | Tests | Assertions | Type errors | Runtime deps |
|------|-------|-------------|-------|-------|------------|-------------|---------------|
| {{SETUP_DATE}} | Setup baseline | — | — | — | — | 0 | — |

---

## Baseline definitions

| Metric | Green ✅ | Warn ⚠️ | High 🔴 |
|--------|---------|--------|--------|
| LOC per file | < {{LOC_WARN_THRESHOLD}} | {{LOC_WARN_THRESHOLD}}–{{LOC_HIGH_THRESHOLD}} | > {{LOC_HIGH_THRESHOLD}} |
| Runtime deps | ≤ {{DEP_BUDGET}} | {{DEP_BUDGET_WARN}} | — |
| Type errors | 0 | — | > 0 |
| Tests | growing | stable | declining |

---

*(Never edit existing rows. Only append new rows. This is an append-only log.)*
