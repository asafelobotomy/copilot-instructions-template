# Research URL Tracker — copilot-instructions-template

<!-- workspace-layer: L2 | trigger: research request -->
> **Domain**: References — URLs, external documentation, and research notes.
> **Boundary**: No internal project facts, preferences, or reasoning.
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

## VS Code Copilot — Memory Tool

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/docs/copilot/agents/memory> | Canonical memory tool docs: scopes (user/repo/session), storage (local, GitHub Copilot Chat extension), settings (`github.copilot.chat.tools.memory.enabled`, `github.copilot.chat.copilotMemory.enabled`), no path redirect setting | 2026-04-09 | memory, agents, storage |

## MCP Servers — Web Access and Search

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://github.com/microsoft/playwright-mcp> | Playwright MCP — full browser automation via accessibility tree; ~20 core tools; README explicitly recommends CLI+SKILLS over MCP for coding agents | 2026-04-28 | mcp, playwright, browser |
| <https://github.com/modelcontextprotocol/servers/blob/main/src/fetch/README.md> | mcp-server-fetch — single `fetch` tool, URL→Markdown; no search capability | 2026-04-28 | mcp, fetch, reference |
| <https://github.com/exa-labs/exa-mcp-server> | Exa MCP — `web_search_exa` + `web_fetch_exa` tools; remote HTTP server at mcp.exa.ai; API key required; neural search excellent for technical docs | 2026-04-28 | mcp, search, exa |
| <https://github.com/brave/brave-search-mcp-server> | Brave Search MCP (official, replaces archived `@modelcontextprotocol/server-brave-search`); tools: `brave_web_search`, `brave_news_search`, `brave_image_search`, `brave_video_search`, `brave_summarizer`; API key required; 2,000 free queries/month | 2026-04-28 | mcp, search, brave |
| <https://github.com/nickclyde/duckduckgo-mcp-server> | DuckDuckGo MCP — `search` + `fetch_content` tools; no API key required; uvx install; rate-limited 30 req/min | 2026-04-28 | mcp, search, duckduckgo, free |
| <https://github.com/tavily-ai/tavily-mcp> | Tavily MCP — `tavily-search`, `tavily-extract`, `tavily-map`, crawl tools; API key required; 1,000 free credits/month; remote at mcp.tavily.com | 2026-04-28 | mcp, search, tavily |
| <https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-websearchforcopilot> | vscode-websearchforcopilot — VS Code extension adding `@websearch` participant and `#websearch` LM tool; powered by Tavily; API key required; NOT an MCP server | 2026-04-28 | vscode, extension, search, tavily |
| <https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-release-status.yml> | Canonical GA/preview/closing-down status for all Copilot models; all modes (agent/ask/edit) per model | 2026-04-14 | models, release-status |
| <https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-deprecation-history.yml> | Full retirement history with dates and successor models; GPT-5.1 retires 2026-04-15 | 2026-04-14 | models, deprecation |
| <https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-multipliers.yml> | Premium request multipliers per model for paid and free plans | 2026-04-14 | models, billing, multipliers |
| <https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-supported-clients.yml> | Per-model client availability matrix (dotcom/CLI/VS Code/VS/Eclipse/Xcode/JetBrains) | 2026-04-14 | models, clients |
| <https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-supported-plans.yml> | Per-model plan availability (Free/Student/Pro/Pro+/Business/Enterprise) | 2026-04-14 | models, plans |
| <https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-comparison.yml> | Task-to-model recommendation data with task areas and model card links | 2026-04-14 | models, comparison |
| <https://code.visualstudio.com/docs/copilot/concepts/agents#_memory> | Memory concepts section: virtual paths `/memories/`, `/memories/repo/`, `/memories/session/`; user memory first 200 lines auto-loaded per session; local vs Copilot Memory distinction | 2026-04-09 | memory, concepts, agents |
| <https://code.visualstudio.com/docs/copilot/reference/copilot-vscode-features> | Cheat sheet for all VS Code Copilot features; confirms memory is listed under Planning; tool set reference table; `/memories` slash command for Claude agent | 2026-04-09 | reference, tools, features |
| <https://docs.github.com/copilot/how-tos/use-copilot-agents/copilot-memory> | GitHub-hosted Copilot Memory (separate from local memory tool): cross-surface, repo-scoped, 28-day expiry, off by default | 2026-04-09 | memory, github, copilot-memory |
| <https://github.blog/ai-and-ml/github-copilot/building-an-agentic-memory-system-for-github-copilot/> | Engineering blog: just-in-time citation verification, store_memory tool call schema (subject/fact/citations/reason), cross-agent memory sharing, 7% PR merge rate uplift, adversarial stress-testing | 2026-04-09 | memory, architecture, copilot-memory |

## Bootstrap & Distribution — 2026-04-12

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/docs/copilot/customization/agent-plugins> | Agent plugins (preview): install from Git URL, workspace recommendations, enabledPlugins + extraKnownMarketplaces, plugin.json structure, hooks.json and .mcp.json in plugin root | 2026-04-12 | plugins, distribution, bootstrap |

## Risk-Based Test Selection — 2026-04-12

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://engineering.fb.com/2018/11/21/developer-tools/predictive-test-selection/> | Meta predictive test selection: gradient-boosted model, 99.9% faulty-change catch rate, runs 1/3 of impacted tests, doubles infrastructure efficiency | 2026-04-12 | test-selection, ml, meta |
| <https://arxiv.org/abs/1810.05286> | Machalica et al. — Predictive Test Selection paper: >95% individual failure catch, flakiness handling, gradient-boosted trees on change features | 2026-04-12 | test-selection, ml, paper |
| <https://abseil.io/resources/swe-book/html/ch23.html> | Google SWE Book Ch.23 — TAP: global dependency graph, presubmit/post-submit split, 11-min avg wait, Takeout case study (50% fewer broken deploys) | 2026-04-12 | test-selection, google, ci |
| <https://devblogs.microsoft.com/devops/accelerated-continuous-testing-with-test-impact-analysis-part-1/> | Microsoft TIA: file-level instrumentation, >15 min threshold for ROI, periodic override required, managed .NET only | 2026-04-12 | test-selection, microsoft, tia |
| <https://docs.datadoghq.com/tests/test_impact_analysis.md> | Datadog Test Impact Analysis (ITR): coverage-based, tracked files, unskippable tests, ITR:NoSkip commit/PR escape hatches, branch exclusion | 2026-04-12 | test-selection, datadog, ci |
| <https://docs.launchableinc.com/> | Launchable: SaaS ML predictive selection, confidence scoring, test health trends, parallelization bin-packing, Slack notifications | 2026-04-12 | test-selection, launchable, ml |
| <https://engineering.fb.com/2026/02/11/developer-tools/the-death-of-traditional-testing-agentic-development-jit-testing-revival/> | Meta JiTTesting 2026: LLM-generated on-the-fly tests for each change via mutation testing; addresses agentic development test burden | 2026-04-12 | jit-testing, meta, agentic, 2026 |
| <https://testmon.org/> | pytest-testmon: Coverage.py-based per-method dependency tracking; --testmon-noselect for risk-ordered execution without deselection | 2026-04-12 | test-selection, python, testmon |
| <https://code.visualstudio.com/docs/copilot/security> | Trust boundaries: workspace, extension publisher, MCP server, network domain; sandbox constraints; recommended security baseline | 2026-04-12 | security, trust, sandbox |

