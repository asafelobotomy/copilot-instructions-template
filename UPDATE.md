# Update Protocol — copilot-instructions-template

> **For Copilot**: This document defines the update process. Follow every step precisely. Do **not** write anything to the user's project until the user has confirmed the update plan after the Pre-flight Report — except for the automatic backup, which is always created silently before the first write.
>
> **For the human**: Open a Copilot chat and say one of the trigger phrases below. Copilot will fetch this document, check for updates, and walk you through the process.

---

## Trigger phrases

> **Canonical source**: The complete trigger phrase list is in `AGENTS.md` → "Canonical triggers" table.
> The phrases below are repeated here because UPDATE.md is fetched independently from the template repo.

When a user says any of the following in a project that already has Copilot instructions installed:

- *"Update your instructions"*
- *"Check for instruction updates"*
- *"Update from copilot-instructions-template"*
- *"Sync instructions with the template"*
- *"Check the template for updates"*
- *"Force check instruction updates"* *(bypasses version equality check — see end of document)*

> **Disambiguation**: All of these phrases mean the same thing — check the upstream template repository at `https://github.com/asafelobotomy/copilot-instructions-template` for a newer version and, if one exists, walk the user through applying the changes. This is not a request to edit the instructions in an ad-hoc way.

To restore a previous version after an update:

- *"Restore instructions from backup"*
- *"Roll back the instructions update"*
- *"List instruction backups"*

...perform the corresponding sequence below.

---

## Pre-flight Sequence

Complete all five steps before presenting anything to the user. Do not write anything yet.

### U1 — Read the installed instructions

Read `.github/copilot-instructions.md` in the **user's current project**.

Read `.github/copilot-version.md` in the **user's current project**.

Extract:

- **Installed version**: from `.github/copilot-version.md` (must be semver `x.y.z`).
  - If `.github/copilot-version.md` is absent or invalid, treat installed version as `unknown` and proceed with a full comparison.
- **Applied date**: the `Applied` value from that line.
- **Updated date**: the `Updated` value if present (set by a previous update run).
- **Section fingerprints**: parse the `<!-- section-fingerprints ... -->` block from `.github/copilot-version.md` into a map of `§N → stored_fingerprint`. If the block is absent (legacy installation), set `fingerprints_available = false`.
- **§10 content**: the entire `## §10 — Project-Specific Overrides` section — this is preserved unconditionally and never included in the diff.

### U2 — Fetch the current template version

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/VERSION.md
```

If the fetched version **equals** the installed version → report:

```text
Already up to date (version X.Y.Z, applied YYYY-MM-DD). No changes available.
To run a full comparison anyway, say "Force check instruction updates".
```

And stop. No further action.

If the installed version is `unknown`, proceed with a full comparison regardless of the version check.

### U3 — Fetch the migration registry and changelog

> **Parallelization**: U3 and U4 fetches are independent — execute all fetches across both steps in a single parallel batch (up to 4 URLs).

Fetch both files in parallel:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/MIGRATION.md
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/CHANGELOG.md
```

From **MIGRATION.md**, extract all version entries **newer than the installed version**. These provide structured metadata: sections changed, companion files added/updated, new placeholders, breaking changes, and manual actions. This data drives the per-version change groups in the Pre-flight Report.

From **CHANGELOG.md**, extract all changelog entries **newer than the installed version** for the "What's new" narrative. If the installed version is `unknown`, include the full changelog.

### U4 — Fetch templates for three-way merge

Fetch **two** copies of the template:

**A — Old baseline** (template at the installed version):

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/v<INSTALLED_VERSION>/template/copilot-instructions.md
```

If the installed version has no tag (no `v<INSTALLED_VERSION>` tag exists), or the fetch fails, set `OLD_BASELINE = null`. The protocol will fall back to a two-way diff (new template vs installed file).

**B — New template** (latest):

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/copilot-instructions.md
```

### U5 — Build the change manifest (version-walk)

#### Step 1 — Identify intermediate versions

Using the MIGRATION.md entries from U3, list all tagged versions between the installed version (exclusive) and the new version (inclusive), in ascending order. These are the **version steps** the user is traversing.

