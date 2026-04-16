# Tool Usage Patterns — copilot-instructions-template

<!-- workspace-layer: L2 | trigger: tool query -->
> **Domain**: Inventory — CLI commands, tool usage patterns, and extension registry.
> **Boundary**: No preferences, reasoning, or project architecture facts.

## Core commands

| Tool / command | Effective usage pattern |
|----------------|-------------------------|
| `bash scripts/harness/select-targeted-tests.sh <paths...>` | Use during intermediate phases to choose deterministic suites from changed paths. |
| `bash scripts/harness/run-all-captured.sh` | Use as the terminal-safe final full-suite gate before marking a task done. |
| `bash tests/run-all.sh` | Canonical underlying full-suite entrypoint when terminal capture is not needed. |
| `echo "no type check configured"` | Placeholder type-check command; this repo has no dedicated type-check step. |
| `find . \( -name '*.sh' -o -name '*.md' \) -not -path './node_modules/*' \| xargs wc -l \| tail -1` | LOC count — check after adding new files to verify LOC bands. |

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
