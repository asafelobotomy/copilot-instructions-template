# Research URL Tracker — copilot-instructions-template

> Living document. Append rows as new useful URLs are discovered. All agents may update this file.
> Do not delete rows — mark stale entries with `(stale)` in the Summary column.

## VS Code Copilot — AI Customisation

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/docs/copilot/customization/custom-agents> | Custom agents: frontmatter schema, tool names, handoffs, `user-invocable`, `disable-model-invocation` | 2026-03-19 | agents, customisation |
| <https://code.visualstudio.com/docs/copilot/reference/copilot-vscode-features#_chat-tools> | Complete built-in tool list — `#fetch`, `#codebase`, `#editFiles`, `#webSearch` is NOT a VS Code built-in | 2026-03-19 | tools, reference |
| <https://code.visualstudio.com/docs/copilot/agents/agent-tools> | Tool approval flow, URL pre/post approval, tool sets, terminal sandboxing | 2026-03-19 | tools, security |
| <https://code.visualstudio.com/docs/copilot/copilot-customization> | Overview of all customisation types: agents, skills, instructions, prompts, hooks, plugins | 2026-03-19 | customisation |
| <https://code.visualstudio.com/api/extension-guides/ai/ai-extensibility-overview> | AI extensibility options: LM tools, MCP tools, chat participants, Language Model API | 2026-03-19 | api, extensibility |

## Model Context Protocol (MCP)

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://modelcontextprotocol.io/> | Official MCP specification and SDK | 2026-03-15 | mcp |
| <https://code.visualstudio.com/docs/copilot/customization/mcp-servers> | VS Code MCP server configuration | 2026-03-15 | mcp, vscode |
| <https://github.com/modelcontextprotocol/servers> | MCP reference server implementations — Filesystem, Git, Memory, Sequential Thinking, Fetch; Git/Filesystem already configured in .vscode/mcp.json | 2026-03-28 | mcp, reference |
| <https://modelcontextprotocol.io/docs/tools/inspector> | MCP Inspector — interactive dev tool for testing MCP servers via npx; useful for debugging custom tool servers | 2026-03-28 | mcp, debug, tooling |

## GitHub Copilot — Models and Thinking Effort

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://docs.github.com/en/copilot> | GitHub Copilot documentation hub | 2026-03-15 | github, copilot |
| <https://code.visualstudio.com/docs/copilot/customization/language-models> | Configure thinking effort (None/Low/Medium/High via model picker `>` submenu); deprecated settings; BYOK; auto model selection; multipliers | 2026-03-28 | thinking-effort, models, billing |
| <https://code.visualstudio.com/docs/copilot/concepts/language-models> | Concepts: thinking tokens, context window, adaptive reasoning, effort levels vary by model and provider | 2026-03-28 | thinking-effort, concepts |
| <https://code.visualstudio.com/updates/v1_99> | v1.99 Mar 2025 — Thinking Tool (experimental, agent mode only, any model); `github.copilot.chat.agent.thinkingTool` setting | 2026-03-28 | thinking-tool, agents |
| <https://code.visualstudio.com/updates/v1_109> | v1.109 Jan 2026 — Anthropic thinking tokens rendered in chat UX; `chat.thinking.style`, `chat.agent.thinking.collapsedTools` settings | 2026-03-28 | thinking-effort, ux |
| <https://code.visualstudio.com/updates/v1_110> | v1.110 Feb 2026 — current stable; agent plugins, agentic browser tools, context compaction, fork session | 2026-03-28 | stable, release-notes |
| <https://docs.github.com/en/copilot/concepts/billing/copilot-requests> | Model multipliers (0x included, 0.33x light, 1x standard, 3x flagship); premium request accounting; 10% auto-selection discount | 2026-03-28 | billing, multipliers |
| <https://docs.github.com/en/copilot/reference/ai-models/model-comparison> | Task-based model comparison table: all models with task categories, model card links | 2026-03-28 | models, reference |
| <https://docs.github.com/en/copilot/using-github-copilot/ai-models/supported-ai-models-in-copilot> | Canonical model list; plan availability; retirement history; LTS models | 2026-03-28 | models, reference |
| <https://docs.github.com/en/copilot/concepts/auto-model-selection> | Auto model selection: qualifying models, 10% multiplier discount for paid plans, coding agent auto selection | 2026-03-28 | models, billing |

