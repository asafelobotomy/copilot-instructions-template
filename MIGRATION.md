# Migration Registry — copilot-instructions-template

> **For Copilot**: This file is fetched during the update protocol (UPDATE.md U3)
> to understand what changed at each version. Use it to build per-version change
> groups, identify companion files that need updating, and flag breaking changes.
>
> **For the human**: This registry shows what changed in each release and what
> manual actions may be needed when updating across multiple versions.

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

**Available tags**: v1.1.0, v1.4.0, v2.0.0, v2.1.0, v2.2.0, v3.0.0, v3.0.1, v3.0.2, v3.0.3, v3.0.4, v3.1.0, v3.2.0, v3.3.0, v3.3.1, v3.3.2, v3.4.0, v3.4.1, v4.0.0, v4.1.0, v4.1.1, v4.2.0, v5.0.0, v5.0.1, v5.1.0

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

---

## v3.3.2

**Includes**: v3.3.2

**Sections changed**: none (structural repo change only)

**Companion files added**:

- `template/copilot-instructions.md` — consumer instructions template (new canonical location)
- `template/instructions/tests.instructions.md` — consumer test instruction stub
- `template/prompts/refactor.prompt.md` — consumer prompt with placeholder tokens
- `template/prompts/test-gen.prompt.md` — consumer prompt with placeholder tokens

**New placeholders**: none

**Manual actions**:

- If updating AGENTS.md: step 2 now fetches `template/copilot-instructions.md` instead of `.github/copilot-instructions.md`.
- Developer `.github/copilot-instructions.md` is now the repo-specific developer guide; the consumer template lives in `template/copilot-instructions.md`.

---

## v3.3.1

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | — | — | — |

**What changed**: This release aligns the local test entrypoint and CI workflow inventory, adds the `v3.3.0` migration entry required by release metadata contracts, and cleans up lint-only issues in workflow shell blocks, mirrored skill Markdown, and shell test harness scripts.

**New placeholders**: —

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `tests/run-all.sh` | `tests/run-all.sh` | Updated (skip PowerShell parity locally when `pwsh` is unavailable) |
| `.github/workflows/ci.yml` | `.github/workflows/ci.yml` | Updated (remove stale steps, exempt intentional `mcp-management` divergence, fix shell lint pattern) |
| `MIGRATION.md` | `MIGRATION.md` | Updated (add `v3.3.0` and `v3.3.1` registry entries) |
| `.github/skills/*/SKILL.md` | `template/skills/*/SKILL.md` | Updated (remove duplicate blank lines in mirrored skills) |
| `tests/*.sh` | `tests/*.sh` | Updated (address ShellCheck findings in test harness scripts) |

**Manual actions**: None

---

## v3.3.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §2, §10 | — | — |

**What changed**: §2 now routes extension and test audits through dedicated on-demand review skills instead of embedding the full procedures inline. §10 records new repo-level review surfaces, the canonical local test entrypoint, and the current model guidance surfaced through `llms.txt`.

