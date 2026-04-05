# Memory Strategy — copilot-instructions-template

- Use project-scoped memory for conventions discovered in this codebase.
- Use session transcripts for recent context; do not rely on long-term memory for facts that are in source files.
- Always prefer reading the source file over recalling a cached summary of it.
- When a memory conflicts with a source file, the source file wins.

## Coexistence with built-in memory

VS Code's built-in memory tool (`/memories/`) has three scopes: user (persistent, cross-workspace), session (conversation-scoped), and repo (repository-scoped). This file complements built-in memory — it is **git-tracked and team-shared**, so knowledge here benefits all contributors. Use built-in memory for personal preferences; use this file for project-specific architectural decisions, conventions, and gotchas.

Use `/memories/repo/` as a repo-local inbox while work is in flight. Promote only validated, team-relevant facts here once they are worth versioning and sharing.

*(Updated as the memory system is used.)*

## Metrics Freshness

| Metric | Last reviewed | Notes |
|--------|--------------|-------|
| Test count baseline | 2026-03-19 | 222 tests, 0 failures |
| Starter-kit count | 2026-03-19 | 8 kits in REGISTRY.json |
| Skill count | 2026-04-02 | 16 in .github/skills/, 15 in template/skills/ |
| Agent count | 2026-04-02 | 10 agents in .github/agents/ |

## Known Gotchas — Hooks System

- **Stop hook output schema (confirmed 2026-04-01 docs)**: only `hookSpecificOutput.decision: "block"` and `reason` (string). No button, confirmation title, follow-up chip, or any interactive UI output. Source: `https://code.visualstudio.com/docs/copilot/customization/hooks`.
- **PostToolUse input (confirmed)**: payload includes `tool_name` (camelCase in VS Code, e.g. `create_file`, `replace_string_in_file`) and `tool_input`. This is usable for tracking Copilot edit activity in `soft_post_tool`.
- **Approved design**: active-work-time model for retrospective gating — track `task_window_start_epoch`, `active_work_seconds`, `session_start_git_count`, `copilot_edit_count`, and `tool_call_counter` in state.json. Implemented in shell and PowerShell pulse hooks with autonomous `session_reflect` stop guidance.

## Known Gotchas

- Doctor↔Security have circular handoffs — they delegate to each other. Consider merging into a unified Audit agent.
- Explore agent's read-only guarantee (no editFiles) is critical for parallel subagent safety — do not add editFiles to it.

## Maintenance

- Keep this file short enough to scan during compaction or heartbeat checks.
- Promote durable repo-memory notes here when they should survive machine changes and contributor turnover.
- Prune entries that are now captured in instructions, tests, or source files.
