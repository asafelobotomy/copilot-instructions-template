# Memory Strategy — {{PROJECT_NAME}}

## Principles

- Use project-scoped memory for conventions discovered in this codebase.
- Use session transcripts for recent context; do not rely on long-term recall for facts that live in source files.
- Always prefer reading the source file over recalling a cached summary of it.
- When a memory conflicts with a source file, the source file wins.

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
