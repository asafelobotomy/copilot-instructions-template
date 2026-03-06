# Development Journal — copilot-instructions-template

Architectural decisions and context are recorded here in ADR style.

---

## 2026-02-27 — Project onboarded to copilot-instructions-template

**Context**: This project adopted the generic Lean/Kaizen Copilot instructions template.
**Decision**: Use `.github/copilot-instructions.md` as the primary agent guidance document, with `.copilot/workspace/` for session-persistent identity state.
**Consequences**: Copilot is authorised to update the instructions file when patterns stabilise (see Living Update Protocol).

---

## 2026-02-27 — Setup finalised

**Context**: The initial setup flow finished populating the template into this repository, and the one-time bootstrap instructions were no longer needed as a live working file.
**Decision**: Remove `SETUP.md` from the repository working set after completion and retain the permanent origin record in `BOOTSTRAP.md`.
**Consequences**: The repository keeps a durable setup audit trail without carrying an obsolete in-progress setup artifact.

---

## 2026-03-05 — Agent plugin distribution deferred to v4.0

**Context**: VS Code 1.110 introduced agent plugins (Preview) that bundle agents, skills, hooks, MCP servers, and slash commands into installable packages. The template's structure maps naturally onto this format.
**Decision**: Defer plugin packaging to v4.0. The plugin API is Preview (breaking changes expected), and the template's core value — the interactive setup interview that resolves `{{PLACEHOLDER}}` tokens — cannot be replicated by static plugin installs. Document as a strategic option in AGENTS-GUIDE.md.
**Consequences**: No code changes. Teams wanting to preview can register the template locally via `chat.plugins.paths`. Revisit when the plugin API reaches GA and supports dynamic configuration.

---

## 2026-03-05 — Claude agent format stubs deferred

**Context**: VS Code supports `.claude/agents/*.md` files with Claude-specific frontmatter as a compatibility layer for Claude Code users. The format uses comma-separated tool strings instead of YAML arrays and lacks model pinning, handoffs, and invocation controls.
**Decision**: Do not ship Claude-format stubs. The `.agent.md` format in `.github/agents/` is the primary standard with richer semantics. Document the format differences and provide a workaround for cross-tool teams in AGENTS-GUIDE.md.
**Consequences**: Teams needing Claude Code compatibility create lightweight `.claude/agents/` stubs manually. Reconsider if Claude Code adoption grows or VS Code adds bidirectional format sync.

---

## 2026-03-05 — Organization-level agents documented

**Context**: GitHub supports publishing agents at the organization/enterprise level via a `.github-private` repository. This allows shared agent configurations across all org repos without per-repo setup.
**Decision**: Expanded the organization-level agents section in AGENTS-GUIDE.md with actionable setup steps: `.github-private` repo structure, the root `agents/` directory convention, the `organizationCustomAgents.enabled` setting, and guidance for using template agents at the org level.
**Consequences**: Consumer projects can now follow documented steps to publish template agents at their org level for team-wide access.

---

## 2026-03-05 — MCP memory server removed from defaults

**Context**: VS Code 1.110 ships a built-in memory tool (`/memories/`) with three persistent scopes: user (cross-workspace), session (conversation-scoped), and repository. The template previously included `@modelcontextprotocol/server-memory` as an always-on MCP server in `.vscode/mcp.json`.
**Decision**: Remove the MCP memory server from defaults. The built-in memory tool is superior: it has three scopes (vs one), persists natively without an npx dependency, and integrates directly with VS Code's context management. All seven workspace identity files (MEMORY.md, USER.md, SOUL.md, IDENTITY.md, TOOLS.md, HEARTBEAT.md, BOOTSTRAP.md) are retained — they serve as git-tracked, team-shared knowledge that built-in memory cannot replace.
**Consequences**: `.vscode/mcp.json` and `template/vscode/mcp.json` updated. §13 updated. `mcp-management` skill and `docs/MCP-GUIDE.md` updated. Non-breaking — users needing the MCP memory server can re-add it manually.

---

## 2026-03-05 — Webapp-testing skill rewritten for dual-path architecture

**Context**: VS Code 1.110 introduced 10 agentic browser tools (`openBrowserPage`, `readPage`, `screenshotPage`, etc.) that allow Copilot to interact with web pages directly (Preview, requires `workbench.browser.enableChatTools`). The existing webapp-testing skill was Playwright-only.
**Decision**: Rewrite the skill (v2.0) with two paths: Path A (built-in browser tools for interactive verification, zero setup) and Path B (Playwright for CI regression testing). They complement each other — Path A for quick dev-time checks, Path B for automated CI gates.
**Consequences**: Both `template/skills/webapp-testing/SKILL.md` and `.github/skills/webapp-testing/SKILL.md` updated. Decision criteria table helps users choose the right path.

