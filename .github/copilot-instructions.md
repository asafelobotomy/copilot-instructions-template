# Developer Instructions — copilot-instructions-template

> Role: AI developer for this repository. Template version: 0.7.0 <!-- x-release-please-version --> | Updated: 2026-04-27
>
> **⚡ Critical Reminders** — every session, every task:
>
> 1. **Test** — use deterministic targeted suites during intermediate phases; run `bash tests/run-all.sh` only when the selector or blast radius indicates a full-suite gate is warranted for broad or high-risk work.
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
| **Consumer template** | `template/copilot-instructions.md` | Delivered to consumers by the Setup agent. Contains `{{PLACEHOLDER}}` tokens. |
| **Developer instructions** | `.github/copilot-instructions.md` *(this file)* | Governs how I act in this repo. Zero `{{}}` tokens. |
| **Consumer instruction stubs** | `template/instructions/` | Path-scoped stubs; most are delivered verbatim, a subset contain `{{}}` tokens resolved during consumer setup. |
| **Consumer prompt stubs** | `template/prompts/` | Slash command prompts; most are delivered verbatim, a subset contain `{{}}` tokens resolved during consumer setup. |
| **Developer instruction files** | `.github/instructions/` | Resolved path-stubs for this repo — no `{{}}` tokens. |
| **Developer prompts** | `.github/prompts/` | Resolved prompts for this repo — no `{{}}` tokens. |
| **Template artefacts** | `template/workspace/` | Delivered verbatim by Setup agent. Skills and hooks are now plugin components delivered in `skills/` and `hooks/` at repo root. |
| **Plugin root** | `agents/`, `skills/`, `hooks/` | VS Code Agent Plugin components discovered at repo root. Delivered to consumers via plugin install. |
| **Starter kits** | `starter-kits/` | VS Code agent plugin bundles per language/stack. Installed to consumer's `.github/starter-kits/` during setup based on detected stack. No `{{}}` tokens — delivered verbatim like agents. |

**Invariant**: `.github/instructions/` and `.github/prompts/` must never contain `{{PLACEHOLDER}}` tokens.
**Invariant**: `template/` files must never contain resolved project-specific values.
**Note**: `starter-kits/` are deliberate verbatim-delivered exceptions that lack `template/` mirrors. This is intentional — see Architecture table above.
**Note**: Developer workspace discovers repo-root `agents/` via `chat.agentFilesLocations` and repo-root `skills/` via both `chat.skillsLocations` and legacy `chat.agentSkillsLocations` in `.vscode/settings.json`. Developer hooks are loaded by VS Code from `.github/hooks/copilot-hooks.json`; the plugin delivers `hooks/hooks.json` as its own component — both files are kept in sync. No `.github/agents/` directory is needed in this repo. `.github/skills/` is the consumer-facing skill delivery path referenced by `.plugin/plugin.json` and `.claude-plugin/plugin.json` — keep it in sync with any significant changes to root `skills/`.
**Note**: The repo now ships both OpenPlugin and Claude-format root plugin manifests for executable hook/MCP packaging: `.plugin/*` uses `${PLUGIN_ROOT}` and `.claude-plugin/*` uses `${CLAUDE_PLUGIN_ROOT}`. The root `plugin.json` (VS Code Copilot format) intentionally contains only `agents` and `skills` — do NOT add `hooks` or `mcpServers` to it. VS Code Copilot plugin format has no plugin-root token, so hook/MCP executable paths cannot be resolved; doing so produces errors like `/hooks/scripts/...` immediately on plugin install.

## Key Commands

| Task | Command |
|------|---------|
| Run all tests | `bash tests/run-all.sh` |
| Run all tests (captured) | `bash scripts/harness/run-all-captured.sh` |
| Select targeted tests | `bash scripts/harness/select-targeted-tests.sh <paths...>` |
| Type check | `echo "no type check configured"` |
| Verify release-managed versions | `bash scripts/release/verify-version-references.sh` |
| Sync workspace-index | `bash scripts/workspace/sync-workspace-index.sh --check` |
| LOC count | `find . \( -name '*.sh' -o -name '*.md' \) -not -path './node_modules/*' \| xargs wc -l \| tail -1` |

