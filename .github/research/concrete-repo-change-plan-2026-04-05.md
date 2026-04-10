# Research: Concrete Repo Change Plan

> Date: 2026-04-05 | Status: implemented through Phase 3; follow-up fixes pending
> Builds on: [claw-code-2026-04-05.md](claw-code-2026-04-05.md), [supplemental-agent-patterns-2026-04-05.md](supplemental-agent-patterns-2026-04-05.md), [sisyphus-ecosystem-synthesis-2026-04-05.md](sisyphus-ecosystem-synthesis-2026-04-05.md)

## Summary

This plan turns the April 5 research into an implementation-ready change set for this
repository. It is intentionally biased toward additive policy and documentation work,
because the repo's strongest constraints are parity enforcement, attention-budget CI,
and a zero-dependency shell test posture.

The outcome is a four-batch plan:

1. Safe instruction and agent-policy edits.
2. Medium-risk workflow refinements.
3. Low-cost hook metadata hardening.
4. Explicit rejects or scope-downs for runtime-heavy ideas.

## Feasibility Legend

| Status | Meaning |
|--------|---------|
| `green` | Feasible now with low risk and clear verification |
| `amber` | Feasible, but needs design care or broader verification |
| `red` | Do not implement as proposed |
| `done` | Already satisfied by the current repo; no edit required |

## Current File Sizes

| File | Current LOC |
|------|-------------|
| [template/copilot-instructions.md](template/copilot-instructions.md) | 404 |
| [.github/copilot-instructions.md](../.github/copilot-instructions.md) | 214 |
| [AGENTS.md](../AGENTS.md) | 85 |
| [.github/agents/explore.agent.md](../.github/agents/explore.agent.md) | 44 |
| [.github/agents/commit.agent.md](../.github/agents/commit.agent.md) | 100 |
| [template/instructions/config.instructions.md](template/instructions/config.instructions.md) | 13 |
| [.github/instructions/config.instructions.md](../.github/instructions/config.instructions.md) | 13 |
| [SETUP.md](../SETUP.md) | 393 |
| [template/workspace/knowledge/MEMORY.md](template/workspace/knowledge/MEMORY.md) | 76 |

## Change Matrix

| ID | Recommendation | Status | Priority | Exact files | Est. LOC delta | Targeted checks |
|----|----------------|--------|----------|-------------|----------------|-----------------|
| C1 | IntentGate rule | `done` | Completed | [template/copilot-instructions.md](template/copilot-instructions.md), [.github/copilot-instructions.md](../.github/copilot-instructions.md) | `+6 to +10`, `+4 to +8` | customization contracts, copilot audit |
| C2 | Verified-complete wording | `done` | Completed | [template/copilot-instructions.md](template/copilot-instructions.md), [.github/copilot-instructions.md](../.github/copilot-instructions.md) | `+4 to +6`, `+3 to +5` | customization contracts, copilot audit |
| C3 | PRD or requirements stage | `done` | Completed | [template/copilot-instructions.md](template/copilot-instructions.md), [.github/copilot-instructions.md](../.github/copilot-instructions.md) | `+8 to +14`, `+6 to +10` | customization contracts, copilot audit |
| C4 | Named test tiers | `done` | Completed | [template/copilot-instructions.md](template/copilot-instructions.md), [.github/copilot-instructions.md](../.github/copilot-instructions.md) | `+8 to +12`, `+6 to +10` | customization contracts, setup/update contracts, copilot audit |
| C5 | AGENTS scope note | `done` | Completed | [AGENTS.md](../AGENTS.md) | `+6 to +10` | customization contracts |
| C6 | Trigger phrase completability note | `done` | Completed | [AGENTS.md](../AGENTS.md) | `+3 to +5` | customization contracts |
| C7 | Explore read-only guard | `done` | No-op | [.github/agents/explore.agent.md](../.github/agents/explore.agent.md) | `0` or `+1` | validate-agent-frontmatter, copilot audit |
| C8 | Commit TaskBrief block | `done` | Completed | [.github/agents/commit.agent.md](../.github/agents/commit.agent.md) | `+10 to +16` | customization contracts, validate-agent-frontmatter, sync-models, copilot audit |
| C9 | `session.*` prefixes in hook output | `red` | Avoid | [template/hooks/scripts/](template/hooks/scripts), [template/hooks/copilot-hooks.json](template/hooks/copilot-hooks.json), mirrored `.github/hooks/` copies | not recommended | hook suites would need rewrites |
| C10 | `stop_hook_active` reminder comments | `done` | Completed | Stop-hook related scripts in [template/hooks/scripts/](template/hooks/scripts) and mirrored `.github/hooks/scripts/` copies | `+1 to +2` per file | direct hook suites, parity, permission resilience |
| C11 | Outbound Stop webhook pattern | `red` | Avoid | hook scripts plus docs | not recommended | unresolved external schema |
| C12 | Global `DISABLE_*_HOOKS` pattern | `red` | Avoid | all hook scripts plus docs | high blast radius | broad hook test fallout |
| C13 | BATS hook harness | `red` | Avoid for now | tests runner, manifests, CI, new `tests/hooks/` layout | large, repo-wide | conflicts with zero-dependency test posture |
| C14 | Setup doctor or verify step | `done` | No-op | [SETUP.md](../SETUP.md) | `0` or `+2` wording only | setup/update contracts |
| C15 | MEMORY hot-index plus shards guidance | `done` | Completed | [template/workspace/knowledge/MEMORY.md](template/workspace/knowledge/MEMORY.md) | `+4 to +8` | full suite only; no deterministic mapping |
| C16 | Config resolution order | `done` | Completed | [template/instructions/config.instructions.md](template/instructions/config.instructions.md), [.github/instructions/config.instructions.md](../.github/instructions/config.instructions.md) | `+16 to +24` each | customization contracts, template parity |
| C17 | Hook escalation comment headers | `done` | Completed | selected scripts under [template/hooks/scripts/](template/hooks/scripts) and mirrored `.github/hooks/scripts/` copies | `+1` per file | direct hook suites, parity, permission resilience |