---

## 2026-03-05 — Agent plugins integrated as first-class feature

**Context**: Agent plugins (VS Code 1.110+, Preview) bundle agents, skills, hooks, and MCP servers into installable packages. The template referenced plugins in docs but lacked operational integration — no skill, no Doctor check, no trigger phrases, no §12 reference.
**Decision**: Create `plugin-management` skill (discovery, quality gate, conflict resolution, testing-as-plugin workflow). Add D11 health check to Doctor agent for naming conflicts and settings validation. Update §12 Skill Protocol with plugin priority tier. Add trigger phrases to AGENTS.md. Sync repo HEARTBEAT.md with template (missing Retrospective section).
**Consequences**: Plugins are now discoverable and manageable through the same skill/trigger infrastructure as other template features. Doctor agent validates plugin/workspace conflicts. §12 scope hierarchy now has 4 tiers (project > personal > plugin > org).

---

## 2026-03-05 — Canonical documentation index and dedupe guardrails

**Context**: Documentation inventory content had become duplicated across `README.md`, `AGENTS.md`, and other files, increasing drift risk (skills/counts/descriptions diverging between sources).
**Decision**: Introduce `.copilot/workspace/DOC_INDEX.json` as canonical machine-readable metadata inventory, add `scripts/sync-doc-index.sh` for deterministic sync/check, and deduplicate large inventory blocks in `README.md`/`AGENTS.md` to canonical references plus a high-signal map.
**Consequences**: Drift detection moved from manual review to CI enforcement (`tests/test-doc-consistency.sh` + `sync-doc-index.sh --check`). Human-facing docs are shorter and less repetitive, while machine-critical trigger/setup/update semantics remain unchanged.

---

## 2026-03-06 — Terminology normalized around GPT-5.4 and runCommands

**Context**: A full repository review found that the repo had drifted in two directions: model guidance still mixed older review defaults with the newer GPT-5.4 recommendation, and customization manifests mixed `terminal` and `runCommands` terminology across agents, prompts, skills, and docs. Several human-facing docs also still described the removed E19 question and the old direct-question count.
**Decision**: Standardize current-state documentation and manifests around three rules: `GPT-5.4` is the primary deep-review/debugging model, `GPT-5.3-Codex` remains the coding/agentic implementation model, and `runCommands` is the command-execution identifier used in agent/prompt/skill metadata and related examples. Update setup/security/prompt guides, inventory stubs, MCP sampling settings, and doc-consistency tests to enforce the new terminology.
**Consequences**: The repo now presents one consistent model-selection story, one consistent command-execution term in customization metadata, and stronger drift tests for interview semantics, metrics schema, and MCP settings. Historical changelog entries remain untouched as release history.

---

## 2026-03-06 — LLM-facing surfaces slimmed and generated context packs added

**Context**: The repository's machine-facing surfaces had started to drift. `llms.txt` still contained stale review-model guidance, `.github/copilot-instructions.md` kept two heavy review workflows in the always-loaded prompt, and AGENTS.md duplicated a large file map that was already represented canonically in `BIBLIOGRAPHY.md` and `.copilot/workspace/DOC_INDEX.json`.
**Decision**: Move the extension-review and test-coverage-review workflows into dedicated on-demand skills, replace the embedded §2 procedures with concise activation guidance, add generated `llms-ctx.txt` and `llms-ctx-full.txt` artifacts with a sync script, and shrink `AGENTS.md` to a high-signal machine map that points back to canonical inventories.
**Consequences**: The always-loaded core prompt dropped materially in size, AI-facing summaries now have explicit drift checks, the setup flow now scaffolds 13 skills instead of 11, and both human-facing and machine-facing inventories stay aligned through deterministic sync scripts and tests.

---

## 2026-03-06 — Prompt and skill schemas aligned to current VS Code validation

**Context**: After the terminology sweep, the remaining repo-health warnings came from VS Code schema drift: prompt files still used deprecated `mode:` frontmatter, and skill files still stored rich metadata as top-level frontmatter keys that VS Code no longer validates.
**Decision**: Migrate prompt files to `agent:` frontmatter, keep skill frontmatter minimal (`name` and `description`), and preserve skill version/license/tags/compatibility/tool-scope information in a body-level `Skill metadata` note. Update the skill authoring guide, security guide, prompt guide, and CI advisory checks to match the new contract.
**Consequences**: Prompt and skill files now validate cleanly in the editor, the repo keeps the richer metadata it relies on, and the documented authoring pattern matches current VS Code behavior instead of the superseded schema.

