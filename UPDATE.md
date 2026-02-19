# Update Protocol — copilot-instructions-template

> **For Copilot**: This document defines the update process. Follow every step precisely. Do **not** write anything to the user's project until the user has confirmed the update plan after the Pre-flight Report.
>
> **For the human**: Open a Copilot chat and say one of the trigger phrases below. Copilot will fetch this document, check for updates, and walk you through the process.

---

## Trigger phrases

When a user says any of the following in a project that already has Copilot instructions installed:

- *"Update your instructions"*
- *"Check for instruction updates"*
- *"Update from copilot-instructions-template"*
- *"Sync instructions with the template"*
- *"Check the template for updates"*
- *"Force check instruction updates"* *(bypasses version equality check — see end of document)*

...perform the **Pre-flight Sequence** below.

---

## Pre-flight Sequence

Complete all five steps before presenting anything to the user. Do not write anything yet.

### U1 — Read the installed instructions

Read `.github/copilot-instructions.md` in the **user's current project**.

Extract:
- **Installed version**: from the line `> **Template version**: X.Y.Z | **Applied**: DATE`.
  - If this line is absent, treat installed version as `unknown` and proceed with a full comparison.
- **Applied date**: the `Applied` value from that line.
- **Updated date**: the `Updated` value if present (set by a previous update run).
- **§10 content**: the entire `## 10. Project-Specific Overrides` section — this is preserved unconditionally and never included in the diff.
- **User-modified sections**: any section in §1–§9 whose content has diverged from a standard template section in a way that goes beyond placeholder resolution (Copilot's judgement). Flag these explicitly in the change manifest.

### U2 — Fetch the current template version

```
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/VERSION
```

If the fetched version **equals** the installed version → report:

```
Already up to date (version X.Y.Z, applied YYYY-MM-DD). No changes available.
To run a full comparison anyway, say "Force check instruction updates".
```

And stop. No further action.

If the installed version is `unknown`, proceed with a full comparison regardless of the version check.

### U3 — Fetch the template changelog

```
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/CHANGELOG.md
```

Extract all changelog entries for versions **newer than the installed version**. If the installed version is `unknown`, include the full changelog. These entries form the "What's new" section of the Pre-flight Report.

### U4 — Fetch the new template

```
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/copilot-instructions.md
```

### U5 — Build the change manifest

Compare the new template (U4) section by section against the installed instructions (U1). Work through §1–§9 only. §10 is excluded from comparison entirely.

For each section, assign a status:

| Status | Condition | Default action |
|--------|-----------|----------------|
| `UNCHANGED` | Section text is functionally identical (ignoring resolved placeholder values) | Skip silently |
| `UPDATED` | Section exists in both files; template text has changed | Offer to apply |
| `NEW_SECTION` | Section exists in the new template but not in the installed file | Offer to add |
| `USER_MODIFIED` | Section exists in both; installed version has been substantially modified beyond placeholder resolution AND differs from the new template | Flag explicitly; require explicit user decision |
| `REMOVED_FROM_TEMPLATE` | Section exists in the installed file but not in the new template | Warn; preserve by default |

**Sections permanently excluded from the change manifest** (guardrail — never diff, never modify):

- `## 10. Project-Specific Overrides` — entire section and all subsections
- `### User Preferences` — entire subsection
- `### Additional project notes` — entire subsection
- Any block containing `<!-- migrated -->`
- Any block containing `<!-- user-added -->`
- Any resolved placeholder value (e.g., `bun test` is never reverted to `{{TEST_COMMAND}}`)

If the total count of `UPDATED`, `NEW_SECTION`, and `USER_MODIFIED` items is zero, report "No applicable changes found" and stop.

---

## Pre-flight Report

After completing U1–U5, present this report. Do not write anything yet.

```
╔══════════════════════════════════════════════════════════════════╗
║  INSTRUCTION UPDATE REPORT                                       ║
╚══════════════════════════════════════════════════════════════════╝

  Installed version:   X.Y.Z  (applied: YYYY-MM-DD)
  Latest version:      X.Y.Z
  Status:              <N> change(s) available

  ────────────────────────────────────────────────────────────────
  WHAT'S NEW  (from CHANGELOG)
  ────────────────────────────────────────────────────────────────
  <list each changelog entry for versions newer than installed,
   formatted as bullet points — one line each>

  ────────────────────────────────────────────────────────────────
  SECTION-BY-SECTION DIFF
  ────────────────────────────────────────────────────────────────
  ┌──────┬───────────────────────────────────┬──────────────────┐
  │      │ Section                           │ Status           │
  ├──────┼───────────────────────────────────┼──────────────────┤
  │      │ §1 Development Philosophy         │ UNCHANGED        │
  │  ✓   │ §2 Agent Modes                    │ UPDATED          │
  │      │ §3 Standardised Work Baselines    │ UNCHANGED        │
  │  !   │ §4 Coding Conventions             │ USER_MODIFIED    │
  │      │ §5 Testing                        │ UNCHANGED        │
  │      │ §6 Waste Categories               │ UNCHANGED        │
  │      │ §7 Documentation Ritual           │ UNCHANGED        │
  │      │ §8 Living Update Protocol         │ UNCHANGED        │
  │      │ §9 Subagent Delegation            │ UNCHANGED        │
  │ [§10]│ Project-Specific Overrides        │ PROTECTED        │
  └──────┴───────────────────────────────────┴──────────────────┘
  (✓ = update available | ! = user-modified | [§10] = always protected)

  ────────────────────────────────────────────────────────────────
  USER-MODIFIED SECTIONS  (require your explicit decision)
  ────────────────────────────────────────────────────────────────
  <list any USER_MODIFIED sections with a one-line description of
   what differs from the template baseline — or "None detected.">

  ────────────────────────────────────────────────────────────────
  GUARDRAIL CHECK
  ────────────────────────────────────────────────────────────────
  §10 Project-Specific Overrides:  PROTECTED (never modified)
  User Preferences block:          PROTECTED (never modified)
  Migrated / user-added content:   PROTECTED (never modified)
  Resolved placeholder values:     PROTECTED (never reverted)

  ────────────────────────────────────────────────────────────────
  HOW DO YOU WANT TO PROCEED?
  ────────────────────────────────────────────────────────────────
  U — Update all    Apply all available changes at once.
  S — Skip          Do nothing. Keep current instructions unchanged.
  C — Customise     Review and decide on each change individually.

  Type U, S, or C:
```

Wait for the user's response before proceeding.

---

## Decision paths

### U — Update all

Apply all `UPDATED` and `NEW_SECTION` items in one pass.

1. For each `UPDATED` section:
   - Replace the installed section with the new template section.
   - Re-apply resolved placeholder values: scan the installed §10 placeholder table and re-substitute any `{{PLACEHOLDER}}` tokens that appear in the new section text.
   - If the installed section contained any `<!-- migrated -->` or `<!-- user-added -->` blocks, re-insert them after the updated content with the comment: `<!-- preserved from pre-update version -->`.

2. For each `NEW_SECTION`:
   - Insert the section into the file at the correct ordinal position.
   - Apply placeholder resolution from §10.

3. For each `USER_MODIFIED` section:
   - Do **not** modify the installed content.
   - Append a comment immediately after the section heading:
     ```
     <!-- update-note: template updated this section to vX.Y.Z but your
          version was user-modified and is preserved. Review UPDATE.md
          if you want to apply the upstream change manually. -->
     ```

4. Proceed to **Post-update steps**.

### S — Skip

Do nothing. State:

```
No changes made. Your instructions remain at version X.Y.Z.
To apply updates later, say "Update your instructions".
```

### C — Customise

Walk through each `UPDATED`, `NEW_SECTION`, and `USER_MODIFIED` item one at a time. For each item, present:

```
Change <N> of <total>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Section:  §<N> <Section name>
Status:   <UPDATED / NEW_SECTION / USER_MODIFIED>

WHAT CHANGED:
<Copilot's one-paragraph plain-English summary of what is different
 between the installed and new template versions of this section.>

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

**If the user chooses C (Customise for a specific change)**:

1. Show the full new section text.
2. Say: *"Describe the adjustments you want, or type your replacement text in full."*
3. Accept the user's input. If they described changes rather than providing full text, produce the adjusted version and confirm: *"Here is the adjusted version — shall I apply this?"*
4. On confirmation, record the customised version. Say: *"Customised version recorded. Moving to the next change."*

**After all items are reviewed**, present a final confirmation:

```
Review complete.

  Apply:      <list of sections, or "none">
  Skip:       <list of sections, or "none">
  Customise:  <list of sections with one-line note, or "none">

Shall I write these changes now? (yes / no)
```

Wait for confirmation before writing anything.

---

## Applicability guardrails

Apply these checks **before writing any section**, regardless of the decision path:

| Guardrail | What to check | If triggered |
|-----------|---------------|--------------|
| **Placeholder leakage** | New section contains `{{PLACEHOLDER}}` tokens | Re-resolve using the installed §10 placeholder table. If a value is missing from the table, leave the token as-is and add it to the anomaly list. |
| **§10 collision** | A change would overwrite any content in `## 10.` | Skip the change automatically. Log in the anomaly list. |
| **Migrated content** | Section contains `<!-- migrated -->` blocks | Preserve those blocks verbatim; write the update around them. |
| **User-added content** | Section contains `<!-- user-added -->` blocks | Preserve those blocks verbatim; write the update around them. |
| **User preference conflict** | New section changes behaviour already configured in `### User Preferences` | Flag to user before applying: show both the new template instruction and the user's current preference. Ask which takes precedence. |
| **Metric threshold conflict** | New section changes default threshold values (LOC warn/high, dep budget) that were already resolved in §10 | Show the current resolved values alongside the new template defaults. Ask user which to keep. |

---

## Post-update steps

After all changes are confirmed and written:

### 1 — Update the version stamp

Find the line: `> **Template version**: OLD | **Applied**: DATE`

Update it to:
```
> **Template version**: NEW | **Applied**: ORIGINAL_DATE | **Updated**: TODAY
```

- The original `Applied` date is preserved — it is the record of the initial setup date.
- `Updated` is set to today (ISO 8601). If a previous `Updated` date exists, replace it.

### 2 — Append to JOURNAL.md

```markdown
## TODAY — Template updated vOLD → vNEW

**Applied**: <comma-separated list of updated/added sections, or "none">
**Skipped**: <comma-separated list, or "none">
**Customised**: <comma-separated list with one-line note per item, or "none">
```

### 3 — Append to CHANGELOG.md

Add under `## [Unreleased]` (or create that section if absent):

```markdown
### Changed
- Copilot instructions updated from template v<OLD> to v<NEW>.
  Sections updated: <list>. Skipped: <list>.
```

### 4 — Print the confirmation

```
Updated! ✓

  Template version:  vOLD → vNEW
  Sections updated:  <N>
  Sections skipped:  <N>
  Sections custom:   <N>

  Protected (untouched in all cases):
    §10 Project-Specific Overrides
    User Preferences block
    Migrated / user-added content blocks
    Resolved placeholder values

  <anomaly list, if any — or omit this block>

  JOURNAL.md and CHANGELOG.md updated.
```

---

## Guardrail quick reference

**NEVER modified** by an update, regardless of user choice:

| Item | Reason |
|------|--------|
| `## 10. Project-Specific Overrides` (entire section) | Contains project identity — not generic template content |
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