## Shell Testing Frameworks

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://bats-core.readthedocs.io/en/stable/writing-tests.html> | BATS writing tests — `run` helper, `@test` blocks, `$status`/`$output`/`${lines[@]}`, `setup`/`teardown`, `setup_file`/`teardown_file`, tags, TAP/JUnit output | 2026-03-30 | bash, testing, bats |
| <https://bats-core.readthedocs.io/en/stable/gotchas.html> | BATS gotchas — negation semantics, subshell variable scope, `[[ ]]` on bash 3.2, background-task FD leaks | 2026-03-30 | bash, testing, bats |
| <https://bats-core.readthedocs.io/en/stable/tutorial.html> | BATS tutorial — submodule install, fixture setup, bats-assert integration, `$BATS_TEST_FILENAME` anchor | 2026-03-30 | bash, testing, bats |
| <https://bats-core.readthedocs.io/en/stable/faq.html> | BATS FAQ — working directory, debugging failures, `--filter` / `--negative-filter`, skip syntax, `--jobs` parallelism | 2026-03-30 | bash, testing, bats |
| <https://shellspec.info/> | ShellSpec — full-featured BDD testing for all POSIX shells; mocking, parameterized tests, code coverage via kcov, parallel execution, TAP/JUnit output | 2026-03-30 | bash, testing, shellspec, bdd |
| <https://shellspec.info/comparison.html> | ShellSpec vs shUnit2 vs BATS-core feature comparison table — coverage, mocking, parameterized tests, parallel execution, JUnit XML | 2026-03-30 | bash, testing, comparison |
| <https://github.com/dodie/testing-in-bash> | Community bash test framework comparison — bashunit, BATS, shUnit2, bash_unit, ShellSpec, shpec; feature matrix and test-drive examples | 2026-03-30 | bash, testing, comparison |
| <http://testanything.org/> | TAP (Test Anything Protocol) specification — plan line `1..N`, `ok N - desc`, `not ok N - desc`, YAML diagnostic block | 2026-03-30 | testing, tap, ci |

## Shell Scripting / CI Automation

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://google.github.io/styleguide/shellguide.html> | Google Shell Style Guide — error routing to stderr, function comments, `err()` pattern, SUID/SGID rules | 2026-03-28 | bash, style, ci |
| <https://github.com/kvz/bash3boilerplate> | bash3boilerplate — canonical patterns for logging, cleanup traps, subshell safety, argument parsing | 2026-03-28 | bash, lib, patterns |
| <https://github.com/adrienverge/yamllint> | yamllint — Python-based YAML linter with configurable rules; supports inline disable comments and gitignore-style ignore patterns | 2026-03-28 | yaml, lint, ci |
| <https://github.com/mikefarah/yq> | yq — lightweight Go binary for YAML/JSON/XML processing; suitable for bash-native frontmatter field extraction without Python | 2026-03-28 | yaml, bash, tooling |
| <https://python-frontmatter.readthedocs.io/en/latest/> | python-frontmatter — zero-dep Python library for parsing Jekyll-style YAML front matter from .md files | 2026-03-28 | python, frontmatter, yaml |
| <https://github.com/DavidAnson/markdownlint-cli2> | markdownlint-cli2 — configuration-based Markdown linter CLI; already in use in this repo via .markdownlint-cli2.yaml | 2026-03-28 | markdown, lint, ci |
| <https://github.com/modelcontextprotocol/servers> | MCP reference server implementations — Filesystem, Git, Memory, Sequential Thinking, Fetch; Git/Filesystem already configured in .vscode/mcp.json | 2026-03-28 | mcp, reference |

## Metadata, Constants, and AI Agent File Patterns

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://llmstxt.org/> | llms.txt spec — Markdown navigation file at /llms.txt for LLM consumption; H1 title + blockquote summary + H2-delimited link lists; "Optional" section for skippable content | 2026-03-30 | llms-txt, ai-metadata, standards |
| <https://github.com/agentsmd/agents.md> | AGENTS.md open standard — Markdown format for coding agent instructions; dev tips, testing, PR instructions; nearest file in tree takes precedence; now officially recognised by GitHub Copilot | 2026-03-30 | agents, ai-metadata, standards |
| <https://conventionalcommits.org/en/v1.0.0/> | Conventional Commits 1.0.0 spec — structured commit message format; correlates with SemVer (fix=PATCH, feat=MINOR, BREAKING CHANGE=MAJOR) | 2026-03-30 | commits, changelog, standards |
| <https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot> | GitHub Copilot custom instructions — three types: repository-wide (copilot-instructions.md), path-scoped (.instructions.md), agent (AGENTS.md / CLAUDE.md / GEMINI.md) | 2026-03-30 | copilot, customisation, instructions |
| <https://raw.githubusercontent.com/hashicorp/terraform/main/version/version.go> | Terraform version.go — reads VERSION via //go:embed; canonical single-source-of-truth version pattern for Go repos | 2026-03-30 | terraform, version, constants |
| <https://raw.githubusercontent.com/angular/angular/main/package.json> | Angular monorepo root package.json — private:true, pnpm workspace, centralised scripts and dependency pins; version lives in per-package package.json | 2026-03-30 | angular, package-json, monorepo |
| <https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md> | release-please manifest-releaser — two-file pattern: release-please-config.json (human config) + .release-please-manifest.json (machine state, dot-prefix); textbook SRP for metadata files | 2026-03-30 | release-please, github, metadata |
| <https://raw.githubusercontent.com/renovatebot/renovate/main/renovate.json> | Renovate config — uses $schema for IDE validation; tool-scoped single config; extends pattern for shared presets | 2026-03-30 | renovate, json-schema, config |
| <https://json-schema.org/learn/getting-started-step-by-step> | JSON Schema getting started — $schema, $id, title, description, type, properties, required; draft 2020-12; enables IDE validation for any JSON config file | 2026-03-30 | json-schema, validation, standards |
| <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners> | CODEOWNERS — single-responsibility ownership file; gitignore-style patterns; located at .github/, root, or docs/; case-sensitive | 2026-03-30 | github, codeowners, conventions |
| <https://modelcontextprotocol.io/docs/tools/inspector> | MCP Inspector — interactive dev tool for testing MCP servers via npx; useful for debugging custom tool servers | 2026-03-28 | mcp, debug, tooling |

