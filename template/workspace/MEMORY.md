# Memory Strategy — {{PROJECT_NAME}}

<!-- workspace-layer: L1 | budget: ≤300 tokens | trigger: always -->
> **Domain**: Facts — verified project facts, error patterns, team conventions, baselines, and gotchas.
> **Boundary**: No opinions, preferences, reasoning heuristics, or session-specific state.

## Principles

- Use project-scoped memory for conventions discovered in this codebase.
- Use session transcripts for recent context; do not rely on long-term recall for facts that live in source files.
- Always prefer reading the source file over recalling a cached summary of it.
- When a memory conflicts with a source file, the source file wins.

## Use This File as a Hot Index

- Keep this file short and quick to scan.
- Store durable rules, short summaries, and pointers here.
- Move detailed research notes, session-specific findings, and large inventories into named shard files or adjacent focused docs.
- If a detail does not need to be loaded every time, link to it from here instead of pasting it inline.

## Copilot Memory coexistence

VS Code's **built-in memory tool** (`/memories/`) provides persistent storage across sessions with three scopes. This file exists alongside that system — they are complementary, not competing:

| System | Scope | What it stores | Managed by |
|--------|-------|---------------|------------|
| **Built-in memory** `/memories/` (user scope) | Global — all repos, all sessions | Personal preferences, coding style, cross-project patterns | VS Code (persistent) |
| **Built-in memory** `/memories/session/` | Session — current conversation only | Task-specific context, in-progress notes, working state | VS Code (cleared after conversation) |
| **Built-in memory** `/memories/repo/` | Repository — this workspace | Repository-scoped facts stored locally via Copilot | VS Code (persistent, repo-scoped) |
| **MEMORY.md** (this file) | Project — git-tracked, team-shared | Architectural decisions, error patterns, team conventions, project-specific gotchas | Agent + user (manual, version-controlled) |

**Priority rule**: When built-in memory conflicts with MEMORY.md, **this file wins** for project-specific facts. Built-in user memory wins for personal preferences and cross-project patterns.

**Key distinction**: MEMORY.md is **git-tracked and team-shared** — every team member benefits from the knowledge recorded here. Built-in memory is personal and machine-local. Use MEMORY.md for knowledge that should survive contributor changes, machine migrations, and onboarding.

**Avoid duplication**: Do not record personal preferences here if built-in user memory already tracks them. This file is for project-specific knowledge that would be lost if you switched machines or cleared native memory.

**Promotion rule**: Use built-in `/memories/repo/` as a repo-local inbox while a task is in flight. Promote only validated, team-relevant facts into this file once they are stable enough to version-control and share.

### Known constraints

- **User memory auto-load cap**: the first 200 lines of `/memories/` are injected into every session automatically. Lines beyond 200 are invisible unless the agent reads the file explicitly. Keep user memory concise.
- **Repo memory is machine-local**: `/memories/repo/` files live on disk under `workspaceStorage/{id}/GitHub.copilot-chat/memory-tool/` — they are not git-tracked and do not transfer to other machines or contributors.
- **Copilot Memory (GitHub-hosted)**: a separate, opt-in system (`github.copilot.chat.copilotMemory.enabled`) that stores repo-scoped memories on GitHub servers with 28-day auto-expiry and just-in-time citation verification. It shares knowledge across all Copilot surfaces (coding agent, code review, CLI). Enable it to complement this file for cross-surface agent learning.
- **No duplication**: do not record personal preferences here if built-in user memory already tracks them. This file is for project-specific knowledge that should survive machine changes.

When creating `/memories/repo/` entries, prefer the Copilot Memory JSON schema (`subject`, `fact`, `citations`, `reason`, `category`) for structural compatibility.

## What to remember

- Hard-won architectural decisions.
- Cross-cutting patterns that are not yet in the instructions file.
- Durable repo-memory notes that now need to be shared with the team.
- User preferences observed over time (link to USER.md).

## What not to remember

- File contents — read them fresh.
- Test results — run them fresh.
- LOC counts — measure them fresh.

## Architectural Decisions

Append rows as decisions are made.

| Date | Decision | Rationale | Status | Source | Notes |
|------|----------|-----------|--------|--------|-------|
| | | | | | |

> **Status**: active, superseded, or archived.
> **Source**: `file:line` for code, URL for docs, `session:{id}` for observed.

## Recurring Error Patterns

Append rows when error patterns are identified and resolved.

| Error signature | Root cause | Fix pattern | Impact | Last seen | Source |
|-----------------|------------|-------------|--------|-----------|--------|
| | | | | | |

> **Impact**: critical, notable, or informational.

## Team Conventions Discovered

Append rows when conventions are inferred from code, reviews, or discussions.

| Convention | Source | Confidence | Date learned |
|------------|--------|------------|--------------|
| | | | |

## Known Gotchas

Append rows for non-obvious behaviours, environment quirks, or dependency traps.

| Gotcha | Affected files | Workaround | Impact | Observed | Source |
|--------|---------------|------------|--------|----------|--------|
| | | | | | |

## Archived

*(Expired or superseded entries move here instead of being deleted. Prune quarterly.)*

| Entry | Archived | Reason |
|-------|----------|--------|

## Maintenance Protocol

- Review and prune this file quarterly (or when it exceeds 100 rows total).
- Keep rows concise so compaction snapshots can lift the latest durable entries without tailing the whole file.
- Remove entries that are now captured in the instructions file.
- Archive pruned entries to `.github/archive/memory-pruned-YYYY-MM-DD.md` if historical record is needed.
- When an entry is superseded or expired, move it to the Archived section rather than deleting it.
- When `/memories/repo/` accumulates validated facts that should survive machine changes or contributor turnover, fold the durable subset into this file and trim stale repo-local notes.
- Rules in this file must be falsifiable — remove any entry that no longer improves agent output.

> **Provenance convention**: `file:line` for code, URL for docs, `session:{id}` for observed behaviour.
