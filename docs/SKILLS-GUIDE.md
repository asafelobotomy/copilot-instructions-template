# Skills Guide — Human Reference

> **Machine-readable version**: §12 of `.github/copilot-instructions.md`
> This document explains what Agent Skills are, how they work, and how to use them.

---

## What are Agent Skills?

Agent Skills are reusable, markdown-based **behavioural instructions** that teach your AI coding agent *how* to perform specific workflows. They follow the [Agent Skills](https://agentskills.io) open standard — an open specification maintained by Anthropic and adopted by GitHub Copilot, OpenAI Codex, and Claude Code.

Think of skills as playbooks: step-by-step guides that the agent reads and follows when a matching task comes up. Unlike tools (which are executable scripts), skills are declarative — they shape the agent's approach rather than running code.

---

## Where do skills live?

Skills are stored in directories containing a `SKILL.md` file:

| Location | Scope | Priority |
|----------|-------|----------|
| `.github/skills/<name>/SKILL.md` | Project-specific — checked into version control | Highest |
| `~/.copilot/skills/<name>/SKILL.md` | Personal — shared across all your projects | Lower |
| Agent plugins (`@agentPlugins`) | Distributed alongside agents (VS Code 1.110+) | Lowest |

Project skills always override personal and plugin skills with the same name.

---

## How discovery works

Skills are loaded **on demand** — the agent doesn't pre-load all skills. When you ask the agent to perform a task, it:

1. **Scans** descriptions in `.github/skills/*/SKILL.md` for a match
2. **Searches** online repositories (if enabled — see [Skill search preference](#skill-search-preference))
3. **Creates** a new skill from scratch if nothing matches

This keeps context efficient — only relevant skills consume the agent's context window.

---

## Starter skills

Thirteen skills are scaffolded into your project during setup:

| Skill | What it does | Trigger examples |
|-------|-------------|------------------|
| `skill-creator` | Meta-skill — teaches the agent how to author new skills | "Create a skill", "Write a skill for..." |
| `fix-ci-failure` | Diagnose and fix failing CI pipelines / GitHub Actions | "Fix CI", "Why is the pipeline red?" |
| `lean-pr-review` | Review a PR using Lean waste categories and severity ratings | "Review this PR", "Check my changes" |
| `conventional-commit` | Write commit messages following Conventional Commits | "Write a commit message" |
| `mcp-builder` | Build and register MCP servers for external tool integration | "Build an MCP server", "Add an MCP server for..." |
| `webapp-testing` | Set up browser testing — built-in browser tools (interactive) or Playwright (CI) | "Set up e2e tests", "Add browser tests", "Check my web app" |
| `issue-triage` | Triage a GitHub issue with severity, waste category, and recommended action | "Triage this issue", "Classify this bug" |
| `tool-protocol` | Follow the Tool Protocol decision tree to find, build, or adapt automation tools | "Build a tool for...", "Show me the toolbox" |
| `skill-management` | Discover, activate, and manage agent skills following the Skill Protocol | "Show my skills", "Search for a skill that..." |
| `mcp-management` | Configure and manage MCP servers for external tool access | "Configure MCP", "Add an MCP server for..." |
| `plugin-management` | Discover, evaluate, install, test, and manage agent plugins for VS Code Copilot | "Show plugins", "Find a plugin for..." |
| `extension-review` | Audit VS Code extensions against the detected project stack | "Review extensions", "Check my extensions" |
| `test-coverage-review` | Audit test coverage, recommend local tests, and suggest CI workflows | "Review my tests", "Check test coverage" |

---

## Skill anatomy

Every skill is a `SKILL.md` file with a small YAML frontmatter block that sticks to the keys VS Code currently validates, followed by the richer metadata in the body:

```markdown
---
name: fix-ci-failure
description: Diagnose and fix a failing CI pipeline or GitHub Actions workflow
---

# Fix CI Failure

> Skill metadata: version "1.0"; license MIT; tags [ci, github-actions, debugging]; compatibility ">=3.0"; recommended tools [codebase, editFiles, runCommands].

<step-by-step workflow instructions>
```

- **`name`** (required) — kebab-case identifier; matches the directory name
- **`description`** (required) — one-sentence summary; this is how the agent *discovers* the skill
- **`Skill metadata` note** — body-level note that preserves versioning, compatibility, tool-scope, and discovery tags without triggering frontmatter schema warnings

The body contains numbered steps with clear action verbs, ending with a "Verify" section.

---

## Skill search preference

During setup, you're asked (question A15) how the agent should handle missing skills:

| Setting | Behaviour |
|---------|-----------|
| **Local only** (default) | Only use skills in `.github/skills/`. Create new ones from scratch. No online searching. |
| **Official repositories only** | Search official sources (anthropics/skills, openai/skills, github/awesome-copilot) for proven workflows. Adapt and save locally. |
| **Official + community** | Search official repos first, then community sources. Community skills are quality-checked before adoption. |

This setting is stored in §10 as `{{SKILL_SEARCH_PREFERENCE}}` and can be changed at any time.

---

## Creating a new skill

Say any of these to the agent:

- *"Create a skill for..."*
- *"Write a skill that..."*
- *"Add a new skill for..."*

The `skill-creator` meta-skill guides the agent through the process. The result is a new `SKILL.md` file in `.github/skills/<name>/`.

Alternatively, use the **`/create-skill` slash command** (VS Code 1.110+) to scaffold a new skill from VS Code's built-in template. The built-in command generates the basic structure; the `skill-creator` skill adds Lean/Kaizen guidance (waste-aware naming, PDCA verification, quality gate checks).

### Manual creation

Create a directory under `.github/skills/` with a `SKILL.md` file following the [anatomy](#skill-anatomy) above. The key rules:

1. **One skill, one workflow** — if you need "and", split it
2. **Description is the index** — write precisely; this is how the agent finds it
3. **Steps, not prose** — use numbered steps with clear action verbs
4. **No hardcoded paths** — use relative references
5. **Idempotent** — running twice produces the same result
6. **End with Verify** — include a checklist confirming correct completion

---

## Skills vs. Tools

| Aspect | Skill (§12) | Tool (§11) |
|--------|------------|------------|
| Format | Markdown (`SKILL.md`) | Executable script (`.sh`, `.py`, `.js`) |
| Purpose | Teach *how* to approach a workflow | Automate a specific *action* |
| Invocation | Agent reads and follows instructions | Agent executes the script |
| Location | `.github/skills/` | `.copilot/tools/` |
| Composable | Skills can reference tools | Tools don't reference skills |

Use a skill when you want to codify a **process** (multi-step workflow with decisions). Use a tool when you want to automate an **action** (single command or script).

---

## Community skill ecosystem

The Agent Skills open standard has a growing ecosystem:

| Repository | Description |
|-----------|-------------|
| [anthropics/skills](https://github.com/anthropics/skills) | Official Anthropic skills collection |
| [github/awesome-copilot](https://github.com/github/awesome-copilot) | GitHub's community skills collection |
| [openai/skills](https://github.com/openai/skills) | OpenAI skills collection |
| [agentskills.io](https://agentskills.io) | The open standard specification |

Community skills are only searched if you've opted in via the A15 preference.

---

## Built-in skills (VS Code 1.110+)

VS Code ships a built-in **accessibility skill** that teaches the agent to write accessible code (ARIA attributes, semantic HTML, keyboard navigation, colour contrast). This skill is always available — it does not need to be installed or configured.

Built-in skills do not appear in `.github/skills/` — they are part of VS Code itself. They complement project skills: built-in skills provide general best practices, project skills provide project-specific workflows.

---

## Quality gate for community skills

Before adopting a community-sourced skill, the agent verifies:

- Repository has ≥ 50 stars or is from a recognised organisation
- `SKILL.md` has both `name` and `description` in frontmatter
- Instructions are clear, specific, and non-destructive
- No embedded credentials, tokens, or suspicious URLs
- License is permissive (MIT, Apache 2.0, CC-BY)

Skills failing two or more checks are rejected. Borderline cases are presented to you for manual review.

---

## Trigger phrases

| Action | What to say |
|--------|------------|
| Create a skill | *"Create a skill"* / *"Write a skill for..."* |
| List skills | *"Show my skills"* / *"List available skills"* |
| Search for a skill | *"Search for a skill that..."* / *"Find a skill for..."* |

---

## Updating the instructions

The skills system is part of §12 in `.github/copilot-instructions.md`. When you update from a newer template version, §12 may receive improvements. Your local skills (in `.github/skills/`) are never overwritten by template updates — they belong to your project.

---

## Agent plugins and skill distribution (VS Code 1.110+ — experimental)

Agent plugins are a new distribution mechanism that bundles skills alongside agents, hooks, and MCP servers into installable packages. Plugins are discovered via the Extensions view (`@agentPlugins` filter).

**How this affects skills**:

- Skills bundled in agent plugins are automatically available — no manual copying to `.github/skills/`
- Plugin skills use the same `SKILL.md` format and are discovered via the same description-matching mechanism
- Project-level skills (`.github/skills/`) always take priority over plugin skills with the same name

**Skill search with plugins**: When `{{SKILL_SEARCH_PREFERENCE}}` is set to "Official + community", the agent now also considers skills from installed agent plugins as a discovery source, alongside the official repositories and community sources.
