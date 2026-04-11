# Research: Metadata / Constants File Patterns for AI-Agent Repos

> Date: 2026-03-30 | Agent: Researcher | Status: final

## Summary

Large open-source repositories universally separate concerns when metadata files grow
beyond a single responsibility. The dominant pattern is **one file per consumer** (each
tool owns its own config), not one mega-file. AI agent ecosystems are converging on
Markdown-based navigation indices (`llms.txt`, `AGENTS.md`) for LLM consumption and
JSON registries for machine drift-checks. For this repo, `DOC_INDEX.json` is already
correctly scoped as a **drift-check inventory** — that is its single purpose. Splitting
it is unwarranted today. Renaming it is worth considering. The findings below provide
concrete evidence for these conclusions.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://llmstxt.org/ | llms.txt spec — AI-readable project navigation standard |
| https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot | GitHub Copilot custom instructions file types |
| https://github.com/agentsmd/agents.md | AGENTS.md open standard — minimal AI agent instruction format |
| https://docs.npmjs.com/cli/v10/configuring-npm/package-json | package.json as canonical single-file metadata pattern |
| https://raw.githubusercontent.com/hashicorp/terraform/main/version/version.go | Terraform version.go — single-source VERSION file pattern |
| https://raw.githubusercontent.com/angular/angular/main/package.json | Angular monorepo package.json — centralized build metadata |
| https://raw.githubusercontent.com/facebook/react/main/package.json | React monorepo private package.json — dependency / scripts only |
| https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md | release-please two-file pattern: config vs manifest |
| https://raw.githubusercontent.com/renovatebot/renovate/main/renovate.json | Renovate — tool-specific config with $schema reference |
| https://conventionalcommits.org/en/v1.0.0/ | Conventional Commits spec — structured commit metadata |
| https://json-schema.org/learn/getting-started-step-by-step | JSON Schema — structured validation for JSON metadata |
| https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners | CODEOWNERS — single-responsibility ownership metadata |

---

## Findings

### 1. How Large Repos Centralise Constants and Metadata

**npm/Node.js ecosystem — `package.json`:**
The canonical single-file pattern. `package.json` consolidates identity
(`name`, `version`, `description`, `license`, `homepage`, `bugs`, `repository`),
scripts, and dependencies into one file. Both Angular and React use a **root-level
private** `package.json` for monorepo build metadata only — the actual `version` for
released packages lives in each package's own `package.json`.

Key lesson: `package.json` works as a single file at human scale because npm
enforces its schema. At monorepo scale, the root file is stripped down to build
concerns only; per-package metadata moves to sub-package files.

**Terraform — `VERSION` + `version.go`:**
Version is stored in a plain-text `VERSION` file embedded at compile time via
`//go:embed`. `version.go` reads it. This decouples the "value" (VERSION) from the
"logic" (version.go). Result: changing the version requires touching only one file.
This is the most disciplined "single source of truth" pattern observed.

**release-please — `release-please-config.json` + `.release-please-manifest.json`:**
A textbook separation of concerns:
- `release-please-config.json` — human-authored configuration (release type, changelog
  behaviour, package paths, plugins). Changes when a human changes release settings.
- `.release-please-manifest.json` — machine-maintained state (current versions per
  package). Changes when a release is cut. The dot-prefix signals machine ownership.

This is the clearest example of SRP applied to metadata files in the GitHub ecosystem.

**Renovate — `renovate.json`:**
Single tool-scoped config. Uses `"$schema"` to reference an external JSON Schema,
enabling IDE validation. References external presets via `"extends"`. Does not try to
be a general project metadata file — it is scoped exclusively to dependency management.

**Kubernetes — conventions over configuration:**
Kubernetes does not have a single metadata registry file. It uses:
- `CODEOWNERS` — ownership rules
- `CHANGELOG/` directory — per-version changelogs indexed by a `README.md`
- `staging/src/k8s.io/client-go/metadata/` — API type library for object metadata

The lesson from Kubernetes: at very large scale, centralised single files become
bottlenecks. Convention-based discovery (well-known paths, predicable naming) scales
better than a master registry.

---

### 2. Single-File vs Multi-File: Tradeoffs and SRP

**Single-file advantages:**
- One place to look — reduces cognitive overhead for new contributors
- Atomic updates — no risk of two files going out of sync
- Lower tooling overhead — one sync script, one CI check
- Works well when the file has one consumer or one reason to change

**Single-file disadvantages:**
- Becomes a "god object" as scope grows (the `package.json` anti-pattern in large repos)
- Multiple consumers with different update frequencies cause noise in diffs
- Schema validation becomes harder when semantically distinct sections mix

