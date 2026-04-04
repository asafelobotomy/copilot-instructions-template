# SETUP.md — Copilot Instructions Template Setup Guide

> **Machine-readable.** Fetched and executed by the Setup agent.
> All writes go to the **user's current project** — never to the template repository.
> After setup completes and the user confirms, delete this file from the user's project.

## Recovery mode

`UPDATE.md` uses this setup flow only after factory restore has created a complete backup and removed every managed surface from the working tree. When recovery mode starts, treat the project as a clean install.

- Do not read, merge, preserve, or rely on current `.github/copilot-instructions.md`, `.github/copilot-version.md`, current §10 values, existing `.copilot/workspace/` files, existing `.vscode/*.json` files, or template-managed `CHANGELOG.md` content except from the backup snapshot.
- If any managed surface still exists when recovery mode begins, stop and remove it after backing it up. Do not continue with merge or keep-existing behavior.
- Collect fresh setup answers and write a fresh installation from upstream sources.

## Pre-conditions

- You are inside the **user's project**, not the template repository.
- You fetched `template/copilot-instructions.md` from `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/copilot-instructions.md` and hold it in memory.
- You have `editFiles` tool access.
- If invoked by factory restore, disregard local managed files and rebuild from scratch after the backup-and-purge step.
- If any fetch fails during setup, **stop immediately** and report the error.

---

## § 0 — Pre-flight (before any writes)

### § 0.0 — Scope guard

Run `git remote get-url origin`. If the output contains `asafelobotomy/copilot-instructions-template`, **STOP** — this is the template repo, not a consumer project. If the command fails or has no `.git/`, ask the user to confirm the directory before proceeding.

### § 0a — Existing Copilot instructions

If `.github/copilot-instructions.md` exists:

```ask_questions
header: "Existing instructions"
question: ".github/copilot-instructions.md already exists. How should I handle it?"
options:
  - label: "A — Archive then use template"
    description: "Archive to .github/archive/pre-setup-YYYY-MM-DD/ then use the template"
    recommended: true
  - label: "B — Delete and start fresh"
    description: "Delete the old file and use the template from scratch"
  - label: "C — Merge"
    description: "Preserve unique conventions from the old file into §10 of the new instructions"
allowFreeformInput: false
```

Default **A** if user skips. **Fallback**: present as a numbered list in chat if `ask_questions` is unavailable.

### § 0b — Existing workspace identity files

If `.copilot/workspace/` exists with files:

```ask_questions
header: "Workspace identity files"
question: "Workspace identity files already exist. These may contain session history and learned preferences. How should I handle them?"
options:
  - label: "K — Keep all existing files"
    description: "Preserve session history and learned preferences"
    recommended: true
  - label: "O — Overwrite all with fresh stubs"
    description: "Replace all workspace files with new defaults"
  - label: "I — Handle each file individually"
    description: "I'll ask about each file one by one"
allowFreeformInput: false
```

Default **K**. **Fallback**: present as a numbered list in chat if unavailable.

### § 0c — Existing documentation stubs

Note whether `CHANGELOG.md` exists. Skip creating it later if so (or ask to append).

### § 0d — User Preference Interview

Fetch interview questions from the companion file:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/setup/interview.md
```

Present the tier selection:

```ask_questions
header: "Setup tier"
question: "Which setup level do you want?"
options:
  - label: "Q — Quick"
    description: "5 questions (S1-S5), ~3 min, sensible defaults for everything else"
    recommended: true
  - label: "S — Standard"
    description: "17 questions (S1-S5 + A6-A17), ~6 min"
  - label: "F — Full"
    description: "25 questions (S1-S5 + A6-A17 + E16-E18, E20-E24), ~10 min"
  - label: "Skip"
    description: "Use all defaults immediately — no questions asked"
allowFreeformInput: false
```

**Fallback**: present as a numbered list in chat if unavailable.

Present questions for the selected tier from `interview.md` in batches of up to 4 per `ask_questions` call. Question IDs by tier:

- **Tier Q**: S1, S2, S3, S4, S5
- **Tier S**: S1–S5 + A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17
- **Tier F**: All S + A questions + E16–E18, E20–E24

E19 removed — global autonomy derived from S5 answer.

#### § 0e — Pre-flight summary

Present a summary of files that will be created/archived, then confirm:

```ask_questions
header: "Pre-flight confirmation"
question: "Review the setup summary above. Ready to proceed?"
options:
  - label: "Go"
    description: "Proceed with setup"
    recommended: true
  - label: "Stop"
    description: "Cancel setup — no files will be written"
