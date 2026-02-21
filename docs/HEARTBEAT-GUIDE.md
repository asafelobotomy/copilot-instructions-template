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
4. Copilot updates the **Pulse** status: `HEARTBEAT_OK` if all checks pass, or `[!] <alert>` for each failure.
5. Copilot appends a row to the **History** table (keeping the last 5 entries).
6. Copilot writes observations to **Agent Notes** for the next heartbeat.
7. Copilot reports to you **only if alerts exist** — healthy heartbeats are silent.

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

### Agent Notes

An agent-writable section where Copilot records observations, patterns, and items to flag on the next heartbeat. This section persists across sessions and helps Copilot build context over time.

### History

An append-only table recording the last 5 heartbeat runs. Each row records the date, trigger event, result (OK or alerts), and any actions taken.

---

## Silent-when-healthy contract

The heartbeat follows an important principle: **report only when alerts exist**. A healthy heartbeat produces no output to the user — it runs silently in the background. This prevents notification fatigue and keeps the agent focused on actual issues.

---

## Interaction with other protocols

| Protocol | How heartbeat interacts |
|----------|------------------------|
| **§8 Living Update Protocol** | Heartbeat is a subsection of §8. It follows the same additive-by-default rules. |
| **§6 Waste Catalogue** | The waste scan check references W1–W16 categories from §6. |
| **§10 Project-Specific Overrides** | The settings drift check verifies §10 overrides match reality. |
| **MEMORY.md** | The consolidation check triggers writes to MEMORY.md tables. |
| **METRICS.md** | The freshness and coverage checks read from METRICS.md rows. |
| **TOOLS.md** | The dependency audit check cross-references TOOLS.md patterns. |
| **SOUL.md** | The heartbeat procedure references SOUL.md for reasoning alignment. |

---

## Trigger phrases

Say any of these in Copilot chat:

- *"Check your heartbeat"* — run all checks now
- *"Run heartbeat checks"* — same as above
- *"Show heartbeat status"* — display current Pulse and recent History
- *"Update heartbeat checklist"* — add or modify checks
- *"Clear heartbeat alerts"* — reset Pulse to `HEARTBEAT_OK`
- *"Heartbeat history"* — show the History table

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
