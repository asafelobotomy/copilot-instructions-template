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

### Extension audit workflow

1. User asks to *"review extensions"* or *"check my extensions"*
2. Agent switches to Review Mode
3. Agent reads `.vscode/extensions.json` (workspace recommendations) and `.vscode/settings.json` (extension-specific config)
4. Agent scans for format/lint commands in `package.json` scripts, `{{TEST_COMMAND}}`, and tooling config files
5. Agent detects stack from language/runtime/framework placeholders and identified tooling
6. Agent matches detected stack against recommended extensions (language servers → linters → formatters → test runners)
7. Agent presents three-category report:
   - **Missing**: extensions that should be installed (e.g., shellcheck for `.sh` files, ESLint for `.js`)
   - **Redundant**: installed extensions not relevant to this stack
   - **Unknown**: installed extensions requiring research to assess relevance
8. User manually installs/uninstalls via VS Code Extensions view or command palette
9. Agent does not modify `.vscode/extensions.json` unless explicitly instructed with *"Apply these changes"* or *"Write the updated extensions.json"*