Run deterministic targeted suites during intermediate phases when the repo has a reliable path-to-test mapping. Run `bash tests/run-all.sh` only when the selector emits `run_full_suite_at_completion: true` or `should_run_full_suite_early: true`, or when no reliable targeted mapping exists for a broad multi-surface change. Do not rerun the full suite between intermediate steps just to be safe.

**`execution_subagent` cwd**: The subagent does not inherit the current shell directory. Always embed the absolute repo path inside the command string (`cd /mnt/SteamLibrary/git/copilot-instructions-template && <cmd>`), not just in the prose description. For single final-gate commands where full output matters, use `run_in_terminal` instead.

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

**Terminal discipline**: See `.github/instructions/terminal.instructions.md` (loaded automatically for shell files). The following rules apply regardless of file type:

- Prefer `execution_subagent` or synchronous `run_in_terminal` over async+poll for any command that will finish on its own. Reserve async sessions for genuinely persistent processes (servers, watchers).
- `get_terminal_output` and `send_to_terminal` accept `id` for async `run_in_terminal` sessions and `terminalId` for visible foreground terminals. `kill_terminal` still accepts only the async `id` UUID.
- If `get_terminal_output` returns "command not found", the call used an invalid ID. Discard the result and re-run with `execution_subagent` or synchronous `run_in_terminal`.
- Background terminal notifications are enabled by default, so polling loops and sleep-based checks are wasted work.

## PDCA Cycle

Every non-trivial change:

1. **Plan** — state the goal, list files, estimate LOC delta, and for non-trivial work write a brief requirements summary before coding. If that summary changes the plan, realign first.
2. **Do** — implement; write tests alongside.
3. **Check** — during intermediate phases or multi-part tasks, run the narrowest deterministic targeted suites for the touched paths when available. If the blast radius includes shared helpers, broad contract surfaces, or no reliable mapping exists, broaden aggressively. Run `bash tests/run-all.sh` only when the selector emits `run_full_suite_at_completion: true` or `should_run_full_suite_early: true`, or when no reliable targeted mapping exists for a broad multi-surface change. Do not rerun the full suite between intermediate steps just to be safe. Fix before continuing.
4. **Act** — address any baseline breach; summarise.

### Test Scope Policy

| Tier | Meaning | Use when |
|------|---------|----------|
| `PathTargeted` | Narrow deterministic checks mapped to touched paths | Default during intermediate work |
| `AffectedSuite` | Broader checks for shared helpers or broad contract surfaces | Path-targeted coverage is too narrow |
| `FullSuite` | Entire local test suite | When the selector emits `run_full_suite_at_completion: true` or `should_run_full_suite_early: true`, or when no reliable targeted mapping exists for a broad multi-surface change |
| `MergeGate` | Verified state required before merge, release, or final handoff | The change is ready to leave the working session |

- **Task complete** means the full user-visible task is finished end-to-end and the required verification has passed, not that one phase of a larger plan is done and not that one item in a multi-part TODO list is done.
- During intermediate phases, prefer deterministic path-based targeted suites tied to the files or directories actually touched.
- Use `bash scripts/harness/select-targeted-tests.sh <paths...>` to choose deterministic phase checks from changed paths when the mapping exists.
- Keep intermediate verification under roughly 10 seconds when the targeted mapping allows; if the selected phase checks exceed that, narrow the scope or defer broader coverage to the next task boundary.
- If multiple sub-parts are still in progress, do not treat a passing targeted subset as permission to declare the whole task complete.
- Broaden early when changes touch shared helpers, broad policy surfaces, parity mirrors, or any area without a reliable targeted test mapping.
- **Risk-based early escalation**: when the selector emits `should_run_full_suite_early: true`, run the full suite immediately rather than deferring to task completion. Escalation triggers include: critical-surface or security-sensitive risk classes matched, tracked file patterns matched, or broadening across multiple top-level domains.
- Re-run the full suite during active work only if a targeted failure required a fix and you need to verify that the fix did not broaden the regression surface.
- Never run the full suite repeatedly between intermediate steps just to be safe.
- Final gate: before marking the full task complete, run the full suite only when the selector emits `run_full_suite_at_completion: true` or `should_run_full_suite_early: true`, or when no reliable targeted mapping exists for a broad multi-surface change.