**New placeholders**: —

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/skills/extension-review/SKILL.md` | `template/skills/extension-review/SKILL.md` | **New** (VS Code extension audit workflow) |
| `.github/skills/test-coverage-review/SKILL.md` | `template/skills/test-coverage-review/SKILL.md` | **New** (coverage-gap audit workflow) |
| `llms.txt` | `llms.txt` | Updated (model guidance and review-skill inventory) |
| `CHANGELOG.md` | `CHANGELOG.md` | Updated (v3.3.0 release entry) |

**Manual actions**: None

---

## v3.2.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §12, §13 | — | v3.1.0 |

**What changed**: §12 updated to include agent plugin priority hierarchy and plugin-management skill reference. §13 updated to reference MCP GA status. Instruction files gain `description` frontmatter for on-demand loading (VS Code 1.102+). Prompt files gain YAML frontmatter (`description`, `mode`, `tools`). Skills updated to reference `/create-*` built-in commands and agent plugins. Heartbeat adds agent compatibility check and Retrospective section. Guard-destructive scripts document auto-approval complementarity. AGENTS-GUIDE expanded: agent plugin strategic roadmap, Claude agent format compatibility, and actionable org-level agent setup steps. Doctor agent gains D11 plugin health check. Documentation architecture gains canonical machine-readable index (`.copilot/workspace/DOC_INDEX.json`) with deterministic sync/check script (`scripts/sync-doc-index.sh`) and CI enforcement; `README.md` and `AGENTS.md` inventory-heavy sections are deduplicated to canonical references.

**New placeholders**: —

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/instructions/tests.instructions.md` | `template/instructions/tests.instructions.md` | Updated (`description` field added) |
| `.github/instructions/api-routes.instructions.md` | `template/instructions/api-routes.instructions.md` | Updated (`description` field added) |
| `.github/instructions/config.instructions.md` | `template/instructions/config.instructions.md` | Updated (`description` field added) |
| `.github/instructions/docs.instructions.md` | `template/instructions/docs.instructions.md` | Updated (`description` field added) |
| `.github/prompts/explain.prompt.md` | `template/prompts/explain.prompt.md` | Updated (YAML frontmatter added) |
| `.github/prompts/refactor.prompt.md` | `template/prompts/refactor.prompt.md` | Updated (YAML frontmatter added) |
| `.github/prompts/test-gen.prompt.md` | `template/prompts/test-gen.prompt.md` | Updated (YAML frontmatter added) |
| `.github/prompts/review-file.prompt.md` | `template/prompts/review-file.prompt.md` | Updated (YAML frontmatter added) |
| `.github/prompts/commit-msg.prompt.md` | `template/prompts/commit-msg.prompt.md` | Updated (YAML frontmatter added) |
| `.github/skills/skill-creator/SKILL.md` | `template/skills/skill-creator/SKILL.md` | Updated (`/create-skill` reference) |
| `.github/skills/skill-management/SKILL.md` | `template/skills/skill-management/SKILL.md` | Updated (agent plugins, org agents) |
| `.github/skills/mcp-management/SKILL.md` | `template/skills/mcp-management/SKILL.md` | Updated (MCP GA, capabilities, discovery) |
| `.github/hooks/scripts/guard-destructive.sh` | `template/hooks/scripts/guard-destructive.sh` | Updated (auto-approval documentation) |
| `.copilot/workspace/HEARTBEAT.md` | `template/workspace/HEARTBEAT.md` | Updated (agent compatibility check) |
| `.copilot/workspace/TOOLS.md` | `template/workspace/TOOLS.md` | Updated (built-in tools table) |
| `.vscode/mcp.json` | `template/vscode/mcp.json` | Updated (**`memory` server removed** — replaced by built-in `/memories/` tool) |
| `.copilot/workspace/MEMORY.md` | `template/workspace/MEMORY.md` | Updated (coexistence section rewritten for built-in memory) |
| `.copilot/workspace/USER.md` | `template/workspace/USER.md` | Updated (coexistence note added) |
| `.github/skills/webapp-testing/SKILL.md` | `template/skills/webapp-testing/SKILL.md` | Updated (v2.0 — dual-path: browser tools + Playwright) |
| `.github/skills/conventional-commit/SKILL.md` | `template/skills/conventional-commit/SKILL.md` | Updated (`git.addAICoAuthor` section added) |
| `.github/skills/plugin-management/SKILL.md` | `template/skills/plugin-management/SKILL.md` | **New** (agent plugin discovery, evaluation, management) |
| `.github/agents/doctor.agent.md` | `.github/agents/doctor.agent.md` | Updated (D11 agent plugin health check) |
| `.copilot/workspace/DOC_INDEX.json` | `.copilot/workspace/DOC_INDEX.json` | **New** (canonical machine-readable docs metadata index) |
| `scripts/sync-doc-index.sh` | `scripts/sync-doc-index.sh` | **New** (sync/check canonical docs index) |
| `tests/test-doc-consistency.sh` | `tests/test-doc-consistency.sh` | Updated (DOC_INDEX and sync-script checks) |
| `.github/workflows/ci.yml` | `.github/workflows/ci.yml` | Updated (DOC_INDEX required-file + sync check + docs consistency test) |
| `README.md` | `README.md` | Updated (repository layout deduplicated to canonical references) |
| `AGENTS.md` | `AGENTS.md` | Updated (file map deduplicated to canonical references + high-signal map) |

**Manual actions**:

1. If you rely on the MCP `memory` server, re-add it manually to `.vscode/mcp.json` after updating. VS Code's built-in memory tool (`/memories/`) is the recommended replacement.

---