## Batch A — Safe Policy Edits

### C1 — IntentGate Rule

**Goal**: encode clarify-before-execute behavior from IntentGate and `$deep-interview` without adding a new primitive.

**Exact edits**:
- In [template/copilot-instructions.md](template/copilot-instructions.md), under `## §5 — PDCA Cycle` → `### Structured Thinking Discipline`, insert a new bullet between `Frame` and `Gather`:
  - `Intent-Gate — If the prompt is ambiguous, compound, or lacks scope, ask one clarifying question before acting.`
- In [.github/copilot-instructions.md](../.github/copilot-instructions.md), add the equivalent rule inside the local `Structured Thinking Discipline` block.

**Current sizes**:
- [template/copilot-instructions.md](template/copilot-instructions.md): 404 LOC with §5 comfortably inside budget.
- [.github/copilot-instructions.md](../.github/copilot-instructions.md): 214 LOC.

**Estimated delta**:
- Template copy: `+6 to +10` lines.
- Developer copy: `+4 to +8` lines.

**Feasibility check**:
- `green`.
- Attention budget is not the blocker; CI and policy symmetry are.

**Targeted checks**:
- `bash scripts/harness/select-targeted-tests.sh template/copilot-instructions.md .github/copilot-instructions.md`
- Expected suites:
  - `tests/contracts/test-customization-contracts.sh`
  - `tests/contracts/test-setup-update-contracts.sh`
  - `tests/scripts/test-copilot-audit.sh`

### C2 — Verified-Complete Wording

**Goal**: make `done means verified done` explicit.

**Exact edits**:
- In [template/copilot-instructions.md](template/copilot-instructions.md), expand the first bullet under `### Test Scope Policy` so it says task complete requires verification to pass, not just one phase or one TODO item.
- Mirror the corresponding policy wording in [.github/copilot-instructions.md](../.github/copilot-instructions.md).

**Estimated delta**:
- Template copy: `+4 to +6` lines.
- Developer copy: `+3 to +5` lines.

**Feasibility check**:
- `green`.
- This is additive clarification of existing policy, not a contract rewrite.

**Targeted checks**:
- Same as C1.

### C4 — Named Test Tiers

**Goal**: formalize the existing prose-only progression into a stable four-tier table.

**Exact edits**:
- In [template/copilot-instructions.md](template/copilot-instructions.md), insert a 4-row table immediately under `### Test Scope Policy` with these names:
  - `PathTargeted`
  - `AffectedSuite`
  - `FullSuite`
  - `MergeGate`
