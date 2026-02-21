# MCP Guide — Human Reference

> **Machine-readable version**: §13 in `.github/copilot-instructions.md`
> This document explains what MCP is, how it integrates with the template, and how to configure it.

---

## What is MCP?

The **Model Context Protocol** (MCP) is an open standard that lets AI agents communicate with external tools and data sources through a structured JSON-RPC protocol. Instead of building custom integrations for each data source, MCP provides a universal interface.

In this template, MCP extends Copilot's capabilities beyond its built-in tools. Want Copilot to query your database, interact with Jira, or fetch API documentation? An MCP server makes that possible.

---

## How MCP works with this template

### §13 in the instructions file

Section 13 of `.github/copilot-instructions.md` tells Copilot how to discover, evaluate, and use MCP servers. It includes:

- A **server tier classification** (always-on, credentials-required, stack-specific)
- A **decision tree** for when to use an MCP server vs. built-in tools
- A **quality gate** for evaluating new servers before adding them
- An **available servers table** showing what is currently configured

### `.vscode/mcp.json`

This is where MCP servers are configured. It lives in your project's `.vscode/` directory and VS Code reads it automatically. The template includes a starter version with five official servers.

---

## Server tiers

### Always-on (enabled by default)

These servers provide core capabilities useful in every project:

| Server | What it does |
|--------|-------------|
| **filesystem** | Read and write files beyond the VS Code workspace boundary |
| **memory** | Persistent key-value store that survives across sessions |
| **git** | Git operations — history, diffs, branches, commit details |

### Credentials-required (disabled by default)

These need access tokens. They are pre-configured in `mcp.json` but set to `"disabled": true` until you provide credentials:

| Server | What it does | Required credential |
|--------|-------------|---------------------|
| **github** | GitHub API — issues, PRs, repos, Actions | `GITHUB_TOKEN` |
| **fetch** | HTTP fetch for web content and APIs | None (but rate limits may apply) |

To enable a credentials-required server:

1. Remove `"disabled": true` from the server entry in `.vscode/mcp.json`
2. Set the required environment variable (e.g., `export GITHUB_TOKEN=ghp_...`)
3. Restart VS Code

### Stack-specific (added during setup)

During Step 2.12 of setup, Copilot discovers your project's stack and suggests relevant MCP servers:

| Stack | Suggested server | Purpose |
|-------|-----------------|---------|
| PostgreSQL | `@modelcontextprotocol/server-postgres` | Query and explore database |
| SQLite | `mcp-server-sqlite` (via `uvx`) | Local database queries |
| Slack | `@modelcontextprotocol/server-slack` | Send messages, read channels |
| Google Drive | `@modelcontextprotocol/server-gdrive` | Search and read documents |
| Puppeteer | `@modelcontextprotocol/server-puppeteer` | Browser automation |

---

## Configuring `.vscode/mcp.json`

### Adding a new server

Add an entry to the `"servers"` object:

```json
{
  "my-server": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@scope/mcp-server-name"],
    "env": {
      "API_KEY": "${env:MY_SERVER_API_KEY}"
    }
  }
}
```

### Using input prompts for credentials

Instead of hardcoding credentials or relying on environment variables, you can use VS Code input prompts:

```json
{
  "inputs": [
    {
      "type": "promptString",
      "id": "my-api-key",
      "description": "API key for My Service",
      "password": true
    }
  ],
  "servers": {
    "my-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "my-mcp-server"],
      "env": {
        "API_KEY": "${input:my-api-key}"
      }
    }
  }
}
```

VS Code will prompt you for the value when the server starts.

### Disabling a server

Add `"disabled": true` to temporarily disable a server without removing its configuration:

```json
{
  "my-server": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "my-mcp-server"],
    "disabled": true
  }
}
```

---

## The MCP decision tree

Before reaching for an MCP server, Copilot follows this priority order:

1. **Built-in tools** — Copilot's native capabilities (file reading, code search, terminal commands)
2. **Configured MCP servers** — servers already in `.vscode/mcp.json`
3. **Search for existing servers** — official (modelcontextprotocol/servers), registries (mcp.so, glama.ai, smithery.ai), or stack-specific servers
4. **Build a custom server** — use the `mcp-builder` skill to create one from scratch

---

## Server quality gate

Before adding any new MCP server (especially from community sources), verify:

- **Publisher trust**: Verified publisher or ≥ 100 GitHub stars
- **Transport security**: stdio for local, HTTPS for remote
- **No hardcoded credentials**: Uses `${env:VAR}` or `${input:id}` references
- **Permissive license**: MIT, Apache 2.0, or similar
- **Tested**: Works with MCP Inspector before committing

---

## Building custom MCP servers

If no existing server meets your needs, the `mcp-builder` skill guides you through creating one:

1. Clarify what the server does and what tools it exposes
2. Choose the transport (stdio recommended for local)
3. Scaffold the server structure
4. Implement tool handlers
5. Test with MCP Inspector
6. Register in `.vscode/mcp.json`

See the `mcp-builder` skill in `.github/skills/mcp-builder/SKILL.md` for the complete workflow.

---

## Interaction with other sections

| Section | How MCP relates |
|---------|----------------|
| §11 — Tool Protocol | MCP servers are one option in the Tool decision tree (step 2 of SEARCH) |
| §12 — Skill Protocol | Skills like `mcp-builder` teach workflows for creating MCP servers |
| §9 — Subagent Protocol | Subagents inherit access to all configured MCP servers |
| §10 — Project Overrides | `{{MCP_STACK_SERVERS}}` and `{{MCP_CUSTOM_SERVERS}}` placeholders |

---

## Troubleshooting

**Server doesn't start**

- Check that the command exists (`npx`, `uvx`, `node`, etc.)
- Verify Node.js is installed and accessible from VS Code
- Check the VS Code Output panel → "MCP" channel for error messages

**Server starts but tools don't appear**

- Verify the server implements tools correctly (test with MCP Inspector)
- Check that the tool names don't conflict with built-in Copilot tools
- Restart VS Code after modifying `mcp.json`

**Credentials not working**

- Environment variables must be set before VS Code starts (or use `${input:id}` prompts)
- `${env:VAR}` reads from the VS Code process environment, not a shell profile
- Add env vars to your shell profile AND restart VS Code for them to take effect

---

## E22 — MCP servers preference

During Expert setup (E22), you choose how MCP is configured:

| Option | What happens |
|--------|-------------|
| **A — None** | No `.vscode/mcp.json` is created. MCP can be added later. |
| **B — Always-on only** (default) | filesystem, memory, git servers enabled. Credentials-required servers disabled. |
| **C — Full configuration** | All servers configured. Copilot asks about each credentials-required and stack-specific server. |
