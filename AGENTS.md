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

Canonical sources for full inventory:

- `BIBLIOGRAPHY.md` — exhaustive file-level catalogue with LOC
- `.copilot/workspace/DOC_INDEX.json` — canonical machine-readable metadata index

High-signal map (machine-relevant and navigation-critical paths):

| Path | Role |
|------|------|
| `AGENTS.md` | AI entry point — trigger phrases + remote sequences |
| `SETUP.md` | Complete setup guide (remote-executable) |
| `UPDATE.md` | Complete update + restore protocol (remote-executable) |
| `.github/copilot-instructions.md` | Primary instructions template (§1–§13) |
| `.github/agents/` | Model-pinned agents |
| `.github/skills/` | Repo skill library |
| `template/skills/` | Starter skill stubs scaffolded into consumer projects |
| `.github/hooks/` | Hook configuration + scripts |
| `template/hooks/` | Hook templates scaffolded into consumer projects |
| `.github/instructions/` | Path-specific instruction files |
| `.github/prompts/` | Slash-command prompt files |
| `.github/workflows/` | CI/CD workflows |
| `docs/` | Human-readable guides |
| `.copilot/workspace/` | Workspace identity files + canonical `DOC_INDEX.json` |
| `tests/` | Script tests and guardrail checks |
| `scripts/` | Utility scripts |
| `MIGRATION.md` | Per-version migration registry |
| `CHANGELOG.md` | Template release history |
| `JOURNAL.md` | ADR-style decision log |
| `METRICS.md` | Kaizen baseline snapshots |

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

- Workspace identity file stubs and documentation stubs are embedded inline in `SETUP.md`. However, SETUP.md also fetches agent files, skill files, prompt files, path instruction files, and hook scripts from upstream during §2.5–§2.12. If any fetch fails, SETUP.md will instruct you to stop — do not attempt to continue with partial writes.
- The instructions template fetched in step 2 is the file that gets populated with `{{PLACEHOLDER}}` values and written to the user's `.github/copilot-instructions.md`.

Setup outputs written to the **user's project**:

| File | Description |
|------|-------------|
| `.github/copilot-instructions.md` | Populated instructions (from the template fetched above) |
| `.github/agents/setup.agent.md` | Model-pinned Setup agent (Claude Sonnet 4.6) |
| `.github/agents/coding.agent.md` | Model-pinned Coding agent (GPT-5.3-Codex) |
| `.github/agents/review.agent.md` | Model-pinned Review agent (GPT-5.4) |
| `.github/agents/fast.agent.md` | Model-pinned Fast agent (Claude Haiku 4.5) |
| `.github/agents/update.agent.md` | Model-pinned Update agent (Claude Sonnet 4.6) |
| `.github/agents/doctor.agent.md` | Model-pinned Doctor agent (Claude Sonnet 4.6) |
| `.github/hooks/copilot-hooks.json` | Agent lifecycle hooks configuration |
| `.github/hooks/scripts/*.sh` | Five starter hook scripts (security, formatting, retrospective, context) |
| `.github/skills/*/SKILL.md` | Reusable skill library (13 starter skills from template) |
| `.vscode/mcp.json` | MCP server configuration (created if E22 ≠ None) |
| `.copilot/workspace/IDENTITY.md` | Agent self-description |
| `.copilot/workspace/SOUL.md` | Agent values & reasoning patterns |
| `.copilot/workspace/USER.md` | Observed user profile |
| `.copilot/workspace/TOOLS.md` | Tool usage patterns |
| `.copilot/workspace/MEMORY.md` | Memory strategy |
| `.copilot/workspace/DOC_INDEX.json` | Canonical machine-readable inventory for docs metadata |
| `.copilot/workspace/BOOTSTRAP.md` | Permanent setup origin record |
| `.copilot/workspace/HEARTBEAT.md` | Event-driven health check checklist |
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

Follow every step in `UPDATE.md` exactly. The protocol: reads installed version; fetches `VERSION.md`, `MIGRATION.md`, `CHANGELOG.md`, and template (at both installed-version tag and latest); performs a version-walk across all intermediate versions using MIGRATION.md; builds a three-way merge change manifest for §1–§9 sections (§10 always protected); collects companion file changes (agents, skills, hooks, MCP config); flags breaking changes; presents Per-version Pre-flight Report; user chooses **U** (update all) / **S** (skip) / **C** (customise per-section and per-companion-file); backs up instructions + modified companion files to `.github/archive/pre-update-YYYY-MM-DD-vX.Y.Z/`; writes confirmed changes; resolves new placeholders; appends to `JOURNAL.md` and `CHANGELOG.md`.

---

## Remote Restore Sequence

### 1 — Fetch UPDATE.md

