---
name: Plugin Components
applyTo: ".github/agents/**,.github/skills/**,.github/hooks/**"
description: "Conventions for authoring agents, skills, and hooks in this project"
---

# Plugin Component Instructions

## Agents (`.github/agents/*.agent.md`)

- Every agent must have: `name`, `description`, `argument-hint`, `model` (list), `tools`, `agents` (delegation allow-list).
- `user-invocable: false` marks the agent as an internal delegation target only.
- `agents:` lists the agents this specialist may delegate to. Keep it tight — do not add agents speculatively.
- Descriptions must be one sentence. Trigger phrases in `argument-hint` must be short and completable from a single request.
- Keep the `agents:` allow-list aligned with actual delegation behaviour in the body — never list an agent not referenced in the workflow.

## Skills (`.github/skills/*/SKILL.md`)

Each `SKILL.md` must start with a frontmatter block containing `name`, `description`, and `version`.

- `description` must be one sentence answering "when should a model load this skill?" — not a step-by-step summary of the workflow.
- `version` must follow semver (`1.0.0`).
- The skill directory name must match the `name` field in frontmatter (lowercase, hyphenated).

## Hooks (`.github/hooks/`)

- Hook scripts accept JSON on stdin and must emit JSON on stdout (stdio protocol). Never print plain text to stdout.
- All shell hook scripts must begin with `set -euo pipefail`.
- Python hook scripts must be importable without side effects (`python3 -m py_compile <file>` must pass).
- Use `${TMPDIR:-/tmp}` rather than bare `/tmp` in hook scripts.
- Hook command paths in `.github/hooks/copilot-hooks.json` must be bare workspace-relative paths (e.g. `.github/hooks/scripts/foo.sh`) — never use a leading `./`.
- When adding or removing a hook registration, update `.github/hooks/copilot-hooks.json`.
