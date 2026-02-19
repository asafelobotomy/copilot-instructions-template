# Copilot Instructions — {{PROJECT_NAME}}

> **Template version**: 1.0.0 | **Applied**: {{SETUP_DATE}}
> This file is a *living document*. See §8 for self-edit rules and template update instructions.

> **Model Quick Reference** — select model in Copilot picker before starting each task, or use `.github/agents/` (VS Code 1.106+). [Why these models?](https://docs.github.com/en/copilot/reference/ai-models/model-comparison)
>
> | Task | Best model (Pro+) | Budget / Free fallback |
> |------|------------------|----------------------|
> | Setup / onboarding | Claude Sonnet 4.6 | GPT-5 mini |
> | Coding & agentic tasks | GPT-5.3-Codex | GPT-5.1-Codex → GPT-5 mini |
> | Code review — PR / diff | GPT-5.2-Codex | GPT-5.1-Codex → GPT-4.1 |
> | Code review — deep / architecture | Claude Opus 4.6 *(3×)* → Claude Sonnet 4.6 *(1×)* | GPT-5 mini |
> | Complex debugging & reasoning | Claude Opus 4.6 *(3×)* → Claude Sonnet 4.6 *(1×)* | GPT-5 mini |
> | Quick questions / lightweight | Claude Haiku 4.5 *(0.33×)* | GPT-5 mini |
>
> Model names change frequently. If a model is missing from your picker, check [Supported AI models](https://docs.github.com/en/copilot/reference/ai-models/supported-models) and update the agent files.

---

## §1 — Lean Principles

| # | Principle | This project |
|---|-----------|-------------|
| 1 | Eliminate waste (Muda) | Every line of code has a cost; every unused feature is waste |
| 2 | Map the value stream | {{VALUE_STREAM_DESCRIPTION}} |
| 3 | Create flow | {{FLOW_DESCRIPTION}} |
| 4 | Establish pull | Build only what is needed, when it is needed |
| 5 | Seek perfection | Small, continuous improvements (Kaizen) over big rewrites |

**Waste taxonomy** (§6 provides full detail):
- Overproduction · Waiting · Transport · Over-processing · Inventory · Motion · Defects · Unused talent

---

## §2 — Operating Modes

Switch modes explicitly. Default is **Implement**.

### Implement Mode (default)
- Plan → implement → test → document in one uninterrupted flow.
- Full PDCA cycle for every non-trivial change.
- Three-check ritual before marking a task complete.
- Update `BIBLIOGRAPHY.md` on every file create/rename/delete.

### Review Mode
- Read-only by default. State findings before proposing fixes.
- Tag every finding with a waste category (§6).
- Use format: `[severity] | [file:line] | [waste category] | [description]`
- Severity: `critical` | `major` | `minor` | `advisory`

### Refactor Mode
- No behaviour changes. Tests must pass before and after.
- Measure LOC delta. Flag if a refactor increases LOC without justification.

### Planning Mode
- Produce a task breakdown before writing code.
- Estimate complexity (S/M/L/XL). Flag anything XL for decomposition.

---

## §3 — Standardised Work Baselines

These baselines apply to all modes unless overridden in §10.

| Baseline | Value | Action if exceeded |
|----------|-------|--------------------|
| File LOC (warn) | {{LOC_WARN_THRESHOLD}} lines | Flag, suggest decomposition |
| File LOC (hard) | {{LOC_HIGH_THRESHOLD}} lines | Refuse to extend; decompose first |
| Dependency budget | {{DEP_BUDGET}} runtime deps | Propose removal before adding |
| Dependency budget (warn) | {{DEP_BUDGET_WARN}} runtime deps | Flag for review |
| Test command | `{{TEST_COMMAND}}` | Must pass before task is done |
| Type check | `{{TYPE_CHECK_COMMAND}}` | Must pass before task is done |
| Three-check ritual | `{{THREE_CHECK_COMMAND}}` | Run before marking complete |
| Integration test gate | `{{INTEGRATION_TEST_ENV_VAR}}` | Set to run integration tests |
| Max subagent depth | {{SUBAGENT_MAX_DEPTH}} | Stop and report to user |

---

## §4 — Coding Conventions

- Language: **{{LANGUAGE}}** · Runtime: **{{RUNTIME}}** · Package manager: **{{PACKAGE_MANAGER}}**
- Test framework: **{{TEST_FRAMEWORK}}**
- Preferred serialisation: **{{PREFERRED_SERIALISATION}}**

**Patterns observed in this codebase**:
{{CODING_PATTERNS}}

**Universal rules**:
- No `any` / untyped unless explicitly commented with `// deliberately untyped: <reason>`.
- No silent error swallowing. Every caught error must be logged or re-thrown.
- No commented-out code in commits. Delete it; git history is the undo stack.
- Imports are grouped: stdlib → third-party → internal. One blank line between groups.
- Functions do one thing. If you need "and" in the name, split it.

---

## §5 — PDCA Cycle

Apply to every non-trivial change.

**Plan**: State the goal. List the files that will change. Estimate LOC delta.
**Do**: Implement. Write tests alongside code, not after.
**Check**: Run `{{THREE_CHECK_COMMAND}}`. Review output. Fix before proceeding.
**Act**: If baseline exceeded, address it now. Update `BIBLIOGRAPHY.md`. Summarise what changed.

---

## §6 — Waste Catalogue (Muda)

Use in Review Mode to tag findings.

| Code | Name | Examples |
|------|------|---------|
| W1 | Overproduction | Features built before needed; dead code paths |
| W2 | Waiting | Blocking I/O without timeout; sync where async fits |
| W3 | Transport | Unnecessary data copying; props drilled 3+ levels |
| W4 | Over-processing | Abstraction for its own sake; premature generalisation |
| W5 | Inventory | Large WIP branches; uncommitted changes sitting idle |
| W6 | Motion | Context switches; scattered logic across many files |
| W7 | Defects | Bugs, type errors, test failures, silent exceptions |
| W8 | Unused talent | Missing automation; repetitive manual steps |

---

## §7 — Metrics

Append a row to `METRICS.md` after any session that changes these values materially.

| Metric | Command | Target |
|--------|---------|--------|
| Total LOC | `{{LOC_COMMAND}}` | Trending down or flat |
| Test count | `{{TEST_COMMAND}}` | Trending up |
| Type errors | `{{TYPE_CHECK_COMMAND}}` | Zero |
| Runtime deps | count from manifest | ≤ {{DEP_BUDGET}} |
| {{EXTRA_METRIC_NAME}} | — | — |

---

## §8 — Living Update Protocol

Copilot may edit this file when patterns stabilise. Rules:

1. **Never delete** existing rules without explicit user instruction.
2. **Additive by default** — append to sections; don't restructure them.
3. **Flag before writing** — describe the change and wait for confirmation on edits to §1–§7.
4. **Self-update trigger phrases**: "Update your instructions", "Add this to your instructions", "Remember this for next time".
5. **Template updates**: When the user says "Update from template", fetch the latest template and apply the update protocol in `UPDATE.md`.

---

## §9 — Subagent Protocol

When spawning subagents:

- Pass the full contents of this file as system context.
- Set `max_depth = {{SUBAGENT_MAX_DEPTH}}`. Stop and surface to user if reached.
- Each subagent must run the three-check ritual before reporting done.
- Subagent output must include: files changed, LOC delta, test result, any baseline breaches.

---

## §10 — Project-Specific Overrides

Resolved values and project-specific overrides. Populated during setup; updated via §8.

| Placeholder | Resolved value |
|-------------|---------------|
| `{{PROJECT_NAME}}` | *(fill during setup)* |
| `{{LANGUAGE}}` | *(fill during setup)* |
| `{{RUNTIME}}` | *(fill during setup)* |
| `{{PACKAGE_MANAGER}}` | *(fill during setup)* |
| `{{TEST_COMMAND}}` | *(fill during setup)* |
| `{{TYPE_CHECK_COMMAND}}` | *(fill during setup)* |
| `{{THREE_CHECK_COMMAND}}` | *(fill during setup)* |
| `{{LOC_COMMAND}}` | *(fill during setup)* |
| `{{METRICS_COMMAND}}` | *(fill during setup)* |
| `{{TEST_FRAMEWORK}}` | *(fill during setup)* |
| `{{LOC_WARN_THRESHOLD}}` | 250 |
| `{{LOC_HIGH_THRESHOLD}}` | 400 |
| `{{DEP_BUDGET}}` | *(fill during setup)* |
| `{{DEP_BUDGET_WARN}}` | *(fill during setup)* |
| `{{INTEGRATION_TEST_ENV_VAR}}` | INTEGRATION_TESTS=1 |
| `{{PREFERRED_SERIALISATION}}` | JSON |
| `{{SUBAGENT_MAX_DEPTH}}` | 3 |
| `{{VALUE_STREAM_DESCRIPTION}}` | *(fill during setup)* |
| `{{FLOW_DESCRIPTION}}` | *(fill during setup)* |
| `{{PROJECT_CORE_VALUE}}` | *(fill during setup)* |
| `{{SETUP_DATE}}` | *(fill during setup)* |
| `{{EXTRA_METRIC_NAME}}` | *(delete row if not applicable)* |

### User Preferences

*(Populated during setup from interview responses — see SETUP.md §0d.)*

---

*See also: `.github/agents/` (model-pinned VS Code agents) · `.copilot/workspace/` (session identity) · `UPDATE.md` (update protocol) · `AGENTS.md` (AI agent entry point)*
