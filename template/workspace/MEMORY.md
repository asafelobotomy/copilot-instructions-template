# Memory Strategy — {{PROJECT_NAME}}

## Principles

- Use project-scoped memory for conventions discovered in this codebase.
- Use session transcripts for recent context; do not rely on long-term recall for facts that live in source files.
- Always prefer reading the source file over recalling a cached summary of it.
- When a memory conflicts with a source file, the source file wins.

## Copilot Memory coexistence

VS Code's **Copilot Memory** (native memory feature) persists user preferences and patterns across all sessions automatically. This file exists alongside that system — they are complementary, not competing:

| System | Scope | What it stores | Managed by |
|--------|-------|---------------|------------|
| **Copilot Memory** (native) | Global — all repos, all sessions | Personal preferences, coding style, tool usage patterns | VS Code (automatic) |
| **MEMORY.md** (this file) | Project — this repo only | Architectural decisions, error patterns, team conventions, project-specific gotchas | Agent + user (manual) |
| **MCP memory server** (`@modelcontextprotocol/server-memory`) | Session — ephemeral; clears on server restart | Knowledge graphs, intermediate reasoning state, mid-task scratchpad when context limit forces truncation | Agent (automatic, transient) |

**Priority rule**: When native Copilot Memory conflicts with MEMORY.md, **this file wins** for project-specific facts. Native memory wins for personal preferences and cross-project patterns. MCP memory server has lowest priority — treat its entries as transient scratchpad, not ground truth.

**Avoid duplication**: Do not record personal preferences here if Copilot Memory already tracks them. This file is for project-specific knowledge that would be lost if you switched machines or cleared native memory.

## What to remember

- Hard-won architectural decisions (link to JOURNAL.md entry).
- Cross-cutting patterns that are not yet in the instructions file.
- User preferences observed over time (link to USER.md).

## What not to remember

- File contents — read them fresh.
- Test results — run them fresh.
- LOC counts — measure them fresh.

## Architectural Decisions

Append rows as decisions are made. Link to the corresponding JOURNAL.md entry.

| Date | Decision | Rationale | JOURNAL.md link |
|------|----------|-----------|-----------------|
| | | | |

## Recurring Error Patterns

Append rows when error patterns are identified and resolved.

| Error signature | Root cause | Fix pattern | Last seen |
|-----------------|------------|-------------|-----------|
| | | | |

## Team Conventions Discovered

Append rows when conventions are inferred from code, reviews, or discussions.

| Convention | Source | Confidence | Date learned |
|------------|--------|------------|--------------|
| | | | |

## Known Gotchas

Append rows for non-obvious behaviours, environment quirks, or dependency traps.

| Gotcha | Affected files | Workaround | Severity |
|--------|---------------|------------|----------|
| | | | |

## Maintenance Protocol

- Review and prune this file quarterly (or when it exceeds 100 rows total).
- Remove entries that are now captured in the instructions file or JOURNAL.md.
- Archive pruned entries to `.github/archive/memory-pruned-YYYY-MM-DD.md` if historical record is needed.
- Rules in this file must be falsifiable — remove any entry that no longer improves agent output.