## VS Code Terminal Agent Tools — 2026-04-22

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/updates/v1_115> | v1.115 (2026-04-08): `send_to_terminal` introduced for background terminals; `chat.tools.terminal.backgroundNotifications` experimental; `get_terminal_output` for background only | 2026-04-22 | terminal, tools, release-notes |
| <https://code.visualstudio.com/updates/v1_116> | v1.116 (2026-04-15): `send_to_terminal`/`get_terminal_output` extended to ALL visible terminals via `terminalId` (numeric instanceId); LLM prompt-detection removed; background notifications default-on | 2026-04-22 | terminal, tools, release-notes |
| <https://code.visualstudio.com/docs/copilot/concepts/trust-and-safety> | Agent sandboxing: macOS (Seatbelt) / Linux (bubblewrap+socat); read-all/write-cwd default; network blocked by default; child processes inherit restrictions; sandbox auto-approves commands | 2026-04-22 | sandbox, security, terminal |
| <https://code.visualstudio.com/docs/editor/workspace-trust> | Workspace Trust Restricted Mode disables agents, tasks, debugging; trust required before agent bootstrap can run | 2026-04-12 | security, workspace-trust |
| <https://code.visualstudio.com/docs/devcontainers/create-dev-container> | devcontainer.json: postCreateCommand + customizations.vscode.extensions for zero-touch Copilot + template install | 2026-04-12 | devcontainer, bootstrap |
| <https://code.visualstudio.com/api/working-with-extensions/publishing-extension> | VSIX packaging via vsce; Azure DevOps publisher account required; sideload vs Marketplace paths | 2026-04-12 | vsix, extension, distribution |
| <https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository> | GitHub template repos: copies directory structure + files on "Use this template"; branches have unrelated histories | 2026-04-12 | github, template-repo, bootstrap |
| <https://github.com/github/copilot-plugins> | Official Copilot plugins marketplace repo; skills only as of Apr 2026; MCP servers and hooks listed as "coming soon" | 2026-04-12 | plugins, marketplace |

## Awesome Copilot — Community Pattern Research — 2026-04-26

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://github.com/github/awesome-copilot> | Community Copilot collection: agents, instructions, skills, plugins, hooks, agentic workflows; default plugin marketplace for VS Code and Copilot CLI | 2026-04-26 | agent-plugins, marketplace, community |
| <https://awesome-copilot.github.com/llms.txt> | Machine-readable llms.txt: full structured listing of all agents, instructions, and skills with raw GitHub URLs for AI agent discovery | 2026-04-26 | llms-txt, discoverability, machine-readable |
| <https://awesome-copilot.github.com/learning-hub> | Learning Hub: 20+ curated guides covering agents, skills, hooks, MCP servers, agentic workflows, CLI intro, context management | 2026-04-26 | learning, onboarding, guides |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/docs/README.skills.md> | Skills doc: gh CLI install pattern (`gh skill install github/awesome-copilot <name>`), bundled assets column, requires GitHub CLI v2.90.0+ | 2026-04-26 | skills, gh-cli, install |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/docs/README.plugins.md> | Plugins doc: tags array per plugin, featured plugins at top, `@agentPlugins` Extensions search filter, `copilot plugin install` CLI command | 2026-04-26 | plugins, discoverability, tags |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/docs/README.hooks.md> | Hooks catalog: dependency license checker, governance audit, secrets scanner, session auto-commit, session logger, tool guardian; event types reference | 2026-04-26 | hooks, catalog, events |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/docs/README.agents.md> | Agents doc: VS Code/VS Code Insiders install badges (deeplink pattern `vscode:chat-agent/install?url=...`), MCP server dependencies per agent | 2026-04-26 | agents, install-badges, deeplink |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/CONTRIBUTING.md> | Contributing guide: quality criteria, what's rejected (no circumvention, no duplicate model strengths, no remote-source plugins), format examples | 2026-04-26 | contributing, quality, guidelines |

## VS Code Agent Plugins — Schema and Install Flow

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/docs/copilot/customization/agent-plugins> | Primary agent-plugins doc: directory structure, install via Extensions view and "Install from Source" (full repo URL only), hooks, MCP, `chat.pluginLocations`, marketplace config | 2026-04-13 | agent-plugins, schema, install |
| <https://code.claude.com/docs/en/plugins-reference> | Canonical plugin manifest schema: `name` is the only required field, complete optional fields, component paths, auto-discovery rules | 2026-04-13 | agent-plugins, schema, claude-code |
| <https://code.claude.com/docs/en/plugin-marketplaces> | Marketplace schema: `git-subdir` source type for subdirectory plugin install, `strict` mode, version management, plugin sources table | 2026-04-13 | agent-plugins, marketplace, subdirectory |
| <https://raw.githubusercontent.com/rwoll/markdown-review/main/plugin.json> | Real plugin.json cited by official VS Code docs: `name`, `description`, `version`, `author`, `repository`, `license`, `keywords`, `category`, `skills` — no `displayName`, `publisher`, `engines`, or `contributes` | 2026-04-13 | agent-plugins, example, schema |
| <https://github.com/github/copilot-plugins> | Official GitHub Copilot plugins marketplace repo — structure mirrors awesome-copilot | 2026-04-13 | agent-plugins, marketplace |
| <https://github.com/github/awesome-copilot> | Community Copilot marketplace with 50+ plugins, skills, agents, hooks; default marketplace in VS Code | 2026-04-13 | agent-plugins, marketplace |

## VS Code Extension APIs for Copilot Companion — 2026-04-16

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/api/extension-guides/ai/ai-extensibility-overview> | AI extensibility overview: LM tools vs MCP tools vs chat participants vs LM API — decision guide | 2026-04-16 | extension-api, lm-tools, mcp, copilot |
| <https://code.visualstudio.com/api/extension-guides/tools> | LM tool guide: `contributes.languageModelTools` package.json schema, `vscode.lm.registerTool()`, `LanguageModelTool<T>` interface, `prepareInvocation`, `invoke`, `LanguageModelToolResult` | 2026-04-16 | extension-api, lm-tools, stable |
| <https://code.visualstudio.com/api/extension-guides/ai/mcp> | MCP extension guide: `contributes.mcpServerDefinitionProviders`, `vscode.lm.registerMcpServerDefinitionProvider()`, `McpStdioServerDefinition`, `McpHttpServerDefinition`, dev mode, troubleshooting | 2026-04-16 | extension-api, mcp, proposed-api |
| <https://code.visualstudio.com/api/get-started/your-first-extension> | Extension scaffolding: `yo code` / `npx --package yo --package generator-code -- yo code`, TypeScript template structure | 2026-04-16 | extension-api, scaffolding, yo-code |
| <https://code.visualstudio.com/api/working-with-extensions/publishing-extension> | Publishing: `@vscode/vsce` CLI, PAT + Azure DevOps, `vsce package` for VSIX, `vsce publish`, publisher management page | 2026-04-16 | extension-api, publishing, vsix |
| <https://raw.githubusercontent.com/microsoft/vscode-extension-samples/main/mcp-extension-sample/package.json> | Real mcp-extension-sample package.json: `mcpServerDefinitionProviders` contribution point, requires `^1.101.0`, uses `@vscode/dts` for proposed API download | 2026-04-16 | extension-api, mcp, sample |
| <https://raw.githubusercontent.com/microsoft/vscode-extension-samples/main/chat-sample/package.json> | Real chat-sample package.json: `languageModelTools` contribution point shape, `chatParticipants` shape, requires `^1.100.0`, uses `@types/vscode` (stable) | 2026-04-16 | extension-api, lm-tools, sample |
| <https://raw.githubusercontent.com/microsoft/vscode-extension-samples/main/mcp-extension-sample/src/extension.ts> | MCP provider implementation: `EventEmitter<void>`, `registerMcpServerDefinitionProvider`, `McpStdioServerDefinition` constructor pattern | 2026-04-16 | extension-api, mcp, sample |

