# copilot-instructions-template

A **generic, living** GitHub Copilot instructions template grounded in **Lean / Kaizen** methodology. Drop it into any project — new or existing — and Copilot will run a one-time setup to tailor everything to that project's stack, then continue to improve the instructions as patterns emerge.

---

## Quickstart — one line

Open a Copilot chat in any project and say:

> *"Setup from asafelobotomy/copilot-instructions-template"*

Copilot fetches the template and setup guide directly from GitHub, runs the full setup process in your current project, and asks you questions as it goes. No downloading, no copying files, no manual steps.

---

## What this gives you

| File / directory | Purpose |
|-----------------|----------|
| `.github/copilot-instructions.md` | The primary AI guidance file. Methodology-complete on arrival; project-specific section filled in during setup. |
| `.github/agents/` | Four model-pinned agents for VS Code 1.106+: Setup (Claude Sonnet 4.6), Code (GPT-5.3-Codex), Review (Claude Opus 4.6), Fast (Claude Haiku 4.5). |
| `.copilot/workspace/` | Six workspace identity files Copilot maintains across sessions. |
| `AGENTS.md` | AI agent entry point — trigger phrases + remote bootstrap / update / restore sequences. |
| `UPDATE.md` | Update protocol — fetch, diff, backup, and apply template improvements on demand. |
| `template/CHANGELOG.md` | Keep-a-Changelog stub. |
| `template/JOURNAL.md` | Architectural decision record (ADR-style) journal. |
| `template/BIBLIOGRAPHY.md` | File catalogue (every file, its purpose, its LOC). |
| `template/METRICS.md` | Kaizen baseline snapshot table — one row per measurement event. |

---

## Alternative: copy files manually

### Existing project

1. Copy `.github/copilot-instructions.md` into the root of your project.
2. Copy `SETUP.md` into your project's `.github/` directory.
3. Open a Copilot chat and say: *"Please run the setup process described in SETUP.md."*
4. Copilot will discover your stack, fill every `{{PLACEHOLDER}}`, scaffold the workspace identity files, capture an initial METRICS baseline, create the doc stubs, and delete `SETUP.md`.

### New project

Click **"Use this template"** on GitHub to create a new repo from this template. Then follow step 3 above.

---

## How the living instructions work

The instructions contain an explicit **Living Update Protocol** section. Copilot is authorised to edit `.github/copilot-instructions.md` when *any* of the following is true:

- A convention has appeared identically in **≥ 3 separate sessions** → codify it.
- An existing guideline **demonstrably caused wasted work** → revise or retire it.
- A **retrospective session** explicitly reviews the instructions.

Every self-edit must be accompanied by a one-line entry in `JOURNAL.md` recording what changed and why.

---

## Reference implementation

[asafelobotomy/Valis](examples/valis/README.md) is the canonical first consumer of this template — a CLI AI assistant with a mature Lean/Kaizen workflow that this template was distilled from.

---

## Human-readable guides

The `docs/` directory contains plain-English explanations of the AI-facing files, for transparency:

| Guide | Explains |
|-------|---------|
| [`docs/INSTRUCTIONS-GUIDE.md`](docs/INSTRUCTIONS-GUIDE.md) | What each section of `.github/copilot-instructions.md` does and how to customise it |
| [`docs/SETUP-GUIDE.md`](docs/SETUP-GUIDE.md) | What happens during setup, step by step |
| [`docs/UPDATE-GUIDE.md`](docs/UPDATE-GUIDE.md) | How the update and restore process works |
| [`docs/AGENTS-GUIDE.md`](docs/AGENTS-GUIDE.md) | Trigger phrases and the model-pinned agent system |
| [`docs/EXTENSION-REVIEW-GUIDE.md`](docs/EXTENSION-REVIEW-GUIDE.md) | How the VS Code extension audit feature works |

---

## Files in this repo

```
copilot-instructions-template/
├── .github/
│   ├── copilot-instructions.md         # Primary AI guidance (Lean/Kaizen, §1–§11)
│   ├── agents/
│   │   ├── setup.agent.md              # Claude Sonnet 4.6 — onboarding & template ops
│   │   ├── coding.agent.md             # GPT-5.3-Codex — implementation & refactoring
│   │   ├── review.agent.md             # Claude Opus 4.6 — architectural review
│   │   └── fast.agent.md               # Claude Haiku 4.5 — quick questions
│   └── SETUP.md                        # One-time agentic setup (self-destructs after use)
├── .copilot/
│   └── tools/                          # Toolbox: reusable scripts/tools saved by agents
│       └── INDEX.md                    # Toolbox catalogue (auto-maintained)
├── docs/
│   ├── INSTRUCTIONS-GUIDE.md           # Human guide to copilot-instructions.md
│   ├── SETUP-GUIDE.md                  # Human guide to the setup process
│   ├── UPDATE-GUIDE.md                 # Human guide to the update/restore protocol
│   ├── AGENTS-GUIDE.md                 # Human guide to trigger phrases + model agents
│   └── EXTENSION-REVIEW-GUIDE.md      # Human guide to the extension audit feature
├── template/
│   ├── CHANGELOG.md                    # Keep-a-Changelog stub (for consumer projects)
│   ├── JOURNAL.md                      # ADR-style journal stub
│   ├── BIBLIOGRAPHY.md                 # File catalogue stub
│   ├── METRICS.md                      # Kaizen baseline snapshot stub
│   └── workspace/
│       ├── IDENTITY.md                 # Agent self-description stub
│       ├── SOUL.md                     # Values & reasoning patterns stub
│       ├── USER.md                     # User profile stub
│       ├── TOOLS.md                    # Tool usage patterns + Extension registry
│       ├── MEMORY.md                   # Memory strategy stub
│       └── BOOTSTRAP.md               # Permanent setup origin record stub
├── examples/
│   └── valis/
│       └── README.md                   # Reference implementation (asafelobotomy/Valis)
├── AGENTS.md                           # AI entry point — triggers + remote sequences
├── UPDATE.md                           # Update protocol (run on demand)
├── VERSION                             # Semver — read by update pre-flight
└── CHANGELOG.md                        # This template's own version history
```

---

## Philosophy

This template is not a linter config or a CI pipeline. It is **instruction firmware** — a shared mental model between you and your AI coding agent about *how work should be done*. The Lean/Kaizen methodology it encodes has three properties that make it well-suited to AI-assisted development:

1. **Measurable baselines** — you can always tell whether things are improving.
2. **Small batches** — changes are granular, reversible, and reviewable.
3. **Continuous improvement** — the instructions themselves are a product that gets better over time.

License: MIT
