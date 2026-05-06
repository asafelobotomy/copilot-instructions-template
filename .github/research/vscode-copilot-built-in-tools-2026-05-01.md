# Research: VS Code Copilot Built-in Agent Tools

> Date: 2026-05-01 | Agent: Researcher | Status: complete

## Summary

As of VS Code v1.114 (April 2026), the GitHub Copilot Chat extension ships
37+ built-in tools organized into seven tool sets plus several standalone tools.
Tools use a hierarchical `toolset/tool` namespace (e.g. `#edit/editFiles`,
`#execute/runInTerminal`), though legacy flat names (`editFiles`, `runCommands`,
`codebase`) still work in agent frontmatter `tools:` fields. All built-in tools
are owned by the GitHub Copilot Chat extension (`GitHub.copilot-chat`); they
are not VS Code core. Extension-contributed tools use the Language Model Tools
API. MCP tools are a third, separate category. The key finding relevant to this
repo: the legacy `runTests` tool **no longer exists** as an execution tool —
its replacement `#execute/testFailure` is **read-only** (gets failure info from
an installed Test Controller extension). This confirms why `mcp_heartbeat_run_tests`
was the right superseding design. Five further tools are strong MCP candidates.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://code.visualstudio.com/docs/copilot/reference/copilot-vscode-features#_chat-tools | Canonical built-in tool table (v1.114) |
| https://code.visualstudio.com/docs/copilot/agents/agent-tools | Tool approval flow, terminal sandboxing, permission levels |
| https://code.visualstudio.com/docs/copilot/customization/custom-agents | Agent frontmatter schema, tool list semantics |
| https://code.visualstudio.com/docs/copilot/concepts/tools | Tool type taxonomy: built-in vs extension vs MCP |
| https://code.visualstudio.com/docs/copilot/reference/workspace-context | `#codebase` semantic-only change (v1.114) |
| https://code.visualstudio.com/api/extension-guides/ai/ai-extensibility-overview | Extension tool registration options |
| https://code.visualstudio.com/api/extension-guides/ai/tools | Language Model Tools API: `vscode.lm.registerTool()` |
| https://code.visualstudio.com/updates/v1_114 | Release notes: codebase simplification, fine-grained tool approval API |

---

## Findings

### 1. Complete built-in tool table (v1.114, 2026-04-01)

All tools are contributed by the `GitHub.copilot-chat` extension (not VS Code
core). They are available without any additional setup. Source:
https://code.visualstudio.com/docs/copilot/reference/copilot-vscode-features#_chat-tools

#### Tool Sets (groupings of related individual tools)

| Tool Set | Frontmatter shorthand | Purpose | Individual tools |
|----------|-----------------------|---------|-----------------|
| `#agent` | `agent` | Delegate to subagents | `runSubagent` |
| `#browser` | *(no shorthand; experimental)* | Integrated browser interaction | navigate, screenshot, click, type, hover, drag, dialogs |
| `#edit` | `editFiles` | Workspace file mutations | `createDirectory`, `createFile`, `editFiles`, `editNotebook` |
| `#execute` | `runCommands` | Execute code and commands | `createAndRunTask`, `getTerminalOutput`, `runInTerminal`, `runNotebookCell`, `testFailure` |
| `#read` | *(part of `search`)* | Read workspace files/state | `getNotebookSummary`, `problems`, `readFile`, `readNotebookCellOutput`, `terminalLastCommand`, `terminalSelection` |
| `#search` | `search` / `codebase` | Search workspace | `changes`, `codebase`, `fileSearch`, `listDirectory`, `textSearch`, `usages` |
| `#web` | `fetch` | Fetch web content | `fetch` |

#### Standalone tools

| Tool | Frontmatter name | Purpose | Requirements |
|------|-----------------|---------|--------------|
| `#githubRepo` | `githubRepo` | Semantic search a GitHub repo by `owner/repo` | GitHub auth |
| `#githubTextSearch` | *(none listed)* | Text/keyword search GitHub repo or org | GitHub auth |
| `#newWorkspace` | *(none listed)* | Scaffold a new workspace | — |
| `#selection` | *(context variable)* | Current editor text selection | Text must be selected |
| `#todos` | *(none listed)* | Track task progress via a todo list | — |
| `#vscode/askQuestions` | `askQuestions` | Interactive clarifying-question carousel | — |
| `#vscode/extensions` | *(none listed)* | Search and ask about VS Code extensions | — |
| `#vscode/getProjectSetupInfo` | *(none listed)* | Project scaffolding instructions | — |
| `#vscode/installExtension` | *(none listed)* | Install a VS Code extension | — |
| `#vscode/runCommand` | *(none listed)* | Run any VS Code command | — |
| `#vscode/VSCodeAPI` | *(none listed)* | VS Code extension API documentation | — |