## Dependency Evaluation — 2026-04-09

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://pypi.org/project/tiktoken/> | tiktoken: OpenAI BPE tokenizer; v0.12.0 Oct 2025; CDN vocab download on first use (~1.7MB); deps: regex+requests | 2026-04-09 | deps, tokenizer, tiktoken |

## Model Landscape Audit — 2026-04-11

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://docs.github.com/en/copilot/reference/ai-models/supported-models> | Canonical supported-models page: full GA/preview table, per-client, per-plan, multipliers, retirement history | 2026-04-11 | models, reference, retirement |
| <https://docs.github.com/en/copilot/concepts/fallback-and-lts-models> | GPT-5.3-Codex designated base+LTS 2026-03-18; GPT-4.1 is premium-exhausted fallback; GPT-5.1 retiring 2026-04-15 | 2026-04-11 | models, lts, base-model, retirement |
| <https://code.visualstudio.com/docs/copilot/customization/custom-agents> | Agent frontmatter: model field is string or array of plain display names; handoffs.model uses qualified `Model Name (vendor)` format | 2026-04-11 | agents, frontmatter, models |
| <https://github.com/openai/tiktoken/releases> | tiktoken release history: 0.12.0 (Oct 2025), 0.11.0 (Aug 2025) | 2026-04-09 | deps, tokenizer |
| <https://github.com/astral-sh/ruff/releases> | ruff v0.15.9 (Apr 2026): Rust Python linter+formatter, zero Python deps, 10-100x faster than flake8/black | 2026-04-09 | deps, linter, ruff |
| <https://github.com/gorakhargosh/watchdog/releases> | watchdog v6.0.0 (Nov 2024): Python file system events; inotify/kqueue; 1 transitive dep (pathtools) | 2026-04-09 | deps, filewatcher |
| <https://github.com/rapidfuzz/RapidFuzz/releases> | rapidfuzz v3.14.5 (Apr 2026): C++ fuzzy string matching; ~9MB wheel; 0 runtime deps | 2026-04-09 | deps, fuzzy |
| <https://github.com/jqlang/jq/releases> | jq 1.8.1 (Jul 2025): CVE-2025-49014 fix (heap UAF in f_strftime); ~1MB static binary | 2026-04-09 | deps, jq, security |
| <https://github.com/koalaman/shellcheck/releases> | shellcheck v0.11.0 (Aug 2025): SC2327-2332 new checks; ~10MB Haskell static binary | 2026-04-09 | deps, shellcheck, ci |
| <https://github.com/crate-ci/typos/releases> | typos-cli v1.45.0 (Apr 2026): monthly dictionary updates; MIT; Rust; zero deps; gitignore-aware | 2026-04-09 | deps, typos, spellcheck |
| <https://github.com/crate-ci/typos/blob/master/docs/comparison.md> | typos vs codespell feature matrix: typos wins on CamelCase, snake_case, gitignore, UUID/hex/base64/SHA ignore | 2026-04-09 | deps, typos, spellcheck |
| <https://github.com/sharkdp/fd/releases> | fd v10.4.2 (Mar 2026): modern find; ~5MB binary; no Python gap in this repo | 2026-04-09 | deps, fd, system |
| <https://github.com/microsoft/LLMLingua> | LLMLingua: last active Jul 2024 (v0.2.2); effectively unmaintained; requires torch+transformers; SKIP | 2026-04-09 | deps, compression, stale |
| <https://github.com/open-compress/claw-compactor> | Claw Compactor v7.0 (Apr 2026): 14-stage fusion pipeline; 15-82% compression; tree-sitter dep; not for instruction file authoring | 2026-04-09 | deps, compression, prompt |
| <https://github.com/DelvyG/promptmin> | promptminify (Apr 2026): tiktoken-validated prompt minification; EN/ES; ~400 curated rules; not for structured Markdown | 2026-04-09 | deps, compression, prompt |
| <https://github.com/topics/prompt-compression?l=python&o=desc&s=updated> | Prompt compression landscape Apr 2026: 17 repos; no purpose-built tool for agent instruction files exists | 2026-04-09 | deps, compression, landscape |
| <https://pre-commit.com/> | pre-commit v4.5.1 (Dec 2025): git hook framework; ~15 transitive deps; SKIP for this repo due to contributor friction | 2026-04-09 | deps, pre-commit, hooks |
| <https://pypi.org/project/check-jsonschema/> | check-jsonschema: CLI + pre-commit hook wrapping jsonschema; validates JSON Schema Draft 2020-12 and GitHub Actions YAML | 2026-04-09 | deps, jsonschema, validation |
| <https://github.com/codespell-project/codespell/releases> | codespell v2.4.2 (Mar 2026): GPL v2; no gitignore support; no CamelCase; inferior to typos-cli for this repo | 2026-04-09 | deps, spellcheck |

## Claude Code — Sub-agents and Project Agents

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://docs.anthropic.com/en/docs/claude-code/sub-agents> | Claude Code sub-agents: stored in `.claude/agents/` (project) or `~/.claude/agents/` (user); frontmatter fields `name`, `description`, `tools`; invoked via `Task` tool; isolated context per agent | 2026-04-10 | claude-code, agents, sub-agents |
| <https://docs.anthropic.com/en/docs/claude-code/memory> | Claude Code memory: `CLAUDE.md` project instructions; `.claude/` as the project config directory | 2026-04-10 | claude-code, memory, instructions |

