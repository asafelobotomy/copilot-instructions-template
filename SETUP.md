# Copilot Setup — Run Once

> **Instructions for Copilot**: This file defines a one-time setup process. Read every step carefully before starting. Tell the user what you are about to do and wait for confirmation before deleting this file at the end.
>
> **Instructions for the human**: Open a Copilot chat and say: *"Please run the setup process described in SETUP.md."* Copilot will do the rest.

---

## Prerequisites check

Before starting, confirm:
- [ ] `.github/copilot-instructions.md` is present (it should be — if using this as a template, it is).
- [ ] You are in the root of the target project.
- [ ] The project has at least one of: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Makefile`, `pom.xml`, `build.gradle`.

If `.github/copilot-instructions.md` is missing, copy it from the template repo before proceeding.

---

## Step 1 — Discover the project

Read every project manifest file present in the repo root:

- `package.json` → language = TypeScript/JavaScript, runtime, test framework, scripts
- `pyproject.toml` / `setup.cfg` / `requirements.txt` → language = Python
- `Cargo.toml` → language = Rust
- `go.mod` → language = Go
- `pom.xml` / `build.gradle` → language = Java/Kotlin
- `Makefile` → extract test, build, lint targets
- `README.md` → project name, description, purpose

For each manifest found, extract and record:

| Placeholder | Where to find it |
|-------------|------------------|
| `{{PROJECT_NAME}}` | `package.json:name`, `Cargo.toml:[package].name`, `pyproject.toml:[project].name`, or repo name |
| `{{LANGUAGE}}` | Infer from manifest type; confirm with dominant file extension in `src/` or equivalent |
| `{{RUNTIME}}` | `package.json:engines`, or Node/Bun/Deno version, or Python version, etc. |
| `{{PACKAGE_MANAGER}}` | Presence of `bun.lockb`→Bun, `pnpm-lock.yaml`→pnpm, `yarn.lock`→Yarn, `package-lock.json`→npm, `uv.lock`→uv, etc. |
| `{{TEST_COMMAND}}` | `package.json:scripts.test`, `Makefile:test` target, `pyproject.toml:[tool.pytest.ini_options]`, etc. |
| `{{TYPE_CHECK_COMMAND}}` | `package.json:scripts.typecheck` / `check:types`, or `mypy src/`, or `cargo check`, etc. If none found, set to `echo "no type check configured"` |
| `{{LOC_COMMAND}}` | `package.json:scripts.check:loc` or `check:lines`, or `find src -name '*.{{EXT}}' | xargs wc -l | sort -n` |
| `{{THREE_CHECK_COMMAND}}` | Compose from TEST + TYPE_CHECK + LOC: `<test> && <typecheck> && <loc>` |
| `{{METRICS_COMMAND}}` | `package.json:scripts.kaizen` / `metrics`, or `make metrics`, or compose a one-liner |
| `{{LOC_WARN_THRESHOLD}}` | Default **250** unless existing codebase median file size suggests otherwise |
| `{{LOC_HIGH_THRESHOLD}}` | Default **400** |
| `{{DEP_BUDGET}}` | Count current runtime deps; use that count + 2 as the budget (min 6) |
| `{{DEP_BUDGET_WARN}}` | `{{DEP_BUDGET}}` + 2 |
| `{{TEST_FRAMEWORK}}` | From manifest devDependencies or test imports |
| `{{INTEGRATION_TEST_ENV_VAR}}` | Look for env-gated tests; default `INTEGRATION_TESTS=1` |
| `{{PREFERRED_SERIALISATION}}` | Default `JSON`; adjust if project uses YAML/MessagePack/Protobuf predominantly |
| `{{SUBAGENT_MAX_DEPTH}}` | Default `3` |
| `{{VALUE_STREAM_DESCRIPTION}}` | One sentence describing the main flow of value through the system (e.g., "User request → processing → response") |
| `{{FLOW_DESCRIPTION}}` | One sentence on how the system creates flow (e.g., "stream output; fast feedback loops") |
| `{{PROJECT_CORE_VALUE}}` | Noun phrase from README — what the project ultimately delivers to the user |
| `{{SETUP_DATE}}` | Today's date in ISO 8601 format |
| `{{EXTRA_METRIC_NAME}}` | If a domain-specific metric is obvious (e.g., "API response time"), add it; otherwise delete this row |

If a value cannot be determined, leave the `{{PLACEHOLDER}}` as-is in the instructions file and add a comment: `<!-- TODO: fill {{PLACEHOLDER}} once known -->`.

---

## Step 2 — Populate the instructions file

1. Open `.github/copilot-instructions.md`.
2. Replace every `{{PLACEHOLDER}}` with the resolved value from Step 1.
3. In the **Project-Specific Overrides** table (§10), fill the "Resolved value" column with the same values.
4. In the Lean Principles table (§1), update the Principle 2 description to the `{{VALUE_STREAM_DESCRIPTION}}` and Principle 3 to `{{FLOW_DESCRIPTION}}`.
5. In the Coding Conventions section (§4), replace `{{CODING_PATTERNS}}` with a bullet list of the top 3–5 patterns you observed in the existing source code (or "*(to be discovered)*" if the project is new).
6. Save the file.

---

## Step 3 — Scaffold workspace identity files

Create the directory `.copilot/workspace/` (relative to the repo root). For each file below, create it with the listed starter content, substituting `{{PROJECT_NAME}}` with the resolved value. If a file already exists, leave it untouched.

### `.copilot/workspace/IDENTITY.md`

```markdown
# Agent Identity — {{PROJECT_NAME}}

