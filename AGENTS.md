# Agent Entry Point — copilot-instructions-template

This file is read by AI agents (GitHub Copilot and compatible agents) to understand how to interact with this repository.

---

## Trigger phrases

### Setup (first time)

When a user says any of the following in a Copilot chat:

- *"Setup from asafelobotomy/copilot-instructions-template"*
- *"Bootstrap this project from copilot-instructions-template"*
- *"Use the Lean/Kaizen Copilot template to set up this project"*
- *"Initialise this project with asafelobotomy/copilot-instructions-template"*
- *"Run the copilot-instructions-template setup"*

...perform the **Remote Bootstrap Sequence** below. No manual file copying is required from the user.

### Update (already set up)

When a user says any of the following in a project that **already has Copilot instructions installed**:

- *"Update your instructions"*
- *"Check for instruction updates"*
- *"Update from copilot-instructions-template"*
- *"Sync instructions with the template"*
- *"Check the template for updates"*
- *"Force check instruction updates"* *(bypasses version equality check)*

...perform the **Remote Update Sequence** below.

### Restore (from backup)

When a user says any of the following:

- *"Restore instructions from backup"*
- *"Roll back the instructions update"*
- *"List instruction backups"*

...perform the **Remote Restore Sequence** below.

### Tool operations

When a user says any of the following:

- *"Show me the toolbox"* / *"List available tools"*
- *"Search for a tool that ..."*
- *"Build a tool for ..."* / *"Create a tool to ..."*
- *"Save this to the toolbox"* / *"Add this to the toolbox"*
- *"Update the tool index"* / *"Rebuild INDEX.md"*
- *"Deprecate tool <name>"*

...follow the Tool Protocol in **§11** of `.github/copilot-instructions.md`. For search/build/save tasks, apply the full decision tree: Find → Search online → Build → Evaluate reusability → Save.

### Test coverage review

When a user says any of the following:

- *"Review my tests"* / *"Audit my test suite"*
- *"What tests should I add?"* / *"What tests am I missing?"*
- *"Check test coverage"* / *"Review test coverage"*
- *"Repo health review"* / *"Review repo health"*
- *"What's my coverage?"* / *"Coverage report"*
- *"Recommend CI tests"* / *"What CI workflows should I add?"*

...switch to **Review Mode** and perform a test coverage audit following the **§2 Test Coverage Review** protocol in `.github/copilot-instructions.md`. Produce a structured report covering: current coverage snapshot, well-covered/partial/untested modules, recommended local tests with priority, and ready-to-use CI workflow YAML snippets. Do not write test files or workflow files until explicitly instructed.

### Extension review

When a user says any of the following:

- *"Review extensions"* / *"Check my extensions"*
- *"Audit VS Code extensions"*
- *"What extensions should I install?"*
- *"Do I have the right extensions?"*
- *"Check for missing extensions"*
- *"Recommend extensions for this project"*

...switch to **Review Mode** and perform an extension audit following the **§2 Extension Review** protocol in `.github/copilot-instructions.md`. Present findings in three categories (Missing, Redundant, Unknown) with actionable recommendations. Do not auto-install.

### Skill operations

When a user says any of the following:

- *"Create a skill"* / *"Write a skill"* / *"Add a new skill"*
- *"Show my skills"* / *"List available skills"*
- *"Search for a skill that ..."*
- *"Find a skill for ..."*
- *"What skills do I have?"*

...follow the Skill Protocol in **§12** of `.github/copilot-instructions.md`. For creation tasks, activate the `skill-creator` skill if present. For search tasks, respect the `{{SKILL_SEARCH_PREFERENCE}}` setting (default: local-only).

### MCP operations

When a user says any of the following:

- *"Configure MCP servers"* / *"Set up MCP"*
- *"Add an MCP server"* / *"Add an MCP server for ..."*
- *"Show MCP servers"* / *"List MCP servers"*
- *"Check MCP configuration"* / *"Verify MCP setup"*

...follow the MCP Protocol in **§13** of `.github/copilot-instructions.md`. Use the decision tree (built-in tool → MCP server → community package → custom tool) and apply the quality gate before adding any new server.

---

## What this repo is

A generic, **living** GitHub Copilot instructions template grounded in **Lean/Kaizen** methodology. It provides:

