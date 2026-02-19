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
```
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
```
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
