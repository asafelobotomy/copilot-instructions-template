# {{PROJECT_NAME}}

> This file is auto-detected by Claude Code and VS Code (when using Claude models).
> It mirrors the core rules from `.github/copilot-instructions.md`.

## Project

- **Name**: {{PROJECT_NAME}}
- **Language**: {{LANGUAGE}}
- **Test command**: `{{TEST_COMMAND}}`

## Rules

1. Run `{{TEST_COMMAND}}` before marking any task done.
2. Plan-Do-Check-Act (PDCA) for every non-trivial change.
3. Never modify a file not opened this session.
4. Never delete existing rules without explicit user instruction.

## Coding conventions

- Shell scripts: `set -euo pipefail` required.
- No silent error swallowing — log or re-throw.
- No commented-out code — git history is the undo stack.

## See also

- `.github/copilot-instructions.md` — full Lean/Kaizen instructions
- `.github/agents/` — model-pinned agent definitions
- `.github/skills/` — domain-specific skill library
