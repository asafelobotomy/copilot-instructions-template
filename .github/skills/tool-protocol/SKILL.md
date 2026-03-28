---
name: tool-protocol
description: Find, build, or adapt automation tools following the Tool Protocol decision tree
compatibility: ">=1.4"
---

# Tool Protocol

> Skill metadata: version "1.1"; license MIT; tags [tools, automation, scripting, toolbox, plugins, mcp-apps]; compatibility ">=1.4"; recommended tools [codebase, editFiles, runCommands, fetch].

When a task requires automation, a scripted command sequence, or a repeatable utility, follow this decision tree before writing anything ad-hoc.

## When to use

- The user asks to "build a tool", "create a script", or "automate" something
- You need a repeatable utility and want to check if one already exists
- You are evaluating whether to save a script to the toolbox

## Decision tree

```text
Need a tool for task X
 │
 ├─ 1. FIND — check .copilot/tools/INDEX.md
 │     ├─ Exact match  → USE IT directly
 │     ├─ Close match  → ADAPT (fork, rename, note source in comment at top of file)
 │     └─ No match     → ↓
 │
 ├─ 1.5 BUILT-IN — check VS Code's native tool capabilities
 │     ├─ `list_code_usages`  → find all references, implementations, callers of a symbol
 │     ├─ `get_errors`        → get compile/lint errors for a file or the entire workspace
 │     ├─ `fetch_webpage`     → fetch web pages, docs, APIs (use for documentation lookups)
 │     ├─ `semantic_search`   → natural language search across the codebase
 │     ├─ `grep_search`       → fast text/regex search in workspace files
 │     ├─ Sufficient → USE built-in tool
 │     └─ Not sufficient → ↓
 │
 ├─ 1.6 PLUGIN TOOLS — check installed agent plugins for contributed tools
 │     ├─ Search Extensions view with `@agentPlugins`
 │     ├─ Inspect plugin docs for commands, skills, hooks, and MCP servers
 │     ├─ Suitable existing capability → USE plugin-contributed capability
 │     └─ No suitable capability → ↓
 │
 ├─ 2. SEARCH online (try in order)
 │     a. MCP server registry  github.com/modelcontextprotocol/servers
 │     b. GitHub search        github.com/search?type=repositories&q=<task>
 │     c. Awesome lists        awesome-cli-apps · awesome-shell · awesome-python · awesome-rust · awesome-go
 │     d. Stack registry       npmjs.com / pypi.org / crates.io / pkg.go.dev
 │     e. Official CLI docs    git · docker · gh · jq · ripgrep · sed · awk (built-ins first)
 │     ├─ Found something usable → evaluate fit, adapt as needed, note source
 │     └─ Nothing applicable → ↓
 │
 ├─ 2.5 COMPOSE — can this be assembled from 2+ existing toolbox tools via pipe or import?
 │     ├─ Yes → compose; document the pipeline; save to toolbox if reusable
 │     └─ No  → ↓
 │
 └─ 3. BUILD — write the tool from scratch
          - Follow §4 coding conventions and §3 LOC baselines
          - Single-purpose: one tool, one job; compose via pipes or imports
          - Accept arguments instead of hardcoding project-specific paths
          - Required inline header at the top of every built or saved tool:
            # purpose:  <what this tool does — one precise sentence>
            # when:     <when to invoke it | when NOT to invoke it>
            # inputs:   <argument list with types and valid values>
            # outputs:  <what it returns — type and structure; include MCP Apps output when interactive UI is beneficial>
            # risk:     safe | destructive
            # source:   <url or "original" if built from scratch>
          │
          └─ 4. EVALUATE reusability
                ├─ ≥ 2 distinct tasks in this project would benefit → SAVE to toolbox
                │   a. Place file in .copilot/tools/<kebab-name>.<ext>
                │   b. Add a row to .copilot/tools/INDEX.md (see format below)
                └─ Single-use / too project-specific → use inline only; do not save
```

## Toolbox

`.copilot/tools/` is created on first tool save (no setup step required). Contents:

Files: `INDEX.md` (catalogue) · `*.sh` · `*.py` · `*.js`/`*.ts` · `*.mcp.json`

**INDEX.md row format**:

| Tool | Lang | What it does | When to use | Output | Risk |
|------|------|-------------|------------|--------|------|
| `count-exports.sh` | bash | Count exported symbols per file | API surface audits | symbol counts to stdout | safe |
| `summarise-metrics.py` | python | Parse metrics baselines and print trends | Kaizen review sessions | trend table to stdout | safe |

## Tool quality rules

**Naming** — Tool names must be a verb-noun kebab phrase describing the action (`count-exports`, `sync-schema`), not a noun or generic label (`exports`, `utils`).

**Risk tier**:

- `safe` — read-only or fully idempotent; invoke without confirmation
- `destructive` — deletes files, overwrites data, or writes to remote systems; **must pause and confirm with the user before execution**, regardless of session autonomy level

**Other rules**:

- Tools must be idempotent where possible
- Tools must not hardcode project-specific paths, names, or secrets — accept arguments
- Retire unused tools: mark `[DEPRECATED]` in INDEX.md; counts as W1 (Overproduction)
- Tools follow the same LOC baseline as source code (§3 hard limit: 400 lines)
- Output efficiency — prefer targeted reads (`grep`, `head`, `jq`) over raw dumps; return the minimum token payload the callsite requires.
- For interactive workflows (forms, tabular drill-down, visual states), prefer MCP Apps output over plain text when the runtime supports it.

## Subagent tool use

Subagents inherit this protocol fully. A subagent may build or adapt a tool independently. To **save** a tool to the toolbox, the subagent must first flag the proposal to the parent agent, which confirms before any write to `.copilot/tools/`.
