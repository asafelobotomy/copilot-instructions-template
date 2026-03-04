# Update Guide — Human Reference

> **Machine-readable version**: `UPDATE.md`
> This document explains how to update your installed instructions when a new template version is released.

---

## How to trigger an update

Open a Copilot chat and say:

> *"Update your instructions"*

This tells Copilot to check the upstream template repository at [`asafelobotomy/copilot-instructions-template`](https://github.com/asafelobotomy/copilot-instructions-template) for a newer version. Copilot fetches `UPDATE.md` from that repo and follows the update protocol exactly — comparing versions, building a change manifest, and letting you decide what to apply.

---

## What happens during an update

### 1 — Version check

Copilot reads your installed version from `.github/copilot-version.md`.

It then fetches the current `VERSION.md` from the template repo. If the versions are equal, it reports "already up to date" and stops.

Use *"Force check instruction updates"* to run a full comparison even when versions match — useful if you edited your local files manually or want to verify sync.

---

### 2 — Build the change manifest

Copilot fetches `MIGRATION.md` from the template repo — a structured registry of what changed at each version. It then performs a **version-walk**: identifying every tagged version between your installed version and the latest, and collecting per-version metadata (sections changed, companion files, breaking changes, new placeholders, manual actions).

For a **three-way merge**, Copilot also fetches the template at your installed version's tag (the old baseline). This lets it distinguish:

| Status | Meaning |
|--------|---------|
| `UNCHANGED` | Section is identical to the template |
| `UPDATED` | Template changed upstream; your copy was not edited — clean merge |
| `USER_MODIFIED` | Both you and the template changed this section — requires your decision |
| `USER_ONLY` | You edited this section but the template did not change it — your edits are preserved |
| `BREAKING` | Template changed this section with breaking impact — requires explicit confirmation |
| `NEW_SECTION` | New section introduced in the template |
| `PROTECTED` | §10 — always excluded from comparison and never touched |

---

### 3 — Pre-flight Report

Copilot presents a report showing:

- The version comparison and version steps traversed
- Breaking changes (if any)
- What changed in each version (from CHANGELOG, grouped by version)
- The section-by-section diff table with which version introduced each change
- Companion files available (agent files, skills, hooks, MCP config, etc.)
- New placeholders that need resolution
- Manual actions from MIGRATION.md
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

Copilot writes only the confirmed sections and companion files. It never touches:

- §10 (Project-Specific Overrides) — entire section
- Your User Preferences block
- Any `<!-- migrated -->` or `<!-- user-added -->` blocks
- Resolved placeholder values (commands and thresholds you've set)

Companion files (agent files, skills, hooks, MCP config, path instructions, prompt files) are created or updated based on your decisions. User-customised companion files are preserved unless you explicitly choose to overwrite them.

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

> **Machine-readable source**: All per-version migration data (sections changed, companion files, new placeholders, breaking changes, manual actions) is maintained in [`MIGRATION.md`](../MIGRATION.md) at the repository root. The update protocol reads this file automatically during the version-walk.
>
> The entries below are a human-readable summary. For the authoritative data, see `MIGRATION.md`.

### v1.x → v2.0.0 (Major — Breaking)

**New in this release**: §13 Model Context Protocol (MCP), MCP server template, two new starter skills, and an automated release workflow option.

**What the update protocol handles automatically** (since the version-walk update):

- Proposes adding §13 as a `NEW_SECTION` — accept it to bring in the full MCP protocol.
- Proposes changes to existing §1–§12 sections as `UPDATED` items.
- Offers companion files: `.vscode/mcp.json`, `mcp-builder` skill, `webapp-testing` skill.
- Detects new placeholders: `{{MCP_STACK_SERVERS}}`, `{{MCP_CUSTOM_SERVERS}}`.

**What still requires manual action**:

| Item | Action |
|------|--------|
| §10 User Preferences | Manually add an `MCP servers` row (E22) to your existing User Preferences table |
| Release automation | Optionally adopt `release-please.yml` — see `docs/RELEASE-AUTOMATION-GUIDE.md` |

### v1.0.x / v1.1.0 → v1.4.0

**New in this release**: SHA-pinned actions, harden-runner, OpenSSF Scorecard, Graduated Trust Model (§10), skill `compatibility` and `allowed-tools` fields, path-specific instructions, prompt files.

**What the update protocol handles automatically** (since the version-walk update):

- Offers companion files: 4 path instruction files, 5 prompt files, updated skills.
- Detects new placeholder: `{{TRUST_OVERRIDES}}`.

**What still requires manual action**:

| Item | Action |
|------|--------|
| §10 Verification trust | Manually add a `Verification trust` row (E21) to your User Preferences table |
