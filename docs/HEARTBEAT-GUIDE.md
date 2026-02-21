# Heartbeat Guide — Human Reference

> **Machine-readable version**: `.copilot/workspace/HEARTBEAT.md` (in consumer projects)
> **Template source**: `template/workspace/HEARTBEAT.md`
> This document explains the event-driven heartbeat system and how to customise it.

---

## What is the heartbeat?

The heartbeat is an **event-driven health check** that Copilot runs automatically during certain development events. It keeps the agent aligned with the real state of your project — catching stale metrics, outdated dependencies, accumulated waste, and settings drift without you having to ask.

The concept is adapted from [OpenClaw's heartbeat mechanism](https://docs.openclaw.ai/gateway/heartbeat), which uses timed 30-minute intervals. This template replaces the timer with **event triggers** because GitHub Copilot has no built-in scheduler — instead, the heartbeat fires at natural breakpoints in your development workflow.

---

## How it works

1. A trigger event occurs (see below).
2. Copilot reads `.copilot/workspace/HEARTBEAT.md`.
3. Copilot runs every check in the Checks section.
4. If the trigger is **task completion** or **explicit**, Copilot runs the **Retrospective** — 7 self-reflection questions that persist insights to workspace files.
5. Copilot updates the **Pulse** status: `HEARTBEAT_OK` if all checks pass, or `[!] <alert>` for each failure.
6. Copilot appends a row to the **History** table (keeping the last 5 entries).
7. Copilot writes observations to **Agent Notes** for the next heartbeat.
8. Copilot reports to you **only if alerts exist** — healthy heartbeats are silent (exception: retrospective Q4/Q5 always surface when non-empty).

---

## Event triggers

The heartbeat fires when any of these occur:

| Trigger | When |
|---------|------|
| **Session start** | Every new Copilot session |
| **Large change** | After modifying more than 5 files in a single task |
| **Refactor/migration** | After any task tagged as refactor, migration, or restructure |
| **Dependency update** | After any package manifest changes (package.json, Cargo.toml, requirements.txt, go.mod, etc.) |
| **CI resolution** | After resolving a CI failure |
| **Task completion** | After completing any user-requested task |
| **Explicit** | When you say "Check your heartbeat" or any heartbeat trigger phrase |

### Adding custom triggers

Add new triggers below the `<!-- Add custom triggers below this line -->` comment in `HEARTBEAT.md`. Use the same format:

```markdown
- **Custom trigger name** — description of when it fires
```

Copilot can also add triggers itself as it learns your project's patterns.

---

## Health checks

Each heartbeat runs these checks:

| Check | What it does | Cross-references |
|-------|-------------|------------------|
| **Dependency audit** | Checks for outdated or security-advisory dependencies | `TOOLS.md`, package manifests |
| **Test coverage delta** | Checks if coverage dropped since the last METRICS.md row | `METRICS.md` |
| **Waste scan** | Scans for new W1–W16 waste accumulated this session | §6 Waste Catalogue |
| **MEMORY.md consolidation** | Checks if anything from this session should be persisted | `MEMORY.md` |
| **METRICS.md freshness** | Checks if the baseline is older than 3 sessions | `METRICS.md` |
| **Settings drift** | Checks if §10 overrides still match the codebase | §10 Project-Specific Overrides |

### Adding custom checks

Add new checks below the `<!-- Add custom checks below this line -->` comment in `HEARTBEAT.md`. Use the same format:

```markdown
- [ ] **Check name** — description of what to verify?
```

---

## Retrospective

The retrospective is a structured self-reflection that runs after **task completion** and **explicit** heartbeat triggers. It helps Copilot grow its understanding of itself, the project, and the user over time by asking 7 introspective questions and writing the answers to the appropriate workspace files.

Unlike health checks (which are project-focused), the retrospective is **agent-focused** — it builds the agent's memory, values, and user model.

### The 7 questions

| # | Question | Label | Writes to |
|---|----------|-------|-----------|
| 1 | With the task complete, could I have done anything differently? | Approach review | `SOUL.md` — new reasoning heuristic |
| 2 | Could I have achieved more during this session? | Ambition check | Agent Notes — self-assessment for next heartbeat |
| 3 | Was there anything I missed or failed to address? | Gap analysis | `MEMORY.md` — Known Gotchas table |
| 4 | Did I spot any issues (related or unrelated) to report to $USER? | Issue report | **Surface to $USER** |
| 5 | Do I have questions, suggestions, or things I misunderstood? | Agent questions | **Surface to $USER** |
| 6 | What was $USER's approach, methodology, emotion, and thinking? | User profile | `USER.md` — observed profile |
| 7 | Are there lessons to remember for future tasks? | Lessons learned | `MEMORY.md` + `SOUL.md` |

**$USER** is the user's name (from `USER.md`) if they've shared it, or "the user" otherwise.

### Reporting contract

Questions 4 and 5 are **communication questions** — they always surface to the user when Copilot has something to report, even during an otherwise silent heartbeat. Questions 1–3 and 6–7 are **silent** — Copilot writes insights to workspace files without interrupting the user.

### Adding custom retrospective questions

Add new questions below the `<!-- Add custom retrospective questions below this line -->` comment in `HEARTBEAT.md`. Use the same numbered format:

```markdown
8. **Label** — question text? → *Target file*
```

---

## Sections of HEARTBEAT.md

### Pulse

A single status line. When all checks pass: `HEARTBEAT_OK`. When any check fails, Copilot prepends `[!]` with a one-line alert for each failure. Example:

```text
[!] METRICS.md baseline is 5 sessions old — consider refreshing.
[!] 2 outdated dependencies found in package.json.
```

### Event Triggers

The list of events that cause a heartbeat to fire. Both the template defaults and any custom triggers you add.

### Checks

The checklist of health checks. Each check has a checkbox (`- [ ]`) that Copilot marks when running the heartbeat.

### Retrospective

A numbered list of 7 self-reflection questions that Copilot answers internally after task completion. Each question targets a specific workspace file for persistence. Two questions (Q4 and Q5) surface directly to the user.

### Agent Notes

An agent-writable section where Copilot records observations, patterns, and items to flag on the next heartbeat. This section persists across sessions and helps Copilot build context over time.

### History

An append-only table recording the last 5 heartbeat runs. Each row records the date, trigger event, result (OK or alerts), and any actions taken.

---

## Silent-when-healthy contract

The heartbeat follows an important principle: **report only when alerts exist**. A healthy heartbeat produces no output to the user — it runs silently in the background. This prevents notification fatigue and keeps the agent focused on actual issues.

**Exception**: Retrospective questions Q4 (issue report) and Q5 (agent questions) always surface to the user when Copilot has something to communicate, even during an otherwise healthy heartbeat. These are communication questions — the agent is proactively sharing observations or asking for clarification.

---

## Interaction with other protocols

| Protocol | How heartbeat interacts |
|----------|------------------------|
| **§8 Living Update Protocol** | Heartbeat is a subsection of §8. It follows the same additive-by-default rules. |
| **§6 Waste Catalogue** | The waste scan check references W1–W16 categories from §6. |
| **§10 Project-Specific Overrides** | The settings drift check verifies §10 overrides match reality. |
| **MEMORY.md** | The consolidation check triggers writes to MEMORY.md tables. The retrospective writes gap analysis (Q3) and lessons learned (Q7) to MEMORY.md. |
| **METRICS.md** | The freshness and coverage checks read from METRICS.md rows. |
| **TOOLS.md** | The dependency audit check cross-references TOOLS.md patterns. |
| **SOUL.md** | The heartbeat procedure references SOUL.md for reasoning alignment. The retrospective writes approach reviews (Q1) and lessons learned (Q7) to SOUL.md reasoning heuristics. |
| **USER.md** | The retrospective writes user profile observations (Q6) to USER.md. |

---

## Trigger phrases

Say any of these in Copilot chat:

- *"Check your heartbeat"* — run all checks now
- *"Run heartbeat checks"* — same as above
- *"Show heartbeat status"* — display current Pulse and recent History
- *"Update heartbeat checklist"* — add or modify checks
- *"Clear heartbeat alerts"* — reset Pulse to `HEARTBEAT_OK`
- *"Heartbeat history"* — show the History table
- *"Run retrospective"* — run the retrospective questions now

---

## Customisation examples

### Add a check for API response time

```markdown
- [ ] **API health** — is the main API endpoint responding under 500ms?
```

### Add a trigger for deployment

```markdown
- **Post-deploy** — after any deployment to staging or production
```

### Add a check for TODO count

```markdown
- [ ] **TODO audit** — did the TODO count increase this session? Check with `grep -r 'TODO' src/ | wc -l`
```

### Add a retrospective question for code quality

```markdown
8. **Quality reflection** — did the code I wrote meet the project's quality standards? → *Agent Notes*
```