allowFreeformInput: false
```

If "Stop", halt immediately. **Fallback**: wait for user to type "go" or "stop" in chat.

---

## § 1 — Stack discovery

Read project files if present: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Makefile`. Determine:

| Placeholder | Value to detect |
|-------------|----------------|
| `{{LANGUAGE}}` | Primary language (TypeScript, Python, Rust, Go, etc.) |
| `{{RUNTIME}}` | Runtime version (Node 22, Python 3.12, etc.) |
| `{{RUNTIME_VERSION}}` | Exact runtime version string |
| `{{PACKAGE_MANAGER}}` | npm / pnpm / yarn / bun / pip / cargo / go |
| `{{TEST_FRAMEWORK}}` | Jest / pytest / cargo test / go test / etc. |
| `{{TEST_COMMAND}}` | Full test command (e.g. `npm test`) |
| `{{TYPE_CHECK_COMMAND}}` | Type check command (e.g. `npx tsc --noEmit`) |
| `{{BUILD_COMMAND}}` | Build command (e.g. `npm run build`) |
| `{{INSTALL_COMMAND}}` | Install dependencies command |
| `{{LOC_COMMAND}}` | LOC count command |
| `{{THREE_CHECK_COMMAND}}` | Combined three-check ritual |
| `{{METRICS_COMMAND}}` | Metrics snapshot command |
| `{{PROJECT_NAME}}` | Project name |
| `{{PROJECT_CORE_VALUE}}` | One sentence: what value does this project deliver? |
| `{{VALUE_STREAM_DESCRIPTION}}` | How code changes reach users |
| `{{CODING_PATTERNS}}` | 3–5 detected patterns in the codebase |
| `{{SETUP_DATE}}` | Today's date (YYYY-MM-DD) |

Leave undetermined values as `{{PLACEHOLDER}}` with `<!-- TODO: fill once known -->`.

---

## § 2 — Populate the instructions file

Replace every `{{PLACEHOLDER}}` in `template/copilot-instructions.md` with values from §1. Add user preferences to `## § 10 — Project-Specific Overrides` as a table (IDs S1–E24, one row per answered question). Write to `.github/copilot-instructions.md`.

Fetch the companion manifests file for §2.5–§3:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/setup/manifests.md
```

Also prefetch the workspace index fallback used by §2.5, §2.6, and §2.12 when
the GitHub tree API response is truncated. Keep it in memory until §3 writes the
same payload to `.copilot/workspace/workspace-index.json`:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/workspace/workspace-index.json
```

> **Parallelization**: §2.5–§2.14 (including §2.11a) are independent. Fetch all URLs
> in parallel where possible.

## § 2.4 — Validate placeholder resolution

Grep `.github/copilot-instructions.md` for remaining `{{.*}}` tokens. If any found:

```ask_questions
header: "Unresolved placeholder: {{PLACEHOLDER_NAME}}"
question: "I couldn't auto-detect a value for {{PLACEHOLDER_NAME}}. What should it be?"
allowFreeformInput: true
```

Batch up to 4 per call. Do not proceed with unresolved tokens. **Fallback**: present as a numbered list in chat if unavailable.

---

## § 2.5 — Write model-pinned agent files

Create `.github/agents/`. Follow manifests.md § Agent files. If the GitHub tree response is truncated, use the prefetched workspace-index fallback from §2 before continuing. If any fetch fails, stop immediately.

---

## § 2.6 — Scaffold skill library

Create `.github/skills/`. Follow manifests.md § Skill files. If the GitHub tree response is truncated, use the prefetched workspace-index fallback from §2 before continuing.

---

## § 2.7 — Scaffold path-specific instruction files

Follow manifests.md § Path instruction stubs. For each stub, evaluate the `exists:GLOB` condition against the workspace before installing. Skip stubs whose conditions are not satisfied. Write matching stubs to `.github/instructions/`. Validate no `{{PLACEHOLDER}}` tokens remain.

---

## § 2.8 — Scaffold prompt files

> **Conditional (A17)**: Skip if A17 = "No". If "Ask about each", present each before writing.

Follow manifests.md § Prompt files. Write to `.github/prompts/`.

---

## § 2.9 — Scaffold Copilot setup steps workflow

Fetch to `.github/workflows/copilot-setup-steps.yml`:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/copilot-setup-steps.yml
```

Populate runtime sections from §1. Remove unused runtime sections. Replace `{{RUNTIME_VERSION}}`, `{{INSTALL_COMMAND}}`, `{{BUILD_COMMAND}}`, `{{TEST_COMMAND}}`.

---

## § 2.10 — Configure MCP servers (E22 only)

Skip if E22 = A (None) or not asked. If E22 = B or C, create `.vscode/mcp.json` using the config from `manifests.md` § MCP server configs. Run sandbox detection on Linux first. If E22 = C, enable relevant servers and add stack-specific ones.

---

## § 2.11 — Configure VS Code settings (E18 only)

Skip if E18 = No. Fetch and merge recommended settings from:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/vscode/settings.json
```