I am the Copilot agent for **{{PROJECT_NAME}}**. My role is to help build, maintain, and improve this project according to the Lean/Kaizen methodology described in `.github/copilot-instructions.md`.

*(This file is updated by me as I develop a clearer understanding of the project.)*
```

### `.copilot/workspace/SOUL.md`

```markdown
# Values & Reasoning Patterns — {{PROJECT_NAME}}

Core values I apply to every decision in this project:

- **YAGNI** — I do not build what is not needed today.
- **Small batches** — A 50-line PR is better than a 500-line PR.
- **Explicit over implicit** — Naming, types, and docs should remove ambiguity, not add it.
- **Reversibility** — I prefer decisions that can be undone.
- **Baselines** — I measure before and after any significant change.

*(Updated as reasoning patterns emerge.)*
```

### `.copilot/workspace/USER.md`

```markdown
# User Profile — {{PROJECT_NAME}}

| Attribute | Observed value |
|-----------|---------------|
| Communication style | *(to be discovered)* |
| Domain expertise | *(to be discovered)* |
| Preferences | *(to be discovered)* |
| Working hours / pace | *(to be discovered)* |
| Preferred review depth | *(to be discovered)* |

*(Updated as I learn through interaction.)*
```

### `.copilot/workspace/TOOLS.md`

```markdown
# Tool Usage Patterns — {{PROJECT_NAME}}

| Tool / command | Effective usage pattern |
|----------------|-------------------------|
| `{{TEST_COMMAND}}` | Run after every change; treat red as blocking |
| `{{TYPE_CHECK_COMMAND}}` | Run after every type definition change |
| `{{THREE_CHECK_COMMAND}}` | Three-check ritual — run before marking a task done |

*(Updated as effective workflows are discovered.)*
```

### `.copilot/workspace/MEMORY.md`

```markdown
# Memory Strategy — {{PROJECT_NAME}}

- Use project-scoped memory for conventions discovered in this codebase.
- Use session transcripts for recent context; do not rely on long-term memory for facts that are in source files.
- Always prefer reading the source file over recalling a cached summary of it.

*(Updated as the memory system is used.)*
```

### `.copilot/workspace/BOOTSTRAP.md`

```markdown
# Bootstrap Record — {{PROJECT_NAME}}

