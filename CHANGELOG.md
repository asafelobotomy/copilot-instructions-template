# Changelog — copilot-instructions-template

All notable changes to the **template itself** are recorded here.
This is the upstream version history — not a stub for consumer projects.

Format follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [Semantic Versioning](https://semver.org/).

> **Consumer projects**: your own `CHANGELOG.md` records your project's changes, not this file.

## [Unreleased]

## [0.9.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v0.8.0...v0.9.0) (2026-05-01)

### Added

* **skills:** extract `git-workflows` skill from `commit.agent.md` — contains all per-operation git workflow procedures (commit, push, tag/release, branch, sync, stash, merge-conflict, PR) with MCP tool preferences ([3f80da1](https://github.com/asafelobotomy/copilot-instructions-template/commit/3f80da1))
* **skills:** extract `audit-procedures` skill from `audit.agent.md` — contains full D1–D14 health check definitions with thresholds and flag levels ([3f80da1](https://github.com/asafelobotomy/copilot-instructions-template/commit/3f80da1))
* **ci:** add CodeQL analysis workflow (`.github/workflows/codeql.yml`) analyzing Python on push/PR to main and weekly schedule ([e311b6b](https://github.com/asafelobotomy/copilot-instructions-template/commit/e311b6b))

### Fixed

* **agents:** trim `commit.agent.md` (330→129 lines) and `audit.agent.md` (316→196 lines); both now delegate procedure detail to their respective skills ([3f80da1](https://github.com/asafelobotomy/copilot-instructions-template/commit/3f80da1))
* **security:** pin `markdownlint-cli2` to exact version `0.22.1` in `package.json` (removes floating `^` range) ([e311b6b](https://github.com/asafelobotomy/copilot-instructions-template/commit/e311b6b))
* **tests:** add `# shellcheck shell=bash` directive to 9 sourced shard files; fix `test-helpers.sh` arithmetic increment and `cleanup_dirs` to be safe under `set -e` callers ([e311b6b](https://github.com/asafelobotomy/copilot-instructions-template/commit/e311b6b))
* **audit-procedures:** D7 check now exempts zero-byte `*.lock` files under `.copilot/workspace/runtime/` and `.tmp/` (transient heartbeat mutex artifacts) ([e311b6b](https://github.com/asafelobotomy/copilot-instructions-template/commit/e311b6b))
* **mcp:** disable VS Code agent sandbox and add per-suite timeout to `mcp_heartbeat_run_tests` ([78a8702](https://github.com/asafelobotomy/copilot-instructions-template/commit/78a8702))

## [0.8.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v0.7.0...v0.8.0) (2026-04-28)

### Added

* **skills:** add 8 new skills — `accessibility-review`, `api-design`, `changelog-entry`, `dependency-update`, `docker-scaffold`, `env-config`, `onboarding-docs`, `performance-profiling`, `refactor-extract`, `tech-debt-audit` ([5546baf](https://github.com/asafelobotomy/copilot-instructions-template/commit/5546baf))
* **mcp:** add `duckduckgo-mcp-server` (`uvx`) as default web search provider; replace `@playwright/mcp` Path C (now opt-in only) ([7fe3fea](https://github.com/asafelobotomy/copilot-instructions-template/commit/7fe3fea))
* **mcp:** add `github` MCP server entry to `.vscode/mcp.json` (disabled by default) ([bf62716](https://github.com/asafelobotomy/copilot-instructions-template/commit/bf62716))
* **ci:** add `mcp-servers:` ID validation to `validate_agent_frontmatter.py`; add `llms.txt` link-target existence check to `validate-cross-references.sh` ([9d1e549](https://github.com/asafelobotomy/copilot-instructions-template/commit/9d1e549))
* **commit:** add `pull-strategy` field to commit-style config ([b33abe6](https://github.com/asafelobotomy/copilot-instructions-template/commit/b33abe6))

### Fixed

* **agents:** audit all 13 agents — normalize `askQuestions` naming, update handoffs, skill maps, routing guards, and diary stubs ([5ed5f55](https://github.com/asafelobotomy/copilot-instructions-template/commit/5ed5f55), [be7f4f9](https://github.com/asafelobotomy/copilot-instructions-template/commit/be7f4f9)–[ebeae29](https://github.com/asafelobotomy/copilot-instructions-template/commit/ebeae29))
* **agents:** remove stale `playwright` and `gitkraken` entries from `mcp-servers:` allowlists; replace GitKraken-specific tool calls in `commit.agent.md` with `mcp_git_*` / `mcp_github_*` equivalents; remove literal `{{...}}` tokens from agent prose ([9d1e549](https://github.com/asafelobotomy/copilot-instructions-template/commit/9d1e549))
* **heartbeat:** rename `asafelobotomy_session_reflect` → `mcp_heartbeat_session_reflect`, `write_diary` → `mcp_heartbeat_write_diary`, `read_diaries` → `mcp_heartbeat_read_diaries` throughout all surfaces ([a16b6b5](https://github.com/asafelobotomy/copilot-instructions-template/commit/a16b6b5), [12a875a](https://github.com/asafelobotomy/copilot-instructions-template/commit/12a875a))
* **hooks:** harden `pulse.sh` stdio contract; fix `pulse_runtime.py` importability (move module-level execution into `main()` with `if __name__ == "__main__"` guard); fix `save-context.ps1` priority-row parity with shell version; wrap `session_reflect_fallback.py` loader in error-safe try/except; fix `mcp-npx.sh` SC2012 lint warning ([01e7967](https://github.com/asafelobotomy/copilot-instructions-template/commit/01e7967))
* **hooks:** harden `scan-secrets` strict mode and self-exclusion; extract `pulse` handlers and heartbeat lib; mirror pulse Python modules to template ([44db58c](https://github.com/asafelobotomy/copilot-instructions-template/commit/44db58c), [9eecd6a](https://github.com/asafelobotomy/copilot-instructions-template/commit/9eecd6a), [df966db](https://github.com/asafelobotomy/copilot-instructions-template/commit/df966db))
* **skills:** fix `conventional-commit` v1.2 and `commit-preflight` v1.1 ([f3c38a3](https://github.com/asafelobotomy/copilot-instructions-template/commit/f3c38a3))
* **llms.txt:** split Skills catalog into Developer and Plugin sections with correct paths ([9d1e549](https://github.com/asafelobotomy/copilot-instructions-template/commit/9d1e549))
* **routing-manifest:** fix commit guard, git-lifecycle coverage, and Code suppress ([b440f79](https://github.com/asafelobotomy/copilot-instructions-template/commit/b440f79))
* **docs:** archive Playwright Path C in `webapp-testing` and `mcp-management` skills; fix stale tool names in research docs; complete `CHANGELOG.md` entries for prior releases ([8e5c0b1](https://github.com/asafelobotomy/copilot-instructions-template/commit/8e5c0b1))

### Removed

* **mcp:** remove `@playwright/mcp` from default template MCP config (`@playwright/mcp` Path C is now opt-in only) ([7fe3fea](https://github.com/asafelobotomy/copilot-instructions-template/commit/7fe3fea))

## [0.7.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v0.6.2...v0.7.0) (2026-04-27)

### Removed

* **mcp:** remove Playwright MCP (`@playwright/mcp`) from default template config; use Path A (browser tools) or Path B (Playwright CLI) instead — Path C now opt-in only ([7fe3fea](https://github.com/asafelobotomy/copilot-instructions-template/commit/7fe3fea))
* **mcp:** replace `duckduckgo-search` MCP placeholder with `duckduckgo-mcp-server` (`uvx`); add as default web search provider ([7fe3fea](https://github.com/asafelobotomy/copilot-instructions-template/commit/7fe3fea))

### Fixed

* **mcp:** add missing `github` server entry to `.vscode/mcp.json` (disabled by default); update MCP Protocol tier note in developer instructions ([bf62716](https://github.com/asafelobotomy/copilot-instructions-template/commit/bf62716))
* **hooks:** harden `pulse.sh` stdio contract; fix `pulse_runtime.py` importability (move module-level execution into `main()`); fix `save-context.ps1` priority-row selection parity with shell version; wrap `session_reflect_fallback.py` loader in error-safe try/except; fix `mcp-npx.sh` SC2012 lint warning ([01e7967](https://github.com/asafelobotomy/copilot-instructions-template/commit/01e7967))
* **agents:** remove stale `playwright` and `gitkraken` entries from `mcp-servers:` allowlists in 6 agents; replace GitKraken-specific tool calls in `commit.agent.md` body with `mcp_git_*` / `mcp_github_*` equivalents; remove literal `{{...}}` tokens from agent prose; split `llms.txt` Skills catalog into Developer and Plugin sections; add `mcp-servers:` ID validation to agent frontmatter validator; add `llms.txt` link-target existence check to cross-reference validator ([9d1e549](https://github.com/asafelobotomy/copilot-instructions-template/commit/9d1e549))

### Added

* **hooks:** extract `guard-policy.json` (13 blocked + 11 caution + 6 readonly-write patterns) as single source for guard-destructive logic
* **hooks:** extract `secrets-patterns.json` (25 patterns) as single source for scan-secrets logic
* **hooks:** add `json_field` and `try_exec_in_container` helpers to `lib-hooks.sh` to centralize inline Python and distrobox logic
* **scripts:** extract `validate_agent_frontmatter.py` from shell heredoc into standalone Python CI module
* **scripts:** add `scripts/ci/validate-manifest-alignment.sh` for routing-manifest vs. frontmatter alignment validation
* **tests:** add `tests/lib/suite-bootstrap.sh` and `tests/lib/guard-test-helpers.sh` to reduce per-suite ceremony
* **scripts:** add `require_file` and `find_repo_root` helpers to `scripts/lib.sh`
* **models:** add Grok Code Fast 1, Raptor mini, and Gemini 3.1 Pro to model registry; enforce 7.5× rate exclusion policy; correct GPT-5.4 nano → GPT-5.4 mini for VS Code clients
* **settings:** add 8 optimized Copilot settings to `template/vscode/settings.json` — `codesearch.enabled`, `checkpoints.showFileChanges`, `agent.maxRequests: 50`, `autopilot.enabled`, `copilotMemory.enabled`, `agent.thinkingTool`, `codeGeneration.useInstructionFiles`, `useClaudeMdFile`

### Fixed

* **setup:** fix duplicate "All-local mode" heading in `template/setup/manifests.md` hook scripts section — plugin-backed guard clauses now appear before the all-local block
* **setup:** split interview Batch 7 into Batches 7 and 8 so no batch exceeds the 4-question `ask_questions` limit
* **setup:** add E24 (thinking effort) handling step to `agents/setup.agent.md` §2 so the Thinking Effort Configuration table in §10 is correctly customised during install
* **settings:** remove retired models from dev workspace `serverSampling` lists (`gpt-5.1`, `gpt-5.1-codex*`, `gemini-3-pro-preview`, `oswe-vscode-prime`); normalize ordering across all 5 MCP servers; add `gpt-5.4-mini`

## [0.6.2](https://github.com/asafelobotomy/copilot-instructions-template/compare/v0.6.1...v0.6.2) (2026-04-17)

### Fixed

* fix stale Setup-agent references in developer docs, audit rules, and setup manifests
* fix strict JSON validity for MCP configuration files and align customization contracts with the new protocol source

## [0.6.1](https://github.com/asafelobotomy/copilot-instructions-template/compare/v0.6.0...v0.6.1) (2026-04-16)

### Changed

* **skills:** compress prose across 16 SKILL.md files for token efficiency (−391 LOC, 15.5% reduction)

### Fixed

* **refactor:** canonicalize heartbeat routing to Python-only, slim PS1 pulse test, split audit test, extract Python selector, tighten MCP policy prose

## [0.6.0](https://github.com/asafelobotomy/copilot-instructions-template/compare/v5.12.0...v0.6.0) (2026-04-14)


### Changed

* **versioning:** reset version scheme from 5.x to 0.x to signal beta status


> Historical entries from `v5.12.0` back to `v1.0.0` are archived in [CHANGELOG.archive.md](CHANGELOG.archive.md).