The restore procedure is fully documented in the "Restore from backup" section of UPDATE.md. Fetch it:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/UPDATE.md
```

### 2 — Follow the Restore sequence

Locate **"## Restore from backup"** in UPDATE.md and follow it: scans `.github/archive/` for `pre-update-*` dirs; lists backups from `BACKUP-MANIFEST.md`; asks user to select; creates a pre-restore snapshot; copies selected backup to `.github/copilot-instructions.md`; appends to `JOURNAL.md` and `CHANGELOG.md`.

## High-Signal File Map

Use these navigation anchors first. For exhaustive inventory, read `BIBLIOGRAPHY.md` or `.copilot/workspace/DOC_INDEX.json` instead of relying on a duplicated path dump here.

| Path | Role |
|------|------|
| `AGENTS.md` | This file — trigger phrases and remote sequences |
| `.github/copilot-instructions.md` | Primary instructions template (§1–§13) |
| `SETUP.md` | Remote setup protocol |
| `UPDATE.md` | Remote update and restore protocol |
| `MIGRATION.md` | Per-version migration registry |
| `README.md` | Human landing page and feature overview |
| `llms.txt` | Concise LLM-facing summary |
| `llms-ctx.txt` | Generated compact LLM context pack |
| `llms-ctx-full.txt` | Generated expanded LLM context pack |
| `.github/agents/` | Six model-pinned agents |
| `.github/skills/` | Thirteen repo skills, including review skills |
| `template/skills/` | Thirteen template skill stubs scaffolded into consumer projects |
| `.github/prompts/` | Reusable slash-command prompt files |
| `.github/instructions/` | Path-specific instruction files |
| `.github/hooks/` | Hook configuration and scripts |
| `.github/workflows/` | CI and release workflows |
| `docs/` | Human-readable guides |
| `scripts/` | Sync and maintenance scripts |
| `tests/` | Drift guards and shell test suites |
| `.copilot/workspace/` | Workspace identity files and canonical metadata index |
| `.copilot/workspace/TOOLS.md` | Tool usage patterns |
| `.copilot/workspace/MEMORY.md` | Memory strategy |
| `.copilot/workspace/BOOTSTRAP.md` | Permanent setup origin record |
| `.copilot/workspace/HEARTBEAT.md` | Event-driven health check checklist |
| **Docs** | |
| `docs/AGENTS-GUIDE.md` | Human-readable guide to model-pinned agents, trigger phrases, and fallback chains |
| `docs/SETUP-GUIDE.md` | Human-readable walkthrough of the setup interview and output files |
| `docs/UPDATE-GUIDE.md` | Human-readable guide to the update and restore protocol |
| `docs/HOOKS-GUIDE.md` | Human-readable guide to agent lifecycle hooks: config, customisation, security |
| `docs/SKILLS-GUIDE.md` | Human-readable guide to the Agent Skills system |
| `docs/MCP-GUIDE.md` | Human-readable guide to MCP server configuration and server tiers |
| `docs/HEARTBEAT-GUIDE.md` | Human-readable guide to the heartbeat protocol and checklist |
| `docs/EXTENSION-REVIEW-GUIDE.md` | Human-readable guide to the extension review workflow |
| `docs/TEST-REVIEW-GUIDE.md` | Human-readable guide to the test coverage review workflow |
| `docs/PATH-INSTRUCTIONS-GUIDE.md` | Human-readable guide to path-specific instruction files |
| `docs/PROMPTS-GUIDE.md` | Human-readable guide to reusable prompt files and slash commands |
| `docs/INSTRUCTIONS-GUIDE.md` | Human-readable guide to the copilot-instructions.md structure |
| `docs/SECURITY-GUIDE.md` | Human-readable guide to CI hardening, SHA-pinning, and Graduated Trust Model |
| `docs/RELEASE-AUTOMATION-GUIDE.md` | Human-readable guide to release-please and version management |
| **Examples** | |
| `examples/valis/README.md` | Reference implementation |
| **Consumer-only files (created during setup, not in template repo)** | |
| `.github/copilot-version.md` | Installed template version number (semver) + per-section fingerprints — created in consumer project |
| `.copilot/tools/INDEX.md` | Toolbox catalogue — created in consumer project on first tool save |

---

## Canonical triggers

| Action | Trigger phrase |
|--------|----------------|
| First-time setup | *"Setup from asafelobotomy/copilot-instructions-template"* |
| Check for updates (from [template repo](https://github.com/asafelobotomy/copilot-instructions-template)) | *"Update your instructions"* |
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
| Check heartbeat | *"Check your heartbeat"* / *"Run heartbeat checks"* |
| Show heartbeat status | *"Show heartbeat status"* / *"Heartbeat history"* |
| Update heartbeat | *"Update heartbeat checklist"* / *"Clear heartbeat alerts"* |
| Run retrospective | *"Run retrospective"* |
| Run health check (Doctor) | *"Run health check"* / *"Doctor check"* / *"Check instruction files"* |
| Configure hooks | *"Configure hooks"* / *"Set up agent hooks"* |
| List hooks | *"Show hooks"* / *"List agent hooks"* |
| Add a hook | *"Add a hook"* / *"Create a hook for ..."* |
| Disable hooks | *"Disable hooks"* / *"Remove hook ..."* |
| List plugins | *"Show plugins"* / *"List agent plugins"* |
| Find a plugin | *"Find a plugin for ..."* / *"Search for a plugin that ..."* |
| Test as plugin | *"Test as plugin"* / *"Preview template as plugin"* |
| Check plugin conflicts | *"Check plugin conflicts"* |
