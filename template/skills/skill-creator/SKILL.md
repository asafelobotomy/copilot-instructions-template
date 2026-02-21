---
name: skill-creator
description: Author a new agent skill from scratch following the Agent Skills open standard and §12 conventions
version: "1.0"
license: MIT
tags: [meta, authoring, skill, scaffold]
compatibility: ">=1.4"
allowed-tools: [codebase, editFiles]
---

# Skill Creator

Create a new agent skill that follows the [Agent Skills](https://agentskills.io) open standard and the project's §12 Skill Protocol.

## When to use

- The user asks to "create a skill", "write a skill", or "add a new skill"
- A workflow is being repeated manually and would benefit from codification
- An online skill was found but needs significant adaptation

## Steps

1. **Clarify scope** — Ask the user: *"What workflow should this skill encode? Describe the trigger and the desired outcome in one sentence."*

2. **Choose a name** — Use a verb-noun kebab phrase describing the workflow (e.g., `review-dependencies`, `scaffold-api-route`). The name becomes the directory name under `.github/skills/`.

3. **Write the frontmatter** — Create `.github/skills/<name>/SKILL.md` with:

   ```yaml
   ---
   name: <kebab-name>
   description: <one precise sentence — this is how the agent discovers the skill>
   version: "1.0"
   license: MIT
   tags: [<2-5 keywords matching common task descriptions>]
   ---
   ```

4. **Write the body** — Structure as:
   - **Title** (`# <Name>`) — human-readable heading.
   - **When to use** — bullet list of trigger conditions and contra-indications.
   - **Steps** — numbered list with clear action verbs. Each step should be independently verifiable.
   - **Verify** — a final step that confirms the skill completed correctly.

5. **Apply authoring rules** (from §12):
   - One skill, one workflow — if you need "and", split it.
   - No hardcoded paths — use relative references and contextual lookups.
   - Idempotent — running the skill twice produces the same result.
   - Steps, not prose — the agent follows these literally.

6. **Save and log** — Write the file, then append to `JOURNAL.md`:

   ```text
   [skill] <name> created — <one-line reason>
   ```

7. **Update BIBLIOGRAPHY.md** — Add a row for the new skill file.

## Verify

- [ ] `.github/skills/<name>/SKILL.md` exists
- [ ] Frontmatter has both `name` and `description` fields
- [ ] Body has "When to use" and "Steps" sections
- [ ] Steps are numbered with clear action verbs
- [ ] Final step is a verification check
- [ ] JOURNAL.md has a `[skill]` entry for this skill