## VS Code Release Notes — v1.100–v1.115

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/updates/v1_100> | v1.100 Apr 2025 — `.instructions.md`/`.prompt.md` aligned; `applyTo`+`description` front matter; `#githubRepo` tool; MCP Streamable HTTP; faster agent edits; prompt caching | 2026-04-09 | release-notes, instructions, mcp, agents |
| <https://code.visualstudio.com/updates/v1_103> | v1.103 Jul 2025 — GPT-5; chat checkpoints; revamped tool picker; tool grouping >128 tools; terminal auto-approve; input request detection | 2026-04-09 | release-notes, tools, terminal |
| <https://code.visualstudio.com/updates/v1_105> | v1.105 Sep 2025 — Plan agent; handoffs front matter; isolated subagents (`#runSubagent`); fully qualified tool names (`server/tool`); nested AGENTS.md GA | 2026-04-09 | release-notes, agents, mcp, instructions |
| <https://code.visualstudio.com/updates/v1_107> | v1.107 Nov 2025 — Multi-agent orchestration; background agents with Git worktrees; Agent Sessions view; custom agents as subagents; Claude skills reuse | 2026-04-09 | release-notes, agents, background |
| <https://code.visualstudio.com/updates/v1_110> | v1.110 Feb 2026 — Agent plugins (skills+tools+hooks bundles); agentic browser tools; session memory; context compaction; fork session; Agent Debug panel; edit mode deprecated | 2026-04-09 | release-notes, agents, plugins |
| <https://code.visualstudio.com/updates/v1_111> | v1.111 Mar 9 2026 — Autopilot + agent permissions (Default/Bypass/Autopilot); agent-scoped hooks in `.agent.md` frontmatter; `task_complete` tool; weekly stable releases begin | 2026-04-09 | release-notes, autopilot, hooks, agents |
| <https://code.visualstudio.com/updates/v1_112> | v1.112 Mar 18 2026 — MCP server sandboxing (`sandboxEnabled`); monorepo parent-repo customisations discovery; image/binary in agents; Copilot CLI permissions; export/import debug logs | 2026-04-09 | release-notes, mcp, monorepo, sandbox |
| <https://code.visualstudio.com/updates/v1_113> | v1.113 Mar 25 2026 — Chat Customisations editor; nested subagents; MCP in CLI/Claude agents; plugin URL handlers (`vscode://chat-plugin/install`); manage plugin marketplaces | 2026-04-09 | release-notes, customisation, plugins, mcp |
| <https://code.visualstudio.com/updates/v1_114> | v1.114 Apr 1 2026 — `/troubleshoot` previous sessions; `#codebase` semantic-only; TypeScript 6.0; enterprise Claude group policy; fine-grained tool approval API (proposed) | 2026-04-09 | release-notes, troubleshoot, enterprise |
| <https://code.visualstudio.com/updates/v1_115> | v1.115 Apr 8 2026 — VS Code Agents companion app (Insiders); `send_to_terminal` tool; background terminal notifications (experimental) | 2026-04-09 | release-notes, agents, terminal |
| <https://code.visualstudio.com/docs/copilot/customization/hooks#_agentscoped-hooks> | Agent-scoped hooks: define `hooks:` in `.agent.md` frontmatter; fires only for that agent/subagent invocation | 2026-04-09 | hooks, agents, customisation |
| <https://code.visualstudio.com/docs/copilot/customization/agent-plugins> | Agent plugins: bundle skills/tools/hooks for distribution; install from Extensions view or `vscode://chat-plugin/install?source=...` URL handler | 2026-04-09 | plugins, starter-kits, distribution |
| <https://code.visualstudio.com/docs/copilot/agents/agent-tools#permission-levels> | Agent permission levels: Default Approvals / Bypass Approvals / Autopilot; `chat.autopilot.enabled`; `task_complete` tool | 2026-04-09 | agents, autopilot, security |
| <https://code.visualstudio.com/docs/copilot/customization/overview#_chat-customizations-editor> | Chat Customisations editor: unified UI for instructions/prompts/agents/skills/MCP/plugins; `Chat: Open Chat Customisations` command | 2026-04-09 | customisation, editor |

## Multi-Agent Memory Architecture

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://github.com/milla-jovovich/mempalace> | MemPalace v3.0.14 (29.9k stars): palace architecture, AAAK compression, knowledge graph. **Specialist Agents**: per-agent wings + diary (reviewer, architect, ops). 96.6% LongMemEval R@5 from raw verbatim ChromaDB — NOT from palace metaphor. +34% from wing/room filtering is standard metadata filtering. Palace metaphor organises human maintenance; vector search is what helps the AI. | 2026-04-09 | memory, multi-agent, mempalace, prior-art |
| <https://docs.letta.com/guides/get-started/intro> | Letta (formerly MemGPT): stateful agents with per-agent core + archival memory. Cross-agent sharing is explicit (tool calls), not ambient. Each agent truly owns its state. Agent isolation with explicit sharing outperforms shared-everything in their benchmarks. | 2026-04-09 | memory, multi-agent, letta, prior-art |
| <https://github.com/GhostwheeI/AI-Memory-Persistence> | AI Memory Persistence (archived Dec 2025, 0 stars): per-host model (host_template.json + global.json), not per-agent. Importance scoring 1-10. Author acknowledged native AI memory tools superseded it. | 2026-04-09 | memory, prior-art, archived |

## Release Automation Tooling

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://github.com/googleapis/release-please> | release-please README — releasable units (feat/fix/deps only), path config (single dir), release-as commit footer, monorepo manifest | 2026-03-30 | release, semver, changelog |

## tool_search / Deferred Tool Support by Model — 2026-04-28

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-release-status.yml> | (re-fetched) GPT-5 mini and GPT-5.4 mini both GA with agent_mode/ask_mode/edit_mode all true; no tool-calling restrictions | 2026-04-28 | models, agent-mode, tool-support |
| <https://docs.github.com/en/copilot/reference/ai-models/model-comparison> | (re-fetched 2026-04-28) GPT-5.4 mini explicitly recommended for "Agentic software development / codebase exploration and grep-style tools"; GPT-5 mini is general-purpose only | 2026-04-28 | models, tool-use, agentic |
| <https://code.visualstudio.com/docs/copilot/concepts/tools> | Tools overview: built-in, MCP, extension types; no model-specific tool restrictions documented | 2026-04-28 | tools, concepts, models |
| <https://code.visualstudio.com/api/extension-guides/ai/tools> | Extension LM tools guide: `contributes.languageModelTools`, `when` clause for availability — availability gated on VS Code context not model family | 2026-04-28 | extension-api, lm-tools, deferred |
| <https://code.visualstudio.com/updates/v1_117> | v1.117 (Apr 22 2026): BYOK for Business/Enterprise; incremental chat rendering; terminal improvements — no tool_search or deferred tool mentions | 2026-04-28 | release-notes, models |
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
| <https://code.visualstudio.com/docs/copilot/customization/agent-plugins> | Agent plugins: bundles of skills/hooks/agents/MCP servers; plugin-root token is format-specific (`${CLAUDE_PLUGIN_ROOT}` for Claude, `${PLUGIN_ROOT}` for OpenPlugin, none documented for Copilot); hooks.json or hooks/hooks.json discovered automatically; plugin hooks fire alongside workspace hooks | 2026-03-30 | plugins, vscode, hooks |
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

