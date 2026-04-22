# Plan: Dynamic Subagent Routing and Reminders

> Date: 2026-04-05 | Status: draft

## Summary

Implement a routing layer that reminds Copilot about available subagents at the moment a specialist handoff becomes relevant. Do not add more static prose. Use the existing hook and pulse state pipeline to classify intent, confirm it from behavior, emit a sparse reminder once, and carry forward the reason for any chosen subagent.

User decisions recorded on 2026-04-05:

- `Setup` should become a routable specialist, but only with explicit safeguards.
- Add new agents before implementing routing.
- Stabilize the agent catalog first, then implement routing, then expand optional tools and starter-kit specialists.

## Goals

- Make every available subagent visible to the runtime without spamming every turn.
- Route clear prompts and behaviors toward the right specialist.
- Keep reminders short, contextual, and stateful.
- Cover every agent in `.github/agents/`.
- Keep Bash and PowerShell hooks in parity.

## Current Base

- `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PreCompact`, `SubagentStart`, `SubagentStop`, and `Stop` are already wired through `.github/hooks/copilot-hooks.json`.
- `.github/hooks/scripts/session-start.sh` injects environment and project context.
- `.github/hooks/scripts/pulse.sh`, `.github/hooks/scripts/pulse_state.py`, and `.github/hooks/scripts/pulse_intent.py` already persist session state and phase transitions.
- `.github/hooks/scripts/subagent-start.sh` and `.github/hooks/scripts/subagent-stop.sh` already inject generic subagent lifecycle context.
- Agent roles and allow-lists already exist in `.github/agents/*.agent.md`.

## Agent Coverage

| Agent | Primary route when |
|-------|--------------------|
| `Fast` | quick question, syntax lookup, tiny single-file edit |
| `Code` | multi-step implementation, bugfix, refactor, test-backed coding task |
| `Review` | formal code review, critique, architectural review |
| `Audit` | health check, security audit, secrets, vulnerability posture |
| `Explore` | read-only repo inventory, caller discovery, multi-file search |
| `Researcher` | current external docs, version-specific behavior, multi-source research |
| `Commit` | stage, commit, push, tag, release, commit preflight |
| `Extensions` | VS Code extensions, profiles, recommendations, workspace extension config |
| `Setup` | template setup, update, backup restore, factory restore |
| `Organise` | file moves, path repair, folder reshaping, structural cleanup |
| `Planner` | read-only planning, scoping, task breakdown, implementation sequencing |
| `Docs` | documentation generation, walkthroughs, API docs, README work |
| `Debugger` | root-cause analysis, error diagnosis, regression triage |

## Delivery Order

### Stage 1 — Catalog First

Finalize the base catalog and its ordering before any runtime routing work.

Target catalog after Stage 1:

- Direct or broadly surfaced agents: `Fast`, `Code`, `Review`, `Commit`, `Explore`, `Setup`
- Hidden universal specialists: `Planner`, `Docs`, `Debugger`, `Audit`, `Researcher`, `Extensions`, `Organise`
- Later optional layers: starter-kit and project-shape-specific specialists

### Stage 2 — Routing Second

Once the catalog is stable, add routing metadata, runtime reminders, cooldown rules, and stateful handoff nudges.

### Stage 3 — Optional Expansion Third

After routing works for the base catalog, add optional starter-kit agents, optional tools, and broader installable catalogs.

## Setup Safeguards

`Setup` is now a target routable specialist, but it should not lose its current safety boundary until routing safeguards exist.

That means:

- define `Setup` as a routable target in the catalog stage
- keep the current hard block until the routing stage is ready to enforce guardrails
- flip the actual model-invocation behavior only when the safeguards below land in the same pass

Required safeguards for routable `Setup`:

- high-confidence prompt and behavior signals only
- explicit lifecycle-only routing scope
- mandatory confirmation path for destructive or overwriting operations
- no silent transition from ordinary coding work into setup or restore mode
- clear stop conditions when the current repo is the template repo rather than a consumer repo

## Routing Architecture

### 1. Routing Inventory

Create one machine-readable routing manifest for all agents.

Include for each agent:

- name
- role summary
- prompt signals
- behavior signals
- suppressors
- confidence thresholds
- reminder copy
- cooldown rules
- whether the route is direct, internal, or picker-visible

Use `.github/agents/*.agent.md` as the source of truth for names, roles, user visibility, and allow-lists. Do not duplicate frontmatter fields that can be derived.

### 2. Session-Start Awareness

Update `session-start.sh` and `session-start.ps1` to inject a compact live specialist roster based on the routing inventory.

Requirements:

- keep the roster to one or two lines
- list the most relevant specialists for this repo
- mark internal-only specialists clearly
- avoid long prose or repeated instructions

### 3. Prompt-Intent Capture

Extend the `UserPromptSubmit` path in the pulse pipeline to classify the current request into a routing candidate.

Store in state:

- `route_candidate`
- `route_reason`
- `route_confidence`
- `route_source`
- `route_emitted`
- `route_epoch`

Prompt capture must be conservative. It should prefer no route over a weak route.

### 4. Behavior Confirmation

Use `PreToolUse` to confirm or refine the candidate based on actual behavior.

Examples:

