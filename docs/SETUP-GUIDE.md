# Setup Guide — Human Reference

> **Machine-readable version**: `SETUP.md` (deleted after setup completes)
> This document explains what happens during setup, what choices you'll be asked to make, and what gets created.

---

## How to start

Open a Copilot chat in your project and say:

> *"Setup from asafelobotomy/copilot-instructions-template"*

Copilot fetches the setup guide directly from GitHub and runs it in your current project. You don't need to copy any files.

---

## What happens during setup

Setup runs in six steps. Here's what to expect at each one.

### Step 0 — Pre-flight (questions before any writes)

Copilot checks four things before creating a single file:

**0a — Existing Copilot instructions**

If `.github/copilot-instructions.md` already exists, Copilot asks what to do:

- **Archive** — save the old file to `.github/archive/`, then use the template. Your existing conventions are preserved in the archive.
- **Delete** — remove the old file and start fresh.
- **Merge** — read both files and produce a unified version. Unique conventions from your old file land in §10 (Project-Specific Overrides), clearly labelled.

**0b — Existing workspace identity files**

If `.copilot/workspace/` already has files (IDENTITY.md, SOUL.md, etc.), Copilot asks whether to keep them, overwrite them, or handle each one individually. The safe default is "keep all" — these files often contain session history and learned preferences.

**0c — Existing documentation stubs**

Copilot checks for `CHANGELOG.md`, `JOURNAL.md`, `BIBLIOGRAPHY.md`, `METRICS.md`. If they exist, it skips creating them (or appends setup entries if you prefer).

**0d — User Preference Interview**

This is the most interactive part. Copilot first asks which setup level you want, then presents the corresponding questions. All tiers produce an equally-capable agent — higher tiers unlock deeper customisation rather than adding features.

| Setup level | Questions | Time |
|-------------|-----------|------|
| **S — Simple** | S1–S5 (5 questions) | ~1 min |
| **A — Advanced** | S1–S5 + A6–A14 (14 questions) | ~2 min |
| **E — Expert** | S1–S5 + A6–A14 + E15–E19 (19 questions) | ~3 min |

You can also type "skip" to use all defaults and proceed immediately.

| Question | What it controls |
|----------|-----------------|
| S1 — Response style | How much explanation Copilot gives |
| S2 — Experience level | Whether Copilot explains basics or assumes you know them |
| S3 — Primary mode | Speed vs quality vs learning vs production hardening |
| S4 — Testing | Whether tests are written automatically, suggested, or skipped |
| S5 — Autonomy | Whether Copilot acts then tells you, or asks first |
| A6 — Code style | How formatting and style decisions are made (infer / linter / guide) |
| A7 — Documentation | Level of inline docs expected |
| A8 — Error handling | Fail fast vs defensive vs graceful degradation |
| A9 — Security | How aggressively to flag security concerns |
| A10 — File size discipline | LOC thresholds for §3 baselines (150/300 to no limits) |
| A11 — Dependencies | Minimal vs pragmatic vs ecosystem-first |
| A12 — Instruction editing | How §8 Living Update Protocol behaves (free / ask / suggest / locked) |
| A13 — Refactoring appetite | Proactively fix smells, flag them, or ignore |
| A14 — Reporting format | How Copilot reports completed work |
| E15 — Tool availability | What to do when a required tool isn't installed |
| E16 — Agent persona | Personality / tone (Professional, Mentor, Pair-programmer, etc.) |
| E17 — VS Code settings | Whether Copilot may modify `.vscode/settings.json` |
| E18 — Global autonomy | Master 1–5 failsafe that caps all autonomy settings |
| E19 — Mood lightener | Whether Copilot drops occasional humour |

All answers are written into §10 of your instructions file as a 19-row User Preferences table. Questions you didn't answer (because you chose a lower tier) use sensible defaults. You can change preferences any time by editing that section or triggering an update interview.

**0e — Pre-flight summary**

Copilot presents a summary of everything it will do and waits 10 seconds. You can say "wait" or "stop" to cancel before any files are written.

---

### Step 1 — Stack discovery

Copilot reads your `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Makefile`, or `README.md` to discover your project's language, runtime, package manager, test framework, and build commands.

Any values it can't determine are left as `{{PLACEHOLDER}}` tokens with a `<!-- TODO: fill once known -->` comment — you can fill them in later.

---

### Step 2 — Populate the instructions file

Every `{{PLACEHOLDER}}` in `.github/copilot-instructions.md` is replaced with the values discovered in Step 1. The user preferences from Step 0d are added to §10.

---

### Step 2.5 — Write model-pinned agent files

Four agent files are created in `.github/agents/` for VS Code 1.106+ users. These pre-configure the Copilot agent dropdown with the recommended model for each task type. See [AGENTS-GUIDE.md](AGENTS-GUIDE.md) for details.

---

### Step 3 — Scaffold workspace identity files

Six files are created in `.copilot/workspace/`:

| File | Purpose |
|------|---------|
| `IDENTITY.md` | Copilot's self-description for this project |
| `SOUL.md` | Core values and reasoning patterns |
| `USER.md` | Empty profile — filled as Copilot learns your preferences |
| `TOOLS.md` | Effective command patterns for this project |
| `MEMORY.md` | Memory strategy (what to retain vs. always re-read) |
| `BOOTSTRAP.md` | Permanent record of setup date, stack, and files created |

These files help Copilot maintain context across sessions. They're regularly updated by Copilot as it learns more about your project and your working style.

---

### Step 4 — Capture a metrics baseline

An initial row is appended to `METRICS.md` with today's date, current LOC count, file count, test count, and dependency count. This is your baseline for Kaizen improvement tracking.

---

### Step 5 — Create documentation stubs

`CHANGELOG.md`, `JOURNAL.md`, `BIBLIOGRAPHY.md` are created if they don't exist. `JOURNAL.md` gets an initial entry recording the setup date and methodology decision.

---

### Step 6 — Self-destruct

Copilot prints a full summary of everything that was created or modified, then asks whether to delete `SETUP.md`. Once confirmed, `SETUP.md` is removed and the project is live.

---

## After setup

You're done. Copilot will now use `.github/copilot-instructions.md` automatically on every chat session in this project. Use the trigger phrases in [AGENTS-GUIDE.md](AGENTS-GUIDE.md) to run updates or restores later.
