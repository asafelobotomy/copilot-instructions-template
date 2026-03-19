# Changelog — copilot-instructions-template

All notable changes to the **template itself** are recorded here.
This is the upstream version history — not a stub for consumer projects.

Format follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [Semantic Versioning](https://semver.org/).

> **Consumer projects**: your own `CHANGELOG.md` records your project's changes, not this file.

---

## [Unreleased]

## [4.0.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.4.1...v4.0.0) (2026-03-19)


### ⚠ BREAKING CHANGES

* New §13 (MCP Protocol) changes section count from 12 to 13. Step 2.12 generates .vscode/mcp.json during setup. Interview expands to 22 questions (E22 added to Expert tier).

### Features

* §2 Test Coverage Review — local test recommendations + CI workflow generation ([e21e64f](https://github.com/asafelobotomy/copilot-instructions-template/commit/e21e64fec3c5381404b530e23719206289f15b1d))
* 3-tier preference interview — Simple (5) / Advanced (+9) / Expert (+5) ([8c77f9b](https://github.com/asafelobotomy/copilot-instructions-template/commit/8c77f9b4cf246ed8b2c353f0ba39365ce366c1ea))
* add §11 Tool Protocol — find/adapt/build/save decision tree with toolbox ([30e798c](https://github.com/asafelobotomy/copilot-instructions-template/commit/30e798c33a864174976cfceaaf296c3cfa6c3fbb))
* add agent lifecycle hooks and enhance built-in tool discovery ([26a4dc2](https://github.com/asafelobotomy/copilot-instructions-template/commit/26a4dc21eef2683c46e2c4d236d2ee24edbef816))
* add Agent Skills system (§12, A15, 4 starter skills, docs) ([#1](https://github.com/asafelobotomy/copilot-instructions-template/issues/1)) ([6b485b2](https://github.com/asafelobotomy/copilot-instructions-template/commit/6b485b228358de3f87fda6536d0d3dfa49a92f21))
* add Agent Skills system (§12, A15, 4 starter skills, docs) ([#1](https://github.com/asafelobotomy/copilot-instructions-template/issues/1)) ([6b485b2](https://github.com/asafelobotomy/copilot-instructions-template/commit/6b485b228358de3f87fda6536d0d3dfa49a92f21))
* add mcp-builder skill for creating MCP servers ([69f5609](https://github.com/asafelobotomy/copilot-instructions-template/commit/69f5609e2e846cfef39d511960435b221e6305f4))
* add model-pinned agent files to .github/agents/ ([0f4cc16](https://github.com/asafelobotomy/copilot-instructions-template/commit/0f4cc1634f263a9687a43ec34ed8053c71bfc771))
* add model-pinned agent files to .github/agents/ ([d6f94b4](https://github.com/asafelobotomy/copilot-instructions-template/commit/d6f94b42f4b820b9ca309e1b4f30542ca0fdb20e))
* add model-pinned agent files to .github/agents/ ([a106ed6](https://github.com/asafelobotomy/copilot-instructions-template/commit/a106ed6c4bc4611cb19d8785f9764eeb97814f30))
* add model-pinned agent files to .github/agents/ ([694b1e5](https://github.com/asafelobotomy/copilot-instructions-template/commit/694b1e582c753e5e5bfaedf44c1af0bc02a65484))
* add post-edit linting script for auto-formatting files ([69f5609](https://github.com/asafelobotomy/copilot-instructions-template/commit/69f5609e2e846cfef39d511960435b221e6305f4))
* add remote bootstrap — trigger phrase activates full setup via GitHub fetch ([b4b2d52](https://github.com/asafelobotomy/copilot-instructions-template/commit/b4b2d520c1984246f6c1be5076d26695906e14d8))
* add Researcher and Explore agents; update agent counts and documentation; implement RESEARCH.md URL tracker ([0e84d49](https://github.com/asafelobotomy/copilot-instructions-template/commit/0e84d491c0c286552d787ee4df39ec1d0f8379b0))
* add starter kits for Python, React, Rust, and TypeScript with skills, prompts, and instructions ([bc7b3b8](https://github.com/asafelobotomy/copilot-instructions-template/commit/bc7b3b8577e70daffa26d4e96b84c7b316c9759d))
* add Tool Protocol trigger phrases and toolbox entries to AGENTS.md ([f702e8e](https://github.com/asafelobotomy/copilot-instructions-template/commit/f702e8eac2e6eba6edbd52b1ad78bd1f943a2648))
* add toolbox note to BOOTSTRAP.md stub ([675a2f0](https://github.com/asafelobotomy/copilot-instructions-template/commit/675a2f049e2f54d78d9ccc4a5b2a73dfc9d4700c))
* add Toolbox section to BIBLIOGRAPHY.md stub ([32ee8ad](https://github.com/asafelobotomy/copilot-instructions-template/commit/32ee8ad3acc7b6e2a12d5618cc74cd8ddb5780aa))
* add UPDATE.md — full update protocol with pre-flight, report, and decision paths ([e7f34f8](https://github.com/asafelobotomy/copilot-instructions-template/commit/e7f34f855da0c5297e912a1aa6d654be49478ffe))
* **agents:** add restore trigger phrases and Remote Restore Sequence ([5506949](https://github.com/asafelobotomy/copilot-instructions-template/commit/5506949e91539e31616ce97662066110c0b44514))
* **agents:** add Update and Doctor custom agents ([749ec1a](https://github.com/asafelobotomy/copilot-instructions-template/commit/749ec1ab275453bedfd35dc3cc74c6449e7d650e))
* **agents:** add update trigger phrases and Remote Update Sequence ([b71b9ba](https://github.com/asafelobotomy/copilot-instructions-template/commit/b71b9bab484968fcf0e3ddeba287dcd74cd28c81))
* **context:** deepen LLM grounding, add llms.txt and issue-triage skill (items 6-13) ([2fe86fa](https://github.com/asafelobotomy/copilot-instructions-template/commit/2fe86fac2532a5946a218e95ce5c076f0e1d6b01))
* **context:** improve LLM attention, grounding, and efficiency (items 1-5) ([ed9b9fa](https://github.com/asafelobotomy/copilot-instructions-template/commit/ed9b9fa1476d862098e32b838fc5fda685644ecd))
* create save-context script for pre-compaction workspace snapshot ([69f5609](https://github.com/asafelobotomy/copilot-instructions-template/commit/69f5609e2e846cfef39d511960435b221e6305f4))
* enhance HEARTBEAT and MEMORY documentation; add metrics freshness section and update task completion logging ([2c4baae](https://github.com/asafelobotomy/copilot-instructions-template/commit/2c4baaeec9371632f968984388143aacd0fdd199))
* enhance heartbeat protocol with retrospective introspection and task completion triggers ([4ef14d9](https://github.com/asafelobotomy/copilot-instructions-template/commit/4ef14d9174890dcd663912398d72e78783dbd83d))
* implement event-driven heartbeat protocol with health checks and triggers ([d5ceb27](https://github.com/asafelobotomy/copilot-instructions-template/commit/d5ceb27119e48b07a144e09bb1b2ab99c112d52b))
* implement model synchronization script and tests, add MODELS.md for agent model registry ([d8af48b](https://github.com/asafelobotomy/copilot-instructions-template/commit/d8af48b992964ac1a49acb1b05370a6e6df3d334))
* implement session-start script to inject project context ([69f5609](https://github.com/asafelobotomy/copilot-instructions-template/commit/69f5609e2e846cfef39d511960435b221e6305f4))
* implement skill-creator for new agent skills ([69f5609](https://github.com/asafelobotomy/copilot-instructions-template/commit/69f5609e2e846cfef39d511960435b221e6305f4))
* initial scaffold — generic Lean/Kaizen living Copilot instructions template ([4a43021](https://github.com/asafelobotomy/copilot-instructions-template/commit/4a4302113985a90d49e09026ee4aaf3cc3bbf8d7))
* **instructions:** add Attention Budget policy with CI enforcement ([d9c9a6b](https://github.com/asafelobotomy/copilot-instructions-template/commit/d9c9a6b339927fad131d329a6ff7930264c3a3fb))
* **instructions:** add model quick reference table ([43bdad2](https://github.com/asafelobotomy/copilot-instructions-template/commit/43bdad215173040bb95af89b7d0977216a572b25))
* offer fetch-from-template option in SETUP.md Step 2.5 ([2105d78](https://github.com/asafelobotomy/copilot-instructions-template/commit/2105d7826ce49e7b8682146a82e9965786ad576d))
* Refactor Copilot instructions and templates for improved clarity and structure ([3a076b6](https://github.com/asafelobotomy/copilot-instructions-template/commit/3a076b64b64a86d9003752748a3ca0abaf10ddef))
* refactor hook scripts to use shared utility functions for JSON escaping; add lib-hooks.sh and lib.sh ([78328d3](https://github.com/asafelobotomy/copilot-instructions-template/commit/78328d383eeb920fb7da0551206852a4a0b9d99d))
* **setup:** add pre-flight detection for existing instructions and files ([cb8568d](https://github.com/asafelobotomy/copilot-instructions-template/commit/cb8568d81dae87d47b9c9b71bc9c56d80c8d0a77))
* **setup:** add Step 2.5 with four model-pinned agent file stubs ([426b29c](https://github.com/asafelobotomy/copilot-instructions-template/commit/426b29cc2b0b7642ec3fb28ef491c4ff117a45fb))
* **setup:** add user preference interview to pre-flight (Step 0d) ([36887c8](https://github.com/asafelobotomy/copilot-instructions-template/commit/36887c8d5b410de518dd841c69885b3d8accd360))
* **setup:** revamp onboarding UX — Quick/Standard/Full tiers, A16/A17, streamline E-tier ([e456d36](https://github.com/asafelobotomy/copilot-instructions-template/commit/e456d36f5cf2303b3a4ce8d675ff1dcebd279ad3))
* **template:** add review skills and llms context packs ([fc8c660](https://github.com/asafelobotomy/copilot-instructions-template/commit/fc8c6601bf24d6a6c28f6e32893fa90c757afb34))
* **template:** add template update subsection to §8 Living Update Protocol ([da3f089](https://github.com/asafelobotomy/copilot-instructions-template/commit/da3f08997e6997cac46b4622c4e23a47221a1fd4))
* Update hooks and templates for enhanced functionality ([384b848](https://github.com/asafelobotomy/copilot-instructions-template/commit/384b84883f44d194de2f5a47efcdc88e39e5ef94))
* update llms and hooks for subagent orchestration ([1757151](https://github.com/asafelobotomy/copilot-instructions-template/commit/1757151d23559299ad3d11ddd99232ef6d223fc1))
* Update setup and documentation for new skills and features ([bebc1ad](https://github.com/asafelobotomy/copilot-instructions-template/commit/bebc1ad0440a0c404dd459d79904ce56b2991dc5))
* update TOOLS.md stub — add toolbox section and §11 reference ([7e9a173](https://github.com/asafelobotomy/copilot-instructions-template/commit/7e9a173ac24a09d49e4a68eb5e7428a0c8da22d5))
* **update:** add automatic pre-write backup + restore flow ([15c0eda](https://github.com/asafelobotomy/copilot-instructions-template/commit/15c0eda3920030f414dd8f075be736d344312aa9))
* v1.2.0 — Waste Taxonomy & CI Hardening ([0b26c58](https://github.com/asafelobotomy/copilot-instructions-template/commit/0b26c58bca8a38857e85f91a4ec5e520f6eb324a))
* v1.3.0 — Context Precision ([76843e2](https://github.com/asafelobotomy/copilot-instructions-template/commit/76843e2681f9a0b222c59dcf14e0f20241f7be35))
* v1.4.0 — Security & Trust ([524789d](https://github.com/asafelobotomy/copilot-instructions-template/commit/524789d771d1f361eb848252729655d84f60685e))
* v2.0.0 — MCP Integration & Ecosystem ([802f086](https://github.com/asafelobotomy/copilot-instructions-template/commit/802f08615c0d75c91a8f0c6a945d0ecf5eee4cf4))


### Bug Fixes

* add .github/agents/ entries to AGENTS.md file map and bootstrap outputs ([4109bff](https://github.com/asafelobotomy/copilot-instructions-template/commit/4109bff84fc4e29abbdd5774f80a8f10eb069057))
* add agents dir, AGENTS.md, UPDATE.md, VERSION to README file list and tree ([735c1d9](https://github.com/asafelobotomy/copilot-instructions-template/commit/735c1d939dda636ddf764397bff3e3568af30d93))
* add language specifier to fenced code blocks (MD040) ([1853577](https://github.com/asafelobotomy/copilot-instructions-template/commit/18535770188fcf16da2830d6773c3bc90afa2ac2))
* add model-pinned agent files to template/workspace/BOOTSTRAP.md ([e323b24](https://github.com/asafelobotomy/copilot-instructions-template/commit/e323b2477ea4d3d73265f715023b331169d08bc1))
* add model-pinned agents section to template/BIBLIOGRAPHY.md stub ([6fb0d56](https://github.com/asafelobotomy/copilot-instructions-template/commit/6fb0d56466d7d0cb337b0d3173dacb94be2a9ed8))
* add release-please config and manifest to fix CI failure ([74b78e3](https://github.com/asafelobotomy/copilot-instructions-template/commit/74b78e3d62d31a24f02c27560d6525dfceda0341))
* **agents:** correct four LLM-clarity bugs in agent instructions ([7385170](https://github.com/asafelobotomy/copilot-instructions-template/commit/738517019694fa0f586e197e9f23d8a2b9593c9b))
* **agents:** correct handoff agent: identifiers to use filename stems ([095bf86](https://github.com/asafelobotomy/copilot-instructions-template/commit/095bf862c827186bfe132ddd8d275b5f732170ac))
* align release metadata contracts and migration registry ([fa0df4f](https://github.com/asafelobotomy/copilot-instructions-template/commit/fa0df4f99a005780c79f414272036cec9bbfa338))
* **ci:** add v3.4.1 MIGRATION.md entry and available-tags line ([11e04c3](https://github.com/asafelobotomy/copilot-instructions-template/commit/11e04c3deb71b35de2adbd6800fbbc552267adde))
* **ci:** align local and workflow test gates ([585bd28](https://github.com/asafelobotomy/copilot-instructions-template/commit/585bd285674ef3fe5b1782ed3787473dcfc1ab2a))
* **ci:** close remaining metadata gaps ([3769c9a](https://github.com/asafelobotomy/copilot-instructions-template/commit/3769c9afaca950ff34fa08a67b23501b00b015c4))
* **ci:** inline x-release-please-version markers and add auto-commit sync ([8a4d108](https://github.com/asafelobotomy/copilot-instructions-template/commit/8a4d1083198b1e309643b73d5b55a7448cb6c41c))
* **ci:** make scorecard job non-blocking via continue-on-error ([c347934](https://github.com/asafelobotomy/copilot-instructions-template/commit/c347934b3b1f337e5fbb774f0dc937b01caaa825))
* **ci:** resolve CI lint failures ([25fe77a](https://github.com/asafelobotomy/copilot-instructions-template/commit/25fe77a3eddd6d34c6bacb86edc307c4c1dc5e18))
* **ci:** resolve markdown lint, shellcheck, and structural validation failures ([08a1e31](https://github.com/asafelobotomy/copilot-instructions-template/commit/08a1e312de32dbfba5c0e8db788762ae12ba7349))
* **ci:** tolerate disabled release auto-merge ([6a0e30c](https://github.com/asafelobotomy/copilot-instructions-template/commit/6a0e30c9769692169c9572dfc9cf75a16faf8223))
* correct §10 notation, fix stale section names, optimize Pre-flight Report format ([f00d3ed](https://github.com/asafelobotomy/copilot-instructions-template/commit/f00d3ed472eb3a229457699a1085d8d41dc7aae9))
* correct section names and add agent files to CHANGELOG.md ([71576cd](https://github.com/asafelobotomy/copilot-instructions-template/commit/71576cdc6a0ca4942428d389209742f891fb77e5))
* correct skill counts, tree formatting, file counts, SHA-pin examples, and CHANGELOG ref ([5fb1096](https://github.com/asafelobotomy/copilot-instructions-template/commit/5fb109618ac514777aa0c4646aa39c407914294a))
* enhance tool compatibility by adding runCommands to agents and skills ([345c2fd](https://github.com/asafelobotomy/copilot-instructions-template/commit/345c2fd6867fe4f861b48d4837818a55df1e36dc))
* full repo review — 10 findings addressed ([979c271](https://github.com/asafelobotomy/copilot-instructions-template/commit/979c27152c827a018599b6c890eb8adb0722e618))
* **lint:** resolve 22 markdownlint errors and sync version stamp ([43499ff](https://github.com/asafelobotomy/copilot-instructions-template/commit/43499ff0929f0cf89868e5e9d686974f0dcbc8d1))
* **lint:** resolve 271 markdownlint errors in CHANGELOG.md ([1e88d66](https://github.com/asafelobotomy/copilot-instructions-template/commit/1e88d6623437249dec7fae8cce0a43b7481edf53))
* markdownlint bulk cleanup — all CI errors resolved ([ae9d4f9](https://github.com/asafelobotomy/copilot-instructions-template/commit/ae9d4f9950c2de14e4772016777292fa6da793a8))
* **mcp:** correct git and fetch MCP servers to use uvx not npx ([6f13858](https://github.com/asafelobotomy/copilot-instructions-template/commit/6f138585f84dfe3b896f87d738d1b792b56db510))
* **models:** correct coding agent to GPT-5.3-Codex; update all SETUP.md references ([b1cc2fa](https://github.com/asafelobotomy/copilot-instructions-template/commit/b1cc2faf0a8b91d001f95c7791eb82278ff72e5a))
* **models:** restore copilot-instructions.md with updated model quick reference table ([6b29a1b](https://github.com/asafelobotomy/copilot-instructions-template/commit/6b29a1b3e8096b4a3ba074a515914963c796ad7f))
* **release:** centralise version constants via release-please extra-files ([97c7599](https://github.com/asafelobotomy/copilot-instructions-template/commit/97c75990b7572cd41a7cb202febd09201aeee3a3))
* resolve all review findings ([ac9aefc](https://github.com/asafelobotomy/copilot-instructions-template/commit/ac9aefc8e5007ee5853273ef1267de834ad089fc))
* resolve CI and actionlint failures ([441feda](https://github.com/asafelobotomy/copilot-instructions-template/commit/441feda06fa50442055ac353364327421371a71b))
* setup interview guardrails — batch plan, verification gate, Codex warnings ([abec974](https://github.com/asafelobotomy/copilot-instructions-template/commit/abec9745d6f6752f864e52135f43a01363f8a69c))
* **SETUP.md:** add mcp-builder + webapp-testing to Step 2.8 and HEARTBEAT.md to BIBLIOGRAPHY stub ([8a593d8](https://github.com/asafelobotomy/copilot-instructions-template/commit/8a593d8af1c976be99eeff0bc0cefd0497b7db56))
* **skills:** correct 5 bugs and enhance skill library ([0c7a5cd](https://github.com/asafelobotomy/copilot-instructions-template/commit/0c7a5cd62cd00deeae7fdb74f0494c8f2ee66f71))
* **update:** clarify 'Update your instructions' means checking upstream template repo ([1846d99](https://github.com/asafelobotomy/copilot-instructions-template/commit/1846d99f1b044b737297957b5fadc05f32817ce4))


### Performance Improvements

* lossless compression — copilot-instructions.md + AGENTS.md (7.6% token reduction) ([61b8d1e](https://github.com/asafelobotomy/copilot-instructions-template/commit/61b8d1e0f5e8cdd17c7df4dc3647611f70eb0a95))

## [3.4.1](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.4.0...v3.4.1) (2026-03-19)

### Bug Fixes

- **ci:** resolve markdown lint, shellcheck, and structural validation failures (MD028, MD029, MD031, MD034, SC2221, SC2222, missing `## [Unreleased]` in CHANGELOG)

## [3.3.2](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.3.1...v3.3.2) (2026-03-07)


### Bug Fixes

* **ci:** close remaining metadata gaps ([3769c9a](https://github.com/asafelobotomy/copilot-instructions-template/commit/3769c9afaca950ff34fa08a67b23501b00b015c4))
* **ci:** resolve CI lint failures ([25fe77a](https://github.com/asafelobotomy/copilot-instructions-template/commit/25fe77a3eddd6d34c6bacb86edc307c4c1dc5e18))
* **ci:** tolerate disabled release auto-merge ([6a0e30c](https://github.com/asafelobotomy/copilot-instructions-template/commit/6a0e30c9769692169c9572dfc9cf75a16faf8223))

## [3.3.1](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.3.0...v3.3.1) (2026-03-07)


### Bug Fixes

* **ci:** align local and workflow test gates ([585bd28](https://github.com/asafelobotomy/copilot-instructions-template/commit/585bd285674ef3fe5b1782ed3787473dcfc1ab2a))

## [3.3.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.2.0...v3.3.0) (2026-03-06)


### Features

* **template:** add review skills and llms context packs ([fc8c660](https://github.com/asafelobotomy/copilot-instructions-template/commit/fc8c6601bf24d6a6c28f6e32893fa90c757afb34))

## [3.2.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.1.0...v3.2.0) (2026-03-06)


### Features

* Update setup and documentation for new skills and features ([bebc1ad](https://github.com/asafelobotomy/copilot-instructions-template/commit/bebc1ad0440a0c404dd459d79904ce56b2991dc5))

## [3.1.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.0.4...v3.1.0) (2026-02-27)


### Features

* add mcp-builder skill for creating MCP servers ([69f5609](https://github.com/asafelobotomy/copilot-instructions-template/commit/69f5609e2e846cfef39d511960435b221e6305f4))
* add post-edit linting script for auto-formatting files ([69f5609](https://github.com/asafelobotomy/copilot-instructions-template/commit/69f5609e2e846cfef39d511960435b221e6305f4))
* create save-context script for pre-compaction workspace snapshot ([69f5609](https://github.com/asafelobotomy/copilot-instructions-template/commit/69f5609e2e846cfef39d511960435b221e6305f4))
* implement session-start script to inject project context ([69f5609](https://github.com/asafelobotomy/copilot-instructions-template/commit/69f5609e2e846cfef39d511960435b221e6305f4))
* implement skill-creator for new agent skills ([69f5609](https://github.com/asafelobotomy/copilot-instructions-template/commit/69f5609e2e846cfef39d511960435b221e6305f4))

## [3.4.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.3.2...v3.4.0) (2026-03-19)

### Features

- `extension-review` skill added in both `.github/skills/` and `template/skills/` for on-demand VS Code extension audits tied to detected stack signals.
- `test-coverage-review` skill added in both `.github/skills/` and `template/skills/` for on-demand coverage-gap analysis, local test recommendations, and CI workflow suggestions.
- `llms-ctx.txt` and `llms-ctx-full.txt` added as generated AI-facing context packs.
- `scripts/sync-llms-context.sh` added to generate and check the `llms-ctx*.txt` artifacts.
- `tests/run-all.sh` added as the canonical local test entrypoint for the template repository.
- `tests/test-sync-doc-index.sh` added to cover `scripts/sync-doc-index.sh` argument validation, write mode, ordering, missing-file recovery, and drift detection.
- `tests/test-sync-llms-context.sh` added to cover `scripts/sync-llms-context.sh` argument validation, deterministic generation, missing outputs, and drift detection.
- `tests/test-hooks-powershell.sh` and `tests/test-guard-destructive-powershell.sh` added to cover the PowerShell hook counterparts on Linux via `pwsh`, closing the largest remaining executable coverage gap.
- `scripts/report-script-coverage.sh`, `tests/coverage/bash-prelude.sh`, `tests/coverage/invoke-powershell-with-coverage.ps1`, and `tests/coverage/run-powershell-coverage.sh` added to collect runtime bash and PowerShell coverage, emit JSON/Markdown summaries, and make script coverage measurable in CI.
- `tests/test-inventory-files.sh` added to turn bibliography and metrics drift into executable checks by comparing `BIBLIOGRAPHY.md` against the actual workspace file set, current LOC values, summary totals, and the latest `METRICS.md` row.
- `tests/test-markdown-contracts.sh` added to validate local Markdown links, core `CHANGELOG.md` sections, ADR structure in `JOURNAL.md`, and high-signal navigation sections in `README.md` and `AGENTS.md`.
- `tests/test-release-contracts.sh` added to validate `VERSION.md`, release-please manifest/config alignment, current-version coverage in `CHANGELOG.md` and `MIGRATION.md`, and retained release markers in managed files.
- `tests/test-customization-contracts.sh` added to validate prompt frontmatter, instruction frontmatter, and the human docs that describe those customization surfaces.
- `tests/test-agent-skill-contracts.sh` added to validate the expected agent and skill inventories, required frontmatter fields, body metadata markers, and the guide documents that advertise those Copilot customization surfaces.
- `tests/test-template-parity.sh` added to enforce exact parity for the repo/template hook mirrors and the stable mirrored skills, while keeping the intentionally divergent `mcp-management` and `webapp-testing` skills explicit.
- `tests/lib/test-helpers.sh` added to centralize common shell-test counters, string assertions, JSON validation, and embedded Python execution helpers for the growing contract-test layer.
- `tests/test-hook-session-start.sh`, `tests/test-hook-post-edit-lint.sh`, `tests/test-hook-enforce-retrospective.sh`, and `tests/test-hook-save-context.sh` added to split the former monolithic bash hook suite into per-hook files with finer-grained ownership and reporting.
- `tests/test-doc-discoverability.sh` and `tests/test-doc-platform-contracts.sh` added to replace the old all-in-one documentation drift suite with smaller checks for summary discoverability versus generated-context/platform contracts.
- `tests/test-report-script-coverage.sh` added to validate `scripts/report-script-coverage.sh --list-bash-tests`, so the coverage harness's test discovery has a direct contract of its own.
- `tests/test-security-edge-cases.sh` — 29-assertion security and contract edge-case suite for `guard-destructive.sh` and `sync-version.sh`. Covers six gap categories identified by online research (OWASP Command Injection cheat sheet, BATS testing best practices): exit-code contract (hook must always exit 0), JSON output validity (every response parseable), `tool_input.input` field alias support, OWASP-sourced chained/embedded command detection (`;`, `&&`, `||`, subshell), SQL keyword case-insensitivity, and `sync-version.sh` idempotency.
- Copilot instructions scaffolded from [copilot-instructions-template](https://github.com/asafelobotomy/copilot-instructions-template) — populated `.github/copilot-instructions.md`, workspace identity files, skills, hooks, MCP config, and documentation stubs.
- `description` field added to all 4 path-specific instruction files (`.github/instructions/*.instructions.md`) for VS Code 1.102+ on-demand loading.
- YAML frontmatter (`description`, `mode`, `tools`) added to all 5 prompt files (`.github/prompts/*.prompt.md`) for VS Code prompt integration.
- MCP capabilities section (tools, resources, prompts, sampling, elicitations, auth) added to `mcp-management` skill and `docs/MCP-GUIDE.md`.
- MCP server discovery sources (MCP Marketplace, agent plugins, community registries) documented in `mcp-management` skill and `docs/MCP-GUIDE.md`.
- Profile-level MCP configuration (`mcp.json`, VS Code commands) documented alongside workspace-level `.vscode/mcp.json`.
- Agent plugins documentation (VS Code 1.110+ experimental) added to `docs/AGENTS-GUIDE.md` and `docs/SKILLS-GUIDE.md`.
- Built-in `/create-*` slash commands (`/create-prompt`, `/create-instruction`, `/create-skill`, `/create-agent`, `/create-hook`) documented in `docs/AGENTS-GUIDE.md`.
- Organization-level agents section added to `docs/AGENTS-GUIDE.md`.
- Agent Debug Panel documentation (replaces Diagnostics) added to `docs/AGENTS-GUIDE.md` and `docs/HOOKS-GUIDE.md`.
- Explore subagent documentation added to `docs/AGENTS-GUIDE.md`.
- Terminal auto-approval (`allowList`/`denyList`) and sandboxing sections added to `docs/HOOKS-GUIDE.md`.
- `/yolo` and `/disableYolo` commands documented in `docs/HOOKS-GUIDE.md`.
- MCP `memory` server (`@modelcontextprotocol/server-memory`) removed from `.vscode/mcp.json` defaults — replaced by VS Code's built-in memory tool (`/memories/`) with three scopes (user, session, repository).
- §13 updated: `memory` removed from always-on server list; migration note added.
- `mcp-management` skill updated with removal note and built-in memory alternative.
- `template/workspace/MEMORY.md` coexistence section rewritten — MCP memory server row removed, updated to 2-layer hierarchy (built-in memory + MEMORY.md).
- `template/workspace/USER.md` gains coexistence note distinguishing project-scoped profile from built-in user memory.
- `webapp-testing` skill (v2.0) rewritten with dual-path architecture: Path A (built-in browser tools, 10 agentic tools, interactive) and Path B (Playwright, CI-ready).
- `template/workspace/TOOLS.md` gains agentic browser tools table (10 tools, Preview, `workbench.browser.enableChatTools`).
- `docs/HOOKS-GUIDE.md` gains context management section: `/compact`, `/fork`, session memory for plans.
- `docs/AGENTS-GUIDE.md` gains Chat Customizations editor and session management sections.
- `docs/SKILLS-GUIDE.md` gains built-in accessibility skill note.
- `plugin-management` skill created — discover, evaluate, install, test, and manage agent plugins (VS Code 1.110+).
- §12 (Skill Protocol) updated: agent plugins added to priority hierarchy; `plugin-management` skill reference.
- Doctor agent gains D11 check: agent plugin naming conflicts, skill collisions, and settings validation.
- Plugin trigger phrases added to `AGENTS.md`: "Show plugins", "Find a plugin for...", "Test as plugin", "Check plugin conflicts".
- Repo HEARTBEAT.md synced with template: Retrospective section (8 questions) and Task completion trigger added.
- `docs/AGENTS-GUIDE.md` gains custom thinking phrases (`chat.agent.thinking.phrases`) and `askQuestions` core tool documentation.
- `BIBLIOGRAPHY.md` refreshed: all LOC counts updated to current values; new plugin-management skill entries added.
- `conventional-commit` skill gains `git.addAICoAuthor` co-author attribution section.
- `docs/MCP-GUIDE.md` updated: memory server removed from tiers, `npx` note corrected.
- Built-in VS Code tools table (usages, rename, Explore subagent) added to `template/workspace/TOOLS.md`.
- Agent compatibility check added to heartbeat checklist (`template/workspace/HEARTBEAT.md`).
- Agent plugins and org-level agents added to skill scope hierarchy (`skill-management` skill).
- Agent plugin strategic roadmap — "Template as an agent plugin" subsection added to `docs/AGENTS-GUIDE.md`; documents why packaging is deferred to v4.0, what a plugin version could look like, and how to preview locally via `chat.plugins.paths`.
- Claude agent format compatibility section added to `docs/AGENTS-GUIDE.md` — documents format differences (`.agent.md` vs `.claude/agents/*.md`), current decision to defer dual-format stubs, and workaround for cross-tool teams.
- Organization-level agents section expanded in `docs/AGENTS-GUIDE.md` — actionable setup steps for `.github-private` repository, `agents/` directory convention, `organizationCustomAgents.enabled` setting, file structure diagram, and guidance for publishing template agents at the org level.
- `v3.2.0` entry added to `MIGRATION.md` with full companion file manifest.
- `.copilot/workspace/DOC_INDEX.json` added as canonical machine-readable documentation metadata index.
- `scripts/sync-doc-index.sh` added to generate/check `DOC_INDEX.json` (`--write` / `--check`).
- `tests/test-doc-consistency.sh` extended with canonical index validation and sync-script check.

### Changed

- `.github/copilot-instructions.md` §2 slimmed by replacing long embedded extension-review and test-coverage-review procedures with concise on-demand skill activation guidance.
- `AGENTS.md` reduced to a high-signal machine map and canonical references instead of maintaining an exhaustive duplicated file inventory.
- `llms.txt` refreshed to current GPT-5.4 review guidance, current skill inventory, and links to generated compact and expanded context packs.
- The canonical local test command is now `bash tests/run-all.sh`, and the main repo instructions, contributor guide, workspace tool notes, and LLM context surfaces now point to that single entrypoint.
- `llms.txt`, `llms-ctx.txt`, and `llms-ctx-full.txt` now advertise the runtime coverage report command alongside the canonical local test suite.
- Setup and documentation surfaces updated from 11 to 13 starter skills, including `SETUP.md`, `README.md`, `docs/*`, `template/workspace/BOOTSTRAP.md`, and `template/workspace/DOC_INDEX.json`.
- `tests/test-doc-consistency.sh` extended to guard `llms.txt`, `llms-ctx.txt`, `llms-ctx-full.txt`, and the new review skills against drift.
- `tests/run-all.sh` and `.github/workflows/ci.yml` now run `tests/test-inventory-files.sh`, extending executable coverage from scripts into Markdown inventory artifacts.
- `tests/run-all.sh` and `.github/workflows/ci.yml` now run `tests/test-markdown-contracts.sh`, extending executable coverage from inventory files into structural Markdown contracts.
- `tests/run-all.sh` and `.github/workflows/ci.yml` now run `tests/test-release-contracts.sh` and `tests/test-customization-contracts.sh`, extending executable coverage into release metadata and Copilot customization-file contracts.
- `tests/run-all.sh` and `.github/workflows/ci.yml` now also run `tests/test-agent-skill-contracts.sh` and `tests/test-template-parity.sh`, extending executable coverage into agent/skill manifests and repo/template mirror guarantees.
- The newer contract and direct-script tests now share `tests/lib/test-helpers.sh` instead of carrying repeated assertion boilerplate, making the test layer easier to extend and audit.
- The older legacy suites (`test-hooks.sh`, `test-guard-destructive.sh`, `test-sync-version.sh`, and `test-security-edge-cases.sh`) now also use the shared helper layer, and `tests/run-all.sh` is grouped into labeled phases so local runs are easier to scan.
- The former `tests/test-hooks.sh` suite is now split into four per-hook files, `tests/run-all.sh` reflects that split in its Hook Behavior phase, and the CI `script-tests` job names now use the same Hook/Script/Docs phase vocabulary as the local runner.
- The former `tests/test-doc-consistency.sh` suite is now split into `tests/test-doc-discoverability.sh` and `tests/test-doc-platform-contracts.sh`, keeping the docs phase narrower without losing any coverage of canonical indexes, llms packs, or setup scaffolds.
- `scripts/report-script-coverage.sh` now discovers its bash test inputs from repo naming conventions instead of a hard-coded list and exposes `--list-bash-tests` so that discovery contract can be tested directly.
- `.github/workflows/ci.yml` script-tests job now runs the new sync-script and PowerShell hook suites, making those coverage gains part of the standard CI contract.
- `.github/workflows/ci.yml` now also runs a dedicated `script-coverage` job that enforces initial 60% bash, PowerShell, and overall coverage thresholds and publishes the Markdown summary to the GitHub Actions job summary.
- `guard-destructive.sh` (both `.github/hooks/` and `template/hooks/`) — added header comments documenting complementary relationship with VS Code terminal auto-approval.
- `skill-creator` skill — notes that `/create-skill` is now built-in in VS Code 1.110+; this skill adds Lean/Kaizen guidance.
- `docs/MCP-GUIDE.md` — "What is MCP?" section updated to note MCP GA status; configuration section expanded to multi-level (workspace, profile, settings, devcontainer).
- `docs/HOOKS-GUIDE.md` — diagnostics section updated to reference Agent Debug Panel.
- `README.md` — repository layout section deduplicated to a high-signal structure with canonical inventory references (`DOC_INDEX.json`, `BIBLIOGRAPHY.md`).
- `AGENTS.md` — exhaustive file map deduplicated to canonical-source references plus high-signal machine-relevant path map.
- Model-selection guidance refreshed across instructions, agents, setup outputs, and guides: `GPT-5.4` is now the primary deep review/debugging model, while `GPT-5.3-Codex` remains the coding/agentic implementation model.
- Command-execution terminology normalized across agents, prompts, skills, and shared docs: `runCommands` is now the canonical metadata identifier, replacing mixed `terminal` usage in frontmatter examples and allowlists.
- `docs/PROMPTS-GUIDE.md` now reflects the repo's current practice: starter prompt files include optional YAML frontmatter metadata rather than being documented as frontmatter-free.
- Root `METRICS.md` aligned with the template's extended schema so repo docs, setup output, and the live metrics file describe the same columns.
- `.vscode/settings.json` MCP sampling list aligned with the current server roster and model set: stale `memory` sampling entry removed and `GPT-5.4` added to active server allowlists.
- Prompt files and prompt docs now use the current VS Code `agent:` frontmatter key instead of deprecated `mode:`.
- Skill files now keep VS Code-compatible minimal frontmatter and move richer metadata into a body-level `Skill metadata` note, preserving compatibility/tooling context without schema warnings.

### Fixed

- `README.md` — badge URL missing `-blue` Shields.io color parameter (discovered during idempotency test run).
- `guard-destructive.ps1` (both repo and template copies) now matches the shell hook's `rm -rf .` policy precisely: only the current directory target is hard-denied, while relative subpaths like `./tmp` require confirmation.
- `README.md` — "Four model-pinned agents" heading and table updated to reflect all six agents (setup, coding, review, fast, update, doctor); added `update.agent.md` and `doctor.agent.md` rows; scaffolding table row updated to "Six model-pinned agents".
- `docs/AGENTS-GUIDE.md` — "four agent files" prose corrected to "six agent files"; Doctor agent model column corrected from Claude Opus 4.6 to Claude Sonnet 4.6 (primary model; Opus 4.6 is the fallback).
- `docs/SETUP-GUIDE.md` — "Four agent files" prose in Step 2.5 corrected to "Six agent files".
- `AGENTS.md` — file map expanded with 15 missing entries: `VERSION.md`, `scripts/sync-version.sh`, `.github/instructions/*.instructions.md` (4 files), `.github/prompts/*.prompt.md` (5 files), `template/skills/issue-triage/SKILL.md`, `template/hooks/scripts/*.ps1` (5 Windows counterparts), `template/copilot-setup-steps.yml`, and all 15 `docs/*.md` human-readable guides.
- `README.md`, `docs/SETUP-GUIDE.md`, and `docs/SECURITY-GUIDE.md` — stale setup-interview references corrected after the E19 removal: Full tier is 23 direct questions, and Global autonomy is now derived from S5 instead of being asked as a separate question.
- `AGENTS.md`, `template/BIBLIOGRAPHY.md`, `template/workspace/BOOTSTRAP.md`, and `BIBLIOGRAPHY.md` — inventory records corrected to match the current review model and the actual scaffolded file set.
- `MIGRATION.md` — available-tags list refreshed to include `v3.2.0`, keeping the release registry aligned with the current template version.
- `tests/test-doc-consistency.sh` — expanded to catch the terminology and contract drift found in review: skill-count mismatch, stale interview counts, stale E19 references, metrics-schema mismatch, and stale MCP `memory` sampling configuration.
- Agent handoff metadata updated to match the currently validated agent names (`Code`, `Review`, `Doctor`, `Update`) instead of lower-case filename stems.
- `.github/workflows/ci.yml`, `docs/SKILLS-GUIDE.md`, `docs/SECURITY-GUIDE.md`, and `skill-creator` now match the new skill schema contract instead of teaching deprecated top-level skill metadata fields.
- `llms.txt` — stale `docs` branch reference removed; now points to `README.md`.
- `UPDATE.md` — U4 fetch URLs corrected from `.github/copilot-instructions.md` to `template/copilot-instructions.md` after the architectural split.
- `.github/agents/update.agent.md` — pre-flight URLs 5 and 6 corrected from `.github/copilot-instructions.md` to `template/copilot-instructions.md`.
- `SETUP.md` — step 2 description corrected to reference `template/copilot-instructions.md` instead of `.github/copilot-instructions.md`.
- `README.md` — version string now carries the `<!-- x-release-please-version -->` marker so release-please keeps it in sync automatically.

### Update protocol

- **`MIGRATION.md` (new)** — structured machine-parseable per-version migration registry. Each tagged version has an entry documenting: sections changed, companion files added/updated, new placeholders, breaking changes, and manual actions. This is the data source for the version-walk algorithm.
- **`UPDATE.md` rewrite** — U3–U5 pre-flight sequence redesigned:
  - **Version-walk**: walks through all intermediate tagged versions between installed and latest, collecting per-version change metadata from `MIGRATION.md`.
  - **Three-way merge**: fetches the template at the installed version's tag (old baseline) for accurate `USER_MODIFIED` vs `UPDATED` classification. Falls back to two-way diff if the tag is unavailable.
  - **Companion file manifest**: agents, skills, hooks, MCP config, path instructions, and prompt files are now part of the change manifest — offered as `NEW`, `UPDATABLE`, or `USER_CUSTOMISED`.
  - **Breaking change tracking**: sections with breaking impact from any intermediate version flagged with `BREAKING` status and ⚠ marker.
  - **New placeholder detection**: unresolved `{{PLACEHOLDER}}` tokens introduced across intermediate versions are listed and resolved during the update.
  - **Expanded backup scope**: companion files modified during the update are now backed up alongside `copilot-instructions.md`.
  - Pre-flight Report now shows per-version change groups, companion file manifest, breaking changes, new placeholders, and manual actions.
- **`update.agent.md`** — fixed ambiguous "fetch from template repo or read locally" to always fetch upstream; added `MIGRATION.md` as pre-flight URL #3; added old-baseline template fetch as URL #6.
- **`AGENTS.md`** — Remote Update Sequence rewritten to describe version-walk, three-way merge, companion file handling, and breaking change flagging; `MIGRATION.md` added to file map.
- **`docs/UPDATE-GUIDE.md`** — human-readable guide updated: step 2 describes three-way merge and version-walk; step 3 lists expanded Pre-flight Report contents; step 6 covers companion file handling; "Notable version migrations" section now references `MIGRATION.md` as authoritative source.

### CI

- Added `Test security edge cases` step to `script-tests` job in `ci.yml`.
- Added `Test documentation consistency` step to `script-tests` job in `ci.yml`.
- Added `DOC_INDEX.json is in sync` validation step to `validate` job in `ci.yml`.
- Added required-file checks for `scripts/sync-doc-index.sh` and `.copilot/workspace/DOC_INDEX.json`.
- `.github/workflows/ci.yml` — "Developer instructions have no placeholder tokens" step now strips inline backtick spans before counting `{{` tokens, eliminating 13 false-positive matches from documentation code examples.
- `.github/workflows/ci.yml` — auto-commit step now stages `README.md` alongside `template/copilot-instructions.md` and `.release-please-manifest.json`.
- `.github/workflows/release-please.yml` — workflow_run trigger name was stored as a Unicode escape sequence instead of a literal em dash, causing the release job to silently never fire; corrected to the literal character.
- `release-please-config.json` — `README.md` added to `extra-files` so release-please keeps the version badge in sync on every release.
- `tests/test-release-contracts.sh` — test 5 added to verify the `release-please.yml` workflow_run trigger name matches the CI workflow `name:` field exactly, preventing recurrence of encoding bugs.

---

## [3.0.4](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.0.3...v3.0.4) (2026-02-26)


### Bug Fixes

* **ci:** inline x-release-please-version markers and add auto-commit sync ([8a4d108](https://github.com/asafelobotomy/copilot-instructions-template/commit/8a4d1083198b1e309643b73d5b55a7448cb6c41c))

## [3.0.3](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.0.2...v3.0.3) (2026-02-26)


### Bug Fixes

* **skills:** correct 5 bugs and enhance skill library ([0c7a5cd](https://github.com/asafelobotomy/copilot-instructions-template/commit/0c7a5cd62cd00deeae7fdb74f0494c8f2ee66f71))

## [3.0.2](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.0.1...v3.0.2) (2026-02-26)


### Bug Fixes

* **agents:** correct four LLM-clarity bugs in agent instructions ([7385170](https://github.com/asafelobotomy/copilot-instructions-template/commit/738517019694fa0f586e197e9f23d8a2b9593c9b))

## [3.0.1](https://github.com/asafelobotomy/copilot-instructions-template/compare/v3.0.0...v3.0.1) (2026-02-26)


### Bug Fixes

* **release:** centralise version constants via release-please extra-files ([97c7599](https://github.com/asafelobotomy/copilot-instructions-template/commit/97c75990b7572cd41a7cb202febd09201aeee3a3))

## [3.0.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v2.3.0...v3.0.0) (2026-02-26)


### ⚠ BREAKING CHANGES

* New §13 (MCP Protocol) changes section count from 12 to 13. Step 2.12 generates .vscode/mcp.json during setup. Interview expands to 22 questions (E22 added to Expert tier).

### Features

* §2 Test Coverage Review — local test recommendations + CI workflow generation ([e21e64f](https://github.com/asafelobotomy/copilot-instructions-template/commit/e21e64fec3c5381404b530e23719206289f15b1d))
* 3-tier preference interview — Simple (5) / Advanced (+9) / Expert (+5) ([8c77f9b](https://github.com/asafelobotomy/copilot-instructions-template/commit/8c77f9b4cf246ed8b2c353f0ba39365ce366c1ea))
* add §11 Tool Protocol — find/adapt/build/save decision tree with toolbox ([30e798c](https://github.com/asafelobotomy/copilot-instructions-template/commit/30e798c33a864174976cfceaaf296c3cfa6c3fbb))
* add agent lifecycle hooks and enhance built-in tool discovery ([26a4dc2](https://github.com/asafelobotomy/copilot-instructions-template/commit/26a4dc21eef2683c46e2c4d236d2ee24edbef816))
* add Agent Skills system (§12, A15, 4 starter skills, docs) ([#1](https://github.com/asafelobotomy/copilot-instructions-template/issues/1)) ([6b485b2](https://github.com/asafelobotomy/copilot-instructions-template/commit/6b485b228358de3f87fda6536d0d3dfa49a92f21))
* add Agent Skills system (§12, A15, 4 starter skills, docs) ([#1](https://github.com/asafelobotomy/copilot-instructions-template/issues/1)) ([6b485b2](https://github.com/asafelobotomy/copilot-instructions-template/commit/6b485b228358de3f87fda6536d0d3dfa49a92f21))
* add model-pinned agent files to .github/agents/ ([0f4cc16](https://github.com/asafelobotomy/copilot-instructions-template/commit/0f4cc1634f263a9687a43ec34ed8053c71bfc771))
* add model-pinned agent files to .github/agents/ ([d6f94b4](https://github.com/asafelobotomy/copilot-instructions-template/commit/d6f94b42f4b820b9ca309e1b4f30542ca0fdb20e))
* add model-pinned agent files to .github/agents/ ([a106ed6](https://github.com/asafelobotomy/copilot-instructions-template/commit/a106ed6c4bc4611cb19d8785f9764eeb97814f30))
* add model-pinned agent files to .github/agents/ ([694b1e5](https://github.com/asafelobotomy/copilot-instructions-template/commit/694b1e582c753e5e5bfaedf44c1af0bc02a65484))
* add remote bootstrap — trigger phrase activates full setup via GitHub fetch ([b4b2d52](https://github.com/asafelobotomy/copilot-instructions-template/commit/b4b2d520c1984246f6c1be5076d26695906e14d8))
* add Tool Protocol trigger phrases and toolbox entries to AGENTS.md ([f702e8e](https://github.com/asafelobotomy/copilot-instructions-template/commit/f702e8eac2e6eba6edbd52b1ad78bd1f943a2648))
* add toolbox note to BOOTSTRAP.md stub ([675a2f0](https://github.com/asafelobotomy/copilot-instructions-template/commit/675a2f049e2f54d78d9ccc4a5b2a73dfc9d4700c))
* add Toolbox section to BIBLIOGRAPHY.md stub ([32ee8ad](https://github.com/asafelobotomy/copilot-instructions-template/commit/32ee8ad3acc7b6e2a12d5618cc74cd8ddb5780aa))
* add UPDATE.md — full update protocol with pre-flight, report, and decision paths ([e7f34f8](https://github.com/asafelobotomy/copilot-instructions-template/commit/e7f34f855da0c5297e912a1aa6d654be49478ffe))
* **agents:** add restore trigger phrases and Remote Restore Sequence ([5506949](https://github.com/asafelobotomy/copilot-instructions-template/commit/5506949e91539e31616ce97662066110c0b44514))
* **agents:** add Update and Doctor custom agents ([749ec1a](https://github.com/asafelobotomy/copilot-instructions-template/commit/749ec1ab275453bedfd35dc3cc74c6449e7d650e))
* **agents:** add update trigger phrases and Remote Update Sequence ([b71b9ba](https://github.com/asafelobotomy/copilot-instructions-template/commit/b71b9bab484968fcf0e3ddeba287dcd74cd28c81))
* **context:** deepen LLM grounding, add llms.txt and issue-triage skill (items 6-13) ([2fe86fa](https://github.com/asafelobotomy/copilot-instructions-template/commit/2fe86fac2532a5946a218e95ce5c076f0e1d6b01))
* **context:** improve LLM attention, grounding, and efficiency (items 1-5) ([ed9b9fa](https://github.com/asafelobotomy/copilot-instructions-template/commit/ed9b9fa1476d862098e32b838fc5fda685644ecd))
* enhance heartbeat protocol with retrospective introspection and task completion triggers ([4ef14d9](https://github.com/asafelobotomy/copilot-instructions-template/commit/4ef14d9174890dcd663912398d72e78783dbd83d))
* implement event-driven heartbeat protocol with health checks and triggers ([d5ceb27](https://github.com/asafelobotomy/copilot-instructions-template/commit/d5ceb27119e48b07a144e09bb1b2ab99c112d52b))
* initial scaffold — generic Lean/Kaizen living Copilot instructions template ([4a43021](https://github.com/asafelobotomy/copilot-instructions-template/commit/4a4302113985a90d49e09026ee4aaf3cc3bbf8d7))
* **instructions:** add Attention Budget policy with CI enforcement ([d9c9a6b](https://github.com/asafelobotomy/copilot-instructions-template/commit/d9c9a6b339927fad131d329a6ff7930264c3a3fb))
* **instructions:** add model quick reference table ([43bdad2](https://github.com/asafelobotomy/copilot-instructions-template/commit/43bdad215173040bb95af89b7d0977216a572b25))
* offer fetch-from-template option in SETUP.md Step 2.5 ([2105d78](https://github.com/asafelobotomy/copilot-instructions-template/commit/2105d7826ce49e7b8682146a82e9965786ad576d))
* **setup:** add pre-flight detection for existing instructions and files ([cb8568d](https://github.com/asafelobotomy/copilot-instructions-template/commit/cb8568d81dae87d47b9c9b71bc9c56d80c8d0a77))
* **setup:** add Step 2.5 with four model-pinned agent file stubs ([426b29c](https://github.com/asafelobotomy/copilot-instructions-template/commit/426b29cc2b0b7642ec3fb28ef491c4ff117a45fb))
* **setup:** add user preference interview to pre-flight (Step 0d) ([36887c8](https://github.com/asafelobotomy/copilot-instructions-template/commit/36887c8d5b410de518dd841c69885b3d8accd360))
* **setup:** revamp onboarding UX — Quick/Standard/Full tiers, A16/A17, streamline E-tier ([e456d36](https://github.com/asafelobotomy/copilot-instructions-template/commit/e456d36f5cf2303b3a4ce8d675ff1dcebd279ad3))
* **template:** add template update subsection to §8 Living Update Protocol ([da3f089](https://github.com/asafelobotomy/copilot-instructions-template/commit/da3f08997e6997cac46b4622c4e23a47221a1fd4))
* update TOOLS.md stub — add toolbox section and §11 reference ([7e9a173](https://github.com/asafelobotomy/copilot-instructions-template/commit/7e9a173ac24a09d49e4a68eb5e7428a0c8da22d5))
* **update:** add automatic pre-write backup + restore flow ([15c0eda](https://github.com/asafelobotomy/copilot-instructions-template/commit/15c0eda3920030f414dd8f075be736d344312aa9))
* v1.2.0 — Waste Taxonomy & CI Hardening ([0b26c58](https://github.com/asafelobotomy/copilot-instructions-template/commit/0b26c58bca8a38857e85f91a4ec5e520f6eb324a))
* v1.3.0 — Context Precision ([76843e2](https://github.com/asafelobotomy/copilot-instructions-template/commit/76843e2681f9a0b222c59dcf14e0f20241f7be35))
* v1.4.0 — Security & Trust ([524789d](https://github.com/asafelobotomy/copilot-instructions-template/commit/524789d771d1f361eb848252729655d84f60685e))
* v2.0.0 — MCP Integration & Ecosystem ([802f086](https://github.com/asafelobotomy/copilot-instructions-template/commit/802f08615c0d75c91a8f0c6a945d0ecf5eee4cf4))


### Bug Fixes

* add .github/agents/ entries to AGENTS.md file map and bootstrap outputs ([4109bff](https://github.com/asafelobotomy/copilot-instructions-template/commit/4109bff84fc4e29abbdd5774f80a8f10eb069057))
* add agents dir, AGENTS.md, UPDATE.md, VERSION to README file list and tree ([735c1d9](https://github.com/asafelobotomy/copilot-instructions-template/commit/735c1d939dda636ddf764397bff3e3568af30d93))
* add language specifier to fenced code blocks (MD040) ([1853577](https://github.com/asafelobotomy/copilot-instructions-template/commit/18535770188fcf16da2830d6773c3bc90afa2ac2))
* add model-pinned agent files to template/workspace/BOOTSTRAP.md ([e323b24](https://github.com/asafelobotomy/copilot-instructions-template/commit/e323b2477ea4d3d73265f715023b331169d08bc1))
* add model-pinned agents section to template/BIBLIOGRAPHY.md stub ([6fb0d56](https://github.com/asafelobotomy/copilot-instructions-template/commit/6fb0d56466d7d0cb337b0d3173dacb94be2a9ed8))
* add release-please config and manifest to fix CI failure ([74b78e3](https://github.com/asafelobotomy/copilot-instructions-template/commit/74b78e3d62d31a24f02c27560d6525dfceda0341))
* **agents:** correct handoff agent: identifiers to use filename stems ([095bf86](https://github.com/asafelobotomy/copilot-instructions-template/commit/095bf862c827186bfe132ddd8d275b5f732170ac))
* **ci:** make scorecard job non-blocking via continue-on-error ([c347934](https://github.com/asafelobotomy/copilot-instructions-template/commit/c347934b3b1f337e5fbb774f0dc937b01caaa825))
* correct §10 notation, fix stale section names, optimize Pre-flight Report format ([f00d3ed](https://github.com/asafelobotomy/copilot-instructions-template/commit/f00d3ed472eb3a229457699a1085d8d41dc7aae9))
* correct section names and add agent files to CHANGELOG.md ([71576cd](https://github.com/asafelobotomy/copilot-instructions-template/commit/71576cdc6a0ca4942428d389209742f891fb77e5))
* correct skill counts, tree formatting, file counts, SHA-pin examples, and CHANGELOG ref ([5fb1096](https://github.com/asafelobotomy/copilot-instructions-template/commit/5fb109618ac514777aa0c4646aa39c407914294a))
* full repo review — 10 findings addressed ([979c271](https://github.com/asafelobotomy/copilot-instructions-template/commit/979c27152c827a018599b6c890eb8adb0722e618))
* **lint:** resolve 22 markdownlint errors and sync version stamp ([43499ff](https://github.com/asafelobotomy/copilot-instructions-template/commit/43499ff0929f0cf89868e5e9d686974f0dcbc8d1))
* **lint:** resolve 271 markdownlint errors in CHANGELOG.md ([1e88d66](https://github.com/asafelobotomy/copilot-instructions-template/commit/1e88d6623437249dec7fae8cce0a43b7481edf53))
* markdownlint bulk cleanup — all CI errors resolved ([ae9d4f9](https://github.com/asafelobotomy/copilot-instructions-template/commit/ae9d4f9950c2de14e4772016777292fa6da793a8))
* **mcp:** correct git and fetch MCP servers to use uvx not npx ([6f13858](https://github.com/asafelobotomy/copilot-instructions-template/commit/6f138585f84dfe3b896f87d738d1b792b56db510))
* **models:** correct coding agent to GPT-5.3-Codex; update all SETUP.md references ([b1cc2fa](https://github.com/asafelobotomy/copilot-instructions-template/commit/b1cc2faf0a8b91d001f95c7791eb82278ff72e5a))
* **models:** restore copilot-instructions.md with updated model quick reference table ([6b29a1b](https://github.com/asafelobotomy/copilot-instructions-template/commit/6b29a1b3e8096b4a3ba074a515914963c796ad7f))
* resolve all review findings ([ac9aefc](https://github.com/asafelobotomy/copilot-instructions-template/commit/ac9aefc8e5007ee5853273ef1267de834ad089fc))
* resolve CI and actionlint failures ([441feda](https://github.com/asafelobotomy/copilot-instructions-template/commit/441feda06fa50442055ac353364327421371a71b))
* setup interview guardrails — batch plan, verification gate, Codex warnings ([abec974](https://github.com/asafelobotomy/copilot-instructions-template/commit/abec9745d6f6752f864e52135f43a01363f8a69c))
* **SETUP.md:** add mcp-builder + webapp-testing to Step 2.8 and HEARTBEAT.md to BIBLIOGRAPHY stub ([8a593d8](https://github.com/asafelobotomy/copilot-instructions-template/commit/8a593d8af1c976be99eeff0bc0cefd0497b7db56))
* **update:** clarify 'Update your instructions' means checking upstream template repo ([1846d99](https://github.com/asafelobotomy/copilot-instructions-template/commit/1846d99f1b044b737297957b5fadc05f32817ce4))


### Performance Improvements

* lossless compression — copilot-instructions.md + AGENTS.md (7.6% token reduction) ([61b8d1e](https://github.com/asafelobotomy/copilot-instructions-template/commit/61b8d1e0f5e8cdd17c7df4dc3647611f70eb0a95))

## [2.3.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v2.2.0...v2.3.0) (2026-02-26)

### Features

* **version:** bump to 2.3.0; move installed version tracking from root `VERSION.md` → `.github/copilot-version.md` to avoid collision with consumer project version files; update all references in `UPDATE.md`, `AGENTS.md`, `SETUP.md`, `doctor.agent.md`, and `docs/UPDATE-GUIDE.md`
* **context(items 1-5):** research-backed LLM attention and grounding improvements — Critical Reminders block at preamble (beats Lost-in-the-Middle), `<project_config>` XML tags on §10 placeholder table, parallel execution directive at §11 head, read-before-claiming rule in §4, few-shot `<examples>` blocks in §2 Review Mode / §5 PDCA / `review.agent.md`
* **context(items 6-7):** skill description anti-smells added to §12 authoring rule 2; output-efficiency bullet added to §11 Other rules — prefer `grep`/`head`/`jq` over raw dumps, return minimum token payload
* **context(item 8):** add `llms.txt` at repo root per llmstxt.org spec — project overview, key file links, agent inventory, skill inventory, MCP server summary, workspace identity file catalogue
* **context(item 9):** add step 8 (context limit protocol) to §8 Heartbeat Procedure — run `save-context.sh`, write resume note to Agent Notes, continue mid-task (never abandon)
* **memory(item 10):** add MCP memory server row to `MEMORY.md` coexistence table — session-scoped, ephemeral, lowest priority; update priority rule to cover all three memory systems
* **skills(item 11):** add `issue-triage` agentic workflow skill — triage GitHub issues with severity classification, Lean waste category mapping, next-action recommendation, and structured comment draft
* **docs(item 12):** add "Sub-directory instruction scoping" section to `docs/AGENTS-GUIDE.md` — covers `AGENTS.md`/`CLAUDE.md` per-path overrides, `excludeAgent:` frontmatter, priority rules, and practical workflow
* **§12(item 13):** replace "Steps, not prose" authoring rule with "Steps for procedures, goals for judgment" — numbered steps for deterministic workflows; goal-level language for reasoning tasks
* **agents:** add `update.agent.md` — dedicated agent for the instruction update protocol (fetch, diff, apply, restore) with handoff to Doctor
* **agents:** add `doctor.agent.md` — read-only health check agent covering attention budget, section structure, placeholder leakage, agent validity, MCP config, workspace memory files, VERSION.md, JOURNAL.md, BIBLIOGRAPHY.md
* **agents(setup):** add handoff from Setup → Doctor so first-time setup flows naturally into a health verification
* **agents(fast):** add `terminal` tool and Code escalation handoff; rename description to be concise
* **§8:** add Attention Budget policy — per-section line limits for `copilot-instructions.md` with CI enforcement
* **ci:** new `Attention budget` step in `ci.yml` enforcing line limits per section (800 total, 210 §2, 120 §1/§3–§9, 150 §11–§13)

### Bug Fixes

* **agents:** fix handoff `agent:` identifiers — must use filename stem (`coding`, `review`) not `name:` frontmatter value (`Code`, `Review`); this caused handoff buttons to silently fail to switch agents
* **agents:** audit `send:` across all agents — file-writing handoffs (Review→Code, Doctor→Code) changed to `send: false` so users can review/add context before implementation starts; verify-only handoffs (Setup→Doctor, Update→Doctor, Doctor→Update) remain `send: true`
* **agents(doctor):** swap primary model to Claude Sonnet 4.6 (accurate for D1–D10 mechanical checks, 3× cheaper than Opus); Opus 4.6 remains as fallback
* **mcp:** fix git and fetch MCP servers incorrectly using `npx`; they are Python packages requiring `uvx` (`mcp-server-git`, `mcp-server-fetch`)
* **update:** clarify that "Update your instructions" means checking `https://github.com/asafelobotomy/copilot-instructions-template` for upstream changes, not making ad-hoc edits

### Documentation

* **CONTRIBUTING.md:** add Attention Budget section explaining per-section limits and overflow rule
* **docs/INSTRUCTIONS-GUIDE.md:** document Attention Budget under §8 guide
* **docs/MCP-GUIDE.md:** strengthen note on `uvx` vs `npx` distinction for git/fetch servers
* **docs/UPDATE-GUIDE.md, AGENTS.md, UPDATE.md, README.md:** make "Update your instructions" trigger explicitly reference the upstream repo URL

---

## [2.2.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v2.1.0...v2.2.0) (2026-02-26)


### Features

* **setup:** revamp onboarding UX — Quick/Standard/Full tiers, A16/A17, streamline E-tier ([e456d36](https://github.com/asafelobotomy/copilot-instructions-template/commit/e456d36f5cf2303b3a4ce8d675ff1dcebd279ad3))


### Bug Fixes

* **ci:** make scorecard job non-blocking via continue-on-error ([c347934](https://github.com/asafelobotomy/copilot-instructions-template/commit/c347934b3b1f337e5fbb774f0dc937b01caaa825))
* **lint:** resolve 271 markdownlint errors in CHANGELOG.md ([1e88d66](https://github.com/asafelobotomy/copilot-instructions-template/commit/1e88d6623437249dec7fae8cce0a43b7481edf53))

## [2.1.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v2.0.0...v2.1.0) (2026-02-23)


### Features

* add agent lifecycle hooks and enhance built-in tool discovery ([26a4dc2](https://github.com/asafelobotomy/copilot-instructions-template/commit/26a4dc21eef2683c46e2c4d236d2ee24edbef816))
* enhance heartbeat protocol with retrospective introspection and task completion triggers ([4ef14d9](https://github.com/asafelobotomy/copilot-instructions-template/commit/4ef14d9174890dcd663912398d72e78783dbd83d))
* implement event-driven heartbeat protocol with health checks and triggers ([d5ceb27](https://github.com/asafelobotomy/copilot-instructions-template/commit/d5ceb27119e48b07a144e09bb1b2ab99c112d52b))


### Bug Fixes

* add language specifier to fenced code blocks (MD040) ([1853577](https://github.com/asafelobotomy/copilot-instructions-template/commit/18535770188fcf16da2830d6773c3bc90afa2ac2))
* add release-please config and manifest to fix CI failure ([74b78e3](https://github.com/asafelobotomy/copilot-instructions-template/commit/74b78e3d62d31a24f02c27560d6525dfceda0341))
* correct skill counts, tree formatting, file counts, SHA-pin examples, and CHANGELOG ref ([5fb1096](https://github.com/asafelobotomy/copilot-instructions-template/commit/5fb109618ac514777aa0c4646aa39c407914294a))
* resolve all review findings ([ac9aefc](https://github.com/asafelobotomy/copilot-instructions-template/commit/ac9aefc8e5007ee5853273ef1267de834ad089fc))
* resolve CI and actionlint failures ([441feda](https://github.com/asafelobotomy/copilot-instructions-template/commit/441feda06fa50442055ac353364327421371a71b))
* **SETUP.md:** add mcp-builder + webapp-testing to Step 2.8 and HEARTBEAT.md to BIBLIOGRAPHY stub ([8a593d8](https://github.com/asafelobotomy/copilot-instructions-template/commit/8a593d8af1c976be99eeff0bc0cefd0497b7db56))

### Added

- `template/hooks/copilot-hooks.json` — agent lifecycle hooks configuration template. Defines five hook events (SessionStart, PreToolUse, PostToolUse, Stop, PreCompact) with bash scripts and Windows PowerShell overrides. Hooks provide deterministic enforcement of security, formatting, and retrospective rules that soft instructions cannot guarantee.
- `template/hooks/scripts/session-start.sh` — SessionStart hook: auto-detects project manifest (package.json, pyproject.toml, Cargo.toml), gathers git branch/commit, runtime versions, and heartbeat pulse; emits project context as `additionalContext` JSON.
- `template/hooks/scripts/guard-destructive.sh` — PreToolUse hook: two-tier pattern matching for dangerous commands. BLOCKED tier (hard deny): `rm -rf /`, `DROP TABLE`, fork bombs, pipe-to-shell. CAUTION tier (user confirmation): `rm -rf`, `git push --force`, `npm publish`. Only intercepts terminal/command tools. Enforces §5 ("Secure by default") deterministically.
- `template/hooks/scripts/post-edit-lint.sh` — PostToolUse hook: language-aware auto-formatting after agent edits. Detects file extension and runs the appropriate formatter (Prettier for JS/TS, Black/Ruff for Python, rustfmt for Rust, gofmt for Go). Only activates for edit/create/write/replace tools. Eliminates W9 (manual repetition) for formatting.
- `template/hooks/scripts/enforce-retrospective.sh` — Stop hook: prevents agent session end if retrospective has not been run. Checks session transcript for retrospective keywords and HEARTBEAT.md mtime. Includes `stop_hook_active` infinite-loop guard.
- `template/hooks/scripts/save-context.sh` — PreCompact hook: preserves critical workspace state before conversation context compaction. Captures heartbeat pulse, recent MEMORY.md entries, SOUL.md heuristics, and git status as `additionalContext`.
- `docs/HOOKS-GUIDE.md` — human-readable hooks guide: hook overview table, five starter hook descriptions, configuration format, adding/disabling hooks, interaction with §5/§6/§8/§10 systems, troubleshooting, security considerations, customisation examples.
- `.github/copilot-instructions.md` — new `### Agent Hooks` subsection in §8: five-hook starter table, JSON protocol description, cross-system interaction summary, link to HOOKS-GUIDE.md.
- `AGENTS.md` — "Hook operations" trigger phrase section (5 phrases); hook entries added to canonical triggers table; hook template files added to file map; hooks line added to "What this repo is" description; `.github/hooks/` added to bootstrap output table.
- `.github/copilot-instructions.md` — new `### 1.5 BUILT-IN` step in §11 Tool Protocol decision tree: documents VS Code's native tools (`list_code_usages`, `get_errors`, `fetch_webpage`, `semantic_search`, `grep_search`) as a discovery step between local toolbox lookup and online search.
- `.github/copilot-instructions.md` — W15 (Tool friction) examples expanded with concrete built-in tool names (`list_code_usages`, `semantic_search`, `get_errors`, `fetch_webpage`) replacing generic descriptions.
- `.github/copilot-instructions.md` — §7 Metrics: `get_errors` built-in added as alternative to `{{TYPE_CHECK_COMMAND}}` for type error tracking.
- `template/workspace/MEMORY.md` — new "Copilot Memory coexistence" section documenting how project-scoped MEMORY.md complements VS Code's native Copilot Memory feature; includes priority rule (MEMORY.md wins for project facts), scope comparison table, and duplication avoidance guidance.
- `docs/INSTRUCTIONS-GUIDE.md` — new "Instruction priority chain" section documenting the four-tier instruction resolution order (file-scoped → repository → organisation → personal) with scope table, practical placement guidance, template interaction notes, and prompt files reference.
- `docs/SECURITY-GUIDE.md` — new `### Custom tier format` subsection under Graduated Trust Model: concrete Markdown table example showing `{{TRUST_OVERRIDES}}` format, glob pattern rules, and tier precedence logic.
- `docs/UPDATE-GUIDE.md` — new `## Notable version migrations` section with manual-action tables for `v1.x → v2.0.0` and `v1.0.x → v1.4.0` upgrades covering companion files (MCP config, skills, release automation) that the update protocol does not touch automatically.
- `template/workspace/HEARTBEAT.md` — event-driven health check checklist template. Agent-writable file with Pulse status, 6 event triggers (session start, large change, refactor/migration, dependency update, CI resolution, explicit), 6 health checks (dependency audit, test coverage delta, waste scan, memory consolidation, metrics freshness, settings drift), Agent Notes, and append-only History table. Adapted from [OpenClaw's heartbeat mechanism](https://docs.openclaw.ai/gateway/heartbeat) with event-triggered execution replacing timed intervals.
- `docs/HEARTBEAT-GUIDE.md` — human-readable guide: event triggers vs OpenClaw's timed approach, cross-file wiring specification, adding custom triggers and checks, silent-when-healthy contract, interaction with §6/§8/§10/MEMORY.md/METRICS.md/TOOLS.md/SOUL.md.
- `.github/copilot-instructions.md` — new `### Heartbeat Protocol` subsection in §8: event trigger list, 6-step procedure (read → check → update Pulse → log History → write Agent Notes → report alerts only), cross-file references.
- `AGENTS.md` — "Heartbeat operations" trigger phrase section (6 phrases); heartbeat entries added to canonical triggers table; `template/workspace/HEARTBEAT.md` and `.copilot/workspace/HEARTBEAT.md` added to file map and bootstrap outputs.
- `template/workspace/HEARTBEAT.md` — Retrospective introspection section: 7 self-reflection questions with cross-file persistence wiring (SOUL.md for reasoning heuristics, USER.md for user profile observations, MEMORY.md for gap analysis and lessons learned, Agent Notes for self-assessment). Q4 (issue report) and Q5 (agent questions) surface directly to the user.
- `template/workspace/HEARTBEAT.md` — "Task completion" event trigger: fires the heartbeat (including retrospective) after completing any user-requested task.
- `AGENTS.md` — "Run retrospective" trigger phrase added to heartbeat operations section and canonical triggers table.

### Changed

- Version source-of-truth migrated from `VERSION` to `VERSION.md`; CI/release workflows, setup/update docs, and templates now read `VERSION.md`.
- Added `scripts/sync-version.sh` to propagate `VERSION.md` into derived references (`.github/copilot-instructions.md` stamp, `README.md` version badge, `.release-please-manifest.json`). CI now enforces these derived files are synced.

- `template/skills/skill-creator/SKILL.md` — trimmed `description` field to a concise one-sentence form matching the §12 recommendation for reliable agent discovery.
- `template/skills/conventional-commit/SKILL.md` — expanded opaque `§10` and `§4`/`§10` references in "When NOT to use" to include `of their project's Copilot instructions`, improving readability when the skill is used outside the template context.
- `SETUP.md` — added release automation callout after Step 2.11 pointing to `docs/RELEASE-AUTOMATION-GUIDE.md` and noting the `release-please-config.json` / `.release-please-manifest.json` requirement for the release-please strategy; Step 0b updated from 6 to 7 identity files (HEARTBEAT.md added); Step 3 expanded with HEARTBEAT.md scaffold section; BOOTSTRAP.md stub updated from "all six" to "all seven" identity files.
- `AGENTS.md` — "Six workspace identity files" → "Seven workspace identity files" in project description.
- `README.md` — added "Event-driven heartbeat" feature section; workspace identity table expanded from 6 to 7 rows (HEARTBEAT.md added); `docs/HEARTBEAT-GUIDE.md` added to human-readable guides table; file tree updated with `HEARTBEAT.md`.
- `template/workspace/BOOTSTRAP.md` — HEARTBEAT.md row added to "Files created during setup" table.
- `template/BIBLIOGRAPHY.md` — HEARTBEAT.md row added to "Workspace identity" section.
- `.github/workflows/ci.yml` — `docs/HEARTBEAT-GUIDE.md` and `template/workspace/HEARTBEAT.md` added to required files check.
- `docs/INSTRUCTIONS-GUIDE.md` — §8 section expanded with "Heartbeat Protocol" subsection explaining event triggers, cross-file wiring, and silent-when-healthy contract.
- `docs/INSTRUCTIONS-GUIDE.md` — §8 Heartbeat Protocol explanation expanded with retrospective self-reflection description and cross-file persistence (SOUL.md, USER.md, MEMORY.md).
- `docs/HEARTBEAT-GUIDE.md` — retrospective section added: 7-question table with cross-file wiring, reporting contract exception for Q4/Q5, customisation example for custom retrospective questions; "How it works" flow updated from 7 to 8 steps; "Sections of HEARTBEAT.md" expanded with Retrospective; interaction table expanded for SOUL.md/USER.md/MEMORY.md retrospective writes; "Run retrospective" trigger phrase added.
- `.github/copilot-instructions.md` — §8 Heartbeat Protocol procedure expanded from 6 to 7 steps: new step 3 runs the Retrospective on task-completion and explicit triggers; "When to fire" list expanded with task completion; step 7 updated with retrospective Q4/Q5 exception to silent-when-healthy rule.
- `docs/SETUP-GUIDE.md` — "Six files" → "Seven files" in Step 3; HEARTBEAT.md row added to identity files table.
- `docs/AGENTS-GUIDE.md` — heartbeat trigger phrases added to canonical triggers table.
- `template/workspace/HEARTBEAT.md` — retrospective questions rewritten for observable anchoring: Q1 now references concrete errors/corrections/backtracking; Q2 replaced ("Ambition check" → "Scope audit") targeting factual scope drift with write target changed from Agent Notes to MEMORY.md (Known Gotchas); Q3 sharpened to compare original request against delivered result; Q4 expanded with example issue categories; Q6 redesigned to remove emotion inference (observable signals only); Q7 now enforces structured "When [situation], do [action]" format. New Q8 "Correction log" added — captures user corrections as highest-value feedback signal. Research grounding: Reflexion (Shinn et al., NeurIPS 2023), ExpeL (Zhao et al., 2024), Limits of Self-Correction (Huang et al., 2024).
- `docs/INSTRUCTIONS-GUIDE.md` — retrospective description updated from 7 to 8 questions; "reasoning" → "reasoning heuristics"; "observable events" qualifier added.
- `docs/HEARTBEAT-GUIDE.md` — retrospective section updated from 7 to 8 questions; question table rewritten with observable-anchored wording; new "Design rationale" subsection with research citations; reporting contract updated (Q1–3, Q6–8 silent); interaction table updated for scope audit (Q2), correction log (Q8); customisation example renumbered.

### Fixed

- `docs/UPDATE-GUIDE.md` — stale `§1–§12` section range in v1.x→v2.0.0 migration note changed to "§1 through §12"; resolves cross-reference consistency CI failure.
- `.github/workflows/ci.yml` — replaced SC2015-flagged `A && B || C` patterns in "Release workflow mutual exclusion" step with `if` statements; resolves actionlint (Workflow lint) CI failure.

---

## [2.0.0] — 2026-02-21

### Breaking changes

- **New §13 — Model Context Protocol (MCP)** — section count changes from 12 to 13. CI, CONTRIBUTING.md, and UPDATE.md all reference section count and are updated accordingly. Existing consumer repos running the update protocol will encounter the new section.
- **Step 2.12** generates `.vscode/mcp.json` — changes the scaffolding file output. Existing setups are unaffected (MCP defaults to "None").
- **22 interview questions** (was 21) — E22 added to Expert tier. Simple and Advanced tiers get sensible defaults.

### Added

- **§13 — Model Context Protocol (MCP)** in `.github/copilot-instructions.md` — subsections: MCP server tiers (always-on / credentials-required / stack-specific), server configuration (references `.vscode/mcp.json`), MCP decision tree (built-in tool → MCP server → community package → custom tool), server quality gate (4 checks), available server reference table with `{{MCP_STACK_SERVERS}}` and `{{MCP_CUSTOM_SERVERS}}` placeholders.
- **`template/vscode/mcp.json`** — preconfigured MCP server template with 5 official servers: filesystem, memory, git (always-on, enabled), github, fetch (credentials-required, disabled by default). Uses `${workspaceFolder}` and `${input:github-token}` for GitHub credentials.
- **`template/skills/mcp-builder/SKILL.md`** — starter skill adapted from Anthropic's official library. 7-step workflow: clarify purpose, choose transport (stdio/SSE/streamable HTTP), scaffold project, implement handlers, test with MCP Inspector, register in `.vscode/mcp.json`, document.
- **`template/skills/webapp-testing/SKILL.md`** — starter skill adapted from Anthropic's official library. 7-step Playwright-based e2e testing workflow: detect framework, install runner, scaffold test structure, write first test, verify passing, add to CI, document.
- **E22 — MCP server configuration** interview question added to `SETUP.md` Expert tier (batch 7). Three options: None (default) / Always-on only / Full configuration. Maps to `{{MCP_STACK_SERVERS}}` and `{{MCP_CUSTOM_SERVERS}}` placeholders.
- **SETUP.md Step 2.12** — MCP configuration scaffolding: fetch template, create `.vscode/mcp.json`, configure by E22 answer, stack-specific server discovery from Step 1 dependencies (PostgreSQL, SQLite, Redis, Docker, AWS, Puppeteer), populate §13 placeholders.
- **`docs/MCP-GUIDE.md`** — human-readable guide: MCP overview, three-tier server classification, `.vscode/mcp.json` configuration, adding custom servers, stack-specific discovery, credential security, quality gate, troubleshooting, interaction with §11 Tool Protocol and §12 Skill Protocol.
- **`.github/workflows/release-please.yml`** — automated release workflow using `googleapis/release-please-action@v4` (SHA-pinned). Generates PRs from Conventional Commits, auto-bumps VERSION, creates GitHub releases. Coexists with manual workflow — enable one, disable the other.
- **`docs/RELEASE-AUTOMATION-GUIDE.md`** — human-readable guide comparing manual (`release-manual.yml`) and automated (`release-please.yml`) release strategies with trade-off table, switching instructions, configuration reference, and Conventional Commits quick reference.
- MCP operations trigger phrases in `AGENTS.md`: "Configure MCP servers", "Add an MCP server", "Show MCP servers", "Check MCP configuration".

### Changed

- `.github/copilot-instructions.md` — added §13 MCP Protocol; §9 Subagent Protocol updated to reference §13; §10 User Preferences table expanded from 21 to 22 rows (E22 added); template version stamp updated to `2.0.0`.
- `.github/workflows/ci.yml` — §1–§12 section check updated to §1–§13; `docs/MCP-GUIDE.md`, `docs/RELEASE-AUTOMATION-GUIDE.md`, and `template/vscode/mcp.json` added to required files check.
- `.github/workflows/release.yml` → renamed to `.github/workflows/release-manual.yml` (content unchanged).
- `SETUP.md` — Expert tier expanded from 6 to 7 questions (E16–E22); batch 7 updated (E20, E21, E22); all defaults tables, verification gate counts, pre-flight summary, and Step 6 summary updated from 21 → 22 dimensions; Step 2.12 added after Step 2.11; MCP CONFIGURATION section added to Step 6 summary.
- `CONTRIBUTING.md` — CI checklist reference updated from §1–§12 to §1–§13.
- `AGENTS.md` — MCP operations trigger phrase section added; file map expanded with `template/vscode/mcp.json`, `template/skills/mcp-builder/SKILL.md`, `template/skills/webapp-testing/SKILL.md`; bootstrap outputs expanded with `.vscode/mcp.json`; skills count 4 → 6; canonical triggers table expanded with MCP entries.
- `docs/INSTRUCTIONS-GUIDE.md` — "twelve numbered sections" → "thirteen numbered sections (§1–§13)"; §13 MCP section guide added.
- `docs/SETUP-GUIDE.md` — Expert question count E16–E20 → E16–E22; "20-row" → "22-row"; E21 and E22 added to question table; Step 2.12 section added.
- `.github/ISSUE_TEMPLATE/bug_report.yml` — "MCP Protocol (§13)" added to area dropdown.
- `README.md` — version badge `2.0.0`; "Thirteen-section" heading; "MCP integration" feature section; 6 starter skills (was 4); `.vscode/mcp.json` in scaffolding table; `docs/MCP-GUIDE.md` and `docs/RELEASE-AUTOMATION-GUIDE.md` in docs table; file tree updated with MCP files, release workflows, and new skills.

---

## [1.4.0] — 2026-02-21

### Added

- **SHA-pinned all GitHub Actions** — every `uses:` reference across all 6 workflow files now points to an immutable commit SHA (e.g., `actions/checkout@34e114876b…`). Dependabot auto-updates pinned SHAs via `.github/dependabot.yml`.
- **`step-security/harden-runner`** added as the first step in every CI job across all workflows — monitors network egress in `audit` mode to detect supply-chain compromise.
- **`.github/workflows/scorecard.yml`** — OpenSSF Scorecard analysis runs weekly and on push to `main`. Uploads SARIF results to GitHub code scanning for continuous security posture monitoring.
- **Graduated Trust Model** in `§10 — Project-Specific Overrides` — new `### Verification Levels` subsection with a three-tier table (High / Standard / Guarded) that maps file path patterns to verification behaviour (auto-approve / review / pause). New `{{TRUST_OVERRIDES}}` placeholder for project-specific trust customisation.
- **`compatibility` and `allowed-tools`** optional frontmatter fields added to the §12 Skill Protocol anatomy. `compatibility` declares the minimum template version a skill requires; `allowed-tools` declares which tool categories a skill may use.
- **E21 — Verification trust** interview question added to `SETUP.md` Expert tier (batch 7). Four options: Use defaults / Trust everything / Review everything / Custom tiers. Maps to `{{TRUST_OVERRIDES}}` placeholder.
- **`docs/SECURITY-GUIDE.md`** — human-readable guide covering SHA-pinning rationale, harden-runner usage (audit → block upgrade path), OpenSSF Scorecard interpretation, Graduated Trust Model, skill security fields, Dependabot configuration, and a security checklist.

### Changed

- `.github/workflows/ci.yml` — SHA-pinned all actions; added harden-runner to all 3 jobs; new advisory (non-blocking) check for `compatibility` and `allowed-tools` fields in template skills; added `docs/SECURITY-GUIDE.md` to required files.
- `.github/workflows/release-manual.yml` — SHA-pinned all actions; added harden-runner.
- `.github/workflows/stale.yml` — SHA-pinned all actions; added harden-runner.
- `.github/workflows/links.yml` — SHA-pinned all actions; added harden-runner.
- `.github/workflows/vale.yml` — SHA-pinned all actions; added harden-runner.
- `.github/copilot-instructions.md` — §10 expanded with Graduated Trust Model and `Verification trust` row in User Preferences table; §12 skill anatomy expanded with `compatibility` and `allowed-tools` fields and explanatory text.
- All 4 starter skills (`skill-creator`, `fix-ci-failure`, `lean-pr-review`, `conventional-commit`) — added `compatibility: ">=1.4"` and role-appropriate `allowed-tools` frontmatter.
- `SETUP.md` — Expert tier expanded from 5 to 6 questions (E16–E21); batch 7 updated (E20, E21); all defaults tables, verification gate counts, pre-flight summary, and Step 6 summary updated from 20 → 21 dimensions.
- `README.md` — version badge `1.4.0`; OpenSSF Scorecard badge; "Security hardening" feature section; `scorecard.yml` in file tree; `SECURITY-GUIDE.md` in docs table and file tree.

---

## [1.3.0] — 2026-02-21

### Added

- **Path-specific instruction files** (`.github/instructions/`) — 4 starter stubs with `applyTo:` glob frontmatter for context-aware Copilot guidance:
  - `tests.instructions.md` — rules for test files (`**/*.test.*`, `**/*.spec.*`, `**/tests/**`, `**/__tests__/**`)
  - `api-routes.instructions.md` — rules for API route handlers (`**/api/**`, `**/routes/**`, `**/controllers/**`, `**/handlers/**`)
  - `config.instructions.md` — rules for configuration files (`**/*.config.*`, `**/.*rc`, `**/.*rc.json`)
  - `docs.instructions.md` — rules for documentation (`**/*.md`, `**/docs/**`)
- **Reusable prompt files** (`.github/prompts/`) — 5 starter prompt files that become VS Code slash commands:
  - `explain.prompt.md` → `/explain` — waste-aware code explanation using §6 categories
  - `refactor.prompt.md` → `/refactor` — Lean-principled refactoring with full PDCA cycle
  - `test-gen.prompt.md` → `/test-gen` — generate tests following project conventions and framework
  - `review-file.prompt.md` → `/review-file` — single-file review using §2 Review Mode protocol
  - `commit-msg.prompt.md` → `/commit-msg` — Conventional Commits message from staged changes
- **`template/copilot-setup-steps.yml`** — GitHub Actions workflow template for Copilot coding agent environment setup. Contains commented-out sections for Node.js/Bun, Python, Go, and Rust runtimes; populated during setup based on detected stack.
- **`SETUP.md` Steps 2.9, 2.10, 2.11** — three new setup steps between the skills scaffold (2.8) and workspace identity (3):
  - Step 2.9: path-specific instruction scaffolding — detects relevant file patterns, copies matching stubs, populates placeholders
  - Step 2.10: prompt file scaffolding — copies all five starter prompts, substitutes placeholders
  - Step 2.11: copilot-setup-steps scaffolding — detects runtime, generates `.github/workflows/copilot-setup-steps.yml` for the Copilot coding agent
- **`.github/workflows/links.yml`** — Lychee link checker: weekly cron schedule + PR-triggered on `*.md` changes. Validates all Markdown links with configurable exclusions.
- **`.github/workflows/vale.yml`** — Vale prose linter: PR-triggered on `*.md` changes. Posts review comments via `errata-ai/vale-action@v2.1.1`.
- **`.vale.ini`** — Vale configuration file using built-in Vale style as baseline. Custom styles go in `.github/vale/styles/`.
- **`docs/PATH-INSTRUCTIONS-GUIDE.md`** — human-readable guide: `applyTo:` glob syntax, precedence rules, how path instructions augment the main file, starter stubs, creating custom instruction files.
- **`docs/PROMPTS-GUIDE.md`** — human-readable guide: how prompt files become slash commands, naming conventions, variable substitution (`${file}`, `${selection}`, `${input:varName}`), the 5 starters, creating custom prompts.

### Changed

- `.github/workflows/ci.yml` — added `docs/PATH-INSTRUCTIONS-GUIDE.md`, `docs/PROMPTS-GUIDE.md`, and `template/copilot-setup-steps.yml` to required files check.
- `.github/PULL_REQUEST_TEMPLATE.md` — added 3 checklist items: path-specific instructions updated, prompt files reviewed, copilot-setup-steps.yml updated.
- `README.md` — version badge `1.3.0`; added "Path-specific instructions" and "Reusable prompt files" feature sections; scaffolding table expanded with instruction stubs, prompt files, and copilot-setup-steps; docs table expanded with PATH-INSTRUCTIONS-GUIDE and PROMPTS-GUIDE; file tree updated with `instructions/`, `prompts/`, `links.yml`, `vale.yml`, `copilot-setup-steps.yml`, `.vale.ini`, `dependabot.yml`, and 2 new doc guides.

---

## [1.2.0] — 2026-02-20

### Added

- `§6 — Waste Catalogue` expanded with 8 AI-specific waste categories (W9–W16): Prompt waste, Context window waste, Hallucination rework, Verification overhead, Prompt engineering debt, Model-task mismatch, Tool friction, Over/under-trust. Grounded in DORA 2025 research, Stack Overflow Developer Survey 2024, and Claude Code best practices documentation.
- `template/METRICS.md` — 6 new columns: Deploy Freq, Lead Time, CFR, MTTR, AI Accept Rate, Context Resets. New `## DORA definitions` section with Green/Warn/High thresholds. 4 new placeholder tokens (`{{DEPLOY_FREQ_TARGET}}`, `{{LEAD_TIME_TARGET}}`, `{{CFR_TARGET}}`, `{{MTTR_TARGET}}`).
- `.github/workflows/ci.yml` — new `actionlint:` job using `raven-actions/actionlint@v2`; catches expression type errors, script injection, and unknown inputs in workflow files.
- `.github/dependabot.yml` — GitHub Actions dependency management with weekly schedule, grouped minor/patch updates, conventional commit prefix (`ci`), and 5-PR limit.
- `template/workspace/MEMORY.md` — 4 new structured agent-writable sections: Architectural Decisions, Recurring Error Patterns, Team Conventions Discovered, Known Gotchas (all as append-only tables). New `## Maintenance Protocol` section with quarterly review cadence.
- `.github/ISSUE_TEMPLATE/bug_report.yml` — added area options: Skills Protocol (§12), Waste Catalogue (§6).
- `.github/ISSUE_TEMPLATE/feature_request.yml` — added area options: Skills Protocol (§12), Waste Catalogue (§6), Path-Specific Instructions, Prompt Files, MCP Integration.

### Changed

- `.github/workflows/stale.yml` — upgraded from `actions/stale@v9` to `@v10` (Node 24 runtime); added `exempt-draft-pr: true`.
- `.github/workflows/ci.yml` — upgraded `DavidAnson/markdownlint-cli2-action` from `@v16` to `@v22`.

### Fixed

- `CONTRIBUTING.md` — corrected stale CI checklist reference from `§1–§11` to `§1–§12` (§12 was added in v1.1.0 but CONTRIBUTING.md was not updated).

---

## [1.1.0] — 2026-02-19

### Added

- `§12 — Skill Protocol` in `.github/copilot-instructions.md` — structured discovery decision tree (SCAN local → SEARCH registries → CREATE), scope hierarchy (project → personal → community), community quality gate checklist, seven authoring rules, lifecycle table, Skill vs Tool comparison table, subagent skill-save rules.
- `A15 — Skill search preference` — new Advanced-tier interview question with three options: `local-only` (default), `official-only`, `official-and-community`. Written to `{{SKILL_SEARCH_PREFERENCE}}` placeholder in §10 User Preferences.
- `template/skills/skill-creator/SKILL.md` — meta-skill that teaches the agent how to author new skills following §12.
- `template/skills/fix-ci-failure/SKILL.md` — systematic CI / GitHub Actions failure diagnosis and resolution skill.
- `template/skills/lean-pr-review/SKILL.md` — Lean waste-categorised PR review skill with severity ratings and structured report template.
- `template/skills/conventional-commit/SKILL.md` — Conventional Commits message authoring skill with type table and scope rules.
- `SETUP.md` Step 2.8 — skills scaffolding step: fetches four starter skills from the template repo (with inline-stub fallback), writes to `.github/skills/`, populates `SKILL_SEARCH_PREFERENCE` in §10.
- `docs/SKILLS-GUIDE.md` — human-readable guide to Agent Skills: what they are, where they live, discovery, anatomy, search preference, creating skills, Skills vs Tools comparison, community ecosystem, quality gate, trigger phrases.
- `AGENTS.md` — "Skill operations" trigger phrase section (5 phrases); four template skill files and `.github/skills/<name>/SKILL.md` added to file map; skills row in bootstrap output table; three skill-related canonical triggers.
- `.github/workflows/ci.yml` — new "Template skills have valid SKILL.md" validation step (checks `name` + `description` frontmatter in every `template/skills/*/SKILL.md`).

### Changed

- `.github/copilot-instructions.md` — §9 Subagent Protocol updated to reference §12 skill inheritance; §10 User Preferences table expanded from 19 to 20 rows (`SKILL_SEARCH_PREFERENCE` added as A15); Expert questions renumbered E16–E20 (were E15–E19). Template version stamp updated from `1.0.3` to `1.1.0`.
- `SETUP.md` — batch plan updated (batch 5 now covers A14 + A15); question counts updated (Advanced: 14 → 15, Expert: 19 → 20); Expert headings renumbered E16–E20; all defaults tables updated; verification gate counts changed to 5/15/20; §0e pre-flight template expanded (20 prefs, Skill search label, Step 2.8 in NEXT STEPS); Step 6 summary template updated (SKILLS section, skills in BIBLIOGRAPHY stub); BOOTSTRAP stub updated.
- `README.md` — version badge `1.1.0`; "Twelve-section" heading; "📚 Agent Skills library" feature block; skills scaffolding entry in "What gets scaffolded" table; `SKILLS-GUIDE.md` in docs table; layout tree expanded with `skills/` directories and `SKILLS-GUIDE.md`; §1–§12 references updated throughout.
- `.github/workflows/ci.yml` — §1–§11 section check updated to §1–§12; `docs/SKILLS-GUIDE.md` added to required files.
- `docs/INSTRUCTIONS-GUIDE.md` — "eleven numbered sections" → "twelve numbered sections (§1–§12)"; added full §12 writeup with Scan/Search/Create stages and customisation guidance.
- `docs/SETUP-GUIDE.md` — question counts updated (14 → 15, 19 → 20); A15 row added to question table; Expert rows renumbered E16–E20; "19-row" → "20-row" User Preferences; Step 2.8 skills scaffolding section added.
- `template/workspace/BOOTSTRAP.md` — skills row added to files table; new "Skills" section explaining `.github/skills/`.

---

## [1.0.3] — 2026-02-19

### Fixed

- `docs/SETUP-GUIDE.md` §0d — rewrote preference interview section for 3-tier system (was still describing old 2-tier with "5 or 10 questions" and missing A11–A14 / E15–E19).
- `docs/INSTRUCTIONS-GUIDE.md` — corrected "ten numbered sections (§1–§10)" → "eleven numbered sections (§1–§11)"; added full §11 Tool Protocol section writeup.
- `docs/AGENTS-GUIDE.md` — corrected stale "handles the 10-question interview" → "handles the 3-tier preference interview (5–19 questions)".
- `README.md` file tree — moved `SETUP.md` to correct root-level position (was shown inside `.github/`); removed phantom `.copilot/tools/` directory that doesn't exist in the template repo.
- `README.md` "What this gives you" table — clarified that paths are scaffolded into consumer projects during setup (was showing raw `template/` paths).
- `README.md` manual setup instructions — fixed reversed copy paths (step 1 = `copilot-instructions.md` → `.github/`, step 2 = `SETUP.md` → project root).
- Markdownlint: 149 pre-existing errors across 17 files (MD022, MD028, MD031, MD032, MD040, MD024, MD012) — all resolved. CI markdown lint job now passes clean.
- `SETUP.md` §0d — root-cause fix: `ask_questions` tool hard-limits 4 questions/call and 6 options/question; the previous instruction to "present all questions in a single interaction" was physically impossible and caused agent models to improvise or skip the interview entirely. Restructured into mandatory batched calls.
- `SETUP.md` E16 (Persona) — reduced from 7 options (A–G) to 6 options (A–F) to fit the tool's 6-option hard limit; the tool's built-in "Other" option now covers custom persona input (option G was redundant).

### Added

- `LICENSE` — MIT license (README referenced MIT but no file existed).
- `CONTRIBUTING.md` — contributor guide covering issue reporting, PR process, style conventions, and code of conduct.
- `.gitignore` — excludes `node_modules/`, `package.json`, `package-lock.json`.
- CI infrastructure:
  - `.github/workflows/ci.yml` — validates VERSION semver, CHANGELOG entries, all required files, §1–§11 sections, README docs-table links, merge-conflict markers, and placeholder token count on every push and PR
  - `.github/workflows/release.yml` — auto-creates a tagged GitHub release when `VERSION` is bumped on `main`; extracts notes from the matching CHANGELOG section
  - `.github/workflows/stale.yml` — marks issues/PRs stale after 30 days, closes after 37
  - `.markdownlint.json` — markdown lint rules (MD013/MD033/MD036/MD041 disabled; MD024 siblings-only)
  - `.github/PULL_REQUEST_TEMPLATE.md` — PR checklist auto-shown on new PRs
  - `.github/ISSUE_TEMPLATE/bug_report.yml` — structured bug report form
  - `.github/ISSUE_TEMPLATE/feature_request.yml` — structured feature request form
- `§2 Test Coverage Review` subsection in `.github/copilot-instructions.md`.
- `AGENTS.md` — test coverage review and extension review trigger phrase sections.
- `docs/TEST-REVIEW-GUIDE.md` — plain-English guide to the test coverage review feature.
- `SETUP.md` — ⛔ **Mandatory Interactive Protocol** stop-sign block in preamble: explains that Codex/autonomous models cannot present interactive prompts and instructs the agent to stop and warn the user if it cannot ask questions interactively.
- `SETUP.md` — dedicated **Tooling and Batch Plan** sub-section with a full 7-batch table (Batches 1–2: Simple, 3–5: Advanced, 6–7: Expert), tool constraint notes, suggested `ask_questions` headers, and per-tier question manifests.
- `SETUP.md` — ⛔ **Interactive checkpoint** inside the §0d section header, instructing the agent to ask every batch and wait for the user's typed response.
- `SETUP.md` — **Interview Verification Gate** between the interview and §0e: tier/count check table with explicit STOP instruction if the answer count doesn't match the selected tier.
- `SETUP.md` — **Rigid template directives** above §0e and the Step 6 summary: "Output the template below exactly — fill every `<label>` field."
- `SETUP.md` inline `setup.agent.md` stub + `.github/agents/setup.agent.md` — four new guidelines: interactive interview rule, batch plan usage, answer count verification, template-copy requirement.
- `.github/copilot-instructions.md` — ⚠️ Codex model warning in **Model Quick Reference** table: Codex models are autonomous and cannot present interactive prompts; never use for setup.
- `AGENTS.md` — ⚠️ Codex model warning in "What this repo is" section.
- `README.md` — ⚠️ Codex model warning in Quickstart section.

### Changed

- `.github/copilot-instructions.md` §10 User Preferences — expanded blank stub to a 19-row table template showing all preference dimensions (S1–E19) with empty Setting / Instruction columns ready for population.
- `.github/workflows/ci.yml` — added `LICENSE` and `CONTRIBUTING.md` to required-files check.
- `SETUP.md` §0d — preference interview expanded from 2-tier (Simple 5 / Advanced 10) to **3-tier** (Simple 5 / Advanced +9 / Expert +5 = 19 total). All tiers produce an equally-capable agent; higher tiers unlock deeper customisation:
  - Simple (S1–S5): response style, experience level, primary mode, testing, autonomy
  - Advanced (A6–A14): code style, file size discipline, dependency management, instruction self-editing, refactoring appetite, change reporting
  - Expert (E15–E19): tool/dependency availability, agent persona, VS Code settings, global autonomy failsafe, mood lightener
- `README.md` — full overhaul: centred header, CI/version/license/VS Code badges, Key Features section (eleven-section architecture, four model-pinned agents, living update protocol, workspace identity system, Kaizen baseline, extension and test-coverage review), scaffolding table, human-readable guides table, repository layout tree, philosophy section, reference implementation section.
- `README.md` — Setup agent role updated in agents table to reflect "batched interview with verification gate".
- Template version stamp updated from `1.0.0` → `1.0.3`.

### Performance

- Lossless token-reduction pass across `copilot-instructions.md` and `AGENTS.md` (23 targeted substitutions, zero semantic change):
  - `copilot-instructions.md`: −163 words / −1 048 chars
  - `AGENTS.md`: −254 words / −1 614 chars
  - Combined: −417 words / −2 662 chars (**7.6% reduction**)

---

## [1.0.2] — 2026-02-19

### Added

- `§11 — Tool Protocol` in `.github/copilot-instructions.md` — structured decision tree for tool use, adaptation, online search (MCP registry → GitHub → Awesome lists → stack registries → official docs), building from scratch, evaluating reusability, and saving to the toolbox.
- `.copilot/tools/` toolbox convention — lazy-created directory with `INDEX.md` catalogue where agents save reusable tools.
- `AGENTS.md` — "Tool operations" trigger phrase section; `.copilot/tools/INDEX.md` added to setup outputs table and file map; toolbox canonical triggers added.
- `template/workspace/TOOLS.md` — toolbox section explaining how to use `.copilot/tools/` and when to save.
- `template/BIBLIOGRAPHY.md` — Toolbox section stub.
- `template/workspace/BOOTSTRAP.md` — toolbox lazy-creation note.
- `§2 — Review Mode` Extension Review subsection — agents audit VS Code extensions, detect project stack, and recommend additions/removals. Full protocol:
  - Step 0: asks user to run `code --list-extensions | sort` (Copilot chat cannot enumerate installed extensions directly)
  - Built-in stack detection table with 14 stack mappings: Bash, JS/ESLint, JS/Oxc, JS/Biome, Python, Rust, Go, C#, Java, Docker, Vue, Svelte, Markdown, CSS, YAML, TOML
  - `oxc.oxc-vscode` confirmed to cover both oxlint **and** oxfmt — single extension for both tools
  - Unknown-stack research step: searches VS Code Marketplace, filters by quality (>100k installs, ≥4.0 rating, updated <2yr ago), adds qualifying finds to the report
  - Persists new stack → extension mappings to `.copilot/workspace/TOOLS.md` "Extension registry" for future audits in this project
  - Three-category report: Missing · Redundant · Unknown (resolved via Marketplace research)
  - Does not auto-install; waits for explicit user action
- `AGENTS.md` — "Extension review" trigger phrase section; *"Review extensions"* added to canonical triggers table.
- `docs/EXTENSION-REVIEW-GUIDE.md` — plain-English guide to the Extension Review feature (consistent with existing `docs/` guides).
- `template/workspace/TOOLS.md` — "Extension registry" stub table for persisting unknown-stack discoveries across sessions.

### Changed

- `§9 — Subagent Protocol` — subagents inherit the full Tool Protocol (§11) and must flag proposed toolbox saves to the parent before writing.
- Footer of `.github/copilot-instructions.md` — added `.copilot/tools/` link.
- `§11 — Tool Protocol` decision tree — added **step 2.5 COMPOSE**: before building, check whether 2+ existing toolbox tools can be assembled via pipe or import.
- `§11 — Tool Protocol` BUILD step — added **required inline header template** with six mandatory fields: `# purpose`, `# when`, `# inputs`, `# outputs`, `# risk`, `# source`.
- `§11 — Tool Protocol` INDEX.md format — added **`Output` and `Risk` columns**; updated example rows.
- `§11 — Tool Protocol` quality rules — verb-noun naming requirement; six-smell anti-pattern table (grounded in empirical analysis of 856 real-world MCP tools, arxiv 2602.14878); risk tier system (`safe` vs `destructive`); observability rule (≥3 uses → document workflow in TOOLS.md).
- `README.md` — added `docs/EXTENSION-REVIEW-GUIDE.md` to the human-readable guides table and file tree; fixed file content (backtick formatting restored).
- Template version stamp updated from `1.0.0` → `1.0.2`.

---

## [1.0.1] — 2026-02-19

### Added

- `.github/agents/setup.agent.md` — model-pinned Setup agent (Claude Sonnet 4.6). File existed in documentation but had never been committed to the repo; now present.
- `.github/agents/coding.agent.md` — model-pinned Coding agent (GPT-5.3-Codex). Same.
- `.github/agents/review.agent.md` — model-pinned Review agent (Claude Opus 4.6). Same.
- `.github/agents/fast.agent.md` — model-pinned Fast agent (Claude Haiku 4.5). Same.
- `docs/INSTRUCTIONS-GUIDE.md` — human-readable guide to `.github/copilot-instructions.md`.
- `docs/SETUP-GUIDE.md` — human-readable walkthrough of the setup process.
- `docs/UPDATE-GUIDE.md` — human-readable explanation of the update/restore protocol.
- `docs/AGENTS-GUIDE.md` — human-readable guide to trigger phrases and model-pinned agents.

### Changed

- `README.md` — added `.github/agents/`, `AGENTS.md`, `UPDATE.md` to "What this gives you" table; added `docs/` section with links to human guides; updated file tree to match actual repo structure.
- `AGENTS.md` — added four `.github/agents/*.agent.md` entries to file map and bootstrap outputs table.
- `UPDATE.md` — corrected all `## 10. Project-Specific Overrides` references to `## §10 — Project-Specific Overrides`; replaced ASCII-art pre-flight report block with clean markdown table (~1 400 chars saved); updated stale section names in diff example.
- `template/BIBLIOGRAPHY.md` — added "Model-pinned agents" section with all four agent file entries.
- `template/workspace/BOOTSTRAP.md` — added four agent file rows to setup outputs table.
- `SETUP.md` — Step 2.5 now offers fetching agent files directly from the template repo as the preferred option, with inline stubs as fallback.

### Fixed

- `CHANGELOG.md` (this file) — corrected six stale section names that no longer matched the live copilot-instructions.md headings (§1, §2, §5, §6, §7, §9).
- `UPDATE.md` — same six stale section names corrected in the diff table example.
- `AGENTS.md` — same stale section names corrected.

### Refactored

- `.github/copilot-instructions.md` — seven lossless token-saving compressions applied (~63 tokens saved); no semantic change.

---

## [1.0.0] — 2026-02-19

Initial public release. All features below ship in this version.

### Added

#### Core template

- `.github/copilot-instructions.md` — generic Lean/Kaizen instructions template with `{{PLACEHOLDER}}` tokens throughout.
  - §1 Lean Principles (five Lean principles)
  - §2 Operating Modes (Implement / Review / Refactor / Planning)
  - §3 Standardised Work Baselines (LOC, dep budget, test count, type errors)
  - §4 Coding Conventions (language/runtime/patterns/anti-patterns)
  - §5 PDCA Cycle (Plan–Do–Check–Act applied to every change)
  - §6 Waste Catalogue / Muda (seven categories with code examples)
  - §7 Metrics (Kaizen baseline snapshot table + improvement targets)
  - §8 Living Update Protocol (self-edit triggers, procedure, prohibited edits, template update trigger)
  - §9 Subagent Protocol (modes, depth, compact delegation protocol)
  - §10 Project-Specific Overrides (placeholder resolution table + User Preferences slot)
- Template version stamp: `> **Template version**: 1.0.0 | **Applied**: {{SETUP_DATE}}`

#### Setup system

- `SETUP.md` — one-time agentic bootstrap, remote-executable (no manual file copying required).
  - Step 0a: existing instructions detection → Archive / Delete / Merge choice with full merge protocol.
  - Step 0b: existing workspace identity files detection → Keep all / Overwrite all / Selective.
  - Step 0c: existing documentation stubs detection → skip / append entries / create missing only.
  - Step 0d: User Preference Interview — Simple Setup (5 questions) or Advanced Setup (10 questions) or skip-to-defaults.
    - S1 Response style (Concise / Balanced / Thorough)
    - S2 Experience level (Novice / Intermediate / Expert)
    - S3 Primary working mode (Ship / Quality / Learning / Production hardening)
    - S4 Testing expectations (Write always / Suggest / On request / None)
    - S5 Autonomy level (Ask first / Act then summarise / Ask only for risky)
    - A6 Naming & formatting conventions
    - A7 Documentation standard
    - A8 Error handling philosophy
    - A9 Security sensitivity
    - A10 Change reporting format
  - Step 0e: pre-flight summary with 10-second countdown before any writes.
  - Step 2.5: write model-pinned agent files (`.github/agents/`) for VS Code 1.106+.
  - Steps 1–6: stack discovery, placeholder resolution, agent file creation, identity file scaffolding, METRICS baseline, documentation stubs, SETUP.md self-destruct.

#### Model-pinned agents (VS Code 1.106+)

- `.github/agents/setup.agent.md` — Setup agent pinned to Claude Sonnet 4.6 (onboarding & template operations). Fallback: Claude Sonnet 4.5 → GPT-5.1 → GPT-5 mini.
- `.github/agents/coding.agent.md` — Coding agent pinned to GPT-5.3-Codex (implementation & refactoring, GA Feb 9 2026, 25% faster than 5.2-Codex, real-time steering). Fallback: GPT-5.2-Codex → GPT-5.1-Codex → GPT-5.1 → GPT-5 mini.
- `.github/agents/review.agent.md` — Review agent pinned to Claude Opus 4.6 (architectural review, Agent Teams capability, 3× multiplier). Fallback: Claude Opus 4.5 → Claude Sonnet 4.6 → GPT-5.1.
- `.github/agents/fast.agent.md` — Fast agent pinned to Claude Haiku 4.5 (quick questions, 0.33× cost). Fallback: GPT-5 mini → GPT-4.1.

#### Update system

- `UPDATE.md` — update protocol Copilot follows when triggered by "Update your instructions".
- `VERSION` — semver file; read by update pre-flight to detect whether an update is available.
- `CHANGELOG.md` — this file; read by update pre-flight to show changes between versions.

#### Remote operation

- `AGENTS.md` — AI agent entry point. Defines trigger phrases for setup and update. Provides Remote Bootstrap Sequence and Remote Update Sequence.

#### Workspace identity files

- `template/workspace/IDENTITY.md` — agent self-description stub.
- `template/workspace/SOUL.md` — values & reasoning patterns stub.
- `template/workspace/USER.md` — user profile stub.
- `template/workspace/TOOLS.md` — tool usage patterns stub.
- `template/workspace/MEMORY.md` — memory strategy stub.
- `template/workspace/BOOTSTRAP.md` — permanent setup origin record stub.

#### Documentation stubs

- `template/CHANGELOG.md` — Keep-a-Changelog format stub (for consumer projects).
- `template/JOURNAL.md` — ADR-style journal stub.
- `template/BIBLIOGRAPHY.md` — file catalogue stub (includes model-pinned agent file entries).
- `template/METRICS.md` — Kaizen baseline snapshot table stub.

#### Examples

- `examples/valis/README.md` — reference implementation (asafelobotomy/Valis, the first consumer of this template).
