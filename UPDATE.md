# Update Protocol — copilot-instructions-template

<!-- markdownlint-disable MD022 MD031 MD032 MD058 -->

> **For Copilot**: Follow every step precisely. Do **not** write until the user confirms after the Pre-flight Report or the Factory restore confirmation — except the automatic backup (always created silently before first write).
>
> **For the human**: Say one of the trigger phrases below in a Copilot chat.
>
> **ask_questions convention**: Use `ask_questions` for ALL user-facing decisions. Each block must have `header:`, `question:`, `options:` with `- label:` entries.

---

## Trigger phrases
- *"Update your instructions"* / *"Check for instruction updates"* / *"Update from copilot-instructions-template"* / *"Sync instructions with the template"* / *"Check the template for updates"*
- *"Force check instruction updates"* (bypasses version equality — see Force check section)
- *"Factory restore instructions"* / *"Reinstall instructions from scratch"*
- *"Restore instructions from backup"* / *"Roll back the instructions update"* / *"List instruction backups"*

Standard update phrases check `https://github.com/asafelobotomy/copilot-instructions-template` for a newer version.
Factory restore phrases disregard current repo instructions, back up every managed surface, remove those surfaces from the working tree, and reinstall the latest upstream setup payload from scratch.

If the user says *"Factory restore instructions"* or *"Reinstall instructions from scratch"*, skip U1-U5b and jump to Factory restore.

---

## Pre-flight Sequence
Complete all steps before presenting anything. Do not write yet.

### U1 — Read the installed instructions
Read `.github/copilot-instructions.md` and `.github/copilot-version.md`. Extract:

- **Installed version** (semver; `unknown` if absent/invalid), **Applied/Updated dates**
- **Section fingerprints**: `<!-- section-fingerprints -->` → `§N → stored_fp`. If absent: `fingerprints_available = false`
- **File manifest**: `<!-- file-manifest -->` → managed-path hashes. If absent: `file_manifest_available = false`
- **Setup answers**: `<!-- setup-answers -->` → `PLACEHOLDER → value`. If absent: `{}`
- **§10 content**: entire `## §10 — Project-Specific Overrides` — preserved unconditionally, never diffed

Supported in-place updates require a tagged installed version `v3.4.0` or newer plus all three metadata blocks in `.github/copilot-version.md`: `section-fingerprints`, `file-manifest`, and `setup-answers`.

If the installed version is `unknown`, earlier than `v3.4.0`, or any required metadata block is missing, stop the normal update flow and direct the user to **Factory restore** instead of attempting a heuristic merge.

### U2 — Fetch the current template version
```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/VERSION.md
```

If fetched = installed → "Already up to date (vX.Y.Z). Say 'Force check instruction updates' for full comparison." → stop.
If installed = `unknown`, do not continue with the version-walk. Direct the user to **Factory restore**.

### U3 — Fetch migration registry and changelog
> **Parallelization**: U3, U3b, and U4 fetches are independent — batch all.

Always fetch:
```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/MIGRATION.md
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/CHANGELOG.md
```
From `MIGRATION.md`: entries newer than installed (sections changed, companions, placeholders, breaking changes, manual actions). From `CHANGELOG.md`: entries newer than installed for narrative.

### U3b — GitHub API compare (authoritative file diff)
```text
GET https://api.github.com/repos/asafelobotomy/copilot-instructions-template/compare/v{INSTALLED_VERSION}...main
```

Parse `files[]` → record `filename`, `status`, `previous_filename`. Store as `API_FILE_DIFF`.

**404 / no tag**: stop the normal update flow and direct the user to **Factory restore**. Supported installs must have a tagged installed version.
**Fallback** (API unavailable): set `API_FILE_DIFF = null`, use the fetched migration registries only.

### U4 — Fetch templates for three-way merge
- **Old baseline**: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/v<INSTALLED_VERSION>/template/copilot-instructions.md`
- **New template**: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/copilot-instructions.md`

If the old baseline fetch fails, stop and direct the user to retry later or use **Factory restore**. Supported in-place updates require a tagged baseline.

