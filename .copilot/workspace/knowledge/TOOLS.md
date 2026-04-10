# Tool Usage Patterns — copilot-instructions-template

<!-- workspace-layer: L2 | trigger: tool query -->
> **Domain**: Inventory — CLI commands, tool usage patterns, and extension registry.
> **Boundary**: No preferences, reasoning, or project architecture facts.

| Tool / command | Effective usage pattern |
|----------------|-------------------------|
| `bash scripts/harness/select-targeted-tests.sh <paths...>` | Use during intermediate phases to choose deterministic suites from changed paths. |
| `bash scripts/harness/run-all-captured.sh` | Use as the terminal-safe final full-suite gate before marking a task done. |
| `bash tests/run-all.sh` | Canonical underlying full-suite entrypoint when terminal capture is not needed. |
| `echo "no type check configured"` | Placeholder type-check command for workflows and docs; this repo has no dedicated type-check step. |

*(Updated as effective workflows are discovered.)*
