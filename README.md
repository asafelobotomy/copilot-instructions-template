<div align="center">

# copilot-instructions-template

**Instruction firmware for AI-assisted development — grounded in Lean / Kaizen**

[![CI](https://github.com/asafelobotomy/copilot-instructions-template/actions/workflows/ci.yml/badge.svg)](https://github.com/asafelobotomy/copilot-instructions-template/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-3.0.0-blue)](VERSION.md)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/asafelobotomy/copilot-instructions-template/badge)](https://scorecard.dev/viewer/?uri=github.com/asafelobotomy/copilot-instructions-template)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![VS Code](https://img.shields.io/badge/VS_Code-1.106+-007ACC?logo=visualstudiocode)](https://code.visualstudio.com/)

</div>

---

## Contents

- [What is this?](#what-is-this)
- [Quickstart](#quickstart)
- [Setup tiers](#setup-tiers)
- [Key features](#key-features)
- [What gets scaffolded](#what-gets-scaffolded-into-your-project)
- [Human-readable guides](#human-readable-guides)
- [Repository layout](#repository-layout)
- [Philosophy](#philosophy)
- [Reference implementation](#reference-implementation)
- [Contributing](#contributing)
- [License](#license)

---

## What is this?

A **generic, customisable, living** GitHub Copilot instructions template. Drop it into any project — new or existing — and Copilot runs a structured one-time setup to tailor everything to your stack, team conventions, and preferences. From that point on, the instructions evolve with the project through a disciplined **Lean / Kaizen** loop.

This is not a linter config or a style guide. It is **instruction firmware** — a shared mental model between you and your AI coding agent about *how work should be done*.

---

## Quickstart

Open a Copilot chat in **any project** and say:

```text
Setup from asafelobotomy/copilot-instructions-template
```

Copilot fetches the template and setup guide directly from GitHub, interviews you with **5–24 questions** (your choice of depth), fills every placeholder, scaffolds your workspace files, captures a Kaizen baseline, and self-destructs the setup script. **No cloning, no copying, no manual steps.**

> **⚠️ Use the Setup agent or an interactive model.** Codex models (`GPT-5.x-Codex`) run autonomously and cannot present interactive prompts — the preference interview will be silently skipped. Select **Claude Sonnet 4.6** (or any interactive model) in the Copilot picker, or use the `@setup` agent which pins the correct model automatically.

<!-- -->

> **Prefer to do it manually?** Copy `.github/copilot-instructions.md` and `SETUP.md` into your project, then tell Copilot: *"Please run the setup process described in SETUP.md."*
>
> **Starting fresh?** Click **Use this template** on GitHub, then run the quickstart above in your new repo.

---

## Setup tiers

At the start of setup, choose how deep the interview goes:

| Tier | Questions | Time | What gets answered |
|------|-----------|------|--------------------|
| **Quick** | 5 | ~3 min | Core workflow: response style, experience, primary mode, testing, autonomy |
| **Standard** | 17 | ~6 min | Quick + code style, docs, errors, security, dependencies, lifecycle hooks, slash commands, and more |
| **Full** | 24 | ~10 min | Standard + agent persona, VS Code settings, autonomy ceiling, MCP servers, and more |

Questions you skip always get a sensible default. Every preference is written into §10 of your instructions file and can be changed at any time.

---

## Key features

### ⚙️ Thirteen-section instructions architecture

`.github/copilot-instructions.md` ships with thirteen named sections (§1–§13) covering identity, workflow mode, safety gates, coding conventions, the PDCA cycle, waste cataloguing, self-editing protocol, test/extension review, project-specific overrides, a reusable tool library, a skill-based workflow system, and Model Context Protocol (MCP) integration. Every section is placeholder-driven — nothing is hardcoded to a particular stack.

### 🤖 Four model-pinned agents

`.github/agents/` contains four VS Code agent files (requires VS Code 1.106+), each pinned to the model best suited for its role:

| Agent | Model | Role |
|-------|-------|------|
| `setup.agent.md` | Claude Sonnet 4.6 | Onboarding, template ops, preference interview (batched with verification gate) |
| `coding.agent.md` | GPT-5.3-Codex | Implementation, refactoring, test writing |
| `review.agent.md` | Claude Opus 4.6 | Architectural review, Lean waste audit |
| `fast.agent.md` | Claude Haiku 4.5 | Quick lookups, explanations, small edits |

### 📚 Agent Skills library

Six starter skills are scaffolded into `.github/skills/` during setup, following the [Agent Skills](https://agentskills.io) open standard. Skills are markdown-based behavioural instructions that teach the agent *how* to perform specific workflows — from authoring new skills to building MCP servers. Optionally search official and community skill repositories for proven workflows.

### 📂 Path-specific instructions

`.github/instructions/` contains context-aware instruction files with `applyTo:` glob patterns. When Copilot edits a file matching a pattern (e.g., test files, API routes, config files, documentation), the corresponding instructions are loaded alongside the main file. Four starter stubs are scaffolded during setup.

### 💬 Reusable prompt files (slash commands)

`.github/prompts/` contains five starter prompt files that become VS Code slash commands (`/explain`, `/refactor`, `/test-gen`, `/review-file`, `/commit-msg`). Each encapsulates a workflow grounded in the template's Lean methodology — waste-aware explanation, PDCA-driven refactoring, convention-following test generation, structured file review, and Conventional Commits.

### 🔒 Security hardening

All GitHub Actions are SHA-pinned to immutable commit hashes and protected with `step-security/harden-runner` for network egress monitoring. An OpenSSF Scorecard workflow runs weekly, uploading SARIF results to GitHub code scanning. A Graduated Trust Model in §10 assigns verification tiers (High / Standard / Guarded) to file paths, controlling how aggressively the agent seeks confirmation before making changes.

### 🔌 Model Context Protocol (MCP) integration

§13 governs how Copilot connects to external tools via MCP. During **Full** setup, Copilot scaffolds `.vscode/mcp.json` with three tiers of servers: always-on (filesystem, memory, git), credentials-required (GitHub, fetch), and stack-specific (PostgreSQL, Redis, Docker, AWS — auto-suggested from your dependencies). A quality gate ensures only verified, maintained servers are added.

### 🔄 Living update protocol

The template ships versioned. When a new version is released, say *"Update your instructions"* — this tells Copilot to check [`asafelobotomy/copilot-instructions-template`](https://github.com/asafelobotomy/copilot-instructions-template) for a newer release. Copilot will fetch the diff, present a section-by-section change manifest, let you apply / skip / customise each change, back up the current file, write the updates, and record everything in `JOURNAL.md` and `CHANGELOG.md`. The update is always reversible.

### 💓 Event-driven heartbeat

Copilot automatically runs health checks at natural breakpoints — session start, large refactors, dependency updates, and CI resolutions. The heartbeat reads `.copilot/workspace/HEARTBEAT.md`, checks dependency freshness, test coverage deltas, accumulated waste, memory consolidation, and settings drift. Alerts are reported only when something needs attention; healthy heartbeats are silent. The checklist is agent-writable — Copilot adds custom checks as it learns your project.

### 🏗️ Workspace identity system

Seven workspace files are scaffolded into your project during setup and maintained across sessions:

| File | Purpose |
|------|---------|
| `IDENTITY.md` | Agent self-description and project context |
| `SOUL.md` | Values, reasoning patterns, and tone |
| `USER.md` | Your preferences, background, and working style |
| `TOOLS.md` | Tool usage patterns and VS Code extension registry |
| `MEMORY.md` | Session continuity and memory strategy |
| `BOOTSTRAP.md` | Permanent setup origin record |
| `HEARTBEAT.md` | Event-driven health check checklist |

### 📊 Kaizen baseline and metrics

At setup completion Copilot captures a baseline snapshot (file count, LOC, dependency count, test coverage) into `METRICS.md`. Every significant change appends a new row, giving you a continuous improvement record you can actually read.

### 🪩 Agent lifecycle hooks

Five deterministic shell scripts run at key agent lifecycle points — enforcing rules that soft instructions cannot guarantee. Hooks auto-inject project context at session start, block dangerous commands before they execute, auto-format edited files, enforce the retrospective before session end, and preserve workspace state before context compaction. Configure in `.github/hooks/copilot-hooks.json`.

### 🔍 Extension and test-coverage review

Two built-in review modes surface at the end of any session:

- **Extension Review** — audits your installed VS Code extensions against the project's needs, flags redundancies and gaps, and proposes a curated list.
- **Test Coverage Review** — categorises every module by test maturity, identifies untested critical paths, and recommends a prioritised CI/CD action plan.

---

## What gets scaffolded into your project

| Artifact | Source | Purpose |
|----------|--------|---------|
| `.github/copilot-instructions.md` | Filled from template | Primary AI guidance — methodology-complete and project-specific |
| `.github/agents/*.agent.md` | Copied from template | Four model-pinned agents |
| `.github/hooks/copilot-hooks.json` | Copied from template | Agent lifecycle hooks configuration |
| `.github/hooks/scripts/*.sh` | Copied from template | Five starter hook scripts (security, formatting, retrospective, context) |
| `.github/skills/*/SKILL.md` | Copied from template | Six starter skills (Agent Skills standard) |
| `.github/instructions/*.instructions.md` | Copied from template | Path-specific instruction stubs (tests, API, config, docs) |
| `.github/prompts/*.prompt.md` | Copied from template | Five reusable slash commands (/explain, /refactor, /test-gen, /review-file, /commit-msg) |
| `.github/workflows/copilot-setup-steps.yml` | Generated from template | Environment setup for GitHub Copilot coding agent |
| `.vscode/mcp.json` | Generated from template | MCP server configuration (Full setup, E22 ≠ None) |
| `AGENTS.md` | Copied from template | AI entry point — trigger phrases and remote sequences |
| `CHANGELOG.md` | `template/CHANGELOG.md` | Keep-a-Changelog stub for your project's history |
| `JOURNAL.md` | `template/JOURNAL.md` | ADR-style architectural decision record |
| `BIBLIOGRAPHY.md` | `template/BIBLIOGRAPHY.md` | File catalogue with LOC tracking |
| `METRICS.md` | `template/METRICS.md` | Kaizen baseline snapshot table |
| `.copilot/workspace/*.md` | `template/workspace/` | Seven workspace identity files |

---

## Human-readable guides

Every AI-facing file has a plain-English companion in `docs/`:

| Guide | Explains |
|-------|---------|
| [`docs/INSTRUCTIONS-GUIDE.md`](docs/INSTRUCTIONS-GUIDE.md) | What each §1–§13 section does and how to customise it |
| [`docs/SETUP-GUIDE.md`](docs/SETUP-GUIDE.md) | What happens during setup, step by step |
| [`docs/UPDATE-GUIDE.md`](docs/UPDATE-GUIDE.md) | How the update and restore process works |
| [`docs/AGENTS-GUIDE.md`](docs/AGENTS-GUIDE.md) | Trigger phrases and the model-pinned agent system |
| [`docs/SKILLS-GUIDE.md`](docs/SKILLS-GUIDE.md) | How the Agent Skills library and §12 Skill Protocol work |
| [`docs/PATH-INSTRUCTIONS-GUIDE.md`](docs/PATH-INSTRUCTIONS-GUIDE.md) | How path-specific instruction files work and when to use them |
| [`docs/PROMPTS-GUIDE.md`](docs/PROMPTS-GUIDE.md) | How prompt files become VS Code slash commands |
| [`docs/SECURITY-GUIDE.md`](docs/SECURITY-GUIDE.md) | SHA-pinning, harden-runner, Scorecard, and Graduated Trust Model |
| [`docs/MCP-GUIDE.md`](docs/MCP-GUIDE.md) | How MCP integration works — server tiers, configuration, and quality gate |
| [`docs/RELEASE-AUTOMATION-GUIDE.md`](docs/RELEASE-AUTOMATION-GUIDE.md) | Manual vs automated release workflows and how to switch |
| [`docs/EXTENSION-REVIEW-GUIDE.md`](docs/EXTENSION-REVIEW-GUIDE.md) | How the VS Code extension audit feature works |
| [`docs/TEST-REVIEW-GUIDE.md`](docs/TEST-REVIEW-GUIDE.md) | How the test coverage review and CI recommendation feature works |
| [`docs/HEARTBEAT-GUIDE.md`](docs/HEARTBEAT-GUIDE.md) | Event-driven heartbeat — triggers, checks, cross-file wiring, and customisation |
| [`docs/HOOKS-GUIDE.md`](docs/HOOKS-GUIDE.md) | Agent lifecycle hooks — starter scripts, configuration, customisation, and security |

---

## Repository layout

```text
copilot-instructions-template/
├── .github/
│   ├── copilot-instructions.md         # Primary AI guidance (Lean/Kaizen, §1–§13)
│   ├── agents/
│   │   ├── setup.agent.md              # Claude Sonnet 4.6 — onboarding & template ops
│   │   ├── coding.agent.md             # GPT-5.3-Codex — implementation & refactoring
│   │   ├── review.agent.md             # Claude Opus 4.6 — architectural review
│   │   └── fast.agent.md               # Claude Haiku 4.5 — quick questions
│   ├── skills/
│   │   ├── skill-creator/SKILL.md      # Meta-skill — author new skills
│   │   ├── fix-ci-failure/SKILL.md     # Diagnose and fix CI failures
│   │   ├── lean-pr-review/SKILL.md     # Lean waste-categorised PR review
│   │   ├── conventional-commit/SKILL.md # Conventional Commits messages
│   │   ├── mcp-builder/SKILL.md        # Build and register MCP servers
│   │   └── webapp-testing/SKILL.md     # Playwright-based web app testing
│   ├── instructions/
│   │   ├── tests.instructions.md       # Path rules for test files
│   │   ├── api-routes.instructions.md  # Path rules for API routes
│   │   ├── config.instructions.md      # Path rules for config files
│   │   └── docs.instructions.md        # Path rules for documentation
│   ├── prompts/
│   │   ├── explain.prompt.md           # /explain — waste-aware code explanation
│   │   ├── refactor.prompt.md          # /refactor — Lean-principled refactoring
│   │   ├── test-gen.prompt.md          # /test-gen — convention-following test gen
│   │   ├── review-file.prompt.md       # /review-file — §2 Review Mode
│   │   └── commit-msg.prompt.md        # /commit-msg — Conventional Commits
│   ├── workflows/
│   │   ├── ci.yml                      # Validates structure, links, and sections on push/PR
│   │   ├── release-manual.yml          # Manual GitHub release when VERSION.md is bumped
│   │   ├── release-please.yml          # Automated Conventional Commits release
│   │   ├── stale.yml                   # Closes stale issues and PRs weekly
│   │   ├── links.yml                   # Lychee link checker (weekly + PR)
│   │   ├── vale.yml                    # Vale prose linter (PR)
│   │   └── scorecard.yml               # OpenSSF Scorecard (weekly + push)
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml              # Structured bug report form
│   │   └── feature_request.yml         # Structured feature request form
│   └── PULL_REQUEST_TEMPLATE.md        # PR checklist (auto-shown on new PRs)
├── docs/
│   ├── INSTRUCTIONS-GUIDE.md           # Human guide to copilot-instructions.md
│   ├── SKILLS-GUIDE.md                 # Human guide to the Agent Skills library
│   ├── SETUP-GUIDE.md                  # Human guide to the setup process
│   ├── UPDATE-GUIDE.md                 # Human guide to the update/restore protocol
│   ├── AGENTS-GUIDE.md                 # Human guide to trigger phrases + model agents
│   ├── EXTENSION-REVIEW-GUIDE.md       # Human guide to the extension audit feature
│   ├── TEST-REVIEW-GUIDE.md            # Human guide to the test coverage review feature
│   ├── PATH-INSTRUCTIONS-GUIDE.md      # Human guide to path-specific instructions
│   ├── PROMPTS-GUIDE.md                # Human guide to reusable prompt files
│   ├── SECURITY-GUIDE.md              # Human guide to security hardening
│   ├── MCP-GUIDE.md                    # Human guide to MCP integration
│   ├── RELEASE-AUTOMATION-GUIDE.md     # Human guide to release workflows
│   ├── HEARTBEAT-GUIDE.md              # Human guide to event-driven heartbeat
│   └── HOOKS-GUIDE.md                  # Human guide to agent lifecycle hooks
├── template/
│   ├── CHANGELOG.md                    # Keep-a-Changelog stub (scaffolded into consumer projects)
│   ├── JOURNAL.md                      # ADR-style journal stub
│   ├── BIBLIOGRAPHY.md                 # File catalogue stub
│   ├── METRICS.md                      # Kaizen baseline snapshot stub
│   ├── copilot-setup-steps.yml         # GitHub Actions workflow for Copilot coding agent
│   ├── skills/
│   │   ├── skill-creator/SKILL.md      # Starter skill: meta-skill for authoring
│   │   ├── fix-ci-failure/SKILL.md     # Starter skill: CI failure diagnosis
│   │   ├── lean-pr-review/SKILL.md     # Starter skill: Lean PR review
│   │   ├── conventional-commit/SKILL.md # Starter skill: Conventional Commits
│   │   ├── mcp-builder/SKILL.md        # Starter skill: MCP server creation
│   │   └── webapp-testing/SKILL.md     # Starter skill: Playwright web app testing
│   ├── vscode/
│   │   └── mcp.json                    # MCP server configuration template
│   ├── hooks/
│   │   ├── copilot-hooks.json          # Agent hooks configuration template
│   │   └── scripts/
│   │       ├── session-start.sh        # SessionStart — project context injection
│   │       ├── guard-destructive.sh    # PreToolUse — dangerous command guard
│   │       ├── post-edit-lint.sh       # PostToolUse — auto-format after edits
│   │       ├── enforce-retrospective.sh # Stop — retrospective enforcement
│   │       └── save-context.sh         # PreCompact — context preservation
│   └── workspace/
│       ├── IDENTITY.md                 # Agent self-description stub
│       ├── SOUL.md                     # Values & reasoning patterns stub
│       ├── USER.md                     # User profile stub
│       ├── TOOLS.md                    # Tool usage patterns + Extension registry
│       ├── MEMORY.md                   # Memory strategy stub
│       ├── BOOTSTRAP.md                # Permanent setup origin record stub
│       └── HEARTBEAT.md                # Event-driven health check checklist stub
├── examples/
│   └── valis/
│       └── README.md                   # Reference implementation (asafelobotomy/Valis)
├── AGENTS.md                           # AI entry point — trigger phrases + remote sequences
├── SETUP.md                            # One-time agentic setup (self-destructs after use)
├── UPDATE.md                           # Update protocol (run on demand)
├── VERSION.md                          # Semver — single source of truth for template version
├── CHANGELOG.md                        # This template's own version history
├── CONTRIBUTING.md                     # Contribution guidelines
├── LICENSE                             # MIT
├── .markdownlint.json                  # Lint rules enforced by CI
├── .vale.ini                           # Vale prose linting configuration
└── .github/dependabot.yml             # Automated dependency updates
```

---

## Philosophy

The Lean / Kaizen methodology this template encodes has three properties that make it well-suited to AI-assisted development:

1. **Measurable baselines** — you always know whether things are improving.
2. **Small batches** — changes are granular, reversible, and reviewable.
3. **Continuous improvement** — the instructions themselves are a product that gets better over time.

The instructions are not a one-time config. They are a living artefact that accumulates your team's hard-won conventions, retires rules that cause waste, and stays in sync with upstream improvements — automatically, with full audit trail.

---

## Reference implementation

[asafelobotomy/Valis](examples/valis/README.md) is the canonical first consumer of this template — a CLI AI assistant with a mature Lean/Kaizen workflow that this template was distilled from.

---

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

---

## License

MIT — see [LICENSE](LICENSE) for details.
