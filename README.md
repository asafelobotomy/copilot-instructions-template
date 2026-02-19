<div align="center">

# copilot-instructions-template

**Instruction firmware for AI-assisted development — grounded in Lean / Kaizen**

[![CI](https://github.com/asafelobotomy/copilot-instructions-template/actions/workflows/ci.yml/badge.svg)](https://github.com/asafelobotomy/copilot-instructions-template/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-1.0.2-blue)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![VS Code](https://img.shields.io/badge/VS_Code-1.106+-007ACC?logo=visualstudiocode)](https://code.visualstudio.com/)

</div>

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

Copilot fetches the template and setup guide directly from GitHub, interviews you with 5–19 questions (your choice of depth), fills every placeholder, scaffolds your workspace files, captures a Kaizen baseline, and self-destructs the setup script. **No cloning, no copying, no manual steps.**

> **⚠️ Use the Setup agent or an interactive model.** Codex models (`GPT-5.x-Codex`) run autonomously and cannot present interactive prompts — the preference interview will be silently skipped. Select **Claude Sonnet 4.6** (or any interactive model) in the Copilot picker, or use the `@setup` agent which pins the correct model automatically.

<!-- -->

> **Prefer to do it manually?** Copy `.github/copilot-instructions.md` and `SETUP.md` into your project, then tell Copilot: *"Please run the setup process described in SETUP.md."*
>
> **Starting fresh?** Click **Use this template** on GitHub, then run the quickstart above in your new repo.

---

## Key features

### ⚙️ Eleven-section instructions architecture

`.github/copilot-instructions.md` ships with eleven named sections (§1–§11) covering identity, workflow mode, safety gates, coding conventions, the PDCA cycle, waste cataloguing, self-editing protocol, test/extension review, and project-specific overrides. Every section is placeholder-driven — nothing is hardcoded to a particular stack.

### 🤖 Four model-pinned agents

`.github/agents/` contains four VS Code agent files (requires VS Code 1.106+), each pinned to the model best suited for its role:

| Agent | Model | Role |
|-------|-------|------|
| `setup.agent.md` | Claude Sonnet 4.6 | Onboarding, template ops, preference interview (batched with verification gate) |
| `coding.agent.md` | GPT-5.3-Codex | Implementation, refactoring, test writing |
| `review.agent.md` | Claude Opus 4.6 | Architectural review, Lean waste audit |
| `fast.agent.md` | Claude Haiku 4.5 | Quick lookups, explanations, small edits |

### 🔄 Living update protocol

The template ships versioned. When a new version is released, say *"Update your instructions"* and Copilot will fetch the diff, present a section-by-section change manifest, let you apply / skip / customise each change, back up the current file, write the updates, and record everything in `JOURNAL.md` and `CHANGELOG.md`. The update is always reversible.

### 🏗️ Workspace identity system

Six workspace files are scaffolded into your project during setup and maintained across sessions:

| File | Purpose |
|------|---------|
| `IDENTITY.md` | Agent self-description and project context |
| `SOUL.md` | Values, reasoning patterns, and tone |
| `USER.md` | Your preferences, background, and working style |
| `TOOLS.md` | Tool usage patterns and VS Code extension registry |
| `MEMORY.md` | Session continuity and memory strategy |
| `BOOTSTRAP.md` | Permanent setup origin record |

### 📊 Kaizen baseline and metrics

At setup completion Copilot captures a baseline snapshot (file count, LOC, dependency count, test coverage) into `METRICS.md`. Every significant change appends a new row, giving you a continuous improvement record you can actually read.

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
| `AGENTS.md` | Copied from template | AI entry point — trigger phrases and remote sequences |
| `CHANGELOG.md` | `template/CHANGELOG.md` | Keep-a-Changelog stub for your project's history |
| `JOURNAL.md` | `template/JOURNAL.md` | ADR-style architectural decision record |
| `BIBLIOGRAPHY.md` | `template/BIBLIOGRAPHY.md` | File catalogue with LOC tracking |
| `METRICS.md` | `template/METRICS.md` | Kaizen baseline snapshot table |
| `.copilot/workspace/*.md` | `template/workspace/` | Six workspace identity files |

---

## Human-readable guides

Every AI-facing file has a plain-English companion in `docs/`:

| Guide | Explains |
|-------|---------|
| [`docs/INSTRUCTIONS-GUIDE.md`](docs/INSTRUCTIONS-GUIDE.md) | What each §1–§11 section does and how to customise it |
| [`docs/SETUP-GUIDE.md`](docs/SETUP-GUIDE.md) | What happens during setup, step by step |
| [`docs/UPDATE-GUIDE.md`](docs/UPDATE-GUIDE.md) | How the update and restore process works |
| [`docs/AGENTS-GUIDE.md`](docs/AGENTS-GUIDE.md) | Trigger phrases and the model-pinned agent system |
| [`docs/EXTENSION-REVIEW-GUIDE.md`](docs/EXTENSION-REVIEW-GUIDE.md) | How the VS Code extension audit feature works |
| [`docs/TEST-REVIEW-GUIDE.md`](docs/TEST-REVIEW-GUIDE.md) | How the test coverage review and CI recommendation feature works |

---

## Repository layout

```text
copilot-instructions-template/
├── .github/
│   ├── copilot-instructions.md         # Primary AI guidance (Lean/Kaizen, §1–§11)
│   ├── agents/
│   │   ├── setup.agent.md              # Claude Sonnet 4.6 — onboarding & template ops
│   │   ├── coding.agent.md             # GPT-5.3-Codex — implementation & refactoring
│   │   ├── review.agent.md             # Claude Opus 4.6 — architectural review
│   │   └── fast.agent.md               # Claude Haiku 4.5 — quick questions
│   ├── workflows/
│   │   ├── ci.yml                      # Validates structure, links, and sections on push/PR
│   │   ├── release.yml                 # Auto-creates GitHub release when VERSION is bumped
│   │   └── stale.yml                   # Closes stale issues and PRs weekly
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml              # Structured bug report form
│   │   └── feature_request.yml         # Structured feature request form
│   └── PULL_REQUEST_TEMPLATE.md        # PR checklist (auto-shown on new PRs)
├── docs/
│   ├── INSTRUCTIONS-GUIDE.md           # Human guide to copilot-instructions.md
│   ├── SETUP-GUIDE.md                  # Human guide to the setup process
│   ├── UPDATE-GUIDE.md                 # Human guide to the update/restore protocol
│   ├── AGENTS-GUIDE.md                 # Human guide to trigger phrases + model agents
│   ├── EXTENSION-REVIEW-GUIDE.md       # Human guide to the extension audit feature
│   └── TEST-REVIEW-GUIDE.md            # Human guide to the test coverage review feature
├── template/
│   ├── CHANGELOG.md                    # Keep-a-Changelog stub (scaffolded into consumer projects)
│   ├── JOURNAL.md                      # ADR-style journal stub
│   ├── BIBLIOGRAPHY.md                 # File catalogue stub
│   ├── METRICS.md                      # Kaizen baseline snapshot stub
│   └── workspace/
│       ├── IDENTITY.md                 # Agent self-description stub
│       ├── SOUL.md                     # Values & reasoning patterns stub
│       ├── USER.md                     # User profile stub
│       ├── TOOLS.md                    # Tool usage patterns + Extension registry
│       ├── MEMORY.md                   # Memory strategy stub
│       └── BOOTSTRAP.md                # Permanent setup origin record stub
├── examples/
│   └── valis/
│       └── README.md                   # Reference implementation (asafelobotomy/Valis)
├── AGENTS.md                           # AI entry point — trigger phrases + remote sequences
├── SETUP.md                            # One-time agentic setup (self-destructs after use)
├── UPDATE.md                           # Update protocol (run on demand)
├── VERSION                             # Semver — read by update pre-flight check
├── CHANGELOG.md                        # This template's own version history
├── CONTRIBUTING.md                     # Contribution guidelines
├── LICENSE                             # MIT
└── .markdownlint.json                  # Lint rules enforced by CI
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
