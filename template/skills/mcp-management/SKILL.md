---
name: mcp-management
description: Configure and manage Model Context Protocol servers for external tool access
compatibility: ">=1.4"
---

# MCP Management

> Skill metadata: version "1.1"; license MIT; tags [mcp, servers, configuration, integration]; compatibility ">=1.4"; recommended tools [codebase, editFiles, fetch].

MCP enables Copilot to invoke external servers that provide tools, resources, prompts, and interactive UI (MCP Apps) beyond built-in capabilities. Configuration lives in `.vscode/mcp.json`.

## When to use

- The user asks to configure, add, list, or check MCP servers
- You need to determine which MCP servers are available
- A task would benefit from an external tool not yet configured

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
| `github/github-mcp-server` | Credentials | HTTP remote (`type: "http"`) | GitHub API — issues, PRs, repos, actions |
| `mcp-server-fetch` | Credentials | **`uvx`** (Python — not on npm) | HTTP fetch for web content and APIs |

> **Removed (v3.2.0):** `@modelcontextprotocol/server-memory` — replaced by VS Code's built-in memory tool (`/memories/`), which provides persistent storage with three scopes: user (cross-workspace), session (conversation), and repository.

## Adding a new server

Before adding any MCP server:

1. Check if a built-in tool or existing MCP server already covers the need
2. Search `@mcp` in the Extensions view to browse the MCP gallery, or check the MCP registry (`github.com/modelcontextprotocol/servers`)
3. Check for `npx` vs `uvx` vs HTTP remote runtime requirement
4. Add to `.vscode/mcp.json` with appropriate tier classification
5. For credentials-required servers, use `${input:}` or `${env:}` variable syntax — never hardcode secrets
6. For stdio servers on Linux/macOS, add `sandboxEnabled: true` with `sandbox.filesystem.denyRead` rules for credential directories. Optionally add `sandbox.network.allowedDomains` to restrict outbound network access

### Sandbox compatibility (Linux)

On immutable Linux distros (Fedora Atomic/Bazzite/Silverblue, NixOS) where `/home` is a symlink to `/var/home`, the `bwrap` sandbox rejects `allowWrite` paths because symlink resolution points outside the expected location. Detect at setup time:

```bash
[[ "$(readlink -f /home)" != "/home" ]] && echo "immutable" || echo "standard"
```

- **standard**: use sandboxed config (`sandboxEnabled: true` + `allowWrite`/`denyRead` rules)
- **immutable**: omit `sandboxEnabled`, `sandbox`, and the top-level `sandbox` block entirely

## Auto-start

Set `"chat.mcp.autostart": "newAndOutdated"` in `.vscode/settings.json` so MCP servers start automatically when a chat message is sent. This eliminates the need to manually click the refresh/start button each session. VS Code will show a trust dialog the first time a new or changed server auto-starts.

## CLI and external agent access

As of VS Code 1.113, MCP servers configured in `.vscode/mcp.json` are automatically bridged to Copilot CLI and Claude agents. No additional configuration is required — servers registered in the workspace or user profile are available to all agent runtimes.

## Settings Sync

With Settings Sync enabled, MCP server configurations can be synchronised across devices. Run `Settings Sync: Configure` and enable the **MCP Servers** option.

## Subagent MCP use

Subagents inherit access to all configured MCP servers. A subagent may invoke any server already in `.vscode/mcp.json`. To **add** a new server, the subagent must flag the proposal to the parent agent, which confirms before modifying `.vscode/mcp.json`.
