# SETUP.md — Copilot Instructions Template Setup Guide

> **Machine-readable.** This file is fetched and executed by the Copilot Setup agent.
> All writes go to the **user's current project** — never to `asafelobotomy/copilot-instructions-template`.
> After setup completes and the user confirms, delete this file from the user's project.

---

## Pre-conditions

Before running any step, verify:

- You are operating inside the **user's project**, not the template repository.
- You fetched `template/copilot-instructions.md` from the template repo and are holding it in memory (see `AGENTS.md` step 2).
- You have `editFiles` tool access.

> **Remote fetches**: In addition to the two URLs in `AGENTS.md`, this guide fetches
> agent files, skill files, prompt files, path instruction files, and hook scripts from
> upstream during §2.5–§2.14. If any fetch fails, **stop immediately** and report the
> error to the user. Do not proceed with partial writes.

---

## § 0 — Pre-flight (before any writes)

### § 0.0 — Scope guard

Before any other check, verify you are operating in the user's target project and not
inside the template repository itself.

Run: `git remote get-url origin`

If the output contains `asafelobotomy/copilot-instructions-template`, **STOP** and
tell the user:

> "This appears to be the template repository itself, not a consumer project.
> Please open a terminal inside your target project directory and re-run the setup there."

Only proceed once you have confirmed the working directory is the user's own project.

### § 0a — Existing Copilot instructions

Check whether `.github/copilot-instructions.md` already exists in the user's project.

If it exists, ask the user:

> "`.github/copilot-instructions.md` already exists. How should I handle it?
> **A** — Archive to `.github/archive/pre-setup-YYYY-MM-DD/` then use the template (safe default)
> **B** — Delete the old file and start fresh
> **C** — Merge: preserve unique conventions from the old file into §10 of the new instructions"

Wait for the user's choice before proceeding. Default is **A** if the user types "skip" or says nothing.

### § 0b — Existing workspace identity files

Check whether `.copilot/workspace/` exists and contains any files (IDENTITY.md, SOUL.md, etc.).

If files exist, ask the user:

> "Workspace identity files already exist in `.copilot/workspace/`. These may contain session history and learned preferences.
> **K** — Keep all existing files (recommended)
> **O** — Overwrite all with fresh stubs
> **I** — Handle each file individually (I'll ask about each one)"

Default is **K**.

### § 0c — Existing documentation stubs

Check for `CHANGELOG.md` in the project root. Note if it exists — skip creating it if it already exists (or ask to append an entry if the user prefers).

### § 0d — User Preference Interview

Ask the user which setup tier they want, then present the corresponding questions.

> "Which setup level do you want?
> **Q — Quick** (5 questions, ~3 min, sensible defaults for everything else)
> **S — Standard** (17 questions, ~6 min)
> **F — Full** (23 questions, ~10 min)
> Or type **skip** to use all defaults immediately."

#### Tier Q questions (always ask)

Batch these into groups of up to 4 per `ask_questions` call. If `ask_questions` is unavailable (CLI, Codex, or cloud environments), present each batch as a numbered list in chat and ask the user to reply with their choices inline.

**Batch 1 (S1–S4)**:

- **S1 — Response style**: How much explanation do you want?
  Options: Concise (code + one-liner) | Balanced (code + brief explanation) | Verbose (code + full reasoning)

- **S2 — Experience level**: How experienced are you with this stack?
  Options: Beginner (explain basics) | Intermediate (assume language knowledge) | Expert (assume deep knowledge)

- **S3 — Primary mode**: What's your main priority?
  Options: Speed (fast iteration) | Quality (hardened production code) | Learning (teach as you go) | Balanced

- **S4 — Testing**: How should I handle tests?
  Options: Always write tests alongside code | Suggest tests but don't write | Skip unless asked

**Batch 2 (S5)**:

- **S5 — Autonomy**: How should I act when something is ambiguous?
  Options: Ask first (always confirm before acting) | Act then tell (proceed and report) | Best judgement

#### Tier S additional questions (A6–A17)

**Batch 3 (A6–A9)**:

- **A6 — Code style**: How are formatting decisions made?
  Options: Infer from existing code | Follow a linter/formatter (specify which) | Follow a style guide (specify which)

- **A7 — Documentation**: How much inline documentation do you expect?
  Options: Minimal (self-documenting names only) | Standard (public APIs documented) | Full (all functions documented)

- **A8 — Error handling**: What's your error handling philosophy?
  Options: Fail fast (panic early, fix root cause) | Defensive (handle all errors explicitly) | Graceful degradation (recover where possible)

- **A9 — Security**: How aggressively should I flag security concerns?
  Options: Flag everything (even low severity) | Flag medium and above | Flag critical only

**Batch 4 (A10–A13)**:

- **A10 — File size**: What LOC thresholds should I enforce?
  Options: Strict (warn 150, hard 300) | Standard (warn 250, hard 400) | Relaxed (warn 400, hard 600) | None

- **A11 — Dependencies**: What's your dependency philosophy?
  Options: Minimal (avoid deps, write it yourself) | Pragmatic (use well-known libs) | Ecosystem-first (use the ecosystem liberally)

- **A12 — Instruction editing**: Can I edit the instructions file when I learn new patterns?
  Options: Free (edit anytime) | Ask (propose and wait for approval) | Suggest only (surface as recommendations) | Locked (never edit)

- **A13 — Refactoring**: How should I handle code smells I notice?
  Options: Fix proactively | Flag them | Ignore unless asked

**Batch 5 (A14–A17)**:

- **A14 — Reporting**: How should I report completed work?
  Options: Summary (what changed and why) | Detailed (files, LOC delta, test results) | Minimal (one sentence)

- **A15 — Skill search**: When I need a reusable workflow, should I search online skill repositories?
  Options: Local only (`.github/skills/` only) | Search online (agentskills.io and registries) | Ask each time

- **A16 — Lifecycle hooks**: Should I install agent lifecycle hook scripts?
  Options: Yes (install all 5 hooks) | No | Ask about each hook

- **A17 — Prompt commands**: Should I scaffold VS Code slash command prompts?
  Options: Yes (install all 5 prompts) | No | Ask about each

#### Tier F additional questions (E16–E18, E20–E22)

> **Note**: E19 (Autonomy ceiling) was removed — Global autonomy is derived from S5:
> S5=A (Ask first) → level 2 | S5=B (Act then tell) → level 3 | S5=C (Best judgement) → level 4

**Batch 6 (E16–E18)**:

- **E16 — Tool availability**: What should I do when a required tool isn't installed?
  Options: Install it (with permission) | Skip and note it | Report and stop

- **E17 — Agent persona**: What personality/tone do you want?
  Options: Professional | Mentor (teach and explain) | Pair-programmer (collaborative) | Direct (minimal preamble)

- **E18 — VS Code settings**: May I modify `.vscode/settings.json`?
  Options: Yes | No | Ask each time

**Batch 7 (E20–E22)**:

- **E20 — Mood lightener**: Should I occasionally add light humour?
  Options: Yes | No

- **E21 — Verification trust**: Which directories get auto-approve vs. pause-and-confirm?
  Options: All auto | Sensitive dirs require confirmation | Ask me to define

- **E22 — MCP servers**: Should I configure Model Context Protocol servers?
  Options: A — None (skip MCP) | B — Always-on only (filesystem, git) | C — Full configuration (all tiers)

#### § 0e — Pre-flight summary

After all questions are answered, present a summary:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SETUP SUMMARY — copilot-instructions-template vX.Y.Z
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Files that will be CREATED:
  .github/copilot-instructions.md     (populated from template)
  .github/copilot-version.md          (installed template version)
  .github/agents/*.agent.md           (6 model-pinned agents)
  .github/skills/*/SKILL.md           (13 starter skills)
  .github/instructions/*.md           (path-specific stubs)
  .github/prompts/*.prompt.md         (slash command prompts)
  .github/hooks/copilot-hooks.json    (hook configuration)
  .github/hooks/scripts/*.sh + *.ps1  (hook scripts)
  .copilot/workspace/*.md + DOC_INDEX.json (8 workspace files)
  CHANGELOG.md

Files that will be ARCHIVED (if chosen):
  .github/archive/pre-setup-YYYY-MM-DD/

Ready to proceed. Type "go" to continue or "stop" to cancel.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for the user to confirm. If they say "stop" or "cancel", halt immediately. If they say "go", "yes", "continue", or press Enter, proceed to §1.

---

## § 1 — Stack discovery

Read the following files if present (do not error if missing):

- `package.json` → extract `name`, `version`, `dependencies`, `devDependencies`, `scripts`
- `pyproject.toml` → extract `[project]` name, version, dependencies
- `Cargo.toml` → extract `[package]` name, version, dependencies
- `go.mod` → extract module name
- `Makefile` → infer build and test commands

From this, determine:

| Placeholder | Value to detect |
|-------------|----------------|
| `{{LANGUAGE}}` | Primary language (TypeScript, Python, Rust, Go, etc.) |
| `{{RUNTIME}}` | Runtime version (Node 22, Python 3.12, etc.) |
| `{{PACKAGE_MANAGER}}` | npm / pnpm / yarn / bun / pip / cargo / go |
| `{{TEST_FRAMEWORK}}` | Jest / pytest / cargo test / go test / etc. |
| `{{TEST_COMMAND}}` | Full command to run tests (e.g. `npm test`) |
| `{{TYPE_CHECK_COMMAND}}` | Type check command (e.g. `npx tsc --noEmit`) |
| `{{BUILD_COMMAND}}` | Build command (e.g. `npm run build`) |
| `{{LOC_COMMAND}}` | LOC count command (e.g. `wc -l src/**/*.ts`) |
| `{{THREE_CHECK_COMMAND}}` | Combined three-check ritual |
| `{{INSTALL_COMMAND}}` | Install dependencies command |
| `{{RUNTIME_VERSION}}` | Exact runtime version string |
| `{{METRICS_COMMAND}}` | Command to gather metrics snapshot |
| `{{PROJECT_NAME}}` | Project name |
| `{{PROJECT_CORE_VALUE}}` | One sentence: what value does this project deliver? |
| `{{VALUE_STREAM_DESCRIPTION}}` | How code changes reach users |
| `{{CODING_PATTERNS}}` | 3–5 detected patterns in the codebase |

Any value that cannot be determined is left as `{{PLACEHOLDER}}` with a `<!-- TODO: fill once known -->` comment.

---

## § 2 — Populate the instructions file

Take the `template/copilot-instructions.md` template held in memory (fetched in `AGENTS.md` step 2). Replace every `{{PLACEHOLDER}}` token with the value detected in §1.

Add the User Preferences table to `## § 10 — Project-Specific Overrides` using this format:

```markdown
## User Preferences

| ID | Question | Answer |
|----|----------|--------|
| S1 | Response style | [answer] |
| S2 | Experience level | [answer] |
| S3 | Primary mode | [answer] |
| S4 | Testing | [answer] |
| S5 | Autonomy | [answer] |
| A6 | Code style | [answer or "default"] |
...
| E22 | MCP servers | [answer or "default"] |
```

Write the populated file to `.github/copilot-instructions.md` in the user's project.

---

## § 2.4 — Validate placeholder resolution

Before continuing, grep the written `.github/copilot-instructions.md` for any remaining
`{{.*}}` tokens:

```text
grep -oE '\{\{[^}]+\}\}' .github/copilot-instructions.md
```

If any are found, present them to the user:

> "I couldn't auto-detect values for these placeholders — please provide them:
> {{PLACEHOLDER_NAME}}: ?"

Substitute the user's answers and re-write the file before continuing to §2.5.
Do not proceed with unresolved `{{...}}` tokens in the instructions file.

> **Parallelization hint**: Steps §2.5 through §2.14 are independent file-creation tasks.
> Fetch all URLs in parallel where your runtime supports it (e.g., batch `fetch_webpage` calls).
> Write each file group as soon as its fetch completes — do not wait for all groups.

---

## § 2.5 — Write model-pinned agent files

Create `.github/agents/` and write six agent files. Fetch each from the template repository:

| Target path | Source URL |
|-------------|-----------|
| `.github/agents/setup.agent.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/setup.agent.md` |
| `.github/agents/coding.agent.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/coding.agent.md` |
| `.github/agents/review.agent.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/review.agent.md` |
| `.github/agents/fast.agent.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/fast.agent.md` |
| `.github/agents/update.agent.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/update.agent.md` |
| `.github/agents/doctor.agent.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/doctor.agent.md` |

Write each file verbatim to the target path. If any fetch fails, **stop immediately** and report the error.

---

## § 2.6 — Scaffold skill library

Create `.github/skills/` and write the following skill files. Each skill goes in its own subdirectory. Fetch each from the template repository and write verbatim. If any fetch fails, **stop immediately**.

Base URL: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/skills/`

| Target path | Fetch suffix |
|-------------|-------------|
| `.github/skills/skill-creator/SKILL.md` | `skill-creator/SKILL.md` |
| `.github/skills/fix-ci-failure/SKILL.md` | `fix-ci-failure/SKILL.md` |
| `.github/skills/lean-pr-review/SKILL.md` | `lean-pr-review/SKILL.md` |
| `.github/skills/conventional-commit/SKILL.md` | `conventional-commit/SKILL.md` |
| `.github/skills/mcp-builder/SKILL.md` | `mcp-builder/SKILL.md` |
| `.github/skills/webapp-testing/SKILL.md` | `webapp-testing/SKILL.md` |
| `.github/skills/issue-triage/SKILL.md` | `issue-triage/SKILL.md` |
| `.github/skills/tool-protocol/SKILL.md` | `tool-protocol/SKILL.md` |
| `.github/skills/skill-management/SKILL.md` | `skill-management/SKILL.md` |
| `.github/skills/mcp-management/SKILL.md` | `mcp-management/SKILL.md` |
| `.github/skills/plugin-management/SKILL.md` | `plugin-management/SKILL.md` |
| `.github/skills/extension-review/SKILL.md` | `extension-review/SKILL.md` |
| `.github/skills/test-coverage-review/SKILL.md` | `test-coverage-review/SKILL.md` |

---

## § 2.7 — Scaffold path-specific instruction files

Based on the project structure detected in §1, copy relevant stubs.

Check for the following and copy if the project has matching code:

| Project has... | Copy stub |
|---|---|
| Test files (`*.test.*`, `*.spec.*`, `tests/`) | `tests.instructions.md` |
| API routes (`api/`, `routes/`, `controllers/`, `handlers/`) | `api-routes.instructions.md` |
| Config files (`*.config.*`, `.eslintrc`, etc.) | `config.instructions.md` |
| Markdown / docs | `docs.instructions.md` |

Copy default stubs verbatim (fetch URLs below). The `applyTo:` glob in each file's frontmatter handles automatic loading.

| Stub | URL |
|------|-----|
| `tests.instructions.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/instructions/tests.instructions.md` |
| `api-routes.instructions.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/instructions/api-routes.instructions.md` |
| `config.instructions.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/instructions/config.instructions.md` |
| `docs.instructions.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/instructions/docs.instructions.md` |

Write files to `.github/instructions/<name>` in the user's project.

After setup, replace `{{TEST_FRAMEWORK}}` and `{{TEST_COMMAND}}` tokens in `tests.instructions.md` with the values from §1.

---

## § 2.8 — Scaffold prompt files

> **Conditional (A17)**: If the user answered A17 = "No", skip this section entirely.
> If A17 = "Ask about each", present each prompt file by name and description before
> fetching and writing it. Only write the ones the user approves.

Write the following five files to `.github/prompts/` (fetch and write verbatim):

| File | URL |
|------|-----|
| `explain.prompt.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/prompts/explain.prompt.md` |
| `refactor.prompt.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/prompts/refactor.prompt.md` |
| `test-gen.prompt.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/prompts/test-gen.prompt.md` |
| `review-file.prompt.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/prompts/review-file.prompt.md` |
| `commit-msg.prompt.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/prompts/commit-msg.prompt.md` |

After writing, replace `{{THREE_CHECK_COMMAND}}`, `{{TEST_FRAMEWORK}}`, and `{{TEST_COMMAND}}` tokens using values from §1.

---

## § 2.9 — Scaffold Copilot setup steps workflow

Create `.github/workflows/copilot-setup-steps.yml`:

```yaml
name: "Copilot Setup Steps"

on:
  workflow_dispatch:

jobs:
  copilot-setup-steps:
    name: "Copilot Setup Steps"
    runs-on: ubuntu-latest
    timeout-minutes: 30
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

      # --- Runtime setup (uncomment and fill the section matching your stack) ---

      # Node.js / Bun
      # - uses: actions/setup-node@v4
      #   with:
      #     node-version: "{{RUNTIME_VERSION}}"
      # - run: {{INSTALL_COMMAND}}

      # Python
      # - uses: actions/setup-python@v5
      #   with:
      #     python-version: "{{RUNTIME_VERSION}}"
      # - run: pip install -r requirements.txt

      # Go
      # - uses: actions/setup-go@v5
      #   with:
      #     go-version: "{{RUNTIME_VERSION}}"

      # Rust
      # - uses: dtolnay/rust-toolchain@stable

      # --- Verification ---
      # - name: Build
      #   run: {{BUILD_COMMAND}}
      # - name: Test
      #   run: {{TEST_COMMAND}}
```

If the stack was detected in §1, uncomment and populate the matching runtime section. Remove unused runtime sections.

---

## § 2.10 — Configure MCP servers (E22 only)

**If E22 = A (None) or the user used Simple/Advanced setup**: skip this step entirely.

**If E22 = B (always-on only)** or **E22 = C (full)**: create `.vscode/mcp.json`:

```json
{
  "inputs": [
    {
      "type": "promptString",
      "id": "github-token",
      "description": "GitHub Personal Access Token (for MCP GitHub server)",
      "password": true
    }
  ],
  "servers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${workspaceFolder}"]
    },
    "git": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "${workspaceFolder}"]
    },
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${input:github-token}"
      },
      "disabled": true
    },
    "fetch": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-fetch"],
      "disabled": true
    }
  }
}
```

**If E22 = C**, also suggest stack-specific servers based on detected dependencies (PostgreSQL, Redis, Docker, AWS, etc.) using the mcp-builder skill if available.

---

## § 2.11 — Configure VS Code settings (E18 only)

**If E18 = No**: skip this step entirely.

**If E18 = Yes or Ask each time**: merge the following recommended settings into `.vscode/settings.json`.
If the file already exists, merge keys — do not overwrite existing values.

Fetch the settings template:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/vscode/settings.json
```