- Keep the existing bullets below the table; do not replace them.
- Mirror a concise version of the same table in [.github/copilot-instructions.md](../.github/copilot-instructions.md).

**Estimated delta**:
- Template copy: `+8 to +12` lines.
- Developer copy: `+6 to +10` lines.

**Feasibility check**:
- `green`.
- The selector already exposes the underlying concept through `intermediate_phase_strategy` and final gate fields; this change only names the tiers.

**Targeted checks**:
- Same as C1 plus the setup/update contract suite for the template copy.

### C5 — AGENTS Scope Note

**Goal**: make delegation requirements explicit next to the trigger table.

**Exact edits**:
- In [AGENTS.md](../AGENTS.md), add a short `Scope requirement` block after `## Delegation policy` or immediately above `## Canonical triggers`.
- The block should require: one-sentence objective, stated scope, acceptance criteria.

**Estimated delta**:
- `+6 to +10` lines.

**Feasibility check**:
- `green`.
- This is standalone and only hits the customization contract suite.

**Targeted checks**:
- `tests/contracts/test-customization-contracts.sh`

### C6 — Trigger Phrase Completability Note

**Goal**: codify the research conclusion that trigger phrases should be completable from a single short user request.

**Exact edits**:
- In [AGENTS.md](../AGENTS.md), append one paragraph under the new scope note or `## Canonical triggers` that says triggers requiring clarifying back-and-forth to even start are a design defect.

**Estimated delta**:
- `+3 to +5` lines.

**Feasibility check**:
- `green`.

**Targeted checks**:
- `tests/contracts/test-customization-contracts.sh`

### C16 — Config Resolution Order

**Goal**: add a concrete precedence model backed by 12-factor and VS Code hook precedence.

**Exact edits**:
- Append a new `## Config Resolution Order` section to [template/instructions/config.instructions.md](template/instructions/config.instructions.md).
- Apply the same content to [.github/instructions/config.instructions.md](../.github/instructions/config.instructions.md) to preserve template parity.
- Section content should include:
  - resolution order table
  - env-var rule for secrets
  - no named environment groups
  - note that local overrides are invisible to CI

**Estimated delta**:
- Template copy: `+16 to +24` lines.
- Developer copy: `+16 to +24` lines.

**Feasibility check**:
- `green`.
- This is the cleanest high-value addition in the full plan.

**Targeted checks**:
- `tests/contracts/test-customization-contracts.sh`
- `tests/contracts/test-template-parity.sh`

## Batch B — Medium-Risk Workflow Refinements

### C3 — PRD or Requirements Stage

**Goal**: insert a small requirements checkpoint between plan and implementation for multi-file or behavior-changing work.

**Exact edits**:
- Expand the `**Plan**:` line in [template/copilot-instructions.md](template/copilot-instructions.md) to include a brief requirements summary for non-trivial tasks.
- Mirror the same concept in [.github/copilot-instructions.md](../.github/copilot-instructions.md).

**Estimated delta**:
- Template copy: `+8 to +14` lines.
- Developer copy: `+6 to +10` lines.

**Feasibility check**:
- `amber`.
- Valid idea, but needs care to avoid overlapping with `Frame` and making §5 too procedural.

**Targeted checks**:
- Same as C1.

### C8 — Commit TaskBrief

**Goal**: add structured pre-commit metadata fields without disrupting the existing commit flow.

**Exact edits**:
- In [.github/agents/commit.agent.md](../.github/agents/commit.agent.md), insert a `## TaskBrief Validation` subsection between `## Preflight workflow` and `## Commit workflow`.
- The subsection should require or explicitly mark `N/A` for:
  - `acceptance_tests`
  - `escalation_policy`
  - `reporting_contract`

**Estimated delta**:
- `+10 to +16` lines.

**Feasibility check**:
- `amber`.
- It is feasible, but it changes the operational contract of a user-invocable agent, so frontmatter and audit checks matter.

**Targeted checks**:
- `tests/contracts/test-customization-contracts.sh`
- `tests/scripts/test-copilot-audit.sh`
- `tests/scripts/test-sync-models.sh`
- `tests/scripts/test-validate-agent-frontmatter.sh`

### C15 — MEMORY Hot Index and Shards Note

**Goal**: formalize the existing pattern that the main memory file is an index, not a dump.

