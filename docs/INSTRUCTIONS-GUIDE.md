# Instructions Guide — Human Reference

> **Machine-readable version**: `.github/copilot-instructions.md`
> This document explains what is in that file, why each section exists, and how to customise it.

---

## What is `.github/copilot-instructions.md`?

This is the primary AI guidance file — the "instruction firmware" for Copilot in your project. GitHub Copilot loads it automatically at the start of every chat session, so everything written here shapes how Copilot behaves in your project.

The file is structured in eleven numbered sections (§1–§11). The first nine sections encode the Lean/Kaizen methodology and are maintained by the template. §10 is yours — it holds your project's specific values and preferences. §11 defines the Tool Protocol for reusable automation.

---

## Section-by-section guide

### §1 — Lean Principles

**What it does**: Sets the five core Lean principles Copilot applies to every decision.

The table rows for "Map the value stream" and "Create flow" are filled in during setup with your project's specific description. The others are universal.

**How to customise**: Edit the "This project" column in §10 if you want to express these principles differently. Don't edit §1 directly — template updates may overwrite it.

---

### §2 — Operating Modes

**What it does**: Tells Copilot to switch between four behavioural modes depending on what you're doing.

| Mode | When to use | What changes |
|------|------------|--------------|
| Implement (default) | Writing code | Full PDCA cycle, tests required |
| Review | Code review sessions | Read-only, findings with waste tags |
| Refactor | Cleanups | No behaviour changes, LOC measured |
| Planning | Architecture / task breakdown | Complexity estimates, XL tasks flagged |

Say "switch to review mode" or "planning mode" to activate a mode.

**How to customise**: In §10, you can add a note overriding the default mode for your project (e.g., if you always want Planning mode first).

---

### §3 — Standardised Work Baselines

**What it does**: Sets the numerical guardrails that trigger Copilot warnings.

| Baseline | Default | What happens when breached |
|----------|---------|---------------------------|
| File LOC warn | 250 lines | Copilot flags it and suggests decomposition |
| File LOC hard | 400 lines | Copilot refuses to extend the file until it is split |
| Dependency budget | Set during setup | Copilot proposes removing a dep before adding one |

These defaults were set during setup based on your project's current state (dep budget = current count + 2).

**How to customise**: Change the resolved values in the §10 placeholder table. For example, set `LOC_HIGH_THRESHOLD` to 600 for a legacy codebase where 400 is unrealistic.

---

### §4 — Coding Conventions

**What it does**: Tells Copilot your language, runtime, package manager, and the patterns it observed in your codebase.

The `{{CODING_PATTERNS}}` placeholder is filled during setup with 3–5 patterns Copilot detected in your source files (e.g., "uses functional React components", "utility functions in `src/utils/`").

**How to customise**: Edit the `{{CODING_PATTERNS}}` section in your installed file whenever you establish a new convention. The Living Update Protocol (§8) is how you do this — say "Add this to your instructions: we use X pattern".

---

### §5 — PDCA Cycle

**What it does**: Defines the Plan–Do–Check–Act rhythm Copilot follows for every non-trivial change.

- **Plan**: Copilot states what files will change and estimates LOC impact before writing anything.
- **Do**: Implements the change, writing tests alongside (not after).
- **Check**: Runs the three-check ritual (`test && typecheck && loc-count`).
- **Act**: Addresses any baseline breaches, updates BIBLIOGRAPHY.md, summarises what changed.

You'll notice this makes Copilot more deliberate. It's intentional — small, verified changes over fast, broken ones.

---

### §6 — Waste Catalogue

**What it does**: Gives Copilot a vocabulary for categorising problems during code review.

Every finding in Review Mode is tagged with a waste code (W1–W8). This lets you scan a review report quickly by problem type rather than reading line by line.

Example finding: `[major] | [src/api/handler.ts:42] | [W7 Defects] | Unhandled promise rejection — async call has no catch`

---

### §7 — Metrics

**What it does**: Tells Copilot what to track and where to record it.

After any session that meaningfully changes your codebase, Copilot appends a row to `METRICS.md` with: date, total LOC, file count, test count, type error count, and runtime dep count. This gives you a historical view of whether the codebase is growing, shrinking, improving, or regressing.

**How to customise**: Add a custom metric row in §10 (the `{{EXTRA_METRIC_NAME}}` placeholder). For example: "API response time p95 — measured via k6".

---

### §8 — Living Update Protocol

**What it does**: Authorises Copilot to improve this file over time, within guardrails.

Copilot is allowed to edit `.github/copilot-instructions.md` when you use any of these phrases:

- "Add this to your instructions" → Copilot adds the convention to the appropriate section.
- "Update your instructions" → Copilot fetches the latest template and proposes a merge.
- "Remember this for next time" → Copilot adds the pattern to the file.

Every self-edit is recorded in `JOURNAL.md` so you always know what changed and why.

**What Copilot cannot do**: Delete existing rules without your explicit instruction, restructure sections unilaterally, or apply template updates without showing you a diff first.

---

### §9 — Subagent Protocol

**What it does**: Governs how Copilot delegates to sub-agents when running complex multi-step tasks.

The key guardrail: `max_depth = 3` (default). Copilot will not spawn more than 3 levels of nested sub-agents before surfacing to you to confirm direction. This prevents runaway automation.

---

### §10 — Project-Specific Overrides

**What it does**: This is your section. It holds:

1. The resolved values of all `{{PLACEHOLDER}}` tokens (filled during setup).
2. Your User Preferences (filled during the setup interview — response style, autonomy level, etc.).
3. Any additional project-specific conventions Copilot has learned.

**How to use it**: You can edit this section freely. Add conventions here that are unique to your project. Use "Add this to your instructions: ..." to have Copilot populate it for you.

---

### §11 — Tool Protocol

**What it does**: Provides a structured decision tree for when Copilot needs to use automation, scripts, or reusable utilities.

The protocol has four stages:

1. **Find** — check the project toolbox (`.copilot/tools/INDEX.md`) for an existing tool.
2. **Search** — look online (MCP registries, GitHub, package registries, official CLI docs).
3. **Compose** — assemble from 2+ existing tools via pipes or imports.
4. **Build** — write from scratch as a last resort.

Every tool (built or saved) requires an inline header with six fields: `purpose`, `when`, `inputs`, `outputs`, `risk`, and `source`. Tools rated `destructive` always pause for user confirmation before execution.

The toolbox lives at `.copilot/tools/` and is created lazily on first tool save — no setup step required.

**How to customise**: If you build a tool you want Copilot to reuse, say "Save this to the toolbox". Copilot evaluates reusability (≥ 2 distinct use cases) before saving.

---

## The Model Quick Reference

At the top of the file is a table showing which AI model to use for which task. This is for you (the human) — Copilot doesn't select its own model. You select it in the Copilot model picker before starting a task.

The model selection is also pre-configured in `.github/agents/` — see [AGENTS-GUIDE.md](AGENTS-GUIDE.md) for how to use those.

---

## Updating the instructions

To update your installed instructions to a newer version of the template, open Copilot and say:

> *"Update your instructions"*

See [UPDATE-GUIDE.md](UPDATE-GUIDE.md) for details on what happens during an update.