## v3.1.0

See **v3.2.0** — this release is bundled into v3.2.0 via its `Includes` field.

---

## v3.0.4

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | — | — | v3.0.3, v3.0.2, v3.0.1 |

**New placeholders**: —

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/setup.agent.md` | `.github/agents/setup.agent.md` | Updated (LLM-clarity fixes) |
| `.github/agents/coding.agent.md` | `.github/agents/coding.agent.md` | Updated |
| `.github/agents/review.agent.md` | `.github/agents/review.agent.md` | Updated |
| `.github/agents/fast.agent.md` | `.github/agents/fast.agent.md` | Updated |
| `.github/skills/*/SKILL.md` (all 7) | `template/skills/*/SKILL.md` | Updated (5 bug fixes) |

**Manual actions**: None — all changes are in companion files and can be auto-applied.

---

## v3.0.3

See **v3.0.4** — this release is bundled into v3.0.4 via its `Includes` field.

---

## v3.0.2

See **v3.0.4** — this release is bundled into v3.0.4 via its `Includes` field.

---

## v3.0.1

See **v3.0.4** — this release is bundled into v3.0.4 via its `Includes` field.

---

## v3.0.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| **Yes** | §2, §4, §5, §7, §8, §9, §11, §12 | — | v2.3.0 (untagged) |

**Breaking change**: Section count remains 13 but §8 significantly expanded (Attention Budget policy, Heartbeat retrospective redesign). §4 adds read-before-claiming rule. §11 adds parallel execution directive and output efficiency rule. §12 replaces "steps not prose" with "steps for procedures, goals for judgment".

**New placeholders**: —

**Companion files added**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/update.agent.md` | `.github/agents/update.agent.md` | New |
| `.github/agents/doctor.agent.md` | `.github/agents/doctor.agent.md` | New |
| `.github/skills/issue-triage/SKILL.md` | `template/skills/issue-triage/SKILL.md` | New |

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/setup.agent.md` | `.github/agents/setup.agent.md` | Updated |
| `.github/agents/coding.agent.md` | `.github/agents/coding.agent.md` | Updated |
| `.github/agents/review.agent.md` | `.github/agents/review.agent.md` | Updated |
| `.github/agents/fast.agent.md` | `.github/agents/fast.agent.md` | Updated |
| `.copilot/workspace/HEARTBEAT.md` | `template/workspace/HEARTBEAT.md` | Updated (retrospective redesign) |
| `.copilot/workspace/MEMORY.md` | `template/workspace/MEMORY.md` | Updated (MCP memory coexistence) |

**Manual actions**:

| Action | Details |
|--------|---------|
| Version tracking migration | Installed version moved from `VERSION.md` → `.github/copilot-version.md`. If your project has its own `VERSION.md`, this avoids collision. The update protocol handles this automatically. |

---

## v2.2.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | — | — | — |

**New placeholders**: —

**Companion files**: — (changes were to SETUP.md UX only, not consumer-facing files)

**Manual actions**: None

---

## v2.1.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §8, §11 | — | — |

**What changed**: §8 adds Agent Hooks subsection and Heartbeat Protocol subsection. §11 adds built-in tool discovery step (1.5 BUILT-IN). W15 examples expanded in §6.

**New placeholders**: —

**Companion files added**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/hooks/copilot-hooks.json` | `template/hooks/copilot-hooks.json` | New |
| `.github/hooks/scripts/session-start.sh` | `template/hooks/scripts/session-start.sh` | New |
| `.github/hooks/scripts/guard-destructive.sh` | `template/hooks/scripts/guard-destructive.sh` | New |
| `.github/hooks/scripts/post-edit-lint.sh` | `template/hooks/scripts/post-edit-lint.sh` | New |
| `.github/hooks/scripts/enforce-retrospective.sh` | `template/hooks/scripts/enforce-retrospective.sh` | New |
| `.github/hooks/scripts/save-context.sh` | `template/hooks/scripts/save-context.sh` | New |
| `.copilot/workspace/HEARTBEAT.md` | `template/workspace/HEARTBEAT.md` | New |

**Manual actions**: None — hooks are opt-in and work immediately after file creation.

---

## v2.0.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| **Yes** | §9, §10 | §13 | — |

**Breaking change**: New §13 (Model Context Protocol) changes section count from 12 to 13. Interview expands to 22 questions (E22 added to Expert tier).

