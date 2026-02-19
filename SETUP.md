# Copilot Setup — Run Once

> **Instructions for Copilot**: This file defines a one-time setup process. Read **every step** before starting anything. Complete Step 0 fully before writing a single file. Tell the user exactly what you found, what you plan to do, and wait for confirmation at each decision point before proceeding.
>
> **Instructions for the human**: Open a Copilot chat and say: *"Please run the setup process described in SETUP.md."* Copilot will do the rest, pausing to ask you questions wherever a decision is needed.

---

## Step 0 — Pre-flight: detect existing setup

Before writing anything, scan the project for files that this setup process would create or overwrite. Report your findings to the user in a clear table, then handle each category as described below.

### 0a — Detect existing Copilot instructions

Check whether `.github/copilot-instructions.md` already exists.

**If it does NOT exist** → proceed directly to Step 1. No prompt needed.

**If it DOES exist** → read the file in full, then present the user with the following choice before doing anything else:

---

> **Existing Copilot instructions detected** at `.github/copilot-instructions.md`.
>
> How would you like to handle them?
>
> **1 — Archive** Save the current instructions to `.github/archive/copilot-instructions-<YYYY-MM-DD>.md`, then replace the live file with the populated template. Your existing instructions are preserved in the archive folder and referenced from the new file.
>
> **2 — Delete** Remove the current instructions entirely and replace with the freshly populated template. Use this if the existing file is outdated or irrelevant.
>
> **3 — Merge** Read both the existing instructions and the new template, then produce a single unified file that:
> - Uses the template's structure (sections §1–§9 unchanged).
> - Preserves every unique convention, rule, pattern, or anti-pattern from the existing file that is not already covered by the template.
> - Places all preserved unique content into §10 (Project-Specific Overrides), clearly labelled as migrated from the previous instructions.
> - Discards any content from the existing file that is directly contradicted by or duplicated in the template.

---

Wait for the user to reply with **1**, **2**, or **3** (or equivalent phrasing) before proceeding.

#### Archive procedure (option 1)

1. Create the directory `.github/archive/` if it does not exist.
2. Copy the current `.github/copilot-instructions.md` to `.github/archive/copilot-instructions-<TODAY>.md`.
3. Add a comment at the top of the archived file:
   ```markdown
   <!-- Archived on <TODAY> during copilot-instructions-template setup. -->
   <!-- See .github/copilot-instructions.md for the live instructions.  -->
   ```
4. Continue to Step 1 to populate the new template file.
5. After the new file is written, add a note to its §10 section:
   ```markdown
   > Previous instructions archived at `.github/archive/copilot-instructions-<TODAY>.md`.
   > Review that file for any conventions that were not automatically migrated.
   ```

#### Delete procedure (option 2)

1. Delete `.github/copilot-instructions.md`.
2. Continue to Step 1 to populate a fresh template file.

#### Merge procedure (option 3)

This is the most involved path. Follow it carefully.

1. **Extract from the existing file** — read it and identify:
   - Any project-specific conventions (naming rules, code patterns, tool usage rules).
   - Any anti-patterns documented.
   - Any workflow or command sequences.
   - Any metric thresholds that differ from the template defaults (250/400 LOC, dep budget, etc.).
   - Any sections or headings that have no equivalent in the template.

2. **Populate the template** — proceed through Steps 1–2 as normal (discover stack, fill placeholders).

3. **Graft unique content** — for each unique item extracted above:
   - If it belongs naturally in §1–§9 (e.g. a coding convention belongs in §4), add it there with a `<!-- migrated -->` comment.
   - If it doesn't fit neatly, add it to §10 under a subsection titled "Conventions from previous instructions".
   - If it contradicts the template, note the conflict explicitly and ask the user which version to keep.

4. **Produce a summary** — after writing the merged file, tell the user:
   - How many items were migrated.
   - How many conflicts were found (and how they were resolved or deferred).
   - Whether anything was intentionally discarded, and why.

5. Do **not** create an archive in this path (the merged file supersedes both). If the user would also like an archive, they can choose to run option 1 first.

---

### 0b — Detect existing workspace identity files

Check whether `.copilot/workspace/` exists and contains any of the six identity files (IDENTITY.md, SOUL.md, USER.md, TOOLS.md, MEMORY.md, BOOTSTRAP.md).

**If none exist** → proceed; Step 3 will create them all.

**If some or all exist** → report which ones were found, then ask:

> **Existing workspace identity files detected**: `<list of files found>`
>
> These files may contain session history and learned preferences.
> - **Keep all** (default) — skip creating any file that already exists. *(Recommended if Copilot has been working in this project.)*
> - **Overwrite all** — replace all existing identity files with fresh stubs.
> - **Selective** — tell me which files to keep and which to overwrite.

Wait for the user's response before proceeding to Step 3.

---

### 0c — Detect existing documentation stubs

Check for the presence of: `CHANGELOG.md`, `JOURNAL.md`, `BIBLIOGRAPHY.md`, `METRICS.md`.

Report which exist, then state:

