# Agent Entry Point — copilot-instructions-template

This file is read by AI agents (GitHub Copilot and compatible agents) to understand how to interact with this repository.

---

## Trigger phrases

### Setup and update

Use the setup and update entries from the canonical trigger table below.

...the Setup agent handles both first-time setup and updates. It auto-detects
which mode to use based on whether `.github/copilot-instructions.md` exists.

For first-time setup, follow [SETUP.md](SETUP.md) exactly.
For updates, backup restore, or factory restore, follow [UPDATE.md](UPDATE.md) exactly.
Use [template/setup/manifests.md](template/setup/manifests.md#protocol-sources)
as the canonical supporting-source inventory instead of restating fetch lists
here.

Canonical source for inventory:

- `.copilot/workspace/workspace-index.json` — canonical machine-readable metadata index

## Delegation policy

Keep subagent delegation narrow.

- The main/default agent follows the same specialist-first rule: when a request
  clearly belongs to a specialist agent, delegate instead of handling the
  specialist workflow inline.
- Treat each `.github/agents/*.agent.md` `agents:` list as a hard boundary.
- Add a delegate only when the agent body defines a concrete handoff for it.
- Prefer the lightest valid handoff: `Explore` for read-only repo scans, `Researcher` for current external docs, `Audit` for residual-risk checks, and `Organise` for structural moves or path fixes.

---

## Canonical protocol sources

- First-time setup behaviour: [SETUP.md](SETUP.md)
- Update, backup restore, and factory restore behaviour: [UPDATE.md](UPDATE.md)
- Supporting upstream source inventory: [template/setup/manifests.md](template/setup/manifests.md#protocol-sources)
- Canonical inventory and counts: `.copilot/workspace/workspace-index.json`

## Consumer-Only Files

These files are created in the consumer project during setup, not in this template repo:

| Path | Role |
|------|------|
| `.github/copilot-version.md` | Installed template version number (semver) + per-section fingerprints |
| `.copilot/tools/INDEX.md` | Toolbox catalogue (created on first tool save) |
| `.github/starter-kits/<kit>/` | Stack-specific starter-kit plugin (installed during setup if stack matches) |

---

## Canonical triggers

The rows below are the direct consumer-facing trigger phrases. Specialist
delegation-first agents such as Audit, Researcher, Extensions, and Organise may
be installed for internal handoffs while remaining hidden from direct
invocation.

| Action | Trigger phrase |
|--------|----------------|
| First-time setup | *"Setup from asafelobotomy/copilot-instructions-template"* |
| Update instructions | *"Update your instructions"* / *"Check for instruction updates"* / *"Update from copilot-instructions-template"* / *"Sync instructions with the template"* / *"Check the template for updates"* |
| Force update check | *"Force check instruction updates"* |
| Restore backup | *"Restore instructions from backup"* |
| Factory restore | *"Factory restore instructions"* / *"Reinstall instructions from scratch"* |
| Heartbeat | *"Check your heartbeat"* |
| Retrospective | *"Run retrospective"* |
| Show/build/save tools | *"Show me the toolbox"* / *"Build a tool for ..."* |
| Skills (create/list/search) | *"Create a skill"* / *"Show my skills"* / *"Find a skill for ..."* |
| Test coverage review | *"Review my tests"* / *"Check test coverage"* |
| MCP (configure/add/list) | *"Configure MCP servers"* / *"Add an MCP server"* |
| Hooks (configure/list/add) | *"Configure hooks"* / *"Show hooks"* |
| Starter kits (install/list/remove) | *"Install a starter kit"* / *"Show starter kits"* / *"What starter kits are available?"* |
| Plugins (list/find/test) | *"Show plugins"* / *"Find a plugin for ..."* |
| Commit (stage/commit) | *"Commit my changes"* / *"Stage and commit"* / *"Write a commit message"* |
| Commit (push) | *"Push my changes"* / *"Push to origin"* |
| Commit (tag/release) | *"Tag this version"* / *"Create a release"* / *"Tag as v..."* |
| Commit style onboarding | *"Set up my commit style"* / *"Onboard commit preferences"* / *"Configure commit style"* |