## Copilot Audit Tool Design

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/docs/copilot/customization/custom-instructions> | Full inventory of instruction file types, frontmatter fields, `applyTo` patterns, file locations | 2026-03-29 | instructions, audit, frontmatter |
| <https://code.visualstudio.com/docs/copilot/customization/custom-agents> | `.agent.md` frontmatter — name, description, model, tools, agents, handoffs, user-invocable, disable-model-invocation | 2026-03-29 | agents, audit, frontmatter |
| <https://code.visualstudio.com/docs/copilot/customization/agent-skills> | `SKILL.md` format; VS Code extra fields; skill discovery locations | 2026-03-29 | skills, audit, frontmatter |
| <https://code.visualstudio.com/docs/copilot/customization/prompt-files> | `.prompt.md` frontmatter — description, name, argument-hint, agent, model, tools (all optional) | 2026-03-29 | prompts, audit, frontmatter |
| <https://code.visualstudio.com/docs/copilot/customization/hooks> | 8 hook event types, file locations, JSON wire format, `chat.hookFilesLocations` defaults | 2026-03-29 | hooks, audit |
| <https://code.visualstudio.com/docs/copilot/reference/mcp-configuration> | Full MCP JSON schema field reference — stdio, http/sse, sandbox, input variables, dev mode | 2026-03-29 | mcp, audit, schema |
| <https://code.visualstudio.com/docs/copilot/reference/copilot-settings> | Complete chat.\* and github.copilot.\* settings reference; plugin/MCP settings | 2026-03-29 | settings, audit, reference |
| <https://agentskills.io/specification> | Agent Skills spec — name/description constraints, allowed-tools, token budget (~100 tokens metadata, <5000 body) | 2026-03-29 | skills, validation, spec |
| <https://raw.githubusercontent.com/agentskills/agentskills/main/skills-ref/README.md> | skills-ref CLI — validate, read-properties, to-prompt commands; Python API; marked "demo only" | 2026-03-29 | skills, validation, cli |
| <https://github.com/openai/tiktoken> | tiktoken BPE tokeniser; cl100k_base is best offline proxy for Claude token counts (±10%) | 2026-03-29 | tokens, estimation, python |
| <https://github.com/koalaman/shellcheck> | ShellCheck — bash/sh static analysis; -f json for machine output; exits non-zero on violations | 2026-03-29 | bash, lint, audit |

## Cross-Distro VS Code + Copilot Configuration

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/docs/copilot/reference/mcp-configuration> | MCP config full reference — `${env:VAR}`, `envFile`, `${workspaceFolder}`, `${userHome}` variables; sandbox, input variables | 2026-03-30 | mcp, cross-distro, variables |
| <https://code.visualstudio.com/docs/editor/variables-reference> | Full VS Code variable substitution reference; `settings.json` support limited to terminal keys only | 2026-03-30 | variables, settings, cross-distro |
| <https://code.visualstudio.com/docs/configure/settings> | Settings scopes; machine-scoped settings excluded from sync; no per-OS override in `settings.json` | 2026-03-30 | settings, cross-distro, sync |
| <https://code.visualstudio.com/docs/configure/profiles> | Profiles: full config isolation per machine; own settings.json, MCP servers, extensions | 2026-03-30 | profiles, cross-distro, settings |
| <https://code.visualstudio.com/docs/editor/settings-sync> | Settings Sync: `machine` scope excluded by default; `settingsSync.ignoredSettings` for exclusions | 2026-03-30 | sync, machine-settings, cross-distro |
| <https://code.visualstudio.com/docs/terminal/profiles> | Terminal profiles: first-class `terminal.integrated.profiles.linux/.osx/.windows` per-platform settings | 2026-03-30 | terminal, platform-settings, cross-distro |
| <https://code.visualstudio.com/docs/reference/tasks-appendix> | `tasks.json` schema: top-level `linux`, `osx`, `windows` fields in `TaskConfiguration` interface | 2026-03-30 | tasks, platform-settings, schema |
| <https://code.visualstudio.com/docs/debugtest/debugging-configuration> | `launch.json` platform-specific literals: `windows`, `linux`, `osx` within individual configurations | 2026-03-30 | launch, platform-settings, debugging |
