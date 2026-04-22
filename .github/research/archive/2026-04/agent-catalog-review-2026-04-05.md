# Research: Agent Catalog Review — copilot-instructions-template

> Date: 2026-04-05 | Status: final

## Summary

The current catalog is lean and defensible. Keep all 10 existing agents. No immediate merge or removal is justified. The main weakness is not catalog size. It is runtime routing and discoverability. The strongest additions from community patterns are a `Planner` subagent, a `Debugger` subagent, and a `Docs` agent. Stack-specific experts should live in starter kits, not the base catalog.

User decisions recorded on 2026-04-05:

- `Setup` should become a routable specialist with safeguards.
- Add new agents before implementing routing.
- Get the agent catalog in order before adding routing, tools, and starter-kit expansion.

See the routing implementation plan in [subagent-routing-implementation-plan-2026-04-05.md](subagent-routing-implementation-plan-2026-04-05.md).

## Local Inventory Verdict

| Agent | Current role | Frequency | Verdict | Notes |
|-------|--------------|-----------|---------|-------|
| `Setup` | template lifecycle, update, restore | rare | keep | High-consequence workflow. Current `disable-model-invocation: true` is a deliberate policy boundary. |
| `Code` | implementation and refactor work | common | keep | Core workhorse. Broad delegate list is appropriate. |
| `Commit` | stage, commit, push, tag, release | occasional | keep | Non-standard in the wider community, but valuable here because of commit-style and preflight discipline. |
| `Review` | code review and architecture critique | occasional | keep | Clean analytical boundary from `Code`. |
| `Fast` | quick questions and tiny edits | common | adapt | Keep it, but continue to enforce strict single-file and short-scope boundaries so it does not become a dumping ground. |
| `Explore` | read-only repo inventory | occasional | keep | Safe, cheap, and highly reusable. Strong fit for parallel exploration. |
| `Audit` | health and security diagnostics | occasional | keep | Split from `Review` is non-standard, but the read-only diagnostic role is useful. |
| `Researcher` | external docs and multi-source research | rare | keep | Strong role separation. Prevents version guessing and hallucinated API behavior. |
| `Extensions` | VS Code extensions and profiles | rare | keep | Narrow but valid specialist. Better as a hidden specialist than a general user entry point. |
| `Organise` | structural cleanup, moves, path repair | rare | keep | Clear structural role. Prevents file-move work from being absorbed by `Code`. |

## Merge and Removal Review

### No merge recommended

No pair of agents is redundant enough to merge without losing a useful boundary.

- Do not merge `Code` and `Fast`. The quick-task entry point is useful when kept narrow.
- Do not merge `Review` and `Audit`. The split is slightly uncommon, but it preserves distinct review versus diagnostic modes.
- Do not merge `Explore` and `Researcher`. The local-versus-external distinction is stronger than a generic research bucket.
- Do not merge `Commit` into `Code`. This repo benefits from an explicit git workflow owner.
- Do not merge `Organise` into `Code`. Structural cleanup is safer when isolated.

### No removal recommended

No current agent looks dead-weight.

- Rare does not mean useless. `Setup`, `Extensions`, and `Organise` are infrequent by nature.
- The current count of 10 sits near the upper bound of a manageable core catalog, but it is still coherent.

## Local Design Risks

| Risk | Impact | Recommendation |
|------|--------|----------------|
| `Fast` has the widest fan-out | medium | Keep it as a triage entry point, but reinforce its scope limit in routing and tests. |
| `Setup` is known but not delegable | medium | Treat this as a policy choice that must be surfaced in the routing design. Do not assume it can be invoked like other specialists. |
| Current reminders are mostly static | high | Fix routing and surfacing before adding more base agents. |

## Community Pattern Summary

Across VS Code custom-agent examples, Claude Code ecosystems, and broader agent-framework patterns, the most stable catalogs stay small and rely on optional specialist layers rather than shipping a huge default roster.

Common community norms:

- Keep a small core catalog.
- Add domain specialists only when they have a clear trigger.
- Put stack-specific experts behind optional installs or starter kits.
- Use routing or orchestration only when the catalog is large enough to justify it.

The strongest additions that appear across multiple ecosystems are:

1. `Planner`
2. `Debugger`
3. `Docs`

These are broadly useful and do not depend on a particular language stack.

## Candidate Additions

### Strong fit for the base catalog

| Candidate | Why it fits |
|-----------|-------------|
| `Planner` | Common in both VS Code and Claude Code examples. Good for read-only planning before implementation. Helps keep `Code` context smaller. |
| `Debugger` | Root-cause analysis is universal. Separating diagnosis from implementation reduces context pollution inside `Code`. |
| `Docs` | Documentation generation is common across ecosystems and is currently missing from the base catalog. |

## Recommended Catalog Order

### Base surfaced agents

- `Fast`
- `Code`
- `Review`
- `Commit`
- `Explore`
- `Setup`

These are the agents that should be easiest to discover or route to from general work.

### Hidden universal specialists

- `Planner`
- `Docs`
- `Debugger`
- `Audit`
- `Researcher`
- `Extensions`
- `Organise`

These remain specialist tools that support the surfaced agents without bloating the top-level interaction model.

### Optional later layers

- starter-kit-specific experts
- project-shape-specific experts
- optional installable catalogs beyond the base template

## Ordered Rollout Recommendation

1. Add `Planner` first.
2. Add `Docs` second.
3. Add `Debugger` third.
4. After those three land, implement routing and include safeguarded `Setup` in the first routing pass.
5. After routing is stable, expand optional starter-kit and tool layers.

### Why this order

- `Planner` has the strongest cross-ecosystem precedent and improves the whole system's task decomposition.
- `Docs` has a broad, low-risk boundary and fills an obvious catalog gap.
- `Debugger` is valuable but overlaps more with `Code`, so it benefits from landing after the catalog shape is otherwise stable.

### Better as starter-kit or optional agents

| Candidate family | Where it fits |
|------------------|---------------|
| frontend framework experts | `react` and `typescript` starter kits |
| backend language experts | `python`, `java`, `go`, `rust`, `cpp` starter kits |
| browser testing specialist | frontend starter kits |
| cloud, infra, or Kubernetes specialist | `docker` starter kit or cloud-heavy projects |
| database specialist | data-heavy consumer projects, not the base template |
| accessibility or localization specialist | frontend-heavy consumer projects |

### Poor fit for this repo

| Candidate | Why it does not fit |
|-----------|---------------------|
| vendor-specific cloud agents | Too narrow for the base template. |
| social or personality agents | Out of scope and conflicts with the repo's professional tone. |
| general orchestrator agent | Premature for the current catalog size. Routing is needed first. |
| database or incident-response specialist | Not a core need of this repo. |

## Catalog Size Guidance

The current core catalog is close to the right size.

- Keep the base catalog close to 10 to 12 agents.
- Add new universal specialists only when they solve a repeated, cross-project problem.
- Prefer `user-invocable: false` for new specialists unless direct invocation is clearly useful.
- Use starter kits and optional installs for the long tail of stack-specific agents.

## Recommended Next Steps

1. Add `Planner` as the first new base specialist.
2. Add `Docs` as the second new base specialist.
3. Add `Debugger` as the third new base specialist.
4. Implement dynamic routing after the catalog is stable, with `Setup` becoming routable only when safeguards land.
5. Prototype stack-specific experts through starter kits, not the base template.

## Decisions to Make Before Implementation

1. Should new optional agents live in starter kits only, or should the repo also grow an installable optional-agent catalog outside the base template?
2. Should `Docs` be user-invocable, or should it begin as a hidden specialist behind `Code` and `Review` handoffs?