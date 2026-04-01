# Agent Entry Point — copilot-instructions-template

This file is read by AI agents (GitHub Copilot and compatible agents) to understand how to interact with this repository.

---

## Trigger phrases

### Setup and update

When a user says any of the following in a Copilot chat:

- *"Setup from asafelobotomy/copilot-instructions-template"*
- *"Bootstrap this project from copilot-instructions-template"*
- *"Use the Lean/Kaizen Copilot template to set up this project"*
- *"Initialise this project with asafelobotomy/copilot-instructions-template"*
- *"Run the copilot-instructions-template setup"*
- *"Update your instructions"*
- *"Check for instruction updates"*
- *"Update from copilot-instructions-template"*
- *"Sync instructions with the template"*
- *"Force check instruction updates"*
- *"Restore instructions from backup"*

...the Setup agent handles both first-time setup and updates. It auto-detects
which mode to use based on whether `.github/copilot-instructions.md` exists.

For first-time setup, perform the **Remote Bootstrap Sequence** below.
For updates, perform the **Remote Update Sequence** below.

Canonical source for inventory:

- `.copilot/workspace/workspace-index.json` — canonical machine-readable metadata index

---

## Remote Bootstrap Sequence

> All writes go to the **user's current project**. Never modify `asafelobotomy/copilot-instructions-template`.

1. Fetch `SETUP.md`: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/SETUP.md`
2. Fetch the instructions template: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/copilot-instructions.md`
3. Follow `SETUP.md` exactly. It fetches all companion files (agents, skills, hooks, prompts, instructions) from upstream. If any fetch fails, stop. The template from step 2 gets populated with `{{PLACEHOLDER}}` values and written to `.github/copilot-instructions.md`. See `SETUP.md` for the full output file list.

---

## Remote Update Sequence

1. Fetch `UPDATE.md`: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/UPDATE.md`
2. Follow every step in `UPDATE.md` exactly (version-walk, three-way merge, pre-flight report, backup, write).

---

## Remote Restore Sequence

1. Fetch `UPDATE.md`: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/UPDATE.md`
2. Follow the **"Restore from backup"** section in `UPDATE.md`.

## Consumer-Only Files

These files are created in the consumer project during setup, not in this template repo:

| Path | Role |
|------|------|
| `.github/copilot-version.md` | Installed template version number (semver) + per-section fingerprints |
| `.copilot/tools/INDEX.md` | Toolbox catalogue (created on first tool save) |
| `.github/starter-kits/<kit>/` | Stack-specific starter-kit plugin (installed during setup if stack matches) |

---

## Canonical triggers

| Action | Trigger phrase |
|--------|----------------|
| First-time setup | *"Setup from asafelobotomy/copilot-instructions-template"* |
| Update instructions | *"Update your instructions"* / *"Check for instruction updates"* / *"Update from copilot-instructions-template"* / *"Sync instructions with the template"* / *"Check the template for updates"* |
| Force update check | *"Force check instruction updates"* |
| Restore backup | *"Restore instructions from backup"* |
| Health check | *"Run health check"* / *"Doctor check"* / *"Full audit"* |
| Heartbeat | *"Check your heartbeat"* |
| Retrospective | *"Run retrospective"* |
| Show/build/save tools | *"Show me the toolbox"* / *"Build a tool for ..."* |
| Skills (create/list/search) | *"Create a skill"* / *"Show my skills"* / *"Find a skill for ..."* |
| Extensions (review/install/profile) | *"Review extensions"* / *"Check my extensions"* / *"Check my profile"* / *"Sync extensions"* / *"Install recommended extensions"* |
| Test coverage review | *"Review my tests"* / *"Check test coverage"* |
| MCP (configure/add/list) | *"Configure MCP servers"* / *"Add an MCP server"* |
| Hooks (configure/list/add) | *"Configure hooks"* / *"Show hooks"* |
| Starter kits (install/list/remove) | *"Install a starter kit"* / *"Show starter kits"* / *"What starter kits are available?"* |
| Plugins (list/find/test) | *"Show plugins"* / *"Find a plugin for ..."* |
| Research (find/report/track) | *"Research [topic]"* / *"Find documentation for [topic]"* / *"Build a research report on [topic]"* / *"Update the URL tracker"* |
| Security audit | *"Security audit"* / *"Scan for secrets"* / *"Check for vulnerabilities"* / *"Review security posture"* / *"Run security check"* / *"Full audit"* |
| Commit (stage/commit) | *"Commit my changes"* / *"Stage and commit"* / *"Write a commit message"* |
| Commit (push) | *"Push my changes"* / *"Push to origin"* |
| Commit (tag/release) | *"Tag this version"* / *"Create a release"* / *"Tag as v..."* |
| Commit style onboarding | *"Set up my commit style"* / *"Onboard commit preferences"* / *"Configure commit style"* |