## Autonomous Agent Harnesses — claw-code

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://github.com/ultraworkers/claw-code> | Community open-source reimplementation of Claude Code; Python parity tracker + ~20K-line Rust CLI harness; GreenContract, LaneEvents, TaskPacket, RecoveryRecipes, PolicyEngine, WorkerBoot concepts | 2026-04-05 | agent-harness, rust, autonomous, claude-code |
| <https://github.com/ultraworkers/claw-code/blob/main/PHILOSOPHY.md> | Philosophy: humans set direction, claws execute; Discord as human interface; three-part system (OmX, clawhip, OmO); bottleneck is now taste/judgment not typing speed | 2026-04-05 | agent-harness, philosophy, autonomous |
| <https://github.com/ultraworkers/claw-code/blob/main/USAGE.md> | Task-oriented CLI guide: auth, build, REPL, one-shot, JSON output, session management, mock parity harness, model aliases, permission modes | 2026-04-05 | agent-harness, cli, usage |
| <https://github.com/ultraworkers/claw-code/blob/main/rust/README.md> | Rust workspace overview: 9 crates, feature table (hooks=config-only, plugins=planned, skills=planned), slash command table, model alias table | 2026-04-05 | agent-harness, rust, features |
| <https://raw.githubusercontent.com/ultraworkers/claw-code/main/rust/crates/runtime/src/lib.rs> | Runtime crate public API: ConversationRuntime, GreenContract, LaneEvents, PolicyEngine, RecoveryRecipes, WorkerBoot, TaskPacket, HookRunner, McpLifecycleHardened — full module surface | 2026-04-05 | agent-harness, rust, runtime |
| <https://raw.githubusercontent.com/ultraworkers/claw-code/main/rust/crates/runtime/src/green_contract.rs> | GreenContract: 4-level ordered test coverage enum (TargetedTests/Package/Workspace/MergeReady); evaluate() compare observed vs required; Satisfied/Unsatisfied typed outcome | 2026-04-05 | green-contract, testing, patterns |
| <https://raw.githubusercontent.com/ultraworkers/claw-code/main/rust/crates/runtime/src/lane_events.rs> | LaneEvent lifecycle: 16 named events, 10 status values, 11 LaneFailureClass variants for structured diagnostic routing | 2026-04-05 | lane-events, agent-harness, patterns |
| <https://raw.githubusercontent.com/ultraworkers/claw-code/main/rust/crates/runtime/src/task_packet.rs> | TaskPacket: 8-field validated struct (objective/scope/repo/branch_policy/acceptance_tests/commit_policy/reporting_contract/escalation_policy); non-empty validation | 2026-04-05 | task-packet, agent-harness, patterns |
| <https://raw.githubusercontent.com/ultraworkers/claw-code/main/rust/crates/runtime/src/recovery_recipes.rs> | RecoveryRecipes: 7 FailureScenario → RecoveryRecipe mapping; RecoveryStep enum; EscalationPolicy (AlertHuman/LogAndContinue/Abort); RecoveryContext with per-scenario attempt tracking | 2026-04-05 | recovery, agent-harness, patterns |
| <https://raw.githubusercontent.com/ultraworkers/claw-code/main/rust/crates/runtime/src/worker_boot.rs> | WorkerBoot state machine: Spawning to TrustRequired or ReadyForPrompt, then Running to Finished or Failed; trust auto-allowlist by cwd; prompt misdelivery detection + replay recovery | 2026-04-05 | worker-boot, agent-harness, patterns |
| <https://raw.githubusercontent.com/ultraworkers/claw-code/main/rust/crates/runtime/src/policy_engine.rs> | PolicyEngine: composable And/Or conditions, Chain actions, LaneContext evaluation; STALE_BRANCH_THRESHOLD=1h hardcoded; ReconcileReason enum | 2026-04-05 | policy-engine, agent-harness, patterns |
| <https://raw.githubusercontent.com/ultraworkers/claw-code/main/rust/crates/runtime/src/hooks.rs> | HookRunner: PreToolUse/PostToolUse/PostToolUseFailure events; abort signals (AtomicBool); progress reporter trait; stdin/stdout JSON protocol; process-per-invocation execution | 2026-04-05 | hooks, agent-harness, patterns |
| <https://raw.githubusercontent.com/ultraworkers/claw-code/main/src/tools.py> | Python tools.py: loads tools_snapshot.json into PortingModule dataclasses via @lru_cache; execute_tool returns shims only — NOT a runtime | 2026-04-05 | python, parity-tracker, not-runtime |
| <https://raw.githubusercontent.com/ultraworkers/claw-code/main/src/runtime.py> | Python PortRuntime: token-match routing, bootstrap_session assembles RuntimeSession with shim executions; route_prompt interleaves command/tool matches by kind | 2026-04-05 | python, parity-tracker, runtime |
| <https://code.visualstudio.com/docs/configure/profiles> | Profiles: full config isolation per machine; own settings.json, MCP servers, extensions | 2026-03-30 | profiles, cross-distro, settings |
| <https://code.visualstudio.com/docs/editor/settings-sync> | Settings Sync: `machine` scope excluded by default; `settingsSync.ignoredSettings` for exclusions | 2026-03-30 | sync, machine-settings, cross-distro |
| <https://code.visualstudio.com/docs/terminal/profiles> | Terminal profiles: first-class `terminal.integrated.profiles.linux/.osx/.windows` per-platform settings | 2026-03-30 | terminal, platform-settings, cross-distro |
| <https://code.visualstudio.com/docs/reference/tasks-appendix> | `tasks.json` schema: top-level `linux`, `osx`, `windows` fields in `TaskConfiguration` interface | 2026-03-30 | tasks, platform-settings, schema |
| <https://code.visualstudio.com/docs/debugtest/debugging-configuration> | `launch.json` platform-specific literals: `windows`, `linux`, `osx` within individual configurations | 2026-03-30 | launch, platform-settings, debugging |

## MCP Multi-Window Concurrency — Research 2026-04-10

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://modelcontextprotocol.io/specification/2025-06-18/basic/transports> | MCP transport spec: stdio = 1:1 client-subprocess (client launches server); Streamable HTTP explicitly supports multiple client connections via per-session Mcp-Session-Id headers | 2026-04-10 | mcp, transport, concurrency |
| <https://modelcontextprotocol.io/specification/2025-06-18/basic/lifecycle> | MCP lifecycle: Initialization (version + capability negotiation) → Operation → Shutdown (close stdin + SIGTERM + SIGKILL sequence for stdio); no multi-client multiplexing defined | 2026-04-10 | mcp, lifecycle, specification |
| <https://code.visualstudio.com/docs/copilot/guides/mcp-developer-guide> | MCP developer guide: per-window extension host spawns stdio subprocesses; workspace roots provided per-window; dynamic tool discovery; no multi-window sharing documented | 2026-04-10 | mcp, developer, lifecycle, vscode |
| <https://code.visualstudio.com/api/advanced-topics/extension-host> | Extension Host: each VS Code desktop window has its own extension host process; no shared host across windows for workspace-kind extensions; Copilot Chat = workspace extension → separate host per window | 2026-04-10 | extension-host, vscode, multi-window |

## VS Code Copilot — Agent Architecture and Agent Types (2026-04)

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/docs/copilot/agents/overview> | Agent types: Local, Copilot CLI, Cloud, Third-party; permission levels (Default/Bypass/Autopilot); handoff workflow; /delegate command; task assignment via TODO comments | 2026-04-05 | agents, overview, permissions |
| <https://code.visualstudio.com/docs/copilot/concepts/agents> | Agent loop: Understand→Act→Validate; subagents (context isolation, synchronous/parallel); planning 4-phase workflow; memory scopes (user/repo/session); VS Code assembles context per turn | 2026-04-05 | agents, concepts, loop, subagents |
| <https://code.visualstudio.com/docs/copilot/agents/subagents> | Subagent invocation: agent-initiated only; runSubagent tool; context isolation (inherits only task prompt); synchronous and parallel modes; restrict via `agents` experimental property | 2026-04-05 | subagents, delegation, isolation |
| <https://code.visualstudio.com/docs/copilot/agents/planning> | Plan agent: 4-phase (Discovery/Alignment/Design/Refinement); saves plan to `/memories/session/plan.md`; `chat.planAgent.defaultModel` setting; handoff to Copilot CLI via "Start Implementation" | 2026-04-05 | plan-agent, phases, session-memory |
| <https://code.visualstudio.com/docs/copilot/agents/copilot-cli> | Copilot CLI (background agent): worktree isolation (auto-commit per turn, Bypass Approvals); workspace isolation; /yolo /autoApprove /compact /delegate; local unauthenticated MCP only | 2026-04-05 | copilot-cli, background, worktree, isolation |
| <https://code.visualstudio.com/docs/copilot/agents/cloud-agents> | Cloud agents: run remotely; integrate with GitHub PRs; can't access VS Code built-in tools or run-time context (test failures, selections); limited to local unauthenticated MCP | 2026-04-05 | cloud-agents, github-pr, constraints |
| <https://code.visualstudio.com/docs/copilot/concepts/customization> | Customisation hierarchy: always-on instructions → file-based instructions → prompt files → skills → custom agents → MCP → hooks → plugins; incrementally additive | 2026-04-05 | customisation, hierarchy, overview |
| <https://code.visualstudio.com/docs/copilot/customization/overview> | Customisation overview; Chat Customisations editor; parent-repository discovery (`chat.useCustomizationsInParentRepositories`); /init, /create-prompt, /create-agent, /create-hook slash commands | 2026-04-05 | customisation, monorepo, parent-discovery |

