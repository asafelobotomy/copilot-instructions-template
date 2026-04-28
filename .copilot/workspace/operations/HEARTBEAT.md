# Heartbeat — copilot-instructions-template

<!-- workspace-layer: L2 | trigger: heartbeat event -->
> **Domain**: Events — health checks, session history, pulse status, and retrospective protocol.
> **Boundary**: No long-term facts, preferences, or reasoning patterns.
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
- [ ] **MEMORY row budget** — does MEMORY.md remain concise, current, and under the active row budget?
- [ ] **Repo-memory promotion** — do validated facts in `/memories/repo/` now belong in MEMORY.md?
- [ ] **PreCompact snapshot quality** — would the current save-context snapshot surface the trigger, latest MEMORY entries, and SOUL cues cleanly?
- [ ] **Metrics freshness** — has the metrics baseline been reviewed in the last 3 sessions?
- [ ] **Settings drift** — do §10 overrides still match the codebase?
- [ ] **Agent compatibility** — do agent files use current frontmatter schema? Any deprecated fields?
- [ ] **Fact consistency** — do any MEMORY.md entries contradict each other or contradict current source files? Flag conflicting rows.
- [ ] **Metrics staleness** — do any Metrics Freshness rows have an `Expires` date in the past? Re-verify or archive.
<!-- Add custom checks below this line -->

## Retrospective

Retrospective runs autonomously via the `asafelobotomy_session_reflect` extension tool. If it is already loaded, call it directly. Otherwise try `tool_search` once. If that is unavailable, run `python3 .github/hooks/scripts/session_reflect_fallback.py` instead when that file exists. Do not prompt the user.

The PostToolUse hook instructs you to call `asafelobotomy_session_reflect` when a significant task is detected (one strong signal: 8+ modified files or 30+ minutes active; or two supporting signals: 5+ modified files, 15+ minutes, context compaction). On clients that fire the Stop hook (Claude Code / CLI), the Stop handler provides a blocking fallback for the same check.

When `asafelobotomy_session_reflect` returns, process its output silently:

- **Execution insights** → persist to *SOUL.md* if non-trivial
- **Coverage gaps** → persist to *MEMORY.md* if incomplete
- **User signals** → persist to *USER.md* if directly observable
- **Actionable items** → surface to the user (security, tech debt, broken assumptions)
- **Carry-forward lessons** → persist to *MEMORY.md + SOUL.md*

When a lesson first lands in built-in repo memory, decide during heartbeat whether it should stay repo-local or be promoted into MEMORY.md for team-wide durability.

The `session_reflect` path records completion automatically by setting the session sentinel and writing a `session_reflect` completion event. No manual sentinel management is needed.

If both `asafelobotomy_session_reflect` and `session_reflect_fallback.py` are unavailable, briefly self-review: execution accuracy, scope completeness, and anything worth persisting to identity files, then rerun `asafelobotomy_session_reflect` once a supported path is available.

<!-- Add custom retrospective questions below this line -->

## Response Contract
<!-- template-section: heartbeat-response-contract v2 -->

- Always append a History row when the trigger is Session start or Explicit — regardless of check results.
- For all other triggers, append a History row only if a check raised an alert or retrospective output was persisted to identity files.
- If checks pass and nothing was persisted on a non-explicit trigger, keep Pulse as `HEARTBEAT_OK` and omit the History row.

## Agent Notes

*(Agent-writable. Observations, patterns, and items to flag on next heartbeat.)*

## History

*(Append-only. Keep last 5 entries. Keep each row to trigger, result, and where durable insights were persisted.)*

| Date | Session ID | Trigger | Result | Actions taken |
|------|------------|---------|--------|---------------|
| 2026-04-28 | local-835b6fba | session_reflect — P3/P4/P6/P7/P9/P10 implementation | PASS | 14 files edited: install-metadata schema (context.py, checks_version.py, fixtures, setup agent §2.13), MCP delta update step, A18 plugin-authoring opt-in (interview.md, manifests.md, setup agent §2.7), REGISTRY.json schemaVersion 1.2 + per-kit version, workspace-index regen. 42/42 suites green, audit HEALTHY. Diary entry written. |
| 2026-04-28 | local-835b6fba | session_reflect | PASS | Ran session_reflect via local fallback runner after stop-hook block. No additional SOUL/MEMORY/USER updates needed. Targeted validation remained green for agent contracts, model sync, hook pulse, and policy checks. |
| 2026-04-28 | local-04e35182 | session_reflect — MCP + interview + stubs improvements | PASS | 6 files: added sequential-thinking MCP (dev+template), created consumer plugin-components.instructions.md, fixed E22/E22a interview questions (heartbeat+sequential-thinking), updated manifests.md MCP blocks+stubs table. 8/8 contract tests green. Plan produced for P3/P4/P6/P7/P9/P10. |
| 2026-04-16 | local-dadf28a1 | session_reflect — Extension tool naming + deferred load | PASS | 1 commit (306dbb4): exact callable names (asafelobotomy_*), deferred tool_search load instruction, Extension Protocol entry in dev instructions, corrected MCP→extension label in both HEARTBEAT.md files. 45/45 suites green. |
| 2026-04-16 | local-dadf28a1 | session_reflect — Diary system + commit agent | PASS | 2 commits: commit-agent 7 fixes; diary system separation (agent_type field, remove hook auto-write, add write_diary+read_diaries MCP tools, 7 new tests). 45/45 suites green. MEMORY test baseline updated (222→284). SOUL diary-explicit lesson added. |
