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
| `.github/skills/*/SKILL.md` | Reusable skill library (11 starter skills from template) |
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

---

## File map

| File | Role |
|------|------|
| **Project root** | |
| `AGENTS.md` | This file — AI agent entry point |
| `SETUP.md` | Complete setup guide (remote-executable) |
| `UPDATE.md` | Complete update + restore protocol (remote-executable) |
| `MIGRATION.md` | Per-version migration registry — sections changed, companion files, breaking changes, manual actions |
| `VERSION.md` | Single source of truth for template version number (semver) |
| `CHANGELOG.md` | Template version history |
| `README.md` | Project landing page and quick-start guide |
| `CONTRIBUTING.md` | Contributor guide — workflow, conventions, PR checklist |
| `LICENSE` | MIT license |
| `llms.txt` | LLM-friendly project summary (llmstxt standard) |
| `BIBLIOGRAPHY.md` | File catalogue |
| `JOURNAL.md` | ADR-style development journal |
| `METRICS.md` | Kaizen baseline snapshot table |
| `release-please-config.json` | Release-please configuration |
| `.release-please-manifest.json` | Release-please version manifest |
| `.gitignore` | Git ignore rules |
| `.markdownlint.json` | Markdownlint configuration |
| `.markdownlint-cli2.yaml` | Markdownlint CLI v2 configuration |
| `.vale.ini` | Vale prose linting configuration |
| **Scripts** | |
| `scripts/sync-version.sh` | Propagate version from `VERSION.md` to all `x-release-please-version` marker files |
| **Tests** | |
| `tests/test-hooks.sh` | Hook script functionality tests |
| `tests/test-guard-destructive.sh` | Guard-destructive hook security tests |
| `tests/test-security-edge-cases.sh` | Security edge case tests (JSON injection, path traversal, etc.) |
| `tests/test-sync-version.sh` | Version sync script tests |
| **GitHub configuration** | |
| `.github/copilot-instructions.md` | Generic instructions template with `{{PLACEHOLDER}}` tokens |
| `.github/dependabot.yml` | Dependabot dependency update configuration |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Bug report issue template |
| `.github/ISSUE_TEMPLATE/feature_request.yml` | Feature request issue template |
| `.github/PULL_REQUEST_TEMPLATE.md` | Pull request template |
| **CI/CD workflows** | |
| `.github/workflows/ci.yml` | Main CI pipeline — structure, shellcheck, markdownlint, actionlint, hook tests, version sync |
| `.github/workflows/links.yml` | Link checker (lychee) |
| `.github/workflows/release-manual.yml` | Manual release workflow |
| `.github/workflows/release-please.yml` | Automated release via release-please |
| `.github/workflows/scorecard.yml` | OpenSSF Scorecard security analysis |
| `.github/workflows/stale.yml` | Stale issue/PR management |
| `.github/workflows/vale.yml` | Prose linting CI |
| **Agent files** | |
| `.github/agents/setup.agent.md` | Model-pinned Setup agent stub (Claude Sonnet 4.6) |
| `.github/agents/coding.agent.md` | Model-pinned Coding agent stub (GPT-5.3-Codex) |
| `.github/agents/review.agent.md` | Model-pinned Review agent stub (GPT-5.4) |
| `.github/agents/fast.agent.md` | Model-pinned Fast agent stub (Claude Haiku 4.5) |
| `.github/agents/update.agent.md` | Model-pinned Update agent stub (Claude Sonnet 4.6) |
| `.github/agents/doctor.agent.md` | Model-pinned Doctor agent stub (Claude Sonnet 4.6) |
| **Path-specific instructions** | |
| `.github/instructions/tests.instructions.md` | Path-specific instructions for test files (`*.test.*`, `*.spec.*`, `tests/**`) |
| `.github/instructions/api-routes.instructions.md` | Path-specific instructions for API/route/controller files |
| `.github/instructions/config.instructions.md` | Path-specific instructions for config and rc files |
| `.github/instructions/docs.instructions.md` | Path-specific instructions for Markdown and docs files |
| **Prompt files** | |
| `.github/prompts/explain.prompt.md` | Slash command `/explain` — waste-aware code explanation |
| `.github/prompts/refactor.prompt.md` | Slash command `/refactor` — PDCA-driven refactoring workflow |
| `.github/prompts/test-gen.prompt.md` | Slash command `/test-gen` — convention-following test generation |
| `.github/prompts/review-file.prompt.md` | Slash command `/review-file` — structured Lean file review |
| `.github/prompts/commit-msg.prompt.md` | Slash command `/commit-msg` — Conventional Commits message authoring |
| **Agent hooks (repo's own)** | |
| `.github/hooks/copilot-hooks.json` | Agent lifecycle hooks configuration |
| `.github/hooks/scripts/session-start.sh` | SessionStart hook — project context injection |
| `.github/hooks/scripts/guard-destructive.sh` | PreToolUse hook — destructive command guard |
| `.github/hooks/scripts/post-edit-lint.sh` | PostToolUse hook — auto-format after edits |
| `.github/hooks/scripts/enforce-retrospective.sh` | Stop hook — retrospective enforcement |
| `.github/hooks/scripts/save-context.sh` | PreCompact hook — context preservation |
| `.github/hooks/scripts/session-start.ps1` | SessionStart hook — Windows PowerShell counterpart |
| `.github/hooks/scripts/guard-destructive.ps1` | PreToolUse hook — Windows PowerShell counterpart |
| `.github/hooks/scripts/post-edit-lint.ps1` | PostToolUse hook — Windows PowerShell counterpart |
| `.github/hooks/scripts/enforce-retrospective.ps1` | Stop hook — Windows PowerShell counterpart |
| `.github/hooks/scripts/save-context.ps1` | PreCompact hook — Windows PowerShell counterpart |
| **Scaffolded skills (repo's own)** | |
| `.github/skills/skill-creator/SKILL.md` | Meta-skill for authoring new skills |
| `.github/skills/fix-ci-failure/SKILL.md` | CI failure diagnosis and resolution |
| `.github/skills/lean-pr-review/SKILL.md` | Lean PR review with waste categories |
| `.github/skills/conventional-commit/SKILL.md` | Conventional Commits message authoring |
| `.github/skills/mcp-builder/SKILL.md` | MCP server creation and registration |
| `.github/skills/webapp-testing/SKILL.md` | Browser-tools + Playwright web app testing |
| `.github/skills/issue-triage/SKILL.md` | Issue triage with severity classification |
| `.github/skills/tool-protocol/SKILL.md` | Tool Protocol decision tree and toolbox management |
| `.github/skills/skill-management/SKILL.md` | Skill discovery, activation, and management |
| `.github/skills/mcp-management/SKILL.md` | MCP server configuration and management |
| `.github/skills/plugin-management/SKILL.md` | Agent plugin discovery, evaluation, and management |
| **Vale styles** | |
| `.github/vale/styles/README.md` | Vale custom styles documentation |
| **Template files (copied to consumer project during setup)** | |
| `template/skills/skill-creator/SKILL.md` | Starter skill — meta-skill for authoring new skills |
| `template/skills/fix-ci-failure/SKILL.md` | Starter skill — CI failure diagnosis and resolution |
| `template/skills/lean-pr-review/SKILL.md` | Starter skill — Lean PR review with waste categories |
| `template/skills/conventional-commit/SKILL.md` | Starter skill — Conventional Commits message authoring |
| `template/skills/mcp-builder/SKILL.md` | Starter skill — MCP server creation and registration |
| `template/skills/webapp-testing/SKILL.md` | Starter skill — browser-tools + Playwright web app testing |
| `template/skills/issue-triage/SKILL.md` | Starter skill — issue triage with severity classification and structured response |
| `template/skills/tool-protocol/SKILL.md` | Starter skill — Tool Protocol decision tree and toolbox management |
| `template/skills/skill-management/SKILL.md` | Starter skill — Skill discovery, activation, and management |
| `template/skills/mcp-management/SKILL.md` | Starter skill — MCP server configuration and management |
| `template/skills/plugin-management/SKILL.md` | Starter skill — agent plugin discovery and management |
| `template/hooks/copilot-hooks.json` | Agent hooks configuration template |
| `template/hooks/scripts/session-start.sh` | SessionStart hook — project context injection |
| `template/hooks/scripts/guard-destructive.sh` | PreToolUse hook — destructive command guard |
| `template/hooks/scripts/post-edit-lint.sh` | PostToolUse hook — auto-format after edits |
| `template/hooks/scripts/enforce-retrospective.sh` | Stop hook — retrospective enforcement |
| `template/hooks/scripts/save-context.sh` | PreCompact hook — context preservation |
| `template/hooks/scripts/session-start.ps1` | SessionStart hook — Windows PowerShell counterpart |
| `template/hooks/scripts/guard-destructive.ps1` | PreToolUse hook — Windows PowerShell counterpart |
| `template/hooks/scripts/post-edit-lint.ps1` | PostToolUse hook — Windows PowerShell counterpart |
| `template/hooks/scripts/enforce-retrospective.ps1` | Stop hook — Windows PowerShell counterpart |
| `template/hooks/scripts/save-context.ps1` | PreCompact hook — Windows PowerShell counterpart |
| `template/vscode/mcp.json` | MCP server configuration template |
| `template/workspace/IDENTITY.md` | Agent self-description stub |
| `template/workspace/SOUL.md` | Agent values & reasoning patterns stub |
| `template/workspace/USER.md` | User profile stub |
| `template/workspace/TOOLS.md` | Tool usage patterns stub |
| `template/workspace/MEMORY.md` | Memory strategy stub |
| `template/workspace/BOOTSTRAP.md` | Bootstrap record stub |
| `template/workspace/HEARTBEAT.md` | Heartbeat checklist stub |
| `template/CHANGELOG.md` | Keep-a-Changelog stub (for consumer project) |
| `template/JOURNAL.md` | ADR journal stub |
| `template/BIBLIOGRAPHY.md` | File catalogue stub |
| `template/METRICS.md` | Metrics baseline table stub |
| `template/copilot-setup-steps.yml` | GitHub Copilot coding agent environment setup workflow stub |
| **VS Code workspace config** | |
| `.vscode/mcp.json` | MCP server configuration (this repo) |
| `.vscode/settings.json` | VS Code workspace settings |
| **Workspace identity (this repo's own)** | |
| `.copilot/workspace/IDENTITY.md` | Agent self-description |
| `.copilot/workspace/SOUL.md` | Agent values & reasoning patterns |
| `.copilot/workspace/USER.md` | Observed user profile |
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