## GitHub Copilot Cloud Agent — Custom Agents and Session Management (2026-04)

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/manage-agents> | Cloud agent 5-step lifecycle: start, monitor, steer (steering=1 premium req), "Open in VS Code", review+merge PR; session archive; available on Pro/Pro+/Business/Enterprise | 2026-04-05 | cloud-agent, lifecycle, steering |
| <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents> | Custom agent profiles: repo-level (.github/agents/), org/enterprise-level (/agents/); frontmatter: name, description, tools, mcp-servers; works across GitHub.com + VS Code + JetBrains + Eclipse + Xcode | 2026-04-05 | custom-agents, profiles, multi-platform |
| <https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-custom-agents> | Custom agent concepts: tailored teammates; define once vs repeat in every prompt; profile = Markdown + YAML frontmatter; scope: repo / org / enterprise | 2026-04-05 | custom-agents, concepts, scope |

## MCP Specification — Lifecycle, Ping, Cancellation, Transports (2026-04)

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://modelcontextprotocol.io/specification/2025-03-26/basic/lifecycle> | MCP session lifecycle: Initialization (capability negotiation, version) → Operation → Shutdown; 3 error cases: version mismatch, capability failure, timeout; SIGTERM/SIGKILL shutdown for stdio | 2026-04-05 | mcp, lifecycle, error-handling |
| <https://modelcontextprotocol.io/specification/2025-03-26/basic/utilities/ping> | MCP ping: liveness check via request/response; timeout → stale → terminate or reconnect; multiple failures MAY trigger connection reset; frequency should be configurable | 2026-04-05 | mcp, ping, liveness, recovery |
| <https://modelcontextprotocol.io/specification/2025-03-26/basic/utilities/cancellation> | MCP cancellation: `notifications/cancelled` with requestId + reason; fire-and-forget; race conditions must be handled gracefully; log cancellation reasons for diagnostics | 2026-04-05 | mcp, cancellation, recovery |
| <https://modelcontextprotocol.io/docs/concepts/transports> | MCP transports: stdio (subprocess stdin/stdout, newline delimited) and Streamable HTTP/SSE; session management via Mcp-Session-Id header; resumability via Last-Event-ID; DNS rebinding protection required | 2026-04-05 | mcp, transports, stdio, security |

## App Configuration Principles

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://12factor.net/config> | 12-factor III: store config in env vars; strict separation of config from code; named-environment groups (dev/staging/prod) do not scale; prefer granular orthogonal vars per deploy | 2026-04-05 | config, 12-factor, env-vars, best-practices |

## Sisyphus/OpenClaw Ecosystem — Autonomous Coding Agent Coordination

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://github.com/Yeachan-Heo/clawhip> | clawhip — daemon-first Discord notification router with typed session.* event pipeline, renderer/sink separation, filesystem memory scaffold (MEMORY.md + shards), plugin bridge architecture | 2026-04-05 | agents, events, notifications, orchestration |
| <https://github.com/Yeachan-Heo/clawhip/blob/main/ARCHITECTURE.md> | clawhip v0.4.0 architecture: MPSC queue, Source→Dispatcher→Router→Renderer→Sink, multi-delivery (0..N routes per event), best-effort delivery semantics | 2026-04-05 | agents, architecture, events |
| <https://raw.githubusercontent.com/Yeachan-Heo/clawhip/main/docs/native-event-contract.md> | clawhip canonical session.* event vocabulary: 10 canonical names (session.started/blocked/finished/failed/retry-needed/pr-created/test-started/test-finished/test-failed/handoff-needed); normalization contract for OMC/OMX upstream events | 2026-04-05 | agents, events, vocabulary, hooks |
| <https://github.com/code-yeongyu/oh-my-openagent> | oh-my-openagent (OmO) — multi-model orchestration harness; Sisyphus orchestrator; IntentGate (intent analysis before action); 19 specialist agents; hash-anchored edit tool; skill-embedded MCPs; Ralph persistence loop; TodoEnforcer | 2026-04-05 | agents, orchestration, multi-model, skills |
| <https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/refs/heads/dev/docs/guide/installation.md> | OmO installation guide — per-agent model resolution via subscription flags; doctor verification step; provider-specific fallback chains | 2026-04-05 | agents, installation, verification |
| <https://github.com/Yeachan-Heo/oh-my-claudecode> | oh-my-claudecode (OMC) — Claude Code multi-agent plugin; staged pipeline (team-plan→team-prd→team-exec→team-verify→team-fix); 29 agents, 32 skills; project-scoped skills with trigger keywords; stop callbacks to Telegram/Discord/Slack; OpenClaw gateway integration | 2026-04-05 | agents, orchestration, claude-code, skills, hooks |
| <https://raw.githubusercontent.com/Yeachan-Heo/oh-my-claudecode/main/docs/REFERENCE.md> | OMC full reference — hooks system, skills scoping (.omc/skills/ project vs ~/.omc/skills/ user), env vars (DISABLE_OMC, OMC_SKIP_HOOKS, OMC_STATE_DIR), stop callback config | 2026-04-05 | agents, reference, skills, hooks |
| <https://github.com/Yeachan-Heo/oh-my-codex> | oh-my-codex (OMX) — workflow layer for OpenAI Codex CLI; $deep-interview (Socratic clarification), $ralplan (plan approval gate), $ralph (persistence loop), $team (parallel execution); .omx/ state dir convention | 2026-04-05 | agents, orchestration, codex, workflow |

## VS Code Copilot — Agent Memory Systems (2026-04)

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://code.visualstudio.com/docs/copilot/agents/memory> | VS Code memory tool — three scopes (user/repo/session); first 200 user-scope lines auto-loaded; repo/session must be explicitly read; Copilot Memory (GitHub-hosted, 28-day TTL, citation-verified) is separate; local memory tool vs Copilot Memory comparison table | 2026-04-05 | memory, scopes, built-in, copilot-memory |
| <https://github.blog/ai-and-ml/github-copilot/building-an-agentic-memory-system-for-github-copilot/> | GitHub Memory design blog — citation-anchored facts (source file:line references); just-in-time verification at read time rather than offline curation; 28-day TTL; cross-agent (code review ↔ coding agent); privacy: repo-scoped, write-access required | 2026-04-05 | memory, citations, verification, github-copilot-memory |

