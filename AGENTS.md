# Agent Entry Point — copilot-instructions-template

This file is read by AI agents (GitHub Copilot and compatible agents) to understand how to interact with this repository.

---

## Trigger phrases

### Setup and update

The Setup agent handles first-time setup, updates, backup restore, and factory restore as a unified interactive wizard.

Use the canonical trigger phrases below. The Setup agent runs inside VS Code and uses interactive `askQuestions` calls to guide users through personalization. It does not fetch external files — the plugin delivers all necessary template assets at installation time.

## Delegation policy

Keep subagent delegation narrow.

- The main/default agent follows the same specialist-first rule: when a request
  matches a named specialist workflow, delegate instead of handling the
  specialist workflow inline.
- Do not use task size, perceived simplicity, or personal preference as a
  reason to keep specialist work inline.
- Trust the selected specialist to complete the task unless you know it is
  outside the specialist scope, allow-list, or capabilities, or the specialist
  reports a concrete blocker.
- Treat each `.github/agents/*.agent.md` `agents:` list as a hard boundary.
- Add a delegate only when the agent body defines a concrete handoff for it.
- Prefer the lightest valid handoff: `Explore` for read-only repo scans, `Researcher` for current external docs, `Audit` for residual-risk checks, `Docs` for documentation work, `Cleaner` for repo-hygiene cleanup, and `Organise` for structural moves or path fixes.

## Start specialist requests with scope

- Include a one-sentence objective.
- State the scope, including what is in and out.
- State acceptance criteria or a definition of done.
- If the request is vague, ask one clarifying question before starting specialist work.

Trigger phrases should be completable from a single short request. If a trigger
phrase routinely needs clarifying back-and-forth before work can start, the
trigger design is wrong.

---

## Canonical protocol sources

- **Plugin installation**: The template is installed as a VS Code Agent Plugin via `Chat: Install Plugin` or by searching "copilot-instructions-template" in Extensions → Plugin Marketplace.
- **Setup wizard**: The Setup agent (`agents/setup.agent.md`) runs the personalization flow after plugin installation.
- **Agent source location**: `${CLAUDE_PLUGIN_ROOT}/agents/` (Claude-format plugin) or the `agents` field in `plugin.json` (VS Code plugin format); downloaded at install time.
- **Consumer installation location**: `${workspaceFolder}/.github/agents/` (personalised agents copied by Setup wizard).
- **Canonical inventory**: `.copilot/workspace/operations/workspace-index.json` (developer workspace) or `template/workspace/operations/workspace-index.json` (template baseline).

## Consumer-Only Files

These files are created in the consumer project during the Setup wizard personalization, not in this template repo. Paths marked *(all-local only)* are skipped when the corresponding surface is plugin-managed.

| Path | Role |
|------|------|
| `.github/copilot-instructions.md` | Installed developer instructions (from `agents/setup.agent.md` template with project-specific values) |
| `.github/agents/` | Personalised model-pinned agents *(all-local only)* |
| `.github/skills/` | Personalised skills *(all-local only)* |
| `.github/hooks/` | Personalised hook scripts and config *(all-local only)* |
| `.github/copilot-version.md` | Installed template version number (semver) + per-section fingerprints + ownership mode |
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
| First-time setup | *"Setup from asafelobotomy/copilot-instructions-template"* or *"Install the copilot-instructions-template plugin"* or *"Set up this project"* |
| Update instructions | *"Update your instructions"* / *"Check for instruction updates"* / *"Update from copilot-instructions-template"* / *"Sync instructions with the template"* / *"Check the template for updates"* |
| Force update check | *"Force check instruction updates"* |
| Restore backup | *"Restore instructions from backup"* |
| Factory restore | *"Factory restore instructions"* / *"Reinstall instructions from scratch"* |
| Heartbeat | *"Check your heartbeat"* |
| Retrospective | *"Run retrospective"* |
| Show/build/save tools | *"Show me the toolbox"* / *"Build a tool for ..."* |
| Skills (create/list/search) | *"Create a skill"* / *"Show my skills"* / *"Find a skill for ..."* |
| Documentation | *"Write docs"* / *"Update the README"* / *"Draft migration notes"* |
| Cleanup | *"Clean up repo clutter"* / *"Remove stale files"* / *"Prune caches and archives"* |
| Test coverage review | *"Review my tests"* / *"Check test coverage"* |
| MCP (configure/add/list) | *"Configure MCP servers"* / *"Add an MCP server"* |
| Hooks (configure/list/add) | *"Configure hooks"* / *"Show hooks"* |
| Starter kits (install/list/remove) | *"Install a starter kit"* / *"Show starter kits"* / *"What starter kits are available?"* |
| Plugins (list/find/test) | *"Show plugins"* / *"Find a plugin for ..."* |
| Commit (stage/commit) | *"Commit my changes"* / *"Stage and commit"* / *"Write a commit message"* |
| Commit (push) | *"Push my changes"* / *"Push to origin"* |
| Commit (sync) | *"Pull and rebase"* / *"Fetch upstream"* / *"Sync my branch"* / *"Rebase on main"* / *"Merge main into my branch"* |
| Commit (branch) | *"Create a branch"* / *"Switch branch"* / *"List branches"* / *"Delete this branch"* |
| Commit (stash) | *"Stash my changes"* / *"Pop stash"* / *"Show stashes"* |
| Commit (conflicts) | *"Resolve merge conflicts"* / *"Fix conflicts"* / *"Continue rebase"* |
| Commit (PR) | *"Create a PR"* / *"Open a pull request"* / *"Update the PR"* |
| Commit (tag/release) | *"Tag this version"* / *"Create a release"* / *"Tag as v..."* |
| Commit style onboarding | *"Set up my commit style"* / *"Onboard commit preferences"* / *"Configure commit style"* |
| Quick question / tiny edit | *"Quick question"* / *"What does this regex match?"* / *"Fix the typo in ..."* / *"Single-file edit"* / *"What's the wc -l of ...?"* |
| Implement / refactor | *"Implement ..."* / *"Add ..."* / *"Refactor ..."* / *"Fix the bug in ..."* |
| Code review | *"Review my changes"* / *"Review this file"* / *"Architectural review of ..."* |
| Explore codebase | *"Explore ..."* / *"Find where ..."* / *"How does ... work?"* |
| Plan / break down | *"Plan ..."* / *"Break this down"* / *"What are the steps to ..."* |
| Debug / diagnose | *"Debug ..."* / *"Find the root cause of ..."* / *"Why is ... failing?"* |
