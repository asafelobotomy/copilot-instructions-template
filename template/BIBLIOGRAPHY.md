# Bibliography — {{PROJECT_NAME}}

Every file in the project is catalogued here. Update this file whenever a file is created, renamed, deleted, or its purpose changes.

Maintenance rule: run `{{LOC_COMMAND}}` and compare outputs to this table. Any file present in the codebase but absent from this table is **undocumented inventory** (Waste Category 5).

---

## Meta files

| File | Purpose | LOC |
|------|---------|-----|
| `.github/copilot-instructions.md` | AI agent guidance — Lean/Kaizen methodology + project conventions | — |
| `CHANGELOG.md` | Keep-a-Changelog style release notes | — |
| `JOURNAL.md` | ADR-style architectural decision record | — |
| `BIBLIOGRAPHY.md` | This file — complete project file map | — |
| `METRICS.md` | Kaizen baseline snapshot table | — |

## Model-pinned agents

| File | Purpose | LOC |
|------|---------|-----|
| `.github/agents/setup.agent.md` | Setup agent — Claude Sonnet 4.6 (onboarding & template operations) | — |
| `.github/agents/coding.agent.md` | Coding agent — GPT-5.3-Codex (implementation & refactoring) | — |
| `.github/agents/review.agent.md` | Review agent — Claude Opus 4.6 (code review & architectural analysis) | — |
| `.github/agents/fast.agent.md` | Fast agent — Claude Haiku 4.5 (quick questions & lightweight edits) | — |

## Workspace identity

| File | Purpose | LOC |
|------|---------|-----|
| `.copilot/workspace/IDENTITY.md` | Agent self-description | — |
| `.copilot/workspace/SOUL.md` | Agent values & reasoning patterns | — |
| `.copilot/workspace/USER.md` | Observed user profile | — |
| `.copilot/workspace/TOOLS.md` | Effective tool usage patterns | — |
| `.copilot/workspace/MEMORY.md` | Memory system strategy | — |
| `.copilot/workspace/BOOTSTRAP.md` | Permanent setup origin record | — |
| `.copilot/workspace/HEARTBEAT.md` | Event-driven health check checklist | — |

## Source files

| File | Purpose | LOC |
|------|---------|-----|
| *(add source files here)* | | |

---

*(Maintained by Copilot. Run the Documentation Update Ritual after structural changes.)*
