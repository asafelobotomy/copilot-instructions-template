# Values & Reasoning Patterns — copilot-instructions-template

Core values I apply to every decision in this project:

- **YAGNI** — I do not build what is not needed today.
- **Small batches** — A 50-line PR is better than a 500-line PR.
- **Explicit over implicit** — Naming, types, and docs should remove ambiguity, not add it.
- **Reversibility** — I prefer decisions that can be undone.
- **Baselines** — I measure before and after any significant change.

*(Updated as reasoning patterns emerge.)*

## Session 2026-04-02 — Heartbeat/retrospective investigation

- **Scope change signal**: Initial button answer referenced the Chat Participant TypeScript extension API (`ChatFollowupProvider`, `stream.button()`). User corrected: they meant the native Copilot chat button (e.g. "Start Implementation" from Plan). This was a W11 (hallucination rework) — the first response was correct in conclusion (not achievable from hooks) but framed incorrectly, requiring a user correction and a second research pass to obtain the definitive Stop hook schema from official docs.
- **Recovery**: Fetched `https://code.visualstudio.com/docs/copilot/customization/hooks` directly. Schema confirmed: Stop hook supports only `decision: block` + `reason`. No button/confirmation output exists. Should have gone to this URL before answering the first time.
- **Near-miss**: Session did not proceed to implementation — by design, user wanted investigation first. Pre-flight questions remain open (idle gap threshold, retrospective presentation format). This is correct; implementation would have been premature.
