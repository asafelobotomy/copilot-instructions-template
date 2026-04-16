# Research: VS Code Extension APIs for a Copilot Companion Extension

> Date: 2026-04-16 | Agent: Researcher | Status: complete

## Summary

This report covers the VS Code extension APIs needed to build `asafelobotomy.copilot-extension` — a companion extension that contributes Language Model tools, manages MCP servers programmatically, and integrates with VS Code profiles. Language Model (LM) tool registration via `vscode.lm.registerTool()` is **stable** (^1.100.0). MCP server definition provider registration via `vscode.lm.registerMcpServerDefinitionProvider()` is currently a **proposed API** (^1.101.0, requires `@vscode/dts`). Profile detection and switching has **no public extension API** — profile state is purely user-facing. Extension scaffolding uses `yo code` / `generator-code`, and VSIX packaging works via `@vscode/vsce`.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://code.visualstudio.com/api/extension-guides/ai/ai-extensibility-overview> | LM tool vs MCP tool vs chat participant decision guide |
| <https://code.visualstudio.com/api/extension-guides/tools> | Full LM tool implementation guide (stable API) |
| <https://code.visualstudio.com/api/extension-guides/ai/mcp> | MCP server extension guide (proposed API) |
| <https://code.visualstudio.com/api/get-started/your-first-extension> | Extension scaffolding walkthrough |
| <https://code.visualstudio.com/api/working-with-extensions/publishing-extension> | VSIX packaging and Marketplace publishing |
| <https://raw.githubusercontent.com/microsoft/vscode-extension-samples/main/mcp-extension-sample/package.json> | Real-world `mcpServerDefinitionProviders` contribution point example |
| <https://raw.githubusercontent.com/microsoft/vscode-extension-samples/main/chat-sample/package.json> | Real-world `languageModelTools` contribution point example |
| <https://raw.githubusercontent.com/microsoft/vscode-extension-samples/main/mcp-extension-sample/src/extension.ts> | Working implementation of `registerMcpServerDefinitionProvider` |
| <https://code.visualstudio.com/docs/configure/profiles> | VS Code Profiles user-facing feature documentation |

---

## Findings

### 1. Language Model Tools — `vscode.lm.registerTool()`

**Status: Stable** (VS Code ≥ 1.100.0, April 2025)

#### package.json contribution point

```json
"contributes": {
  "languageModelTools": [
    {
      "name": "asafelobotomy_myTool",
      "tags": ["my-domain", "asafelobotomy"],
      "toolReferenceName": "myTool",
      "displayName": "My Tool",
      "userDescription": "Human-readable description shown in the tools picker.",
      "modelDescription": "Detailed description for the LLM: what the tool does, when to use it, its return format, and limitations.",
      "canBeReferencedInPrompt": true,
      "icon": "$(tools)",
      "when": "someContextKey == 'value'",
      "inputSchema": {
        "type": "object",
        "properties": {
          "targetPath": {
            "type": "string",
            "description": "Absolute path to the file to analyse."
          }
        },
        "required": ["targetPath"]
      }
    }
  ]
}
```

#### TypeScript registration (extension.ts activate)

```typescript
import * as vscode from 'vscode';

interface IMyToolInput {
  targetPath: string;
}

class MyTool implements vscode.LanguageModelTool<IMyToolInput> {

  async prepareInvocation(
    options: vscode.LanguageModelToolInvocationPrepareOptions<IMyToolInput>,
    _token: vscode.CancellationToken
  ): Promise<vscode.PreparedToolInvocation | undefined> {
    return {
      invocationMessage: `Analysing ${options.input.targetPath}`,
      confirmationMessages: {
        title: 'Run My Tool',
        message: new vscode.MarkdownString(
          `Analyse \`${options.input.targetPath}\`?`
        )
      }
    };
  }

  async invoke(
    options: vscode.LanguageModelToolInvocationOptions<IMyToolInput>,
    token: vscode.CancellationToken
  ): Promise<vscode.LanguageModelToolResult> {
    const { targetPath } = options.input;
    // ... do work ...
    return new vscode.LanguageModelToolResult([
      new vscode.LanguageModelTextPart(`Result for ${targetPath}`)
    ]);
  }
}

