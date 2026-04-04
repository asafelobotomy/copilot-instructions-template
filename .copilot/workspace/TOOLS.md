# Tool Usage Patterns — copilot-instructions-template

| Tool / command | Effective usage pattern |
|----------------|-------------------------|
| `bash scripts/tests/select-targeted-tests.sh <paths...>` | Use during intermediate phases to choose deterministic suites from changed paths. |
| `bash scripts/tests/run-all-captured.sh` | Use as the terminal-safe final full-suite gate before marking a task done. |
| `bash tests/run-all.sh` | Canonical underlying full-suite entrypoint when terminal capture is not needed. |
| `echo "no type check configured"` | Placeholder type-check command for workflows and docs; this repo has no dedicated type-check step. |

*(Updated as effective workflows are discovered.)*
