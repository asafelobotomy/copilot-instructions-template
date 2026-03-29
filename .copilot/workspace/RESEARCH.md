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
| <https://code.visualstudio.com/docs/copilot/reference/copilot-settings> | Complete chat.* and github.copilot.* settings reference; plugin/MCP settings | 2026-03-29 | settings, audit, reference |
| <https://agentskills.io/specification> | Agent Skills spec — name/description constraints, allowed-tools, token budget (~100 tokens metadata, <5000 body) | 2026-03-29 | skills, validation, spec |
| <https://raw.githubusercontent.com/agentskills/agentskills/main/skills-ref/README.md> | skills-ref CLI — validate, read-properties, to-prompt commands; Python API; marked "demo only" | 2026-03-29 | skills, validation, cli |
| <https://github.com/openai/tiktoken> | tiktoken BPE tokeniser; cl100k_base is best offline proxy for Claude token counts (±10%) | 2026-03-29 | tokens, estimation, python |
| <https://github.com/koalaman/shellcheck> | ShellCheck — bash/sh static analysis; -f json for machine output; exits non-zero on violations | 2026-03-29 | bash, lint, audit |
