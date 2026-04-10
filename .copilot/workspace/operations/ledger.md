# Spatial Ledger — copilot-instructions-template

<!-- workspace-layer: L2 | trigger: on spatial_status call or heartbeat -->

> Full vocabulary for the project's spatial metaphor. The compact table in §14 covers daily work;
> this file is the complete reference.

## Metaphor: village

| Term | Meaning | Maps to |
|------|---------|---------|
| Village | This project workspace | Repository root |
| Town Hall | Main instructions | `.github/copilot-instructions.md` |
| Building | Agent workspace | `.github/agents/{name}.agent.md` |
| Workshop | Template layer | `template/` |
| Trade Route | Cross-repo memory | `/memories/repo/` |
| Diary | Per-agent findings log | `.copilot/workspace/knowledge/diaries/{agent}.md` |
| Ledger | This file | `.copilot/workspace/operations/ledger.md` |

## Spaces

Spaces are the logical areas of the project. Each space maps to a directory or file group.

| Space | Path pattern | Owner agent | Purpose |
|-------|-------------|-------------|---------|
| Template | `template/` | Code | Consumer-facing instruction template |
| Scripts | `scripts/` | Code | Utility and CI scripts |
| Tests | `tests/` | Code | Test suite |
| Agents | `.github/agents/` | Code | Model-pinned VS Code agents |
| Skills | `.github/skills/` | Code | Reusable skill library |
| Hooks | `.github/hooks/` | Code | Agent lifecycle hooks |
| Kits | `starter-kits/` | Code | Stack-specific starter kits |
| Workspace | `.copilot/workspace/` | All | Session identity and state |

## Agent Homes

Each specialist agent has a home — the space it primarily operates in.

| Agent | Home space | Diary path |
|-------|-----------|------------|
| Code | Template + Scripts | `.copilot/workspace/knowledge/diaries/code.md` |
| Review | Template + Tests | `.copilot/workspace/knowledge/diaries/review.md` |
| Audit | Scripts + Hooks | `.copilot/workspace/knowledge/diaries/audit.md` |
| Explore | All (read-only) | `.copilot/workspace/knowledge/diaries/explore.md` |
| Researcher | External | `.copilot/workspace/knowledge/diaries/researcher.md` |

## Cross-References

| From | To | Relationship |
|------|----|-------------|
| Template | .github/ | Parity mirror |
| Hooks | MCP server | Lifecycle integration |
| Skills | template/skills/ | Source mirror |

## Maintenance

- Review during heartbeat when spatial_status reports drift.
- Add new spaces when directories are created.
- Archive removed spaces rather than deleting rows.
- Keep this file under 100 lines. Move historical data to `.github/archive/`.
