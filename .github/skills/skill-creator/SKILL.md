---
name: skill-creator
description: Create a new agent skill following the Agent Skills open standard
compatibility: ">=1.4"
---

# Skill Creator

> Skill metadata: version "1.2"; license MIT; tags [meta, authoring, skill, scaffold]; compatibility ">=1.4"; recommended tools [codebase, editFiles, runCommands].

Create a new agent skill that follows the [Agent Skills](https://agentskills.io) open standard and the project's §12 Skill Protocol.

## When to use

- User asks to "create a skill", "write a skill", or "add a new skill"
- A repeated workflow would benefit from codification
- An online skill needs significant adaptation

> **Tip**: VS Code 1.110+ has `/create-skill` for basic scaffolds. This skill adds Lean/Kaizen guidance: waste-aware naming, PDCA verification, quality gates.

## Steps

1. **Clarify scope** — Ask the user: *"What workflow should this skill encode? Describe the trigger and the desired outcome in one sentence."*

2. **Choose a name** — Verb-noun kebab phrase (`review-dependencies`, `scaffold-api-route`). Becomes directory name under `.github/skills/`. Rules: 1–64 chars, lowercase alphanumeric + hyphens, no leading/trailing/consecutive hyphens, must match directory.

3. **Write the frontmatter** — Create `.github/skills/<name>/SKILL.md`:

   ```yaml
   ---
   name: <kebab-name>
   description: <one precise sentence - this is how the agent discovers the skill>
   compatibility: ">=<current template version>"
   ---
   ```

   Optional frontmatter fields (add only when relevant):

   | Field | When to include |
   |-------|----------------|
   | `user-invocable` | Set to `false` to hide from the `/` menu while still allowing auto-load |
   | `disable-model-invocation` | Set to `true` to require manual `/` invocation only |
   | `allowed-tools` | Space-delimited pre-approved tools (experimental) |
   | `compatibility` | Environment requirements (e.g., `">=3.2"`, `"Requires Python 3.14+"`) |

   Do not add unsupported top-level keys like `stacks`. Put stack hints in `description` or the metadata note.

   Add a metadata note after the `# <Name>` heading:

   ```markdown
   > Skill metadata: version "1.0"; license MIT; tags [<2-5 keywords>]; compatibility ">={{version}}"; recommended tools [codebase, editFiles].
   ```

4. **Write the body** — Title, When to use (triggers + contra-indications), Steps (numbered, action verbs, independently verifiable), Verify.

5. **Authoring rules** (§12): one skill = one workflow; no hardcoded paths; idempotent; steps not prose.

6. **Progressive disclosure**: metadata ~100 tokens at startup; instructions <5000 tokens on activation; resources on demand in `scripts/`, `references/`, `assets/` subdirs. Keep under 500 lines.

7. **Save** the file.

8. **Validate** — Run `skills-ref validate .github/skills/<name>` if available, otherwise verify manually.

9. **Run tests** — Verify new skill passes applicable test suite checks.

## Verify

- [ ] `.github/skills/<name>/SKILL.md` exists with `name` and `description` frontmatter
- [ ] `name` matches directory name (lowercase, hyphens)
- [ ] Body has "When to use" and "Steps" sections with numbered action verbs
- [ ] Final step is a verification check
- [ ] File under 500 lines
