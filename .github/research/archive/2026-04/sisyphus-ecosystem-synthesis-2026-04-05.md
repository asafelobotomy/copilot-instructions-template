# Research: Sisyphus Ecosystem Synthesis — clawhip, oh-my-openagent, oh-my-claudecode, oh-my-codex

> Date: 2026-04-05 | Agent: Researcher | Status: complete
> Builds on: `.github/research/claw-code-2026-04-05.md` and `.github/research/supplemental-agent-patterns-2026-04-05.md`

## Summary

The four repos under study — `clawhip`, `oh-my-openagent` (OmO), `oh-my-claudecode` (OMC), and
`oh-my-codex` (OMX) — form a coherent **Sisyphus/OpenClaw ecosystem** built by the same author
(Yeachan-Heo) and collaborators. Together with `claw-code` (researched previously), they define a
complete autonomous coding workflow: agent executes → structured events route to human via Discord →
human steers asynchronously. Each repo is a real, deployed implementation (not vaporware), though
with varying maturity. The ecosystem is philosophically distinct from VS Code Copilot's customisation
model but shares several structural ideas. Six of those ideas translate cleanly into instruction-template
concerns; the rest are runtime/product concerns that should not be copied.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://github.com/Yeachan-Heo/clawhip> | clawhip README — architecture, event model, memory offload, plugin system |
| <https://github.com/Yeachan-Heo/clawhip/blob/main/ARCHITECTURE.md> | clawhip v0.4.0 architecture: MPSC queue, dispatcher, router, renderer, sink |
| <https://raw.githubusercontent.com/Yeachan-Heo/clawhip/main/docs/native-event-contract.md> | Canonical session.* event vocabulary and normalization contract |
| <https://github.com/code-yeongyu/oh-my-openagent> | oh-my-openagent README — Sisyphus orchestrator, IntentGate, hash-anchored edits, specialist agents |
| <https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/refs/heads/dev/docs/guide/installation.md> | OmO installation guide — provider flags, agent-specific model resolution, doctor verification |
| <https://github.com/Yeachan-Heo/oh-my-claudecode> | oh-my-claudecode README — Team pipeline, 29 agents, 32 skills, OpenClaw integration |
| <https://raw.githubusercontent.com/Yeachan-Heo/oh-my-claudecode/main/docs/REFERENCE.md> | OMC full reference — hooks system, skills scoping, env vars, stop callbacks |
| <https://github.com/Yeachan-Heo/oh-my-codex> | oh-my-codex README — OMX workflow layer, deep-interview, ralplan, ralph, team mode |

---

## Per-Repo Findings

### 1. clawhip

**What it is and what problem it solves:**
`clawhip` is a daemon-first Discord (and Slack) notification router with a typed event pipeline.
It solves the problem of coupling autonomous agent CLIs to human attention channels: rather than
having each agent send its own platform notifications, agents emit structured `session.*` events;
clawhip normalises, routes, and formats them. It is the single human-notification surface for
the Sisyphus ecosystem.

**Actual scope vs. marketing:**
Fully implemented and deployed. v0.4.0 ships: MPSC queue architecture with typed event families;
Git/GitHub/tmux monitors as event sources; a router with multi-delivery (0..N deliveries per event);
renderer/sink separation (Discord REST + webhook sink); `clawhip memory init/status` for filesystem
memory scaffolds; a plugin system (`plugins/`) with shell bridge scripts per tool; and an install
lifecycle (`install.sh`, `clawhip install/update/uninstall`). There is no LLM in clawhip — it is
purely an event pipeline. The README is written as an operator spec that agents can follow directly.

**Key abstractions:**
- **Typed event families**: `session.*`, `git.*`, `github.*`, `tmux.*` — each dispatched through a
  shared Tokio MPSC queue
- **Canonical session vocabulary** (see §2A below): 10 canonical `session.*` event names plus 4
  legacy `agent.*` aliases; all upstream OMC/OMX events normalise to this set
- **Router multi-delivery**: a single event can match multiple `[[routes]]` rules; each route has
  a filter (tool, repo_name, branch, issue_number), sink, format (compact/alert/inline/raw), and
  optional mention
- **Renderer/sink separation**: message formatting is decoupled from transport; new sinks can be
  added without touching routing or rendering
