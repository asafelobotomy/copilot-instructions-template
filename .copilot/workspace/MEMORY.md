# Memory Strategy — copilot-instructions-template

- Use project-scoped memory for conventions discovered in this codebase.
- Use session transcripts for recent context; do not rely on long-term memory for facts that are in source files.
- Always prefer reading the source file over recalling a cached summary of it.
- When a memory conflicts with a source file, the source file wins.

## Coexistence with built-in memory

VS Code's built-in memory tool (`/memories/`) has three scopes: user (persistent, cross-workspace), session (conversation-scoped), and repo (repository-scoped). This file complements built-in memory — it is **git-tracked and team-shared**, so knowledge here benefits all contributors. Use built-in memory for personal preferences; use this file for project-specific architectural decisions, conventions, and gotchas.

*(Updated as the memory system is used.)*

## Metrics Freshness

| Metric | Last reviewed | Notes |
|--------|--------------|-------|
| Test count baseline | 2026-03-19 | 222 tests, 0 failures |
| Starter-kit count | 2026-03-19 | 8 kits in REGISTRY.json |
| Skill count | 2026-03-19 | 14 in .github/skills/, 14 in template/skills/ |
| Agent count | 2026-03-19 | 6 agents in .github/agents/ |
