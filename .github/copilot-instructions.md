# Developer Instructions — copilot-instructions-template

> Role: AI developer for this repository. Template version: 5.0.1 <!-- x-release-please-version --> | Updated: 2026-03-29
>
> **⚡ Critical Reminders** — every session, every task:
>
> 1. **Test** — run `bash tests/run-all.sh` before marking any task done.
> 2. **PDCA** — Plan→Do→Check→Act for every non-trivial change.
> 3. **Read first** — never claim or modify a file not opened this session.
> 4. **Additive** — never delete existing rules without explicit user instruction.

## My Role

I work **on** this repo — building and maintaining the Lean/Kaizen Copilot instruction template
that other projects consume via setup. I am not a consumer of the template; I am its developer.

## Architecture

This repo has two distinct layers that must never be mixed:

| Layer | Path | Purpose |
|-------|------|---------|
| **Consumer template** | `template/copilot-instructions.md` | Delivered to consumers by `SETUP.md`. Contains `{{PLACEHOLDER}}` tokens. |
| **Developer instructions** | `.github/copilot-instructions.md` *(this file)* | Governs how I act in this repo. Zero `{{}}` tokens. |
| **Consumer instruction stubs** | `template/instructions/` | Path-scoped stubs with `{{}}` tokens; resolved during consumer setup. |
| **Consumer prompt stubs** | `template/prompts/` | Slash command prompts with `{{}}` tokens; resolved during consumer setup. |
| **Developer instruction files** | `.github/instructions/` | Resolved path-stubs for this repo — no `{{}}` tokens. |
| **Developer prompts** | `.github/prompts/` | Resolved prompts for this repo — no `{{}}` tokens. |
| **Template artefacts** | `template/skills/`, `template/hooks/`, `template/workspace/` | Delivered verbatim; must stay in parity with `.github/skills/`, `.github/hooks/`. |
| **Model-pinned agents** | `.github/agents/` | Fetched directly by `SETUP.md` §2.5. No `template/agents/` mirror exists — deliberate exception. Agents contain no `{{}}` tokens and change rarely; maintaining a separate mirror would add CI overhead with no practical benefit. |
| **Starter kits** | `starter-kits/` | VS Code agent plugin bundles per language/stack. Installed to consumer's `.github/starter-kits/` during setup based on detected stack. No `{{}}` tokens — delivered verbatim like agents. |

**Invariant**: `.github/instructions/` and `.github/prompts/` must never contain `{{PLACEHOLDER}}` tokens.
**Invariant**: `template/` files must never contain resolved project-specific values.
**Note**: `.github/agents/` is the only verbatim-delivered artefact that lacks a `template/` mirror. This is intentional — see Architecture table above.

## Key Commands

| Task | Command |
|------|---------|
| Run all tests | `bash tests/run-all.sh` |
| Type check | `echo "no type check configured"` |
| Sync version | `bash scripts/sync-version.sh` |
| Sync workspace-index | `bash scripts/sync-workspace-index.sh --check` |
| LOC count | `find . \( -name '*.sh' -o -name '*.md' \) -not -path './node_modules/*' \| xargs wc -l \| tail -1` |

Run `bash tests/run-all.sh` before marking any task done.

## Coding Conventions

- Language: **Markdown / Shell** · Runtime: **bash** · Package manager: **N/A**
- Test framework: **bash (custom shell test scripts)**
- Preferred serialisation: **JSON**
- Shell scripts: `set -euo pipefail` required.
- Hook scripts: JSON in on stdin → JSON on stdout (stdio protocol).
- Markdown: follow `.markdownlint.json` / `.markdownlint-cli2.yaml`.
- No silent error swallowing — log or re-throw.
- No commented-out code — git history is the undo stack.
- Read before claiming — never describe or modify a file not opened this session.

## PDCA Cycle

Every non-trivial change:

1. **Plan** — state the goal, list files, estimate LOC delta.
2. **Do** — implement; write tests alongside.
3. **Check** — run `bash tests/run-all.sh`. Fix before continuing.
4. **Act** — address any baseline breach; summarise.

### Structured Thinking Discipline

Before acting on any medium-to-complex task:

1. **Frame** — state the problem in one sentence. Decompose if you cannot.
2. **Gather** — search once with broad terms. Do not repeat with minor variations.
3. **Decide** — choose an approach and commit. Do not oscillate between equal options.
4. **Act** — implement in one pass. Do not re-read files already read unless changed.
5. **Verify** — check once. On failure, diagnose root cause before retrying.

**Anti-loop rules** (all agents and subagents):

- **3-strike rule**: same tool call unhelpful 3 times → reformulate or ask user.
- **No circular re-reads**: do not re-read unchanged files within the same task.
- **Monotonic progress**: each step must produce new information or output.
- **Scope lock**: do not expand scope mid-task. Note new work for follow-up.
- **Time-box exploration**: max 5 tool calls per sub-question. Surface gaps to user.

## Baselines

| Baseline | Value |
|----------|-------|
| File LOC (warn) | 250 lines |
| File LOC (hard) | 400 lines |
| Dependency budget | 6 runtime deps |
| Max subagent depth | 3 |

## Critical Rules

