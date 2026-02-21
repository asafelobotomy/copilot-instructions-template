# Copilot Instructions — {{PROJECT_NAME}}

> **Template version**: 1.1.0 | **Applied**: {{SETUP_DATE}}
> Living document — self-edit rules in §8.
>
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
> **⚠️ Codex models** (`GPT-5.x-Codex`) are designed for **autonomous, headless execution** and **cannot** present interactive prompts. Never use a Codex model for Setup/onboarding — the interview will be silently skipped. The Setup agent pins Claude Sonnet 4.6 for this reason.
>
> If a model is missing from your picker, check [Supported AI models](https://docs.github.com/en/copilot/reference/ai-models/supported-models) and update agent files.

---

## §1 — Lean Principles

| # | Principle | This project |
|---|-----------|-------------|
| 1 | Eliminate waste (Muda) | Every line of code has a cost; every unused feature is waste |
| 2 | Map the value stream | {{VALUE_STREAM_DESCRIPTION}} |
| 3 | Create flow | {{FLOW_DESCRIPTION}} |
| 4 | Establish pull | Build only what is needed, when it is needed |
| 5 | Seek perfection | Small, continuous improvements (Kaizen) over big rewrites |

**Waste taxonomy** (§6):

- Overproduction · Waiting · Transport · Over-processing · Inventory · Motion · Defects · Unused talent

---

## §2 — Operating Modes

Switch modes explicitly. Default is **Implement**.

### Implement Mode (default)

- Plan → implement → test → document in one uninterrupted flow.
- Full PDCA for every non-trivial change.
- Three-check ritual before marking a task complete.
- Update `BIBLIOGRAPHY.md` on every file create/rename/delete.

### Review Mode

- Read-only by default. State findings before proposing fixes.
- Tag every finding with a waste category (§6).
- Use format: `[severity] | [file:line] | [waste category] | [description]`
- Severity: `critical` | `major` | `minor` | `advisory`

#### Extension Review

When asked to review or recommend VS Code extensions:

0. **Get installed extensions** — ask user to run and paste (Copilot cannot enumerate installed extensions directly):

   ```shell
   code --list-extensions | sort
   ```

   Also read `.vscode/extensions.json` and `.vscode/settings.json` if they exist.

1. **Audit current state**:
   - Cross-reference the installed list from step 0 against workspace recommendations.
   - Scan for linter/formatter config files: `.eslintrc.*`, `.prettierrc.*`, `oxlint.json`, `biome.json`, `.stylelintrc.*`, `ruff.toml`, `pyproject.toml`, `rustfmt.toml`, etc.
   - Check `package.json` scripts and `{{TEST_COMMAND}}` for tooling references.

2. **Match to stack** — use the detection table below; also check `{{LANGUAGE}}` / `{{RUNTIME}}` / `{{TEST_FRAMEWORK}}` / `{{PACKAGE_MANAGER}}` placeholders:

   | Stack signals | Recommended extensions |
   |--------------|------------------------|
   | `*.sh`, `*.bash`, `#!/bin/bash` shebang | `timonwong.shellcheck` · `foxundermoon.shell-format` |
   | `*.js`, `*.ts`, `package.json` + ESLint config | `dbaeumer.vscode-eslint` · `esbenp.prettier-vscode` |
   | `*.js`, `*.ts`, `oxlint.json` or `oxlint` in scripts | `oxc.oxc-vscode` *(covers oxlint + oxfmt — one extension)* |
   | `*.js`, `*.ts`, `biome.json` | `biomejs.biome` |
   | `*.py`, `requirements.txt`, `pyproject.toml` | `ms-python.python` · `charliermarsh.ruff` |
   | `*.rs`, `Cargo.toml` | `rust-lang.rust-analyzer` · `tamasfe.even-better-toml` |
   | `*.go`, `go.mod` | `golang.go` |
   | `*.cs`, `*.csproj`, `*.sln` | `ms-dotnettools.csharp` |
   | `*.java`, `pom.xml`, `build.gradle` | `vscjava.vscode-java-pack` |
   | `Dockerfile`, `docker-compose.yml` | `ms-azuretools.vscode-docker` |
   | `*.vue`, `vue.config.*` | `Vue.volar` |
   | `*.svelte`, `svelte.config.*` | `svelte.svelte-vscode` |
   | `*.md`, `*.mdx` (doc-heavy project) | `yzhang.markdown-all-in-one` |
   | `*.css`, `*.scss`, `*.less` + stylelint config | `stylelint.vscode-stylelint` |
   | `*.yaml`, `*.yml` (Kubernetes, Actions, schemas) | `redhat.vscode-yaml` |
   | `*.toml` (non-Rust project) | `tamasfe.even-better-toml` |

3. **Recommend additions** — suggest extensions only if:
   - A linter, formatter, or language server is configured but its extension is absent
   - A core language feature is unrepresented
   - Priority order: language server → linter → formatter → test runner → debugger

4. **Flag for removal** — mark extensions that:
   - Duplicate functionality provided by another installed extension
   - Target a language/framework not used in this project
   - Are deprecated, unmaintained (>2 years no update), or superseded

5. **Unknown stacks** — if you detect a language, framework, or tool not in the table above:
   a. Search the VS Code Marketplace for relevant extensions
   b. Qualify by: install count > 100 k · rating ≥ 4.0 · updated within 12 months
   c. Add qualifying finds to the report under **➕ Recommended additions**
   d. Append the new mapping to `.copilot/workspace/TOOLS.md` under **"Extension registry"**

6. **Present in chat**:

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
   - (stack-specific context, unknown stacks discovered, extension registry updates made)
   ```

7. **Wait** — do not modify `.vscode/extensions.json` or install/uninstall extensions until user says *"Apply these changes"* or *"Write the updated extensions.json"*.

#### Test Coverage Review

When asked to review test coverage, recommend tests, or audit the test suite:

0. **Discover test stack** — scan for test config files and runner signals:

   | Stack signals | Test runner | Coverage command |
   |--------------|-------------|-----------------|
   | `jest.config.*`, `"jest"` in `package.json` | Jest | `npx jest --coverage` |
   | `vitest.config.*`, `"vitest"` in `package.json` | Vitest | `npx vitest run --coverage` |
   | `mocha`, `.mocharc.*` in project | Mocha + nyc | `npx nyc mocha` |
   | `pytest.ini`, `pyproject.toml` [pytest], `conftest.py` | pytest | `pytest --cov=. --cov-report=term-missing` |
   | `go.mod` | go test | `go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out` |
   | `Cargo.toml` | cargo test | `cargo tarpaulin --out Lcov` · `cargo llvm-cov` |
   | `*.csproj`, `*.sln` | dotnet test | `dotnet test --collect:"XPlat Code Coverage"` |
   | `pom.xml` (Maven) | JUnit + JaCoCo | `mvn test jacoco:report` |
   | `build.gradle` (Gradle) | JUnit + JaCoCo | `./gradlew test jacocoTestReport` |
   | `*.spec.rb`, `Gemfile` + rspec | RSpec + SimpleCov | `bundle exec rspec --format progress` |

   Also read `{{TEST_COMMAND}}`, `{{TEST_FRAMEWORK}}`, and `.github/workflows/` for configured test steps.

1. **Get coverage data** — cannot run commands directly. Ask user to run the step-0 command and paste output. If no tooling exists, note it and proceed with step 2 (static analysis).

2. **Scan test files statically**:
   - Count test files (`*.test.*`, `*.spec.*`, `*_test.*`, `test_*.py`, `*Test.java`, `*_test.go`, etc.)
   - List source files that have no corresponding test file
   - Note which modules are imported the most — high-import modules with no tests are highest priority

3. **Identify gaps** from coverage data (or static scan if no coverage data):
   - **Zero coverage** — files/modules with 0% (or no test file at all)
   - **Low coverage** — files with < 50% line coverage
   - **Missing test types** — no integration tests, no edge-case tests, untested error paths
   - **Unchecked invariants** — functions that take user input, do I/O, or mutate state without assertions

4. **Recommend local tests** — for each gap, recommend:
   - **What to test**: specific function, class, or behaviour
   - **Test type**: unit · integration · end-to-end · property-based · snapshot
   - **Priority**: `critical` (security/data path) · `high` (core logic) · `medium` (utilities) · `low` (pure formatting)
   - **Suggested approach**: brief description of the test case incl. edge inputs

5. **Recommend CI workflows** — propose GitHub Actions to add or improve:

   | Workflow | What it does | Action / Tool |
   |----------|-------------|--------------|
   | Coverage gate | Fail PR if overall coverage drops below threshold | `codecov/codecov-action@v4` with `fail_ci_if_error: true` |
   | Coverage diff comment | Post per-PR coverage change as a PR comment | `davelosert/vitest-coverage-report-action` (Vitest) · `MishaKav/jest-coverage-comment` (Jest) · `py-cov-action/python-coverage-comment-action` (Python) |
   | Nightly coverage report | Full run on schedule for slower suites | `schedule: cron` trigger |
   | Test matrix | Run against multiple runtime versions | `strategy.matrix` with version array |
   | Mutation testing | Verify test quality, not just line coverage | Stryker (`stryker-mutator/action`) (JS/TS) · mutmut (Python) · `cargo-mutants` (Rust) |
   | Contract / API tests | Validate API contracts don't break consumers | `pactflow/pact-stub-server` · Schemathesis |

   For each recommendation: include a ready-to-use YAML snippet the user can copy directly into `.github/workflows/`.

6. **Present in chat**:

   ````markdown
   ## Test Coverage Review — {{PROJECT_NAME}}

   ### 📊 Current coverage snapshot
   - Framework: <framework> | Runner: `<command>`
   - Overall coverage: X% (or "not yet measured — run `<cmd>` and paste output")
   - Test files found: N | Source files without tests: M

   ### ✅ Well-covered (≥ 80%)
   - `src/foo.ts` — 92%

   ### ⚠️ Partially covered (20–79%)
   - `src/bar.ts` — 54% — missing: error branch at line 42, null-input guard

   ### ❌ Untested or near-zero (< 20%)
   - `src/baz.ts` — 0% — **critical**: handles user auth input

   ### 🧪 Recommended local tests
   | File | Test type | Priority | What to cover |
   |------|-----------|----------|--------------|
   | `src/baz.ts` | Unit | critical | Happy path, null input, token expiry |
   | `src/bar.ts` | Unit | high | Error branch at line 42 |

   ### ⚙️ Recommended CI workflows
   **Coverage gate** — fail PR if coverage < 80%:
   ```yaml
   # .github/workflows/coverage.yml  (paste this file)
   <ready-to-use YAML snippet>
   ```

   **Coverage comments on PRs**:
   ```yaml
   <ready-to-use YAML snippet>
   ```

   ### ℹ️ Notes
   - <framework-specific context, tooling gaps, coverage tooling not yet installed>
   ````

7. **Wait** — do not write test files, workflow files, or config until user explicitly asks.

### Refactor Mode

- No behaviour changes. Tests must pass before and after.
- Measure LOC delta. Flag if a refactor increases LOC without justification.

### Planning Mode

- Produce a task breakdown before writing code.
- Estimate complexity (S/M/L/XL). Flag anything XL for decomposition.

---

## §3 — Standardised Work Baselines

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
- No silent error swallowing — log or re-throw.
- No commented-out code — git history is the undo stack.
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
| W9 | Prompt waste | Vague instructions requiring re-prompting; prompt too long for task complexity |
| W10 | Context window waste | Exceeding token budget with irrelevant files; stale context degrading output quality |
| W11 | Hallucination rework | Accepting generated code without verification; debugging phantom APIs or methods |
| W12 | Verification overhead | Testing obvious transformations; re-running passing checks without cause |
| W13 | Prompt engineering debt | Overgrown instruction files where key rules are ignored; no skill extraction from successful patterns |
| W14 | Model-task mismatch | Using Opus for a rename; using Haiku for architectural planning |
| W15 | Tool friction | Manual file reads when codebase search suffices; missing MCP integration for available services |
| W16 | Over/under-trust | Blindly accepting all suggestions; reviewing every single-line change manually |

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
- Each subagent inherits the full Tool Protocol (§11) and Skill Protocol (§12) — check the toolbox before building, search before coding, and flag any proposed toolbox saves to the parent.
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
| `{{SKILL_SEARCH_PREFERENCE}}` | local-only |
| `{{EXTRA_METRIC_NAME}}` | *(delete row if not applicable)* |

### User Preferences

*(Populated during setup from interview responses — see SETUP.md §0d.)*

| Dimension | Setting | Instruction |
|-----------|---------|-------------|
| Response style | *(S1)* | |
| Experience level | *(S2)* | |
| Primary mode | *(S3)* | |
| Testing | *(S4)* | |
| Autonomy | *(S5)* | |
| Code style | *(A6)* | |
| Documentation | *(A7)* | |
| Error handling | *(A8)* | |
| Security | *(A9)* | |
| File size discipline | *(A10)* | |
| Dependency management | *(A11)* | |
| Instruction self-editing | *(A12)* | |
| Refactoring appetite | *(A13)* | |
| Reporting format | *(A14)* | |
| Skill search | *(A15)* | |
| Tool availability | *(E16)* | |
| Agent persona | *(E17)* | |
| VS Code settings | *(E18)* | |
| Global autonomy | *(E19)* | |
| Mood lightener | *(E20)* | |

---

## §11 — Tool Protocol

When a task requires automation, a scripted command sequence, or a repeatable utility, follow this decision tree before writing anything ad-hoc.

### Decision tree

```text
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

Files: `INDEX.md` (catalogue) · `*.sh` · `*.py` · `*.js`/`*.ts` · `*.mcp.json`

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

- Tools must be idempotent where possible
- Tools must not hardcode project-specific paths, names, or secrets — accept arguments
- Retire unused tools: mark `[DEPRECATED]` in INDEX.md; counts as W1 (Overproduction)
- Tools follow the same LOC baseline as source code (§3 hard limit: {{LOC_HIGH_THRESHOLD}} lines)
- Observability: after using a toolbox tool, note it in the session summary; ≥ 3 uses → document the workflow in `TOOLS.md` "Discovered workflow patterns"

### Subagent tool use

Subagents inherit this protocol fully. A subagent may build or adapt a tool independently. To **save** a tool to the toolbox, the subagent must first flag the proposal to the parent agent, which confirms before any write to `.copilot/tools/`.

---

## §12 — Skill Protocol

Skills are reusable markdown-based **behavioural instructions** that teach the agent *how* to perform a specific workflow. Unlike tools (§11) which are executable scripts, skills are declarative — they shape the agent's approach rather than running code.

Skills follow the [Agent Skills](https://agentskills.io) open standard. Each skill is a `SKILL.md` file with YAML frontmatter and a markdown body containing step-by-step workflow instructions.

### Skill anatomy

```yaml
---
name: <short name>
description: <one-sentence summary — used for discovery matching>
version: "1.0"
license: MIT
tags: [<keyword>, <keyword>]
---

<markdown body with step-by-step workflow instructions>
```

Required fields: `name`, `description`. All others are optional.

### Discovery and activation

Skills are loaded **on demand** — the agent reads a skill's `SKILL.md` only when the `description` field matches the current task context. Do not pre-load all skills.

```text
Task requires a workflow
 │
 ├─ 1. SCAN — check .github/skills/*/SKILL.md descriptions
 │     ├─ Match found  → READ the full SKILL.md, follow its instructions
 │     └─ No match     → ↓
 │
 ├─ 2. SEARCH (if enabled by {{SKILL_SEARCH_PREFERENCE}})
 │     ├─ "official-only"   → search official skill repositories:
 │     │     a. github.com/anthropics/skills
 │     │     b. github.com/openai/skills
 │     │     c. github.com/github/awesome-copilot
 │     │     d. agentskills.io/registry (when available)
 │     │     ├─ Found → evaluate fit, adapt, save locally
 │     │     └─ Not found → ↓
 │     │
 │     ├─ "official-and-community" → search official repos (above) THEN:
 │     │     e. github.com/search?type=repositories&q=agent+skill+<topic>
 │     │     f. Community lists: awesome-agent-skills, huggingface/skills
 │     │     ├─ Found → evaluate fit, quality-check (see below), adapt, save locally
 │     │     └─ Not found → ↓
 │     │
 │     └─ "local-only" (default) → skip online search entirely → ↓
 │
 └─ 3. CREATE — author a new skill from scratch
       - Follow the authoring rules below
       - Save to .github/skills/<kebab-name>/SKILL.md
       - Append to JOURNAL.md: `[skill] <name> created — <one-line reason>`
```

### Scope hierarchy

Skills are resolved in priority order:

| Priority | Location | Scope |
|----------|----------|-------|
| 1 (highest) | `.github/skills/<name>/SKILL.md` | Project — checked into version control |
| 2 | `~/.copilot/skills/<name>/SKILL.md` | Personal — shared across all projects for one user |

Project skills always override personal skills with the same name.

### Community skill quality gate

Before adopting a community-sourced skill (search tier "official-and-community"), verify:

- [ ] Repository has ≥ 50 stars or is from a recognised organisation
- [ ] `SKILL.md` has both `name` and `description` in frontmatter
- [ ] Instructions are clear, specific, and non-destructive
- [ ] No embedded credentials, tokens, or suspicious URLs
- [ ] License is permissive (MIT, Apache 2.0, CC-BY)

Reject any skill that fails two or more checks. For borderline cases, present the skill to the user for review before adopting.

### Authoring rules

When creating or adapting a skill:

1. **One skill, one workflow** — a skill does one thing well. If you need "and", split it.
2. **Description is the index** — write a precise one-sentence description; this is how the agent discovers the skill.
3. **Steps, not prose** — use numbered steps with clear action verbs. The agent follows these literally.
4. **No hardcoded paths** — use relative references and contextual lookups, not project-specific paths.
5. **Idempotent** — running the skill twice should produce the same result.
6. **Test instructions** — include a "Verify" step at the end that confirms the skill completed correctly.
7. **Tag for discovery** — use 2–5 tags that match common task descriptions.

### Lifecycle

| Event | Action |
|-------|--------|
| Skill created | Save to `.github/skills/`, log in JOURNAL.md |
| Skill used 3+ times | Promote: consider contributing upstream |
| Skill unused for 3 months | Flag for review; mark `[DEPRECATED]` if no longer relevant |
| Skill from online source | Adapt to project conventions before saving locally |

### Skill vs. Tool

| Aspect | Skill (§12) | Tool (§11) |
|--------|------------|------------|
| Format | Markdown (`SKILL.md`) | Executable script (`.sh`, `.py`, `.js`) |
| Purpose | Teach *how* to approach a workflow | Automate a specific *action* |
| Invocation | Agent reads and follows instructions | Agent executes the script |
| Location | `.github/skills/` | `.copilot/tools/` |
| Composable | Skills can reference tools | Tools don't reference skills |

### Subagent skill use

Subagents inherit this protocol fully. A subagent may read and follow any project or personal skill. To **create** a new skill, the subagent must flag the proposal to the parent agent, which confirms before any write to `.github/skills/`.

---

*See also: `.github/agents/` (model-pinned VS Code agents) · `.copilot/workspace/` (session identity) · `.copilot/tools/` (reusable tool library) · `.github/skills/` (reusable skill library) · `UPDATE.md` (update protocol) · `AGENTS.md` (AI agent entry point)*
