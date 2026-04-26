<div align="center">
  <img src="assets/logo.png" alt="Lean/Kaizen Copilot Instructions Template" width="200"/>

<h1>Lean/Kaizen Copilot Instructions Template</h1>

  **A versioned VS Code agent plugin that keeps AI developer behaviour consistent across all your projects.**

  [![Version](https://img.shields.io/badge/version-0.6.2-blue)](CHANGELOG.md) <!-- x-release-please-version -->
  [![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
  [![Agents](https://img.shields.io/badge/agents-14-purple)](agents/)
  [![Skills](https://img.shields.io/badge/skills-18-teal)](skills/)
</div>

---

## What this is

A single VS Code agent plugin that installs a full AI developer workflow into any project via a guided personalisation wizard. One installation gives every project:

| Component | Count | Description |
|-----------|------:|-------------|
| Model-pinned agents | 14 | Specialist agents for every workflow stage |
| Reusable skills | 18 | Domain-specific capability modules |
| Lifecycle hooks | 6 | PreToolUse, PostToolUse, and Stop guards |
| Starter kits | 8 | Stack-specific bundles (Python, TypeScript, Go, Rust, Java, C++, React, Docker) |
| MCP configuration | — | Pre-configured server set with sandbox policy |
| Setup wizard | — | Interactive personalisation at install time |

The template follows Lean/Kaizen principles — waste-tagged reviews, PDCA cycles, and progressive narrowing of test scope by default.

---

### Cold-start bootstrap

If the Setup agent is not available yet in a fresh workspace, install the template plugin first, reload VS Code, and then run the setup trigger above.

Use one of these bootstrap paths:

- Extensions view → agent plugins → Install from Source with the full repository URL.
- Local development/testing only: add the plugin root to `chat.pluginLocations`, reload VS Code, then run setup.

For local plugin paths, prefer repo-relative entries for workspace-installed starter kits and avoid committing machine-specific absolute home-directory paths.

This repo now ships plugin manifests for all three currently relevant surfaces: the root Copilot-format manifest at [`plugin.json`](plugin.json), OpenPlugin under [`.plugin/plugin.json`](.plugin/plugin.json), and Claude format under [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json). The OpenPlugin and Claude manifests are the token-bearing formats that can safely resolve plugin-owned executables. VS Code still does not document an equivalent plugin-root token for Copilot-format plugin-owned hook and MCP executable paths, so the root manifest keeps explicit component wiring instead.

## Install

1. Open VS Code → open the Chat panel → click **Chat: Install Plugin**
2. Search **copilot-instructions-template** and install
3. Tell Copilot:

   > *"Set up this project"*

The Setup agent runs an interactive personalisation wizard. It asks a few questions, then writes your `.github/copilot-instructions.md`, copies agents and skills into `.github/`, installs hooks and MCP config, and creates a workspace scaffold. No manual file copying or URL fetching required.

---

## Agents

| Agent | Role |
|-------|------|
| **Setup** | Interactive personalisation wizard — first-time setup, updates, backup restore, and factory restore |
| **Code** | Implement features, refactor, and run multi-step coding tasks |
| **Review** | Deep code review and architectural analysis with Lean/Kaizen critique |
| **Audit** | Read-only health check — structural validation, OWASP Top 10, secret detection |
| **Commit** | Full git lifecycle — stage, commit, push, branch, stash, tag, PR creation |
| **Debugger** | Diagnose failures, isolate root causes, and triage regressions |
| **Docs** | Draft and update documentation, migration notes, and README sections |
| **Planner** | Break complex work into scoped execution plans with risks and verification steps |
| **Explore** | Fast read-only codebase exploration and Q&A |
| **Researcher** | Fetch current external documentation and produce structured research output |
| **Cleaner** | Prune stale artefacts, caches, archives, and dead files |
| **Organise** | Move files, fix broken paths, and reshape repository layouts |
| **Extensions** | Manage VS Code extensions, profiles, and workspace configuration |
| **Fast** | Quick questions, syntax lookups, and lightweight single-file edits |

---

## Skills

| Skill | Purpose |
|-------|---------|
| `agentic-workflows` | Set up GitHub Actions workflows with Copilot coding agents |
| `commit-preflight` | Inspect CI workflows before commit and run matching local checks |
| `compress-prose` | Tighten prose without losing required meaning |
| `conventional-commit` | Write Conventional Commits spec messages with scope and body |
| `create-adr` | Create Architectural Decision Records |
| `extension-review` | Audit VS Code extensions against the current project stack |
| `fix-ci-failure` | Diagnose and fix failing CI pipelines |
| `issue-triage` | Classify severity, label waste, and draft structured responses |
| `lean-pr-review` | Review pull requests with Lean waste categories and severity ratings |
| `mcp-builder` | Scaffold and register new MCP servers |
| `mcp-management` | Configure and manage MCP servers |
| `plugin-management` | Discover, install, and manage agent plugins |
| `security-audit` | OWASP Top 10, secret detection, injection patterns, supply chain checks |
| `skill-creator` | Create new agent skills following the open standard |
| `skill-management` | Discover, activate, and manage agent skills |
| `test-coverage-review` | Audit coverage gaps and recommend local tests plus CI workflows |
| `tool-protocol` | Find, build, or adapt automation tools |
| `webapp-testing` | Set up browser testing with VS Code tools or Playwright |

---

## Starter kits

Stack-specific instruction bundles installed during setup when the stack is detected:

`cpp` · `docker` · `go` · `java` · `python` · `react` · `rust` · `typescript`

---

## Daily commands

| What you want | Tell Copilot |
|---------------|-------------|
| Update to latest plugin version | *"Update your instructions"* |
| Restore a broken installation | *"Factory restore instructions"* |
| Check heartbeat / session state | *"Check your heartbeat"* |
| Run a retrospective | *"Run retrospective"* |
| Commit staged changes | *"Commit my changes"* |
| Create a pull request | *"Create a PR"* |
| Configure MCP servers | *"Configure MCP servers"* |
| Install a starter kit | *"Install a starter kit"* |

See [AGENTS.md](AGENTS.md) for the full trigger phrase list.

---

## For contributors

### Version

Current template version: **0.6.2** <!-- x-release-please-version --> — see [CHANGELOG.md](CHANGELOG.md).

Version bumps are done locally. Bump `VERSION.md` and all `<!-- x-release-please-version -->` markers together, then verify:

```bash
bash scripts/release/verify-version-references.sh
```

When the push lands on `main` and the version in `VERSION.md` does not yet have a corresponding git tag, CI creates a GitHub release automatically.

**SemVer policy**: Major for breaking consumer-facing changes · Minor (`feat:`) for consumer-facing additions · Patch for fixes, maintenance, and refactors.

Minor: `feat:` for a consumer-facing addition. Use `feat` only for a real consumer-facing capability.

### Validation

During iterative work, prefer `bash scripts/harness/select-targeted-tests.sh <paths...>` over running the full suite. Reserve `bash tests/run-all.sh` as the single end-of-task full-suite gate. If a targeted failure forces broader re-verification, run the full suite and fix before continuing.

```bash
# Full suite (use as final gate only)
bash tests/run-all.sh

# Targeted — prefer during iterative work
bash scripts/harness/select-targeted-tests.sh <paths...>

# Captured full suite (output saved to logs/)
bash scripts/harness/run-all-captured.sh

# Drift checks
bash scripts/workspace/sync-workspace-index.sh --check
bash scripts/sync/sync-models.sh --check
```

## Recommended GitHub settings

- Block branch deletion and non-fast-forward pushes on `main`
- Enable squash merge.

Audit live settings with an authenticated GitHub CLI session:

```bash
bash scripts/release/audit-release-settings.sh
```

### Terminal-safe shell protocol

When an agent needs the terminal, follow this order:

1. Run an existing repo script directly if one covers the task.
2. Use direct execution for a single command with no shell control flow, tempfile plumbing, or retries.
3. For ad hoc multi-step snippets, use an isolated child shell wrapper:

```bash
bash scripts/harness/run-isolated-shell.sh --shell bash --strict --command 'your-command-here'
```

For multi-line snippets:

```bash
bash scripts/harness/run-isolated-shell-stdin.sh --shell bash --strict <<'EOF'
your
multi-line
snippet
EOF
```

For terminal-session tools, use the right selector: `id` is the opaque UUID returned by `run_in_terminal` async mode, while `terminalId` is the numeric instanceId for a terminal already visible in the terminal panel.

`get_terminal_output` and `send_to_terminal` can use either selector in the correct parameter; `kill_terminal` only accepts the async `id` UUID.

For the async terminal tool family, use the exact terminal ID returned by `run_in_terminal` async mode with `get_terminal_output`, `send_to_terminal`, and `kill_terminal`. Treat those tools as valid only when `run_in_terminal` returned a live terminal ID, usually from async mode or from a sync command that outlived its timeout.

- Use `terminal_last_command` and `terminal_selection` only for the currently active editor terminal.
- When a command is non-blocking, prefer `execution_subagent` or a synchronous terminal run over creating a background terminal just to poll it.
- call `kill_terminal` when the session is no longer needed.
- Background terminal notifications are enabled by default, so do not add `sleep` loops or blind polling around background terminals.
- For persistent task workflows, prefer repo scripts or `create_and_run_task` instead of a persistent interactive shell.
- For interactive terminal prompts, send one answer at a time with `send_to_terminal` and check the next prompt before sending more input.

*** Add File: /mnt/SteamLibrary/git/copilot-instructions-template/.github/skills/plugin-management/SKILL.md
---
name: plugin-management
description: Discover, evaluate, install, test, and manage agent plugins for VS Code Copilot
compatibility: ">=3.2"
---

# Plugin Management

> Skill metadata: version "1.1"; license MIT; tags [plugins, agents, extensions, discovery, management]; compatibility ">=3.2"; recommended tools [codebase, runCommands, editFiles].

Agent plugins (VS Code 1.110+, Preview) are installable packages that bundle agents, skills, hooks, MCP servers, and slash commands. This skill covers discovering, evaluating, installing, testing, and managing plugins alongside the template's own customization files.

## When to use

- The user asks to find, list, install, or manage agent plugins
- A task would benefit from a plugin-provided agent or skill
- You need to check for conflicts between plugin-contributed and workspace-level agents or skills
- The user wants to test the template as a local plugin

## What plugins provide

A single plugin can bundle any combination of:

| Type | Description |
|------|-------------|
| Slash commands | Additional `/` commands in chat |
| Skills | Agent skills with instructions, scripts, and resources |
| Agents | Custom agents with specialized personas and tool configurations |
| Hooks | Shell commands at agent lifecycle points (hook config in `hooks/hooks.json` or `hooks.json`) |
| MCP servers | External tool integrations (config in `.mcp.json` at plugin root, uses `mcpServers` key) |

## Discovery

```text
User wants a plugin
 │
 ├─ 1. CHECK INSTALLED — list installed plugins
 │     Run in Extensions view: filter @agentPlugins
 │     Or check VS Code settings for chat.pluginLocations (local plugins)
 │     ├─ Found  → verify it meets the need → DONE
 │     └─ Not found → ↓
 │
 ├─ 2. SEARCH — find plugins in configured marketplaces
 │     Extensions view → search @agentPlugins <keyword>
 │     Or browse chat.plugins.marketplaces URLs
 │     Default marketplaces: github/copilot-plugins, github/awesome-copilot
 │     Additional: anthropics/claude-code
 │     ├─ Found → evaluate (see Quality Gate below) → install
 │     └─ Not found → ↓
 │
 ├─ 3. INSTALL FROM SOURCE — install directly from a Git URL
 │     Command: Chat: Install Plugin From Source
 │     Or: select + button on Plugins page of Chat Customizations editor
 │
 └─ 4. RECOMMEND ALTERNATIVE — no suitable plugin exists
       Consider: workspace skill (.github/skills/), MCP server, or custom tool
```

## Quality gate

Before recommending or installing a plugin, verify:

- [ ] **Publisher trust** — known publisher or verified organization
- [ ] **Maintenance** — updated within 12 months; no abandoned or archived repo
- [ ] **No credential exposure** — plugin does not require secrets beyond standard VS Code secret storage
- [ ] **Conflict check** — no naming collisions with existing workspace agents, skills, or hooks
- [ ] **Scope review** — plugin only requests the minimum capability it needs (check the contributed agent and skill metadata for unnecessary tool access)
- [ ] **Hook review** — if the plugin includes hooks, inspect hook scripts before enabling (hooks execute with VS Code's permissions)
- [ ] **MCP review** — if the plugin bundles MCP servers, verify server sources and tool capabilities

Plugins failing two or more checks are rejected.

## Conflict resolution

When a plugin contributes an agent or skill with the same name as a workspace file:

| Conflict type | Resolution |
|--------------|------------|
| Agent name collision | Workspace agent takes priority. VS Code shows source in tooltip. |
| Skill name collision | Project skills (`.github/skills/`) override plugin skills. |
| Hook collision | Workspace hooks fire alongside plugin hooks — check for duplicate behaviour. Most restrictive `PreToolUse` decision wins. |
| MCP server collision | Plugin MCP servers run alongside workspace servers. Disable via plugin toggle. |

Use the **Agent Debug Panel** (`Developer: Open Agent Debug Panel`) to see exactly which agents, skills, and hooks are loaded and from which source.

## Plugin hooks

Plugins can include hooks that fire at lifecycle events (`SessionStart`, `PreToolUse`, `PostToolUse`, `PreCompact`, `SubagentStart`, `SubagentStop`, `Stop`).

- Hook config location depends on format: `hooks/hooks.json` (Claude format) or `hooks.json` (Copilot/OpenPlugin format)
- Use the plugin-root token that matches the plugin format: `${CLAUDE_PLUGIN_ROOT}` for Claude-format plugins and `${PLUGIN_ROOT}` for OpenPlugin plugins
- Copilot-format plugins do not currently document a plugin-root token in VS Code. Do not assume `${CLAUDE_PLUGIN_ROOT}` exists there.
- Plugin hooks are implicitly trusted on install — review before enabling
- Disabling a plugin also disables its hooks

## Plugin MCP servers

Plugins can bundle MCP servers that start automatically when the plugin is enabled.

- Config in `.mcp.json` at plugin root using `mcpServers` key (not `servers`)
- Use the plugin-root token that matches the plugin format: `${CLAUDE_PLUGIN_ROOT}` for Claude-format plugins and `${PLUGIN_ROOT}` for OpenPlugin plugins
- Copilot-format plugins do not currently document a plugin-root token in VS Code. Prefer Claude or OpenPlugin format when plugin-owned executables need stable absolute paths.
- Plugin MCP servers are implicitly trusted (no separate trust prompt)
- Disabling a plugin stops its MCP servers

## Settings reference

| Setting | Purpose |
|---------|---------|
| `chat.plugins.enabled` | Enable/disable plugin discovery (boolean) |
| `chat.plugins.marketplaces` | Git repositories serving as plugin marketplaces (array of owner/repo) |
| `chat.pluginLocations` | Local paths for plugin development/testing (map of path → boolean) |

## Workspace plugin recommendations

Projects can recommend plugins for team members:

```json
{
  "extraKnownMarketplaces": {
    "company-tools": {
      "source": { "source": "github", "repo": "your-org/plugin-marketplace" }
    }
  },
  "enabledPlugins": {
    "code-formatter@company-tools": true
  }
}
```

## Testing the template as a plugin

To preview how the template's agents, skills, hooks, and prompts appear as plugin-contributed customizations:

1. Clone the template repo (or use an existing local copy)
2. Add to VS Code settings:

   ```json
   "chat.pluginLocations": {
       "/path/to/copilot-instructions-template": true
   }
   ```

3. Reload VS Code — plugin-contributed agents appear in the Copilot dropdown
4. Verify: open the Agent Debug Panel to confirm agents, skills, and hooks are loaded
5. Check for conflicts with any workspace-level agents in `.github/agents/`

## Managing installed plugins

1. **List** — Extensions view → filter `@agentPlugins` to see all installed plugins
2. **Inspect** — select a plugin to see its contributed agents, skills, MCP servers, and commands
3. **Disable** — right-click → Disable (globally or per-workspace; also disables hooks and MCP servers)
4. **Remove** — right-click → Uninstall to fully remove
5. **Update** — `Extensions: Check for Extension Updates` or automatic every 24 hours

## Verify

- [ ] Requested plugin was found or a suitable alternative was identified
- [ ] Quality gate was applied before installation (including hook and MCP review)
- [ ] No unresolved naming conflicts between plugin and workspace agents/skills
- [ ] Agent Debug Panel confirms correct loading order and source attribution