Example: installed `v1.4.0`, new `v3.0.0` → version steps: `v2.0.0`, `v2.1.0`, `v2.2.0`, `v3.0.0`.

#### Step 2 — Section-by-section comparison

For each section §1–§9 (§10 is excluded entirely):

1. Extract the section from the **installed file** (U1).
2. Extract the section from the **old baseline** (U4-A), if available.
3. Extract the section from the **new template** (U4-B).

**Determine user modification** (fingerprint-based, deterministic):

If `fingerprints_available` (from U1), compute the current fingerprint for each section:

```bash
fp=$(awk "/^## §${i} —/{found=1; next} /^## §/{if(found) exit} found{print}" \
  .github/copilot-instructions.md | sha256sum | cut -c1-12)
```

Compare `current_fp` vs `stored_fp` from U1:

- `current_fp = stored_fp` → **user did NOT modify** this section since last setup/update.
- `current_fp ≠ stored_fp` → **user modified** this section.

If `fingerprints_available = false` (legacy installation): treat all sections as "user modification unknown" — fall back to the heuristic rules in the **Legacy fallback** paragraph below.

**Determine upstream change**:

- If OLD_BASELINE available: compare old baseline section vs new template section (ignoring resolved `{{PLACEHOLDER}}` values).
- If OLD_BASELINE unavailable: compare installed section vs new template section (ignoring resolved `{{PLACEHOLDER}}` values).
- Sections are equivalent (`≈`) if they match after stripping resolved placeholder values and normalising whitespace.

**Assign status** using the combined result:

| Status | Condition | Default action |
|--------|-----------|----------------|
| `UNCHANGED` | User did not modify AND upstream did not change | Skip silently |
| `UPDATED` | User did not modify AND upstream changed | Offer to apply |
| `USER_MODIFIED` | User modified AND upstream changed | Flag explicitly; require user decision |
| `USER_ONLY` | User modified AND upstream did not change | Skip silently; preserve user's version |
| `NEW_SECTION` | Section exists in new template but not in installed file | Offer to add |
| `REMOVED_FROM_TEMPLATE` | Section exists in installed file but not in new template | Warn; preserve by default |
| `BREAKING` | Section is marked as breaking in any intermediate MIGRATION.md entry | Flag with ⚠ marker; require explicit confirmation |

**Legacy fallback** (when `fingerprints_available = false` AND `OLD_BASELINE = null`): compare installed vs new template directly. A section that differs is `UPDATED` unless the installed version has been substantially modified beyond placeholder resolution (e.g., added paragraphs, changed rules, different table rows), in which case mark `USER_MODIFIED`. This heuristic path is only reached for installations predating fingerprint support.

#### Step 3 — Companion file manifest

Walk through each intermediate version's MIGRATION.md entry and collect all companion files:

| Category | Examples |
|----------|---------|
| Agent files | `.github/agents/*.agent.md` |
| Skills | `.github/skills/*/SKILL.md` |
| Hook config | `.github/hooks/copilot-hooks.json` |
| Hook scripts | `.github/hooks/scripts/*.sh` |
| MCP config | `.vscode/mcp.json` |
| Path instructions | `.github/instructions/*.instructions.md` |
| Prompt files | `.github/prompts/*.prompt.md` |
| Workspace identity | `.copilot/workspace/*.md` |

For each companion file, determine:

| Companion status | Condition | Action |
|-----------------|-----------|--------|
| `NEW` | File does not exist in user's project | Offer to create |
| `UPDATABLE` | File exists; template version is newer | Offer to update (show diff summary) |
| `CURRENT` | File exists and matches the latest template | Skip silently |
| `USER_CUSTOMISED` | File exists but differs from both old and new template | Flag; let user decide |

#### Step 4 — Accumulate metadata

From the intermediate MIGRATION.md entries, collect:

- **Breaking changes**: any version with `Breaking = Yes` — list the version and the breaking change description.
- **New placeholders**: all `{{PLACEHOLDER}}` tokens introduced across the version range — list each with its target section.
- **Manual actions**: all manual action items from intermediate versions — deduplicate and list.

