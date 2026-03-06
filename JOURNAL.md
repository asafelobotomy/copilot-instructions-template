# Development Journal — copilot-instructions-template

Architectural decisions and context are recorded here in ADR style.

---

## 2026-02-27 — Project onboarded to copilot-instructions-template

**Context**: This project adopted the generic Lean/Kaizen Copilot instructions template.
**Decision**: Use `.github/copilot-instructions.md` as the primary agent guidance document, with `.copilot/workspace/` for session-persistent identity state.
**Consequences**: Copilot is authorised to update the instructions file when patterns stabilise (see Living Update Protocol).

---

## 2026-02-27 — Setup finalised

[instructions] Setup complete — SETUP.md removed. See BOOTSTRAP.md for origin record.

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

## 2026-03-06 — Prompt and skill schemas aligned to current VS Code validation

**Context**: After the terminology sweep, the remaining repo-health warnings came from VS Code schema drift: prompt files still used deprecated `mode:` frontmatter, and skill files still stored rich metadata as top-level frontmatter keys that VS Code no longer validates.
**Decision**: Migrate prompt files to `agent:` frontmatter, keep skill frontmatter minimal (`name` and `description`), and preserve skill version/license/tags/compatibility/tool-scope information in a body-level `Skill metadata` note. Update the skill authoring guide, security guide, prompt guide, and CI advisory checks to match the new contract.
**Consequences**: Prompt and skill files now validate cleanly in the editor, the repo keeps the richer metadata it relies on, and the documented authoring pattern matches current VS Code behavior instead of the superseded schema.
