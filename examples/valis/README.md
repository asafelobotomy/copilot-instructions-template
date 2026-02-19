# Reference Implementation — Valis

[asafelobotomy/Valis](https://github.com/asafelobotomy/Valis) is the canonical first consumer of this template.

Valis is a **CLI AI assistant** built on Bun and large language models. It was the project from which the methodology in this template was originally distilled — its Lean/Kaizen workflow, agent modes, workspace identity system, and documentation rituals all pre-date this template and were the direct source material for it.

---

## How Valis uses this template

| Template concept | Valis implementation |
|-----------------|---------------------|
| `.github/copilot-instructions.md` | Present and mature; Bun/TypeScript-specific overrides in §10 |
| `.copilot/workspace/` | Implemented as `.valis/workspace/` — same six files |
| `CHANGELOG.md` | Full Keep-a-Changelog history from v0.1.x |
| `JOURNAL.md` | Rich ADR history including major architectural pivots |
| `BIBLIOGRAPHY.md` | Every file catalogued with LOC |
| `METRICS.md` | Multiple snapshots; shows clear LOC and test growth |
| Living Update Protocol | Instructions have been through ≥ 3 compression/rewrite cycles |

---

## Project-specific overrides (Valis)

The following placeholder values apply to Valis:

| Placeholder | Value |
|-------------|-------|
| `{{PROJECT_NAME}}` | `Valis` |
| `{{LANGUAGE}}` | `TypeScript` |
| `{{RUNTIME}}` | `Bun >= 1.0` |
| `{{PACKAGE_MANAGER}}` | `Bun` |
| `{{TEST_COMMAND}}` | `bun test` |
| `{{TYPE_CHECK_COMMAND}}` | `bun run check:types` |
| `{{LOC_COMMAND}}` | `bun run check:loc` |
| `{{THREE_CHECK_COMMAND}}` | `bun test && bun run check:types && bun run check:loc` |
| `{{METRICS_COMMAND}}` | `bun run kaizen` |
| `{{LOC_WARN_THRESHOLD}}` | `250` |
| `{{LOC_HIGH_THRESHOLD}}` | `400` |
| `{{DEP_BUDGET}}` | `6` |
| `{{DEP_BUDGET_WARN}}` | `8` |
| `{{TEST_FRAMEWORK}}` | `bun:test` |
| `{{INTEGRATION_TEST_ENV_VAR}}` | `VALIS_LIVE_TEST` |
| `{{PREFERRED_SERIALISATION}}` | `JSON, HTTP, SQLite` |
| `{{SUBAGENT_MAX_DEPTH}}` | `3` |
| `{{VALUE_STREAM_DESCRIPTION}}` | `User Input → REPL → Agent Loop → Provider → Tool Calls → Response` |
| `{{FLOW_DESCRIPTION}}` | `Stream tokens; single-pass tool execution; fast feedback (<5s tests)` |
| `{{PROJECT_CORE_VALUE}}` | `agent capability` |

---

## Additional Valis-specific conventions

These are recorded in Valis's own `copilot-instructions.md` §10 and are not part of the generic template:

- Tool implementations use **factory functions** (not classes) taking injected dependencies.
- All tool parameters are validated with **Zod** (`z.object({...})`) with `.describe()` strings for LLM clarity.
- **Bun-specific APIs**: `Bun.file()`, `Bun.write()`, `bun:sqlite`, `bun:test`.
- Architecture tests are in `test/architecture.test.ts` and are advisory (warn, never fail CI).
- `BIBLIOGRAPHY.md` discipline: every file catalogued; omission = undocumented inventory.
- Workspace identity lives under `.valis/workspace/` rather than `.copilot/workspace/`.
