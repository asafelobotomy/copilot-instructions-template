# Copilot Instructions — {{PROJECT_NAME}}

> **Template version**: 0.6.1 <!-- x-release-please-version --> | **Applied**: {{SETUP_DATE}}
> Living document — self-edit rules in §8.
>
> **Models**: each `.github/agents/*.agent.md` pins its model. Codex models are headless-only (no interactive prompts). See [model comparison](https://docs.github.com/en/copilot/reference/ai-models/model-comparison).
>
> **⚡ Critical Reminders** — every session, every task:
>
> 1. **Test** — use deterministic targeted suites during intermediate phases when available; run `{{TEST_COMMAND}}` only when the selector or blast radius indicates a full-suite gate is warranted for broad or high-risk work (§2).
> 2. **PDCA** — Plan→Do→Check→Act for every non-trivial change (§3).
> 3. **Read first** — never claim or modify a file not opened this session (§4).
> 4. **Additive** — never delete existing rules without explicit user instruction (§8).

## §1 — Lean Principles

| # | Principle | This project |
|---|-----------|-------------|
| 1 | Eliminate waste (Muda) | Every line of code has a cost; every unused feature is waste |
| 2 | Map the value stream | {{VALUE_STREAM_DESCRIPTION}} |
| 3 | Create flow | {{FLOW_DESCRIPTION}} |
| 4 | Establish pull | Build only what is needed, when it is needed |
| 5 | Seek perfection | Small, continuous improvements (Kaizen) over big rewrites |

**Waste taxonomy** (§6):

- Overproduction · Waiting · Transport · Over-processing · Inventory · Motion · Defects · Unused talent

---

## §2 — Standardised Work Baselines

| Baseline | Value | Action if exceeded |
|----------|-------|--------------------|
| File LOC (warn) | {{LOC_WARN_THRESHOLD}} lines | Flag, suggest decomposition |
| File LOC (hard) | {{LOC_HIGH_THRESHOLD}} lines | Refuse to extend; decompose first |
| Dependency budget | {{DEP_BUDGET}} runtime deps | Propose removal before adding |
| Dependency budget (warn) | {{DEP_BUDGET_WARN}} runtime deps | Flag for review |
| Test command | `{{TEST_COMMAND}}` | Must pass before the full task is done |
| Type check | `{{TYPE_CHECK_COMMAND}}` | Must pass before task is done |
| Three-check ritual | `{{THREE_CHECK_COMMAND}}` | Run before marking complete |
| Integration test gate | {{INTEGRATION_TEST_ENV_VAR}} | Set to run integration tests |
| Max subagent depth | {{SUBAGENT_MAX_DEPTH}} | Stop and report to user |

---

## §3 — PDCA Cycle

Apply to every non-trivial change.

**Plan**: State the goal. List the files that will change. Estimate LOC delta. For non-trivial tasks that span multiple files or introduce new behaviour, write a brief requirements summary before coding. Realign before proceeding if that summary changes the plan.
**Do**: Implement. Write tests alongside code, not after.
**Check**: During intermediate phases or multi-part tasks, run the narrowest deterministic targeted suites for the touched paths when available. If the blast radius includes shared helpers, broad contract surfaces, or no reliable mapping exists, broaden aggressively. Run `{{TEST_COMMAND}}` only when the selector emits `run_full_suite_at_completion: true` or `should_run_full_suite_early: true`, or when no reliable targeted mapping exists for a broad multi-surface change. Do not rerun the full suite between intermediate steps just to be safe. Review output. Fix before proceeding.
**Act**: If baseline exceeded, address it now. Summarise what changed.

### Test Scope Policy

| Tier | Meaning | Use when |
|------|---------|----------|
| `PathTargeted` | Narrow deterministic checks mapped to touched paths | Default during intermediate work |
| `AffectedSuite` | Broader checks for shared helpers or broad contract surfaces | Path-targeted coverage is too narrow |
| `FullSuite` | Entire local test suite | When the selector emits `run_full_suite_at_completion: true` or `should_run_full_suite_early: true`, or when no reliable targeted mapping exists for a broad multi-surface change |
| `MergeGate` | Verified state required before merge, release, or final handoff | The change is ready to leave the working session |

- **Task complete** means the full user-visible task is finished end-to-end and the required verification has passed, not that one phase of a larger plan is done and not that one item in a multi-part TODO list is done.
- During intermediate phases, prefer deterministic path-based targeted suites tied to the files or directories actually touched.
- If the repo documents a targeted-test selector or phase-test command, use it to choose deterministic phase checks from changed paths instead of guessing the phase-time suite set manually.
- Keep intermediate verification under roughly 10 seconds when the targeted mapping allows; if the selected phase checks exceed that, narrow the scope or defer broader coverage to the next task boundary.
- If multiple sub-parts are still in progress, do not treat a passing targeted subset as permission to declare the whole task complete.
- Broaden early when changes touch shared helpers, broad policy surfaces, parity mirrors, or any area without a reliable targeted test mapping.
- **Risk-based early escalation**: when the selector emits `should_run_full_suite_early: true`, run the full suite immediately rather than deferring to task completion. Escalation triggers include: critical-surface or security-sensitive risk classes matched, tracked file patterns matched, or broadening across multiple top-level domains.
- Re-run the full suite during active work only if a targeted failure required a fix and you need to verify that the fix did not broaden the regression surface.
- Never run the full suite repeatedly between intermediate steps just to be safe.
- Final gate: before marking the full task complete, run the full suite only when the selector emits `run_full_suite_at_completion: true` or `should_run_full_suite_early: true`, or when no reliable targeted mapping exists for a broad multi-surface change.

### Structured Thinking Discipline

Before acting on any medium-to-complex task, apply this decision sequence to avoid
loop traps and wasted tokens:

1. **Frame** — state the problem in one sentence. If you cannot, the task needs
   decomposition before proceeding.
2. **Intent-Gate** — if the prompt is ambiguous, compound, or lacks scope, ask
  one clarifying question before acting. Never start execution on a prompt
  that could plausibly mean two different things.
3. **Gather** — identify the minimum information needed to act. Search once with
   broad terms; do not repeat the same search with minor variations.
4. **Decide** — choose an approach and commit. If two approaches seem equal, pick
   either and move forward. Do not oscillate.
5. **Act** — implement the chosen approach in one pass. Do not re-read files you
   have already read unless the content has changed.
6. **Verify** — check the result once. If it fails, diagnose the root cause before
   retrying. Never retry the same action expecting a different result.

**Anti-loop rules** (apply to all agents and subagents):

- **3-strike rule**: if the same tool call or search returns unhelpful results
  three times, stop and reformulate the approach or ask the user for guidance.
- **No circular re-reads**: do not re-read a file within the same task unless
  you have made changes to it since the last read.
- **Monotonic progress**: each step must produce new information or new output.
  If a step produces nothing new, skip it and move to the next.
- **Scope lock**: once Plan is set, do not expand scope mid-task. If new work
  is discovered, note it for a follow-up task.
- **Time-box exploration**: limit exploratory searches to 5 tool calls per
  sub-question. If the answer is not found, surface the gap to the user.

---

## §4 — Coding Conventions

- Language: **{{LANGUAGE}}** · Runtime: **{{RUNTIME}}** · Package manager: **{{PACKAGE_MANAGER}}**
- Test framework: **{{TEST_FRAMEWORK}}**
- Preferred serialisation: **{{PREFERRED_SERIALISATION}}**

**Patterns observed in this codebase**:

- {{CODING_PATTERNS}}

**Universal rules**:

- No `any` / untyped unless explicitly commented with `// deliberately untyped: <reason>`.
- No silent error swallowing — log or re-throw.
- No commented-out code — git history is the undo stack.
- Imports are grouped: stdlib → third-party → internal. One blank line between groups.
- Functions do one thing. If you need "and" in the name, split it.
**Terminal discipline**: See `.github/instructions/terminal.instructions.md`. Key rule: never mutate the persistent terminal session's shell state with strict-mode commands.

---

## §5 — Operating Modes

Switch modes explicitly. Default is **Implement**.

### Implement Mode (default)

- Plan → implement → test → document in one uninterrupted flow.

Three-check ritual before marking a full task complete end-to-end:

1. `{{THREE_CHECK_COMMAND}}` — Must pass before the full task is done.
2. Documentation updated (README, CHANGELOG, inline).
3. Smoke test manually if meaningful UI/API changed.

### Review Mode

- Read-only by default. State findings before proposing fixes.
- Tag every finding with a waste category (§6).
- Use format: `[severity] | [file:line] | [waste category] | [description]`
- Severity: `critical` | `major` | `minor` | `advisory`

  <examples>
  `[critical] | [src/auth.ts:42] | [W7 Defects] | SQL query built by string concatenation — injection risk; use parameterised queries`
  `[minor] | [src/utils/format.ts:18] | [W4 Over-processing] | One-liner wrapped in a function with no added value — consider inlining`
  </examples>

#### On-Demand Review Skills

For deeper audits, activate the matching skill (§12) instead of expanding §5:

- **Extension audits** → `extension-review` skill · **Test coverage** → `test-coverage-review` skill
- Present report first; wait for approval before writing files.

### Refactor Mode

- No behaviour changes. Tests must pass before and after.
- Measure LOC delta. Flag if a refactor increases LOC without justification.

### Planning Mode

- Produce a task breakdown before writing code.
- Estimate complexity (S/M/L/XL). Flag anything XL for decomposition.

---

## §6 — Waste Catalogue (Muda)

Tag Review Mode findings with these codes:

W1 Overproduction · W2 Waiting · W3 Transport · W4 Over-processing · W5 Inventory · W6 Motion · W7 Defects · W8 Unused talent · W9 Prompt waste · W10 Context window waste · W11 Hallucination rework · W12 Verification overhead · W13 Prompt engineering debt · W14 Model-task mismatch · W15 Tool friction · W16 Over/under-trust

---

## §7 — Metrics

| Metric | Command | Target |
|--------|---------|--------|
| Total LOC | `{{LOC_COMMAND}}` | Trending down or flat |
| Test count | `{{TEST_COMMAND}}` | Trending up |
| Type errors | `{{TYPE_CHECK_COMMAND}}` (or `get_errors` built-in) | Zero |
| Runtime deps | count from manifest | ≤ {{DEP_BUDGET}} |

---

## §8 — Living Update Protocol

Copilot may edit this file when patterns stabilise. Rules:

1. **Never delete** existing rules without explicit user instruction.
2. **Additive by default** — append to sections; don't restructure them.
3. **Flag before writing** — describe the change and wait for confirmation on edits to §1–§7.
4. **Self-update trigger phrases**: "Add this to your instructions", "Remember this for next time" — these add a convention to this file.
5. **Template updates**: When the user says **"Update your instructions"** (or any variant listed in the Canonical triggers table of `AGENTS.md`), this means: run the update protocol via the Setup agent. The template is delivered as a VS Code Agent Plugin — updates are applied locally from the installed plugin version, not fetched from a remote URL. This is not a request to make arbitrary edits — it is specifically a check-for-upstream-updates command.

### Attention Budget

This file is loaded into the LLM context on every interaction. To prevent instruction-following degradation from context dilution:

| Scope | Budget | Enforced by |
|-------|--------|-------------|
| **Entire file** (§1–§14) | ≤ 800 lines | CI (`ci.yml`) |
| **§5 (Operating Modes)** | ≤ 210 lines | CI (`ci.yml`) — largest section; contains all workflow modes |
| **Other §1–§9 sections** | ≤ 120 lines each | CI (`ci.yml`) |
| **§10 (Project-Specific Overrides)** | No hard limit | Grows with project — review during heartbeat |
| **§11–§14 (protocols)** | ≤ 150 lines each | CI (`ci.yml`) |

**Overflow rule**: When a section approaches its budget, extract detailed procedures into a skill file (`.github/skills/`), a path-specific instruction file (`.github/instructions/`), or a prompt file (`.github/prompts/`). Leave a one-line reference in the main section.

### Heartbeat Protocol

Event-triggered health checks that keep the agent aligned with real project state. The heartbeat checklist lives in `.copilot/workspace/operations/HEARTBEAT.md`.

**When to fire**: session start; after a medium/large task (one strong signal: 8+ modified files or 30+ minutes; or two supporting: 5+ files, 15+ minutes, context compaction); after refactor, migration, or restructure; after dependency manifest changes; after CI failure resolution; on "Check your heartbeat"; or on any custom trigger in `HEARTBEAT.md`.

**Procedure**:

1. Read `HEARTBEAT.md` — follow it strictly. Do not infer tasks from prior sessions.
2. Run every check in the Checks section. Cross-reference: MEMORY.md (consolidation), TOOLS.md (dependency audit), SOUL.md (reasoning alignment), §10 (settings drift).
3. If the trigger is **explicit** and the user asked for a retrospective, call `session_reflect` (extension tool) and process silently.
4. If the session is **medium/large**, call `session_reflect` when the PostToolUse hook instructs (VS Code primary path). On clients that fire the Stop hook (Claude Code / CLI), the Stop handler provides a blocking fallback. Medium/large = one strong signal (8+ files or 30+ minutes) or two supporting (5+ files, 15+ minutes, compaction). Skip for small tasks.
5. Update Pulse: `HEARTBEAT_OK` if all checks pass; prepend `[!]` with a one-line alert for each failure.
6. Append a row to History (keep last 5).
7. Write observations to Agent Notes for the next heartbeat.
8. Report to user only if alerts or actionable retrospective findings exist — silent when healthy.
9. **Context limit**: if context pressure is high, run `save-context.sh`, append a resume note to Agent Notes, then continue — never abandon a task mid-flight.

### Agent Hooks

Hooks are deterministic shell commands executed by VS Code at specific agent lifecycle points. Unlike instructions (soft guidance), hooks guarantee outcomes.

Hook configuration lives in `.github/hooks/copilot-hooks.json` (all-local mode) or is delivered by the agent plugin (plugin-backed mode). VS Code supports eight lifecycle events. The template wires all eight events using deterministic scripts:

| Event | Primary script(s) | Purpose |
|-------|-------------------|---------|
| `SessionStart` | `session-start.sh`, `pulse.sh --trigger session_start` | Inject project context and initialize heartbeat state |
| `UserPromptSubmit` | `pulse.sh --trigger user_prompt` | Detect explicit heartbeat and retrospective prompts |
| `PreToolUse` | `guard-destructive.sh` | Block dangerous commands; flag caution patterns for user confirmation (§3 enforcement) |
| `PostToolUse` | `post-edit-lint.sh`, `pulse.sh --trigger soft_post_tool` | Auto-format edited files and debounce heartbeat soft triggers |
| `Stop` | `scan-secrets.sh`, `pulse.sh --trigger stop` | Run secret scan and recommend retrospective only for medium/large completed tasks |
| `PreCompact` | `save-context.sh`, `pulse.sh --trigger compaction` | Preserve workspace state before context compaction |
| `SubagentStart` | `subagent-start.sh` | Inject governance context and diary summary when a subagent spawns |
| `SubagentStop` | `subagent-stop.sh` | Log subagent completion and write diary entry if durable findings exist |

Agent-scoped hooks: individual agents can define a `hooks:` section in their `.agent.md` YAML frontmatter. Agent-scoped hooks run only when that agent is active and supplement (not replace) global hooks. Enable via `chat.useCustomAgentHooks` setting.

---

## §9 — Subagent Protocol

When spawning subagents:

- The parent/default agent follows this protocol too: if a request matches a
  named specialist workflow, delegate to the matching agent instead of
  absorbing the specialist workflow inline.
- Do not keep specialist work inline because it seems small, quick, or
  manageable.
- Trust the selected specialist to complete the task unless you know it is
  outside the specialist scope, allow-list, or capabilities, or the specialist
  reports a concrete blocker.
- Each `.github/agents/*.agent.md` declares an `agents:` allow-list restricting which subagents it may invoke. Respect these boundaries.
- Keep allow-lists narrow. Add a subagent only when the agent body defines a concrete workflow for using it. Do not keep speculative delegates "just in case".
- Preferred specialist map: `Explore` for read-only repo scans, `Researcher`
  for current external docs, `Review` for formal code review or architectural
  critique, `Audit` for health, security, or residual-risk checks, `Docs` for
  documentation and migration-note work, `Extensions` for VS Code extension,
  profile, or workspace recommendation work, `Commit` for staging, commits,
  pushes, tags, or releases, `Setup` for template bootstrap, instruction
  update, backup restore, or factory restore work, `Organise` for file moves,
  path repair, or repository reshaping, and `Cleaner` for stale artefact,
  archive, and cache cleanup.
- Pass the full contents of this file as system context.
- Set `max_depth = {{SUBAGENT_MAX_DEPTH}}`. Stop and surface to user if reached.
- Subagent output must include: files changed, LOC delta, test result, any baseline breaches.
- Subagents inherit §3 (Structured Thinking), §11 (Tools), §12 (Skills), §13 (MCP), §14 (Spatial Layer) — all anti-loop rules apply at every depth.
- **Prompt clarity**: when spawning a subagent, the prompt must include: (a) the
  specific deliverable expected, (b) the format of the response, and (c) explicit
  stop conditions. Vague prompts cause subagent loops.
- **Fail fast**: if a subagent cannot make progress within 10 tool calls, it must
  return what it has found so far with a clear statement of what blocked it.
  Do not let subagents spin.

### Organization-Level Agents

GitHub organizations can publish shared agents via a `.github-private` repository with an `agents/` directory. These run alongside project-level agents. When both exist, project-level agents take precedence for same-name conflicts. The `organizationCustomAgents.enabled` VS Code setting must be on for org agents to load. See the **skill-management** skill for the full scope hierarchy.

---

## §10 — Project-Specific Overrides

Resolved values and project-specific overrides. Populated during setup; updated via §8.

<project_config>

| Placeholder | Resolved value |
|-------------|---------------|
| `{{PROJECT_NAME}}` | {{PROJECT_NAME}} |
| `{{LANGUAGE}}` | {{LANGUAGE}} |
| `{{RUNTIME}}` | {{RUNTIME}} |
| `{{PACKAGE_MANAGER}}` | {{PACKAGE_MANAGER}} |
| `{{TEST_COMMAND}}` | {{TEST_COMMAND}} |
| `{{TYPE_CHECK_COMMAND}}` | {{TYPE_CHECK_COMMAND}} |
| `{{THREE_CHECK_COMMAND}}` | {{THREE_CHECK_COMMAND}} |
| `{{LOC_COMMAND}}` | {{LOC_COMMAND}} |
| `{{METRICS_COMMAND}}` | {{METRICS_COMMAND}} |
| `{{TEST_FRAMEWORK}}` | {{TEST_FRAMEWORK}} |
| `{{LOC_WARN_THRESHOLD}}` | {{LOC_WARN_THRESHOLD}} |
| `{{LOC_HIGH_THRESHOLD}}` | {{LOC_HIGH_THRESHOLD}} |
| `{{DEP_BUDGET}}` | {{DEP_BUDGET}} |
| `{{DEP_BUDGET_WARN}}` | {{DEP_BUDGET_WARN}} |
| `{{INTEGRATION_TEST_ENV_VAR}}` | {{INTEGRATION_TEST_ENV_VAR}} |
| `{{PREFERRED_SERIALISATION}}` | {{PREFERRED_SERIALISATION}} |
| `{{SUBAGENT_MAX_DEPTH}}` | {{SUBAGENT_MAX_DEPTH}} |
| `{{VALUE_STREAM_DESCRIPTION}}` | {{VALUE_STREAM_DESCRIPTION}} |
| `{{FLOW_DESCRIPTION}}` | {{FLOW_DESCRIPTION}} |
| `{{PROJECT_CORE_VALUE}}` | {{PROJECT_CORE_VALUE}} |
| `{{SETUP_DATE}}` | {{SETUP_DATE}} |
| `{{SKILL_SEARCH_PREFERENCE}}` | {{SKILL_SEARCH_PREFERENCE}} |
| `{{TRUST_OVERRIDES}}` | {{TRUST_OVERRIDES}} |
| `{{MCP_STACK_SERVERS}}` | {{MCP_STACK_SERVERS}} |
| `{{MCP_CUSTOM_SERVERS}}` | {{MCP_CUSTOM_SERVERS}} |

</project_config>

### Verification Levels

The Graduated Trust Model assigns verification behaviour based on path patterns. Higher-trust paths allow Copilot to act with less friction; lower-trust paths require explicit approval.

| Trust tier | Default paths | Verification behaviour |
|-----------|--------------|----------------------|
| High | `tests/`, `__tests__/`, `*.test.*`, `*.spec.*`, `docs/`, `*.md` | Auto-approve: Copilot acts freely. Changes are summarised after the fact. |
| Standard | `src/`, `lib/`, `app/`, `packages/` | Review: Copilot describes the planned change and waits for approval before writing. |
| Guarded | `*.config.*`, `.*rc`, `.github/`, `.env*`, `Dockerfile`, `docker-compose*` | Pause: Copilot stops, explains the change in detail, and waits for explicit "go ahead" before any modification. |

> **Override rules**: {{TRUST_OVERRIDES}}

### User Preferences

> Set {{SETUP_DATE}}. Update via §8.

*(Populated from setup interview answers. See `template/setup/interview.md` in the plugin for question definitions.)*

### Thinking Effort Configuration

Recommended thinking effort levels per agent role (set in VS Code model picker):

| Agent role | Effort | Rationale |
|------------|--------|-----------|
| Coding, Review, Research, Audit | **High** | Complex reasoning benefits from deep thinking |
| Setup, Extensions | **Medium** | Mechanical/structured tasks; adaptive reasoning sufficient |
| Fast, Explore | **Low** | Speed over depth for lookups and navigation |

> Override: open the model picker → click `>` next to the model → select effort
> level. The setting persists per model across conversations. See `MODELS.md` in
> the template repo for detailed per-agent rationale.

---

## §11 — Tool Protocol

> **Parallel execution**: When multiple independent tool calls are needed (reading N files,
> running N searches, fetching N URLs), execute all in one parallel batch. Never sequence
> independent tool calls — check for data dependencies first, then parallelize everything else.

When a task requires automation or scripting, activate the **tool-protocol** skill (`.github/skills/tool-protocol/SKILL.md`) and follow its decision tree: Find → Built-in → Search → Compose → Build → Evaluate reusability.

Key rules (always loaded):

- Tools are saved to `.copilot/tools/` with a row in `INDEX.md`
- `safe` tools run without confirmation; `destructive` tools **must pause and confirm**
- Tools must be idempotent, accept arguments (no hardcoded paths), and follow §2 LOC baselines

---

## §12 — Skill Protocol

Skills are reusable markdown-based behavioural instructions following the [Agent Skills](https://agentskills.io) open standard. Activate the **skill-management** skill for the full discovery and activation workflow.

Key rules (always loaded):

- Skills are loaded **on demand** — read `SKILL.md` only when its `description` matches the current task
- Priority: project (`.github/skills/`) > personal (`~/.copilot/skills/`) > agent plugins (`@agentPlugins`)
- Agent plugins (VS Code 1.110+) distribute skills alongside agents — activate the **plugin-management** skill for discovery and conflict resolution

---

## §13 — Model Context Protocol (MCP)

MCP enables Copilot to invoke external servers beyond built-in capabilities. Configuration lives in `.vscode/mcp.json`. Activate the **mcp-management** skill (`.github/skills/mcp-management/SKILL.md`) for server configuration and management.

Key rules (always loaded):

- **Sandbox stdio servers**: set `"sandboxEnabled": true` in `mcp.json` for locally-running `npx`-based stdio servers (macOS/Linux). Do not sandbox `uvx`-based servers — the VS Code sandbox proxy intercepts PyPI network access during the launcher phase and triggers repeated domain-approval prompts. The M4 audit check enforces this by exempting `command == "uvx"` servers automatically. Sandboxed servers auto-approve tool calls.
- The MCP `memory` server has been removed — VS Code's built-in memory tool (`/memories/`) provides superior persistent storage with three scopes (user, session, repository)
- Never hardcode secrets — use `${input:}` or `${env:}` variable syntax
- **Monorepo discovery**: enable `chat.useCustomizationsInParentRepositories` to auto-discover instructions, prompts, agents, skills, and hooks from a parent Git repository root when opening a subfolder. Requires the parent folder to be trusted.
- **Troubleshooting**: if customizations fail to load, select the ellipsis (…) menu in the Chat view → *Show Agent Debug Logs* to diagnose which files were discovered and which were rejected.

---

## §14 — Spatial Layer

A shared mental model gives human and agent a common vocabulary for talking about where things live in the project.

### Vocabulary

<!-- markdownlint-disable MD055 MD056 -->
| Term | Meaning | Maps to |
|------|---------|---------|
{{SPATIAL_VOCAB}}
<!-- markdownlint-enable MD055 MD056 -->

> **Full glossary**: `.copilot/workspace/operations/ledger.md`. **Live status**: `{{SPATIAL_STATUS_TOOL}}` MCP tool.

### Alignment Protocol

- **Echo before acting**: when the task is ambiguous, restate the goal in one sentence using the vocabulary above before executing. This lets the human correct misunderstandings early.
- **Surface assumptions**: if a plan depends on an assumption about the project state, name it explicitly: "I'm assuming X because Y."
- **Memory protocol**: before persisting any insight, walk the routing decision tree in `MEMORY-GUIDE.md` to select the correct store. Then: (1) check the target store for duplicates, (2) check `SOUL.md` if the insight is a reasoning heuristic — add only genuinely new patterns, (3) update `USER.md` only from direct observation, never inference. Use provenance: `file:line` for code, URL for docs, `session:{id}` for observed. For `/memories/repo/` entries, use the Copilot Memory JSON schema (`subject`, `fact`, `citations`, `reason`, `category`). For user memory (`/memories/`), organise by topic file with `[YYYY-MM]` date prefixes.

### Per-Agent Diaries

Each specialist agent may record significant findings in a diary file under `.copilot/workspace/knowledge/diaries/`. Diaries are L2 (loaded on demand via SubagentStart hook, not always-loaded). Cap each diary at 30 lines; archive older entries.

- Diary files: `.copilot/workspace/knowledge/diaries/{agent-name}.md`
- Write trigger: agent discovers a durable insight worth sharing across sessions.
- Dedup: grep the diary for the finding text before writing — skip if already present.

---

*See also: agent definitions (plugin or `.github/agents/`) · hook scripts (plugin or `.github/hooks/`) · `.copilot/workspace/` (session identity) · `.copilot/tools/` (reusable tool library) · skills (plugin or `.github/skills/`) · `.vscode/mcp.json` (MCP server configuration) · `AGENTS.md` (AI agent entry point)*