The template contains these recommended defaults:

```json
{
  "chat.useAgentsMdFile": true,
  "chat.useNestedAgentsMdFiles": true,
  "chat.useCustomAgentHooks": true,
  "chat.promptFilesRecommendations": true,
  "chat.plugins.enabled": true
}
```

Merge these into the project's `.vscode/settings.json`. If the file does not exist, create it with these contents. If it exists, add only the keys that are not already present.

---

## § 2.12 — Scaffold agent lifecycle hooks

> **Conditional (A16)**: If the user answered A16 = "No", skip this section entirely.
> If A16 = "Ask about each", present each hook script by name and purpose before
> fetching and writing it. Only write the ones the user approves. Always write
> `copilot-hooks.json` if at least one script is written.

Fetch and write the following hook files to the user's `.github/hooks/`:

**Configuration**: fetch and write to `.github/hooks/copilot-hooks.json`:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/copilot-hooks.json
```

**Bash scripts** (Linux/macOS) — fetch each to `.github/hooks/scripts/`:

| Script | URL |
|--------|-----|
| `session-start.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/session-start.sh` |
| `guard-destructive.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/guard-destructive.sh` |
| `post-edit-lint.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/post-edit-lint.sh` |
| `enforce-retrospective.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/enforce-retrospective.sh` |
| `save-context.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/save-context.sh` |
| `subagent-start.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/subagent-start.sh` |
| `subagent-stop.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/subagent-stop.sh` |

**PowerShell scripts** (Windows) — fetch each to `.github/hooks/scripts/`:

| Script | URL |
|--------|-----|
| `session-start.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/session-start.ps1` |
| `guard-destructive.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/guard-destructive.ps1` |
| `post-edit-lint.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/post-edit-lint.ps1` |
| `enforce-retrospective.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/enforce-retrospective.ps1` |
| `save-context.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/save-context.ps1` |
| `subagent-start.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/subagent-start.ps1` |
| `subagent-stop.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/hooks/scripts/subagent-stop.ps1` |

After writing the `.sh` files, make them executable:

```bash
chmod +x .github/hooks/scripts/*.sh
```

**If A16 = No**: skip this step entirely.

---

## § 2.13 — Write version file and section fingerprints

Write the installed template version to `.github/copilot-version.md` in the user's project.

Fetch the current template version:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/VERSION.md
```

**Compute section fingerprints** — run this command against the instructions file you just wrote:

```bash
echo "<!-- section-fingerprints"
for i in $(seq 1 9); do
  fp=$(awk "/^## §${i} —/{found=1; next} /^## §/{if(found) exit} found{print}" \
    .github/copilot-instructions.md | sha256sum | cut -c1-12)
  echo "§${i}=${fp}"
done
echo "-->"
```

Write to `.github/copilot-version.md`:

```markdown
# Installed Template Version

<!-- This file is read by the Update agent to compare your installed version against the upstream template. -->
<!-- Do not edit manually — it is updated automatically during instruction updates. -->

X.Y.Z

<!-- section-fingerprints
§1=<fingerprint>
§2=<fingerprint>
§3=<fingerprint>
§4=<fingerprint>
§5=<fingerprint>
§6=<fingerprint>
§7=<fingerprint>
§8=<fingerprint>
§9=<fingerprint>
-->
```

Replace `X.Y.Z` with the fetched version string. Replace each `<fingerprint>` with the computed value from the shell command above.

If the terminal is unavailable, omit the `<!-- section-fingerprints ... -->` block — the Update agent will fall back to heuristic comparison.

---

## § 2.14 — Generate Claude compatibility file (optional)

Ask the user: *"Generate a `CLAUDE.md` for Claude Code compatibility?"*

**If Yes**: fetch and write `CLAUDE.md` to the project root:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/CLAUDE.md
```

Replace all `{{PLACEHOLDER}}` tokens with values resolved in §1.

**If No**: skip this step.

This file is auto-detected by Claude Code and by VS Code when using Claude models.
It provides a lightweight mirror of the core project rules so teams using both tools
get consistent behaviour without maintaining two full instruction sets.

---

## § 3 — Scaffold workspace identity files

Create `.copilot/workspace/` and write eight workspace files from the upstream template.
This includes seven identity files plus `DOC_INDEX.json` (canonical machine-readable metadata index).

Replace all `{{PLACEHOLDER}}` tokens using values from §1.
Replace `{{SETUP_DATE}}` with today's date in `YYYY-MM-DD` format.

### Fetch all workspace stubs

Fetch all eight files in parallel from the template repository:

| Target path | Source URL |
|-------------|-----------|
| `.copilot/workspace/IDENTITY.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/workspace/IDENTITY.md` |
| `.copilot/workspace/SOUL.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/workspace/SOUL.md` |
| `.copilot/workspace/USER.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/workspace/USER.md` |
| `.copilot/workspace/TOOLS.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/workspace/TOOLS.md` |
| `.copilot/workspace/MEMORY.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/workspace/MEMORY.md` |
| `.copilot/workspace/DOC_INDEX.json` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/workspace/DOC_INDEX.json` |
| `.copilot/workspace/BOOTSTRAP.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/workspace/BOOTSTRAP.md` |
| `.copilot/workspace/HEARTBEAT.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/workspace/HEARTBEAT.md` |

For each file:

1. Fetch the content from the source URL.
2. Replace all `{{PLACEHOLDER}}` tokens with values resolved in §1.
3. Replace `{{SETUP_DATE}}` with today's date (`YYYY-MM-DD`).
4. Write to the target path in the user's project.

If any fetch fails, **stop immediately** and report the error. Do not proceed with partial writes.

---

## § 4 — Create documentation stubs

Create the following files if they do not exist. If they already exist (detected in §0c), skip or append as agreed.

### `CHANGELOG.md`

```markdown
# Changelog

All notable changes to **{{PROJECT_NAME}}** will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Copilot instructions scaffolded from [copilot-instructions-template](https://github.com/asafelobotomy/copilot-instructions-template).

---

<!--
Template for future entries:

## [X.Y.Z] - YYYY-MM-DD

### Added
- …

### Changed
- …

### Fixed
- …

### Removed
- …
-->
```

---

## § 5 — Self-destruct and final summary

Print the following summary, filling in actual file counts and dates:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SETUP COMPLETE — copilot-instructions-template vX.Y.Z
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ .github/copilot-instructions.md   populated
✓ .github/copilot-version.md        written (vX.Y.Z)
✓ .github/agents/                   6 model-pinned agents
✓ .github/skills/                   13 starter skills
✓ .github/instructions/             N path-specific stubs
✓ .github/prompts/                  5 slash-command prompts
✓ .github/hooks/                    hooks config + 10 scripts (5 sh + 5 ps1)
✓ .copilot/workspace/               8 workspace files (7 identity + DOC_INDEX.json)
✓ CHANGELOG.md                      [created / already existed]

Next steps:
  1. Open a Copilot chat and say "Check your heartbeat" to verify setup.
  2. Say "Run health check" to run the Doctor agent.
  3. Commit the scaffolded files: git add .github .copilot .vscode CHANGELOG.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then ask:

> "Setup is complete. Should I delete `SETUP.md` from your project now? (It's a machine-readable guide that's no longer needed.)"

If the user confirms, delete `SETUP.md` from the **user's project**. Do not delete it from the template repository.

Offer the Doctor agent handoff:

> "Would you like me to hand off to the Doctor agent for a full health check?"