#### Legacy ↔ current name mapping (for agent frontmatter)

Old `tools:` list names still accepted in `.agent.md` frontmatter. The mapping:

| Legacy name | Maps to | Notes |
|-------------|---------|-------|
| `editFiles` | `#edit` tool set | Includes create/edit/notebook |
| `runCommands` | `#execute` tool set | Includes terminal, tasks, notebook cells, testFailure |
| `codebase` | `#search/codebase` | Semantic search only (changed v1.114) |
| `search` | `#search` tool set | All search subtypes |
| `fetch` | `#web/fetch` | Single URL fetch |
| `githubRepo` | `#githubRepo` | Semantic GitHub repo search |
| `askQuestions` | `#vscode/askQuestions` | Question carousel |
| `agent` | `#agent` tool set | Subagent delegation |
| `runTests` | **REMOVED** | No direct equivalent. `#execute/testFailure` reads failure info only; test execution requires `createAndRunTask` or `runInTerminal` plus a Test Controller extension |

---

### 2. Tool ownership by layer

| Tier | Owner | Registration mechanism | Examples |
|------|-------|----------------------|---------|
| **Built-in** | `GitHub.copilot-chat` extension | Internal (not public API) | All tools above |
| **Extension-contributed** | Any VS Code extension | `vscode.lm.registerTool()` (Language Model Tools API) | `ms-vscode.vscode-websearchforcopilot` |
| **MCP-contributed** | External MCP server (local or remote) | `.vscode/mcp.json` / `settings.json` `mcp` key | `mcp_heartbeat_*`, `mcp_filesystem_*` |

**Key detail**: Built-in tools have access to VS Code extension APIs and run in
the extension host process. MCP tools run *outside* VS Code and have **no access
to VS Code extension APIs**. Extension-contributed tools are the only non-built-in
tier that gets VS Code API access — but require shipping as a Marketplace extension.

---

### 3. Per-tool limitations and gating conditions

#### `#execute/runInTerminal` (legacy: `runCommands`)

- **Approval required** by default for each invocation; bypass needs session permission change or global `chat.tools.global.autoApprove`
- **Shell restriction**: agent uses configured default shell, but `cmd` (Windows) and `sh` (macOS/Linux) are unsupported — no shell integration, so agent relies on timeouts/idle detection, producing slow/flaky behavior
- **Sandboxing** (`chat.agent.sandbox.enabled`): when enabled, network access is **fully blocked** for terminal commands; filesystem restricted to workspace + CWD subtree (no home dir); commands auto-approved but tightly contained
- **Auto-approve bypass risk**: tree-sitter grammar extraction is bypassable via quote concatenation (e.g. `find -e"x"ec` bypasses blocked `find -exec`); zsh/fish not supported (bash grammar used)
- **Timeout**: model can specify a timeout; behavior controlled by `chat.tools.terminal.enforceTimeoutFromModel`; long-running commands have a "Continue in Background" escape hatch
- **Output location**: configurable — inline in chat or in integrated terminal (`chat.tools.terminal.outputLocation`)
- **Max 128 tools** per request limit (shared across all enabled tools)

#### `#execute/testFailure` (legacy: `runTests` — effectively removed)

- **Read-only**: gets test failure *information* from an installed Test Controller extension; does NOT execute tests
- **Requires Test Controller extension**: only provides data if a Test Controller (e.g. Python Test, Jest runner) is installed and has already run tests
- **No test execution**: this tool cannot trigger a test run; test execution requires `createAndRunTask` or `runInTerminal` instead
- **This confirms** why `mcp_heartbeat_run_tests` was built and is preferred — it provides structured test execution AND output capture in one call

#### `#search/codebase` (legacy: `codebase`)

- **Purely semantic** as of v1.114 — no more fuzzy fallback
- **Index required**: GitHub.com/Azure DevOps repos get a remote index (often instant); other workspaces build a local index (initial build takes minutes)
- **Automatic**: agents use it automatically when semantic search makes sense; explicit `#codebase` forces semantic search
- **Not for exact text**: text/regex search is `#search/textSearch`; `#codebase` is meaning-based only
- **Index gaps**: very large codebases without a GitHub repo may not be indexable yet (v1.114 note: "slowly rolling out support")
- **Scope**: only indexes the open workspace, excluding `.gitignore`d files and those in `files.exclude`

#### `#web/fetch` (legacy: `fetch`)

