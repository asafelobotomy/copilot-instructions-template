# Research: VS Code Insiders Updates — v1.100 through v1.115

> Date: 2026-04-09 | Agent: Researcher | Status: final

## Summary

VS Code has shipped sixteen monthly/weekly releases from v1.100 (April 2025) through v1.115 (April 8, 2026). The dominant theme is **agent-native development**: agent plugins, Autopilot, agent-scoped hooks, monorepo customisation discovery, a Chat Customisations editor, MCP sandboxing, nested subagents, and a dedicated VS Code Agents companion app. The cadence accelerated to weekly stable releases starting with v1.111. Every major feature is directly or indirectly relevant to the copilot-instructions-template project, which packages agents, skills, hooks, MCP configs, prompt files, and starter-kit plugins.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://code.visualstudio.com/updates/v1_100 | April 2025: instructions/prompt files alignment, #githubRepo, MCP Streamable HTTP |
| https://code.visualstudio.com/updates/v1_103 | July 2025: GPT-5, chat checkpoints, tool picker, tool grouping, terminal auto-approve |
| https://code.visualstudio.com/updates/v1_105 | September 2025: Plan agent, handoffs, subagents, Codex/CLI integration, qualified tool names |
| https://code.visualstudio.com/updates/v1_107 | November 2025: Multi-agent orchestration, background agents, agent sessions view |
| https://code.visualstudio.com/updates/v1_110 | February 2026: Agent plugins, browser tools, session memory, context compaction, fork session, Agent Debug panel |
| https://code.visualstudio.com/updates/v1_111 | March 9, 2026: Autopilot + agent permissions, agent-scoped hooks, weekly stable releases |
| https://code.visualstudio.com/updates/v1_112 | March 18, 2026: MCP sandboxing, monorepo discovery, image/binary support, Copilot CLI permissions |
| https://code.visualstudio.com/updates/v1_113 | March 25, 2026: Chat Customisations editor, nested subagents, MCP in CLI/Claude agents, plugin URL handlers |
| https://code.visualstudio.com/updates/v1_114 | April 1, 2026: /troubleshoot sessions, codebase search simplification, TypeScript 6.0, fine-grained tool approval |
| https://code.visualstudio.com/updates/v1_115 | April 8, 2026: VS Code Agents companion app, send_to_terminal, background terminal notifications |

---

## Findings by Category

---

### 1. Instructions Files & Prompt Files

**Status: GA (v1.100+)**

v1.100 aligned the implementation of `.instructions.md` and `.prompt.md` files:

- **Instructions files** (`.instructions.md`) carry `applyTo` front matter glob patterns and are auto-attached to matching requests. Setting: `chat.instructionsFilesLocations`. Command: `Chat: New Instructions File...`.
- **Prompt files** (`.prompt.md`) are standalone chat requests with `mode` (`ask`/`edit`/`agent`) and `tools` front matter. Run via `/promptname` slash, the Play button in the editor, or `Chat: Run Prompt File...`.
- Both accept a `description` metadata header.
- Both sync through Settings Sync (opt in via "Prompts and Instructions" in Backup and Sync Settings).
- **Language IDs**: "Prompt" and "Instructions" modes are now callable from the language mode picker.

**Template relevance (HIGH)**: The template already delivers `.instructions.md` and `.prompt.md` files under `template/instructions/` and `template/prompts/`. The `description` front matter field is now formally supported; template stubs should carry it. The Settings Sync support means user-level instruction files can roam across machines — consumers should understand the distinction between user-data instructions (synced) and workspace instructions (repo-local).

---

### 2. AGENTS.md / CLAUDE.md / copilot-instructions.md Handling

**AGENTS.md GA (v1.105)**; **Monorepo discovery GA (v1.112)**

- `AGENTS.md` at workspace root is now generally available (was experimental in v1.104).
- `CLAUDE.md` is supported as an always-on instruction file alongside `copilot-instructions.md` and `AGENTS.md`.
- **Nested AGENTS.md files** (`chat.useNestedAgentsMdFiles`): GA in v1.105. Subdirectory AGENTS.md files are picked up automatically.
- **Monorepo parent-repo discovery** (`chat.useCustomizationsInParentRepositories`, v1.112): When the open workspace is a subdirectory (not itself a Git root), VS Code walks parent folders to the Git root and discovers all customisation types — `copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`, instruction files, prompt files, custom agents, skills, and hooks. Requires the parent repo to be workspace-trusted.

**Template relevance (HIGH)**: This project ships `AGENTS.md` and `CLAUDE.md`. Monorepo discovery means consumers who open a package subfolder instead of the repo root will still pick up all template-delivered customisations without any extra setup. This should be documented in `SETUP.md` / `README.md`.

