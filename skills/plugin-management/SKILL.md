---
name: plugin-management
description: Discover, evaluate, install, test, and manage agent plugins for VS Code Copilot
compatibility: ">=3.2"
---

# Plugin Management

> Skill metadata: version "1.1"; license MIT; tags [plugins, agents, extensions, discovery, management]; compatibility ">=3.2"; recommended tools [codebase, runCommands, editFiles].

Agent plugins (VS Code 1.110+, Preview) bundle agents, skills, hooks, MCP servers, and slash commands as installable packages.

## When to use

- The user asks to find, list, install, or manage agent plugins
- A task would benefit from a plugin-provided agent or skill
- You need to check for conflicts between plugin-contributed and workspace-level agents or skills
- The user wants to test the template as a local plugin

## What plugins provide

| Type | Description |
|------|-------------|
| Slash commands | Additional `/` commands in chat |
| Skills | Instructions, scripts, and resources |
| Agents | Specialized personas and tool configs |
| Hooks | Shell commands at lifecycle points (`hooks/hooks.json`, `copilot-hooks.json`, or `plugin.json` hooks component) |
| MCP servers | External tool integrations (`.mcp.json` at plugin root, `mcpServers` key) |

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

Before installing, verify:

- [ ] **Publisher trust** — known publisher or verified org
- [ ] **Maintenance** — updated within 12 months; not abandoned/archived
- [ ] **No credential exposure** — no secrets beyond standard VS Code secret storage
- [ ] **Conflict check** — no naming collisions with existing agents, skills, or hooks
- [ ] **Scope review** — minimum capability requested (check agent/skill metadata)
- [ ] **Hook review** — inspect hook scripts before enabling (execute with VS Code permissions)
- [ ] **MCP review** — verify MCP server sources and tool capabilities

Reject plugins failing two or more checks.

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

Plugins can fire hooks at lifecycle events (`SessionStart`, `PreToolUse`, `PostToolUse`, `PreCompact`, `SubagentStart`, `SubagentStop`, `Stop`). Use `${CLAUDE_PLUGIN_ROOT}` in hook commands. Plugin hooks are implicitly trusted on install. Disabling a plugin also disables its hooks.

## Plugin MCP servers

Config in `.mcp.json` at plugin root (`mcpServers` key, not `servers`). Use `${CLAUDE_PLUGIN_ROOT}` in `command`, `args`, `cwd`, `env`, `url`, `headers`. Implicitly trusted; disabling a plugin stops its MCP servers.

## Settings reference

| Setting | Purpose |
|---------|---------|
| `chat.plugins.enabled` | Enable/disable plugin discovery (boolean) |
| `chat.plugins.marketplaces` | Git repositories serving as plugin marketplaces (array of owner/repo) |
| `chat.pluginLocations` | Local paths for plugin development/testing (map of path → boolean) |

## Workspace plugin recommendations

Projects can recommend plugins:

```json
{
  "extraKnownMarketplaces": {
    "company-tools": {
      "source": { "source": "github", "repo": "your-org/plugin-marketplace" }
    }
  },
  "enabledPlugins": { "code-formatter@company-tools": true }
}
```

## Testing the template as a plugin

1. Clone or use an existing local copy
2. Add to settings: `"chat.pluginLocations": { "/path/to/copilot-instructions-template": true }`
3. Reload VS Code — plugin agents appear in Copilot dropdown
4. Open Agent Debug Panel to confirm agents, skills, hooks loaded
5. Check for conflicts with workspace-level agents in `.github/agents/`

## Managing installed plugins

1. **List** — Extensions view → filter `@agentPlugins`
2. **Inspect** — select to see contributed agents, skills, MCP servers, commands
3. **Disable** — right-click → Disable (globally or per-workspace; disables hooks and MCP servers)
4. **Remove** — right-click → Uninstall
5. **Update** — `Extensions: Check for Extension Updates` or automatic every 24h

## Verify

- [ ] Plugin found or suitable alternative identified
- [ ] Quality gate applied (including hook and MCP review)
- [ ] No unresolved naming conflicts
- [ ] Agent Debug Panel confirms correct loading and source attribution