- **Two-step URL approval**: pre-approval (trust the domain) + post-approval (review fetched content before adding to context). Post-approval is *not* linked to Trusted Domains — always requires review by default
- **Single URL per call**: no batching; each page requires a separate call
- **No JS execution**: fetches raw HTML/Markdown, not a full browser render; can't access SPA content that requires JavaScript
- **Sandbox blocks it**: when `chat.agent.sandbox.enabled` is true, network access is blocked entirely for terminal tools (separate from fetch tool's own network filter)
- **Network filter**: `chat.agent.networkFilter` + allow/deny lists can restrict domains globally
- **Auto-approval**: `chat.tools.urls.autoApprove` allows domain-level pre/post approval bypass

#### `#edit/editFiles` (legacy: `editFiles`)

- **Diff-apply model**: edits are presented as diffs for user review; the user can accept/reject
- **Sensitive file protection**: users can mark files as sensitive to require approval; `.gitignore`d and `files.exclude` files are accessible (`.gitignore` bypass if file is open)
- **No atomic rename**: create+write+delete are separate operations, not atomic
- **Edit tool confirmation**: hooks (`post-edit-lint`) can run after edits

#### `#githubRepo` / `#githubTextSearch`

- **GitHub auth required**: needs GitHub account sign-in
- **Read-only**: no write capabilities; semantic or text search only
- **Remote-only**: searches GitHub.com (or GHEC) repos, not local filesystem
- **`#githubRepo`**: semantic search (meaning-based) — good for finding patterns
- **`#githubTextSearch`**: exact keyword/pattern search across a repo or org

#### `#browser` tool set (experimental)

- **Experimental**: requires `workbench.browser.enableChatTools` setting (org-managed)
- **Integrated browser only**: uses VS Code's built-in browser, not a real browser with full JS engine
- **Capabilities**: navigate, read page content, take screenshots, click, type, hover, drag, handle dialogs
- **Organization policy**: can be disabled by org admins

#### `#vscode/askQuestions`

- **Autopilot mode auto-responds**: in Autopilot permission level, the agent auto-responds to clarifying questions without waiting for user, so this tool becomes a no-op for interaction
- **Interactive question carousel**: best in Default/Bypass Approvals mode

#### `#agent/runSubagent` (via `agent` tool set)

- **Isolated context**: runs in a fresh context window, preventing context bloat in main thread
- **Max depth 3** (documented in `.github/copilot-instructions.md` as repo convention)
- **Agent allow-list**: `agents:` frontmatter field hard-limits which subagents can be delegated to

---

### 4. MCP supersession candidates — ranked

The following built-in tools have limitations that custom MCP tools can
meaningfully supersede. Ranked by impact for this repo:

#### Rank 1: `#execute/runInTerminal` + `#execute/getTerminalOutput` → MCP structured command runner

**Already partially superseded** by `mcp_heartbeat_run_tests` for tests.
A general-purpose MCP command executor could provide:
- Pre-approved command categories (no approval theater)
- Structured JSON output (stdout/stderr/exit code separately)
- Built-in timeout with graceful fallback
- CWD control without shell trust issues
- Works in sandbox (MCP server runs outside the sandbox)

**Design**: `mcp_run_command(command, args, cwd, timeout_ms)` → `{stdout, stderr, exit_code, timed_out}`

**Limitation vs built-in**: MCP tools can't access VS Code APIs, so they can't use the integrated terminal UI or shell integration events. But for automation tasks (CI checks, linters, formatters) this is not needed.

#### Rank 2: `#web/fetch` → MCP pre-approved fetch + search

**Current superseding**: `mcp_fetch_fetch` (already configured) provides the same capability but outside the VS Code approval flow. When domains are pre-trusted in MCP config, no per-URL approval is needed.

**Gap**: A structured MCP fetch tool could additionally:
- Cache responses for the session (avoid re-fetching)
- Strip/extract specific content (markdown, code blocks, JSON)
- Handle redirects and pagination automatically

**Design**: `mcp_fetch_with_cache(url, extract_mode)` → `{content, status, cached}`

#### Rank 3: `#read/readFile` + `#search/listDirectory` → MCP filesystem

**Already superseded** by `mcp_filesystem_*` (configured in `.vscode/mcp.json`).
The MCP filesystem server provides:
- Batched multi-file reads
- Access to paths outside the workspace (home dir, system paths)
- Atomic create+write operations
- Directory tree traversal

**Remaining gap**: `mcp_filesystem` requires path to be in allowed roots. VS Code
`#read/readFile` respects workspace semantics (relative paths, workspace folder
resolution). Neither is strictly superior — complement each other.

#### Rank 4: `#search/codebase` → MCP semantic or hybrid search

**Gap**: `#search/codebase` is purely semantic as of v1.114. For exact text/regex
searches across large repos where the semantic index may be stale or absent, an
MCP text search tool could provide:
- Ripgrep-backed exact search without indexing delay
- Regex with full PCRE2 support (VS Code uses fixed grammars)
- Configurable include/exclude patterns
- Sorted results by relevance signal (file age, match density)

**Design**: `mcp_grep_search(pattern, is_regex, include_glob, max_results)` → `{matches: [{file, line, content}]}`

**Note**: `mcp_filesystem_*` already provides some search. A dedicated grep-wrapper MCP would be tighter.

#### Rank 5: `#execute/testFailure` → `mcp_heartbeat_run_tests` (already done)

`mcp_heartbeat_run_tests` fully supersedes the read-only `#execute/testFailure`
by providing actual test execution with structured output. No further work needed
here — this was the right design decision.

---

### 5. Extension-contributed tools vs MCP tools: decision matrix

From https://code.visualstudio.com/api/extension-guides/ai/ai-extensibility-overview:

| Criterion | Extension tool | MCP tool |
|-----------|---------------|----------|
| VS Code API access | Yes (runs in extension host) | No (runs outside VS Code) |
| Distribution | VS Code Marketplace | Manual install / plugin delivery |
| Cross-editor reuse | VS Code only | Any MCP client |
| Remote hosting | Yes (client-server) | Yes (stdio or HTTP) |
| Local-only | Yes | Yes (stdio) |
| Install UX | One-click (Marketplace) | Config file + server binary |
| Right for this repo | MCP preferred (no Marketplace dependency) | Primary choice |

For this repo's use case (developer workflow automation without Marketplace
dependency), MCP is the correct tier for all new tools. Extension-contributed
tools are only worth pursuing if VS Code API access is strictly required (e.g.
debug context, Test Controller integration).