- **Filesystem memory scaffold**: `MEMORY.md` is the hot pointer/index file; detailed memory lives
  in structured shards under `memory/` (daily shard, project shard, topic files, channel/agent
  shards). Bootstrap with `clawhip memory init`; inspect with `clawhip memory status`
- **Plugin bridge**: `plugins/{name}/bridge.sh` provides tool-specific shell hook entrypoints;
  `plugins/{name}/plugin.toml` holds metadata. Built-in plugins: `codex/`, `claude-code/`

**LLM interaction:** None directly. clawhip receives events FROM coding agents and routes them TO
humans. Its operator install spec is written to be executed by a coding agent (clone, run install.sh,
read SKILL.md, scaffold config, start daemon, verify).

**Genuinely reusable for this repo:**
- The `session.*` canonical event vocabulary: 10 names covering every agent lifecycle transition.
  This is a direct model for standardising `systemMessage` prefixes in our VS Code hook scripts.
- The MEMORY.md + memory-shards pattern: a hot index file pointing to detail-rich file shards.
  Our `.copilot/workspace/` identity files already use a similar structure informally.
- The filter-first routing model: prefer structured metadata (repo_name, branch, issue_number)
  over message-text matching. Applies to our hook routing logic and AGENTS.md trigger design.
- The "emit events then let the router own delivery" principle: direct notification from within
  an agent is deprecated in favour of emitting to clawhip. Maps to our hooks-as-event-emitters
  philosophy.

**Should NOT be copied:**
- The Rust daemon, Tokio MPSC infrastructure, Discord/Slack sinks — runtime product
- The tmux monitor, git poll source, GitHub webhook ingress — runtime product
- The cron scheduler pattern — runtime concern

---

### 2. oh-my-openagent (OmO)

**What it is and what problem it solves:**
A multi-model orchestration harness built on OpenCode/opencode shell. It solves the problem of
"how do you get an autonomous coding agent to produce production-quality work reliably" by adding
an intent-clarification gate, specialised agents, and a persistent completion loop.

