---
name: mcp-management
description: Configure and manage Model Context Protocol servers for external tool access
---

# MCP Management

> Skill metadata: version "1.0"; license MIT; tags [mcp, servers, configuration, integration]; compatibility ">=1.4"; recommended tools [codebase, editFiles, fetch].

MCP (Model Context Protocol) is GA in VS Code as of v1.102. MCP servers provide tools, resources, and prompts beyond built-in capabilities. Configuration lives in `.vscode/mcp.json` (workspace-scoped) or profile-level `mcp.json` (user-scoped).

## When to use

- The user asks to configure, add, list, or check MCP servers
- You need to determine which MCP servers are available
- A task would benefit from an external tool not yet configured

## Configuration locations

| Location | Scope | When to use |
|----------|-------|-------------|
| `.vscode/mcp.json` | Workspace | Project-specific servers shared via version control |
| Profile-level `mcp.json` | User | Personal servers available across all workspaces |
| `settings.json` `"mcp"` key | User/Workspace | Alternative to standalone `mcp.json` |
| Dev container `customizations.vscode.mcp` | Container | Per-container MCP servers |

**VS Code commands:**

- `MCP: Open Workspace Configuration` — edit `.vscode/mcp.json`
- `MCP: Open User Configuration` — edit profile-level `mcp.json`

## Server tiers

| Tier | Default servers | When to enable | Configuration |
|------|----------------|-----------------|---------------|
| Always-on | filesystem, git | Every project — core development tools | Enabled by default in `.vscode/mcp.json` |
| Credentials-required | github, fetch | When external API access is needed | Requires `${input:github-token}` or `${env:GITHUB_PERSONAL_ACCESS_TOKEN}` (GitHub) |

## Available servers

| Server | Tier | Command | Purpose |
|--------|------|---------|--------|
| `@modelcontextprotocol/server-filesystem` | Always-on | `npx` | File operations beyond the workspace |
| `mcp-server-git` | Always-on | **`uvx`** (Python — not on npm) | Git history, diffs, and branch operations |

> **Removed (v3.2.0):** `@modelcontextprotocol/server-memory` — replaced by VS Code's built-in memory tool (`/memories/`), which provides persistent storage with three scopes: user (cross-workspace), session (conversation), and repository.
| `@modelcontextprotocol/server-github` | Credentials | `npx` | GitHub API — issues, PRs, repos, actions |
| `mcp-server-fetch` | Credentials | **`uvx`** (Python — not on npm) | HTTP fetch for web content and APIs |

## MCP capabilities (GA since v1.102)

MCP servers can expose four capability types:

| Capability | Description | Agent interaction |
|-----------|-------------|-------------------|
| **Tools** | Functions the agent can invoke (e.g., query database, call API) | Agent calls tools directly |
| **Resources** | Data sources the agent can read (e.g., database schemas, config files) | Agent reads from `#` context menu |
| **Prompts** | Reusable prompt templates provided by the server | Available via `/` slash commands |
| **Sampling** | Server requests the agent to generate text on its behalf | Agent responds to server requests |

Additional features: **elicitations** (server requests user input via the agent), **MCP auth** (OAuth/token flows for secure server connections).

## Server discovery

- **MCP Marketplace**: Browse and install servers from `code.visualstudio.com/mcp`
- **Official registry**: `github.com/modelcontextprotocol/servers`
- **Community registries**: `mcp.so`, `glama.ai`, `smithery.ai`
- **Agent plugins**: MCP servers can be bundled inside agent plugins (`@agentPlugins` in Extensions view)

## Adding a new server

Before adding any MCP server:

1. Check if a built-in tool or existing MCP server already covers the need
2. Search the MCP Marketplace (`code.visualstudio.com/mcp`) and official registry
3. Check for `npx` vs `uvx` runtime requirement
4. Add to `.vscode/mcp.json` (workspace) or profile `mcp.json` (user) with appropriate tier
5. For credentials-required servers, use `${input:}` or `${env:}` variable syntax — never hardcode secrets
6. Agent files can restrict MCP access using the `mcp-servers` frontmatter field

## Subagent MCP use

Subagents inherit access to all configured MCP servers. A subagent may invoke any server already in `.vscode/mcp.json`. To **add** a new server, the subagent must flag the proposal to the parent agent, which confirms before modifying `.vscode/mcp.json`.
