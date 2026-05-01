---
name: mcp-management
description: Configure and manage Model Context Protocol servers for external tool access
compatibility: ">=1.4"
---

# MCP Management

> Skill metadata: version "1.1"; license MIT; tags [mcp, servers, configuration, integration]; compatibility ">=1.4"; recommended tools [codebase, editFiles, fetch].

MCP (Model Context Protocol) is GA in VS Code v1.102+. Servers provide tools, resources, and prompts beyond built-in capabilities. Config in `.vscode/mcp.json` (workspace) or profile-level `mcp.json` (user).

## When to use

- The user asks to configure, add, list, or check MCP servers
- You need to determine which MCP servers are available
- A task would benefit from an external tool not yet configured

## Configuration locations

| Location | Scope |
|----------|-------|
| `.vscode/mcp.json` | Workspace — shared via VCS |
| Profile-level `mcp.json` | User — all workspaces |
| `settings.json` `"mcp"` key | User/Workspace alternative |
| Dev container `customizations.vscode.mcp` | Per-container |

Commands: `MCP: Open Workspace Configuration`, `MCP: Open User Configuration`

## Server tiers

| Tier | Servers | When | Config |
|------|---------|------|--------|
| Always-on | filesystem, git | Every project | Enabled by default |
| External | github, fetch | GitHub/web access needed | `github` uses VS Code OAuth; `fetch` needs no creds |
| Documentation | context7 | Third-party libraries | HTTP remote, free tier, optional API key |
| Optional | sequential-thinking | Complex planning or architecture tasks requiring explicit thought branching | Disabled by default; enable per-workspace or at user level |

## Available servers

| Server | Tier | Transport | Purpose |
|--------|------|-----------|---------|
| `@modelcontextprotocol/server-filesystem` | Always-on | `npx` (stdio) | File operations within the workspace; supports OS-level sandboxing |
| `mcp-server-git` | Always-on | **`uvx`** (stdio, Python) | Git history, diffs, and branch operations |
| `github/github-mcp-server` | Credentials | **HTTP remote** (`https://api.githubcopilot.com/mcp/`) | GitHub API — issues, PRs, repos, Actions, CI/CD, security alerts, Dependabot |
| `mcp-server-fetch` | Credentials | **`uvx`** (stdio, Python) | HTTP fetch for web content and APIs |
| `@upstash/context7-mcp` | Documentation | **HTTP remote** (`https://mcp.context7.com/mcp`) | Live, version-specific library documentation — prevents hallucinated or outdated APIs |
| `@modelcontextprotocol/server-sequential-thinking` | Optional | **`npx`** (stdio) | Explicit step-by-step reasoning — externalizes thought trees with revisable steps for complex planning and architecture decisions |

> **Removed (v3.2.0):** `@modelcontextprotocol/server-memory` — replaced by VS Code's built-in memory tool (`/memories/`). **Archived:** `@modelcontextprotocol/server-github` (npm) — replaced by `github/github-mcp-server` HTTP remote.

## Stack-specific servers

Not included in base template. Add to `.vscode/mcp.json` by stack:

| Stack | Server | Notes |
|-------|--------|-------|
| Browser/UI testing | `@playwright/mcp` (Microsoft) | **Removed from default template in v0.7.0.** Use Path A (browser tools) or Path B (Playwright CLI) from the `webapp-testing` skill. Add manually if required. |
| PostgreSQL, SQLite, Redis | Search MCP Marketplace | Official reference servers archived; find maintained replacements |
| Docker | Search MCP Marketplace | Evaluate trust and permissions carefully |
| AWS | Search MCP Marketplace | Fine-grained IAM via `${env:}`, never hardcode |

Discover servers: `code.visualstudio.com/mcp` · `registry.modelcontextprotocol.io` · `glama.ai` · `smithery.ai`

### Sequential Thinking

`@modelcontextprotocol/server-sequential-thinking` (`npx`, stdio) provides an explicit reasoning scratchpad: structured steps with revisable thoughts, branch tracking, and persistent reasoning state across tool calls.

**Tool name**: `mcp_sequential-th_sequentialthinking`

**When to invoke** — the external tool adds value beyond the built-in Structured Thinking Discipline when:

- A planning task requires explicit thought-tree branching or backtracking to earlier reasoning states
- Architectural decisions need auditable, revisable steps visible in the chat UI for human review
- Multi-step problem decomposition must survive context switches (reasoning state persists server-side across tool calls)
- You want a shareable reasoning trace (e.g. for pairing or handoff)