---

### 3. Agent Mode Capabilities

**Status: GA, with specific features in Insiders**

Key progression:

| Release | Feature | Status |
|---------|---------|--------|
| v1.100 | Faster edits: OpenAI apply-patch + Anthropic replace-string tool | GA |
| v1.100 | Autofix diagnostics from agent edits (`github.copilot.chat.agent.autoFix`) | GA |
| v1.100 | Prompt caching for conversation summaries | GA |
| v1.103 | Chat checkpoints (`chat.checkpoints.enabled`) | GA |
| v1.105 | Plan agent (research/plan before coding) | Insiders→GA |
| v1.105 | Handoffs in custom chat modes (`handoffs` front matter) | Insiders→GA |
| v1.105 | Isolated subagents (`#runSubagent` tool) | Insiders→GA |
| v1.107 | Background agents (Copilot CLI) in Agent Sessions view | GA |
| v1.110 | Context compaction (`/compact`) | GA |
| v1.110 | Fork a chat session (`/fork`) | GA |
| v1.110 | Edit mode deprecated (hidden by default, `chat.editMode.hidden`) | GA |
| v1.111 | Autopilot: Default / Bypass Approvals / Autopilot levels | Insiders→GA |
| v1.111 | `task_complete` tool (agents signal done) | GA |
| v1.113 | Nested subagents (`chat.subagents.allowInvocationsFromSubagents`) | GA |
| v1.115 | VS Code Agents companion app (parallelize across worktrees) | Insiders only |

**Template relevance (HIGH)**: The `handoffs` front matter field in custom `.agent.md` files is now fully supported. The template's agent definitions (`.github/agents/`) can specify `handoffs` to guide multi-step workflows. The `task_complete` tool signals that agent mode now has a formal completion signal — agent definitions may benefit from knowing this. Edit mode deprecation in v1.110 means template prompt files that specified `mode: 'edit'` should be migrated to `mode: 'agent'` with appropriate tool restrictions.

---

### 4. Agent Plugins (Starter Kits)

**Status: Experimental → GA track (v1.110+)**

- **Agent Plugins** (v1.110): Install pre-packaged bundles of skills, tools, and hooks from the Extensions view. Functionally equivalent to the template's "starter kits" concept. Plugin bundles are discovered from a marketplace or local directory.
- **Manage Plugin Marketplaces** (v1.113): New command `Chat: Manage Plugin Marketplaces` lists configured marketplaces with browse/open/remove.
- **URL handlers for plugin installation** (v1.113): Install a plugin marketplace via `vscode://chat-plugin/add-marketplace?ref=<repo>` or an extension via `vscode://chat-plugin/install?source=<source>`. For Insiders: `vscode-insiders://...`.

**Template relevance (CRITICAL)**: The template's `starter-kits/` directory maps directly onto the Agent Plugin architecture. The URL handler scheme means the template could provide one-click install links for each starter kit in `README.md` or `SETUP.md`. The `plugin.json` structure in each `starter-kits/<stack>/` should be verified for compatibility with the current agent plugin format.

---

### 5. Agent-Scoped Hooks

**Status: Preview (v1.111), setting: `chat.useCustomAgentHooks`**

- An `.agent.md` file can now contain a `hooks` section in its YAML frontmatter. These hooks run only when that specific agent is selected or invoked via `runSubagent`.
- This is distinct from global hooks in `copilot-hooks.json`.
- Documentation: https://code.visualstudio.com/docs/copilot/customization/hooks#_agentscoped-hooks

**Template relevance (HIGH)**: The template has a full hooks system (`template/hooks/copilot-hooks.json`, `.github/hooks/`). Agent-scoped hooks can reduce noise from global hooks; the template's Stop and PostToolUse hooks could potentially be scoped to specific agents rather than running globally. The agent definitions in `.github/agents/` should be reviewed for candidates. The hooks documentation and `SKILL.md` for the commit-preflight and hooks management skills should reference this feature.

---

### 6. MCP Integration

**Status: GA (core); Sandbox on macOS/Linux in v1.112**

| Release | Feature | Status |
|---------|---------|--------|
| v1.100 | Streamable HTTP transport for MCP | GA |
| v1.100 | Image attachments in MCP calls | GA |
| v1.103 | Tool grouping for >128 tools (`github.copilot.chat.virtualTools.threshold`) | Experimental |
| v1.105 | Fully qualified tool names (`server/tool_name`) with code action to migrate | GA |
| v1.112 | MCP server sandboxing (`"sandboxEnabled": true` in `mcp.json`) — macOS+Linux only | GA |
| v1.113 | MCP servers available in Copilot CLI and Claude agent sessions | GA |

