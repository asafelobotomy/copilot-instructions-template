---
name: Plugin Components
applyTo: "agents/**,skills/**,hooks/**,plugin.json"
description: "Conventions for authoring agents, skills, hooks, and plugin manifests in this repo"
---

# Plugin Component Instructions

## Tool naming in agent and skill bodies

VS Code's interactive question UI tool is `askQuestions` (camelCase). The fully qualified runtime name is `vscode_askQuestions`.

| Context | Correct form |
|---------|-------------|
| `tools:` frontmatter array | `askQuestions` |
| Inline prose reference | `` `askQuestions` `` |
| Tool invocation (system / API) | `vscode_askQuestions` |

**Never write `ask_questions` (snake_case)** — this form does not exist in VS Code's tool API (GA as `askQuestions` since v1.110).

## Agents (`agents/*.agent.md`)

- Every agent must have: `name`, `description`, `argument-hint`, `model` (list), `tools`, `agents` (delegation allow-list).
- `user-invocable: false` means the agent is internal delegation only — also set `"visibility": "internal"` in `agents/routing-manifest.json` to match.
- `agents:` lists the agents this specialist may delegate to. Keep it tight — do not add agents speculatively.
- Descriptions must be one sentence. Trigger phrases in `argument-hint` must match the canonical trigger table in `AGENTS.md`.
- Add a corresponding entry to `agents/routing-manifest.json` when adding a new agent.
- Update `llms.txt` and `workspace-index.json` after any agent addition or removal (`bash scripts/workspace/sync-workspace-index.sh --write`).

## Skills

Two skill directories serve different audiences:

- `skills/` (repo root) — developer workspace skills, auto-loaded via `chat.skillsLocations` in `.vscode/settings.json`. Edit these for developer-facing workflows.
- `.github/skills/` — consumer-facing skills delivered to plugin installers via `.plugin/plugin.json` and `.claude-plugin/plugin.json` (`"skills": "../.github/skills"`). Keep this directory in sync when the corresponding root skill changes significantly.

Each SKILL.md must start with a frontmatter block: `name`, `description` (one sentence, routing-optimised — state the trigger intent, not the workflow steps), `version`.
Description must answer "when should a model load this skill?" — not "what does this skill do step by step?"
After adding a skill, add a corresponding `llms.txt` entry and re-run `bash scripts/workspace/sync-workspace-index.sh --write`.

## Hooks (`hooks/scripts/`, `hooks/hooks.json`, `.github/hooks/`)

- Hook scripts accept JSON on stdin and must emit JSON on stdout (stdio protocol). Never print plain text.
- All hook scripts must use `set -euo pipefail` (shell) or equivalent strict mode.
- `hooks/hooks.json` (plugin component) and `.github/hooks/copilot-hooks.json` (VS Code developer config) must be kept in sync — edit both when adding or removing a registration.
- Use `${TMPDIR:-/tmp}` rather than bare `/tmp` in hook scripts.
- Python hook scripts must pass `python3 -m py_compile` before commit.

## Plugin Manifests (`plugin.json`, `.plugin/`, `.claude-plugin/`)

- `plugin.json` is the VS Code Copilot plugin manifest. It must contain only `agents` and `skills` — do NOT add `hooks` or `mcpServers`. VS Code Copilot plugin format has no plugin-root token, so any hook or MCP executable path would be resolved incorrectly (token expands to empty string, producing paths like `/hooks/scripts/...`).
- `.plugin/plugin.json` uses `${PLUGIN_ROOT}` for OpenPlugin format. `.claude-plugin/plugin.json` uses `${CLAUDE_PLUGIN_ROOT}` for Claude format. These manifests CAN include `hooks` and `mcpServers` because their respective runtimes expand the token correctly.
- MCP server paths in `.plugin/.mcp.json` and `.claude-plugin/.mcp.json` must point to `.github/hooks/scripts/mcp-heartbeat-server.py` relative to the plugin root.
- After changing any manifest, verify that `.vscode/mcp.json` and `template/vscode/mcp.json` remain consistent with the plugin MCP config.