Merge keys into `.vscode/settings.json` (do not overwrite existing values). Also fetch extension recommendations:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/vscode/extensions.json
```

Merge `recommendations` array into `.vscode/extensions.json`.

---

## § 2.11a — Install starter-kit plugin (automatic)

1. Fetch the registry: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/starter-kits/REGISTRY.json`
2. Match detected stack against `kits[].detect` conditions (files, language, dependencies). Multiple kits may match.
3. Present matches:

```ask_questions
header: "Starter kits"
question: "Detected starter kits that match your project. Install them?"
options:
  - label: "Yes"
    description: "Install all matched kits"
    recommended: true
  - label: "Pick"
    description: "Let me select which to install"
  - label: "Skip"
    description: "Skip starter-kit installation entirely"
allowFreeformInput: false
```

> **Fallback**: present as a numbered list in chat if unavailable.

1. Fetch kit files from `starter-kits/<kit-name>/`, write to `.github/starter-kits/<kit-name>/`.
2. Register in `.vscode/settings.json` under `chat.pluginLocations`.
3. Report installed kits. If none matched: "No starter kits installed. Say 'Install a starter kit' later."

---

## § 2.12 — Scaffold agent lifecycle hooks

> **Conditional (A16)**: Skip if A16 = "No". If "Ask about each", present each hook before writing.

Follow manifests.md § Hook scripts. Write config and scripts to `.github/hooks/`. Always write `copilot-hooks.json` if at least one script is written.

Config fetch: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/copilot-hooks.json`

---

## § 2.13 — Write version file, fingerprints, and file manifest

Fetch current version: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/VERSION.md`

Compute section fingerprints and file-manifest hashes (see `manifests.md` § Version file template for commands). Write to `.github/copilot-version.md` with version, date, fingerprints, manifest, and setup-answers blocks.

If terminal unavailable, use the Python fallback in `manifests.md § Version file template`. Omit fingerprint/manifest blocks only if neither `sha256sum` nor Python is available. Always write setup-answers.

---

## § 2.14 — Generate Claude compatibility file (E23 only)

Skip if E23 = "No". Fetch and write to project root:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/CLAUDE.md
```

Replace all `{{PLACEHOLDER}}` tokens with values from §1.

---

## § 2.15 — Install companion extension (optional)

```ask_questions
header: "Companion extension"
question: "The copilot-profile-tools extension enables profile-aware extension management. Install it?"
options:
  - label: "Yes"
    description: "Install the companion extension"
  - label: "Skip"
    description: "Proceed without it — Extensions agent uses CLI fallback"
    recommended: true
allowFreeformInput: false
```

**Fallback**: present as yes/skip in chat if unavailable.

If "Yes": `code --install-extension asafelobotomy.copilot-profile-tools`. If Marketplace fails, fetch VSIX from GitHub Releases. Add to `.vscode/extensions.json` recommendations.

---

## § 3 — Scaffold workspace identity files

Create `.copilot/workspace/`. Follow manifests.md § Workspace identity files for the ten-file table. Replace `{{PLACEHOLDER}}` tokens from §1 and `{{SETUP_DATE}}` with today's date. If any fetch fails, stop immediately.

---

## § 4 — Create documentation stubs

Create `CHANGELOG.md` if it does not exist (detected in §0c). Use this template:

```markdown
# Changelog

All notable changes to **{{PROJECT_NAME}}** will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added

- Copilot instructions scaffolded from [copilot-instructions-template](https://github.com/asafelobotomy/copilot-instructions-template).
```

---

## § 5 — Self-destruct and final summary

Print a summary of all written files with counts and version, then:

```ask_questions
header: "Delete SETUP.md"
question: "Setup is complete. Should I delete SETUP.md from your project?"
options:
  - label: "Yes"
    description: "Delete SETUP.md from this project"
    recommended: true
  - label: "No"
    description: "Keep SETUP.md for reference"
allowFreeformInput: false
```

**Fallback**: present as yes/no in chat if unavailable.

If confirmed, delete `SETUP.md` from the user's project (never the template repository).

```ask_questions
header: "Health check"
question: "Would you like me to hand off to the Audit agent for a full health check?"
options:
  - label: "Yes"
    description: "Run an Audit health check now"
    recommended: true
  - label: "No"
    description: "Skip the health check"
allowFreeformInput: false
```

**Fallback**: present as yes/no in chat if unavailable.