### Structured Thinking Discipline

Before acting on any medium-to-complex task:

1. **Frame** — state the problem in one sentence. Decompose if you cannot.
2. **Intent-Gate** — if the prompt is ambiguous, compound, or lacks scope, ask one clarifying question before acting. Never start execution on a prompt that could plausibly mean two different things.
3. **Gather** — search once with broad terms. Do not repeat with minor variations.
4. **Decide** — choose an approach and commit. Do not oscillate between equal options.
5. **Act** — implement in one pass. Do not re-read files already read unless changed.
6. **Verify** — check once. On failure, diagnose root cause before retrying.

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

## Critical Rules

- `template/copilot-instructions.md` must contain §1–§14 and ≤ 800 lines (CI enforced).
- `template/copilot-instructions.md` must contain ≥ 3 `{{PLACEHOLDER}}` tokens (CI enforced).
- `.github/copilot-instructions.md` *(this file)* must contain **zero** `{{}}` tokens (CI enforced).
- Parity: `.github/instructions/` and `.github/prompts/` must stay in sync with `template/instructions/` and `template/prompts/`. CI enforces.
- Version source of truth: `VERSION.md`. Version bumps are done locally. Bump `VERSION.md` and all `x-release-please-version` markers together, then verify with `bash scripts/release/verify-version-references.sh`. CI creates a GitHub release when `VERSION.md` changes.
- `workspace-index.json` must stay in sync: `bash scripts/workspace/sync-workspace-index.sh --write` then commit.

## File Inventory

| Path | Role |
|------|------|
| `template/copilot-instructions.md` | Consumer instructions template (placeholder version) |
| `template/workspace/` | Consumer workspace identity stubs |
| `template/instructions/` | Consumer path-instruction stubs (most verbatim; subset with `{{}}` tokens) |
| `template/prompts/` | Consumer prompt stubs (most verbatim; subset with `{{}}` tokens) |
| `agents/` | Model-pinned VS Code agents (Setup, Code, Organise, Review, Fast, Audit, Explore, Extensions, Researcher, Commit, Debugger, Docs, Planner, Cleaner) |
| `skills/` | Skill library — plugin component, auto-discovered by VS Code |
| `hooks/hooks.json` | Plugin-level hook config (Copilot format, `${CLAUDE_PLUGIN_ROOT}` paths) |
| `hooks/scripts/` | Hook scripts delivered via plugin |
| `.github/instructions/` | Developer path-instructions (resolved, no `{{}}`) |
| `.github/prompts/` | Developer prompts (resolved, no `{{}}`) |
| `AGENTS.md` | Machine entry point (trigger phrases, fetch URLs) |
| `CHANGELOG.md` | Version history and migration notes |
| `tests/` | Test suite — `bash tests/run-all.sh` |
| `scripts/` | Utility scripts (sync-workspace-index, sync-models, validate-agent-frontmatter, copilot\_audit) |
| `starter-kits/` | VS Code agent plugin starter kits per language/stack |
| `.copilot/workspace/` | Developer workspace files — `identity/`, `knowledge/`, `operations/`, `runtime/` (gitignored) |

## Operating Modes

**Implement** (default): plan → implement → test → document.
**Review**: read-only; state findings before proposing fixes. Tag waste (W1–W16).
**Refactor**: no behaviour changes; tests pass before and after.
**Planning**: produce task breakdown before writing code.