This workspace was scaffolded on **{{SETUP_DATE}}** using the [copilot-instructions-template](https://github.com/asafelobotomy/copilot-instructions-template).

## Initial stack

- Language: {{LANGUAGE}}
- Runtime: {{RUNTIME}}
- Package manager: {{PACKAGE_MANAGER}}
- Test framework: {{TEST_FRAMEWORK}}

## What was created

- `.github/copilot-instructions.md` — instructions populated from template
- `.copilot/workspace/` — all six identity files
- `CHANGELOG.md` — Keep-a-Changelog stub
- `JOURNAL.md` — ADR journal with setup entry
- `BIBLIOGRAPHY.md` — file catalogue with initial snapshot
- `METRICS.md` — baseline snapshot for this date

*(This file is not updated after setup. It is a permanent record of origin.)*
```

---

## Step 4 — Capture an initial METRICS baseline

Create `METRICS.md` in the repo root (if it does not exist) using the template at `template/METRICS.md` (or the stub below if the template file is not present).

Then:
1. Count the number of source files and total LOC (using `find`/`wc` or the `{{LOC_COMMAND}}`).
2. Count the number of tests (from the last test run output, if available, or estimate as "N/A").
3. Count runtime dependencies from the manifest.
4. Append a row to `METRICS.md`:

```
| {{SETUP_DATE}} | Setup baseline | <total_loc> | <file_count> | <test_count> | <assertion_count_or_NA> | 0 | <dep_count> |
```

---

## Step 5 — Create documentation stubs

For each file below, create it **only if it does not already exist**. Use the stubs in the `template/` directory of the template repo, or the content shown.

### `CHANGELOG.md`
```markdown
# Changelog

All notable changes to {{PROJECT_NAME}} will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- Copilot instructions scaffolded from [copilot-instructions-template](https://github.com/asafelobotomy/copilot-instructions-template).
```

### `JOURNAL.md`
```markdown
# Development Journal — {{PROJECT_NAME}}

Architectural decisions and context are recorded here in ADR style.

---

## {{SETUP_DATE}} — Project onboarded to copilot-instructions-template

**Context**: This project adopted the generic Lean/Kaizen Copilot instructions template.
**Decision**: Use `.github/copilot-instructions.md` as the primary agent guidance document, with `.copilot/workspace/` for session-persistent identity state.
**Consequences**: Copilot is authorised to update the instructions file when patterns stabilise (see Living Update Protocol).
```

### `BIBLIOGRAPHY.md`
```markdown
# Bibliography — {{PROJECT_NAME}}

Every file in the project is catalogued here. Update this file whenever a file is created, renamed, deleted, or its purpose changes significantly.

| File | Purpose | LOC |
|------|---------|-----|
| `.github/copilot-instructions.md` | AI agent guidance (Lean/Kaizen methodology + project conventions) | — |
| `.copilot/workspace/IDENTITY.md` | Agent self-description | — |
| `.copilot/workspace/SOUL.md` | Agent values & reasoning patterns | — |
| `.copilot/workspace/USER.md` | Observed user profile | — |
| `.copilot/workspace/TOOLS.md` | Effective tool usage patterns | — |
| `.copilot/workspace/MEMORY.md` | Memory system strategy | — |
| `.copilot/workspace/BOOTSTRAP.md` | Permanent setup origin record | — |
| `CHANGELOG.md` | Keep-a-Changelog | — |
| `JOURNAL.md` | ADR-style development journal | — |
| `BIBLIOGRAPHY.md` | This file — complete file map | — |
| `METRICS.md` | Kaizen baseline snapshot table | — |

*(Add all project source files below this line.)*
```

### `METRICS.md`
Use the stub from `template/METRICS.md`.

---

## Step 6 — Finalise and self-destruct

1. Review what was created and print a summary to the user:
   - Which placeholders were filled vs. left as `{{TODO}}`.
   - Which files were created vs. already existed and were skipped.
   - Any anomalies or decisions made during setup.
2. Ask the user: *"Setup is complete. Shall I delete SETUP.md now?"*
3. On confirmation, delete `SETUP.md`.
4. Append to `JOURNAL.md`:
   ```
   [instructions] Setup complete — SETUP.md removed. See BOOTSTRAP.md for origin record.
   ```

---

> **Note for Copilot**: The `template/` directory in this repo (if present) contains stub files used as canonical sources for METRICS.md etc. You can read them for reference but do not copy them verbatim into the target project — use the content from this SETUP.md instead, as it has the placeholders already contextualised.
