---
name: mcp-builder
description: Create a new MCP server — clarify purpose, choose transport, scaffold, implement, test, and register
version: "1.0"
license: MIT
tags: [mcp, server, tool, integration, scaffold]
compatibility: ">=2.0"
allowed-tools: [codebase, editFiles, terminal, runCommands]
---

# MCP Server Builder

Build a new Model Context Protocol (MCP) server from scratch. This skill walks through the full lifecycle: clarifying the server's purpose, choosing transport, scaffolding, implementing tools/resources, testing, and registering the server in `.vscode/mcp.json`.

## When to activate

- User says "Build an MCP server", "Create an MCP server for ...", or "I need an MCP integration for ..."
- A task requires external data or capabilities not covered by existing MCP servers
- The §13 MCP decision tree reaches step 4 (BUILD)

## Workflow

### 1. Clarify purpose

Ask the user:

- **What capability** does this server provide? (e.g., "query our Postgres database", "fetch Jira tickets", "interact with Slack")
- **What tools** should it expose? (list 1–5 tool names with one-sentence descriptions)
- **What resources** should it expose, if any? (e.g., database schemas, API documentation)
- **Does it need credentials?** If yes, which environment variables?

### 2. Choose transport

| Transport | When to use | Trade-offs |
|-----------|------------|------------|
| **stdio** (recommended) | Local servers, same machine as VS Code | Simplest setup, no network config, most secure |
| **SSE** | Remote servers, shared team servers | Requires HTTPS in production, more complex deployment |
| **Streamable HTTP** | New servers targeting latest MCP spec | Newest transport, best for stateless operations |

Default to **stdio** unless the user has a specific reason for a remote transport.

### 3. Scaffold the server

Choose the implementation language based on the project's primary stack:

**TypeScript/JavaScript** (recommended for most projects):

```bash
mkdir -p .mcp-servers/<server-name>
cd .mcp-servers/<server-name>
npm init -y
npm install @modelcontextprotocol/sdk zod
```

Create the entry point (`src/index.ts` or `index.js`):

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({
  name: "<server-name>",
  version: "1.0.0",
});

// Tools are registered here (Step 4)

const transport = new StdioServerTransport();
await server.connect(transport);
```

**Python** (alternative):

```bash
mkdir -p .mcp-servers/<server-name>
cd .mcp-servers/<server-name>
uv init && uv add mcp
```

### 4. Implement tools

For each tool identified in Step 1:

1. Define the input schema using Zod (TypeScript) or Pydantic (Python)
2. Implement the handler function
3. Register with the server:

```typescript
server.tool(
  "<tool-name>",
  "<one-sentence description>",
  { param: z.string().describe("what this parameter does") },
  async ({ param }) => {
    // Implementation
    return { content: [{ type: "text", text: result }] };
  }
);
```

Rules:
- One tool, one action — keep tools focused
- Validate all inputs with schemas
- Return structured content (text or JSON)
- Handle errors gracefully — return error content, don't throw

### 5. Test with MCP Inspector

```bash
npx @modelcontextprotocol/inspector node .mcp-servers/<server-name>/src/index.ts
```

Verify:
- [ ] Server starts without errors
- [ ] Each tool appears in the inspector's tool list
- [ ] Each tool executes correctly with sample inputs
- [ ] Error cases return meaningful messages

### 6. Register in `.vscode/mcp.json`

Add the server to the project's MCP configuration:

```json
{
  "<server-name>": {
    "type": "stdio",
    "command": "node",
    "args": [".mcp-servers/<server-name>/src/index.ts"],
    "env": {
      "API_KEY": "${env:SERVER_NAME_API_KEY}"
    }
  }
}
```

### 7. Document

- Add the server to the §13 Available servers table in `.github/copilot-instructions.md`
- Log in JOURNAL.md: `[mcp] <server-name> server created — <one-line reason>`
- If the server is reusable across projects, consider publishing to an MCP registry

## Verify

- [ ] Server starts via stdio and responds to `initialize` request
- [ ] All tools execute correctly in MCP Inspector
- [ ] `.vscode/mcp.json` is valid JSON with the new server entry
- [ ] §13 Available servers table is updated
- [ ] JOURNAL.md has an entry
