# Memory Strategy — copilot-instructions-template

<!-- workspace-layer: L1 | budget: ≤300 tokens | trigger: always -->
> **Domain**: Facts — verified project facts, error patterns, team conventions, baselines, and gotchas.
> **Boundary**: No opinions, preferences, reasoning heuristics, or session-specific state.

- Use project-scoped memory for conventions discovered in this codebase.
- Use session transcripts for recent context; do not rely on long-term memory for facts that are in source files.
- Always prefer reading the source file over recalling a cached summary of it.
- When a memory conflicts with a source file, the source file wins.

## Coexistence with built-in memory

VS Code's built-in memory tool (`/memories/`) has three scopes: user (persistent, cross-workspace), session (conversation-scoped), and repo (repository-scoped). This file complements built-in memory — it is **git-tracked and team-shared**, so knowledge here benefits all contributors. Use built-in memory for personal preferences; use this file for project-specific architectural decisions, conventions, and gotchas.

Use `/memories/repo/` as a repo-local inbox while work is in flight. Promote only validated, team-relevant facts here once they are worth versioning and sharing.

### Known constraints

- **User memory auto-load cap**: the first 200 lines of `/memories/` are injected into every session automatically. Lines beyond 200 are invisible unless the agent reads the file explicitly. Keep user memory concise.
- **Repo memory is machine-local**: `/memories/repo/` files live on disk under `workspaceStorage/{id}/GitHub.copilot-chat/memory-tool/` — they are not git-tracked and do not transfer to other machines or contributors.
- **Copilot Memory (GitHub-hosted)**: a separate, opt-in system (`github.copilot.chat.copilotMemory.enabled`) that stores repo-scoped memories on GitHub servers with 28-day auto-expiry and just-in-time citation verification. It shares knowledge across all Copilot surfaces (coding agent, code review, CLI). Enable it to complement this file for cross-surface agent learning.
- **No duplication**: do not record personal preferences here if built-in user memory already tracks them. This file is for project-specific knowledge that should survive machine changes.

When creating `/memories/repo/` entries, prefer the Copilot Memory JSON schema (`subject`, `fact`, `citations`, `reason`, `category`) for structural compatibility.

*(Updated as the memory system is used.)*

## Metrics Freshness

| Metric | Last reviewed | Expires | Priority | Source | Notes |
|--------|--------------|---------|----------|--------|-------|
| Test count baseline | 2026-03-19 | 2026-06-19 | P1 | `tests/run-all.sh` | 222 tests, 0 failures |
| Starter-kit count | 2026-03-19 | 2026-06-19 | P2 | `starter-kits/REGISTRY.json` | 8 kits in REGISTRY.json |
| Skill count | 2026-04-02 | 2026-07-02 | P2 | `.github/skills/` | 16 in .github/skills/, 15 in template/skills/ |
| Agent count | 2026-04-02 | 2026-07-02 | P2 | `.github/agents/` | 10 agents in .github/agents/ |

> **Priority**: P1 = critical baseline, P2 = important inventory, P3 = informational.
> **Expires**: review-by date; heartbeat flags rows past expiry. Default: 3 months from last review.

## Known Gotchas — Hooks System

| Gotcha | Impact | Observed | Source | Notes |
|--------|--------|----------|--------|-------|
| Stop hook output: only `decision: "block"` + `reason` (string) | critical | 2026-04-01 | [hooks docs](https://code.visualstudio.com/docs/copilot/customization/hooks) | No button, confirmation title, follow-up chip, or interactive UI output |
| PostToolUse input includes `tool_name` + `tool_input` | notable | 2026-04-01 | [hooks docs](https://code.visualstudio.com/docs/copilot/customization/hooks) | Usable for tracking Copilot edit activity in `soft_post_tool` |
| Active-work-time model for retrospective gating | notable | 2026-04-02 | `template/hooks/scripts/pulse_state.py` | Tracks epoch, active seconds, git count, edit count, tool counter in state.json |

## Known Gotchas

| Gotcha | Impact | Observed | Source | Notes |
|--------|--------|----------|--------|-------|
| Doctor↔Security circular handoffs | notable | 2026-04-02 | `.github/agents/` | Consider merging into unified Audit agent |
| Explore agent read-only guarantee (no editFiles) | critical | 2026-04-02 | `.github/agents/explore.agent.md` | Required for parallel subagent safety — do not add editFiles |

## Archived

*(Expired or superseded entries move here instead of being deleted. Prune quarterly.)*

| Entry | Archived | Reason |
|-------|----------|--------|

## Maintenance

- Keep this file short enough to scan during compaction or heartbeat checks.
- Promote durable repo-memory notes here when they should survive machine changes and contributor turnover.
- Prune entries that are now captured in instructions, tests, or source files.
- When a Metrics Freshness row passes its `Expires` date, either re-verify and update the date, or move the row to Archived.

> **Provenance convention**: `file:line` for code, URL for docs, `session:{id}` for observed behaviour.
