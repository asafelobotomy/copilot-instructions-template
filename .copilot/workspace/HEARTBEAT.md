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

Retrospective runs autonomously via the `session_reflect` MCP tool. Do not prompt the user.

The Stop hook blocks the session and instructs you to call `session_reflect` when a significant task is detected (one strong signal: 8+ modified files or 30+ minutes active; or two supporting signals: 5+ modified files, 15+ minutes, context compaction).

When `session_reflect` returns, process its output silently:

- **Execution insights** → persist to *SOUL.md* if non-trivial
- **Coverage gaps** → persist to *MEMORY.md* if incomplete
- **User signals** → persist to *USER.md* if directly observable
- **Actionable items** → surface to the user (security, tech debt, broken assumptions)
- **Carry-forward lessons** → persist to *MEMORY.md + SOUL.md*

The MCP tool sets the session sentinel complete automatically. No manual sentinel management is needed.

If the `session_reflect` MCP tool is unavailable, briefly self-review: execution accuracy, scope completeness, and anything worth persisting to SOUL.md / MEMORY.md / USER.md.

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
| 2026-04-02 | local-a0d837a3 | Retrospective — heartbeat/button investigation | PASS | Research session: diagnosed false-positive retrospective trigger (elapsed time alone as strong signal, no delta gate); confirmed Stop hook schema (no button output); designed active-work-time model. W11 noted: initial button answer required user correction. Insights persisted to SOUL.md, MEMORY.md, USER.md, repo memory. |
| 2026-04-02 | 1bfe8821-3b7b-4b8a-89eb-65472a1368cd | Session start + CI resolution | PASS | Reviewed latest failed CI run; isolated ShellCheck failure in test-customization-contracts.sh; added scoped SC2016 suppressions for embedded Python snippets; ran bash tests/run-all.sh (25 suites passing); updated repo memory with shell-quoting note |
| 2026-03-19 | n/a | Task completion + explicit debug | WARN→PASS | Added CI check 4 for copilot-instructions.md placeholders; updated MEMORY.md metrics freshness; logged this heartbeat entry |
| 2026-03-19 | n/a | Task completion (Researcher + Explore agents) | PASS | Added researcher.agent.md, explore.agent.md; RESEARCH.md URL tracker; SETUP.md counts 6→8 agents, 8→9 workspace files; DOC_INDEX updated; tests 226→227+ |