## Waste Catalogue (Muda)

Tag review findings with these codes:

W1 Overproduction · W2 Waiting · W3 Transport · W4 Over-processing · W5 Inventory · W6 Motion · W7 Defects · W8 Unused talent · W9 Prompt waste · W10 Context window waste · W11 Hallucination rework · W12 Verification overhead · W13 Prompt engineering debt · W14 Model-task mismatch · W15 Tool friction · W16 Over/under-trust

## Skills and Agents

- Skills: `skills/` — loaded on demand. Read `SKILL.md` when description matches task.
- Agents: `agents/` — each pins a model.
- Main/default agent delegation: when the request matches a named specialist
  workflow, delegate instead of absorbing the workflow inline.
- Do not keep specialist work inline because it seems small, quick, or
  manageable.
- Trust the selected specialist to complete the task unless you know it is
  outside the specialist scope, allow-list, or capabilities, or it
  reports a concrete blocker.
- Preferred specialist map: `Explore` for read-only repo scans, `Researcher`
  for current external docs, `Review` for formal code review or architectural
  critique, `Audit` for health, security, or residual-risk checks, `Docs` for
  documentation and migration-note work, `Extensions` for VS Code extension,
  profile, or workspace recommendation work, `Commit` for staging, commits,
  pushes, tags, or releases, `Setup` for template bootstrap, instruction
  update, backup restore, or factory restore work, `Organise` for file moves,
  path repair, or repository reshaping, and `Cleaner` for stale artefact,
  archive, and cache cleanup.
- Tool Protocol: activate `skills/tool-protocol/SKILL.md` before building any script.
- Heartbeat: `.copilot/workspace/operations/HEARTBEAT.md` — run at session start. Health digest emits on meaningful phase transitions and overlay changes, not a fixed tool-call cadence. On significant sessions (8+ files or 30+ active minutes), the PostToolUse hook instructs the model to call `asafelobotomy_session_reflect` autonomously. The Stop hook provides a blocking fallback on clients that support it (Claude Code / CLI). Silent when healthy.

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
- **MCP**: Full config. Default servers configured. Suggest new MCP servers proactively.

## Graduated Trust Model

| Trust tier | Paths | Behaviour |
|-----------|-------|-----------|
| High | `tests/`, `*.md` | Act freely, summarise after |
| Standard | `scripts/`, `template/` | Describe plan, wait for approval |
| Guarded | `.github/`, `.vscode/`, `*.config.*` | Pause, explain in detail, wait for "go ahead" |

## Protocols

- **Tool Protocol**: Check `.copilot/tools/INDEX.md` before building. Follow `skills/tool-protocol/SKILL.md`.
- **Skill Protocol**: Skills loaded on demand from `skills/`. Follow `skills/skill-management/SKILL.md`.
- **MCP Protocol**: Config in `.vscode/mcp.json`. Always-on: filesystem, git. Credentials-required: github, fetch.
- **Extension Protocol**: The `asafelobotomy.copilot-extension` provides LM tools directly (not via MCP). Exact callable names: `asafelobotomy_session_reflect`. Call them directly if already loaded; otherwise try `tool_search` once. If the tool is still unavailable, follow the documented local fallback. Declare unavailable only after the direct and deferred-load paths fail — never pre-emptively assume they are inactive. Diary tools (`write_diary`, `read_diaries`) are exposed via the MCP heartbeat server (`mcp_heartbeat_write_diary`, `mcp_heartbeat_read_diaries`) — not as extension LM tools.
- **Delegation Protocol**: See **Skills and Agents** for the full specialist-first delegation policy.
- **Subagent depth**: max 3. Stop and surface to user if reached. Subagents inherit all protocols including the Structured Thinking Discipline and anti-loop rules.

*See also: `template/copilot-instructions.md` (consumer template) · `agents/` · `skills/` · `AGENTS.md` · `CHANGELOG.md`*