## Agent Catalogs And Patterns (2026-04)

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://docs.anthropic.com/en/docs/claude-code/sub-agents> | Claude Code sub-agents — frontmatter fields, isolation, effort, memory, background execution, per-invocation overrides, and subagent workflow design | 2026-04-05 | agents, subagents, claude-code, routing |
| <https://docs.anthropic.com/en/docs/claude-code/agent-teams> | Claude Code teams versus subagents — when to use peer collaboration, when to use focused return-result specialists, and how to compose them | 2026-04-05 | agents, teams, subagents, orchestration |
| <https://www.anthropic.com/engineering/building-effective-agents> | Anthropic engineering guidance — keep workflows simple, add agentic orchestration only when needed, and prefer the right system over the biggest catalog | 2026-04-05 | agents, orchestration, minimalism, design |
| <https://awesome-copilot.github.com/llms.txt> | awesome-copilot community catalog — broad marketplace of optional agents, useful for identifying common archetypes and which specialists are better kept opt-in | 2026-04-05 | agents, marketplace, catalog, optional |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/agents/gem-orchestrator.agent.md> | Gem Orchestrator agent — multi-specialist orchestration example with explicit handoff and keyword routing patterns | 2026-04-05 | agents, orchestrator, routing, community |
| <https://openai.github.io/openai-agents-python/multi_agent/> | OpenAI Agents SDK multi-agent patterns — agents-as-tools, handoffs, and orchestration tradeoffs that support lean core catalogs with specialist depth | 2026-04-05 | agents, multi-agent, handoffs, architecture |

## MemPalace AI Memory System (2026-04)

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://github.com/milla-jovovich/mempalace> | MemPalace v3.0.0 — method-of-loci AI memory system; ChromaDB + SQLite; 19 MCP tools; 4-layer memory stack (L0-L3); 96.6% LongMemEval R@5 in raw mode; MIT licence | 2026-04-09 | memory, mcp, chromadb, ai-memory |
| <https://github.com/milla-jovovich/mempalace/issues/27> | lhl's claims-vs-code audit: contradiction detection non-existent, AAAK lossy not lossless (12.4pp regression), 96.6% is ChromaDB baseline not palace structure, +34% is metadata filtering | 2026-04-09 | memory, audit, benchmarks, claims |
| <https://github.com/milla-jovovich/mempalace/issues/39> | gizmax M2 Ultra independent reproduction: raw 96.6% confirmed in 4:37; aaak 84.2%; rooms 89.4%; benchmark runner never touches palace wings/rooms code path; ~810 token real wake-up cost | 2026-04-09 | memory, benchmarks, reproduction |
| <https://github.com/milla-jovovich/mempalace/issues/74> | macOS ARM64 segfault after ~8,400 drawers — null pointer in chromadb_rust_bindings.abi3.so; workaround: wipe and re-mine smaller batches | 2026-04-09 | memory, bug, arm64, chromadb |
| <https://github.com/milla-jovovich/mempalace/issues/100> | Unpinned ChromaDB dependency — pip pulls chromadb 1.5.6 which segfaults; fix: chromadb>=0.6,<1; authors committed to pinning | 2026-04-09 | memory, dependency, chromadb, packaging |
| <https://github.com/milla-jovovich/mempalace/issues/110> | Shell injection in hook scripts — fixed in current code (SESSION_ID sanitised via tr, TRANSCRIPT_PATH passed as argument not interpolated) | 2026-04-09 | memory, security, shell, hooks |
| <https://penfieldlabs.substack.com/p/milla-jovovich-just-released-an-ai> | Penfield Labs deep analysis: LoCoMo 100% via top-k=50 bypasses retrieval entirely; LongMemEval score is recall_any@5 on labels not QA; hybrid 100% patches 3 test-specific cases; benchmark wars context (Zep vs Mem0) | 2026-04-09 | memory, analysis, benchmarks, critique |
| <https://github.com/lhl/agentic-memory/blob/main/ANALYSIS-mempalace.md> | lhl agentic-memory survey: NOT PROMOTED (only system with provably non-existent README features); spatial metaphor genuinely novel; wake-up cost best in survey; zero-LLM write path; deterministic chunking | 2026-04-09 | memory, survey, analysis, architecture |
| <https://news.ycombinator.com/item?id=47672792> | Main HN thread (59 pts, 12 comments) — community mostly critical of benchmarks; consensus: real product under inflated marketing | 2026-04-09 | memory, community, hn |

## Prompt Compression and Token Efficiency

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://arxiv.org/abs/2310.05736> | LLMLingua (EMNLP 2023, Microsoft): coarse-to-fine perplexity-based prompt compression; up to 20x compression with little performance loss; budget controller + token-level iteration | 2026-04-09 | compression, llmlingua, microsoft |
| <https://arxiv.org/abs/2403.12968> | LLMLingua-2 (ACL Findings 2024, Microsoft): BERT-based bidirectional token classification; 3x-6x faster than LLMLingua; 2x-5x compression ratio; task-agnostic | 2026-04-09 | compression, llmlingua, microsoft |
| <https://github.com/microsoft/LLMLingua> | LLMLingua GitHub repo: all 3 variants, integrations with LangChain/LlamaIndex/PromptFlow; demo on HuggingFace | 2026-04-09 | compression, llmlingua, tools |
| <https://llmlingua.com/> | LLMLingua project page: benchmarks, case studies for RAG, meetings, CoT, code; SCBench KV-cache analysis | 2026-04-09 | compression, llmlingua, benchmarks |
| <https://arxiv.org/abs/2310.06201> | Selective Context (Li et al., EMNLP 2023): 50% context reduction via self-information pruning; 36% memory reduction, 32% inference time reduction; 0.023 BERTscore drop only | 2026-04-09 | compression, selective-context |
| <https://arxiv.org/abs/2310.04408> | RECOMP (Xu et al., 2023): extractive + abstractive document compressors for RAG; 6% compression rate with minimal QA performance loss | 2026-04-09 | compression, recomp, rag |
| <https://arxiv.org/abs/2305.14788> | AutoCompressor (Chevalier et al., EMNLP 2023): fine-tunes LLMs to compress long context into soft-prompt summary vectors; 30,720-token contexts; requires model fine-tuning | 2026-04-09 | compression, autocompressor, soft-prompts |
| <https://aclanthology.org/2025.naacl-long.376/> | GenPI / Generative Prompt Internalization (KAIST, NAACL 2025): fine-tunes a model to internalise system prompts, eliminating them at inference; data synthesis via role-swapping | 2026-04-09 | compression, fine-tuning, genpi |
| <https://arxiv.org/abs/2307.03172> | "Lost in the Middle" (Liu et al., Stanford/Berkeley, TACL 2023): LLM recall worst in middle of long context; best at beginning and end; applies to instruction ordering | 2026-04-09 | context-window, position-bias, attention |
| <https://arxiv.org/abs/2602.05447> | Structured Context Engineering for File-Native Agentic Systems (McMillan 2026): 9,649 experiments; YAML > TOON despite TOON being 25% smaller — "grep tax" 138-740% at scale; format familiarity >> raw token efficiency | 2026-04-09 | format, yaml, toon, context-engineering |
| <https://simonwillison.net/2026/Feb/9/structured-context-engineering-for-file-native-agentic-systems/> | Simon Willison commentary on McMillan 2026 format study; explains the "grep tax" figure | 2026-04-09 | format, context-engineering, grep-tax |
| <https://github.com/open-compress/claw-compactor> | Claw Compactor (2026): 14-stage deterministic Fusion Pipeline; 15-82% compression; zero LLM cost; reversible; AST-aware; JSON 82%, agent conversations 31%, Python 25% | 2026-04-09 | compression, tools, deterministic |
| <https://github.com/sriinnu/clipforge-PAKT> | ClipForge PAKT (2026): lossless-first TypeScript compression library; structured payloads 27-33%, repetitive text 38-69%, logs 57%; includes MCP server + npm package | 2026-04-09 | compression, tools, typescript, lossless |
| <https://github.com/gladehq/claude-shorthand> | Claude-shorthand (2026): LLMLingua-2 Claude Code plugin; ~55% compression on prompts >800 chars; protects code identifiers; configurable rate + protected tokens | 2026-04-09 | compression, tools, claude-code |
| <https://github.com/topics/prompt-compression> | GitHub topic: 32 repos as of April 2026; claw-compactor, claude-shorthand, PAKT, contextcrunch among notable entries | 2026-04-09 | compression, tools, ecosystem |
| <https://www.anthropic.com/news/prompt-caching> | Anthropic prompt caching (GA August 2025): cache reads 10% of base input cost; 90% cost reduction, 85% latency reduction for repeated 100K-token prompts | 2026-04-09 | caching, cost-reduction, anthropic |
| <https://simonwillison.net/2026/Feb/20/thariq-shihipar/> | Thariq Shihipar (Claude Code): "We build our entire harness around prompt caching. We run alerts on prompt cache hit rate and declare SEVs if they're too low." | 2026-04-09 | caching, claude-code, production |
| <https://simonwillison.net/2025/Jun/27/context-engineering/> | Simon Willison on context engineering (June 2025); Karpathy quote: "filling context window with just the right information... compacting is a key component" | 2026-04-09 | context-engineering, karpathy |
| <https://www.anthropic.com/research/building-effective-agents> | Anthropic — Building Effective Agents: simplest solution first, routing for instruction specialist selection, workflows vs agents taxonomy | 2026-04-09 | agents, routing, patterns |

