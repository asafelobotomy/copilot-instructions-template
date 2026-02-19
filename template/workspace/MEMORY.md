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

*(Updated as the memory system is used and its effectiveness becomes clear.)*