**Actual scope vs. marketing:**
Substantially real. The marketing is ambitious ("Sisyphus does in 1 hour what Claude Code does in
7 days") and the testimonials are likely cherry-picked. The actual implemented scope includes:
19 named specialist agents (Sisyphus orchestrator, Hephaestus, Oracle, Librarian, Explore, plus
tier variants); IntentGate (intent analysis before task classification); hash-anchored edit tool
(LINE#ID content hash to prevent stale-line errors); LSP + AST-grep integration; background agent
parallelism; built-in MCPs (Exa, Context7, Grep.app); a Prometheus Planner (interview mode) and
a `/init-deep` auto-hierarchy generator. The `ultrawork` one-word entry point activates all agents.
The project is under active development and has real user adoption. Caution: the repo branch is
`dev`, not `main`, implying instability.

**Key abstractions:**
- **IntentGate**: analyses user intent before classifying or acting. Prevents literal
  misinterpretations of vague or compound requests. Equivalent to our "Frame" step in structured
  thinking but formalised as a gate that runs before any tool use.
- **Discipline agents**: Sisyphus orchestrates Hephaestus (execution), Oracle (GPT reasoning),
  Librarian (Z.ai research), Explore (read-only lookup) in parallel. Each agent has a specific
  tool set and context budget.
- **Hash-anchored edit tool**: every line change includes a LINE#ID content hash; stale-line
  errors are caught before they're applied. Addresses what the blog post calls "The Harness
  Problem" — agents editing wrong lines due to stale context.
- **Skill-embedded MCPs**: skills carry their own MCP server declarations; no global context bloat.
  A skill that needs web search includes an Exa MCP server spec inline.
- **Ralph Loop / `/ulw-loop`**: persistent completion loop that blocks on unfinished work item
  until verified done. Enforces that "done" means verified, not just "submitted".
- **TodoEnforcer**: watches agent idle states; if agent goes quiet with open todos, it is yanked
  back into the loop. Structurally enforces the "Act through completion" requirement.

**LLM interaction:** Multi-provider (Claude Max, GPT-5.4, Gemini, Kimi, GLM, MiniMax) with per-agent
fallback chains. Provider selection is agent-specific, not global. Installation flags map each agent
to the best available model in the operator's subscription stack. Background agent spawning keeps
context lean for the orchestrator.

**Genuinely reusable:**
- IntentGate concept → our "Frame" step in PDCA should be formalised as a gate: "if scope is
  unclear, clarify before delegating or executing; never start a complex task on a vague prompt"
- Skill-embedded MCPs → VS Code SKILL.md can reference MCP tool names; a skill that needs a
  specific tool should declare that requirement in its frontmatter
- Ralph/TodoEnforcer semantics → our existing "task complete = end-to-end" language should be
  strengthened: agents should block on incomplete verification loops, not mark tasks done silently
- Prometheus Planner → maps to our structured thinking "Decide" step: for large tasks, produce
  an explicit plan and confirm it before proceeding to write tooling calls

**Should NOT be copied:**
- OpenCode-specific architecture, subscription flag system, CLI flags — product concerns
- Hash-anchored edit tool — VS Code/Claude Code tool-layer implementation
- LSP/AST-grep integration — language-tooling concern
- Multi-provider subscription routing — product billing concern

---

### 3. oh-my-claudecode (OMC)

**What it is and what problem it solves:**
A Claude Code plugin that adds multi-agent orchestration, staged pipeline execution, specialist
agents, project-scoped skills, and async notification callbacks. Solves "how to get Claude Code
to tackle large, complex tasks reliably without constant human babysitting".

**Actual scope vs. marketing:**
Real, maintained product. The implementation includes: a staged pipeline (team-plan → team-prd →
team-exec → team-verify → team-fix loop); 29 named agents with tier variants; 32 skills; smart
model routing (Haiku for simple, Opus for complex/architecture); tmux CLI workers (real claude/
codex/gemini CLI processes in split panes); stop callbacks to Telegram/Discord/Slack when session
ends; OpenClaw gateway integration to forward session events to clawhip; rate-limit wait daemon;
HUD statusline; an auto-learner that extracts reusable patterns from sessions; and `/omc-doctor`
for install verification. Latest version: 4.4.0+. Package name confusion (oh-my-claudecode vs
oh-my-claude-sisyphus) is a real maintenance friction — noted.

**Key abstractions:**
- **Staged pipeline**: `team-plan → team-prd → team-exec → team-verify → team-fix` is the canonical
  execution surface. Each stage is a skill/agent that can be entered independently. This is the
  engineer-facing form of `PDCA` — explicit stages, explicit verification, explicit fix loop.
- **Project-scoped skills** (`.omc/skills/`) with frontmatter including trigger keywords:
  ```
  triggers: ["proxy", "aiohttp", "disconnected"]
  source: extracted
  ```
  Skills auto-inject when a trigger keyword appears in the session. User scope (`~/.omc/skills/`)
  has lower priority than project scope. This is more powerful than VS Code's `applyTo` glob —
  it uses semantic keyword matching.
- **Configuration precedence**: project `./.claude/CLAUDE.md` overrides global `~/.claude/CLAUDE.md`.
  `OMC_STATE_DIR` centralises state outside the worktree (survives worktree deletions).
  `DISABLE_OMC` / `OMC_SKIP_HOOKS` env vars allow clean opt-out.
- **Stop callbacks**: when a Claude Code session ends, OMC sends a structured notification to
  configured Telegram/Discord/Slack channels with tag lists. This is the async "human, your task
  is done" interface.
- **OpenClaw integration**: OMC emits `session.started` / `session.finished` events to a configured
  gateway URL; clawhip ingests them and routes to Discord. This is the production implementation of
  "agents emit structured events, router owns delivery".

**LLM interaction:** Plugin-based delegation to specialized agents based on task content. Background
agent firing keeps orchestrator context lean. Multi-provider CLI workers (codex/gemini in tmux).
Cost optimisation via tiered model routing. Stop hooks for session summary and notification.

**Genuinely reusable:**
- The team-plan→team-prd→team-exec→team-verify→team-fix pipeline as a named pattern to reference
  in our PDCA section (adds explicit PRD/requirements stage between Plan and Do)
- Project-scoped skill trigger keywords → VS Code's `applyTo` glob is the partial equivalent;
  document that skill descriptions should include trigger contexts for better auto-loading
- Stop callback integration as a pattern: the Stop hook in our repo can emit a structured JSON
  event to a configurable gateway URL for clawhip/OpenClaw routing
- Doctor verification command → `omx doctor` pattern maps to our heartbeat and audit flow
- `DISABLE_OMC` clean opt-out env var → our hooks should document a `DISABLE_COPILOT_HOOKS`
  escape hatch for CI or scripted contexts

**Should NOT be copied:**
- The Claude Code plugin infrastructure, npm package lifecycle, bun/Node.js dependency
- tmux CLI worker spawning — runtime product
- HUD statusline widget — terminal UX product
- Rate-limit wait daemon — Claude Code billing management
- Provider-specific fallback chains — product billing concern

---

### 4. oh-my-codex (OMX)

**What it is and what problem it solves:**
A workflow layer for OpenAI Codex CLI. It does not replace Codex; it adds structured intent
clarification, plan approval, persistent completion loops, and state persistence around it.

**Actual scope vs. marketing:**
Implemented and deployed. More opinionated and simpler than OMC. The implementation includes:
a `$deep-interview` Socratic clarification skill; `$ralplan` plan-approval skill; `$ralph` completion
loop; `$team` parallel execution via tmux; `.omx/` state directory for plans/logs/memory; `omx setup`
installer; `omx doctor` verification; `omx explore` (read-only Codex lookup); `omx sparkshell`
(bounded shell-native inspection); `omx hud --watch` (monitoring). The mental model is explicit:
"OMX adds better task routing + better workflow + better runtime to Codex." Not modelling itself as
a complete replacement.

**Key abstractions:**
- **`$deep-interview`**: Socratic clarification before execution. "If scope or boundaries are still
  vague, use deep-interview first." Surfaces hidden assumptions and measures clarity across weighted
  dimensions. This is the most directly translatable pattern for our repo.
- **`$ralplan`**: Plan approval gate. Produces an architecture and implementation plan, pauses for
  operator approval and tradeoff review before any code is written. Explicit alignment checkpoint.
- **`$ralph` (persistent completion)**: The task owner does not stop until the work is verified
  complete. On partial results, loops back into execution. Enforces "done means verified done".
- **`.omx/` state directory**: Plans live in `.omx/plans/`, logs in `.omx/logs/`, memory in
  `.omx/memory/`, mode tracking in `.omx/state/`. This is a documented convention, not ad hoc.
  `OMX_STATE_DIR` env var can move it outside the worktree.
- **Explore + sparkshell separation**: `omx explore` is read-only (safe); `omx sparkshell` runs
  bounded shell inspection. This mirrors our trusted/guarded access model.
- **Doctor pattern**: `omx doctor` verifies system state, config, tools, and model resolution on
  demand. Structured self-verification as a first-class operator command.

**LLM interaction:** Claude Code/Codex as the engine; OMX adds workflow structure around it. Intent
clarified first, plan approved before execution, completion loops with explicit verification, structured
artifacts persisted for replay or handoff.

**Genuinely reusable:**
- The `$deep-interview` → clarify pattern is the single most reusable conceptual pattern across all
  four repos. Every ambiguous task should pass through a clarification gate before delegation.
- The `$ralplan` explicit plan-approval stage is directly applicable to our PDCA's "Plan" step:
  for non-trivial tasks, produce a brief, pause for alignment, then proceed.
- The `.omx/` state directory convention maps exactly to how our `.copilot/workspace/` should be
  structured: hot-index file + named subdirectories for plans, logs, memory.
- The `omx doctor` command pattern maps to our heartbeat and suggests a formal "self-check" prompt
  for agents that could be codified in a skill.
- The explore (read-only) / sparkshell (bounded execution) separation maps to our trusted/guarded
  access tier model. Read-only agents should use only read tools; writes should require explicit
  escalation.

**Should NOT be copied:**
- Codex CLI-specific integration, Node.js/npm binary packaging
- tmux team mode implementation
- Platform-specific psmux/tmux install instructions
- Provider-specific model resolution chains

---

## Combined Synthesis

### A. Common Philosophy and Architecture

A single architectural pattern emerges across all five repos (including claw-code):

```
Human sets direction (Discord / async)
    ↓
Intent-clarification gate (deep-interview / IntentGate)
    ↓
Plan approval (ralplan / TaskPacket / Plan agent)
    ↓
Parallel specialist agents execute (team / swarm / lane workers)
    ↓
Typed events route to human (clawhip / stop callbacks)
    ↓
Persistent verification loop (ralph / TodoEnforcer / GreenContract)
    ↓
Notification: task complete or blocked
```

**Three distinguishing philosophical commitments:**

1. **Intent first, execution second.** Every repo has an explicit stage where the agent clarifies
   what is wanted before writing a line of code. This prevents the classic failure mode of an agent
   completing the wrong task with high confidence.

2. **Humans steer, agents persist.** The human interface is async and minimal (a sentence in Discord,
   a flag in a CLI). The agent is expected to keep working — including verification loops — until done
   or explicitly blocked. There is no "I'll stop here and wait for further instructions" default.

3. **Events over polling.** Agents emit machine-readable typed events; a dedicated router owns
   delivery to humans. No agent manages its own notification policy. This is separation of concerns
   applied to the human feedback channel.

---

### B. Runtime/Product vs. Instruction-Template Concerns

| Concern | Runtime/Product | Template / Instruction |
|---------|-----------------|------------------------|
| Discord/Slack/Telegram daemon + delivery | ✓ runtime | — |
| Tmux multi-pane CLI worker spawning | ✓ runtime | — |
| Hash-anchored line-edit validation | ✓ runtime | — |
| LSP / AST-grep language integration | ✓ runtime | — |
| Multi-provider subscription routing | ✓ runtime | — |
| Rate-limit wait daemon | ✓ runtime | — |
| HUD statusline widget | ✓ runtime | — |
| npm/bun package lifecycle | ✓ runtime | — |
| Intent-clarification gate (deep-interview) | — | ✓ instruction |
| Plan approval before execution (ralplan) | — | ✓ instruction |
| Staged verification pipeline (team pipeline / PDCA) | — | ✓ instruction |
| Persistent completion until verified done (ralph) | — | ✓ instruction |
| Named agent roles with clear specialisation | — | ✓ instruction |
| Project-scoped skill layers with trigger keywords | — | ✓ instruction |
| Typed session event vocabulary for hooks | — | ✓ instruction |
| Memory hot-index + file-shards pattern | — | ✓ instruction |
| Doctor / self-check verification on setup | — | ✓ instruction |
| Stop-hook notification integration | — | ✓ instruction (hook design) |
| Explore (read-only) / write (guarded) separation | — | ✓ instruction |

---

### C. Mapping to This Repo's Surfaces

#### `template/copilot-instructions.md`

1. **Add an IntentGate statement to Structured Thinking Discipline.** Before the existing "Frame"
   step, add: _"If a task prompt is ambiguous, compound, or lacks stated scope, ask one clarifying
   question before proceeding. Never start execution on a prompt that could plausibly mean two
   different things."_ This is the direct translation of deep-interview / IntentGate into an
   instruction rule.

2. **Strengthen the "task complete" definition.** Add: _"A task is complete only after verification
   passes — not after submission. If verification fails, loop back into Act; do not hand back to the
   user with a silent partial."_ This encodes the ralph / TodoEnforcer semantics as an instruction rule.

3. **Add a PRD/requirements stage to the PDCA Plan step.** The OMC staged pipeline inserts an
   explicit `team-prd` stage between planning and execution. For non-trivial tasks, add: _"For tasks
   that span multiple files or introduce new behaviour, produce a brief requirements summary before
   coding. Pause here if the brief would change the implementation plan."_

4. **Rename and formalise test tiers** (already planned from supplemental research):
   `PathTargeted < AffectedSuite < FullSuite < MergeGate` — now validated by three independent
   implementations (GreenContract, OMC's team-verify, OMX's $ralph verification loop).

#### `AGENTS.md`

5. **Add scope requirement to every trigger phrase block.** After listing agents and trigger phrases,
   add: _"Every task dispatched to a specialist agent should have: (a) a one-sentence objective,
   (b) stated scope (which files or areas are in/out), and (c) acceptance criteria. Agents receiving
   a vague trigger should ask one clarifying question before proceeding."_ This is the TaskPacket
   pattern rendered as instructions rather than schema.

6. **Update trigger phrase completability rule.** From PHILOSOPHY.md via claw-code research: "Any
   trigger that requires follow-up Q&A to start is a design defect." Document this as the design
   criterion for trigger phrases.

#### `.github/agents/`

7. **Explore agent**: already read-only; add explicit note _"Use read tools only. Never write,
   stage, or execute. Use this agent for reconnaissance before handing work to Code."_ This maps
   to OMX's `omx explore` / sparkshell separation.

8. **Commit agent**: add a `TaskBrief` block standard (from supplemental research plus OMC
   validation): before any commit, the agent should confirm `acceptance_tests`, `escalation_policy`,
   and `reporting_contract` are defined.

#### `template/hooks/`

9. **Adopt `session.*` vocabulary for hook `systemMessage` prefixes.** Standardise output:
   ```json
   { "systemMessage": "[session.started] Project: {{PROJECT_NAME}} v{{VERSION}} | branch: {{BRANCH}}" }
   ```
   The 10 canonical names from clawhip's event contract:
   `session.started`, `session.blocked`, `session.finished`, `session.failed`,
   `session.retry-needed`, `session.pr-created`, `session.test-started`,
   `session.test-finished`, `session.test-failed`, `session.handoff-needed`.
   Using these names makes hook output machine-parseable by clawhip-style routers without requiring
   custom parser logic.

10. **Add `stop_hook_active` guard comment to all Stop hook scripts** (already planned from
    supplemental research — confirmed by OMC's stop-callback architecture: a Stop hook that fires
    clawhip events must not re-trigger itself).

11. **Document the outbound gateway pattern.** In `template/hooks/`, add a comment block explaining:
    _"The Stop hook can forward a structured session event to a configurable webhook URL (e.g. an
    OpenClaw gateway or clawhip `/api/omx/hook`). Set `COPILOT_STOP_WEBHOOK_URL` to enable. Leave
    unset to disable. This is the integration point for external notification routing."_

#### `template/instructions/`

12. **`config.instructions.md`**: Add a `DISABLE_*_HOOKS` env var pattern. Following OMC's
    `DISABLE_OMC` / `OMC_SKIP_HOOKS` model, all hook scripts should check for a bypass env var
    so CI or scripted contexts can opt out.

#### `tests/`

13. **BATS hook test harness** (already from supplemental research, now further validated by OMC+OMX
    having their own `omx doctor` / `/omc-doctor` verification tools): add `tests/hooks/` with BATS
    tests for each hook script. The `session.*` vocabulary standardisation (item 9 above) makes
    BATS assertions straightforward: test that Stop hooks emit correct session event prefix.

#### `setup/update flows` (SETUP.md, UPDATE.md)

14. **Add a doctor/verification step to SETUP.md.** After installation, instruct operators to run
    a verification check. Model after `omx doctor`: verify that hooks are wired, skills are
    discoverable, and agents resolve correctly. This can be a short prompt: _"Run `@Setup Verify
    the installation — check that all hooks, skills, and agents are accessible and correctly
    configured`."_

#### Workspace identity files (`.copilot/workspace/`)

15. **Document the MEMORY.md + shards pattern explicitly.** From clawhip's `docs/memory-offload-*`:
    `MEMORY.md` = hot pointer index (fast reads, agent loads immediately); `memory/` shards = bulk
    detail (loaded only when needed). Our current `RESEARCH.md` URL tracker already follows this
    pattern. Formalise it: add a comment in `MEMORY.md` (if it exists) noting that detailed notes
    go to a named shard, not into the index file.

---

### D. Ideas That Conflict With VS Code/GitHub Copilot Constraints

| Ecosystem idea | Conflict | Action |
|----------------|----------|--------|
| tmux multi-pane CLI workers | VS Code agents are not processes; no tmux | Skip entirely |
| Direct Discord/Slack send from within hooks | VS Code hooks output JSON, not HTTP calls | Route via outbound webhook URL instead |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var | Claude Code experimental flag, not VS Code Copilot | Do not reference in template; too unstable |
| Skill trigger keyword injection (OMC `.omc/skills/` model) | VS Code loads skills by `applyTo` glob, not semantic keyword | Use rich `description` fields in SKILL.md as approximation |
| Multi-provider fallback chains per agent | VS Code `.agent.md` `model:` is an array — tries in order | Usable in limited form: first available model wins |
| Background agents fire 5+ in parallel with separate context budgets | VS Code parallel subagents share the parent session; no per-subagent context budget | Use the lightweight delegation pattern with `user-invocable: false` instead |
| `omx sparkshell` arbitrary bounded shell execution | VS Code terminal tool requires permission approval per command | Document explicitly in agent instructions to use `user-invocable: false` for guarded operations |
| Session LaneEvent sequential state machine | VS Code provides 8 invocation hook points, not a sequential state machine | Use the 8 hook event names as vocabulary; do not implement a custom state machine |

---

### E. Phased Adoption Plan

#### Now — High confidence, low risk, minimal scope

1. **`session.*` event vocabulary in hook `systemMessage` prefixes** — Standardise the 10 canonical
   names across all hook scripts. Estimated: 1–2 lines per hook script, plus comment block.

2. **IntentGate rule in Structured Thinking Discipline** — Add one paragraph to
   `template/copilot-instructions.md` requiring ambiguous prompts to be clarified before execution.
   Estimated: < 10 lines.

3. **"Task complete = verified complete" language strengthening** — Add one sentence to the PDCA
   section. Estimated: < 5 lines.

4. **AGENTS.md scope requirement** — Add a "scope and context required" note adjacent to the
   trigger phrase table. Estimated: < 10 lines.

5. **Explore agent guard** — Add _"read tools only"_ note to `.github/agents/Explore.agent.md`.
   Estimated: 1 line.

#### Next — Validated, requires moderate design work

6. **BATS hook test harness** (already from supplemental research, now further validated) — Add
   `tests/hooks/` with BATS tests for each hook script. Now with `session.*` vocabulary as test
   anchor.

7. **PRD/requirements stage in PDCA Plan step** — Adds a brief requirements-summary step for
   non-trivial tasks. Requires reviewing the PDCA section for integration without duplication.

8. **TaskBrief standard in Commit agent** — Add `acceptance_tests`, `escalation_policy`, and
   `reporting_contract` fields to Commit agent prompt. Requires reviewing current Commit agent format.

9. **Stop hook outbound gateway pattern** — Document and optionally implement. Requires reviewing
   template hook scripts to add `COPILOT_STOP_WEBHOOK_URL` env var check.

10. **SETUP.md doctor step** — Add verification prompt after installation.

#### Later — Useful but requires significant design or external work

11. **Skill trigger keyword enhancement** — Add `triggers:` metadata to `SKILL.md` files and
    update skill-loading instructions to use richer descriptions. Requires reviewing all existing
    skills.

12. **Memory shards documentation** — Formalise the MEMORY.md hot-index + shards convention in
    workspace identity files.

13. **Recovery scenario table in PDCA** — Named failure scenarios with prescribed steps. Requires
    alignment with existing anti-loop rules. (Already planned from supplemental research.)

#### Avoid

14. **Discord/Slack daemon infrastructure** — Runtime product; not template scope.
15. **Tmux CLI worker coordination** — Runtime product; incompatible with VS Code agent model.
16. **Hash-anchored line edits** — Tool-layer implementation; Claude Code / VS Code tool API
    specific.
17. **Multi-provider subscription routing** — Product billing concern; not template scope.
18. **Full LaneEvent sequential state machine** — VS Code provides invocation points, not a
    sequential state machine; implementing one creates unsupported complexity.

---

## Gaps / Further Research Needed

1. **OpenClaw gateway API**: The gateway endpoint used by OMC/OMX to forward session events to
   clawhip is documented only partially. The exact JSON schema for `POST /wake` is not public. If
   the Stop hook outbound gateway pattern is implemented (item 9 above), this schema needs to be
   confirmed from clawhip's `/api/omx/hook` ingress spec.

2. **VS Code agent-scoped hooks in `.agent.md`**: Still experimental as of v1.111. Whether agent-
   scoped Stop hooks can forward HTTP events needs confirmation once the feature stabilises.

3. **clawhip v0.5.x roadmap**: clawhip's retry queue and multi-sink support (Telegram, Matrix) are
   listed as roadmap items. If implemented, the session event contract may expand. Check before
   adopting the vocabulary in a stable template release.

4. **OMO under active rename**: `oh-my-openagent` repo is renaming from `oh-my-opencode` to
   `oh-my-openagent`; the npm package, config files, and documentation are mid-transition. Any
   reference to this repo in research should note the active rename and prefer the canonical new
   name going forward.