**New placeholders**: `{{MCP_STACK_SERVERS}}` (§13), `{{MCP_CUSTOM_SERVERS}}` (§13)

**Companion files added**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.vscode/mcp.json` | `template/vscode/mcp.json` | New |
| `.github/skills/mcp-builder/SKILL.md` | `template/skills/mcp-builder/SKILL.md` | New |
| `.github/skills/webapp-testing/SKILL.md` | `template/skills/webapp-testing/SKILL.md` | New |

**Manual actions**:

| Action | Details |
|--------|---------|
| Add E22 to §10 User Preferences | Manually add an `MCP servers` row to your User Preferences table |
| Configure MCP servers | Edit `.vscode/mcp.json` to enable/disable servers for your project |
| Resolve new placeholders | Set `{{MCP_STACK_SERVERS}}` and `{{MCP_CUSTOM_SERVERS}}` in §10 placeholder table |

---

## v1.4.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §6, §10, §12 | — | v1.2.0, v1.3.0 (untagged) |

**What changed**: §6 expanded with 8 AI-specific waste categories (W9–W16). §10 adds Graduated Trust Model (Verification Levels subsection). §12 adds `compatibility` and `allowed-tools` skill fields.

**New placeholders**: `{{TRUST_OVERRIDES}}` (§10)

**Companion files added**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/instructions/tests.instructions.md` | `.github/instructions/tests.instructions.md` | New |
| `.github/instructions/api-routes.instructions.md` | `.github/instructions/api-routes.instructions.md` | New |
| `.github/instructions/config.instructions.md` | `.github/instructions/config.instructions.md` | New |
| `.github/instructions/docs.instructions.md` | `.github/instructions/docs.instructions.md` | New |
| `.github/prompts/explain.prompt.md` | `.github/prompts/explain.prompt.md` | New |
| `.github/prompts/refactor.prompt.md` | `.github/prompts/refactor.prompt.md` | New |
| `.github/prompts/test-gen.prompt.md` | `.github/prompts/test-gen.prompt.md` | New |
| `.github/prompts/review-file.prompt.md` | `.github/prompts/review-file.prompt.md` | New |
| `.github/prompts/commit-msg.prompt.md` | `.github/prompts/commit-msg.prompt.md` | New |

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/skills/*/SKILL.md` (all 4) | `template/skills/*/SKILL.md` | Updated (`compatibility` + `allowed-tools` fields) |

**Manual actions**:

| Action | Details |
|--------|---------|
| Add E21 to §10 User Preferences | Manually add a `Verification trust` row and resolve `{{TRUST_OVERRIDES}}` |
| Update skill frontmatter | Optionally add `compatibility` and `allowed-tools` to your existing skills |

---

## v1.1.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §2, §9, §10 | §11, §12 | v1.0.1, v1.0.2, v1.0.3 (untagged) |

**What changed**: §2 gains Extension Review and Test Coverage Review subsections. §9 updated (subagents inherit §11, §12). §10 User Preferences expanded to 20 rows. §11 Tool Protocol and §12 Skill Protocol are entirely new sections. Codex warning added to model quick reference.

**New placeholders**: `{{SKILL_SEARCH_PREFERENCE}}` (§10)

**Companion files added**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/setup.agent.md` | `.github/agents/setup.agent.md` | New |
| `.github/agents/coding.agent.md` | `.github/agents/coding.agent.md` | New |
| `.github/agents/review.agent.md` | `.github/agents/review.agent.md` | New |
| `.github/agents/fast.agent.md` | `.github/agents/fast.agent.md` | New |
| `.github/skills/skill-creator/SKILL.md` | `template/skills/skill-creator/SKILL.md` | New |
| `.github/skills/fix-ci-failure/SKILL.md` | `template/skills/fix-ci-failure/SKILL.md` | New |
| `.github/skills/lean-pr-review/SKILL.md` | `template/skills/lean-pr-review/SKILL.md` | New |
| `.github/skills/conventional-commit/SKILL.md` | `template/skills/conventional-commit/SKILL.md` | New |

**Manual actions**:

| Action | Details |
|--------|---------|
| Add A15 to §10 User Preferences | Manually add a `Skill search` row and resolve `{{SKILL_SEARCH_PREFERENCE}}` |