> The following files already exist: `<list>`. I will **skip** creating these and only create the missing ones: `<list>`. If you would like me to append setup entries to the existing files instead of skipping them, say "append entries".

Wait for confirmation or the "append entries" instruction before proceeding to Step 5.

**If "append entries"**: for each existing file, append the appropriate setup entry (the same content that would have been written if the file were new — a setup CHANGELOG entry, a setup JOURNAL ADR entry, etc.) rather than replacing the file.

---

### 0d — Pre-flight summary

After completing 0a–0c, present a single summary before writing anything:

```
Pre-flight complete. Here is what I will do:

  Instructions:   [archive / delete / merge / create fresh]
  Workspace files: [keep existing / overwrite / selective / create all]
  Doc stubs:      [skip existing / append entries / create missing only]

Proceeding in 10 seconds unless you say "wait" or "stop".
```

Wait the stated period (or for an explicit "go ahead") before starting Step 1.

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
| `{{LOC_COMMAND}}` | `package.json:scripts.check:loc` or `check:lines`, or `find src -name '*.{{EXT}}' \| xargs wc -l \| sort -n` |
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

If a value cannot be determined, leave the `{{PLACEHOLDER}}` as-is and add a comment: `<!-- TODO: fill {{PLACEHOLDER}} once known -->`.

---

## Step 2 — Populate the instructions file

> **Skip this step** if Step 0a resulted in **Delete** — the template file was already written fresh in that path. Jump to Step 3.

1. Open `.github/copilot-instructions.md` (the template, or the merged file if Merge was chosen).
2. Replace every remaining `{{PLACEHOLDER}}` with the resolved value from Step 1.
3. In the **Project-Specific Overrides** table (§10), fill the "Resolved value" column.
4. In the Lean Principles table (§1), update Principle 2 to `{{VALUE_STREAM_DESCRIPTION}}` and Principle 3 to `{{FLOW_DESCRIPTION}}`.
5. In §4 Coding Conventions, replace `{{CODING_PATTERNS}}` with a bullet list of the top 3–5 patterns observed in the existing source (or "*(to be discovered)*" for a new project).
6. Save the file.

---

## Step 3 — Scaffold workspace identity files

> Apply the decisions made in Step 0b (keep / overwrite / selective).

Create the directory `.copilot/workspace/` if it does not exist. For each file below, create it with the listed starter content — **unless Step 0b determined that file should be kept**. Substitute all resolved placeholder values.

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

> Apply the decision from Step 0c. If `METRICS.md` already exists and the user chose **skip**, do not append. If they chose **append entries**, add a new row.

Create `METRICS.md` in the repo root if it does not exist, using the stub below.

Then:
1. Count source files and total LOC (`find`/`wc` or `{{LOC_COMMAND}}`).
2. Count tests from the last test run output, or estimate as "N/A".
3. Count runtime dependencies from the manifest.
4. Append a row:

```
| {{SETUP_DATE}} | Setup baseline | <total_loc> | <file_count> | <test_count> | <assertion_count_or_NA> | 0 | <dep_count> |
```

**METRICS.md stub** (use only if the file does not exist):

```markdown
# Metrics — {{PROJECT_NAME}}

Kaizen baseline snapshots. Append a row after any session that materially changes LOC, test count, or dependency count.

| Date | Phase | LOC (total) | Files | Tests | Assertions | Type errors | Runtime deps |
|------|-------|-------------|-------|-------|------------|-------------|--------------|
| {{SETUP_DATE}} | Setup baseline | — | — | — | — | 0 | — |
```

---

## Step 5 — Create documentation stubs

> Apply the decision from Step 0c (skip / overwrite / append entries / create missing only).

For each file, act according to the Step 0c decision. The content to create or append is shown below.

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
See Step 4 for the stub — do not duplicate it here.

---

## Step 6 — Finalise and self-destruct

1. **Review** everything created or modified and print a structured summary to the user:

   ```
   Setup complete. Here is what was done:

   INSTRUCTIONS
     Action taken:        [archived / deleted / merged / created fresh]
     Archive location:    [.github/archive/... or N/A]
     Placeholders filled: <N> of <total>
     Placeholders unresolved: <list or "none">
     Merge conflicts:     <N resolved, N deferred or "none">

   WORKSPACE IDENTITY FILES
     Created: <list>
     Skipped (kept existing): <list>

   DOCUMENTATION STUBS
     Created: <list>
     Appended to: <list>
     Skipped: <list>

   METRICS
     Initial baseline row appended: [yes / skipped]

   ANOMALIES
     <any decisions made that the user should verify, or "none">
   ```

2. Ask the user: *"Setup is complete. Shall I delete SETUP.md now?"*
3. On confirmation, delete `SETUP.md`.
4. Append to `JOURNAL.md`:
   ```
   [instructions] Setup complete — SETUP.md removed. See BOOTSTRAP.md for origin record.
   ```

---

> **Note for Copilot**: The `template/` directory in this repo (if present) contains canonical stub files. Read them for reference but use the content in this SETUP.md as the authoritative source, since it has placeholders pre-contextualised for the setup flow.