---

## 2026-03-06 — Coverage plan advanced with direct sync-script and PowerShell hook tests

**Context**: A static coverage audit found that the shell hooks and `sync-version.sh` were already well covered, but the two metadata generator scripts only had smoke coverage and the PowerShell hook counterparts were effectively untested. The repo also repeated its canonical local test command in several places, making future coverage expansion needlessly expensive to maintain.
**Decision**: Add direct bash test suites for `scripts/sync-doc-index.sh` and `scripts/sync-llms-context.sh`, add bash-driven `pwsh` parity tests for the PowerShell hook scripts, introduce `tests/run-all.sh` as the canonical local test entrypoint, and wire the new suites into `.github/workflows/ci.yml`. While doing that work, tighten the PowerShell `guard-destructive.ps1` regex so its `rm -rf .` behavior matches the validated shell contract.
**Consequences**: The repo now has executable coverage over the sync generators and Windows hook logic, CI runs those suites on every push and pull request, and the main local test contract is centralized in one script instead of duplicated inline across multiple docs and prompts.

---

## 2026-03-06 — Runtime script coverage became a CI gate

**Context**: The expanded test surface made the remaining gap obvious: the repo could say it was "close to 100%" only by inspection, not by measurement. Bash and PowerShell scripts needed a shared, repeatable coverage signal that worked in CI without introducing heavyweight language-specific tooling or breaking the existing JSON-based hook tests.
**Decision**: Add runtime tracing for bash via `BASH_ENV` and xtrace, add runtime tracing for PowerShell via line breakpoints that append to a trace log, and centralize summarization in `scripts/report-script-coverage.sh`. Use a deterministic PowerShell coverage driver instead of the assertion-heavy parity harness, exclude mirrored `.github/hooks/scripts/*` files from the denominator because CI already enforces parity with the template copies, and start with 60% thresholds for bash, PowerShell, and overall coverage.
**Consequences**: Coverage is now measurable and enforced in CI, the repo emits both machine-readable JSON and human-readable Markdown summaries, and future coverage pushes can ratchet the thresholds upward from an observed baseline instead of relying on subjective review.

---

## 2026-03-06 — Inventory markdown files became executable contracts

**Context**: Script coverage and sync-script tests closed the largest executable gaps, but the repo still relied on human discipline for its inventory surfaces. `BIBLIOGRAPHY.md` and `METRICS.md` described the repo state, yet nothing failed automatically when file counts, LOC values, or summary totals drifted.
**Decision**: Add `tests/test-inventory-files.sh` to compare `BIBLIOGRAPHY.md` against the live workspace file set, verify every listed LOC value, enforce the bibliography summary totals, and ensure the latest `METRICS.md` row matches the bibliography summary. Run the new test from both `tests/run-all.sh` and the CI `script-tests` job.
**Consequences**: Markdown inventory files now behave more like generated artifacts with executable drift protection. File additions, removals, and line-count changes surface as test failures instead of being discovered later during manual review.

---

## 2026-03-06 — Core markdown documents gained structural contract tests

**Context**: Inventory drift was now executable, but several high-signal Markdown files still depended on convention alone. A broken local link, a missing changelog section, or a malformed journal entry could still slip through without an explicit test.
**Decision**: Add `tests/test-markdown-contracts.sh` to validate local Markdown links and anchors, require the core `CHANGELOG.md` section set, enforce the ADR triad in `JOURNAL.md`, and keep the main navigation sections present in `README.md` and `AGENTS.md`. Run it from both `tests/run-all.sh` and the CI `script-tests` job.
**Consequences**: Structural Markdown regressions now fail fast in the same way script and inventory drift do, which raises confidence in the repo's machine-facing and human-facing documentation surfaces.

---

## 2026-03-06 — Release metadata and customization files gained executable contracts

**Context**: The repo's documentation and inventory surfaces were now guarded, but release metadata and Copilot customization scaffolds still relied on manual consistency checks. That left room for subtle drift between `VERSION.md`, release-please files, `MIGRATION.md`, and the prompt/instruction frontmatter that VS Code expects.
**Decision**: Add `tests/test-release-contracts.sh` to verify version alignment across `VERSION.md`, `.release-please-manifest.json`, `release-please-config.json`, `CHANGELOG.md`, `MIGRATION.md`, and the release-managed marker files. Add `tests/test-customization-contracts.sh` to enforce prompt and instruction frontmatter plus the guide docs that describe those customization surfaces. Run both tests from `tests/run-all.sh` and the CI `script-tests` job.
**Consequences**: Release metadata drift and broken customization scaffolds now fail as tests, and the migration registry's `Available tags` list stays aligned with the current tagged release instead of silently aging out.

