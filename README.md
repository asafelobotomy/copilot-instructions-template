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
|  | The primary AI guidance file. Methodology-complete on arrival; project-specific section filled in during setup. |
|  | Four model-pinned agents for VS Code 1.106+: Setup (Claude Sonnet 4.6), Code (GPT-5.3-Codex), Review (Claude Opus 4.6), Fast (Claude Haiku 4.5). |
|  | Six workspace identity files Copilot maintains across sessions. |
|  | AI agent entry point — trigger phrases + remote bootstrap / update / restore sequences. |
|  | Update protocol — fetch, diff, backup, and apply template improvements on demand. |
|  | Keep-a-Changelog stub. |
|  | Architectural decision record (ADR-style) journal. |
|  | File catalogue (every file, its purpose, its LOC). |
|  | Kaizen baseline snapshot table — one row per measurement event. |

---

## Alternative: copy files manually

### Existing project

1. Copy  into the root of your project.
2. Copy  into your project's  directory.
3. Open a Copilot chat and say: *"Please run the setup process described in SETUP.md."*
4. Copilot will discover your stack, fill every , scaffold the workspace identity files, capture an initial METRICS baseline, create the doc stubs, and delete .

### New project

Click **"Use this template"** on GitHub to create a new repo from this template. Then follow step 3 above.

---

## How the living instructions work

The instructions contain an explicit **Living Update Protocol** section. Copilot is authorised to edit  when *any* of the following is true:

- A convention has appeared identically in **≥ 3 separate sessions** → codify it.
- An existing guideline **demonstrably caused wasted work** → revise or retire it.
- A **retrospective session** explicitly reviews the instructions.

Every self-edit must be accompanied by a one-line entry in  recording what changed and why.

---

## Reference implementation

[asafelobotomy/Valis](examples/valis/README.md) is the canonical first consumer of this template — a CLI AI assistant with a mature Lean/Kaizen workflow that this template was distilled from.

---

## Human-readable guides

The  directory contains plain-English explanations of the AI-facing files, for transparency:

| Guide | Explains |
|-------|---------|
| [](docs/INSTRUCTIONS-GUIDE.md) | What each section of  does and how to customise it |
| [](docs/SETUP-GUIDE.md) | What happens during setup, step by step |
| [](docs/UPDATE-GUIDE.md) | How the update and restore process works |
| [](docs/AGENTS-GUIDE.md) | Trigger phrases and the model-pinned agent system |

---

## Files in this repo



---

## Philosophy

This template is not a linter config or a CI pipeline. It is **instruction firmware** — a shared mental model between you and your AI coding agent about *how work should be done*. The Lean/Kaizen methodology it encodes has three properties that make it well-suited to AI-assisted development:

1. **Measurable baselines** — you can always tell whether things are improving.
2. **Small batches** — changes are granular, reversible, and reviewable.
3. **Continuous improvement** — the instructions themselves are a product that gets better over time.

License: MIT
