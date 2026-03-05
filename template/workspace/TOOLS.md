# Tool Usage Patterns — {{PROJECT_NAME}}

*(Populated by Copilot from observed effective workflows. See §11 of `.github/copilot-instructions.md` for the full Tool Protocol.)*

## Core commands

| Tool / command | Effective usage pattern |
|----------------|-------------------------|
| `{{TEST_COMMAND}}` | Run after every change; treat red as blocking |
| `{{TYPE_CHECK_COMMAND}}` | Run after every type definition change |
| `{{LOC_COMMAND}}` | Run after adding new files to check LOC bands |
| `{{THREE_CHECK_COMMAND}}` | Three-check ritual — run before marking any task done |

## Toolbox

Custom-built and adapted tools are saved to `.copilot/tools/`. The catalogue is maintained in `.copilot/tools/INDEX.md`.

**Before writing any automation script**, always:

1. Check `.copilot/tools/INDEX.md` for an existing tool.
2. Follow §11 (Tool Protocol) in `.github/copilot-instructions.md` if no match is found.

The toolbox directory is created lazily — it does not exist until the first tool is saved.

## Discovered workflow patterns

*(Copilot appends effective multi-step tool workflows here as they become repeatable.)*

### Built-in VS Code tools (v1.110+)

These tools are available natively in VS Code and do not require MCP servers:

| Tool | Purpose | Notes |
|------|---------|-------|
| `usages` | Find all references/usages of a symbol | Replaces grep-based usage search |
| `rename` | Rename a symbol across the workspace | Language-server powered, safe refactoring |
| `editFiles` | Create, edit, or delete files | Core file editing capability |
| `terminal` | Run shell commands | Subject to auto-approval and guard-destructive |
| `codebase` | Semantic code search | Workspace-wide semantic search |
| `fetch` | Fetch web content | Requires network access |
| `githubRepo` | GitHub repository operations | Requires GitHub token |
| `runCommands` | Run VS Code commands | Extension and editor commands |
| `Explore` (subagent) | Read-only codebase exploration | Delegated search without modifying files |

### Agentic browser tools (v1.110+, Preview)

Browser tools allow Copilot to interact with web pages directly. Requires `workbench.browser.enableChatTools: true`.

| Tool | Purpose |
|------|---------|
| `openBrowserPage` | Open a URL in a managed browser |
| `navigatePage` | Navigate to a new URL |
| `readPage` | Read page content (text, links, forms, structure) |
| `screenshotPage` | Capture a screenshot for visual verification |
| `clickElement` | Click a button, link, or interactive element |
| `hoverElement` | Hover over an element |
| `dragElement` | Drag and drop an element |
| `typeInPage` | Type text into input fields |
| `handleDialog` | Accept or dismiss browser dialogs |
| `runPlaywrightCode` | Run custom Playwright code in the browser context |

### Extension audit workflow

1. User asks to *"review extensions"* or *"check my extensions"*
2. Agent switches to Review Mode
3. Agent asks user to run `code --list-extensions | sort` and paste the output
4. Agent reads `.vscode/extensions.json` (workspace recommendations) and `.vscode/settings.json` (extension-specific config)
5. Agent scans for format/lint commands in `package.json` scripts, `{{TEST_COMMAND}}`, and tooling config files
6. Agent detects stack from language/runtime/framework placeholders and identified tooling
7. Agent matches detected stack against built-in extension table (language servers → linters → formatters → test runners)
8. For unknown stacks: agent searches Marketplace, filters by quality, then appends new mappings to "Extension registry" below
9. Agent presents three-category report: Missing (should install) · Redundant (consider removing) · Unknown (researched and resolved)
10. User manually installs/uninstalls via VS Code Extensions view or command palette
11. Agent does not modify `.vscode/extensions.json` unless explicitly instructed with *"Apply these changes"* or *"Write the updated extensions.json"*

## Extension registry

*(Copilot appends new stack → extension mappings here when discovered during extension audits. These persist across sessions and supplement the built-in stack detection table in §2 of `.github/copilot-instructions.md`.)*

| Stack signal | Recommended extension(s) | Discovered | Quality (installs · rating) |
|-------------|--------------------------|------------|----------------------------|
