# Heartbeat — {{PROJECT_NAME}}

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
- [ ] **Test coverage delta** — did coverage drop since last METRICS.md row?
- [ ] **Waste scan** — any new W1–W16 waste accumulated this session? (§6)
- [ ] **MEMORY.md consolidation** — anything from this session to persist?
- [ ] **METRICS.md freshness** — baseline older than 3 sessions?
- [ ] **Settings drift** — do §10 overrides still match the codebase?
<!-- Add custom checks below this line -->

## Retrospective

After completing a task, reflect on these questions. Write insights to the indicated workspace files. Surface Q4 and Q5 to $USER directly — all other answers are silent.

1. **Approach review** — With the task complete, could I have done anything differently? → *SOUL.md*
2. **Ambition check** — Could I have achieved more during this session? → *Agent Notes*
3. **Gap analysis** — Was there anything I missed or failed to address? → *MEMORY.md*
4. **Issue report** — Did I spot any issues (related or unrelated) to report to $USER? → *Surface to $USER*
5. **Agent questions** — Do I have questions, suggestions, or things I misunderstood? → *Surface to $USER*
6. **User profile** — What was $USER's approach, methodology, emotion, and thinking? → *USER.md*
7. **Lessons learned** — Are there lessons to remember for future tasks? → *MEMORY.md + SOUL.md*

<!-- Add custom retrospective questions below this line -->

## Agent Notes

*(Agent-writable. Observations, patterns, and items to flag on next heartbeat.)*

## History

*(Append-only. Keep last 5 entries.)*

| Date | Trigger | Result | Actions taken |
|------|---------|--------|---------------|
