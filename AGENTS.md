# Agent Entry Point — copilot-instructions-template

This file is read by AI agents (GitHub Copilot and compatible agents) to understand how to interact with this repository.

---

## Trigger phrases

When a user says any of the following in a Copilot chat:

- *"Setup from asafelobotomy/copilot-instructions-template"*
- *"Bootstrap this project from copilot-instructions-template"*
- *"Use the Lean/Kaizen Copilot template to set up this project"*
- *"Initialise this project with asafelobotomy/copilot-instructions-template"*
- *"Run the copilot-instructions-template setup"*

…perform the **Remote Bootstrap** sequence below. No manual file copying is required from the user.

---

## What this repo is

A generic, **living** GitHub Copilot instructions template grounded in **Lean/Kaizen** methodology. It provides:

- A structured `.github/copilot-instructions.md` template with `{{PLACEHOLDER}}` tokens for project-specific values.
- A one-time setup process (`SETUP.md`) that Copilot runs to tailor everything to the target project's stack.
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

## File map

| File | Role |
|------|------|
| `AGENTS.md` | This file — AI agent entry point |
| `SETUP.md` | Complete setup guide (remote-executable) |
| `.github/copilot-instructions.md` | Generic instructions template with `{{PLACEHOLDER}}` tokens |
| `template/workspace/IDENTITY.md` | Agent self-description stub |
| `template/workspace/SOUL.md` | Agent values & reasoning patterns stub |
| `template/workspace/USER.md` | User profile stub |
| `template/workspace/TOOLS.md` | Tool usage patterns stub |
| `template/workspace/MEMORY.md` | Memory strategy stub |
| `template/workspace/BOOTSTRAP.md` | Bootstrap record stub |
| `template/CHANGELOG.md` | Keep-a-Changelog stub |
| `template/JOURNAL.md` | ADR journal stub |
| `template/BIBLIOGRAPHY.md` | File catalogue stub |
| `template/METRICS.md` | Metrics baseline table stub |
| `examples/valis/README.md` | Reference implementation |

---

## Canonical trigger (for documentation and onboarding)

> *"Setup from asafelobotomy/copilot-instructions-template"*