---

### 6. VS Code tool registration API surface

For completeness — the public API for contributing extension tools:

**Language Model Tools API** (`vscode.lm`):
- `vscode.lm.registerTool(name, impl)` — register a tool in the extension host
- `package.json`: `contributes.languageModelTools[]` — static tool metadata
  - `name` (format: `verb_noun`), `displayName`, `canBeReferencedInPrompt`
  - `toolReferenceName` — the `#name` used in chat
  - `modelDescription` — what the LLM sees (critical for correct invocation)
  - `inputSchema` — JSON Schema for inputs
  - `when` — condition clause for tool availability
- New in v1.114: **Fine-grained tool approval** — tools can now scope approval
  to a specific argument combination (e.g. `runVSCodeCommand` can require
  separate approval for each distinct command ID, not just the tool)

**MCP registration** (`.vscode/mcp.json` or `settings.json`):
- `mcp.servers.<name>.command/args/env` — local stdio server
- `mcp.servers.<name>.url` — remote HTTP server
- Extensions can register MCP servers programmatically via the MCP extension API

---

## Recommendations

1. **Keep `mcp_heartbeat_run_tests` as the canonical test execution tool** — the
   built-in `#execute/testFailure` cannot run tests, only read failure info from
   an already-run Test Controller. The MCP design is superior.

2. **Continue using `mcp_fetch_fetch` for web fetching** — it bypasses the
   two-step URL approval flow. Update the approved domains list as needed rather
   than relying on built-in `#web/fetch` which requires per-domain confirmation.

3. **Evaluate a structured MCP command runner** (Rank 1 candidate) — the built-in
   `runInTerminal` approval theater and sandbox network-blocking are significant
   friction points for CI-style automation. A purpose-built MCP executor could
   eliminate both. Scope: linters, formatters, build checks. Exclude arbitrary
   shell commands (security boundary).

4. **Update agent frontmatter docs** to reflect new namespaced tool names —
   the old names work but new agent files should prefer explicit tool set paths
   to make intent clear (e.g. `edit/editFiles` over bare `editFiles`).

5. **Consider adding `#githubTextSearch` to agent frontmatter** for agents that
   do cross-repo research (Researcher, Review) — it's separate from `#githubRepo`
   and not currently listed in any agent's `tools:` list.

---

## Gaps / Further research needed

- **`#browser` tool set**: experimental status; need to track when it goes GA and
  whether it uses Playwright under the hood or a different renderer
- **Tool approval fine-grained API** (v1.114 proposed): check if this becomes stable
  and whether it enables better per-command sandboxing for `runCommand` tools
- **Virtual tools** (`github.copilot.chat.virtualTools.threshold`): undocumented
  feature for managing large tool sets — investigate what this does and whether
  it affects tool selection behavior
- **`#execute/createAndRunTask`**: not yet used in any agent in this repo — could
  be useful for structured build task invocation; investigate vs `runInTerminal`
- **Notebook tools** (`#edit/editNotebook`, `#execute/runNotebookCell`, etc.):
  out of scope for this repo (no Jupyter usage) but worth noting for completeness
