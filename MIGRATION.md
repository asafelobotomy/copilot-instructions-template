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

**Available tags**: v3.4.0, v3.4.1, v4.0.0, v4.1.0, v4.1.1, v4.2.0, v5.0.0, v5.0.1, v5.1.0, v5.2.0, v5.3.0, v5.4.0, v5.5.0, v5.6.0, v5.7.0, v5.8.0, v5.9.0, v5.10.0

## Unreleased — workspace and scripts reorganization

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| Yes (layout) | §8, §9 | — | — |

**What changed**: Reorganizes `.copilot/workspace/` into layered subdirectories (`identity/`, `knowledge/`, `operations/`, `runtime/`), renames `scripts/tests/` to `scripts/harness/`, moves `scripts/validate/validate-agent-frontmatter.sh` to `scripts/ci/`, and flattens `logs/copilot/secrets/` to `logs/secrets/`.

**Breaking**: Workspace file paths changed. Hook scripts now expect files in subdirectory paths. Consumers with existing `.copilot/workspace/` files need to run the manual actions below.

**New placeholders**: none

**Companion files added**: none

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.copilot/workspace/identity/IDENTITY.md` | `template/workspace/identity/IDENTITY.md` | Moved from `.copilot/workspace/IDENTITY.md` |
| `.copilot/workspace/identity/SOUL.md` | `template/workspace/identity/SOUL.md` | Moved from `.copilot/workspace/SOUL.md` |
| `.copilot/workspace/identity/BOOTSTRAP.md` | `template/workspace/identity/BOOTSTRAP.md` | Moved from `.copilot/workspace/BOOTSTRAP.md` |
| `.copilot/workspace/knowledge/MEMORY.md` | `template/workspace/knowledge/MEMORY.md` | Moved from `.copilot/workspace/MEMORY.md` |
| `.copilot/workspace/knowledge/MEMORY-GUIDE.md` | `template/workspace/knowledge/MEMORY-GUIDE.md` | Moved from `.copilot/workspace/MEMORY-GUIDE.md` |
| `.copilot/workspace/knowledge/RESEARCH.md` | `template/workspace/knowledge/RESEARCH.md` | Moved from `.copilot/workspace/RESEARCH.md` |
| `.copilot/workspace/knowledge/TOOLS.md` | `template/workspace/knowledge/TOOLS.md` | Moved from `.copilot/workspace/TOOLS.md` |
| `.copilot/workspace/knowledge/USER.md` | `template/workspace/knowledge/USER.md` | Moved from `.copilot/workspace/USER.md` |
| `.copilot/workspace/knowledge/diaries/README.md` | `template/workspace/knowledge/diaries/README.md` | Moved from `.copilot/workspace/diaries/README.md` |
| `.copilot/workspace/operations/HEARTBEAT.md` | `template/workspace/operations/HEARTBEAT.md` | Moved from `.copilot/workspace/HEARTBEAT.md` |
| `.copilot/workspace/operations/commit-style.md` | `template/workspace/operations/commit-style.md` | Moved from `.copilot/workspace/commit-style.md` |
| `.copilot/workspace/operations/ledger.md` | `template/workspace/operations/ledger.md` | Moved from `.copilot/workspace/ledger.md` |
| `.copilot/workspace/operations/workspace-index.json` | `template/workspace/operations/workspace-index.json` | Moved from `.copilot/workspace/workspace-index.json` |
| All hook scripts | `template/hooks/scripts/*` | Updated (workspace subdirectory paths) |

**Manual actions**:

1. Create subdirectories and move workspace files:

```bash
cd .copilot/workspace
mkdir -p identity knowledge/diaries operations runtime
# Identity (L0)
git mv IDENTITY.md SOUL.md BOOTSTRAP.md identity/
# Knowledge (L1)
git mv MEMORY.md MEMORY-GUIDE.md RESEARCH.md TOOLS.md USER.md knowledge/
if [ -d diaries ]; then
    for path in diaries/*; do
        [ -e "$path" ] || continue
        git mv "$path" knowledge/diaries/ 2>/dev/null || mv "$path" knowledge/diaries/
    done
    rmdir diaries 2>/dev/null || true
fi
# Operations (L2)
git mv HEARTBEAT.md commit-style.md ledger.md workspace-index.json operations/
# Runtime files (if present, not tracked)
mv state.json .heartbeat-events.jsonl .heartbeat-session runtime/ 2>/dev/null
mv *.lock runtime/ 2>/dev/null
```

1. Update `.gitignore` — replace individual runtime file entries with:

```gitignore
.copilot/workspace/runtime/
```

1. Update `logs/` layout if you use `scan-secrets.sh`:

```bash
mkdir -p logs/secrets logs/audit logs/tests
mv logs/copilot/secrets/* logs/secrets/ 2>/dev/null
rm -rf logs/copilot
```

## v5.10.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| TBD | — | — | — |

**What changed**: *(stub — fill in before the next release or immediately after)*

**New placeholders**: none

**Companion files added**: none

**Companion files updated**: none

**Manual actions**: None

---

## v5.9.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | None | None | — |

**What changed**: Tightens the MCP sandbox defaults for `git` and `heartbeat`, updates the consumer MCP setup flow so optional servers are selected explicitly during setup, preserves per-server MCP enablement during updates, and adds first-wave MCP allowlists to the main specialist agents.

**New placeholders**: none

**Companion files added**: none

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/audit.agent.md` | `.github/agents/audit.agent.md` | Updated (explicit MCP allowlist) |
| `.github/agents/coding.agent.md` | `.github/agents/coding.agent.md` | Updated (explicit MCP allowlist) |
| `.github/agents/commit.agent.md` | `.github/agents/commit.agent.md` | Updated (explicit MCP allowlist) |
| `.github/agents/debugger.agent.md` | `.github/agents/debugger.agent.md` | Updated (explicit MCP allowlist) |
| `.github/agents/docs.agent.md` | `.github/agents/docs.agent.md` | Updated (explicit MCP allowlist) |
| `.github/agents/researcher.agent.md` | `.github/agents/researcher.agent.md` | Updated (explicit MCP allowlist) |
| `.github/agents/review.agent.md` | `.github/agents/review.agent.md` | Updated (explicit MCP allowlist) |
| `.github/skills/mcp-management/SKILL.md` | `template/skills/mcp-management/SKILL.md` | Updated (consumer MCP selection guidance and `mcp-servers` caveat) |
| `.vscode/mcp.json` | `template/vscode/mcp.json` | Updated (consumer MCP setup selection flow and tighter sandbox defaults) |

**Manual actions**: None — existing consumer `.vscode/mcp.json` server enablement is preserved during updates. Review the file only if you want to opt into newly available optional MCP servers.

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
| `.copilot/workspace/operations/HEARTBEAT.md` | `template/workspace/operations/HEARTBEAT.md` | Updated (active-work heartbeat guidance) |
| `.copilot/workspace/operations/workspace-index.json` | `template/workspace/operations/workspace-index.json` | Updated (expanded hook companion inventory) |

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
| Yes | §2, §10, §11, §12, §13 | §11, §12, §13 | MCP, hooks, skills, starter kits |

**What changed**: Major platform expansion. Adds Tool Protocol (§11), Agent Skills (§12), and MCP Protocol (§13), expands the setup interview and override surface, introduces lifecycle hooks plus remote update/bootstrap flows, and starts shipping model-pinned agents and starter kits. Setup now writes `.vscode/mcp.json`, so the section count increases from 12 to 13 and consumers need to account for the new MCP surface.

**New placeholders**: none

**Companion files added**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/*.agent.md` | `.github/agents/*.agent.md` | **New** (model-pinned specialist agents and routing surfaces) |
| `.github/skills/**` | `template/skills/**` | **New** (Agent Skills system and starter skills) |
| `.github/hooks/copilot-hooks.json` | `template/hooks/copilot-hooks.json` | **New** (agent lifecycle hook wiring) |
| `.github/hooks/scripts/*` | `template/hooks/scripts/*` | **New** (session-start, save-context, post-edit lint, guard-destructive, enforce-retrospective, shared hook helpers) |
| `.github/workflows/copilot-setup-steps.yml` | `template/copilot-setup-steps.yml` | **New** (bootstrap workflow) |
| `.vscode/mcp.json` | `template/vscode/mcp.json` | **New** (MCP server configuration; conditional during setup) |
| `.github/starter-kits/<kit>/` | `starter-kits/<kit>/` | **New** (starter-kit plugin bundles) |

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/copilot-instructions.md` | `template/copilot-instructions.md` | Updated (section layout, hooks, tools, skills, and MCP workflow) |
| `SETUP.md` | `SETUP.md` | Updated (remote bootstrap, interview expansion, MCP setup) |
| `UPDATE.md` | `UPDATE.md` | Updated (full update protocol and restore paths) |
| `AGENTS.md` | `AGENTS.md` | Updated (trigger phrases and routing entry points) |
| `MODELS.md` | `MODELS.md` | Updated (model registry and sync workflow) |
| `.copilot/workspace/identity/BOOTSTRAP.md` | `template/workspace/identity/BOOTSTRAP.md` | Updated (toolbox/bootstrap guidance) |
| `.copilot/workspace/operations/HEARTBEAT.md` | `template/workspace/operations/HEARTBEAT.md` | Updated (heartbeat and retrospective workflow) |
| `.copilot/workspace/knowledge/MEMORY.md` | `template/workspace/knowledge/MEMORY.md` | Updated (memory guidance) |
| `.copilot/workspace/knowledge/RESEARCH.md` | `template/workspace/knowledge/RESEARCH.md` | Updated (research URL tracker) |

**Manual actions**: None

## v5.0.1

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | None | None | — |

**What changed**: Normalises blocking hook payloads to use `continue` instead of `decision`, updates retrospective and PowerShell tests to match, and keeps release/version sync touching both the repo-live and template instruction files.

**New placeholders**: none

**Companion files added**: none

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/copilot-instructions.md` | `template/copilot-instructions.md` | Updated (version-sync and release-managed markers) |
| `.github/hooks/scripts/enforce-retrospective.ps1` | `template/hooks/scripts/enforce-retrospective.ps1` | Updated (PowerShell `continue` payload contract) |
| `.github/hooks/scripts/enforce-retrospective.sh` | `template/hooks/scripts/enforce-retrospective.sh` | Updated (shell `continue` payload contract) |
| `.github/hooks/scripts/guard-destructive.ps1` | `template/hooks/scripts/guard-destructive.ps1` | Updated (PowerShell blocking payload contract) |
| `.github/hooks/scripts/guard-destructive.sh` | `template/hooks/scripts/guard-destructive.sh` | Updated (shell blocking payload contract) |

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

In `.copilot/workspace/operations/HEARTBEAT.md`, replace the `## Response Contract` section with:

```markdown
## Response Contract

- Always append a History row when the trigger is Session start or Explicit — regardless of check results.
- For all other triggers, append a History row only if a check raised an alert or retrospective output was persisted to SOUL.md / MEMORY.md / USER.md.
- If checks pass and nothing was persisted on a non-explicit trigger, keep Pulse as `HEARTBEAT_OK` and omit the History row.
```

**Action 2 — Rename `DOC_INDEX.json` if present** (one-time cleanup for consumers set up before v5.0.0)

If `.copilot/workspace/DOC_INDEX.json` exists, rename it:

```bash
mv .copilot/workspace/DOC_INDEX.json .copilot/workspace/operations/workspace-index.json 2>/dev/null || true
```

Then update any agent count or skill count references inside the file to match the current `.github/agents/` and `.github/skills/` directories.

## v5.4.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §4, §5 | — | — |

**What changed**: Adds detailed terminal-discipline guidance to Coding Conventions, adds targeted-test selector guidance to PDCA phase checks, and refreshes heartbeat/runtime companion scripts plus workspace drift inventory support.

**New placeholders**: none

**Companion files added**: none

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/audit.agent.md` | `.github/agents/audit.agent.md` | Updated (audit workflow and coverage guidance) |
| `.github/agents/coding.agent.md` | `.github/agents/coding.agent.md` | Updated (task brief and verification workflow) |
| `.github/agents/explore.agent.md` | `.github/agents/explore.agent.md` | Updated (repo scan guidance) |
| `.github/agents/extensions.agent.md` | `.github/agents/extensions.agent.md` | Updated (extension-management workflow) |
| `.github/agents/researcher.agent.md` | `.github/agents/researcher.agent.md` | Updated (research handoff guidance) |
| `.github/agents/setup.agent.md` | `.github/agents/setup.agent.md` | Updated (setup protocol alignment) |
| `.github/hooks/scripts/heartbeat-policy.json` | `template/hooks/scripts/heartbeat-policy.json` | Updated (policy thresholds and messages) |
| `.github/hooks/scripts/mcp-heartbeat-server.py` | `template/hooks/scripts/mcp-heartbeat-server.py` | Updated (reflection payload and runtime helpers) |
| `.github/hooks/scripts/pulse_runtime.ps1` | `template/hooks/scripts/pulse_runtime.ps1` | Updated (PowerShell runtime parity) |
| `.github/hooks/scripts/pulse_runtime.py` | `template/hooks/scripts/pulse_runtime.py` | Updated (runtime threshold handling) |
| `.github/hooks/scripts/pulse_state.ps1` | `template/hooks/scripts/pulse_state.ps1` | Updated (PowerShell state parity) |
| `.github/hooks/scripts/pulse_state.py` | `template/hooks/scripts/pulse_state.py` | Updated (state tracking refinements) |
| `.github/hooks/scripts/scan-secrets.ps1` | `template/hooks/scripts/scan-secrets.ps1` | Updated (PowerShell secret-scan parity) |
| `.copilot/workspace/operations/HEARTBEAT.md` | `template/workspace/operations/HEARTBEAT.md` | Updated (heartbeat checks and reporting) |
| `.copilot/workspace/knowledge/TOOLS.md` | `template/workspace/knowledge/TOOLS.md` | Updated (tooling inventory guidance) |
| `.copilot/workspace/operations/workspace-index.json` | `template/workspace/operations/workspace-index.json` | Updated (expanded companion inventory) |
| `CLAUDE.md` | `template/CLAUDE.md` | Updated (Claude compatibility parity) |

**Manual actions**: None

## v5.5.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §9 | — | — |

**What changed**: Expands the Setup specialist scope to cover backup restore and factory restore flows so the delegation map matches the recovery protocol.

**New placeholders**: none

**Companion files added**: none

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/coding.agent.md` | `.github/agents/coding.agent.md` | Updated (specialist escalation guidance) |
| `.github/agents/fast.agent.md` | `.github/agents/fast.agent.md` | Updated (specialist escalation guidance) |
| `.github/agents/setup.agent.md` | `.github/agents/setup.agent.md` | Updated (factory-restore and backup-restore workflow) |

**Manual actions**: None

## v5.6.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §5 | — | — |

**What changed**: Strengthens PDCA with explicit requirements summaries, introduces the four-tier Test Scope Policy, adds an Intent-Gate step to Structured Thinking, and refreshes hook/workspace companions to support the tighter workflow.

**New placeholders**: none

**Companion files added**: none

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/audit.agent.md` | `.github/agents/audit.agent.md` | Updated (audit flow alignment) |
| `.github/agents/coding.agent.md` | `.github/agents/coding.agent.md` | Updated (PDCA/testing guidance alignment) |
| `.github/agents/commit.agent.md` | `.github/agents/commit.agent.md` | Updated (commit workflow alignment) |
| `.github/agents/extensions.agent.md` | `.github/agents/extensions.agent.md` | Updated (extensions workflow alignment) |
| `.github/agents/fast.agent.md` | `.github/agents/fast.agent.md` | Updated (quick-task workflow alignment) |
| `.github/agents/review.agent.md` | `.github/agents/review.agent.md` | Updated (review workflow alignment) |
| `.github/agents/setup.agent.md` | `.github/agents/setup.agent.md` | Updated (setup workflow alignment) |
| `.github/hooks/scripts/guard-destructive.ps1` | `template/hooks/scripts/guard-destructive.ps1` | Updated (PowerShell guard parity) |
| `.github/hooks/scripts/guard-destructive.sh` | `template/hooks/scripts/guard-destructive.sh` | Updated (destructive-command guard hardening) |
| `.github/hooks/scripts/pulse.ps1` | `template/hooks/scripts/pulse.ps1` | Updated (PowerShell pulse parity) |
| `.github/hooks/scripts/pulse.sh` | `template/hooks/scripts/pulse.sh` | Updated (pulse workflow tightening) |
| `.github/hooks/scripts/pulse_state.py` | `template/hooks/scripts/pulse_state.py` | Updated (state tracking refinements) |
| `.github/hooks/scripts/save-context.ps1` | `template/hooks/scripts/save-context.ps1` | Updated (PowerShell save-context parity) |
| `.github/hooks/scripts/save-context.sh` | `template/hooks/scripts/save-context.sh` | Updated (context-preservation flow) |
| `.github/hooks/scripts/scan-secrets.ps1` | `template/hooks/scripts/scan-secrets.ps1` | Updated (PowerShell secret scan parity) |
| `.github/hooks/scripts/scan-secrets.sh` | `template/hooks/scripts/scan-secrets.sh` | Updated (secret-scan workflow) |
| `.github/hooks/scripts/session-start.ps1` | `template/hooks/scripts/session-start.ps1` | Updated (PowerShell session-start parity) |
| `.github/hooks/scripts/session-start.sh` | `template/hooks/scripts/session-start.sh` | Updated (session-start context injection) |
| `.github/hooks/scripts/subagent-start.ps1` | `template/hooks/scripts/subagent-start.ps1` | Updated (PowerShell subagent-start parity) |
| `.github/hooks/scripts/subagent-start.sh` | `template/hooks/scripts/subagent-start.sh` | Updated (subagent-start workflow) |
| `.github/hooks/scripts/subagent-stop.ps1` | `template/hooks/scripts/subagent-stop.ps1` | Updated (PowerShell subagent-stop parity) |
| `.github/hooks/scripts/subagent-stop.sh` | `template/hooks/scripts/subagent-stop.sh` | Updated (subagent-stop workflow) |
| `.github/instructions/config.instructions.md` | `template/instructions/config.instructions.md` | Updated (config conventions) |
| `.copilot/workspace/knowledge/MEMORY.md` | `template/workspace/knowledge/MEMORY.md` | Updated (memory guidance) |
| `.copilot/workspace/operations/workspace-index.json` | `template/workspace/operations/workspace-index.json` | Updated (expanded hook inventory) |

**Manual actions**: None

## v5.7.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §4 | — | — |

**What changed**: Expands terminal discipline with isolated-shell guidance, adds a routing manifest and new Debugger/Docs/Planner specialists, and refreshes hook orchestration plus workspace heartbeat/memory inventory for the routing rollout.

**New placeholders**: none

**Companion files added**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/debugger.agent.md` | `.github/agents/debugger.agent.md` | **New** (root-cause debugging specialist) |
| `.github/agents/docs.agent.md` | `.github/agents/docs.agent.md` | **New** (documentation specialist) |
| `.github/agents/planner.agent.md` | `.github/agents/planner.agent.md` | **New** (execution-planning specialist) |
| `.github/agents/routing-manifest.json` | `.github/agents/routing-manifest.json` | **New** (agent routing sidecar) |

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/coding.agent.md` | `.github/agents/coding.agent.md` | Updated (routing-aware implementation guidance) |
| `.github/agents/fast.agent.md` | `.github/agents/fast.agent.md` | Updated (routing-aware quick-task guidance) |
| `.github/agents/review.agent.md` | `.github/agents/review.agent.md` | Updated (routing-aware review guidance) |
| `.github/hooks/copilot-hooks.json` | `template/hooks/copilot-hooks.json` | Updated (hook routing coverage) |
| `.github/hooks/scripts/guard-destructive.ps1` | `template/hooks/scripts/guard-destructive.ps1` | Updated (PowerShell parity) |
| `.github/hooks/scripts/guard-destructive.sh` | `template/hooks/scripts/guard-destructive.sh` | Updated (guard refinements) |
| `.github/hooks/scripts/pulse.ps1` | `template/hooks/scripts/pulse.ps1` | Updated (PowerShell pulse parity) |
| `.github/hooks/scripts/pulse.sh` | `template/hooks/scripts/pulse.sh` | Updated (routing-aware pulse orchestration) |
| `.github/hooks/scripts/pulse_runtime.ps1` | `template/hooks/scripts/pulse_runtime.ps1` | Updated (PowerShell runtime parity) |
| `.github/hooks/scripts/pulse_runtime.py` | `template/hooks/scripts/pulse_runtime.py` | Updated (runtime routing support) |
| `.github/hooks/scripts/pulse_state.ps1` | `template/hooks/scripts/pulse_state.ps1` | Updated (PowerShell state parity) |
| `.github/hooks/scripts/pulse_state.py` | `template/hooks/scripts/pulse_state.py` | Updated (state routing support) |
| `.github/hooks/scripts/save-context.ps1` | `template/hooks/scripts/save-context.ps1` | Updated (PowerShell save-context parity) |
| `.github/hooks/scripts/save-context.sh` | `template/hooks/scripts/save-context.sh` | Updated (context compaction support) |
| `.github/hooks/scripts/session-start.ps1` | `template/hooks/scripts/session-start.ps1` | Updated (PowerShell session-start parity) |
| `.github/hooks/scripts/session-start.sh` | `template/hooks/scripts/session-start.sh` | Updated (session-start routing injection) |
| `.copilot/workspace/operations/HEARTBEAT.md` | `template/workspace/operations/HEARTBEAT.md` | Updated (heartbeat routing guidance) |
| `.copilot/workspace/knowledge/MEMORY.md` | `template/workspace/knowledge/MEMORY.md` | Updated (memory routing guidance) |
| `.copilot/workspace/operations/workspace-index.json` | `template/workspace/operations/workspace-index.json` | Updated (routing inventory) |

**Manual actions**: None

## v5.8.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | None | None | — |

**What changed**: Adds repository-management hardening and refreshes hook utilities for clock summaries, post-edit linting, and secret scanning. No consumer instruction sections changed.

**New placeholders**: none

**Companion files added**: none

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/hooks/scripts/heartbeat_clock_summary.py` | `template/hooks/scripts/heartbeat_clock_summary.py` | Updated (clock-summary helper) |
| `.github/hooks/scripts/post-edit-lint.sh` | `template/hooks/scripts/post-edit-lint.sh` | Updated (post-edit formatting flow) |
| `.github/hooks/scripts/scan-secrets.sh` | `template/hooks/scripts/scan-secrets.sh` | Updated (secret-scan hardening) |

**Manual actions**: None

---

## v5.1.0

| Breaking | Sections changed | Sections added | Includes |
|----------|-----------------|----------------|----------|
| No | §10 | — | — |

**What changed**: Adds setup interview questions and companion manifests, introduces canonical workspace inventory/bootstrap support for setup and update flows, and tightens guard-destructive handling for setup-time hooks.

**New placeholders**: none

**Companion files added**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/hooks/scripts/mcp-npx.sh` | `template/hooks/scripts/mcp-npx.sh` | **New** (npm-based MCP launcher) |
| `.github/hooks/scripts/mcp-uvx.sh` | `template/hooks/scripts/mcp-uvx.sh` | **New** (uvx-based MCP launcher) |
| `.copilot/workspace/operations/workspace-index.json` | `template/workspace/operations/workspace-index.json` | **New** (canonical machine-readable companion inventory) |

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/agents/doctor.agent.md` | `.github/agents/doctor.agent.md` | Updated (audit workflow alignment) |
| `.github/agents/security.agent.md` | `.github/agents/security.agent.md` | Updated (security workflow alignment) |
| `.github/agents/setup.agent.md` | `.github/agents/setup.agent.md` | Updated (setup interview guidance) |
| `.github/hooks/scripts/guard-destructive.ps1` | `template/hooks/scripts/guard-destructive.ps1` | Updated (PowerShell parity) |
| `.github/hooks/scripts/guard-destructive.sh` | `template/hooks/scripts/guard-destructive.sh` | Updated (guard pattern tightening) |
| `.github/hooks/scripts/lib-hooks.sh` | `template/hooks/scripts/lib-hooks.sh` | Updated (shared helper refinements) |
| `.github/hooks/scripts/session-start.ps1` | `template/hooks/scripts/session-start.ps1` | Updated (PowerShell session-start parity) |
| `.github/hooks/scripts/session-start.sh` | `template/hooks/scripts/session-start.sh` | Updated (session-start scaffold guidance) |
| `.github/instructions/docs.instructions.md` | `template/instructions/docs.instructions.md` | Updated (docs guidance) |
| `.copilot/workspace/identity/BOOTSTRAP.md` | `template/workspace/identity/BOOTSTRAP.md` | Updated (bootstrap/tooling guidance) |

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
| `.copilot/workspace/knowledge/RESEARCH.md` | `template/workspace/knowledge/RESEARCH.md` | **New** (URL tracker for research tasks) |
| `.github/hooks/scripts/lib-hooks.sh` | `template/hooks/scripts/lib-hooks.sh` | **New** (shared hook helper library) |

**Companion files updated**:

| Destination | Template source | Action |
|-------------|----------------|--------|
| `.github/hooks/scripts/*.sh` | `template/hooks/scripts/*.sh` | Updated (shared JSON escaping utilities and common helpers) |
| `AGENTS.md` | `AGENTS.md` | Updated (Researcher/Explore agents inventory) |
| `.copilot/workspace/operations/HEARTBEAT.md` | `template/workspace/operations/HEARTBEAT.md` | Updated (metrics freshness and task logging) |
| `.copilot/workspace/knowledge/MEMORY.md` | `template/workspace/knowledge/MEMORY.md` | Updated (documentation refinements) |

**Manual actions**: None