---

## 2026-03-06 — Agents, skills, and template mirrors gained executable contracts

**Context**: Release/customization guards closed another drift layer, but the repo still relied on convention for two important surfaces: the expected `.github/agents/` and `.github/skills/` manifests, and the companion files that are supposed to stay byte-for-byte aligned between `.github/` and `template/`.
**Decision**: Add `tests/test-agent-skill-contracts.sh` to lock the agent and skill inventories, their required frontmatter/body markers, and the guide docs that advertise them. Add `tests/test-template-parity.sh` to enforce exact parity for mirrored hook files and stable mirrored skills, while preserving the known intentional divergences in `mcp-management` and `webapp-testing`. Run both tests from `tests/run-all.sh` and the CI `script-tests` job.
**Consequences**: Agent/skill manifest drift and accidental repo/template desynchronization now fail as explicit tests instead of being discovered later through broken setup scaffolds or review-only inspection.

---

## 2026-03-06 — Shell test scaffolding consolidated into a shared helper layer

**Context**: The coverage push added many new shell-based tests quickly. The newest suites repeated the same counters, repo-root resolution, JSON validation, string assertions, and embedded Python execution logic, which made the test layer noisier than the behavior it was checking.
**Decision**: Create `tests/lib/test-helpers.sh` as a shared assertion/helper module and refactor the newer contract and direct-script suites to source it instead of duplicating that plumbing inline.
**Consequences**: The test layer is more organized, lower-noise, and easier to extend consistently. Future contract tests can focus on behavior and fixtures instead of reimplementing the same shell harness.

---

## 2026-03-06 — Legacy shell suites and the local runner were reorganized

**Context**: The first helper-layer cleanup left a split structure: the newer contract suites shared `tests/lib/test-helpers.sh`, but the older legacy suites still carried their own generic assertion plumbing. The canonical local runner also remained a flat list, which made longer runs harder to scan.
**Decision**: Move the remaining legacy suites (`tests/test-hooks.sh`, `tests/test-guard-destructive.sh`, `tests/test-sync-version.sh`, and `tests/test-security-edge-cases.sh`) onto the shared helper layer where appropriate, and reorganize `tests/run-all.sh` into labeled phases for hook behavior, script behavior, and documentation/contracts.
**Consequences**: The entire test layer now follows one organizational pattern, helper drift is reduced further, and local validation output is easier to navigate without changing test coverage semantics.

---

## 2026-03-06 — Hook tests split by lifecycle surface and CI names aligned

**Context**: Even after the helper-layer cleanup, the bash hook tests still had one broad file (`tests/test-hooks.sh`) covering four different hook scripts. That kept hook ownership coarse and made CI output less aligned with the phase-grouped local runner.
**Decision**: Replace `tests/test-hooks.sh` with four per-hook suites (`tests/test-hook-session-start.sh`, `tests/test-hook-post-edit-lint.sh`, `tests/test-hook-enforce-retrospective.sh`, and `tests/test-hook-save-context.sh`). Update `tests/run-all.sh`, `scripts/report-script-coverage.sh`, and the CI `script-tests` job so both local and CI execution surfaces use the same Hook/Script/Docs phase structure.
**Consequences**: Hook failures now surface with narrower ownership, the local and CI runners read in the same structure, and coverage collection still exercises the same hook scripts through the split suites.

---

## 2026-03-06 — Documentation drift checks split by concern and coverage discovery automated

**Context**: After the hook-suite split, the remaining broad documentation suite still bundled summary-surface discoverability, generated-context checks, setup scaffolding checks, and validation-command drift into one file. The coverage report script also still carried a hand-maintained bash test list, so each new suite required touching the harness by name.
**Decision**: Replace `tests/test-doc-consistency.sh` with `tests/test-doc-discoverability.sh` and `tests/test-doc-platform-contracts.sh`, both using the shared helper layer. Add `tests/test-report-script-coverage.sh` and update `scripts/report-script-coverage.sh` to discover bash suites from the `tests/test-*.sh` naming convention while excluding PowerShell parity and mirror-only contract suites.
**Consequences**: Documentation failures now point to narrower surfaces, the docs phase is easier to extend without creating another catch-all suite, and the coverage harness updates itself for new behavior-oriented bash tests instead of depending on a manual list.
