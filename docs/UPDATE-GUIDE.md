# Update Guide — Human Reference

> **Machine-readable version**: `UPDATE.md`
> This document explains how to update your installed instructions when a new template version is released.

---

## How to trigger an update

Open a Copilot chat and say:

> *"Update your instructions"*

Copilot fetches `UPDATE.md` from the template repo and follows the protocol exactly.

---

## What happens during an update

### 1 — Version check

Copilot reads your installed version stamp from `.github/copilot-instructions.md`:

```text
> **Template version**: 1.0.0 | **Applied**: 2026-02-19
```

It then fetches the current `VERSION` from the template repo. If the versions are equal, it reports "already up to date" and stops.

Use *"Force check instruction updates"* to run a full comparison even when versions match — useful if you edited your version stamp manually or want to verify sync.

---

### 2 — Build the change manifest

Copilot compares your installed file section-by-section against the new template (§1–§9 only). For each section it assigns a status:

| Status | Meaning |
|--------|---------|
| `UNCHANGED` | Section is identical to the template |
| `UPDATED` | Template has a newer version of this section |
| `USER_MODIFIED` | Your installed section differs from both old and new template — you may have edited it |
| `PROTECTED` | §10 — always excluded from comparison and never touched |

---

### 3 — Pre-flight Report

Copilot presents a report showing:

- The version comparison
- What changed in the new version (from CHANGELOG)
- The section-by-section diff table
- A guardrail check

**Nothing has been written yet.** You choose what to do.

---

### 4 — Your decision

You respond with one of three options:

**U — Update all**: Apply every available change at once and confirm afterwards.

**S — Skip**: Do nothing. Your instructions stay exactly as they are.

**C — Customise**: Copilot walks through each changed section one at a time and asks:

- **Apply** — use the new template version.
- **Skip** — keep your current version.
- **Customise** — see both versions side-by-side and write a merged version.

---

### 5 — Automatic backup (before any writes)

Immediately after you confirm an update (U or C → yes), before anything is written, Copilot creates:

```text
.github/archive/pre-update-YYYY-MM-DD-vX.Y.Z/
  copilot-instructions.md    ← exact copy of your current file
  BACKUP-MANIFEST.md         ← records what version this is and when it was backed up
```

This backup is created unconditionally. You can restore from it at any time.

---

### 6 — Apply changes

Copilot writes only the confirmed sections. It never touches:

- §10 (Project-Specific Overrides) — entire section
- Your User Preferences block
- Any `<!-- migrated -->` or `<!-- user-added -->` blocks
- Resolved placeholder values (commands and thresholds you've set)

---

### 7 — Post-update records

After writing, Copilot:

1. Updates the version stamp: `> **Template version**: 1.1.0 | **Applied**: 2026-02-19 | **Updated**: 2026-03-15`
2. Appends to `JOURNAL.md` — records which sections were updated, skipped, and customised.
3. Appends to `CHANGELOG.md` — records the update under `[Unreleased]`.
4. Prints a confirmation showing the backup location.

---

## How to restore a backup

If an update didn't go as expected, open Copilot and say:

> *"Restore instructions from backup"*

Copilot lists available backups and (after you select one) restores the file. The current state is always backed up before restoration, so restoration is always reversible.

---

## What is permanently protected

These items are **never** modified by an update, regardless of what you choose:

| Protected item | Why |
|---------------|-----|
| §10 — Project-Specific Overrides | Contains your project identity |
| User Preferences block | Set during your setup interview |
| `<!-- migrated -->` blocks | Conventions from before you adopted the template |
| `<!-- user-added -->` blocks | Explicitly human-authored content |
| Resolved placeholder values | Commands like `bun test` must not revert to `{{TEST_COMMAND}}` |

---

## Notable version migrations

These notes cover changes that require manual action beyond running "Update your instructions". The update protocol handles all §1–§9 section changes automatically — these notes cover companion files and setup steps that the protocol does not touch.

### v1.x → v2.0.0 (Major)

**New in this release**: §13 Model Context Protocol (MCP), MCP server template, two new starter skills, and an automated release workflow option.

**What the update protocol does automatically**:

- Proposes adding §13 as a `NEW_SECTION` — accept it to bring in the full MCP protocol.
- Proposes any §1–§12 section changes as `UPDATED` items.

**What requires manual action** (the update protocol does not touch these):

| Item | Action |
|------|--------|
| MCP server config | Optionally create `.vscode/mcp.json` by fetching `template/vscode/mcp.json` from the template repo and configuring your preferred servers |
| New starter skills | Optionally fetch `template/skills/mcp-builder/SKILL.md` and `template/skills/webapp-testing/SKILL.md` into `.github/skills/` |
| Release automation | Optionally adopt `release-please.yml` — requires `release-please-config.json` and `.release-please-manifest.json` at repo root; see `docs/RELEASE-AUTOMATION-GUIDE.md` |
| §10 User Preferences | Manually add an `MCP servers` row (E22) to your existing User Preferences table if you want to document your MCP choice |

### v1.0.x / v1.1.0 → v1.4.0

**New in this release**: SHA-pinned actions, harden-runner, OpenSSF Scorecard, Graduated Trust Model (§10), skill `compatibility` and `allowed-tools` fields.

**What requires manual action**:

| Item | Action |
|------|--------|
| Skill security fields | Optionally add `compatibility: ">=1.4"` and `allowed-tools: [...]` frontmatter to your existing `.github/skills/*/SKILL.md` files |
| §10 Verification trust | Manually add a `Verification trust` row (E21) to your User Preferences table and fill in `{{TRUST_OVERRIDES}}` in §10 |