- repeated read-only search and file reads confirm `Explore`
- external docs fetches confirm `Researcher`
- git staging, commit, push, tag, or release flows confirm `Commit`
- extension and profile work confirm `Extensions`
- move and rename oriented work confirms `Organise`
- lifecycle template operations confirm safeguarded `Setup`

### 5. Sparse Reminder Emission

Emit a one-line `additionalContext` reminder only when:

- a route is high confidence
- the current behavior confirms the route
- the reminder has not already been emitted in the current phase
- cooldown rules allow it

Do not emit reminders on every tool call.

### 6. Subagent Lifecycle Context

Upgrade `subagent-start.sh` and `subagent-stop.sh` so they carry useful context, not only generic governance text.

`SubagentStart` should include:

- the selected agent
- the reason it was selected
- the current scope or stop condition if available

`SubagentStop` should include:

- the agent that completed
- the next recommended action for the parent
- whether the result is review-only or should lead to another specialist

### 7. Missed-Delegation Signals

Record likely missed delegation cases in session state for later compaction and heartbeat summaries.

Examples:

- inline git lifecycle flow when `Commit` would have been a better owner
- long read-only repo inventory performed by the parent instead of `Explore`
- version-specific doc lookups without `Researcher`

Do not turn missed-delegation signals into immediate repeated reminders.

## Phase Plan

### Phase 0 — Catalog Alignment

- resolve the target ordering of all base agents
- decide initial visibility for new agents
- define `Setup` safeguard requirements in the catalog
- choose the location of the future routing manifest

### Phase 1 — Add New Base Agents

Add:

- `Planner`
- `Docs`
- `Debugger`

Recommended order:

1. `Planner` — strongest community precedent and highest leverage for reducing `Code` context
2. `Docs` — broad utility and clear boundary with low risk
3. `Debugger` — valuable, but overlaps more with `Code` and benefits from seeing the final catalog shape first

Work in this phase:

- create agent files
- define tools, model pins, allow-lists, and handoffs
- update canonical inventories and docs
- add validation coverage for the expanded catalog

### Phase 2 — First Routing Pass

Build the minimal router for:

- `Commit`
- `Explore`
- `Researcher`
- safeguarded `Setup`

Reason: these routes are high-value, high-precision, and directly address the most common missed handoffs. `Setup` joins this phase because its safeguards depend on the routing layer.

### Phase 3 — Broader Routing Pass

Add routing for:

- `Planner`
- `Docs`
- `Debugger`
- `Review`
- `Audit`
- `Extensions`
- `Organise`

### Phase 4 — Overlap-Sensitive Routing

Add routing for:

- `Fast`
- `Code`

These require stricter thresholds because they overlap with normal top-level work.

### Phase 5 — Optional Expansion

Expand optional layers:

- starter-kit-specific specialist agents
- optional tool bundles that support those specialists
- optional installable catalogs beyond the base template

## Files Likely to Change

- `.github/hooks/copilot-hooks.json`
- `.github/hooks/scripts/session-start.sh`
- `.github/hooks/scripts/session-start.ps1`
- `.github/hooks/scripts/subagent-start.sh`
- `.github/hooks/scripts/subagent-start.ps1`
- `.github/hooks/scripts/subagent-stop.sh`
- `.github/hooks/scripts/subagent-stop.ps1`
- `.github/hooks/scripts/pulse.sh`
- `.github/hooks/scripts/pulse_state.py`
- `.github/hooks/scripts/pulse_intent.py`
- new routing manifest under `.github/agents/` or another machine-readable location
- new agent files for `Planner`, `Docs`, and `Debugger`
- matching template mirrors under `template/`
- hook and pulse tests under `tests/hooks/`

## Verification Plan

Add or extend tests for:

- session-start roster injection
- prompt classification for every covered agent
- behavior-confirmed reminder emission
- cooldown and non-repetition rules
- safeguarded `Setup` routing behavior
- subagent lifecycle reason and next-step context
- routing inventory coverage for every file in `.github/agents/`
- Bash and PowerShell parity

Primary suites likely affected:

- `tests/hooks/test-hook-session-start.sh`
- `tests/hooks/test-hook-session-start-powershell.sh`
- `tests/hooks/test-hook-subagent-start.sh`
- `tests/hooks/test-hook-subagent-start-powershell.sh`
- `tests/hooks/test-hook-subagent-stop.sh`
- `tests/hooks/test-hook-subagent-stop-powershell.sh`
- `tests/hooks/test-hook-pulse.sh`
- `tests/hooks/test-pulse-state.sh`

## Acceptance Criteria

- The base agent catalog is finalized before routing logic is introduced.
- `Planner`, `Docs`, and `Debugger` exist and validate cleanly before routing work starts.
- Every agent in `.github/agents/` has a routing entry.
- `SessionStart` exposes a compact specialist roster.
- Clear prompts can classify to the correct specialist without flooding unrelated sessions.
- `PreToolUse` emits sparse, behavior-confirmed routing hints.
- `Commit`, `Explore`, `Researcher`, and safeguarded `Setup` are covered in the first routing phase.
- The hook and pulse suites remain green.
- Template and repo-live hook assets stay in parity.

## Open Decisions

1. Should routing metadata live in a dedicated manifest or be folded into an existing inventory such as `workspace-index.json`?
2. Should the first runtime reminder mention the handoff button explicitly, or stay neutral and only name the specialist?
3. Should `Docs` begin hidden or user-invocable in the first catalog pass?