#### Step 5 — Final check

**Sections permanently excluded from the change manifest** (guardrail — never diff, never modify):

- `## §10 — Project-Specific Overrides` — entire section and all subsections
- `### User Preferences` — entire subsection
- `### Additional project notes` — entire subsection
- Any block containing `<!-- migrated -->`
- Any block containing `<!-- user-added -->`
- Any resolved placeholder value (e.g., `bun test` is never reverted to `{{TEST_COMMAND}}`)

If the total count of `UPDATED`, `NEW_SECTION`, `USER_MODIFIED`, and `BREAKING` section items is zero AND no companion files need updating, report "No applicable changes found" and stop.

#### Step 6 — Fast-path for companion-only updates

If **all** §1–§9 sections have status `UNCHANGED` or `USER_ONLY` (no instruction changes from upstream) **and** one or more companion files are `NEW` or `UPDATABLE` **and** no breaking changes exist:

1. Skip the full Pre-flight Report. Instead, show a compact summary:

   ```text
   COMPANION-ONLY UPDATE — vOLD → vNEW

   No instruction section changes. <N> companion file(s) to update:
   <list each file with status (NEW / UPDATABLE)>

   Apply all? [Y / N / list to pick individually]
   ```

2. If user confirms, write the companion files directly — no section-by-section walkthrough needed.
3. Update the version file and fingerprints (Post-update step 1).
4. Append to CHANGELOG.md as normal.

If the user declines or picks individually, proceed to the standard Pre-flight Report.

---

## Pre-flight Report

After completing U1–U5, present this report. Do not write anything yet.

Structure the report as plain text with these sections in order:

1. **Header** — installed version, latest version, version steps traversed, status summary
2. **Breaking changes** — list each breaking version with one-line description, or "None."
3. **What's new** — grouped by version (newest first) from CHANGELOG, one bullet per notable change
4. **Section-by-section diff** — table with columns: Status, Section (§1–§10), Result (UNCHANGED/UPDATED/BREAKING/USER_MODIFIED/PROTECTED), Changed in (version). Status icons: ✓ update, ! user-modified, ⚠ breaking, [§10] protected
5. **Companion files** — table with columns: Status, File, Action (NEW/UPDATABLE/CUSTOM), Since. Icons: + new, ↑ update available, ~ user-customised
6. **New placeholders** — list `{{PLACEHOLDER}}` tokens introduced, or "None."
7. **User-modified sections** — list with one-line description, or "None detected."
8. **Manual actions required** — accumulated from MIGRATION.md across all intermediate versions, or "None."
9. **Guardrail check** — confirm §10, User Preferences block, migrated/user-added content, and resolved placeholder values are all PROTECTED
10. **Backup** — note that backup will be created automatically before any writes
11. **Prompt** — `U` (update all) / `S` (skip) / `C` (customise per-section and per-companion-file)

Wait for the user's response before proceeding.

---

## Pre-write Backup

**This step is automatic and mandatory. It runs immediately after the user's first confirmatory response (U, C + final "yes", or any write-triggering input) and before the first file write. It does not run for path S.**

### What to back up

1. **`.github/copilot-instructions.md`** — the full installed instructions file, exactly as it exists right now.

2. **Companion files that will be modified** — any companion file with status `UPDATABLE` or `USER_CUSTOMISED` from the change manifest. Copy each to the backup directory preserving its relative path.

For companion files with status `NEW`, no backup is needed (the file does not exist yet).

### Where to store it

Create directory `.github/archive/pre-update-<TODAY>-v<INSTALLED_VERSION>/` (append counter `-2`, `-3` if exists). Inside, create:

1. **`copilot-instructions.md`** — exact copy of current `.github/copilot-instructions.md`
2. **`BACKUP-MANIFEST.md`** — table with: backup date, installed version, target version, trigger, files backed up. Include list of changed sections and restore instructions (*"Restore instructions from backup"*).

Print `Backup created at .github/archive/pre-update-<TODAY>-v<INSTALLED_VERSION>/` then continue with writes — no user interaction required.