> **⚠️ Codex models** (`GPT-5.x-Codex`) run autonomously and **cannot** present interactive prompts. Never use a Codex model for Setup — the interview will be silently skipped. Always use the **Setup agent** (pinned to Claude Sonnet 4.6) or select an interactive model manually.

- A structured `.github/copilot-instructions.md` template (§1–§13) with `{{PLACEHOLDER}}` tokens for project-specific values.
- A one-time setup process (`SETUP.md`) that Copilot runs to tailor everything to the target project's stack.
- An update process (`UPDATE.md`) that Copilot runs to fetch and apply improvements from this repo to an already-installed project.
- Four model-pinned agent files (`.github/agents/`) for VS Code 1.106+ — one each for Setup, Coding, Review, and Fast workflows.
- A reusable skill library (`.github/skills/`) following the [Agent Skills](https://agentskills.io) open standard — four starter skills included.
- Automatic pre-write backups so every update is reversible — stored in `.github/archive/`.
- Six workspace identity files that Copilot maintains across sessions.
- Documentation stubs (CHANGELOG, JOURNAL, BIBLIOGRAPHY, METRICS).
- A Living Update Protocol that authorises Copilot to improve the instructions as patterns emerge.

---

> **All sequences**: you are operating in the **user's current project**. All writes go there. Do not create, modify, or delete any files in `asafelobotomy/copilot-instructions-template`.

## Remote Bootstrap Sequence

### 1 — Fetch SETUP.md

Fetch and read the complete setup guide:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/SETUP.md
```

### 2 — Fetch the instructions template

Fetch and hold in memory the Copilot instructions template that will be populated and written to the user's project:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/copilot-instructions.md
```

### 3 — Run the setup

Follow the steps in `SETUP.md` exactly, operating on the **user's current project**.

- All file stubs (identity files, doc stubs) are embedded inline in `SETUP.md` — no further fetching from this repo is required.
- The instructions template fetched in step 2 is the file that gets populated with `{{PLACEHOLDER}}` values and written to the user's `.github/copilot-instructions.md`.

Setup outputs written to the **user's project**:

| File | Description |
|------|-------------|
| `.github/copilot-instructions.md` | Populated instructions (from the template fetched above) |
| `.github/agents/setup.agent.md` | Model-pinned Setup agent (Claude Sonnet 4.6) |
| `.github/agents/coding.agent.md` | Model-pinned Coding agent (GPT-5.3-Codex) |
| `.github/agents/review.agent.md` | Model-pinned Review agent (Claude Opus 4.6) |
| `.github/agents/fast.agent.md` | Model-pinned Fast agent (Claude Haiku 4.5) |
| `.github/skills/*/SKILL.md` | Reusable skill library (6 starter skills from template) |
| `.vscode/mcp.json` | MCP server configuration (created if E22 ≠ None) |
| `.copilot/workspace/IDENTITY.md` | Agent self-description |
| `.copilot/workspace/SOUL.md` | Agent values & reasoning patterns |
| `.copilot/workspace/USER.md` | Observed user profile |
| `.copilot/workspace/TOOLS.md` | Tool usage patterns |
| `.copilot/workspace/MEMORY.md` | Memory strategy |
| `.copilot/workspace/BOOTSTRAP.md` | Permanent setup origin record |
| `CHANGELOG.md` | Keep-a-Changelog stub |
| `JOURNAL.md` | ADR-style development journal |
| `BIBLIOGRAPHY.md` | File catalogue |
| `METRICS.md` | Kaizen baseline snapshot table |
| `.copilot/tools/INDEX.md` | Toolbox catalogue (created lazily on first tool save — §11) |

---

## Remote Update Sequence

### 1 — Fetch UPDATE.md

Fetch and read the complete update protocol:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/UPDATE.md
```

### 2 — Follow the update protocol

Follow every step in `UPDATE.md` exactly. The protocol: reads installed version; fetches current `VERSION`/`CHANGELOG.md`/template; builds §1–§9 change manifest (§10 always protected); presents Pre-flight Report; user chooses **U** (update all) / **S** (skip) / **C** (customise per-section); backs up to `.github/archive/pre-update-YYYY-MM-DD-vX.Y.Z/`; writes confirmed changes; appends to `JOURNAL.md` and `CHANGELOG.md`.

---

## Remote Restore Sequence

### 1 — Fetch UPDATE.md

The restore procedure is fully documented in the "Restore from backup" section of UPDATE.md. Fetch it:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/UPDATE.md
```

### 2 — Follow the Restore sequence

Locate **"## Restore from backup"** in UPDATE.md and follow it: scans `.github/archive/` for `pre-update-*` dirs; lists backups from `BACKUP-MANIFEST.md`; asks user to select; creates a pre-restore snapshot; copies selected backup to `.github/copilot-instructions.md`; appends to `JOURNAL.md` and `CHANGELOG.md`.

---

## File map

| File | Role |
|------|------|
| `AGENTS.md` | This file — AI agent entry point |
| `SETUP.md` | Complete setup guide (remote-executable) |
| `UPDATE.md` | Complete update + restore protocol (remote-executable) |
| `VERSION` | Current template version number (semver) |
| `CHANGELOG.md` | Template version history |
| `.github/copilot-instructions.md` | Generic instructions template with `{{PLACEHOLDER}}` tokens |
| `.github/agents/setup.agent.md` | Model-pinned Setup agent stub (Claude Sonnet 4.6) |
| `.github/agents/coding.agent.md` | Model-pinned Coding agent stub (GPT-5.3-Codex) |
| `.github/agents/review.agent.md` | Model-pinned Review agent stub (Claude Opus 4.6) |
| `.github/agents/fast.agent.md` | Model-pinned Fast agent stub (Claude Haiku 4.5) |
| `template/skills/skill-creator/SKILL.md` | Starter skill — meta-skill for authoring new skills |
| `template/skills/fix-ci-failure/SKILL.md` | Starter skill — CI failure diagnosis and resolution |
| `template/skills/lean-pr-review/SKILL.md` | Starter skill — Lean PR review with waste categories |
| `template/skills/conventional-commit/SKILL.md` | Starter skill — Conventional Commits message authoring |
| `template/skills/mcp-builder/SKILL.md` | Starter skill — MCP server creation and registration |
| `template/skills/webapp-testing/SKILL.md` | Starter skill — Playwright-based web app testing |
| `template/vscode/mcp.json` | MCP server configuration template |
| `template/workspace/IDENTITY.md` | Agent self-description stub |
| `template/workspace/SOUL.md` | Agent values & reasoning patterns stub |
| `template/workspace/USER.md` | User profile stub |
| `template/workspace/TOOLS.md` | Tool usage patterns stub |
| `template/workspace/MEMORY.md` | Memory strategy stub |
| `template/workspace/BOOTSTRAP.md` | Bootstrap record stub |
| `template/CHANGELOG.md` | Keep-a-Changelog stub (for consumer project) |
| `template/JOURNAL.md` | ADR journal stub |
| `template/BIBLIOGRAPHY.md` | File catalogue stub |
| `template/METRICS.md` | Metrics baseline table stub |
| `examples/valis/README.md` | Reference implementation |
| `.github/skills/<name>/SKILL.md` | Scaffolded skill library (skills copied from template during setup) |
| `.copilot/tools/INDEX.md` | Toolbox catalogue — created in consumer project on first tool save |

---

## Canonical triggers

| Action | Trigger phrase |
|--------|----------------|
| First-time setup | *"Setup from asafelobotomy/copilot-instructions-template"* |
| Check for updates | *"Update your instructions"* |
| Force full comparison | *"Force check instruction updates"* |
| Restore a backup | *"Restore instructions from backup"* |
| List available backups | *"List instruction backups"* |
| Show toolbox | *"Show me the toolbox"* |
| Build a tool | *"Build a tool for ..."* |
| Save to toolbox | *"Save this to the toolbox"* |
| Review extensions | *"Review extensions"* / *"Check my extensions"* |
| Review test coverage | *"Review my tests"* / *"Check test coverage"* / *"Repo health review"* |
| Create a skill | *"Create a skill"* / *"Write a skill"* |
| List skills | *"Show my skills"* / *"List available skills"* |
| Search for a skill | *"Search for a skill that ..."* / *"Find a skill for ..."* |
| Configure MCP | *"Configure MCP servers"* / *"Set up MCP"* |
| Add MCP server | *"Add an MCP server"* / *"Add an MCP server for ..."* |
| List MCP servers | *"Show MCP servers"* / *"List MCP servers"* |