**Exact edits**:
- Add a short note near the top of [template/workspace/knowledge/MEMORY.md](template/workspace/knowledge/MEMORY.md) stating that `MEMORY.md` is the hot pointer file and detailed session or research notes belong in named shard files or adjacent focused files.

**Estimated delta**:
- `+4 to +8` lines.

**Feasibility check**:
- `green` with one caveat: the test selector has no deterministic mapping for this file, so it broadens to the full suite at phase time.

**Targeted checks**:
- No deterministic mapping.
- Use the full suite gate when bundled with other changes.

## Batch C — Hook Metadata Hardening

### C10 — `stop_hook_active` Reminder Comment

**Goal**: make the existing loop-prevention invariant obvious in the Stop-hook family.

**Exact edits**:
- Add one comment line near the top of the relevant Stop-hook scripts under [template/hooks/scripts/](template/hooks/scripts) and mirror the same line in `.github/hooks/scripts/`.
- Primary target scripts:
  - `pulse.sh`
  - `scan-secrets.sh`
  - PowerShell parity copies if the same guard is relevant there

**Estimated delta**:
- `+1 to +2` lines per touched file.

**Feasibility check**:
- `green`.
- This is comment-only, but parity still matters.

**Targeted checks**:
- `tests/hooks/test-hook-pulse.sh`
- `tests/hooks/test-hook-scan-secrets.sh`
- `tests/scripts/test-permission-resilience.sh`
- `tests/contracts/test-template-parity.sh`

### C17 — Hook Escalation Header Comments

**Goal**: add machine-readable but non-behavioral metadata for hook escalation posture.

**Exact edits**:
- Add `# ESCALATION: ...` to the header of each touched shell script under [template/hooks/scripts/](template/hooks/scripts) and mirrored `.github/hooks/scripts/` copies.
- Suggested mapping:
  - `guard-destructive.sh` → `ask`
  - `scan-secrets.sh` → `block`
  - `session-start.sh`, `save-context.sh`, `subagent-start.sh`, `subagent-stop.sh` → `none`
  - `pulse.sh` → `none` unless a later design explicitly changes semantics

**Estimated delta**:
- `+1` line per touched file.

**Feasibility check**:
- `green` if kept comment-only.
- `amber` if it starts driving logic.

**Targeted checks**:
- Hook-specific suites from the selector:
  - `tests/hooks/test-hook-session-start.sh`
  - `tests/hooks/test-hook-pulse.sh`
  - `tests/hooks/test-hook-save-context.sh`
  - `tests/hooks/test-guard-destructive.sh`
  - `tests/hooks/test-hook-subagent-start.sh`
  - `tests/hooks/test-hook-subagent-stop.sh`
  - `tests/hooks/test-hook-scan-secrets.sh`
  - `tests/scripts/test-security-edge-cases.sh`
  - `tests/scripts/test-permission-resilience.sh`
  - `tests/contracts/test-template-parity.sh`

## Batch D — No-Ops, Scope-Downs, and Rejects

### C7 — Explore Read-Only Guard

**Outcome**: `done`.

**Reason**:
- [.github/agents/explore.agent.md](../.github/agents/explore.agent.md) already has a strong read-only contract.
- [.copilot/workspace/knowledge/MEMORY.md](../.copilot/workspace/knowledge/MEMORY.md) already records that the Explore guarantee is critical.

**Edit plan**:
- No change required unless a one-line reinforcement is desired.

### C9 — Blanket `session.*` Hook Prefixes

**Outcome**: `red`.

**Reason**:
- Current repo research already established that `systemMessage` is user-facing and should stay sparse.
- Existing hook suites assert absence of unexpected `systemMessage` output in normal flows.
- Use the official hook event names as vocabulary in comments or internal logs instead of forcing a new prefix into every hook result.

**Edit plan**:
- No implementation.
- If revisited later, scope it to internal log artifacts rather than `systemMessage`.

### C11 — Outbound Stop Webhook Pattern

**Outcome**: `red`.

**Reason**:
- The external gateway contract is not stable enough in the local research.
- This repo's hooks are deterministic local stdio helpers, not network clients.

**Edit plan**:
- No implementation.

### C12 — Global Hook Disable Pattern

**Outcome**: `red`.

**Reason**:
- The repo already uses granular skip patterns where needed.
- A global bypass would touch too many scripts and tests for too little value.

**Edit plan**:
- No implementation.

### C13 — BATS Hook Harness