---

## Decision paths

### U — Update all

> **Pre-write Backup runs before this path begins.**

Apply all `UPDATED`, `NEW_SECTION`, and `BREAKING` section items, plus all `NEW` and `UPDATABLE` companion files, in one pass.

#### Section updates

1. For each `UPDATED` or `BREAKING` section:
   - Replace the installed section with the new template section.
   - Re-apply resolved placeholder values: scan the installed §10 placeholder table and re-substitute any `{{PLACEHOLDER}}` tokens that appear in the new section text.
   - If the installed section contained any `<!-- migrated -->` or `<!-- user-added -->` blocks, re-insert them after the updated content with the comment: `<!-- preserved from pre-update version -->`.

2. For each `NEW_SECTION`:
   - Insert the section into the file at the correct ordinal position.
   - Apply placeholder resolution from §10.

3. For each `USER_MODIFIED` section:
   - Do **not** modify the installed content.
   - Append a comment immediately after the section heading:

     ```html
     <!-- update-note: template updated this section to vX.Y.Z but your
          version was user-modified and is preserved. Review UPDATE.md
          if you want to apply the upstream change manually. -->
     ```

4. For each `USER_ONLY` section: leave unchanged (no comment needed).

#### Companion file updates

1. For each `NEW` companion file:
   - Fetch from the template repo at the latest tag:
     `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/<TAG>/<template-source-path>`
   - Write to the destination path in the user's project.
   - If the file contains `{{PLACEHOLDER}}` tokens, resolve using §10 values where available.

2. For each `UPDATABLE` companion file:
   - Fetch the latest version from the template repo.
   - Replace the file in the user's project. If the file is a skill with user-added content, merge carefully.

3. For each `USER_CUSTOMISED` companion file:
   - Do **not** modify the installed content.
   - Report which companion file was skipped and why.

#### New placeholders

1. If any `{{PLACEHOLDER}}` tokens from MIGRATION.md are unresolved in §10:
   - List each unresolved placeholder with its default value (if known).
   - Ask the user to provide values, or accept defaults.
   - Add resolved values to the §10 placeholder table.

2. Proceed to **Post-update steps**.

### S — Skip

No writes. No backup.

```text
No changes made. Your instructions remain at version X.Y.Z.
To apply updates later, say "Update your instructions".
```

### C — Customise

Walk through each `UPDATED`, `BREAKING`, `NEW_SECTION`, and `USER_MODIFIED` section item one at a time. For each item, present:

```text
Section change <N> of <total>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Section:  §<N> <Section name>
Status:   <UPDATED / BREAKING / NEW_SECTION / USER_MODIFIED>
Changed in: <version(s) from MIGRATION.md>

WHAT CHANGED:
<Copilot's one-paragraph plain-English summary of what is different
 between the installed and new template versions of this section.
 For BREAKING sections, explain the breaking change impact.>

--- CURRENT (installed) ---
<Relevant excerpt — up to 20 lines — from the installed instructions.>

+++ NEW (template v X.Y.Z) +++
<Relevant excerpt — up to 20 lines — from the new template.>

HOW TO HANDLE THIS CHANGE?
  A — Apply      Replace this section with the new template version.
  B — Skip       Keep your current version. No change made.
  C — Customise  I'll show you the full new text so you can tailor
                 it before it's applied.
```

Wait for the user's response (A, B, or C) before moving to the next item.

**After all section items are reviewed**, walk through companion files:

```text
Companion file <N> of <total>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File:     <destination path>
Status:   <NEW / UPDATABLE / USER_CUSTOMISED>
Since:    <version that introduced it>

WHAT THIS FILE DOES:
<One-sentence description of the companion file's purpose.>

  A — Apply      <Create / Update> this companion file.
  B — Skip       Leave this file unchanged (or uncreated).
```

Wait for the user's response before moving to the next companion file.

**If the user chooses C (Customise for a specific change)**:

1. Show the full new section text.
2. Say: *"Describe the adjustments you want, or type your replacement text in full."*
3. Accept the user's input. If they described changes rather than providing full text, produce the adjusted version and confirm: *"Here is the adjusted version — shall I apply this?"*
4. On confirmation, record the customised version. Say: *"Customised version recorded. Moving to the next change."*

**After all items are reviewed**, present a final confirmation:

```text
Review complete.

  Sections:
    Apply:      <list of sections, or "none">
    Skip:       <list of sections, or "none">
    Customise:  <list of sections with one-line note, or "none">

  Companion files:
    Apply:      <list of files, or "none">
    Skip:       <list of files, or "none">

Shall I write these changes now? (yes / no)
```

> **Pre-write Backup runs here — immediately after "yes", before the first write.**

---

## Applicability guardrails

Apply these checks **before writing any section**, regardless of the decision path:

| Guardrail | What to check | If triggered |
|-----------|---------------|--------------|
| **Placeholder leakage** | New section contains `{{PLACEHOLDER}}` tokens | Re-resolve using the installed §10 placeholder table. If a value is missing from the table, leave the token as-is and add it to the anomaly list. |
| **§10 collision** | A change would overwrite any content in `## §10 —` | Skip the change automatically. Log in the anomaly list. |
| **Migrated content** | Section contains `<!-- migrated -->` blocks | Preserve those blocks verbatim; write the update around them. |
| **User-added content** | Section contains `<!-- user-added -->` blocks | Preserve those blocks verbatim; write the update around them. |
| **User preference conflict** | New section changes behaviour already configured in `### User Preferences` | Flag to user before applying: show both the new template instruction and the user's current preference. Ask which takes precedence. |
| **Metric threshold conflict** | New section changes default threshold values (LOC warn/high, dep budget) that were already resolved in §10 | Show the current resolved values alongside the new template defaults. Ask user which to keep. |

---

## Post-update steps

After all changes are confirmed and written:

### 1 — Update the version file and section fingerprints

Recompute section fingerprints for the updated instructions file:

```bash
echo "<!-- section-fingerprints"
for i in $(seq 1 9); do
  fp=$(awk "/^## §${i} —/{found=1; next} /^## §/{if(found) exit} found{print}" \
    .github/copilot-instructions.md | sha256sum | cut -c1-12)
  echo "§${i}=${fp}"
done
echo "-->"
```

Write to `.github/copilot-version.md`:

```markdown
# Installed Template Version

<!-- This file is read by the Update agent to compare your installed version against the upstream template. -->
<!-- Do not edit manually — it is updated automatically during instruction updates. -->

NEW

<!-- section-fingerprints
§1=<fingerprint>
...
§9=<fingerprint>
-->
```

Replace `NEW` with the new version string. Replace each `<fingerprint>` with the computed value. If the terminal is unavailable, omit the fingerprints block.

Do **not** run `scripts/sync-version.sh` — that script is template-repo infrastructure and does not exist in consumer projects.

### 2 — Append to CHANGELOG.md

Add under `## [Unreleased]` (or create that section if absent):

```markdown
### Changed
- Copilot instructions updated from template v<OLD> to v<NEW> (<N> version steps).
  Sections updated: <list>. Skipped: <list>.
  Companion files applied: <list, or "none">.
  Backup at: `.github/archive/pre-update-TODAY-v<OLD>/`
```

### 3 — Print the confirmation

```text
Updated! ✓

  Template version:  vOLD → vNEW (<N> version steps)
  Sections updated:  <N>
  Sections skipped:  <N>
  Sections custom:   <N>
  Companion files:   <N> created, <N> updated, <N> skipped

  Breaking changes:  <list of breaking versions — or "none">

  Protected (untouched in all cases):
    §10 Project-Specific Overrides
    User Preferences block
    Migrated / user-added content blocks
    Resolved placeholder values

  Backup:  .github/archive/pre-update-TODAY-v<OLD>/
           (restore anytime: say "Restore instructions from backup")

  <anomaly list, if any — or omit this block>
  <manual actions, if any — or omit this block>

  CHANGELOG.md updated.
```

---

## Restore from backup

### Trigger phrases

