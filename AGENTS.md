# Agent Entry Point — copilot-instructions-template

This file is read by AI agents (GitHub Copilot and compatible agents) to understand how to interact with this repository.

---

## Trigger phrases

### Setup (first time)

When a user says any of the following in a Copilot chat:

- *"Setup from asafelobotomy/copilot-instructions-template"*
- *"Bootstrap this project from copilot-instructions-template"*
- *"Use the Lean/Kaizen Copilot template to set up this project"*
- *"Initialise this project with asafelobotomy/copilot-instructions-template"*
- *"Run the copilot-instructions-template setup"*

...perform the **Remote Bootstrap Sequence** below. No manual file copying is required from the user.

### Update (already set up)

When a user says any of the following in a project that **already has Copilot instructions installed**:

- *"Update your instructions"*
- *"Check for instruction updates"*
- *"Update from copilot-instructions-template"*
- *"Sync instructions with the template"*
- *"Check the template for updates"*
- *"Force check instruction updates"* *(bypasses version equality check)*

...perform the **Remote Update Sequence** below.

---

## What this repo is

A generic, **living** GitHub Copilot instructions template grounded in **Lean/Kaizen** methodology. It provides:

- A structured `.github/copilot-instructions.md` template with `{{PLACEHOLDER}}` tokens for project-specific values.
- A one-time setup process (`SETUP.md`) that Copilot runs to tailor everything to the target project's stack.
- An update process (`UPDATE.md`) that Copilot runs to fetch and apply improvements from this repo to an already-installed project.
- Six workspace identity files that Copilot maintains across sessions.
- Documentation stubs (CHANGELOG, JOURNAL, BIBLIOGRAPHY, METRICS).
- A Living Update Protocol that authorises Copilot to improve the instructions as patterns emerge.

---

## Remote Bootstrap Sequence

Perform these steps in order. You are operating in the **user's current project** — not this template repo.

### 1 — Fetch SETUP.md

Fetch and read the complete setup guide:

```
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/SETUP.md
```

### 2 — Fetch the instructions template

Fetch and hold in memory the Copilot instructions template that will be populated and written to the user's project:

```
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/copilot-instructions.md
```

### 3 — Run the setup

Follow the steps in `SETUP.md` exactly, operating on the **user's current project**.

- All file stubs (identity files, doc stubs) are embedded inline in `SETUP.md` — no further fetching from this repo is required.
- The instructions template fetched in step 2 is the file that gets populated with `{{PLACEHOLDER}}` values and written to the user's `.github/copilot-instructions.md`.

Setup outputs written to the **user's project**:

| File | Description |
|------|-------------|
| `.github/copilot-instructions.md` | Populated instructions (from the template fetched above) |
| `.copilot/workspace/IDENTITY.md` | Agent self-description |
| `.copilot/workspace/SOUL.md` | Agent values & reasoning patterns |
| `.copilot/workspace/USER.md` | Observed user profile |
| `.copilot/workspace/TOOLS.md` | Tool usage patterns |
| `.copilot/workspace/MEMORY.md` | Memory strategy |
| `.copilot/workspace/BOOTSTRAP.md` | Permanent setup origin record |
| `CHANGELOG.md` | Keep-a-Changelog stub |
| `JOURNAL.md` | ADR-style development journal |
| `BIBLIOGRAPHY.md` | File catalogue |
| `METRICS.md` | Kaizen baseline snapshot table |

### 4 — Do not write to this template repo

You are a guest reading this repo. All writes go to the **user's current project**. Do not create, modify, or delete any files in `asafelobotomy/copilot-instructions-template`.

---

## Remote Update Sequence

Perform these steps in order. You are operating in the **user's current project** — not this template repo.

### 1 — Fetch UPDATE.md

Fetch and read the complete update protocol:

```
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/UPDATE.md
```

### 2 — Follow the update protocol

Follow every step in `UPDATE.md` exactly, operating on the **user's current project**. The protocol guides you through:

1. Reading the installed version from the user's `.github/copilot-instructions.md`.
2. Fetching the current `VERSION`, `CHANGELOG.md`, and instructions template from this repo.
3. Building a section-by-section change manifest (§1–§9 only; §10 is always protected).
4. Presenting a Pre-flight Report to the user (version comparison, diff table, guardrail summary).
5. Following the user's chosen decision path:
   - **U — Update all**: apply all available changes at once.
   - **S — Skip**: do nothing.
   - **C — Customise**: review each change individually with Apply / Skip / Customise options.
6. Writing confirmed changes and updating the version stamp.
7. Appending to `JOURNAL.md` and `CHANGELOG.md`.
8. Printing the "Updated! ✓" confirmation.

### 3 — Do not write to this template repo

You are a guest reading this repo. All writes go to the **user's current project**. Do not create, modify, or delete any files in `asafelobotomy/copilot-instructions-template`.

---

## File map

| File | Role |
|------|------|
| `AGENTS.md` | This file — AI agent entry point |
| `SETUP.md` | Complete setup guide (remote-executable) |
| `UPDATE.md` | Complete update protocol (remote-executable) |
| `VERSION` | Current template version number (semver) |
| `CHANGELOG.md` | Template version history |
| `.github/copilot-instructions.md` | Generic instructions template with `{{PLACEHOLDER}}` tokens |
| `template/workspace/IDENTITY.md` | Agent self-description stub |
| `template/workspace/SOUL.md` | Agent values & reasoning patterns stub |
| `template/workspace/USER.md` | User profile stub |
| `template/workspace/TOOLS.md` | Tool usage patterns stub |
| `template/workspace/MEMORY.md` | Memory strategy stub |
| `template/workspace/BOOTSTRAP.md` | Bootstrap record stub |
| `template/CHANGELOG.md` | Keep-a-Changelog stub (for consumer project) |
| `template/JOURNAL.md` | ADR journal stub |
| `template/BIBLIOGRAPHY.md` | File catalogue stub |
| `template/METRICS.md` | Metrics baseline table stub |
| `examples/valis/README.md` | Reference implementation |

---

## Canonical triggers

| Action | Trigger phrase |
|--------|----------------|
| First-time setup | *"Setup from asafelobotomy/copilot-instructions-template"* |
| Check for updates | *"Update your instructions"* |
| Force full comparison | *"Force check instruction updates"* |