### U5 — Build the change manifest (version-walk)
#### Step 1 — Identify intermediate versions
From the fetched migration registries, list versions between installed (exclusive) and new (inclusive), ascending.
#### Step 2 — Section-by-section comparison
For each §1–§9 (§10 excluded):

**User modification** (fingerprint-based): compute fingerprint if `fingerprints_available`:

```bash
fp=$(awk "/^## §${i} —/{found=1; next} /^## §/{if(found) exit} found{print}" \
  .github/copilot-instructions.md | sha256sum | cut -c1-12)
```

Match = not modified. Mismatch = modified. If unavailable, stop and direct the user to **Factory restore**.

**Upstream change**: compare old baseline vs new template (ignore resolved placeholders).

**Status assignment**:

| Status | Condition | Action |
|--------|-----------|--------|
| `UNCHANGED` | No user mod, no upstream change | Skip |
| `UPDATED` | No user mod, upstream changed | Offer |
| `USER_MODIFIED` | User mod, upstream changed | Flag; user decides |
| `USER_ONLY` | User mod, no upstream change | Skip |
| `NEW_SECTION` | In new template only | Offer |
| `REMOVED_FROM_TEMPLATE` | In installed only | Warn; preserve |
| `BREAKING` | Marked breaking in MIGRATION.md | Flag ⚠; confirm |
#### Step 3 — Companion file manifest (API-driven)
**Primary**: `API_FILE_DIFF` filtered through Path Mapping Table. **Secondary**: the fetched migration registries for metadata. Include paths from `API_FILE_DIFF` even if absent from the migration entries.

##### Path Mapping Table
| Template repo glob | Consumer destination |
|-------------------|---------------------|
| `.github/agents/*.agent.md` | `.github/agents/*.agent.md` (verbatim) |
| `.github/agents/*.json` | `.github/agents/*.json` (verbatim support files) |
| `template/skills/*/SKILL.md` | `.github/skills/*/SKILL.md` |
| `template/hooks/**` | `.github/hooks/**` |
| `template/instructions/*` | `.github/instructions/*` |
| `template/prompts/*` | `.github/prompts/*` |
| `template/workspace/**` | `.copilot/workspace/**` |
| `template/copilot-setup-steps.yml` | `.github/workflows/copilot-setup-steps.yml` |
| `template/vscode/settings.json` | `.vscode/settings.json` (only if the consumer already has this file from setup) |
| `template/vscode/extensions.json` | `.vscode/extensions.json` (only if the consumer already has this file from setup) |
| `template/vscode/mcp.json` | `.vscode/mcp.json` (when MCP is enabled) |
| `template/CLAUDE.md` | `CLAUDE.md` |
| `starter-kits/<kit>/**` | `.github/starter-kits/<kit>/**` (only if installed) |

**Excluded** (template internals): `tests/`, `scripts/`, `.github/workflows/`, `.github/copilot-instructions.md`, `.github/instructions/`, `.github/prompts/`, `.github/hooks/`, `.github/skills/`, `SETUP.md`, `UPDATE.md`, `MIGRATION.md`, `AGENTS.md`, `MODELS.md`, `VERSION.md`, `CHANGELOG.md`, `README.md`, `llms.txt`, `release-please-config.json`, `CLAUDE.md` (dev copy), `.markdownlint*`, `.gitignore`, `.github/copilot-version.md`.

**Roster completeness**: fetch `git/trees/main?recursive=1` (reuse U3b cache). Filter for `.github/agents/*.agent.md`, `.github/agents/*.json`, and `template/skills/*/SKILL.md`. Add missing items with status `NEW`.

**Status per companion file**: `NEW` (absent → create), `UPDATABLE` (unmodified, template differs → update), `USER_CUSTOMISED` (modified, template differs → flag), `CURRENT` (matches template → skip), `DELETED_FROM_TEMPLATE` (removed → inform, default keep, require explicit confirmation).

**Three-way comparison**: fetch old template at installed tag, read consumer, compare. If `<!-- file-manifest -->` has stored hash and `sha256(consumer)[0:12]` matches → override to `UPDATABLE`.