## VS Code MCP Sandbox Runtime — Write Failures and Proxy Errors (2026-04-10)

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| `local:/opt/visual-studio-code-insiders/resources/app/node_modules/@anthropic-ai/sandbox-runtime@0.0.42/dist/sandbox/sandbox-utils.js` | `getDefaultWritePaths()` includes `/tmp/claude`; `generateProxyEnvVars()` sets `TMPDIR=/tmp/claude` (or `CLAUDE_TMPDIR`) and `ALL_PROXY=socks5h://localhost:<socksPort>` inside bwrap | 2026-04-10 | mcp, sandbox, proxy, tmpdir |
| `local:/opt/visual-studio-code-insiders/resources/app/node_modules/@anthropic-ai/sandbox-runtime@0.0.42/dist/sandbox/linux-sandbox-utils.js` | `generateFilesystemArgs()` silently skips any `allowWrite` path that does not exist on the host (`!fs.existsSync(normalizedPath)` guard) — root cause of `/tmp/claude` write failures | 2026-04-10 | mcp, sandbox, bwrap, write-failure |
| `local:/opt/visual-studio-code-insiders/resources/app/node_modules/@anthropic-ai/sandbox-runtime@0.0.42/dist/sandbox/sandbox-manager.js` | `wrapWithSandbox()` always prepends `getDefaultWritePaths()` to user `allowWrite`; `wrapCommandWithSandboxLinux()` injects proxy env vars via `--setenv` | 2026-04-10 | mcp, sandbox, allowwrite |
| `local:~/.cache/uv/archive-v0/e69PtoFU3_LyN99J0jBF9/httpx/_config.py` | `httpx 0.27.2 Proxy.__init__` only accepts `http/https/socks5` schemes — `socks5h://` raises `ValueError: Unknown scheme for proxy URL` | 2026-04-10 | httpx, proxy, socks5h |
| `local:~/.cache/uv/archive-v0/CTC1-HivFdy4UVtKcUEhy/httpx/_config.py` | `httpx 0.28.1` adds `socks5h` to the accepted scheme set — upgrade unblocks proxy | 2026-04-10 | httpx, proxy, socks5h, fix |
| `local:~/.cache/uv/archive-v0/pO-kgK6IlruyghP-SK_wY/mcp_server_fetch-2025.4.7.dist-info/METADATA` | `mcp-server-fetch@2025.4.7` pins `httpx<0.28` — prevents the socks5h fix from being used | 2026-04-10 | mcp-server-fetch, httpx, dependency |

## Test Execution Optimization — 2026-04-12

| URL | Summary | Date | Tags |
|-----|---------|------|------|
| <https://devblogs.microsoft.com/devops/accelerated-continuous-testing-with-test-impact-analysis-part-1/> | Microsoft TIA in Azure DevOps: auto test selection via instrumentation; apply when full run >15min; runs impacted + failing + new tests | 2026-04-12 | tia, ci, testing |
| <https://engineering.fb.com/2018/11/21/developer-tools/predictive-test-selection/> | Meta predictive test selection: gradient-boosted DT model; catches >99.9% of regressions; runs only 1/3 of impacted tests; doubles infra efficiency | 2026-04-12 | tia, ml, testing |
| <https://engineering.fb.com/2026/02/11/developer-tools/the-death-of-traditional-testing-agentic-development-jit-testing-revival/> | Meta JiTTesting (Feb 2026): LLM-generated tests on-the-fly for each code change; no maintenance; uses mutation testing; designed for agentic dev | 2026-04-12 | ai-agents, testing, jit |
| <https://abseil.io/resources/swe-book/html/ch23.html> | Google SWE Book Ch.23 CI: TAP handles 50K changes/day, 4B tests/day; avg presubmit wait 11min; hermetic presubmit cut Google Assistant runtime 14x | 2026-04-12 | ci, tap, google, testing |
| <https://martinfowler.com/articles/practical-test-pyramid.html> | Fowler test pyramid: many unit, some integration, few E2E; push tests down; every test is "additional baggage"; avoid ice cream cone | 2026-04-12 | testing, pyramid, strategy |
| <https://www.nngroup.com/articles/response-times-3-important-limits/> | Nielsen 10-second rule: 0.1s=direct, 1s=flow, 10s=attention limit; basis for test feedback timing thresholds | 2026-04-12 | ux, timing, flow-state |
| <https://testmon.org/> | pytest-testmon: Coverage.py-based incremental test selection; pip install pytest-testmon; works with pytest-watch | 2026-04-12 | python, tia, testing, incremental |
| <https://github.com/tarpas/pytest-testmon> | pytest-testmon source: 965 stars; v2.2.0 Dec 2025; Python 3.10+; MIT | 2026-04-12 | python, tia, testing |
| <https://aider.chat/docs/usage/lint-test.html> | Aider --auto-test + --test-cmd: runs tests after each AI edit; agent self-repairs on failure; per-file --no-auto-lint to disable | 2026-04-12 | ai-agents, aider, testing |
| <https://www.swebench.com/> | SWE-bench official leaderboard: current SOTA Claude 4.5 Opus 76.8% Verified; mini-SWE-agent 65% in 100 lines Python | 2026-04-12 | ai-agents, benchmark, swe-bench |
| <https://arxiv.org/abs/2310.06770> | SWE-bench paper (ICLR 2024): 2294 GitHub issues in 12 Python repos; original Claude 2 scored 1.96%; test execution central to agent success | 2026-04-12 | ai-agents, benchmark, swe-bench |
| <https://arxiv.org/pdf/2601.22832> | Meta JiTTesting paper: "Just-in-Time Catching Test Generation at Meta"; mutation-based LLM test generation for regressions | 2026-04-12 | ai-agents, testing, jit, paper |
