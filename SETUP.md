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

If the command fails, returns no output, or the directory has no `.git/` folder:
ask the user to confirm this is their target project directory before proceeding.
Do not stop — just seek verbal confirmation.

If the output contains `asafelobotomy/copilot-instructions-template`, **STOP** and
tell the user:

> "This appears to be the template repository itself, not a consumer project.
> Please open a terminal inside your target project directory and re-run the setup there."

Only proceed once you have confirmed the working directory is the user's own project.

### § 0a — Existing Copilot instructions

Check whether `.github/copilot-instructions.md` already exists in the user's project.

If it exists, use `ask_questions` to present the choice:

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

Wait for the user's choice before proceeding. Default is **A** if the user types "skip" or says nothing.

> **Fallback**: If `ask_questions` is unavailable (CLI, Codex, or cloud environments), present as a numbered list in chat.

### § 0b — Existing workspace identity files

Check whether `.copilot/workspace/` exists and contains any files (IDENTITY.md, SOUL.md, etc.).

If files exist, use `ask_questions`:

```ask_questions
header: "Workspace identity files"
question: "Workspace identity files already exist in .copilot/workspace/. These may contain session history and learned preferences. How should I handle them?"
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

Default is **K**.

> **Fallback**: If `ask_questions` is unavailable, present as a numbered list in chat.

### § 0c — Existing documentation stubs

Check for `CHANGELOG.md` in the project root. Note if it exists — skip creating it if it already exists (or ask to append an entry if the user prefers).

### § 0d — User Preference Interview

Use `ask_questions` to present the tier selection:

```ask_questions
header: "Setup tier"
question: "Which setup level do you want?"
options:
  - label: "Q — Quick"
    description: "5 questions, ~3 min, sensible defaults for everything else"
    recommended: true
  - label: "S — Standard"
    description: "17 questions, ~6 min"
  - label: "F — Full"
    description: "23 questions, ~10 min"
  - label: "Skip"
    description: "Use all defaults immediately — no questions asked"
allowFreeformInput: false
```

Then present the corresponding questions for the selected tier.

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

- **E23 — Claude compatibility**: Should I generate a `CLAUDE.md` file for Claude Code compatibility?
  Options: Yes | No

- **E24 — Thinking effort**: How should I configure thinking effort for reasoning models?
  Options: A — Use MODELS.md recommendations (Low/Medium/High per agent role) | B — All High (maximum reasoning depth) | C — All Medium (balanced) | D — Skip (leave at VS Code defaults)

#### § 0e — Pre-flight summary

After all questions are answered, present a summary:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SETUP SUMMARY — copilot-instructions-template vX.Y.Z
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Files that will be CREATED:
  .github/copilot-instructions.md     (populated from template)
  .github/copilot-version.md          (installed template version)
  .github/agents/*.agent.md           (10 model-pinned agents)
  .github/skills/*/SKILL.md           (15 starter skills)
  .github/instructions/*.md           (path-specific stubs)
  .github/prompts/*.prompt.md         (slash command prompts)
  .github/hooks/copilot-hooks.json    (hook configuration)
  .github/hooks/scripts/*.sh + *.ps1  (hook scripts)
  .github/starter-kits/*/              (stack-specific plugin kits, if matched)
  .copilot/workspace/*.md + DOC_INDEX.json (9 workspace files)
  CHANGELOG.md

Files that will be ARCHIVED (if chosen):
  .github/archive/pre-setup-YYYY-MM-DD/

Ready to proceed. Type "go" to continue or "stop" to cancel.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use `ask_questions` to confirm:

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

If they choose "Stop", halt immediately. If they choose "Go", proceed to §1.

> **Fallback**: If `ask_questions` is unavailable, wait for the user to type "go" or "stop" in chat.

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
| E24 | Thinking effort | [answer or "MODELS.md recommendations"] |
```

Write the populated file to `.github/copilot-instructions.md` in the user's project.

---

## § 2.4 — Validate placeholder resolution

Before continuing, grep the written `.github/copilot-instructions.md` for any remaining
`{{.*}}` tokens:

```text
grep -oE '\{\{[^}]+\}\}' .github/copilot-instructions.md
```

If any are found, present them to the user using `ask_questions` with freeform input enabled:

```ask_questions
header: "Unresolved placeholder: {{PLACEHOLDER_NAME}}"
question: "I couldn't auto-detect a value for {{PLACEHOLDER_NAME}}. What should it be?"
allowFreeformInput: true
```

Batch up to 4 unresolved placeholders per `ask_questions` call. Substitute the user's answers and re-write the file before continuing to §2.5.
Do not proceed with unresolved `{{...}}` tokens in the instructions file.

> **Fallback**: If `ask_questions` is unavailable, present placeholders as a numbered list in chat.
>
> **Parallelization hint**: Steps §2.5 through §2.14 (including §2.11a) are independent
> file-creation tasks. Fetch all URLs in parallel where your runtime supports it
> (e.g., batch `fetch_webpage` calls). Write each file group as soon as its fetch
> completes — do not wait for all groups.

---

## § 2.5 — Write model-pinned agent files

> **Architecture note**: Agent files are fetched directly from `.github/agents/` in the template
> repository. Unlike skills and hooks, there is no `template/agents/` mirror — agents contain
> no `{{PLACEHOLDER}}` tokens and are delivered verbatim. This is a deliberate exception to the
> `template/` staging pattern; it avoids maintaining a redundant mirror for files that require
> no token substitution and change infrequently.

Create `.github/agents/` and write all agent files. Use **dynamic discovery** to ensure new
agents added to the template are never missed: fetch the repository tree and enumerate every
`.agent.md` file at the canonical path.

**Step 1 — Enumerate agents via GitHub API tree**:

```text
GET https://api.github.com/repos/asafelobotomy/copilot-instructions-template/git/trees/main?recursive=1
Accept: application/vnd.github+json
```

Filter the `tree[]` array for entries where `type == "blob"` and `path` matches
`.github/agents/*.agent.md`. Collect the full path list.

> **Truncation guard**: if the response contains `"truncated": true`, the tree is incomplete
> (repo exceeded the 100,000-entry or 7 MB limit). Fall back to the **known-agents table**
> below instead of proceeding with the partial list, to guarantee no agent is silently missed.

**Step 2 — Fetch and write each agent file**:

For each agent path discovered in step 1, fetch verbatim from the template repository
(substitute the actual agent filename for `<agent-path>`):

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/coding.agent.md
```

Construct the URL by replacing `coding.agent.md` with the filename from step 1.
Write each file to the same relative path (`.github/agents/`) in the user's project.
If any fetch fails, **stop immediately** and report the error.

**Known agents** (current as of v4.1.1 — the dynamic step above supersedes this list and
will discover any agents added in future releases):

| Agent file |
|------------|
| `.github/agents/coding.agent.md` |
| `.github/agents/doctor.agent.md` |
| `.github/agents/explore.agent.md` |
| `.github/agents/extensions.agent.md` |
| `.github/agents/fast.agent.md` |
| `.github/agents/researcher.agent.md` |
| `.github/agents/review.agent.md` |
| `.github/agents/security.agent.md` |
| `.github/agents/setup.agent.md` |
| `.github/agents/update.agent.md` |

**Fallback** (if the API tree call is unavailable): fetch each agent in the known-agents
table above using the same URL pattern as step 2 (substitute the agent filename).
For example: `.github/agents/security.agent.md` →
`https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/security.agent.md`.
If a file returns HTTP 404, skip it silently (it may have been renamed or removed).

---

## § 2.6 — Scaffold skill library

Create `.github/skills/` and write all skill files. Use **dynamic discovery** (same approach as
§ 2.5) to ensure new skills are never missed.

**Step 1 — Enumerate skills via GitHub API tree**:

```text
GET https://api.github.com/repos/asafelobotomy/copilot-instructions-template/git/trees/main?recursive=1
```

Filter for entries where `path` matches `template/skills/*/SKILL.md`. Collect the skill name
from the subdirectory component.

> **Truncation guard**: if the response contains `"truncated": true`, the tree is incomplete.
> Fall back to the **known-skills table** below instead of continuing with the partial list.

**Step 2 — Fetch and write each skill**:

For each skill discovered, fetch its `SKILL.md` from the template repository
(substitute the actual skill folder name for `<skill-name>`):

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/skills/conventional-commit/SKILL.md
```

Construct the URL by replacing `conventional-commit` with the skill directory name from
step 1. Write to `.github/skills/<skill-name>/SKILL.md` in the user's project. If any
fetch fails, **stop immediately**.

**Known skills** (current as of v4.1.1 — the dynamic step above supersedes this list):

| Target path | Fetch suffix (under `template/skills/`) |
|-------------|----------------------------------------|
| `.github/skills/agentic-workflows/SKILL.md` | `agentic-workflows/SKILL.md` |
| `.github/skills/conventional-commit/SKILL.md` | `conventional-commit/SKILL.md` |
| `.github/skills/create-adr/SKILL.md` | `create-adr/SKILL.md` |
| `.github/skills/extension-review/SKILL.md` | `extension-review/SKILL.md` |
| `.github/skills/fix-ci-failure/SKILL.md` | `fix-ci-failure/SKILL.md` |
| `.github/skills/issue-triage/SKILL.md` | `issue-triage/SKILL.md` |
| `.github/skills/lean-pr-review/SKILL.md` | `lean-pr-review/SKILL.md` |
| `.github/skills/mcp-builder/SKILL.md` | `mcp-builder/SKILL.md` |
| `.github/skills/mcp-management/SKILL.md` | `mcp-management/SKILL.md` |
| `.github/skills/plugin-management/SKILL.md` | `plugin-management/SKILL.md` |
| `.github/skills/skill-creator/SKILL.md` | `skill-creator/SKILL.md` |
| `.github/skills/skill-management/SKILL.md` | `skill-management/SKILL.md` |
| `.github/skills/test-coverage-review/SKILL.md` | `test-coverage-review/SKILL.md` |
| `.github/skills/tool-protocol/SKILL.md` | `tool-protocol/SKILL.md` |
| `.github/skills/webapp-testing/SKILL.md` | `webapp-testing/SKILL.md` |

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

After all substitutions, validate no `{{PLACEHOLDER}}` tokens remain in any written instruction stub:

```bash
grep -rE '\{\{[^}]+\}\}' .github/instructions/
```

If any are found, present them to the user using the same prompt as §2.4.

---

## § 2.8 — Scaffold prompt files

> **Conditional (A17)**: If the user answered A17 = "No", skip this section entirely.
> If A17 = "Ask about each", present each prompt file by name and description before
> fetching and writing it. Only write the ones the user approves.

Write the following six files to `.github/prompts/` (fetch and write verbatim):

| File | URL |
|------|-----|
| `explain.prompt.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/prompts/explain.prompt.md` |
| `context-map.prompt.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/prompts/context-map.prompt.md` |
| `refactor.prompt.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/prompts/refactor.prompt.md` |
| `test-gen.prompt.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/prompts/test-gen.prompt.md` |
| `review-file.prompt.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/prompts/review-file.prompt.md` |
| `commit-msg.prompt.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/prompts/commit-msg.prompt.md` |

After writing, replace `{{THREE_CHECK_COMMAND}}`, `{{TEST_FRAMEWORK}}`, and `{{TEST_COMMAND}}` tokens using values from §1.

---

## § 2.9 — Scaffold Copilot setup steps workflow

Fetch the setup steps workflow template and write it to `.github/workflows/copilot-setup-steps.yml`:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/copilot-setup-steps.yml
```

If the stack was detected in §1, uncomment and populate the matching runtime section inside the fetched file. Remove unused runtime sections. Replace `{{RUNTIME_VERSION}}`, `{{INSTALL_COMMAND}}`, `{{BUILD_COMMAND}}`, and `{{TEST_COMMAND}}` tokens using values from §1.

---

## § 2.10 — Configure MCP servers (E22 only)

**If E22 = A (None) or the user used Simple/Advanced setup**: skip this step entirely.

**If E22 = B (always-on only)** or **E22 = C (full)**: create `.vscode/mcp.json`.

### Sandbox detection (Linux only)

Before generating the config, detect whether the system uses a symlinked home directory (immutable Linux distros like Fedora Atomic, Bazzite, Silverblue, NixOS). The `bwrap` sandbox cannot follow symlinks for write paths — sandbox must be disabled on these systems.

**Detection rule**: if the OS is Linux, check whether `/home` resolves to a different path (e.g., `/var/home`). Run in terminal or evaluate programmatically:

```bash
[[ "$(readlink -f /home)" != "/home" ]] && echo "immutable" || echo "standard"
```

- **Result = `standard`** (or macOS): use the **sandboxed variant** below.
- **Result = `immutable`**: use the **unsandboxed variant** below.

### Sandboxed variant (standard Linux / macOS — default)

```json
{
  "sandbox": {
    "filesystem": {
      "allowWrite": ["${userHome}/.npm"]
    }
  },
  "servers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${workspaceFolder}"],
      "sandboxEnabled": true,
      "sandbox": {
        "filesystem": {
          "allowWrite": ["${workspaceFolder}", "${userHome}/.npm"],
          "denyRead": ["${userHome}/.ssh", "${userHome}/.gnupg", "${userHome}/.aws"]
        }
      }
    },
    "git": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "${workspaceFolder}"]
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "disabled": true
    },
    "fetch": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-fetch"],
      "disabled": true
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "disabled": true
    }
  }
}
```

### Unsandboxed variant (immutable Linux distros)

Use this when the detection rule above returns `immutable`. The filesystem MCP server already restricts itself to `${workspaceFolder}` by design.

```json
{
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
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "disabled": true
    },
    "fetch": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-fetch"],
      "disabled": true
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "disabled": true
    }
  }
}
```

**If E22 = C**, enable relevant servers from the base config and add stack-specific servers based on the dependencies detected in §1.

Enable these from the base config when appropriate:

| Server | When to enable |
|--------|----------------|
| `github` | Project uses GitHub (issues, PRs, Actions, CI) |
| `fetch` | Agent needs to read web docs, APIs, or external resources |
| `context7` | Project uses any third-party libraries (provides live, version-specific docs) |

Add stack-specific servers for detected dependencies. Common options:

| Stack | Server | Transport |
|-------|--------|-----------|
| Browser / UI testing | `@playwright/mcp` (Microsoft) | `npx -y @playwright/mcp@latest` |
| PostgreSQL | Search MCP Marketplace (`code.visualstudio.com/mcp`) for `postgres` | varies |
| SQLite | Search MCP Marketplace for `sqlite` | varies |
| Redis | Search MCP Marketplace for `redis` | varies |
| Docker | Search MCP Marketplace for `docker` | varies |
| AWS | Search MCP Marketplace for `aws` | varies |

> Note: the official reference implementations for database servers (postgres, sqlite, redis) were moved to `servers-archived`. Always search the MCP Marketplace or `registry.modelcontextprotocol.io` to find an actively maintained replacement rather than using the archived packages.

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
  "chat.mcp.autostart": "newAndOutdated",
  "chat.subagents.allowInvocationsFromSubagents": true,
  "chat.useAgentsMdFile": true,
  "chat.useNestedAgentsMdFiles": true,
  "chat.useCustomAgentHooks": true,
  "chat.promptFilesRecommendations": true,
  "chat.plugins.enabled": true
}
```

Merge these into the project's `.vscode/settings.json`. If the file does not exist, create it with these contents. If it exists, add only the keys that are not already present.

Also fetch the extension recommendations template:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/vscode/extensions.json
```

Merge the `recommendations` array into the project's `.vscode/extensions.json`. If the file does not exist, create it. If it exists, append entries that are not already present — do not duplicate or overwrite.

---

## § 2.11a — Install starter-kit plugin (automatic)

Starter kits are VS Code agent plugins that add stack-specific skills, instructions, and
prompts. They are installed automatically based on the stack detected in §1.

<!-- markdownlint-disable MD007 MD029 -->
1. **Fetch the registry**:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/starter-kits/REGISTRY.json
```

2. **Match the detected stack** — for each kit in `kits[]`, check:
   - Does any file in `detect.files` exist in the consumer project?
   - Does `detect.language` match `{{LANGUAGE}}` from §1?
   - Does any entry in `detect.dependencies` appear in the project's dependency list?

   If any condition matches, the kit is a candidate. A project may match multiple kits
   (e.g., `typescript` + `react` + `docker`).

3. **Present matches to the user** using `ask_questions`:

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

   - **Yes** — install all matched kits
   - **Pick** — present a second `ask_questions` call with `multiSelect: true` listing each matched kit by name and description, then install only the selected ones
   - **Skip** — skip starter-kit installation entirely

   > **Fallback**: If `ask_questions` is unavailable, present as a numbered list in chat.

4. **Fetch and write kit files** — for each selected kit, fetch every file listed in that
   kit's `files[]` array from the template repository:

   Base URL: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/starter-kits/<kit-name>/`

   Write each file to `.github/starter-kits/<kit-name>/` in the consumer project, preserving
   the subdirectory structure.

5. **Register the plugin location** — add a `chat.pluginLocations` entry to
   `.vscode/settings.json` for each installed kit:

```json
{
  "chat.pluginLocations": [
    ".github/starter-kits/python",
    ".github/starter-kits/docker"
  ]
}
```

   If the key already exists, append entries — do not overwrite.

6. **Report** — list the installed kits and their contents:

```text
Installed starter kits:
  ✓ python  — 2 skills, 2 instructions, 1 prompt
  ✓ docker  — 1 skill, 1 instruction, 1 prompt
```
<!-- markdownlint-enable MD007 MD029 -->

> **No matching kits?** If §1 detected a stack but no kit matches, or if the consumer
> chose "skip", print: "No starter kits installed. You can install one later by saying
> 'Install a starter kit'."

---

## § 2.12 — Scaffold agent lifecycle hooks

> **Conditional (A16)**: If the user answered A16 = "No", skip this section entirely.
> If A16 = "Ask about each", present each hook script by name and purpose before
> fetching and writing it. Only write the ones the user approves. Always write
> `copilot-hooks.json` if at least one script is written.

Fetch and write the following hook files to the user's `.github/hooks/`:

**Configuration**: fetch and write to `.github/hooks/copilot-hooks.json`:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/copilot-hooks.json
```

**Bash scripts** (Linux/macOS) — fetch each to `.github/hooks/scripts/`:

| Script | URL |
|--------|-----|
| `lib-hooks.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/lib-hooks.sh` |
| `scan-secrets.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/scan-secrets.sh` |
| `session-start.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/session-start.sh` |
| `guard-destructive.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/guard-destructive.sh` |
| `post-edit-lint.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/post-edit-lint.sh` |
| `enforce-retrospective.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/enforce-retrospective.sh` |
| `save-context.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/save-context.sh` |
| `subagent-start.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/subagent-start.sh` |
| `subagent-stop.sh` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/subagent-stop.sh` |

**PowerShell scripts** (Windows) — fetch each to `.github/hooks/scripts/`:

| Script | URL |
|--------|-----|
| `scan-secrets.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/scan-secrets.ps1` |
| `session-start.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/session-start.ps1` |
| `guard-destructive.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/guard-destructive.ps1` |
| `post-edit-lint.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/post-edit-lint.ps1` |
| `enforce-retrospective.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/enforce-retrospective.ps1` |
| `save-context.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/save-context.ps1` |
| `subagent-start.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/subagent-start.ps1` |
| `subagent-stop.ps1` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/hooks/scripts/subagent-stop.ps1` |

After writing the `.sh` files, make them executable:

```bash
chmod +x .github/hooks/scripts/*.sh
```

**If A16 = No**: skip this step entirely.

---

## § 2.13 — Write version file, section fingerprints, and file manifest

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

**Compute file-manifest hashes** — run this command to record content hashes for all
installed companion files. These hashes allow the Update agent to accurately distinguish
between files the user has modified vs files that are simply out of date with the template:

```bash
echo "<!-- file-manifest"
for f in \
  .github/agents/*.agent.md \
  .github/skills/*/SKILL.md \
  .github/hooks/copilot-hooks.json \
  .github/hooks/scripts/*.sh \
  .github/hooks/scripts/*.ps1 \
  .github/instructions/*.instructions.md \
  .github/prompts/*.prompt.md \
  .github/workflows/copilot-setup-steps.yml \
  .copilot/workspace/*.md \
  .copilot/workspace/DOC_INDEX.json; do
  [ -f "$f" ] || continue
  h=$(sha256sum "$f" | cut -c1-12)
  echo "${f}=${h}"
done
echo "-->"
```

Write to `.github/copilot-version.md`:

```markdown
# Installed Template Version

<!-- This file is read by the Update agent to compare your installed version against the upstream template. -->
<!-- Do not edit manually — it is updated automatically during instruction updates. -->

X.Y.Z
Applied: YYYY-MM-DD

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

<!-- file-manifest
.github/agents/coding.agent.md=<hash>
.github/agents/doctor.agent.md=<hash>
.github/agents/explore.agent.md=<hash>
.github/agents/extensions.agent.md=<hash>
.github/agents/fast.agent.md=<hash>
.github/agents/researcher.agent.md=<hash>
.github/agents/review.agent.md=<hash>
.github/agents/security.agent.md=<hash>
.github/agents/setup.agent.md=<hash>
.github/agents/update.agent.md=<hash>
.github/workflows/copilot-setup-steps.yml=<hash>
... (one line per installed companion file)
-->

<!-- setup-answers
LANGUAGE=<resolved value>
RUNTIME=<resolved value>
PACKAGE_MANAGER=<resolved value>
TEST_FRAMEWORK=<resolved value>
TEST_COMMAND=<resolved value>
TYPE_CHECK_COMMAND=<resolved value>
BUILD_COMMAND=<resolved value>
PROJECT_NAME=<resolved value>
... (one line per resolved {{PLACEHOLDER}} token — omit any left as {{...}})
-->
```

Replace `X.Y.Z` with the fetched version string. Replace `Applied: YYYY-MM-DD` with today's
date. Replace each `<fingerprint>` and `<hash>` with the computed values from the shell
commands above. Populate the `<!-- setup-answers ... -->` block with every `{{PLACEHOLDER}}`
token that was successfully resolved during §1 and §2.4 — record the placeholder name (without
`{{` and `}}`) as the key and the resolved value as the value. Omit any placeholder that
remained unresolved (still contains `{{...}}`).

If the terminal is unavailable, omit both the `<!-- section-fingerprints ... -->` and
`<!-- file-manifest ... -->` blocks — the Update agent will fall back to API-based content
comparison. Always write the `<!-- setup-answers ... -->` block (it requires no terminal).

---

## § 2.14 — Generate Claude compatibility file (E23 only)

> **Conditional (E23)**: If the user answered E23 = "No", skip this step entirely.

**If E23 = Yes**: fetch and write `CLAUDE.md` to the project root:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/CLAUDE.md
```

Replace all `{{PLACEHOLDER}}` tokens with values resolved in §1.

This file is auto-detected by Claude Code and by VS Code when using Claude models.
It provides a lightweight mirror of the core project rules so teams using both tools
get consistent behaviour without maintaining two full instruction sets.

---

## § 2.15 — Install companion extension (optional)

The `copilot-profile-tools` companion extension enables profile-aware extension
management via Language Model Tools. It is optional — the Extensions agent
falls back to CLI-only mode when the extension is absent.

<!-- markdownlint-disable MD007 MD029 -->
1. **Ask the user** using `ask_questions`:

```ask_questions
header: "Companion extension"
question: "The copilot-profile-tools extension enables profile-aware extension management (active profile detection, profile isolation, in-process extension enumeration). Install it?"
options:
  - label: "Yes"
    description: "Install the companion extension"
  - label: "Skip"
    description: "Proceed without it — the Extensions agent uses CLI fallback"
    recommended: true
allowFreeformInput: false
```

   > **Fallback**: If `ask_questions` is unavailable, present as a yes/skip choice in chat.

   - **Skip** — proceed without the extension. The Extensions agent uses CLI fallback.

2. **Install** — if the user chose "yes":

   Try the VS Code Marketplace first:

   ```bash
   code --install-extension asafelobotomy.copilot-profile-tools
   ```

   If a repo-specific profile was created or recommended earlier, target it:

   ```bash
   code --install-extension asafelobotomy.copilot-profile-tools --profile "{{PROJECT_NAME}}"
   ```

   If the Marketplace install fails (offline, restricted network, Marketplace
   unavailable), fall back to the pre-built VSIX from GitHub Releases:

   ```bash
   # Fetch latest VSIX URL from GitHub Releases API
   # Download the .vsix file
   code --install-extension /tmp/copilot-profile-tools.vsix
   ```

3. **Add to workspace recommendations** — merge into `.vscode/extensions.json`:

   ```json
   {
     "recommendations": [
       "asafelobotomy.copilot-profile-tools"
     ]
   }
   ```

   If the file exists, append to the `recommendations` array. If it does not
   exist, create it with the content above.

4. **Report**:

```text
Companion extension:
  ✓ copilot-profile-tools — installed (Marketplace)
```

   Or if skipped: `⊘ copilot-profile-tools — skipped (CLI fallback active)`
<!-- markdownlint-enable MD007 MD029 -->

---

## § 3 — Scaffold workspace identity files

Create `.copilot/workspace/` and write nine workspace files from the upstream template.
This includes eight identity files plus `DOC_INDEX.json` (canonical machine-readable metadata index).

Replace all `{{PLACEHOLDER}}` tokens using values from §1.
Replace `{{SETUP_DATE}}` with today's date in `YYYY-MM-DD` format.

### Fetch all workspace stubs

Fetch all nine files in parallel from the template repository:

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
| `.copilot/workspace/RESEARCH.md` | `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/workspace/RESEARCH.md` |

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
✓ .github/agents/                   10 model-pinned agents
✓ .github/skills/                   15 starter skills
✓ .github/instructions/             N path-specific stubs
✓ .github/prompts/                  6 slash-command prompts
✓ .github/hooks/                    hooks config + 17 scripts (9 sh + 8 ps1)
✓ .github/starter-kits/             N starter-kit plugins (or "none matched")
✓ .copilot/workspace/               9 workspace files (8 identity + DOC_INDEX.json)
✓ CHANGELOG.md                      [created / already existed]

Next steps:
  1. Open a Copilot chat and say "Check your heartbeat" to verify setup.
  2. Say "Run health check" to run the Doctor agent.
  3. Commit the scaffolded files: git add .github .copilot .vscode CHANGELOG.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then use `ask_questions` for post-setup cleanup:

```ask_questions
header: "Delete SETUP.md"
question: "Setup is complete. Should I delete SETUP.md from your project? It's a machine-readable guide that's no longer needed."
options:
  - label: "Yes"
    description: "Delete SETUP.md from this project"
    recommended: true
  - label: "No"
    description: "Keep SETUP.md for reference"
allowFreeformInput: false
```

> **Fallback**: If `ask_questions` is unavailable, present as yes/no choices in chat.

If the user confirms, delete `SETUP.md` from the **user's project**. Do not delete it from the template repository.

Offer the Doctor agent handoff via `ask_questions`:

```ask_questions
header: "Health check"
question: "Would you like me to hand off to the Doctor agent for a full health check?"
options:
  - label: "Yes"
    description: "Run a Doctor health check now"
    recommended: true
  - label: "No"
    description: "Skip the health check"
allowFreeformInput: false
```

> **Fallback**: If `ask_questions` is unavailable, present as yes/no in chat.
