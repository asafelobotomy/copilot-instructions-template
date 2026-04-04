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
| <https://code.visualstudio.com/updates/v1_110> | v1.110 Feb 2026 — agent plugins, agentic browser tools, context compaction, fork session (superseded by v1.114) | 2026-03-28 | release-notes |
| <https://docs.github.com/en/copilot/concepts/billing/copilot-requests> | Model multipliers (0x included, 0.33x light, 1x standard, 3x flagship); premium request accounting; 10% auto-selection discount | 2026-03-28 | billing, multipliers |
| <https://docs.github.com/en/copilot/reference/ai-models/model-comparison> | Task-based model comparison table: all models with task categories, model card links | 2026-03-28 | models, reference |
| <https://docs.github.com/en/copilot/using-github-copilot/ai-models/supported-ai-models-in-copilot> | Canonical model list; plan availability; retirement history; LTS models | 2026-03-28 | models, reference |
| <https://docs.github.com/en/copilot/concepts/auto-model-selection> | Auto model selection: qualifying models, 10% multiplier discount for paid plans, coding agent auto selection | 2026-03-28 | models, billing |
| <https://docs.github.com/en/copilot/concepts/fallback-and-lts-models> | GPT-5.3-Codex designated base+LTS model 2026-03-18; GPT-4.1 is premium-exhausted fallback; LTS commitment = 1 year | 2026-04-04 | models, lts, base-model |
| <https://code.visualstudio.com/updates/v1_111> | v1.111 (2026-03-09) — Autopilot Preview, agent permission levels (Default/Bypass/Autopilot), agent-scoped hooks Preview in `.agent.md` frontmatter | 2026-04-04 | agents, autopilot, hooks |
| <https://code.visualstudio.com/updates> | Current stable: v1.114.0 (2026-04-01) — `/troubleshoot` for chat, codebase search semantic-only, video in image carousel | 2026-04-04 | stable, release-notes |

## Release Automation Tooling

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://github.com/googleapis/release-please> | release-please README — releasable units (feat/fix/deps only), path config (single dir), release-as commit footer, monorepo manifest | 2026-03-30 | release, semver, changelog |
| <https://raw.githubusercontent.com/googleapis/release-please/main/docs/manifest-releaser.md> | Manifest config — exclude-paths per package, release-as per package, skip-github-release, force-tag-creation | 2026-03-30 | release, manifest |
| <https://raw.githubusercontent.com/googleapis/release-please/main/docs/customizing.md> | Customising releases — single-path subdirectory scoping via `path`, versioning strategies, extra-files, pull-request-title-pattern | 2026-03-30 | release, customisation |
| <https://github.com/googleapis/release-please-action> | Action inputs — release-as (direct input), skip-github-release, skip-github-pull-request, config-file, manifest-file | 2026-03-30 | release, actions |
| <https://github.com/changesets/changesets> | Changesets — intent-file model for multi-package repos; requires contributor to run `changeset add`; not path-based | 2026-03-30 | release, changesets, monorepo |
| <https://github.com/changesets/action> | Changesets CI action — hasChangesets and published outputs; version/publish commands; no path filtering | 2026-03-30 | release, changesets, actions |
| <https://github.com/semantic-release/semantic-release> | semantic-release — fully automated, no PR, no path filter; [skip ci] loop prevention via @semantic-release/git | 2026-03-30 | release, semantic-release |
| <https://github.com/release-drafter/release-drafter> | release-drafter — draft-only, human publishes; include-paths filters changelog entries (not release gating) | 2026-03-30 | release, changelog |
| <https://github.com/tj-actions/changed-files> | Changed-files action — glob patterns, any_changed boolean output; requires sha: input for workflow_run context | 2026-03-30 | actions, path-filter |

## VS Code Copilot — LM Tool API and Built-in Tool Names

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/api/extension-guides/ai/tools> | LM Tool naming convention: `{verb}_{noun}`; contributed via `contributes.languageModelTools` in package.json; `canBeReferencedInPrompt`, `toolReferenceName`, `modelDescription` fields | 2026-04-02 | tools, lm-api, extensions |
| <https://code.visualstudio.com/docs/copilot/reference/copilot-vscode-features#_chat-tools> | Complete built-in tool table (April 2026): `#search/usages`, `#read/problems`, `#web/fetch` — NOT `list_code_usages`, `get_errors`, `fetch_webpage` in user-facing names | 2026-04-02 | tools, built-in, reference |

