# Development Journal — {{PROJECT_NAME}}

Architectural decisions and key context are recorded here in ADR (Architectural Decision Record) style. New entries go at the **top**.

---

## {{SETUP_DATE}} — Project onboarded to copilot-instructions-template

**Context**: This project adopted the generic Lean/Kaizen Copilot instructions template from [asafelobotomy/copilot-instructions-template](https://github.com/asafelobotomy/copilot-instructions-template).

**Decision**: Use `.github/copilot-instructions.md` as the primary agent guidance document. Use `.copilot/workspace/` for session-persistent agent identity state. Apply Lean/Kaizen as the development methodology.

**Consequences**:
- Copilot is authorised to update `.github/copilot-instructions.md` when patterns stabilise (see Living Update Protocol in the instructions).
- All significant architectural decisions are recorded here.
- METRICS.md tracks measurable baselines over time.

---

<!--
Template for future ADR entries:

## YYYY-MM-DD — <short title>

**Context**: Why this decision was needed.
**Decision**: What was decided.
**Consequences**: What changes as a result. What future options are opened or closed.
-->