#### Step 4 — Final check
**Permanently excluded** (never diff/modify): §10 and its subsections (User Preferences, Additional project notes), `<!-- migrated -->` blocks, `<!-- user-added -->` blocks, resolved placeholder values.

From the fetched migration entries: accumulate breaking changes, new placeholders, manual actions.

If zero items need updating → "No applicable changes found" → stop.

#### Step 5 — Fast-path for companion-only updates
If all §1–§9 are `UNCHANGED`/`USER_ONLY` AND companions need updating AND no breaking changes: show compact summary, then:

```ask_questions
header: "Companion-only update"
question: "No instruction changes. Apply all companion file updates?"
options:
  - label: "Y — Apply all"
    description: "Update all listed companion files"
    recommended: true
  - label: "N — Skip"
    description: "No changes will be made"
  - label: "List — Pick individually"
    description: "Choose which companion files to update"
allowFreeformInput: false
```

> **Fallback**: If `ask_questions` unavailable, present as Y/N/list in chat.

If confirmed, write files, update version + CHANGELOG, skip full report.

---

### U5b — Workspace drift check
Scan `.copilot/workspace/` for structural sentinel drift using `scripts/workspace/check-workspace-drift.sh`. Sentinels are HTML comments embedded in template workspace files; their absence indicates a structural section that has been updated in the template but not yet applied to this consumer's workspace.

If `scripts/workspace/check-workspace-drift.sh` is available locally:

```bash
bash scripts/workspace/check-workspace-drift.sh .copilot/workspace
```

