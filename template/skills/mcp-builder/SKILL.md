---
name: mcp-builder
description: Create a new MCP server — clarify purpose, choose transport, scaffold, implement, test, and register
compatibility: ">=2.0"
---

# MCP Server Builder

> Skill metadata: version "1.2"; license MIT; tags [mcp, server, tool, integration, scaffold]; compatibility ">=2.0"; recommended tools [codebase, editFiles, runCommands].

Build a new MCP server: clarify purpose, choose transport, scaffold, implement tools/resources, test, and register in `.vscode/mcp.json`.

## When to activate

- User says "Build an MCP server", "Create an MCP server for ...", or "I need an MCP integration for ..."
- A task requires external data or capabilities not covered by existing MCP servers
- The §13 MCP decision tree reaches step 4 (BUILD)

## Workflow

### 1. Clarify purpose

Ask the user: what capability, what tools (1–5 with descriptions), what resources (if any), and what credentials (environment variables)?

### 2. Choose transport

| Transport | When to use | Trade-offs |
|-----------|------------|------------|
| **stdio** (default) | Local servers, same machine | Simplest, no network config, most secure |
| **SSE** | Remote/shared team servers | Requires HTTPS in production |
| **Streamable HTTP** | Latest MCP spec targets | Newest, best for stateless ops |

### 3. Scaffold the server

Choose language by project stack.

**TypeScript** (recommended):

```bash
mkdir -p .mcp-servers/<server-name> && cd .mcp-servers/<server-name>
npm init -y && npm install @modelcontextprotocol/sdk zod
npm install --save-dev tsx typescript @types/node
```

Entry point `src/index.ts`:

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({ name: "<server-name>", version: "1.0.0" });
// Tools registered in Step 4
const transport = new StdioServerTransport();
await server.connect(transport);
```

**Python**:

```bash
mkdir -p .mcp-servers/<server-name> && cd .mcp-servers/<server-name>
uv init && uv add mcp
```

### 4. Implement tools

For each tool: define input schema (Zod/Pydantic), implement handler, register:

```typescript
server.tool(
  "<tool-name>",
  "<one-sentence description>",
  { param: z.string().describe("what this parameter does") },
  async ({ param }) => {
    return { content: [{ type: "text", text: result }] };
  }
);
```

Rules: one tool = one action, validate all inputs with schemas, return structured content (text or JSON), handle errors gracefully (return error content, don't throw).

### 5. Test with MCP Inspector

```bash
npx @modelcontextprotocol/inspector tsx .mcp-servers/<server-name>/src/index.ts
```

Python: `npx @modelcontextprotocol/inspector python .mcp-servers/<server-name>/main.py`

Verify: server starts, all tools appear in inspector, each executes correctly with sample inputs, error cases return meaningful messages.

### 6. Add resources and prompts (optional)

| Capability | Purpose | VS Code access |
|------------|---------|---------------|
| **Resources** | Read-only data context (schemas, docs) | Chat → Add Context → MCP Resources |
| **Prompts** | Pre-configured prompt templates | `/<server>.<prompt>` in chat |
| **MCP Apps** | Interactive UI (forms, visualisations) | Inline in chat |

Add resources when the server has reference data. Add prompts for common task patterns. Consider MCP Apps (`@modelcontextprotocol/ext-apps` SDK) for interactive output.

### 7. Register in `.vscode/mcp.json`

```json
{
  "<server-name>": {
    "type": "stdio",
    "command": "npx",
    "args": ["tsx", ".mcp-servers/<server-name>/src/index.ts"],
    "env": { "API_KEY": "${env:SERVER_NAME_API_KEY}" }
  }
}
```

For production, compile TypeScript first (`npx tsc`) and reference compiled JS.

### 8. Document

Add the server to the **Available servers** table in `.github/skills/mcp-management/SKILL.md`. If reusable across projects, consider publishing to an MCP registry.

### 9. Distribute via plugin (optional)

Create `.mcp.json` at plugin root (uses `mcpServers` key, not `servers`):

```json
{
  "mcpServers": {
    "<server-name>": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/<server-name>",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
    }
  }
}
```

For Claude-format plugins, use `${CLAUDE_PLUGIN_ROOT}`. For OpenPlugin plugins, replace it with `${PLUGIN_ROOT}`. Copilot-format plugins do not currently document a plugin-root token in VS Code, so prefer Claude or OpenPlugin format when the server path must resolve inside the plugin directory. Plugin MCP servers start on enable and are implicitly trusted.

## Verify

- [ ] Server starts via stdio and responds to `initialize`
- [ ] All tools execute correctly in MCP Inspector
- [ ] `.vscode/mcp.json` is valid JSON with the new server entry
- [ ] §13 Available servers table updated