**Multi-file advantages:**
- Each file has one owner and one reason to change (SRP)
- Machine-maintained files (manifests, state) can have dot-prefix to signal they are
  not for direct human editing
- Smaller files are easier to review and less prone to merge conflicts

**Multi-file disadvantages:**
- Files can drift from each other without explicit sync tooling
- More files to discover and understand

**The SRP test for `DOC_INDEX.json`:**
Ask: "What would cause this file to change?"

Current `DOC_INDEX.json` answers:
1. A new agent is added/removed → agents list changes
2. A new skill is added/removed → skills list changes
3. A hook script is added/removed → hookScripts list changes
4. A note is updated → notes array changes

All four reasons are the **same category of change**: the file inventory drifts.
The `schemaVersion`, `updated`, and `counts` fields are metadata *about* the inventory,
not separate constants. This means `DOC_INDEX.json` currently has **one logical reason
to change** — the inventory changed. SRP is satisfied as-is.

The case for splitting would arise if: (a) a second consumer needed only project
constants (URLs, template version, description) and not the file lists, or (b) the
file exceeded manageable size. Neither condition is currently met.

**Verdict:** Keep `DOC_INDEX.json` as a single file. Do not split prematurely.

---

### 3. AI Agent Consumption Patterns

**llms.txt convention (llmstxt.org):**
- Markdown file at `/llms.txt` in the root of a project/website
- Structure: H1 (project name) → blockquote (short summary) → optional prose → H2
  sections containing bullet lists of `[name](url): description` links
- Purpose: **curated navigation for LLMs**, not an exhaustive file list
- "Optional" H2 section = content an LLM may skip for shorter context
- Adopted by VitePress, Docusaurus, Drupal plugins; gaining fast traction
- This repo already has `llms.txt` at root — it follows the spec

**Key design principle from llms.txt:** the file is a *curated guide*, not a *complete
index*. It helps an LLM find what it needs quickly; it does not replace detailed docs.

**AGENTS.md standard (agentsmd/agents.md):**
- Open format: Markdown, developer-facing, stored anywhere in the repo hierarchy
- Sections: dev environment tips, testing instructions, PR instructions
- GitHub Copilot now officially recognises `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` as
  agent instruction files (per GitHub docs, fetched 2026-03-30)
- Nearest `AGENTS.md` in the directory tree takes precedence — supports monorepo
  per-package agent instructions

**GitHub Copilot custom instructions (GitHub docs, 2026-03-30):**
Three supported file types:
1. `copilot-instructions.md` in `.github/` — repository-wide
2. `NAME.instructions.md` in `.github/instructions/` — path-scoped
3. `AGENTS.md` anywhere in repo — AI agent instructions

**Format preferences for AI consumption:**
| Format | AI Strengths | AI Weaknesses |
|--------|-------------|---------------|
| Markdown | Natural language, headers create structure, links are meaningful | Not machine-parseable without additional tooling |
| JSON | Structured, unambiguous, schema-validatable, fast parsing | Verbose, poor for long prose, no comments |
| YAML | Concise, supports comments | YAML parsing quirks (Norway problem), whitespace-sensitive |
| TOML | Human-friendly, clear types | Less universally supported in tooling |

**Emerging pattern:** Use **Markdown for human+AI navigation** (`llms.txt`, `AGENTS.md`,
`copilot-instructions.md`) and **JSON for machine drift-checks** (`DOC_INDEX.json`,
`release-please-config.json`, `renovate.json`). The two formats serve different
consumers and should not be merged.

**MCP server config:** Uses `.vscode/mcp.json` — JSON with strict schema, exclusively
for machine consumption. Follows the "one config per tool" pattern.

---

### 4. Naming Conventions

**Observed naming patterns by category:**

| Category | Common names in the wild |
|----------|--------------------------|
| Project identity + deps | `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod` |
| File/component registry | `REGISTRY.json`, `manifest.json`, `index.json`, `catalog.json` |
| Machine-maintained state | `.release-please-manifest.json`, `.version` (dot-prefix convention) |
| Tool-specific config | `renovate.json`, `release-please-config.json`, `settings.json` |
| AI navigation | `llms.txt`, `AGENTS.md`, `CLAUDE.md`, `copilot-instructions.md` |
| Version constant | `VERSION` (plain text), `VERSION.md`, embedded in `package.json` |
| Ownership | `CODEOWNERS` (all-caps, no extension) |
| Drift-check inventory | `DOC_INDEX.json` (this repo) |

