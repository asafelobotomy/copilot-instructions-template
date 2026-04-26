<div align="center">
  <img src="assets/logo.png" alt="Lean/Kaizen Copilot Instructions Template" width="200"/>

<h1>Lean/Kaizen Copilot Instructions Template</h1>

  **A versioned VS Code agent plugin that keeps AI developer behaviour consistent across all your projects.**

  [![Version](https://img.shields.io/badge/version-0.6.2-blue)](CHANGELOG.md) <!-- x-release-please-version -->
  [![License](https://img.shields.io/badge/license-MIT-green)](LICENSE.md)
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
| Lifecycle hooks | 8 | Session, prompt, tool, compaction, and subagent lifecycle events |
| Starter kits | 8 | Stack-specific bundles (Python, TypeScript, Go, Rust, Java, C++, React, Docker) |
| MCP configuration | — | Pre-configured server set with sandbox policy |
| Setup wizard | — | Interactive personalisation at install time |

The template follows Lean/Kaizen principles — waste-tagged reviews, PDCA cycles, and progressive narrowing of test scope by default.

---

### Setup routes

Use the plugin install path by default. Use the manual Copilot bootstrap path only when the marketplace entry is unavailable or you are testing locally.

- Plugin marketplace install: use **Chat: Install Plugin**, search `copilot-instructions-template`, install, reload VS Code if needed, then tell Copilot `Set up this project`.
- Manual Copilot bootstrap: use **Chat: Install Plugin From Source** and enter `https://github.com/asafelobotomy/copilot-instructions-template` (enter the full HTTPS URL, not the `owner/repo` shorthand), or add a local repo path to `chat.pluginLocations`, reload VS Code, then tell Copilot `Set up this project`.

If you need to confirm the plugin in VS Code, search the Extensions view for `@agentPlugins copilot-instructions-template` and make sure it is enabled.

See [SETUP.md](SETUP.md) for the full plugin and manual setup flow, exact trigger phrases, verification steps, and ownership-mode choices.

For local plugin paths, prefer repo-relative entries for workspace-installed starter kits and avoid committing machine-specific absolute home-directory paths.

This repo now ships plugin manifests for all three currently relevant surfaces: the root Copilot-format manifest at [`plugin.json`](plugin.json), OpenPlugin under [`.plugin/plugin.json`](.plugin/plugin.json), and Claude format under [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json). The OpenPlugin and Claude manifests are the token-bearing formats that can safely resolve plugin-owned executables. VS Code still does not document an equivalent plugin-root token for Copilot-format plugin-owned hook and MCP executable paths, so the root manifest keeps explicit component wiring instead.

## Install

1. Open VS Code → open the Chat panel → click **Chat: Install Plugin**
2. Search **copilot-instructions-template** and install
3. Tell Copilot:

   > *"Set up this project"*

The Setup agent runs an interactive personalisation wizard. It asks a few questions, then writes your `.github/copilot-instructions.md`, copies agents and skills into `.github/`, installs hooks and MCP config, and creates a workspace scaffold. No manual file copying or URL fetching required.

If the plugin marketplace entry is unavailable, follow the manual Copilot bootstrap path in [SETUP.md](SETUP.md).

If the Setup agent does not appear, search the Extensions view for `@agentPlugins copilot-instructions-template`, confirm the plugin is enabled, reload VS Code, and rerun `Set up this project`.

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

Featured default kits: `python` and `typescript`. The starter-kit registry carries `featured` and `tags` metadata so Setup can present the highest-confidence matches first when several kits fit the same workspace.

## Hooks

The plugin wires eight lifecycle events. In plugin-backed mode, these run from [hooks/hooks.json](hooks/hooks.json). In all-local mode, the same behavior can be installed into `.github/hooks/` during setup.

| Event | Primary script(s) | Purpose |
|-------|-------------------|---------|
| `SessionStart` | `session-start.sh`, `pulse.sh --trigger session_start` | Add project context and initialize heartbeat state |
| `UserPromptSubmit` | `pulse.sh --trigger user_prompt` | Detect explicit heartbeat and retrospective prompts |
| `PreToolUse` | `guard-destructive.sh`, `pulse.sh --trigger pre_tool` | Block dangerous commands and track pre-tool heartbeat signals |
| `PostToolUse` | `post-edit-lint.sh`, `pulse.sh --trigger soft_post_tool` | Auto-format edits and debounce soft heartbeat triggers |
| `Stop` | `pulse.sh --trigger stop`, `scan-secrets.sh` | Gate retrospectives and run the secret scan |
| `PreCompact` | `save-context.sh`, `pulse.sh --trigger compaction` | Save workspace state before compaction |
| `SubagentStart` | `subagent-start.sh` | Add governance context when a subagent starts |
| `SubagentStop` | `subagent-stop.sh` | Mark subagent completion |

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
