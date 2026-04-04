# Tool Usage Patterns — {{PROJECT_NAME}}

*(Populated by Copilot from observed effective workflows. See §11 of `.github/copilot-instructions.md` for the full Tool Protocol.)*

## Core commands

| Tool / command | Effective usage pattern |
|----------------|-------------------------|
| `{{TEST_COMMAND}}` | Canonical underlying full-suite entrypoint when you need the direct command. |
| `{{TYPE_CHECK_COMMAND}}` | Run after every type definition change |
| `{{LOC_COMMAND}}` | Run after adding new files to check LOC bands |
| `{{THREE_CHECK_COMMAND}}` | Preferred final verification command or ritual before marking any task done. |

If the repo documents a targeted-test selector or phase-test command, use it during intermediate phases instead of defaulting to the full suite.

## Toolbox

Custom-built and adapted tools are saved to `.copilot/tools/`. The catalogue is maintained in `.copilot/tools/INDEX.md`.

**Before writing any automation script**, always:

1. Check `.copilot/tools/INDEX.md` for an existing tool.
2. Follow §11 (Tool Protocol) in `.github/copilot-instructions.md` if no match is found.

The toolbox directory is created lazily — it does not exist until the first tool is saved.

## Discovered workflow patterns

*(Copilot appends effective multi-step tool workflows here as they become repeatable.)*

## Extension registry

*(Copilot appends new stack → extension mappings here when discovered during extension audits.)*

| Stack signal | Recommended extension(s) | Discovered | Quality (installs · rating) |
|-------------|--------------------------|------------|----------------------------|