**Analysis of `DOC_INDEX.json`:**
- All-caps prefix (`DOC_`) is unusual for JSON files — most JSON files use lowercase
  or camelCase (`package.json`, `renovate.json`)
- `INDEX` is clearer than `MANIFEST` (which connotes a listing of artifacts for
  distribution) or `REGISTRY` (which connotes a lookup table)
- The "DOC" prefix is ambiguous — it could mean "documentation" or "document"
- Better alternatives that follow naming conventions in the wild:
  - `workspace-index.json` — explicit about scope, lowercase, conventional
  - `repository-index.json` — very explicit
  - `copilot-index.json` — signals AI-agent consumption purpose
  - `project-index.json` — generic but clear
- If the file served dual purposes (inventory + constants), better names would be:
  - Split: `project-constants.json` + `doc-inventory.json`
  - Combined: `project-metadata.json` (but this risks scope creep)

**Recommendation on the name:** `DOC_INDEX.json` is a working name but has the
all-caps/ambiguous-prefix issue. The `template/workspace/DOC_INDEX.json` template
stub perpetuates this in consumer repos. A rename to `workspace-index.json` would
better align with ecosystem conventions, but it is a breaking change requiring a
migration step. The decision is cosmetic; the functionality is correct.

---

### 5. GitHub-Specific Patterns

**`.github/` directory conventions:**
- `copilot-instructions.md` — Copilot repository-wide system prompt
- `instructions/` — path-scoped instruction stubs
- `CODEOWNERS` — pull request ownership rules
- `workflows/` — GitHub Actions workflows (no central registry; discovered by path)
- `PULL_REQUEST_TEMPLATE.md` — PR template
- `ISSUE_TEMPLATE/` — issue templates
- `agents/` — VS Code agent definitions (this repo's convention)

**release-please conventions:**
- `release-please-config.json` at root — human config
- `.release-please-manifest.json` at root — machine state (dot-prefix)
- Both are JSON, both are at root (not in `.github/`)

**Renovate conventions:**
- `renovate.json` at root — the `$schema` key is standard practice and highly
  recommended for all JSON config files consumed by tooling

**Key GitHub ecosystem insight:** There is no central file-registry standard for
GitHub repos. Discovery is entirely **convention-based** (known paths, known filenames).
The closest thing to a "file index" in the GitHub ecosystem is the GitHub API tree
endpoint used in `template/setup/manifests.md`, which dynamically enumerates files by
path pattern.

---

## Recommendations

### R1 — Keep `DOC_INDEX.json` as one file (do not split)
The SRP test is satisfied. All sections have one reason to change: the inventory
drifted. Splitting introduces sync overhead with no practical benefit at current scale.

### R2 — Consider renaming `DOC_INDEX.json` → `workspace-index.json`
Rationale: follows lowercase ecosystem convention, removes ambiguous `DOC_` prefix,
signals scope (workspace-level). Requires a migration step and update to
`sync-doc-index.sh`, tests, and the template stub. Log as a deferred improvement.

### R3 — Add `$schema` key to `DOC_INDEX.json` if a JSON Schema is ever authored
The renovate/release-please pattern: add `"$schema": "..."` to enable IDE validation.
Even a local schema at `.copilot/schema/workspace-index.schema.json` would improve
authoring experience and catch drift-check errors earlier.

### R4 — If project constants are needed, use a *separate* Markdown table in `llms.txt`
This repo already has a well-structured `llms.txt`. If URL constants, template version,
or other project-level values need a home for AI consumption, add an H2 section to
`llms.txt` (e.g., `## Constants`) rather than creating a new JSON file. JSON is for
machine consumers; Markdown is for LLM consumers.

### R5 — `AGENTS.md` is the correct file for AI agent navigation metadata
The AGENTS.md standard (now officially recognised by GitHub Copilot) is the right
place for agent trigger phrases, bootstrap sequences, and update sequences — which is
exactly how this repo uses it. No change needed.

---

## Gaps / Further Research Needed

1. **Consumer feedback on `DOC_INDEX.json` naming** — the rename recommendation (R2)
   should be validated against consumer usage patterns before committing.
2. **JSON Schema authoring** — if R3 is pursued, the schema structure for
   `workspace-index.json` should be designed and tested with an online validator.
3. **llms.txt adoption trajectory** — the spec is informal (no RFC/ISO). Monitor
   whether it gains an official standard body endorsement, which would strengthen the
   case for R4.
4. **Copilot instruction file precedence rules** — the interaction between
   `copilot-instructions.md`, path-scoped `.instructions.md`, and `AGENTS.md` when
   all three are present is not fully documented. Worth a follow-up fetch once the
   GitHub docs stabilise.