## VS Code Copilot — Hooks, Skills, Agents Schema (2026-04)

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/docs/copilot/customization/hooks> | Hooks: all 8 lifecycle events, common input fields (sessionId, transcript_path on all events), per-event input/output schemas, `hookSpecificOutput.additionalContext` for context injection, `systemMessage` is user-facing warning only, Stop `decision:"block"` via hookSpecificOutput | 2026-04-01 | hooks, agents, customisation |
| <https://code.visualstudio.com/docs/copilot/customization/agent-skills> | SKILL.md VS Code-specific frontmatter: name, description, argument-hint, user-invocable, disable-model-invocation. No stack/tags metadata. Agent loads by description relevance only. | 2026-04-01 | skills, customisation |
| <https://agentskills.io/specification> | Agent Skills open spec: frontmatter fields include metadata (arbitrary key-value map), compatibility, allowed-tools (experimental). No stacks field in spec. | 2026-04-01 | skills, spec, agentskills |
| <https://code.visualstudio.com/updates/v1_111> | v1.111 March 9 2026 — first weekly stable; Autopilot/agent permissions; agent-scoped hooks Preview (`hooks` field in .agent.md, requires chat.useCustomAgentHooks); debug events snapshot | 2026-04-01 | release-notes, agents, hooks |
| <https://code.visualstudio.com/updates/v1_112> | v1.112 March 18 2026 — /troubleshoot skill (debug logs), sandbox MCP servers, image/binary file agents, monorepo parent-repo discovery (chat.useCustomizationsInParentRepositories) | 2026-04-01 | release-notes, mcp, agents |
| <https://code.visualstudio.com/updates/v1_113> | v1.113 March 25 2026 — Chat Customizations editor Preview; configurable thinking effort in model picker (deprecated: anthropic.thinking.effort, responsesApiReasoningEffort settings); nested subagents | 2026-04-01 | release-notes, agents, thinking-effort |
| <https://code.visualstudio.com/updates/v1_114> | v1.114 April 1 2026 (latest stable) — copy final response, /troubleshoot previous sessions, workspace search simplification (#codebase now pure semantic only) | 2026-04-01 | release-notes, latest |

## zsh Shell Options — ERR_EXIT, NOUNSET, LOCAL_OPTIONS, emulate -L

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://zsh.sourceforge.io/Doc/Release/Options.html> | Canonical zsh options reference — ERR_EXIT (-e): exits shell on non-zero status; LOCAL_OPTIONS (<K>): restores options on function return; `emulate -L` activates LOCAL_OPTIONS, LOCAL_PATTERNS, LOCAL_TRAPS | 2026-04-03 | zsh, options, errexit, localoptions |
| <https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html> | `emulate [-lLR] [shell [flags...]]`: -L activates LOCAL_OPTIONS/LOCAL_PATTERNS/LOCAL_TRAPS, scoping all option changes to the enclosing function; `emulate -L zsh` is canonical pattern for safe option scoping | 2026-04-03 | zsh, emulate, builtins |
| <https://zsh.sourceforge.io/Doc/Release/Functions.html> | Anonymous functions `() { ... }` provide local variable/option scope; paired with `emulate -L zsh` is the recommended way to scope options in zsh without function definitions | 2026-04-03 | zsh, functions, anonymous |
| <https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html> | bash `set -e` / `set -u` / `set -o pipefail` reference; -e does NOT apply to the outer shell when a subshell is used — subshell exits, but the parent continues | 2026-04-03 | bash, set-e, nounset, pipefail |

## VS Code Shell Integration — zsh Hook Scripts

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/docs/terminal/shell-integration> | VS Code shell integration: zsh support via shellIntegration-rc.zsh injected at $ZDOTDIR; adds precmd/preexec hooks and OSC 633 sentinel sequences; shell integration quality levels (Rich/Basic/None) | 2026-04-03 | vscode, terminal, shell-integration, zsh |
| <file:///opt/visual-studio-code-insiders/resources/app/out/vs/workbench/contrib/terminal/common/scripts/shellIntegration-rc.zsh> | Local VS Code Insiders shell integration script — adds `__vsc_precmd`/`__vsc_preexec` hooks; `__vsc_update_prompt` references `$RPROMPT` without `${RPROMPT-}` guard; NOUNSET check at load-time only; `__vsc_escape_value` uses `emulate -L zsh` but other hooks do NOT | 2026-04-03 | vscode, zsh, shell-integration, internal |

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

## Heartbeat / Agent Health Files

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://docs.openclaw.ai/gateway/heartbeat> | OpenClaw heartbeat: timed interval turns (30m default), HEARTBEAT_OK suppression, lightContext/isolatedSession cost controls, response-contract, HEARTBEAT.md as read-only checklist input | 2026-03-30 | heartbeat, openclaw, agent-health |
| <https://docs.openclaw.ai/automation/cron-vs-heartbeat> | Cron vs Heartbeat decision guide: heartbeat = batched main-session awareness, cron = exact timing + isolation. Heartbeat reduces API calls vs many small pollers | 2026-03-30 | heartbeat, cron, openclaw |
| <https://code.visualstudio.com/docs/copilot/customization/hooks> | VS Code hooks full reference: 8 lifecycle events, Stop hook decision:block vs continue:false semantics, PreCompact additionalContext-only output, SessionStart sessionId field, timeout constraints | 2026-03-30 | hooks, vscode, lifecycle |
| <https://code.visualstudio.com/docs/copilot/customization/agent-plugins> | Agent plugins: bundles of skills/hooks/agents/MCP servers; CLAUDE_PLUGIN_ROOT env var; hooks.json discovered automatically; plugin hooks fire alongside workspace hooks | 2026-03-30 | plugins, vscode, hooks |
| <https://martinfowler.com/articles/201701-event-driven.html> | Fowler event-driven patterns: Event Notification vs Event-Carried State Transfer vs Event Sourcing; event-as-passive-aggressive-command anti-pattern | 2026-03-30 | event-driven, patterns, architecture |

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