If unavailable (consumer hasn't pulled the script): fetch the script first from:

```text
https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/scripts/workspace/check-workspace-drift.sh
```

Record each drifted section as a **workspace drift item** to report in the Pre-flight Report. These items are always shown to the user and always listed under manual actions — workspace files are consumer-owned and cannot be auto-updated.

---

## Pre-flight Report
Present after U1–U5b. Do not write yet. Include: (1) version header, (2) breaking changes, (3) what’s new from CHANGELOG, (4) section diff table, (5) companion files table, (6) new placeholders, (7) user-modified sections, (8) manual actions, (9) workspace drift items (from U5b), (10) guardrail confirmation, (11) backup note. Then:

```ask_questions
header: "Update decision"
question: "How would you like to proceed with this update?"
options:
  - label: "U — Update all"
    description: "Apply all changes (user-modified sections preserved with a note)"
    recommended: true
  - label: "S — Skip"
    description: "No changes — stay on current version"
  - label: "C — Customise"
    description: "Walk through each change individually"
allowFreeformInput: false
```

> **Fallback**: If `ask_questions` unavailable, present as U/S/C in chat.

---

## Pre-write Backup
**Automatic and mandatory.** Runs after user's first confirmatory response, before first write. Not for path S.

Back up `.github/copilot-instructions.md` + companion files with status `UPDATABLE`/`USER_CUSTOMISED` to `.github/archive/pre-update-<TODAY>-v<INSTALLED_VERSION>/` (append counter if exists). Include `BACKUP-MANIFEST.md`. Print backup path, then continue.

---

## Decision paths
### U — Update all
> Pre-write Backup runs before this path begins.

**Sections**: `UPDATED`/`BREAKING` → replace with new template, re-apply placeholders, re-insert `<!-- migrated -->`/`<!-- user-added -->` blocks with `<!-- preserved from pre-update version -->`. `NEW_SECTION` → insert at correct position with placeholder resolution. `USER_MODIFIED` → do NOT modify, append `<!-- update-note: template updated to vX.Y.Z but user-modified, preserved -->`. `USER_ONLY` → unchanged.

**Companion files**: `NEW` → fetch, write, resolve placeholders. `UPDATABLE` → fetch latest, replace. `USER_CUSTOMISED` → skip, report.

Special case for `.vscode/mcp.json`: after writing the latest template structure, restore the consumer's previous per-server `disabled` state for every server present in both the old and new configs. If a server was previously enabled (no `disabled` field), remove `disabled` from the updated config as well. Newly introduced servers keep the template default. Sandbox and other structural fields always come from the template.

**New placeholders**: use `ask_questions` with `allowFreeformInput: true` (batch ≤4). Add to §10.

> **Fallback**: If `ask_questions` unavailable, present as numbered list in chat.

Proceed to Post-update steps.

### S — Skip
No writes. No backup. "No changes made. Your instructions remain at version X.Y.Z."

### C — Customise
Walk through each `UPDATED`, `BREAKING`, `NEW_SECTION`, `USER_MODIFIED` item showing: ID, status, versions, summary, excerpts (≤20 lines current + new).

```ask_questions
header: "Section §<N>"
question: "How should I handle §<N> <name>? (Status: <STATUS>)"
options:
  - label: "A — Apply"
    description: "Replace with new template version"
    recommended: true
  - label: "B — Skip"
    description: "Keep current version"
  - label: "C — Customise"
    description: "View full text and tailor before applying"
allowFreeformInput: false
```

> **Fallback**: If `ask_questions` unavailable, present as A/B/C in chat.

Then companion files:

```ask_questions
header: "Companion: <filename>"
question: "How should I handle <path>? (Status: <STATUS>)"
options:
  - label: "A — Apply"
    description: "<Create/Update> this file"
    recommended: true
  - label: "B — Skip"
    description: "Leave unchanged"
allowFreeformInput: false
```

> **Fallback**: If `ask_questions` unavailable, present as A/B in chat.

If **C** chosen: show full text, accept adjustments, confirm via ask_questions (Yes/No, `allowFreeformInput: true`). After all reviewed, summarise and confirm:

```ask_questions
header: "Write changes"
question: "Review complete. Shall I write these changes now?"
options:
  - label: "Yes"
    description: "Apply all confirmed changes"
    recommended: true
  - label: "No"
    description: "Cancel — no changes written"
allowFreeformInput: false
```

> **Fallback**: If `ask_questions` unavailable, present as yes/no in chat.

Pre-write Backup runs after "yes", before first write.

---

## Applicability guardrails
Apply before writing any section, regardless of decision path:

| Guardrail | Check | Action |
|-----------|-------|--------|
| **Placeholder leakage** | New section has `{{PLACEHOLDER}}` tokens | Re-resolve from §10. If missing, leave as-is, log anomaly |
| **§10 collision** | Change would overwrite §10 | Skip automatically, log anomaly |
| **Migrated content** | Section has `<!-- migrated -->` blocks | Preserve verbatim; write around them |
| **User-added content** | Section has `<!-- user-added -->` blocks | Preserve verbatim; write around them |
| **User preference conflict** | New section changes behaviour in User Preferences | Flag. Use `ask_questions`: "Keep my preference" / "Use template version". Fallback: ask in chat. |
| **Metric threshold conflict** | New section changes resolved thresholds in §10 | Show current vs defaults. Use `ask_questions`: "Keep current values" / "Use template defaults". Fallback: ask in chat. |
| **MCP enablement state** | Updating `.vscode/mcp.json` and consumer has existing per-server `disabled` choices | Apply the latest template structure first, then restore the consumer's prior per-server `disabled` state for servers present in both old and new configs. Keep template defaults for newly introduced servers. Always take sandbox and structural fields from the template. |

**Items never modified by updates**: §10 (all subsections), `<!-- migrated -->` blocks, `<!-- user-added -->` blocks, resolved placeholder values. **Items flagged for user decision**: `USER_MODIFIED` sections, sections with `<!-- update-note: -->`, differing thresholds, preference conflicts.

---

## Post-update steps
### 1 — Update version file, fingerprints, and file manifest
Recompute fingerprints and file-manifest hashes:

```bash
# Section fingerprints
for i in $(seq 1 9); do
  fp=$(awk "/^## §${i} —/{found=1; next} /^## §/{if(found) exit} found{print}" \
    .github/copilot-instructions.md | sha256sum | cut -c1-12)
  echo "§${i}=${fp}"
done
# File manifest
for f in .github/agents/*.agent.md .github/agents/*.json .github/skills/*/SKILL.md \
  .github/starter-kits/*/plugin.json \
  .github/starter-kits/*/skills/*/SKILL.md \
  .github/starter-kits/*/instructions/*.instructions.md \
  .github/starter-kits/*/prompts/*.prompt.md \
  .github/hooks/copilot-hooks.json .github/hooks/scripts/*.sh \
  .github/hooks/scripts/*.ps1 .github/hooks/scripts/*.json \
  .github/hooks/scripts/*.py .github/instructions/*.instructions.md \
  .github/prompts/*.prompt.md .github/workflows/copilot-setup-steps.yml \
  .vscode/settings.json .vscode/extensions.json .vscode/mcp.json \
  CLAUDE.md \
  .copilot/workspace/*.md .copilot/workspace/workspace-index.json; do
  [ -f "$f" ] || continue; echo "${f}=$(sha256sum "$f" | cut -c1-12)"
done
```

If `sha256sum` is unavailable, use this Python fallback:

```python
import hashlib, pathlib, glob, re

# Section fingerprints
text = pathlib.Path('.github/copilot-instructions.md').read_text(encoding='utf-8')
for i in range(1, 10):
    match = re.search(rf'(?m)^## §{i} —.*?(?=^## §|\Z)', text, re.DOTALL)
    body = match.group(0) if match else ''
    fp = hashlib.sha256(body.encode()).hexdigest()[:12]
    print(f'§{i}={fp}')

# File manifest
for pattern in [
  '.github/agents/*.agent.md', '.github/agents/*.json', '.github/skills/*/SKILL.md',
    '.github/starter-kits/*/plugin.json',
    '.github/starter-kits/*/skills/*/SKILL.md',
    '.github/starter-kits/*/instructions/*.instructions.md',
    '.github/starter-kits/*/prompts/*.prompt.md',
    '.github/hooks/copilot-hooks.json', '.github/hooks/scripts/*.sh',
  '.github/hooks/scripts/*.ps1', '.github/hooks/scripts/*.json',
  '.github/hooks/scripts/*.py', '.github/instructions/*.instructions.md',
    '.github/prompts/*.prompt.md', '.github/workflows/copilot-setup-steps.yml',
    '.vscode/settings.json', '.vscode/extensions.json', '.vscode/mcp.json',
    'CLAUDE.md',
    '.copilot/workspace/*.md', '.copilot/workspace/workspace-index.json',
]:
    for f in sorted(glob.glob(pattern)):
        h = hashlib.sha256(pathlib.Path(f).read_bytes()).hexdigest()[:12]
        print(f'{f}={h}')
```

Write `.github/copilot-version.md`: version, `Applied:` (preserved), `Updated: YYYY-MM-DD`, `<!-- section-fingerprints -->`, `<!-- file-manifest -->`, `<!-- setup-answers -->` (preserved). Omit fingerprint/manifest blocks only if neither `sha256sum` nor Python is available.

### 2 — Append to CHANGELOG.md
Under `## [Unreleased]`: version transition, sections updated/skipped, companions applied, backup path.

### 3 — Print confirmation
Report: version transition, section counts, companion counts, breaking changes, protected items, backup path, anomalies, manual actions.

---

## Factory restore
### F1 — Confirm recovery mode
Factory restore is a destructive recovery path for broken or partial installations. It bypasses the normal update pre-flight, ignores the current instruction installation, backs up every managed surface, removes those surfaces from the working tree, and reinstalls the latest upstream template from scratch.

```ask_questions
header: "Factory restore"
question: "Factory restore ignores current repo instructions, backs up every managed file, removes those files from the working tree, and reinstalls from scratch. Continue?"
options:
  - label: "Yes"
    description: "Archive current managed files and reinstall from upstream"
    recommended: true
  - label: "No"
    description: "Cancel"
allowFreeformInput: false
```

> **Fallback**: If `ask_questions` unavailable, present as yes/no in chat.

If the user declines, stop with no writes.

### F2 — Back up current managed files
Create `.github/archive/pre-factory-restore-<TODAY>-v<CURRENT_VERSION_OR_UNKNOWN>/` (append a counter if needed) before the first write. Archive any existing managed surfaces that are present:

- `.github/copilot-instructions.md`
- `.github/copilot-version.md`
- `.github/agents/`
- `.github/skills/`
- `.github/hooks/`
- `.github/instructions/`
- `.github/prompts/`
- `.github/workflows/copilot-setup-steps.yml`
- `.github/starter-kits/`
- `.copilot/workspace/`
- `.vscode/mcp.json`
- `.vscode/settings.json`
- `.vscode/extensions.json`
- `CLAUDE.md`
- `CHANGELOG.md`

Do not require every path to exist. Include `BACKUP-MANIFEST.md` listing every managed surface, whether it was copied, and its original destination. The goal is a complete reversible recovery snapshot.

### F3 — Remove current managed surfaces
After the backup succeeds, remove every existing managed surface from the working tree before reinstall begins.

- Do not leave prior managed files in place after the backup completes.
- Do not merge with, preserve, or consult current managed files during factory restore.
- The only surviving copy of previous managed files must be the pre-factory backup snapshot.

### F4 — Reinstall from scratch
After the purge, fetch the latest upstream `SETUP.md` and execute it as a clean install.

- Explicitly disregard current repo instructions, `.github/copilot-version.md`, stored setup answers, current §10 overrides, existing workspace identity content, existing VS Code config files, and template-managed CHANGELOG content except as data preserved inside the backup snapshot.
- Do not read old managed files to guide reinstall decisions.
- Do not offer merge or keep-existing branches for managed files during factory restore.
- Collect fresh setup answers and write a fresh installation from upstream sources.

### F5 — Report completion
Report the pre-factory backup path, confirm that managed surfaces were removed before reinstall, and note that future updates can return to the normal update flow.

---

## Restore from backup
### R1 — List available backups
Scan `.github/archive/` for `pre-update-*`, `pre-factory-restore-*`, and `pre-restore-*` dirs. If none: "No backups found." → stop.

```ask_questions
header: "Select backup"
question: "Which backup would you like to restore?"
options:
  - label: "<BACKUP_DIR>/"
    description: "Backup type, date, and managed files from BACKUP-MANIFEST.md"
  - label: "Cancel"
    description: "Do not restore"
allowFreeformInput: false
```

> **Fallback**: If `ask_questions` unavailable, list as numbered choices in chat.

Populate dynamically from scanned directories.

#### R2 — Show backup manifest and confirm
Read `BACKUP-MANIFEST.md`, show backup type, version/date if present, and the managed files included. Note current managed files will be backed up first.

```ask_questions
header: "Confirm restore"
question: "Restoring replaces current instructions. Pre-restore snapshot saved first. Proceed?"
options:
  - label: "Yes"
    description: "Restore (current files backed up first)"
    recommended: true
  - label: "No"
    description: "Cancel"
allowFreeformInput: false
```

> **Fallback**: If `ask_questions` unavailable, present as yes/no in chat.

#### R3 — Back up current managed files
Create `.github/archive/pre-restore-<TODAY>-v<CURRENT_VERSION_OR_UNKNOWN>/` with current managed files and `BACKUP-MANIFEST.md`. Always reversible.

#### R4 — Restore
Restore the managed surfaces recorded in `BACKUP-MANIFEST.md` to their original paths, preserving structure. Remove current managed copies first when needed so the restored snapshot is exact. Create parent dirs as needed.

#### R5 — Record the restoration
Append to CHANGELOG.md: "Restored from `<BACKUP_DIR>`. Pre-restore snapshot at `pre-restore-<TODAY>-v<CURRENT_OR_UNKNOWN>`."

#### R6 — Confirmation
Report: restored from, files count, pre-restore path, CHANGELOG updated. Note: undo by restoring pre-restore snapshot.

---

## Force check
If user says *"Force check instruction updates"*, bypass version equality check in U2 and run full comparison.

---

> **Note for Copilot**: All writes go to the **user's current project**. Do not modify files in the template repo.
