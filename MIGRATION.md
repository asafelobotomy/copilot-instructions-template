# Migration Registry — copilot-instructions-template

> **For Copilot**: This file is fetched during the update protocol (UPDATE.md U3)
> to understand what changed at each version. Use it to build per-version change
> groups, identify companion files that need updating, and flag breaking changes.
>
> **For the human**: This registry shows what changed in each release and what
> manual actions may be needed when updating across multiple versions.

For versions `v3.3.2` and earlier, read `MIGRATION.archive.md` alongside this
file. `MIGRATION.md` now carries the active registry for `v3.4.0+` and for new
release stubs.

## How to read this file

Each entry covers one **tagged** version. Untagged patch releases are bundled into
the next tagged version (listed in **Includes**).

- **Sections changed**: Which `§N` sections of `copilot-instructions.md` were modified.
- **Sections added**: New `§N` sections introduced (consumers upgrading from before this version will not have them).
- **Companion files**: Files outside `copilot-instructions.md` that were added or updated. The update protocol offers these to the user. **Consumer-deliverable only** — paths matching the Excluded paths list in UPDATE.md U5 Step 3 (`tests/`, `scripts/`, `.github/workflows/`, `SETUP.md`, `UPDATE.md`, `MIGRATION.md`, `AGENTS.md`, `README.md`, `CHANGELOG.md`, `MODELS.md`, etc.) are template-internal and are not offered to consumers even if they appear in historical entries.
- **New placeholders**: `{{PLACEHOLDER}}` tokens introduced in `§10` that consumers need to resolve.
- **Manual actions**: Steps that require human intervention beyond accepting section updates.

