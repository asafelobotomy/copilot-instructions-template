# Heartbeat — copilot-instructions-template

> Event-driven health check. Read this file at every trigger event, run all checks, update Pulse, and log to History.
> **Contract**: Follow this checklist strictly. Do not infer tasks from prior sessions.

## Pulse

`HEARTBEAT_OK` — No alerts.

## Event Triggers

Fire a heartbeat when any of these occur:

- **Session start** — always
- **Large change** — modified >5 files in a single task
- **Refactor/migration** — task tagged as refactor, migration, or restructure
- **Dependency update** — any manifest changed (package.json, Cargo.toml, requirements.txt, go.mod, etc.)
- **CI resolution** — after resolving a CI failure
- **Task completion** — after completing any user-requested task
- **Explicit** — user says "Check your heartbeat"
<!-- Add custom triggers below this line -->

## Checks

Run each check; prepend `[!]` to Pulse if any fails:

- [ ] **Dependency audit** — any outdated or security-advisory deps in TOOLS.md / manifests?
- [ ] **Test coverage delta** — did coverage drop since last session?
- [ ] **Waste scan** — any new W1–W16 waste accumulated this session? (§6)
- [ ] **MEMORY.md consolidation** — anything from this session to persist?
- [ ] **Metrics freshness** — has the metrics baseline been reviewed in the last 3 sessions?
- [ ] **Settings drift** — do §10 overrides still match the codebase?
- [ ] **Agent compatibility** — do agent files use current frontmatter schema? Any deprecated fields?
<!-- Add custom checks below this line -->

## Retrospective

After completing a task, reflect on these questions. Write insights to the indicated workspace files. Surface Q4 and Q5 to $USER directly — all other answers are silent.

1. **Approach review** — Were there any errors, corrections, or backtracking during this task? What concrete signal caused the course change? → *SOUL.md*
2. **Scope audit** — Did the task scope grow or shrink during execution? Were any user requests deferred, simplified, or left incomplete? → *MEMORY.md (Known Gotchas)*
3. **Gap analysis** — Review the original request and the delivered result. Is there any explicit requirement I did not address, or any file I modified without updating its tests or docs? → *MEMORY.md*
4. **Issue report** — Did I spot any issues to report to $USER? (e.g. security concerns, tech debt, broken assumptions, stale dependencies) → *Surface to $USER*
5. **Agent questions** — Do I have questions, suggestions, or things I misunderstood? → *Surface to $USER*
6. **User profile** — What explicit preferences, corrections, or working patterns did $USER demonstrate? (Only record directly observable signals; do not infer emotion or intent.) → *USER.md*
7. **Lessons learned** — State as concrete rules: "When [situation], do [action] instead of [what usually fails]." Only record lessons grounded in this session’s events. → *MEMORY.md + SOUL.md*
8. **Correction log** — Did $USER correct, reject, or redirect anything I produced? What was my original output and what did $USER want instead? → *MEMORY.md (Recurring Error Patterns) + SOUL.md*

After completing retrospective steps, mark the current session sentinel complete:

```bash
python3 - <<'PY'
from pathlib import Path
p = Path('.copilot/workspace/.heartbeat-session')
if p.exists():
	parts = p.read_text(encoding='utf-8').strip().split('|')
	if len(parts) >= 3:
		p.write_text(f"{parts[0]}|{parts[1]}|complete\n", encoding='utf-8')
PY
```

<!-- Add custom retrospective questions below this line -->

## Response Contract

- If all checks pass and no new issues were found, keep Pulse as `HEARTBEAT_OK` and do not append a History row.
- Append a History row only when trigger is Explicit or Session start, a check raised an alert, or retrospective output was persisted to SOUL.md / MEMORY.md / USER.md.

## Agent Notes

*(Agent-writable. Observations, patterns, and items to flag on next heartbeat.)*

## History

*(Append-only. Keep last 5 entries.)*

| Date | Session ID | Trigger | Result | Actions taken |
|------|------------|---------|--------|---------------|
| 2026-03-19 | n/a | Task completion + explicit debug | WARN→PASS | Added CI check 4 for copilot-instructions.md placeholders; updated MEMORY.md metrics freshness; logged this heartbeat entry |
| 2026-03-19 | n/a | Task completion (Researcher + Explore agents) | PASS | Added researcher.agent.md, explore.agent.md; RESEARCH.md URL tracker; SETUP.md counts 6→8 agents, 8→9 workspace files; DOC_INDEX updated; tests 226→227+ |