**When the built-in discipline is sufficient**: standard single-turn implementation tasks, and any task where internal chain-of-thought is adequate and no external audit trail is needed.

**Deployment**: workspace `.vscode/mcp.json` when the reasoning pattern is relevant to the team; user-level `mcp.json` for personal workflows where committing the server to the workspace would be noise.

## MCP capabilities (GA since v1.102)

MCP servers can expose four capability types:

| Capability | Description | Agent interaction |
|-----------|-------------|-------------------|
| **Tools** | Functions the agent can invoke (e.g., query database, call API) | Agent calls tools directly |
| **Resources** | Data sources the agent can read (e.g., database schemas, config files) | Agent reads from `#` context menu |
| **Prompts** | Reusable prompt templates provided by the server | Available via `/` slash commands |
| **MCP Apps** | Interactive UI components (forms, visualisations, drag-and-drop) | Rendered inline in chat responses |
| **Sampling** | Server requests the agent to generate text on its behalf | Agent responds to server requests |

Additional features: **elicitations** (server requests user input via the agent), **MCP auth** (OAuth/token flows for secure server connections).

## Server discovery

- **MCP gallery**: In the Extensions view, search `@mcp` to browse and install servers directly (installs to user profile or workspace)
- **MCP Marketplace**: Browse and install servers from `code.visualstudio.com/mcp`
- **Official registry**: `github.com/modelcontextprotocol/servers`
- **Community registries**: `mcp.so`, `glama.ai`, `smithery.ai`
- **Agent plugins**: MCP servers can be bundled inside agent plugins (`@agentPlugins` in Extensions view)

## Adding a new server

Before adding any MCP server:

1. Check if a built-in tool or existing MCP server already covers the need
2. Search the MCP Marketplace (`code.visualstudio.com/mcp`) and official registry
3. Check for `npx` vs `uvx` vs HTTP remote transport — prefer HTTP remote for officially hosted servers (no local process, OAuth-managed auth)
4. Add to `.vscode/mcp.json` (workspace) or profile `mcp.json` (user) with appropriate tier
5. For credentials-required stdio servers, use `${input:}` or `${env:}` variable syntax — never hardcode secrets; HTTP remote servers use VS Code's built-in OAuth where supported
6. For `npx`-based stdio servers on Linux/macOS, add `sandboxEnabled: true` with `sandbox.filesystem.denyRead` rules for credential directories (`~/.ssh`, `~/.gnupg`, `~/.aws`) as a defence-in-depth measure against prompt injection. Optionally add `sandbox.network.allowedDomains` to restrict outbound network access. Do not sandbox `uvx`-based servers: the VS Code sandbox proxy intercepts PyPI network access during the `uvx` launcher phase and triggers repeated domain-approval prompts that cannot be reliably suppressed via per-server `allowedDomains`. The M4 audit check enforces this by exempting servers with `command == "uvx"` automatically.
7. In consumer template repos, keep optional servers such as `github`, `fetch`, and `context7` present in `.vscode/mcp.json` but disabled by default until setup or update explicitly enables them
8. Agent files can declare least-privilege MCP access using the `mcp-servers` frontmatter field. Treat this as forward-compatible policy metadata: GitHub Copilot cloud agents document support for the field today, while local VS Code agent support may lag behind

### Sandbox compatibility (Linux)

On immutable Linux distros (Fedora Atomic/Bazzite/Silverblue, NixOS) where `/home` symlinks to `/var/home`, `bwrap` rejects `allowWrite` paths. Detect: `[[ "$(readlink -f /home)" != "/home" ]] && echo "immutable" || echo "standard"`. **standard**: use sandboxed config. **immutable**: omit `sandboxEnabled`, `sandbox`, and top-level `sandbox` block.

## Auto-start

Set `"chat.mcp.autostart": "newAndOutdated"` in `.vscode/settings.json` — servers start on chat message. Trust dialog shown on first auto-start.

## CLI and external agent access

VS Code 1.113+: `.vscode/mcp.json` servers are bridged to Copilot CLI and Claude agents automatically.

## Settings Sync

Enable `Settings Sync: Configure` → **MCP Servers** to sync configs across devices.

## Subagent MCP use

Subagents inherit all configured MCP servers. To **add** a new server, the subagent flags the proposal to the parent agent before modifying `.vscode/mcp.json`.
