# Bootstrap Record — {{PROJECT_NAME}}

This workspace was scaffolded on **{{SETUP_DATE}}** using the [copilot-instructions-template](https://github.com/asafelobotomy/copilot-instructions-template).

## Initial stack detected

| Property | Value |
|----------|-------|
| Language | {{LANGUAGE}} |
| Runtime | {{RUNTIME}} |
| Package manager | {{PACKAGE_MANAGER}} |
| Test framework | {{TEST_FRAMEWORK}} |

## Files created during setup

| File | Action |
|------|--------|
| `.github/copilot-instructions.md` | Created from template + placeholders filled |
| `.github/agents/setup.agent.md` | Created — model-pinned Setup agent (Claude Sonnet 4.6) |
| `.github/agents/coding.agent.md` | Created — model-pinned Coding agent (GPT-5.3-Codex) |
| `.github/agents/review.agent.md` | Created — model-pinned Review agent (Claude Opus 4.6) |
| `.github/agents/fast.agent.md` | Created — model-pinned Fast agent (Claude Haiku 4.5) |
| `.github/skills/*/SKILL.md` | Created — reusable skill library (4 starter skills from §12) |
| `.copilot/workspace/IDENTITY.md` | Created |
| `.copilot/workspace/SOUL.md` | Created |
| `.copilot/workspace/USER.md` | Created |
| `.copilot/workspace/TOOLS.md` | Created |
| `.copilot/workspace/MEMORY.md` | Created |
| `.copilot/workspace/BOOTSTRAP.md` | This file — created |
| `CHANGELOG.md` | Created / already existed |
| `JOURNAL.md` | Created / already existed |
| `BIBLIOGRAPHY.md` | Created / already existed |
| `METRICS.md` | Created / already existed |

## Toolbox

`.copilot/tools/` is created lazily — it does not exist until the first tool is saved by the agent. When it is created, `.copilot/tools/INDEX.md` will act as the catalogue.

## Skills

`.github/skills/` contains reusable workflow instructions following the [Agent Skills](https://agentskills.io) open standard. Starter skills were scaffolded during setup. New skills can be created via §12 or by saying "Create a skill for...".

*(This file is not updated after setup. It is a permanent record of origin.)*