**Fetch URL pattern** for companion files:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/<tag>/<template-source-path>
```

**Available tags**: v3.4.0, v3.4.1, v4.0.0, v4.1.0, v4.1.1, v4.2.0, v5.0.0, v5.0.1, v5.1.0, v5.2.0, v5.3.0, v5.4.0

## v5.3.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §2, §5, §8, §9 | — | — |

**What changed**: Adds phase-scoped test selection guidance and a consumer-facing audit workflow, tightens heartbeat runtime helpers around active-work tracking, and expands the hook/workspace inventory used by setup and update flows.

**Breaking**: None

**New placeholders**: none

**Companion files added**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/skills/commit-preflight/SKILL.md` | `template/skills/commit-preflight/SKILL.md` | **New** (commit-time workflow preflight skill) |

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/audit.agent.md` | `.github/agents/audit.agent.md` | Updated (consumer audit mode and residual-risk workflow) |
| `.github/hooks/scripts/heartbeat-policy.json` | `template/hooks/scripts/heartbeat-policy.json` | Updated (policy-driven heartbeat thresholds and messages) |
| `.github/hooks/scripts/mcp-heartbeat-server.py` | `template/hooks/scripts/mcp-heartbeat-server.py` | Updated (reflection payload handling) |
| `.github/hooks/scripts/pulse.sh` | `template/hooks/scripts/pulse.sh` | Updated (phase testing and heartbeat orchestration) |
| `.github/hooks/scripts/pulse.ps1` | `template/hooks/scripts/pulse.ps1` | Updated (PowerShell parity for heartbeat orchestration) |
| `.github/hooks/scripts/pulse_intent.py` | `template/hooks/scripts/pulse_intent.py` | Updated (audit-mode prompt routing) |
| `.github/hooks/scripts/pulse_paths.py` | `template/hooks/scripts/pulse_paths.py` | Updated (consumer path classification) |
| `.github/hooks/scripts/pulse_runtime.py` | `template/hooks/scripts/pulse_runtime.py` | Updated (policy loading and runtime thresholds) |
| `.github/hooks/scripts/pulse_state.py` | `template/hooks/scripts/pulse_state.py` | Updated (active-work tracking and retrospective thresholds) |
| `.copilot/workspace/HEARTBEAT.md` | `template/workspace/HEARTBEAT.md` | Updated (active-work heartbeat guidance) |
| `.copilot/workspace/workspace-index.json` | `template/workspace/workspace-index.json` | Updated (expanded hook companion inventory) |

**Manual actions**: None

## v4.2.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | None | None | v4.1.1 |

**What changed**: Adds a static copilot_audit.py script and Doctor D14 integration for auditing Copilot-visible files, extends coverage to starter-kit prompts, skills, instructions, and registry metadata, and updates hooks and setup docs to match the new static audit behavior.

**Breaking**: None

**New placeholders**: None

**Companion files added**: None

**Companion files updated**: None

**Manual actions**: None — changes are template-internal (scripts, tests, agents, and documentation) and do not alter consumer instructions.

## v4.1.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §2, §13 | — | — |

**What changed**: Adds Extensions and Security agents; hardens agent invocation policies
and read-only guardrails across all agent files; integrates `ask_questions` directives into
SETUP.md; introduces dynamic agent and skill discovery in setup scripts; updates the Doctor
agent with upstream baseline checks (D11–D13); improves cross-agent delegation and tool
handoffs for comprehensive capability coverage; documentation formatting fixes across agents
and skill files.

**Breaking**: None

**New placeholders**: None

**Companion files added**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/extensions.agent.md` | `.github/agents/extensions.agent.md` | **New** (VS Code extension management agent) |
| `.github/agents/security.agent.md` | `.github/agents/security.agent.md` | **New** (security audit agent) |

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/coding.agent.md` | `.github/agents/coding.agent.md` | Updated (cross-agent delegation, tool handoffs) |
| `.github/agents/doctor.agent.md` | `.github/agents/doctor.agent.md` | Updated (D11–D13 upstream baseline checks) |
| `.github/agents/explore.agent.md` | `.github/agents/explore.agent.md` | Updated (read-only guardrail hardening) |
| `.github/agents/fast.agent.md` | `.github/agents/fast.agent.md` | Updated (invocation policy hardening) |
| `.github/agents/researcher.agent.md` | `.github/agents/researcher.agent.md` | Updated (tool handoffs and capability coverage) |
| `.github/agents/review.agent.md` | `.github/agents/review.agent.md` | Updated (cross-agent delegation) |
| `.github/agents/setup.agent.md` | `.github/agents/setup.agent.md` | Updated (`ask_questions` directives integrated) |
| `.github/agents/update.agent.md` | `.github/agents/update.agent.md` | Updated (invocation policy hardening) |

**Manual actions**: None — agent files are installed by setup/update; no manual edits required.

## v5.0.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| TBD | — | — | — |

**What changed**: *(stub — fill in before the next release or immediately after)*

**New placeholders**: none

**Companion files added**: none

**Companion files updated**: none

**Manual actions**: None

## v5.0.1

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| TBD | — | — | — |

**What changed**: *(stub — fill in before the next release or immediately after)*

**New placeholders**: none

**Companion files added**: none

**Companion files updated**: none

**Manual actions**: None

## v5.2.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| Yes | §8, §9 | — | v5.1.0 |

**What changed**: Fixes critical heartbeat system defects. The `SessionStart` hook now injects its instruction to the agent via `hookSpecificOutput.additionalContext` (model context) instead of `systemMessage` (UI-only banner — the model never received it). The transcript-fallback retrospective gate regex is tightened to require specific Q-answer evidence patterns rather than the bare word "retrospective". Session IDs now use a stable local fallback (`local-XXXX`) instead of always resolving to "unknown". The `HEARTBEAT.md` Response Contract is rewritten to be unambiguous: three explicit rules replace two contradictory bullets. Removes dead `enforce-retrospective.sh`/`.ps1` scripts (enforcement was already performed by `pulse.sh`). Adds `SubagentStop` hook commentary and documents `UserPromptSubmit` model-injection limitation.

**Breaking**: Yes — the `HEARTBEAT.md` Response Contract section must be manually updated in each consumer workspace (it is consumer-owned and cannot be auto-merged). Consumers who do not update will continue to get an empty History because the old Contract's rule 1 ("omit row if all checks pass") overrides rule 2 ("append on session start").

**New placeholders**: none

**Companion files added**: none

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/hooks/scripts/pulse.sh` | `template/hooks/scripts/pulse.sh` | Updated (F1–F5 heartbeat fixes) |
| `.github/hooks/scripts/pulse.ps1` | `template/hooks/scripts/pulse.ps1` | Updated (F1–F5 heartbeat fixes, PowerShell parity) |

**Manual actions**:

**Action 1 — Update `HEARTBEAT.md` Response Contract** (required — fixes empty History)

