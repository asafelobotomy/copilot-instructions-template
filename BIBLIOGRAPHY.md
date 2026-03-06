# Bibliography — copilot-instructions-template

Every file in the project is catalogued here. Update this file whenever a file is created, renamed, deleted, or its purpose changes significantly.

| File | Purpose | LOC |
|------|---------|-----|
| **Project root** | | |
| `AGENTS.md` | AI agent entry point — trigger phrases, bootstrap/update/restore sequences | 230 |
| `BIBLIOGRAPHY.md` | This file — complete file catalogue | 170 |
| `CHANGELOG.md` | Keep-a-Changelog version history | 725 |
| `CONTRIBUTING.md` | Contributor guide — workflow, conventions, PR checklist | 83 |
| `JOURNAL.md` | ADR-style development journal | 97 |
| `LICENSE` | MIT license | 21 |
| `llms.txt` | LLM-friendly project summary (llmstxt standard) | 47 |
| `llms-ctx.txt` | Generated compact LLM context pack | 34 |
| `llms-ctx-full.txt` | Generated expanded LLM context pack | 66 |
| `METRICS.md` | Kaizen baseline snapshot table | 9 |
| `README.md` | Project landing page and quick-start guide | 253 |
| `SETUP.md` | Complete setup guide (remote-executable) | 905 |
| `UPDATE.md` | Complete update + restore protocol (remote-executable) | 761 |
| `MIGRATION.md` | Per-version migration registry — sections changed, companion files, breaking changes | 273 |
| `VERSION.md` | Single source of truth for template version (semver) | 1 |
| `release-please-config.json` | Release-please configuration | 15 |
| `.release-please-manifest.json` | Release-please version manifest | 3 |
| `.gitignore` | Git ignore rules | 16 |
| `.markdownlint.json` | Markdownlint configuration | 10 |
| `.markdownlint-cli2.yaml` | Markdownlint CLI v2 configuration | 4 |
| `.vale.ini` | Vale prose linting configuration | 15 |
| **Copilot instructions** | | |
| `.github/copilot-instructions.md` | AI agent guidance (Lean/Kaizen methodology + project conventions) | 390 |
| **Agent files** | | |
| `.github/agents/setup.agent.md` | Model-pinned Setup agent — Claude Sonnet 4.6 | 37 |
| `.github/agents/coding.agent.md` | Model-pinned Coding agent — GPT-5.3-Codex | 30 |
| `.github/agents/review.agent.md` | Model-pinned Review agent — GPT-5.4 | 35 |
| `.github/agents/fast.agent.md` | Model-pinned Fast agent — Claude Haiku 4.5 | 30 |
| `.github/agents/update.agent.md` | Model-pinned Update agent — Claude Sonnet 4.6 | 75 |
| `.github/agents/doctor.agent.md` | Model-pinned Doctor agent — Claude Sonnet 4.6 | 295 |
| **Path-specific instructions** | | |
| `.github/instructions/api-routes.instructions.md` | Instructions for API/route/controller files | 14 |
| `.github/instructions/config.instructions.md` | Instructions for config and rc files | 12 |
| `.github/instructions/docs.instructions.md` | Instructions for Markdown and docs files | 15 |
| `.github/instructions/tests.instructions.md` | Instructions for test files | 15 |
| **Prompt files** | | |
| `.github/prompts/commit-msg.prompt.md` | Slash command `/commit-msg` — Conventional Commits authoring | 17 |
| `.github/prompts/explain.prompt.md` | Slash command `/explain` — waste-aware code explanation | 15 |
| `.github/prompts/refactor.prompt.md` | Slash command `/refactor` — PDCA-driven refactoring | 16 |
| `.github/prompts/review-file.prompt.md` | Slash command `/review-file` — structured Lean file review | 22 |
| `.github/prompts/test-gen.prompt.md` | Slash command `/test-gen` — convention-following test generation | 22 |
| **Agent hooks (repo's own)** | | |
| `.github/hooks/copilot-hooks.json` | Agent lifecycle hooks configuration | 44 |
| `.github/hooks/scripts/session-start.sh` | SessionStart hook — project context injection | 47 |
| `.github/hooks/scripts/session-start.ps1` | SessionStart hook — Windows PowerShell counterpart | 49 |
| `.github/hooks/scripts/guard-destructive.sh` | PreToolUse hook — destructive command guard | 105 |
| `.github/hooks/scripts/guard-destructive.ps1` | PreToolUse hook — Windows PowerShell counterpart | 85 |
| `.github/hooks/scripts/post-edit-lint.sh` | PostToolUse hook — auto-format after edits | 73 |
| `.github/hooks/scripts/post-edit-lint.ps1` | PostToolUse hook — Windows PowerShell counterpart | 68 |
| `.github/hooks/scripts/enforce-retrospective.sh` | Stop hook — retrospective enforcement | 65 |
| `.github/hooks/scripts/enforce-retrospective.ps1` | Stop hook — Windows PowerShell counterpart | 50 |
| `.github/hooks/scripts/save-context.sh` | PreCompact hook — context preservation | 58 |
| `.github/hooks/scripts/save-context.ps1` | PreCompact hook — Windows PowerShell counterpart | 53 |
| **Skills (repo's own)** | | |
| `.github/skills/conventional-commit/SKILL.md` | Skill — Conventional Commits message authoring | 108 |
| `.github/skills/extension-review/SKILL.md` | Skill — VS Code extension audit workflow | 72 |
| `.github/skills/fix-ci-failure/SKILL.md` | Skill — CI failure diagnosis and resolution | 64 |
| `.github/skills/issue-triage/SKILL.md` | Skill — issue triage with severity classification | 83 |
| `.github/skills/lean-pr-review/SKILL.md` | Skill — Lean PR review with waste categories | 102 |
| `.github/skills/mcp-builder/SKILL.md` | Skill — MCP server creation and registration | 155 |
| `.github/skills/plugin-management/SKILL.md` | Skill — agent plugin discovery, evaluation, and management | 104 |
| `.github/skills/skill-creator/SKILL.md` | Skill — meta-skill for authoring new skills | 70 |
| `.github/skills/skill-management/SKILL.md` | Skill — skill discovery, activation, and management | 58 |
| `.github/skills/test-coverage-review/SKILL.md` | Skill — coverage-gap audit and CI recommendation workflow | 90 |
| `.github/skills/tool-protocol/SKILL.md` | Skill — Tool Protocol decision tree and toolbox management | 105 |
| `.github/skills/mcp-management/SKILL.md` | Skill — MCP server configuration and management | 86 |
| `.github/skills/webapp-testing/SKILL.md` | Skill — dual-path web app testing (browser tools + Playwright) | 292 |
| **CI/CD workflows** | | |
| `.github/workflows/ci.yml` | Main CI — structure, shellcheck, markdownlint, actionlint, hooks, version sync | 447 |
| `.github/workflows/links.yml` | Link checker (lychee) | 33 |
| `.github/workflows/release-manual.yml` | Manual release workflow | 67 |
| `.github/workflows/release-please.yml` | Automated release via release-please | 45 |
| `.github/workflows/scorecard.yml` | OpenSSF Scorecard security analysis | 43 |
| `.github/workflows/stale.yml` | Stale issue/PR management | 47 |
| `.github/workflows/vale.yml` | Prose linting CI | 27 |
| **GitHub templates & config** | | |
| `.github/dependabot.yml` | Dependabot dependency update configuration | 17 |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Bug report issue template | 64 |
| `.github/ISSUE_TEMPLATE/feature_request.yml` | Feature request issue template | 49 |
| `.github/PULL_REQUEST_TEMPLATE.md` | Pull request template | 23 |
| **Vale styles** | | |
| `.github/vale/styles/.gitkeep` | Placeholder for custom Vale styles | — |
| `.github/vale/styles/README.md` | Vale custom styles documentation | 26 |
| **Workspace identity** | | |
| `.copilot/workspace/IDENTITY.md` | Agent self-description | 5 |
| `.copilot/workspace/SOUL.md` | Agent values & reasoning patterns | 11 |
| `.copilot/workspace/USER.md` | Observed user profile | 11 |
| `.copilot/workspace/TOOLS.md` | Effective tool usage patterns | 9 |
| `.copilot/workspace/MEMORY.md` | Memory system strategy | 12 |
| `.copilot/workspace/DOC_INDEX.json` | Canonical machine-readable inventory for docs metadata | 89 |
| `.copilot/workspace/BOOTSTRAP.md` | Permanent setup origin record | 28 |
| `.copilot/workspace/HEARTBEAT.md` | Event-driven health check checklist | 60 |
| **VS Code workspace config** | | |
| `.vscode/mcp.json` | MCP server configuration (this repo) | 35 |
| `.vscode/settings.json` | VS Code workspace settings | 139 |
| **Docs** | | |
| `docs/AGENTS-GUIDE.md` | Guide to model-pinned agents, trigger phrases, fallback chains | 384 |
| `docs/EXTENSION-REVIEW-GUIDE.md` | Guide to the extension review workflow | 120 |
| `docs/HEARTBEAT-GUIDE.md` | Guide to the heartbeat protocol and checklist | 217 |
| `docs/HOOKS-GUIDE.md` | Guide to agent lifecycle hooks: config, customisation, security | 392 |
| `docs/INSTRUCTIONS-GUIDE.md` | Guide to the copilot-instructions.md structure | 270 |
| `docs/MCP-GUIDE.md` | Guide to MCP server configuration and server tiers | 283 |
| `docs/PATH-INSTRUCTIONS-GUIDE.md` | Guide to path-specific instruction files | 118 |
| `docs/PROMPTS-GUIDE.md` | Guide to reusable prompt files and slash commands | 137 |
| `docs/RELEASE-AUTOMATION-GUIDE.md` | Guide to release-please and version management | 119 |
| `docs/SECURITY-GUIDE.md` | Guide to CI hardening, SHA-pinning, Graduated Trust Model | 181 |
| `docs/SETUP-GUIDE.md` | Walkthrough of the setup interview and output files | 196 |
| `docs/SKILLS-GUIDE.md` | Guide to the Agent Skills system | 205 |
| `docs/TEST-REVIEW-GUIDE.md` | Guide to the test coverage review workflow | 173 |
| `docs/UPDATE-GUIDE.md` | Guide to the update and restore protocol | 180 |
| **Examples** | | |
| `examples/valis/README.md` | Reference implementation example | 61 |
| **Scripts** | | |
| `scripts/sync-version.sh` | Propagate version from VERSION.md to all marker files | 27 |
| `scripts/sync-doc-index.sh` | Sync/check canonical DOC_INDEX metadata inventory | 162 |
| `scripts/sync-llms-context.sh` | Sync/check generated llms context packs | 165 |
| **Tests** | | |
| `tests/test-hooks.sh` | Hook script functionality tests | 343 |
| `tests/test-guard-destructive.sh` | Guard-destructive hook security tests | 167 |
| `tests/test-security-edge-cases.sh` | Security edge case tests (JSON injection, path traversal, etc.) | 203 |
| `tests/test-sync-version.sh` | Version sync script tests | 190 |
| `tests/test-doc-consistency.sh` | Documentation drift guardrail tests | 137 |
| **Template files (copied to consumer project during setup)** | | |
| `template/BIBLIOGRAPHY.md` | File catalogue stub | 50 |
| `template/CHANGELOG.md` | Keep-a-Changelog stub (for consumer project) | 30 |
| `template/JOURNAL.md` | ADR journal stub | 29 |
| `template/METRICS.md` | Metrics baseline table stub | 35 |
| `template/copilot-setup-steps.yml` | Copilot coding agent environment setup workflow stub | 42 |
| `template/hooks/copilot-hooks.json` | Agent hooks configuration template | 44 |
| `template/hooks/scripts/session-start.sh` | SessionStart hook template | 47 |
| `template/hooks/scripts/session-start.ps1` | SessionStart hook template (Windows) | 49 |
| `template/hooks/scripts/guard-destructive.sh` | PreToolUse hook template | 105 |
| `template/hooks/scripts/guard-destructive.ps1` | PreToolUse hook template (Windows) | 85 |
| `template/hooks/scripts/post-edit-lint.sh` | PostToolUse hook template | 73 |
| `template/hooks/scripts/post-edit-lint.ps1` | PostToolUse hook template (Windows) | 68 |
| `template/hooks/scripts/enforce-retrospective.sh` | Stop hook template | 65 |
| `template/hooks/scripts/enforce-retrospective.ps1` | Stop hook template (Windows) | 50 |
| `template/hooks/scripts/save-context.sh` | PreCompact hook template | 58 |
| `template/hooks/scripts/save-context.ps1` | PreCompact hook template (Windows) | 53 |
| `template/skills/conventional-commit/SKILL.md` | Starter skill — Conventional Commits | 108 |
| `template/skills/extension-review/SKILL.md` | Starter skill — VS Code extension audit workflow | 72 |
| `template/skills/fix-ci-failure/SKILL.md` | Starter skill — CI failure diagnosis | 64 |
| `template/skills/issue-triage/SKILL.md` | Starter skill — issue triage | 83 |
| `template/skills/lean-pr-review/SKILL.md` | Starter skill — Lean PR review | 102 |
| `template/skills/mcp-builder/SKILL.md` | Starter skill — MCP server creation | 155 |
| `template/skills/plugin-management/SKILL.md` | Starter skill — agent plugin discovery and management | 104 |
| `template/skills/skill-creator/SKILL.md` | Starter skill — skill authoring meta-skill | 70 |
| `template/skills/skill-management/SKILL.md` | Starter skill — skill discovery and management | 58 |
| `template/skills/test-coverage-review/SKILL.md` | Starter skill — coverage-gap audit and CI recommendation workflow | 90 |
| `template/skills/tool-protocol/SKILL.md` | Starter skill — Tool Protocol decision tree | 105 |
| `template/skills/mcp-management/SKILL.md` | Starter skill — MCP server configuration | 51 |
| `template/skills/webapp-testing/SKILL.md` | Starter skill — dual-path web app testing | 292 |
| `template/vscode/mcp.json` | MCP server configuration template | 37 |
| `template/workspace/DOC_INDEX.json` | Canonical machine-readable metadata index stub | 89 |
| `template/workspace/IDENTITY.md` | Agent self-description stub | 17 |
| `template/workspace/SOUL.md` | Agent values & reasoning patterns stub | 18 |
| `template/workspace/USER.md` | User profile stub | 19 |
| `template/workspace/TOOLS.md` | Tool usage patterns stub | 81 |
| `template/workspace/MEMORY.md` | Memory strategy stub | 76 |
| `template/workspace/BOOTSTRAP.md` | Bootstrap record stub | 46 |
| `template/workspace/HEARTBEAT.md` | Heartbeat checklist stub | 60 |

**Total**: 138 files · 14,616 LOC