export function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(
    vscode.lm.registerTool('asafelobotomy_myTool', new MyTool())
  );
}
```

#### How tools appear to Copilot agents

- Tools from extensions appear in the **tools picker** in agent mode alongside built-in tools and MCP tools.
- Users can enable/disable individual tools via the picker.
- Tools can be `#`-referenced explicitly in a prompt when `canBeReferencedInPrompt: true`.
- A confirmation dialog is always shown (unless `readOnlyHint` annotation is used — but that's MCP-only). Extensions can customise the message via `prepareInvocation`, or return `undefined` to get the generic dialog.
- Users can choose **Always Allow** per tool.

#### Key interface shape

```typescript
interface LanguageModelTool<T> {
  invoke(
    options: LanguageModelToolInvocationOptions<T>,
    token: CancellationToken
  ): ProviderResult<LanguageModelToolResult>;

  prepareInvocation?(
    options: LanguageModelToolInvocationPrepareOptions<T>,
    token: CancellationToken
  ): ProviderResult<PreparedToolInvocation>;
}

class LanguageModelToolResult {
  constructor(content: (LanguageModelTextPart | LanguageModelPromptTsxPart)[]);
}
```

#### Gotchas

- Tool names must follow the `{verb}_{noun}` format (e.g. `get_weather`, `find_files`). Including a publisher prefix is recommended to avoid collision: `asafelobotomy_get_weather`.
- `modelDescription` is the most important field — write it as if instructing the LLM. Be specific about format of the return value and when NOT to use the tool.
- File paths in `inputSchema` should be described as absolute paths.
- Throw errors with LLM-meaningful messages; optionally include retry instructions.
- The URL `https://code.visualstudio.com/api/extension-guides/language-model-tool-calling` returns **404** as of 2026-04-16. The correct current URL is `https://code.visualstudio.com/api/extension-guides/tools`.

---

### 2. MCP Server Management — `vscode.lm.registerMcpServerDefinitionProvider()`

**Status: Proposed API** (VS Code ≥ 1.101.0, requires `@vscode/dts` download at dev time)

The `mcp-extension-sample` explicitly states "You can use proposed API here" and downloads type definitions via `dts dev` / `dts main`. This API is not yet available via the stable `@types/vscode` package.

#### package.json contribution point

```json
"engines": { "vscode": "^1.101.0" },
"contributes": {
  "mcpServerDefinitionProviders": [
    {
      "id": "asafelobotomyMcp",
      "label": "aSafeLobotomy MCP Servers"
    }
  ]
}
```

#### TypeScript registration

```typescript
import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
  const didChangeEmitter = new vscode.EventEmitter<void>();

  context.subscriptions.push(
    vscode.lm.registerMcpServerDefinitionProvider('asafelobotomyMcp', {
      onDidChangeMcpServerDefinitions: didChangeEmitter.event,

      provideMcpServerDefinitions: async (): Promise<vscode.McpServerDefinition[]> => {
        return [
          // stdio (local process) server
          new vscode.McpStdioServerDefinition({
            label: 'my-local-server',
            command: 'node',
            args: ['path/to/server.js'],
            cwd: vscode.Uri.file('/absolute/path'),
            env: { API_KEY: '' },
            version: '1.0.0'
          }),
          // HTTP (remote / streamable HTTP) server
          new vscode.McpHttpServerDefinition({
            label: 'my-remote-server',
            uri: 'https://my-service.example.com/mcp',
            headers: { 'X-API-Version': '1.0' },
            version: '1.0.0'
          })
        ];
      },

      resolveMcpServerDefinition: async (
        server: vscode.McpServerDefinition
      ): Promise<vscode.McpServerDefinition | undefined> => {
        if (server.label === 'my-local-server') {
          // Prompt for secrets or perform auth here
          const key = await vscode.window.showInputBox({ prompt: 'Enter API key', password: true });
          if (!key) return undefined; // cancels tool call with error to LLM
          (server as vscode.McpStdioServerDefinition).env = { API_KEY: key };
        }
        return server;
      }
    })
  );
}
```

#### MCP server health monitoring — No programmatic API

There is **no public API** for monitoring MCP server health, querying server status, or receiving health events from VS Code. What is available:

- VS Code shows error indicators in the Chat view when a server fails.
- Users can check server status via **MCP: List Servers** in the Command Palette.
- Server logs are visible via **Show Output** on the error notification or **MCP: List Servers** → **Show Output**.
- The `dev.watch` property in `.vscode/mcp.json` triggers auto-restart on file changes (dev mode only, not settable via the provider API).
- Firing `didChangeEmitter.fire()` causes VS Code to call `provideMcpServerDefinitions` again, which effectively triggers a server restart for changed definitions.

#### Programmatic restart — indirect only

There is no `restart()` method. The closest equivalent is firing `onDidChangeMcpServerDefinitions`, which causes VS Code to re-resolve the server list. If the definition changes, the running server will be stopped and restarted.

#### McpServerDefinition interface shape

```typescript
// Stdio (local process)
class McpStdioServerDefinition {
  label: string;
  command: string;
  args?: string[];
  cwd?: vscode.Uri;
  env?: Record<string, string>;
  version?: string;
}

// HTTP (remote)
class McpHttpServerDefinition {
  label: string;
  uri: string;
  headers?: Record<string, string>;
  version?: string;
}

type McpServerDefinition = McpStdioServerDefinition | McpHttpServerDefinition;
```

#### Gotchas

- This is a **proposed API** as of 2026-04-16. You must use `@vscode/dts` to download the `.d.ts` at dev time and set `enableProposedApi: ["mcpServerDefinitionProvider"]` in `package.json` (or equivalent enablement flag).
- Extensions using proposed APIs **cannot be published to the VS Code Marketplace** without Microsoft approval. VSIX-only distribution (GitHub Releases) is the correct distribution path until this API graduates.
- Returning `undefined` from `resolveMcpServerDefinition` cancels any pending tool call and returns an error message to the LLM.
- The constructor signature in the current sample uses positional args (`label, command, args, env`), but the doc snippet shows an object argument. Verify against the downloaded `.d.ts` version.

---

### 3. Profile Management

**Status: No public extension API**

VS Code profiles are a user-facing feature (Settings, Extensions, Keyboard Shortcuts, etc.). There is no public `vscode.env` property for the current profile name, and no API to list, create, switch, or delete profiles.

What IS available via `vscode.env`:

```typescript
vscode.env.appName          // e.g. "Visual Studio Code - Insiders"
vscode.env.appRoot          // installation directory
vscode.env.language         // display language e.g. "en"
vscode.env.machineId        // stable anonymised machine ID
vscode.env.sessionId        // unique per session
vscode.env.uriScheme        // "vscode" or "vscode-insiders"
```

None of these expose profile information. The only public mechanism is `vscode.workspace.getConfiguration()`, which reads settings respecting the active profile's settings layer — but the profile name itself is not exposed.

**Workaround**: Store a custom setting in each profile (e.g. `asafelobotomy.profileHint`) and read that setting at runtime to infer context. This is brittle and requires user configuration.

**Profile switching**: No API. Users must use the Profiles editor or the Manage button in the Activity Bar.

---

### 4. Extension Scaffolding

#### Generator

```bash
# One-shot (no global install required)
npx --package yo --package generator-code -- yo code

# Or install globally
npm install --global yo generator-code
yo code
```

Answer the prompts for a TypeScript extension:

```
? What type of extension?      New Extension (TypeScript)
? Extension name?              copilot-extension
? Identifier?                  copilot-extension
? Description?                 aSafeLobotomy Copilot Extension
? Initialize git repository?   Y
? Bundler?                     esbuild   (recommended for production)
? Package manager?             npm
```

#### Generated structure

```
copilot-extension/
├── .vscode/
│   └── launch.json          # F5 debug config
├── src/
│   └── extension.ts         # activate() / deactivate()
├── package.json
├── tsconfig.json
└── .vscodeignore
```

#### Minimal package.json for this extension

```json
{
  "name": "copilot-extension",
  "displayName": "aSafeLobotomy's Copilot Extension",
  "description": "Copilot companion tools and MCP server management",
  "version": "0.1.0",
  "publisher": "asafelobotomy",
  "engines": { "vscode": "^1.101.0" },
  "categories": ["AI", "Chat"],
  "activationEvents": [],
  "main": "./out/extension.js",
  "contributes": {
    "languageModelTools": [
      {
        "name": "asafelobotomy_myTool",
        "toolReferenceName": "myTool",
        "displayName": "My Tool",
        "userDescription": "Short description for users.",
        "modelDescription": "Detailed description for the LLM.",
        "canBeReferencedInPrompt": true,
        "inputSchema": { "type": "object", "properties": {} }
      }
    ],
    "mcpServerDefinitionProviders": [
      {
        "id": "asafelobotomyMcp",
        "label": "aSafeLobotomy MCP Servers"
      }
    ]
  },
  "scripts": {
    "compile": "tsc -p ./",
    "watch": "tsc -watch -p ./",
    "vscode:prepublish": "npm run compile",
    "download-api": "dts dev",
    "postdownload-api": "dts main",
    "postinstall": "npm run download-api"
  },
  "devDependencies": {
    "@types/vscode": "^1.101.0",
    "@vscode/dts": "^0.4.1",
    "typescript": "^5.9.2"
  }
}
```

> Note: `@vscode/dts` is required to download proposed API definitions for `registerMcpServerDefinitionProvider`. Remove it (and the download scripts) if you are only using stable LM tool APIs.

---

### 5. Extension Packaging and Distribution

#### VSIX packaging

```bash
npm install -g @vscode/vsce
cd copilot-extension
vsce package
# Produces: asafelobotomy-copilot-extension-0.1.0.vsix
```

Users install a VSIX with:

```bash
code --install-extension asafelobotomy-copilot-extension-0.1.0.vsix
```

Or via VS Code UI: Extensions view → `...` menu → **Install from VSIX…**

#### Marketplace publishing

```bash
vsce login asafelobotomy   # prompts for Azure DevOps PAT
vsce publish
```

Requirements:
- Azure DevOps account + Personal Access Token with **Marketplace → Manage** scope
- `publisher` field in `package.json` must match the registered publisher ID
- No SVG icons; no HTTP image URLs in README/CHANGELOG

**Constraint**: Extensions using proposed APIs cannot be published to the Marketplace without Microsoft enablement. Until `registerMcpServerDefinitionProvider` graduates to stable, VSIX-only is mandatory.

#### GitHub Releases distribution (recommended for proposed-API extensions)

```yaml
# .github/workflows/release.yml
on:
  push:
    tags: ['v*']
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npx @vscode/vsce package
      - uses: softprops/action-gh-release@v2
        with:
          files: '*.vsix'
```

Users download the `.vsix` from the GitHub Release page and install manually.

---

## Recommended Extension Architecture

```
src/
├── extension.ts            # activate(): registers tools + MCP provider
├── tools/
│   ├── index.ts            # registers all tools via context.subscriptions.push(...)
│   └── myTool.ts           # implements LanguageModelTool<IMyToolInput>
└── mcp/
    ├── index.ts            # registerMcpServerDefinitionProvider(...)
    └── provider.ts         # McpServerDefinitionProvider implementation
```

**Key architectural decisions:**

1. Keep LM tools and MCP provider registration separate modules — they serve different purposes and have different API stability levels.
2. Use `EventEmitter<void>` in the MCP provider and expose a `triggerRefresh()` method; call it whenever server configuration changes (settings change listener, command handler, etc.).
3. Store MCP server configs in `vscode.workspace.getConfiguration('asafelobotomy')` or `context.globalState` for portability across profiles.
4. For LM tools: register all tools in `activate()` unconditionally; use `when` clauses in `package.json` to control availability rather than conditional registration code.
5. Set `engines.vscode` to the minimum required by the most advanced API used. Since `registerMcpServerDefinitionProvider` requires `^1.101.0`, use that as the floor.

---

## API Availability Summary

| Capability | API | Status | Min VS Code |
|---|---|---|---|
| Register LM tools | `vscode.lm.registerTool()` | **Stable** | 1.100.0 |
| Declare LM tools | `contributes.languageModelTools` | **Stable** | 1.100.0 |
| Register MCP server provider | `vscode.lm.registerMcpServerDefinitionProvider()` | **Proposed** | 1.101.0 |
| Declare MCP provider | `contributes.mcpServerDefinitionProviders` | **Proposed** | 1.101.0 |
| MCP server health events | — | **Not available** | — |
| MCP server programmatic restart | — | **Not available** (indirect via event) | — |
| Detect active profile name | — | **Not available** | — |
| Switch profiles | — | **Not available** | — |
| Read profile-scoped settings | `vscode.workspace.getConfiguration()` | **Stable** | 1.0.0 |

---

## Gaps / Further Research Needed

1. **Proposed API graduation timeline** — `registerMcpServerDefinitionProvider` was introduced in 1.101.0. Check VS Code release notes for 1.115+ to see if it has graduated to stable.
2. **`enableProposedApi` field** — confirm the exact field name/value required in `package.json` to enable the MCP provider proposed API. The sample does not include it; check the VS Code [proposed API docs](https://code.visualstudio.com/api/advanced-topics/using-proposed-api).
3. **`@vscode/chat-extension-utils`** — the chat-sample depends on this package. Review it for utility helpers when implementing LM tools that interact with chat.
4. **MCP server restart command** — verify whether `workbench.action.mcp.restartServer` or similar internal commands are accessible via `vscode.commands.executeCommand` as an undocumented restart mechanism.
5. **Profile API proposals** — search the VS Code repo for any open proposals around profile extension APIs (`vscode.profile.*`).