- *"Restore instructions from backup"*
- *"Roll back the instructions update"*
- *"List instruction backups"*

### Restore sequence

#### R1 — List available backups

Scan the `.github/archive/` directory for subdirectories matching the pattern `pre-update-*`.

If none exist, report:

```text
No instruction backups found in .github/archive/.
Backups are created automatically when you run "Update your instructions".
```

And stop.

If backups exist, list them:

```text
Available instruction backups:

  1.  pre-update-2026-02-19-v1.0.0/   (installed: 2026-02-19)
  2.  pre-update-2026-03-10-v1.1.0/   (installed: 2026-03-10)
  ...

Which backup would you like to restore? Enter a number, or say "cancel".
```

#### R2 — Show the backup manifest

After the user selects a backup, read `BACKUP-MANIFEST.md` from that directory and show it:

```text
Selected: pre-update-<DATE>-v<VERSION>/

  Backed up:  <DATE>
  Version:    <VERSION>
  Changed sections: <list>

Restoring this backup will replace your current .github/copilot-instructions.md.
Your current file will be backed up first at:
  .github/archive/pre-restore-<TODAY>-<CURRENT_VERSION>/

Proceed? (yes / no)
```

Wait for confirmation.

#### R3 — Back up the current file before restoring

Before overwriting anything, create a new backup of the *current* instructions — the ones that are about to be replaced — using the same backup format:

```text
.github/archive/pre-restore-<TODAY>-v<CURRENT_VERSION>/
  copilot-instructions.md    ← copy of the file being replaced
  BACKUP-MANIFEST.md         ← records this as a pre-restore snapshot
```

This means restoration is always reversible.

#### R4 — Restore

Copy `copilot-instructions.md` from the selected backup directory to `.github/copilot-instructions.md`, replacing the current file exactly.

#### R5 — Record the restoration

Append to `CHANGELOG.md` under `## [Unreleased]`:

```markdown
### Reverted
- Copilot instructions restored from backup `pre-update-<DATE>-v<VERSION>`.
  Pre-restore snapshot saved at `.github/archive/pre-restore-<TODAY>-v<CURRENT_VERSION>/`.
```

#### R6 — Confirmation

```text
Restored! ✓

  Restored from: .github/archive/pre-update-<DATE>-v<VERSION>/
  Pre-restore snapshot saved at:
    .github/archive/pre-restore-<TODAY>-v<CURRENT_VERSION>/

  CHANGELOG.md updated.
  (To undo this restore, say "Restore instructions from backup" and
   select the pre-restore snapshot.)
```

---

## Guardrail quick reference

**NEVER modified** by an update, regardless of user choice:

| Item | Reason |
|------|--------|
| `## §10 — Project-Specific Overrides` (entire section) | Contains project identity — not generic template content |
| `### User Preferences` (entire subsection) | Set by the user during setup interview; only the user changes these |
| `### Additional project notes` (entire subsection) | Copilot-discovered conventions for this project specifically |
| Any block containing `<!-- migrated -->` | Pre-existing conventions migrated from before the template was adopted |
| Any block containing `<!-- user-added -->` | Explicitly user-authored additions |
| Resolved placeholder values | `bun test` must never revert to `{{TEST_COMMAND}}` |

**Flagged for user decision** (not automatically modified):

| Item | Reason |
|------|--------|
| `USER_MODIFIED` sections | User may have intentionally improved on the template |
| Sections with `<!-- update-note: ... -->` comments | Previously skipped or user-modified in a past update run |
| Metric thresholds that differ from template defaults | May have been deliberately tuned for this project |
| Sections where the update conflicts with a User Preference | User preference takes precedence unless the user explicitly overrides it |

---

## Force check

If the user says *"Force check instruction updates"*, bypass the version equality check in U2 and run a full section-by-section comparison even if versions appear equal. This is useful if the user manually edited their version stamp or wants to verify their instructions are in sync.

---

> **Note for Copilot**: You are a guest reading `asafelobotomy/copilot-instructions-template`. All writes go to the **user's current project**. Do not create, modify, or delete any files in this template repo.