**Fully qualified tool names** (v1.105) change how tools are referenced in `tools:` lists in prompt files and custom agents: `codebase` → `search/codebase`, `list_issues` → `github/github-mcp-server/list_issues`. A code action helps migrate. Template prompt files in `template/prompts/` should be audited.

**MCP sandboxing** (`"sandboxEnabled": true` in `mcp.json`): restricts file system and network access for stdio MCP servers. VS Code prompts for additional permissions on demand. This is a security improvement consumers should enable for any MCP server that doesn't need broad access.

**Template relevance (HIGH)**: The template configures MCP servers in `.vscode/mcp.json`. Adding `"sandboxEnabled": true` to the filesystem and git server entries (where appropriate) would improve security posture. The `mcp-management` skill and `mcp-builder` skill should document the sandboxing option and the qualified tool name convention.

---

### 7. Chat Customisations Editor

**Status: Preview (v1.113)**

A unified UI for creating and managing all chat customisations from one place. Opens via `Chat: Open Chat Customisations` or the gear icon in Chat view. Tabs for: instructions, prompt files, custom agents, skills, MCP servers, and plugins. Embedded code editor with syntax highlighting and validation. Can generate initial content with AI using project context.

**Template relevance (MEDIUM)**: Consumers will use this as their primary interface for managing template-delivered files. It should be mentioned in documentation. The template's instruction/prompt/agent files will surface here with their `description` metadata displayed — strong incentive to ensure all template stubs carry accurate `description` fields.

---

### 8. `/troubleshoot` Skill & Agent Debug Tooling

**Status: Preview (v1.112+)**

- `/troubleshoot` (v1.112): analyses agent debug logs inline in chat to explain why instructions/skills/agents loaded or failed to load, why responses are slow, and whether network issues occurred. Requires `github.copilot.chat.agentDebugLog.enabled` and `github.copilot.chat.agentDebugLog.fileLogging.enabled`.
- Previous session troubleshooting (v1.114): attach `#session` to `/troubleshoot` to analyse any prior session from a picker.
- `#debugEventsSnapshot` (v1.111): snapshot of debug events attachable as chat context.
- Export/import agent debug logs (v1.112): share JSONL debug files.

**Template relevance (MEDIUM)**: The template's `HEARTBEAT.md` and retrospective workflow document health. The `/troubleshoot` skill provides the VS Code-native equivalent. The `fix-ci-failure` skill and any debugging guidance in `.github/instructions/` should note this tool. If a user reports that template-delivered instructions aren't being picked up, `/troubleshoot` is the recommended first diagnostic step.

---

### 9. Workspace Search / `#codebase` Simplification

**Status: GA (v1.114)**

- `#codebase` is now **semantic-only**. The local/remote index distinction is removed; VS Code manages indexes automatically.
- For very large codebases without a GitHub remote, indexing is rolling out.
- Agents that still need text/fuzzy searching use other tools; `#codebase` is reserved for semantic queries.

**Template relevance (LOW)**: No direct impact on template artefacts, but the `semantic_search` tool reference in agent definitions and prompt files remains correct. The simplified indexing means consumers get semantic search without any manual index management.

---

### 10. Terminal Integration

**Status: GA and Experimental**

| Release | Feature | Status |
|---------|---------|--------|
| v1.103 | Terminal auto-approve (`chat.tools.terminal.autoApprove`) | GA |
| v1.103 | Input request detection (scripts prompting for Y/N) | GA |
| v1.110 | `/autoApprove` / `/disableAutoApprove` slash commands | GA |
| v1.110 | Kitty graphics protocol (high-fidelity images in terminal) | GA |
| v1.115 | `send_to_terminal` tool (write to background terminals) | GA |
| v1.115 | Background terminal notifications (`chat.tools.terminal.backgroundNotifications`) | Experimental |

The `send_to_terminal` tool in v1.115 is exactly the tool referenced in the template's current `terminal_selection` instructions. The template's terminal instructions (`.github/instructions/terminal.instructions.md`) should be reviewed to confirm guidance is consistent.

**Template relevance (MEDIUM)**: `terminal.instructions.md` documents shell safety rules. The auto-approve and `send_to_terminal` tools expand what agents can do without user confirmation. The instructions file may benefit from a note about agent terminal permission levels.

---

### 11. Weekly Stable Release Cadence

**Status: GA (from v1.111, March 9, 2026)**

VS Code now follows a **weekly stable** release cycle. Feature releases still happen monthly but patch/hotfix stable builds ship every week. Previously, stable was monthly and Insiders was daily.

**Template relevance (MEDIUM)**: The template's `MODELS.md` and version verification scripts assume monthly releases. The `workspace-index.json` may need more frequent syncs. Any documentation that says "monthly release" should be updated. The template's Insiders positioning is less differentiated now since stable ships weekly.

