# Copilot Instructions — {{PROJECT_NAME}}

> **Template version**: 1.0.0 | **Applied**: {{SETUP_DATE}}
> This file is a *living document*. See §8 for self-edit rules and template update instructions.

> **Model Quick Reference** *(for the human — not the AI)* — select a model in the Copilot picker before starting a task, or use the pre-configured agents in `.github/agents/` (VS Code 1.106+ only). [Why these models?](https://docs.github.com/en/copilot/reference/ai-models/model-comparison)
>
> | Task | Best model (Pro+) | Budget / Free fallback |
> |------|------------------|----------------------|
> | Setup / onboarding | Claude Sonnet 4.6 | GPT-5 mini |
> | General coding | GPT-5.1-Codex | GPT-4.1 |
> | Agentic / multi-step tasks | GPT-5.1-Codex-Max | GPT-5 mini |
> | Deep reasoning & debugging | Claude Opus 4.6 *(3×)* → Claude Sonnet 4.6 *(1×)* | GPT-5 mini |
> | Code review | Claude Opus 4.6 *(3×)* → Claude Sonnet 4.6 *(1×)* | GPT-4.1 |
> | Quick questions / lightweight | Claude Haiku 4.5 *(0.33×)* | GPT-5 mini |
>
> **Note**: Model availability and names change frequently. If a model is missing from your picker, check [Supported AI models](https://docs.github.com/en/copilot/reference/ai-models/supported-models) and update the agent files accordingly.

---

## 1. Development Philosophy — Lean / Kaizen

Five core lean principles govern every agent mode and every session:

| # | Principle | In practice |
|---|-----------|-------------|
| 1 | **Define Value** | Features that improve {{PROJECT_CORE_VALUE}} are value. Abstractions, indirection, and speculative structure are cost. |
| 2 | **Map the Value Stream** | {{VALUE_STREAM_DESCRIPTION}} |
| 3 | **Create Flow** | {{FLOW_DESCRIPTION}} |
| 4 | **Establish Pull** | YAGNI. Tools and abstractions are added *only* when demonstrably needed; not anticipated. |
| 5 | **Pursue Perfection** | Every session moves baselines in the right direction. The daily kaizen checklist is the proof. |

### PDCA Cycle (mandatory for every non-trivial change)

- **Plan** — analyse, research, and produce a structured plan before touching code.
- **Do** — implement in the smallest meaningful batch.
- **Check** — run `{{THREE_CHECK_COMMAND}}` and confirm all baselines are green.
- **Act** — update documentation, capture the learning, codify any new pattern.

---

## 2. Agent Modes

### Plan Mode (research-only)

- Research, analyse, and produce a structured plan with file references, steps, and verification criteria.
- **DO NOT make code changes.**
- Kaizen behaviour: before proposing, identify which waste category the current problem falls into (see §6).
- Output format: numbered step list, estimated LOC delta, files affected.

### Implement Mode *(default)*

- Full PDCA cycle is mandatory.
- Three-check ritual after every change: `{{THREE_CHECK_COMMAND}}`
- Write or update tests *alongside* every code change — never after.
- Follow existing patterns in the codebase (see §4 — Coding Conventions).
- Update `BIBLIOGRAPHY.md` if a file is created, renamed, or deleted.

### Review Mode (analysis-only)

- Analyse code quality, architecture constraints, and correctness.
- Check import boundaries, {{LOC_WARN_THRESHOLD}}-line advisory limits, test coverage, and documentation completeness.
- **DO NOT make code changes.**
- Output: structured review with specific file/line references and waste category tags.

### Refactor Mode (structure improvement)

- Improve code structure while preserving observable behaviour.
- Small, incremental changes; run `{{TEST_COMMAND}}` after each.
- Applies one of the four standard improvement patterns per pass:
  1. **Extract-and-Simplify** — file exceeds {{LOC_HIGH_THRESHOLD}} lines.
  2. **Reduce-Duplication** — same pattern appears in ≥ 3 places.
  3. **Strengthen-Types** — loose types (`any`, `unknown`, untyped dicts, etc.) → precise interfaces.
  4. **Improve-Descriptions** — a tool/function is misused because its description is unclear.

---

## 3. Standardised Work Baselines

| Metric | Green ✅ | Warn ⚠️ | High 🔴 |
|--------|---------|--------|--------|
| LOC per file | < {{LOC_WARN_THRESHOLD}} | {{LOC_WARN_THRESHOLD}}–{{LOC_HIGH_THRESHOLD}} | > {{LOC_HIGH_THRESHOLD}} |
| Runtime dependencies | ≤ {{DEP_BUDGET}} | {{DEP_BUDGET_WARN}} | > {{DEP_BUDGET_WARN}} |
| Test count | growing | stable | declining |
| Type / lint errors | 0 | — | > 0 |
| {{EXTRA_METRIC_NAME}} | {{EXTRA_METRIC_GREEN}} | {{EXTRA_METRIC_WARN}} | {{EXTRA_METRIC_RED}} |

Baselines are captured in `METRICS.md`. Run `{{METRICS_COMMAND}}` to produce a new snapshot row.

---

## 4. Coding Conventions

### Language & Runtime

- **Language**: {{LANGUAGE}}
- **Runtime / platform**: {{RUNTIME}}
- **Package manager**: {{PACKAGE_MANAGER}}

### Key patterns in this codebase

{{CODING_PATTERNS}}

### Anti-patterns (never do these)

- No speculative abstraction (YAGNI).
- No raw secrets or API keys in committed files.
- No custom binary protocols — use {{PREFERRED_SERIALISATION}}.
- Do not introduce a new runtime dependency without first checking the dep budget.
- Do not suppress type errors with casts/ignores — fix the root cause.

---

## 5. Testing

- **Framework**: {{TEST_FRAMEWORK}}
- **Run tests**: `{{TEST_COMMAND}}`
- **Run type check**: `{{TYPE_CHECK_COMMAND}}`
- **Run LOC scan**: `{{LOC_COMMAND}}`
- **Three-check ritual**: `{{THREE_CHECK_COMMAND}}`

Rules:
- Every new public function, method, or module gets at least one test.
- Architecture / boundary tests are **advisory** — they warn but do not block CI.
- Integration tests requiring live infrastructure are gated by an environment variable: `{{INTEGRATION_TEST_ENV_VAR}}`.

---

## 6. Waste Categories (Muda)

When diagnosing problems or reviewing code, tag findings with the relevant waste category:

| # | Category | Example in code |
|---|----------|-----------------| 
| 1 | Overproduction | Building abstractions for requirements that don't exist yet |
| 2 | Waiting | Sync I/O blocking an async pipeline; slow tests blocking feedback |
| 3 | Transport | Unnecessary data transformation steps between layers |
| 4 | Over-processing | Parsing the same input twice; re-computing stable values |
| 5 | Inventory | Dead code, unused exports, stale comments, obsolete docs |
| 6 | Motion | Developers repeatedly searching for conventions not written down |
| 7 | Defects | Type errors, failing tests, silent behaviour divergence |

---

## 7. Documentation Update Ritual *(Act phase)*

After *every* meaningful change, apply this checklist:

- [ ] `CHANGELOG.md` — always; even small fixes get an `[Unreleased]` entry.
- [ ] `JOURNAL.md` — if an architectural decision was made, record it as an ADR entry.
- [ ] `BIBLIOGRAPHY.md` — if a file was created, renamed, deleted, or its purpose changed.
- [ ] `METRICS.md` — if the change affects LOC totals, test count, or dep count; append a snapshot row.
- [ ] `.github/copilot-instructions.md` — if a new stable pattern emerged (see §8 below).

---

## 8. Living Update Protocol

This instructions file is **self-referential** — Copilot is authorised to edit it when *any* trigger condition below is met:

### Self-edit trigger conditions

| Trigger | Condition |
|---------|----------|
| **Pattern stabilisation** | A convention has appeared identically in ≥ 3 separate sessions → add it to §4. |
| **Guideline retirement** | An existing guideline demonstrably caused wasted work (waste category 6 — Motion) → revise or remove it. |
| **Retrospective session** | A session explicitly titled "retrospective" or "instructions review" → open review of the whole file. |

### Self-edit procedure

1. Make the minimal change to this file needed to codify the pattern or fix the guideline.
2. Write a one-line entry in `JOURNAL.md` under today's date:
   ```
   [instructions] <what changed> — reason: <why>
   ```
3. Add a `[Unreleased]` entry in `CHANGELOG.md` tagged `[instructions]`.
4. Do **not** change the template version number — that belongs to the upstream template repo.

### Prohibited self-edits

- Do not change the five Lean principles (§1) — they are methodology, not convention.
- Do not change the PDCA cycle definition.
- Do not change this Living Update Protocol without an explicit user request.

### Template updates (from upstream)

To fetch and apply improvements from the upstream template repository, say:

> *"Update your instructions"*

Copilot will:
1. Read the installed version stamp from the top of this file.
2. Fetch the update protocol from:
   ```
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/UPDATE.md
   ```
3. Follow that protocol — comparing this file section-by-section against the latest template, presenting a Pre-flight Report, and asking for confirmation before writing anything.

**Guaranteed protections during any template update:**
- `## 10. Project-Specific Overrides` — never touched.
- `### User Preferences` — never touched.
- Any block containing `<!-- migrated -->` or `<!-- user-added -->` — never touched.
- All resolved placeholder values — never reverted to `{{PLACEHOLDER}}` tokens.

---

## 9. Subagent Delegation

- `run_subagent` / equivalent: always specify a mode (`plan`, `implement`, `review`, `refactor`).
- `plan` and `review` subagents receive **read-only** tool access.
- Maximum recursion depth: **{{SUBAGENT_MAX_DEPTH}}** levels.
- Compact protocol: subagents return structured JSON (`{ plan, rationale, files_affected, verification_steps }`).
- Parent agent is responsible for implementing what the plan subagent returns.

---

## 10. Project-Specific Overrides

> *This section is populated by the setup process and updated by Copilot as the project evolves. It takes precedence over any generic statement in sections 1–9.*

### Resolved placeholders

| Placeholder | Resolved value |
|-------------|----------------|
| `{{PROJECT_NAME}}` | {{PROJECT_NAME}} |
| `{{LANGUAGE}}` | {{LANGUAGE}} |
| `{{RUNTIME}}` | {{RUNTIME}} |
| `{{PACKAGE_MANAGER}}` | {{PACKAGE_MANAGER}} |
| `{{TEST_COMMAND}}` | {{TEST_COMMAND}} |
| `{{TYPE_CHECK_COMMAND}}` | {{TYPE_CHECK_COMMAND}} |
| `{{LOC_COMMAND}}` | {{LOC_COMMAND}} |
| `{{THREE_CHECK_COMMAND}}` | {{THREE_CHECK_COMMAND}} |
| `{{METRICS_COMMAND}}` | {{METRICS_COMMAND}} |
| `{{LOC_WARN_THRESHOLD}}` | {{LOC_WARN_THRESHOLD}} |
| `{{LOC_HIGH_THRESHOLD}}` | {{LOC_HIGH_THRESHOLD}} |
| `{{DEP_BUDGET}}` | {{DEP_BUDGET}} |
| `{{DEP_BUDGET_WARN}}` | {{DEP_BUDGET_WARN}} |
| `{{TEST_FRAMEWORK}}` | {{TEST_FRAMEWORK}} |
| `{{INTEGRATION_TEST_ENV_VAR}}` | {{INTEGRATION_TEST_ENV_VAR}} |
| `{{PREFERRED_SERIALISATION}}` | {{PREFERRED_SERIALISATION}} |
| `{{SUBAGENT_MAX_DEPTH}}` | {{SUBAGENT_MAX_DEPTH}} |
| `{{VALUE_STREAM_DESCRIPTION}}` | {{VALUE_STREAM_DESCRIPTION}} |
| `{{FLOW_DESCRIPTION}}` | {{FLOW_DESCRIPTION}} |
| `{{PROJECT_CORE_VALUE}}` | {{PROJECT_CORE_VALUE}} |

### Additional project notes

*(Copilot appends discovered conventions here as they stabilise.)*

---

## See also

- `JOURNAL.md` — architectural decision record
- `BIBLIOGRAPHY.md` — complete file map
- `METRICS.md` — baseline snapshots
- `.copilot/workspace/` — agent workspace identity files
- `.github/agents/` — model-pinned task agents (VS Code 1.106+)