- `template/copilot-instructions.md` must contain §1–§13 and ≤ 800 lines (CI enforced).
- `template/copilot-instructions.md` must contain ≥ 3 `{{PLACEHOLDER}}` tokens (CI enforced).
- `.github/copilot-instructions.md` *(this file)* must contain **zero** `{{}}` tokens (CI enforced).
- Parity: `.github/skills/` must mirror `template/skills/` (except `mcp-management`). `.github/hooks/` must mirror `template/hooks/` exactly. CI enforces.
- Version source of truth: `VERSION.md`. Run `bash scripts/sync-version.sh` after bumping — it updates `template/copilot-instructions.md` and `.release-please-manifest.json`.
- `workspace-index.json` must stay in sync: `bash scripts/sync-workspace-index.sh --write` then commit.

## File Inventory

| Path | Role |
|------|------|
| `template/copilot-instructions.md` | Consumer instructions template (placeholder version) |
| `template/skills/` | Consumer skill stubs |
| `template/hooks/` | Consumer hook scripts |
| `template/workspace/` | Consumer workspace identity stubs |
| `template/instructions/` | Consumer path-instruction stubs (with `{{}}` tokens) |
| `template/prompts/` | Consumer prompt stubs (with `{{}}` tokens) |
| `.github/agents/` | Model-pinned VS Code agents (Code, Review, Fast, Doctor, Setup, Researcher, Explore, Extensions, Security) |
| `.github/skills/` | Skill library (repo-live copies, mirrors template) |
| `.github/hooks/` | Hook scripts (repo-live copies, mirrors template) |
| `.github/instructions/` | Developer path-instructions (resolved, no `{{}}`) |
| `.github/prompts/` | Developer prompts (resolved, no `{{}}`) |
| `SETUP.md` | Consumer bootstrap protocol |
| `UPDATE.md` | Consumer update protocol |
| `AGENTS.md` | Machine entry point (trigger phrases, fetch URLs) |
| `MIGRATION.md` | Per-version migration registry |
| `tests/` | Test suite — `bash tests/run-all.sh` |
| `scripts/` | Utility scripts (sync-version, sync-workspace-index, sync-models, sync-template-parity, validate-agent-frontmatter, copilot\_audit) |
| `starter-kits/` | VS Code agent plugin starter kits per language/stack |
| `.copilot/workspace/` | Developer workspace identity files (incl. `RESEARCH.md` URL tracker) |

## Operating Modes

**Implement** (default): plan → implement → test → document.
**Review**: read-only; state findings before proposing fixes. Tag waste (W1–W16).
**Refactor**: no behaviour changes; tests pass before and after.
**Planning**: produce task breakdown before writing code.

## Waste Catalogue (Muda)

Tag review findings with these codes:

W1 Overproduction · W2 Waiting · W3 Transport · W4 Over-processing · W5 Inventory · W6 Motion · W7 Defects · W8 Unused talent · W9 Prompt waste · W10 Context window waste · W11 Hallucination rework · W12 Verification overhead · W13 Prompt engineering debt · W14 Model-task mismatch · W15 Tool friction · W16 Over/under-trust

## Skills and Agents

- Skills: `.github/skills/` — loaded on demand. Read `SKILL.md` when description matches task.
- Agents: `.github/agents/` — each pins a model.
- Tool Protocol: activate `.github/skills/tool-protocol/SKILL.md` before building any script.
- Heartbeat: `.copilot/workspace/HEARTBEAT.md` — run at session start, after >5 file changes, after task completion. Silent when healthy.

## User Preferences

- **Response**: Balanced — explain non-obvious decisions only.
- **Experience**: Intermediate — skip well-known patterns.
- **Mode**: Code quality > delivery speed. Flag tech debt.
- **Testing**: Tests alongside every change. Never submit without coverage.
- **Autonomy**: Act freely; pause before deleting, overwriting, or irreversible changes.
- **Refactoring**: Fix proactively. Tag waste category (W1–W16).
- **Reporting**: Narrative paragraph — what changed, decisions, follow-ups.
- **Self-editing**: Free to update this file. Report changes.
- **Global autonomy**: High (4). Pause for: deletions, overwrites, config changes, architecture.
- **Tone**: Professional only. No humour, emoji, or casual language.
- **MCP**: Full config. All 4 default servers. Suggest new MCP servers proactively.

## Graduated Trust Model

| Trust tier | Paths | Behaviour |
|-----------|-------|-----------|
| High | `tests/`, `*.md` | Act freely, summarise after |
| Standard | `scripts/`, `template/` | Describe plan, wait for approval |
| Guarded | `.github/`, `.vscode/`, `*.config.*` | Pause, explain in detail, wait for "go ahead" |

## Protocols

- **Tool Protocol**: Check `.copilot/tools/INDEX.md` before building. Follow `.github/skills/tool-protocol/SKILL.md`.
- **Skill Protocol**: Skills loaded on demand from `.github/skills/`. Follow `.github/skills/skill-management/SKILL.md`.
- **MCP Protocol**: Config in `.vscode/mcp.json`. Always-on: filesystem, git. Credentials-required: github, fetch.
- **Subagent depth**: max 3. Stop and surface to user if reached. Subagents inherit all protocols including the Structured Thinking Discipline and anti-loop rules.

*See also: `template/copilot-instructions.md` (consumer template) · `.github/agents/` · `.github/skills/` · `AGENTS.md` · `UPDATE.md` · `MIGRATION.md`*