---

### 12. New Tools APIs & Extension APIs (Proposed)

| API | Description | Status |
|-----|-------------|--------|
| Fine-grained tool approval (`approveCombination`) | Scope user approval to a specific tool+arguments combination, not just the tool class | Proposed (v1.114) |
| `send_to_terminal` | Write to a background terminal session | GA (v1.115) |
| `askQuestions` | Present a question carousel UI | GA/core (v1.110) |
| `task_complete` | Agent signals task completion | GA (v1.111) |
| Agent plugin manifest (`plugin.json`) | Bundle skills/tools/hooks for distribution | GA (v1.110) |
| URL handlers for plugins | `vscode://chat-plugin/install?source=...` | GA (v1.113) |

**Template relevance (HIGH for plugin API)**: The `plugin.json` in each `starter-kits/<stack>/` should conform to the current agent plugin manifest schema. URL install links would make starter kit distribution significantly more ergonomic.

---

### 13. Enterprise & Workspace Trust

| Release | Feature |
|---------|---------|
| v1.112 | Monorepo parent-repo discovery requires workspace trust on the parent |
| v1.114 | Group policy to disable Claude agent (`Claude3PIntegration = false`) |
| v1.112 | MCP sandbox restricts local server permissions |

**Template relevance (LOW-MEDIUM)**: The enterprise Claude policy and MCP sandboxing are relevant for consumers running in managed enterprise environments. The template's `.vscode/mcp.json` and SETUP.md could note the enterprise security options.

---

## Recommendations for the copilot-instructions-template Project

### Immediate (high-priority)

1. **Add `description` front matter to all `.instructions.md` and `.prompt.md` stubs** in `template/instructions/` and `template/prompts/`. The Chat Customisations editor will display this metadata, and VS Code plans to use `description` for auto-inclusion logic.

2. **Audit `tools:` lists in prompt files and agent definitions** for unqualified tool names. Migrate to fully qualified form (`search/codebase`, `github/github-mcp-server/list_issues`) — a code action in VS Code already flags these. Priority files: `template/prompts/`, `.github/prompts/`, `.github/agents/*.agent.md`.

3. **Update SETUP.md / README.md** to mention `chat.useCustomizationsInParentRepositories` (v1.112) so monorepo consumers know their parent-repo customisations are auto-discovered without opening the repo root.

4. **Review `plugin.json` schema** in each `starter-kits/<stack>/` for compatibility with the current agent plugin format and add URL-handler install links to `starter-kits/REGISTRY.json` or `SETUP.md`.

### Medium-priority

5. **Agent-scoped hooks**: Review `.github/agents/*.agent.md` for hooks that should be scoped per-agent rather than global. Move global noise from `copilot-hooks.json` to per-agent `hooks:` front matter where appropriate. Update `mcp-management/SKILL.md` accordingly.

6. **Edit mode deprecation**: Audit `template/prompts/` and `.github/prompts/` for any `mode: 'edit'` front matter and migrate to `mode: 'agent'` with a restricted `tools:` list.

7. **MCP sandboxing**: Add `"sandboxEnabled": true` to applicable entries in `.vscode/mcp.json` and document this in the `mcp-management` skill and `mcp-builder` skill.

8. **Document `/troubleshoot`** as the recommended first step when consumers report that template instructions/skills/agents are not loading. Consider adding a note to `HEARTBEAT.md` or the setup audit.

9. **VS Code Agents companion app** (v1.115): All template customisations carry over. Document this explicitly in `README.md` so consumers know their template setup works in the companion app.

### Follow-up research

10. **Agent Plugin manifest schema**: Fetch the current schema from VS Code Copilot Chat extension docs or the `vscode-copilot-chat` repo to verify `plugin.json` compatibility in `starter-kits/`.
11. **Handoffs front matter spec**: Fetch the custom-agents docs for the current `handoffs` field schema to validate/extend the agent definitions in `.github/agents/`.
12. **Weekly release infrastructure**: Check if `scripts/release/verify-version-references.sh` needs updating for the new weekly cadence.

---

## Gaps / Further Research Needed

- Complete v1.101, v1.102, v1.104, v1.106, v1.108, v1.109 release notes not individually fetched (covered partially via RESEARCH.md entries for v1.109/v1.110).
- The `plugin.json` schema specification has not been verified against the actual `starter-kits/` files — this should be done before any plugin URL handler links are added.
- The `handoffs` front matter field is documented in the v1.105 release notes but the full spec (required vs optional fields, `send` flag behaviour) was not deep-fetched.
- Background terminal notification events (`chat.tools.terminal.backgroundNotifications`) may affect the template's `run_in_terminal` async tool guidance — further testing needed.