**Outcome**: `red` for now.

**Reason**:
- The repo already has a custom zero-dependency hook test framework.
- Existing research on shell test frameworks does not support near-term migration.
- The change would require runner, manifest, CI, and contributor bootstrap edits.

**Edit plan**:
- No implementation in this batch plan.
- Revisit only if the custom shell framework becomes a measurable bottleneck.

### C14 — Setup Doctor Step

**Outcome**: `done`.

**Reason**:
- [SETUP.md](../SETUP.md) already ends with an Audit handoff question under `## § 5 — Self-destruct and final summary`.
- The repo already has an Audit-centered verification model rather than a separate Doctor surface.

**Edit plan**:
- No functional change required.
- Optional wording-only tweak later: say `health check / verification` instead of only `health check`.

## Recommended Implementation Order

### Phase 1

Status: completed on 2026-04-05.

Apply only:
- C1
- C2
- C4
- C5
- C6
- C16

**Estimated total delta**: roughly `+43 to +67` lines across 5 files.

**Why first**:
- Highest confidence.
- Clear verification path.
- No runtime or test-runner invention.

### Phase 2

Status: completed on 2026-04-05.

Apply only after Phase 1 is green:
- C3
- C8
- C15

**Estimated total delta**: roughly `+22 to +38` lines across 4 files.

**Why second**:
- These are structurally valid, but easier to get wrong semantically.

### Phase 3

Status: completed on 2026-04-05.

Apply only as comment-only hardening:
- C10
- C17

**Estimated total delta**: roughly `+8 to +16` lines across mirrored hook copies.

**Why third**:
- Behavior should stay unchanged.
- Hook suites are sensitive enough that isolated review is safer.

## Phase Checks

### Phase 1 Targeted Checks

```bash
bash scripts/harness/select-targeted-tests.sh \
  template/copilot-instructions.md \
  .github/copilot-instructions.md \
  AGENTS.md \
  template/instructions/config.instructions.md \
  .github/instructions/config.instructions.md
```

Expected suites:
- `tests/contracts/test-customization-contracts.sh`
- `tests/contracts/test-setup-update-contracts.sh`
- `tests/scripts/test-copilot-audit.sh`
- `tests/contracts/test-template-parity.sh`

### Phase 2 Targeted Checks

```bash
bash scripts/harness/select-targeted-tests.sh \
  template/copilot-instructions.md \
  .github/copilot-instructions.md \
  .github/agents/commit.agent.md \
  template/workspace/knowledge/MEMORY.md
```

Expected suites:
- `tests/contracts/test-customization-contracts.sh`
- `tests/scripts/test-copilot-audit.sh`
- `tests/scripts/test-sync-models.sh`
- `tests/scripts/test-validate-agent-frontmatter.sh`
- Full suite fallback because `template/workspace/knowledge/MEMORY.md` is currently unmapped

### Phase 3 Targeted Checks

```bash
bash scripts/harness/select-targeted-tests.sh \
  template/hooks/copilot-hooks.json \
  template/hooks/scripts/session-start.sh \
  template/hooks/scripts/pulse.sh \
  template/hooks/scripts/guard-destructive.sh \
  template/hooks/scripts/scan-secrets.sh \
  template/hooks/scripts/subagent-start.sh \
  template/hooks/scripts/subagent-stop.sh \
  template/hooks/scripts/save-context.sh
```

Expected suites:
- `tests/hooks/test-hook-session-start.sh`
- `tests/hooks/test-hook-pulse.sh`
- `tests/hooks/test-hook-save-context.sh`
- `tests/hooks/test-guard-destructive.sh`
- `tests/hooks/test-hook-subagent-start.sh`
- `tests/hooks/test-hook-subagent-stop.sh`
- `tests/hooks/test-hook-scan-secrets.sh`
- `tests/scripts/test-security-edge-cases.sh`
- `tests/scripts/test-permission-resilience.sh`
- `tests/contracts/test-template-parity.sh`

### Final Gate

Always finish with:

```bash
bash tests/run-all.sh
```

If running from the terminal during implementation, prefer the captured wrapper:

```bash
bash scripts/harness/run-all-captured.sh
```

## Recommended Scope Cut

If only one implementation batch is approved, choose Phase 1. It contains the most reusable LLM-behavior improvements with the least blast radius and no new infrastructure burden.