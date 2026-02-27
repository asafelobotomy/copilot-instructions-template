# Tool Usage Patterns — copilot-instructions-template

| Tool / command | Effective usage pattern |
|----------------|-------------------------|
| `bash tests/test-hooks.sh && bash tests/test-guard-destructive.sh && bash tests/test-sync-version.sh && bash tests/test-security-edge-cases.sh` | Run after every change; treat red as blocking |
| `echo "no type check configured"` | Run after every type definition change |
| `bash tests/test-hooks.sh && bash tests/test-guard-destructive.sh && bash tests/test-sync-version.sh && bash tests/test-security-edge-cases.sh` | Three-check ritual — run before marking a task done |

*(Updated as effective workflows are discovered.)*
