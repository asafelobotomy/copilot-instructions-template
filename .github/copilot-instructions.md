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

#### Extension Review
When asked to review or recommend VS Code extensions:

1. **Audit current state**:
   - Read `.vscode/extensions.json` (workspace recommendations).
   - Check `.vscode/settings.json` for extension-specific config.
   - Scan for format/lint commands in `package.json` scripts, `{{TEST_COMMAND}}`, and tooling config files (`.eslintrc.*`, `.prettierrc.*`, `oxlint.json`, etc.).

2. **Match to stack**:
   - Language/runtime: `{{LANGUAGE}}` / `{{RUNTIME}}`
   - Identified linters/formatters from step 1
   - Test framework: `{{TEST_FRAMEWORK}}`
   - Package manager: `{{PACKAGE_MANAGER}}`

3. **Recommend additions** — suggest extensions only if:
   - A linter, formatter, or language server is configured but its extension is missing
   - A core language feature (e.g., shellcheck for bash, oxc for JS/TS) is unrepresented
   - Priority order: language server → linter → formatter → test runner → debugger

4. **Flag for removal** — mark extensions that:
   - Provide functionality duplicated by another installed extension
   - Target a language/framework not used in this project
   - Are deprecated, unmaintained (>2 years no update), or superseded

5. **Present in chat** (do not write `.vscode/extensions.json` unless explicitly instructed):

```markdown
## Extension Review — {{PROJECT_NAME}}

### ✅ Keep (N extensions)
- `publisher.extension-id` — reason to keep

### ➕ Recommended additions (N extensions)
- `publisher.extension-id` — what it provides | why needed
  Install: Ctrl+P → `ext install publisher.extension-id`

### ❌ Consider removing (N extensions)
- `publisher.extension-id` — why flagged (duplicate / unused lang / deprecated)

### ℹ️ Notes
- (any stack-specific context, e.g., "oxlint configured but not oxc extension installed")
```

6. **Wait for user action** — present recommendations, then wait. Do not modify `.vscode/extensions.json` or install/uninstall extensions unless the user explicitly says *"Apply these changes"* or *"Write the updated extensions.json"*.

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
- Each subagent inherits the full Tool Protocol (§11) — check the toolbox before building, search before coding, and flag any proposed toolbox saves to the parent.
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

## §11 — Tool Protocol

When a task requires automation, a scripted command sequence, or a repeatable utility, follow this decision tree before writing anything ad-hoc.

### Decision tree

```
Need a tool for task X
 │
 ├─ 1. FIND — check .copilot/tools/INDEX.md
 │     ├─ Exact match  → USE IT directly
 │     ├─ Close match  → ADAPT (fork, rename, note source in comment at top of file)
 │     └─ No match     → ↓
 │
 ├─ 2. SEARCH online (try in order)
 │     a. MCP server registry  github.com/modelcontextprotocol/servers
 │     b. GitHub search        github.com/search?type=repositories&q=<task>
 │     c. Awesome lists        awesome-cli-apps · awesome-shell · awesome-python · awesome-rust · awesome-go
 │     d. Stack registry       npmjs.com / pypi.org / crates.io / pkg.go.dev
 │     e. Official CLI docs    git · docker · gh · jq · ripgrep · sed · awk (built-ins first)
 │     ├─ Found something usable → evaluate fit, adapt as needed, note source
 │     └─ Nothing applicable → ↓
 │
 ├─ 2.5 COMPOSE — can this be assembled from 2+ existing toolbox tools via pipe or import?
 │     ├─ Yes → compose; document the pipeline; save to toolbox if reusable
 │     └─ No  → ↓
 │
 └─ 3. BUILD — write the tool from scratch
          - Follow §4 coding conventions and §3 LOC baselines
          - Single-purpose: one tool, one job; compose via pipes or imports
          - Accept arguments instead of hardcoding project-specific paths
          - Required inline header at the top of every built or saved tool:
            # purpose:  <what this tool does — one precise sentence>
            # when:     <when to invoke it | when NOT to invoke it>
            # inputs:   <argument list with types and valid values>
            # outputs:  <what it returns — type and structure>
            # risk:     safe | destructive
            # source:   <url or "original" if built from scratch>
          │
          └─ 4. EVALUATE reusability
                ├─ ≥ 2 distinct tasks in this project would benefit → SAVE to toolbox
                │   a. Place file in .copilot/tools/<kebab-name>.<ext>
                │   b. Add a row to .copilot/tools/INDEX.md (see format below)
                │   c. Append to JOURNAL.md: `[tool] <name> added to toolbox — <one-line reason>`
                └─ Single-use / too project-specific → use inline only; do not save
```

### Toolbox

`.copilot/tools/` is created on first tool save (no setup step required). Contents:

| File | Purpose |
|------|---------|
| `INDEX.md` | Tool catalogue — always kept current |
| `*.sh` | Shell / bash tools |
| `*.py` | Python tools |
| `*.js` / `*.ts` | Node / Deno tools |
| `*.mcp.json` | MCP server configurations |

**INDEX.md row format**:

| Tool | Lang | What it does | When to use | Output | Risk |
|------|------|-------------|------------|--------|------|
| `count-exports.sh` | bash | Count exported symbols per file | API surface audits | symbol counts to stdout | safe |
| `summarise-metrics.py` | python | Parse METRICS.md and print trends | Kaizen review sessions | trend table to stdout | safe |

### Tool quality rules

**Naming** — Tool names must be a verb-noun kebab phrase describing the action (`count-exports`, `sync-schema`), not a noun or generic label (`exports`, `utils`).

**Description anti-smells** — poor descriptions are the leading cause of incorrect tool selection and argument errors (empirically confirmed across 856 real-world MCP tools). Every tool header must avoid these six smells:

| Smell | Anti-pattern | Fix |
|-------|-------------|-----|
| Unclear purpose | "handles export stuff" | One sentence stating exactly what it does and what it returns |
| Missing usage guidelines | no when/when-not-to | Explicit activation criteria AND contraindications |
| Unstated limitations | silent failure modes | Note scope bounds, volume limits, known edge cases |
| Opaque parameters | `--mode <value>` | Type + valid values + behavioural effect for every argument |
| Missing output declaration | result undocumented | Declare type and structure in `# outputs:` header field |
| Underspecified length | one-line stub | ≥ 3 substantive sentences for any non-trivial tool |

**Risk tier**:
- `safe` — read-only or fully idempotent; invoke without confirmation
- `destructive` — deletes files, overwrites data, or writes to remote systems; **must pause and confirm with the user before execution**, regardless of session autonomy level

**Other rules**:
- Adapted tools: preserve lineage — `# source: <url-or-original-tool-name>`
- Tools must be idempotent where possible
- Tools must not hardcode project-specific paths, names, or secrets — accept arguments
- Retire unused tools: mark `[DEPRECATED]` in INDEX.md; counts as W1 (Overproduction)
- Tools follow the same LOC baseline as source code (§3 hard limit: {{LOC_HIGH_THRESHOLD}} lines)
- Observability: after using a toolbox tool, note it in the session summary; ≥ 3 uses → document the workflow in `TOOLS.md` "Discovered workflow patterns"

### Subagent tool use

Subagents inherit this protocol fully. A subagent may build or adapt a tool independently. To **save** a tool to the toolbox, the subagent must first flag the proposal to the parent agent, which confirms before any write to `.copilot/tools/`.

---

*See also: `.github/agents/` (model-pinned VS Code agents) · `.copilot/workspace/` (session identity) · `.copilot/tools/` (reusable tool library) · `UPDATE.md` (update protocol) · `AGENTS.md` (AI agent entry point)*
