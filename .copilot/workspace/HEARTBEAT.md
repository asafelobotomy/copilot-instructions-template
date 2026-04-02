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

Retrospective is optional. Do not run it on every task.

Use it only when:

- the user explicitly asks for a retrospective; or
- a medium/large task has just completed and you first ask the user: "That was a large change to the codebase, would you like me to run a retrospective?"

Skip retrospective entirely for small, localized, or low-risk tasks. If the user declines, stop normally and do not force it.

Treat medium/large as a heuristic. Suggest retrospective when the task hits one strong signal (8+ modified files or 30+ minutes) or two supporting signals (5+ modified files, 15+ minutes, context compaction).

When you do run a retrospective, reflect on these questions. Write insights to the indicated workspace files. Surface Q4 and Q5 to $USER directly — all other answers are silent.

1. **Execution review** — Were there any errors, backtracking, scope changes, or near-misses on explicit requirements? What concrete signal changed course? → *SOUL.md*
2. **Coverage audit** — Compare the original request with the delivered result. Did I defer, simplify, or leave anything incomplete? Did any modified file miss a matching test or doc update? → *MEMORY.md*
3. **User profile** — What explicit preferences, corrections, or working patterns did $USER demonstrate? Record only directly observable signals. → *USER.md*
4. **Issue report** — What should I report to $USER now? (e.g. security concerns, tech debt, broken assumptions, stale dependencies, validation gaps) → *Surface to $USER*
5. **Carry-forward** — What follow-up questions, recommendations, durable lessons, or user corrections should I carry forward from this task? State lessons as: "When [situation], do [action] instead of [what usually fails]." → *Surface to $USER + MEMORY.md + SOUL.md*

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
<!-- template-section: heartbeat-response-contract v2 -->

- Always append a History row when the trigger is Session start or Explicit — regardless of check results.
- For all other triggers, append a History row only if a check raised an alert or retrospective output was persisted to SOUL.md / MEMORY.md / USER.md.
- If checks pass and nothing was persisted on a non-explicit trigger, keep Pulse as `HEARTBEAT_OK` and omit the History row.

## Agent Notes

*(Agent-writable. Observations, patterns, and items to flag on next heartbeat.)*

## History

*(Append-only. Keep last 5 entries.)*

| Date | Session ID | Trigger | Result | Actions taken |
|------|------------|---------|--------|---------------|
| 2026-04-02 | 1bfe8821-3b7b-4b8a-89eb-65472a1368cd | Session start + CI resolution | PASS | Reviewed latest failed CI run; isolated ShellCheck failure in test-customization-contracts.sh; added scoped SC2016 suppressions for embedded Python snippets; ran bash tests/run-all.sh (25 suites passing); updated repo memory with shell-quoting note |
| 2026-03-19 | n/a | Task completion + explicit debug | WARN→PASS | Added CI check 4 for copilot-instructions.md placeholders; updated MEMORY.md metrics freshness; logged this heartbeat entry |
| 2026-03-19 | n/a | Task completion (Researcher + Explore agents) | PASS | Added researcher.agent.md, explore.agent.md; RESEARCH.md URL tracker; SETUP.md counts 6→8 agents, 8→9 workspace files; DOC_INDEX updated; tests 226→227+ |