In `.copilot/workspace/HEARTBEAT.md`, replace the `## Response Contract` section with:

```markdown
## Response Contract

- Always append a History row when the trigger is Session start or Explicit — regardless of check results.
- For all other triggers, append a History row only if a check raised an alert or retrospective output was persisted to SOUL.md / MEMORY.md / USER.md.
- If checks pass and nothing was persisted on a non-explicit trigger, keep Pulse as `HEARTBEAT_OK` and omit the History row.
```

**Action 2 — Rename `DOC_INDEX.json` if present** (one-time cleanup for consumers set up before v5.0.0)

If `.copilot/workspace/DOC_INDEX.json` exists, rename it:

```bash
mv .copilot/workspace/DOC_INDEX.json .copilot/workspace/workspace-index.json 2>/dev/null || true
```

Then update any agent count or skill count references inside the file to match the current `.github/agents/` and `.github/skills/` directories.

## v5.4.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| TBD | — | — | — |

**What changed**: *(stub — fill in before the next release or immediately after)*

**New placeholders**: none

**Companion files added**: none

**Companion files updated**: none

**Manual actions**: None

---

## v5.1.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| TBD | — | — | — |

**What changed**: *(stub — fill in before the next release or immediately after)*

**New placeholders**: none

**Companion files added**: none

**Companion files updated**: none

**Manual actions**: None

---

## v4.1.1

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | None | None | v4.1.0 |

**What changed**: Documentation fixes only — resolved 32 markdownlint errors across agent and research documents.

**Breaking**: None

**New placeholders**: None

**Companion files added**: None

**Companion files updated**: None

**Manual actions**: None

---

## v4.0.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| Yes | §2, §13 | §13 | v3.4.1 |

**What changed**: Adds §13 MCP Protocol (section count 12 → 13); §2 gains Test Coverage Review with local recommendations and CI workflow generation; Setup interview expands to 22 questions (E22 Expert tier). Includes all v3.4.x CI-fix patches. Template-repo docs (`SETUP.md`, `UPDATE.md`, `MIGRATION.md`) also updated but are not consumer-deliverable.

**Breaking**: §13 is a new section — consumers upgrading from v3.x will not have it and must add it manually or re-run setup.

**New placeholders**: none

**Companion files added**: none

**Companion files updated**: none

**Manual actions**: Add `## §13 — MCP Protocol` section to your `.github/copilot-instructions.md` if upgrading from v3.x without re-running setup.

---

## v3.4.1

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | — | — | — |

**What changed**: CI lint fixes only — markdown lint (MD028, MD029, MD031, MD034), shellcheck (SC2221/SC2222), and structural validation (missing `## [Unreleased]` in CHANGELOG). No template or hook behaviour changes.

**New placeholders**: none

**Companion files added**: none

**Companion files updated**: none

**Manual actions**: None

---

## v3.4.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §2, §3, §6, §10, §13 | — | v3.3.2 |

**What changed**: Introduces Researcher and Explore agents with a `RESEARCH.md` URL
tracker, adds stack-specific starter kits, refactors hook scripts into shared
libraries, and updates documentation and templates to surface the new
capabilities.

**New placeholders**: none

**Companion files added**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/researcher.agent.md` | `.github/agents/researcher.agent.md` | **New** (research-oriented agent) |
| `.github/agents/explore.agent.md` | `.github/agents/explore.agent.md` | **New** (exploration agent) |
| `starter-kits/*` | `starter-kits/*` | **New** (stack-specific starter kits for common languages/frameworks) |
| `.copilot/workspace/RESEARCH.md` | `template/workspace/RESEARCH.md` | **New** (URL tracker for research tasks) |
| `.github/hooks/scripts/lib-hooks.sh` | `template/hooks/scripts/lib-hooks.sh` | **New** (shared hook helper library) |

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/hooks/scripts/*.sh` | `template/hooks/scripts/*.sh` | Updated (shared JSON escaping utilities and common helpers) |
| `AGENTS.md` | `AGENTS.md` | Updated (Researcher/Explore agents inventory) |
| `.copilot/workspace/HEARTBEAT.md` | `template/workspace/HEARTBEAT.md` | Updated (metrics freshness and task logging) |
| `.copilot/workspace/MEMORY.md` | `template/workspace/MEMORY.md` | Updated (documentation refinements) |

**Manual actions**: None
