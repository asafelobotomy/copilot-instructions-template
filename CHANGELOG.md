# Changelog — copilot-instructions-template

All notable changes to the **template itself** are recorded here.
This is the upstream version history — not a stub for consumer projects.

Format follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [Semantic Versioning](https://semver.org/).

> **Consumer projects**: your own `CHANGELOG.md` records your project's changes, not this file.

---

## [Unreleased]

### Performance
- Lossless token-reduction pass across both LLM-read files (23 targeted substitutions, zero semantic change):
  - `copilot-instructions.md`: −163 words / −1 048 chars
  - `AGENTS.md`: −254 words / −1 614 chars
  - Combined: −417 words / −2 662 chars (**7.6% reduction**)
  - Compressions applied: redundant prose collapsed to inline; repeated "do not write to template repo" guards consolidated to a single blockquote; numbered sub-lists compressed to prose sentences; verbose step headers trimmed; duplicate bullet removed from §11.

### Changed
- `SETUP.md §0d` — preference interview expanded to 3-tier system (Simple 5 / Advanced +9 / Expert +5 = 19 total questions). All tiers produce an equally-capable agent — higher tiers unlock deeper customisation rather than adding features:
  - Simple (S1–S5): response style, experience level, primary mode, testing, autonomy — unchanged
  - Advanced (A6–A14): code style refined to cover linter/formatter configs; **new**: file size discipline (§3 LOC thresholds), dependency management, instruction self-editing (§8 controls), refactoring appetite; old "change reporting" demoted to A14
  - Expert (E15–E19): **new** — tool/dependency availability behaviour, agent persona (Professional/Mentor/Pair-programmer/Ship-it captain/Zen master/Rubber duck/Custom), VS Code settings management, global autonomy override (1–5 failsafe), mood lightener
  - Mode selection now offers S / A / E (was S / A)
  - All answers still collected per-tier in a single batched interaction
  - Defaults tables expanded to cover all 19 dimensions for each tier

### Added
- CI infrastructure (not a template version bump — repo maintenance):
  - `.github/workflows/ci.yml` — validates VERSION semver, CHANGELOG entries, all required files, §1–§11 sections, README docs-table links, merge-conflict markers, and placeholder token count on every push and PR
  - `.github/workflows/release.yml` — auto-creates a tagged GitHub release when `VERSION` is bumped on `main`; extracts notes from the matching CHANGELOG section
  - `.github/workflows/stale.yml` — marks issues/PRs stale after 30 days, closes after 37
  - `.markdownlint.json` — markdown lint rules (MD013/MD033/MD036/MD041 disabled; MD024 siblings-only)
  - `.github/PULL_REQUEST_TEMPLATE.md` — PR checklist auto-shown on new PRs
  - `.github/ISSUE_TEMPLATE/bug_report.yml` — structured bug report form
  - `.github/ISSUE_TEMPLATE/feature_request.yml` — structured feature request form
- `§2 Test Coverage Review` subsection in `.github/copilot-instructions.md` — structured protocol for auditing test coverage, identifying gaps, recommending local tests, and generating ready-to-use CI workflow YAML:
  - Step 0: detects test stack from config files (Jest/Vitest/Mocha/pytest/go/cargo/dotnet/Maven/Gradle/RSpec)
  - Step 1: asks user to run and paste coverage output (Copilot can't run commands directly)
  - Steps 2–3: static scan for untested files; classifies modules into zero/low/partial coverage
  - Step 4: recommends local tests with type (unit/integration/property-based) and priority (critical/high/medium/low)
  - Step 5: recommends CI workflows with copy-paste YAML — coverage gate, coverage diff comments, nightly runs, test matrix, mutation testing (Stryker/mutmut/cargo-mutants), contract/API tests
  - Step 6: structured report format (📊 snapshot, ✅/⚠️/❌ coverage bands, 🧪 test table, ⚙️ CI YAML snippets)
  - Step 7: waits for user action — does not write files unless explicitly instructed
- `AGENTS.md` — "Test coverage review" trigger section; *"Review my tests"* / *"Repo health review"* / *"Recommend CI tests"* added to canonical triggers table
- `docs/TEST-REVIEW-GUIDE.md` — plain-English guide to the test coverage review feature

---

## [1.0.2] — 2026-02-19

### Added
- `§11 — Tool Protocol` in `.github/copilot-instructions.md` — structured decision tree for tool use, adaptation, online search (MCP registry → GitHub → Awesome lists → stack registries → official docs), building from scratch, evaluating reusability, and saving to the toolbox.
- `.copilot/tools/` toolbox convention — lazy-created directory with `INDEX.md` catalogue where agents save reusable tools.
- `AGENTS.md` — "Tool operations" trigger phrase section; `.copilot/tools/INDEX.md` added to setup outputs table and file map; toolbox canonical triggers added.
- `template/workspace/TOOLS.md` — toolbox section explaining how to use `.copilot/tools/` and when to save.
- `template/BIBLIOGRAPHY.md` — Toolbox section stub.
- `template/workspace/BOOTSTRAP.md` — toolbox lazy-creation note.
- `§2 — Review Mode` Extension Review subsection — agents audit VS Code extensions, detect project stack, and recommend additions/removals. Full protocol:
  - Step 0: asks user to run `code --list-extensions | sort` (Copilot chat cannot enumerate installed extensions directly)
  - Built-in stack detection table with 14 stack mappings: Bash, JS/ESLint, JS/Oxc, JS/Biome, Python, Rust, Go, C#, Java, Docker, Vue, Svelte, Markdown, CSS, YAML, TOML
  - `oxc.oxc-vscode` confirmed to cover both oxlint **and** oxfmt — single extension for both tools
  - Unknown-stack research step: searches VS Code Marketplace, filters by quality (>100k installs, ≥4.0 rating, updated <2yr ago), adds qualifying finds to the report
  - Persists new stack → extension mappings to `.copilot/workspace/TOOLS.md` "Extension registry" for future audits in this project
  - Three-category report: Missing · Redundant · Unknown (resolved via Marketplace research)
  - Does not auto-install; waits for explicit user action
- `AGENTS.md` — "Extension review" trigger phrase section; *"Review extensions"* added to canonical triggers table.
- `docs/EXTENSION-REVIEW-GUIDE.md` — plain-English guide to the Extension Review feature (consistent with existing `docs/` guides).
- `template/workspace/TOOLS.md` — "Extension registry" stub table for persisting unknown-stack discoveries across sessions.

### Changed
- `§9 — Subagent Protocol` — subagents inherit the full Tool Protocol (§11) and must flag proposed toolbox saves to the parent before writing.
- Footer of `.github/copilot-instructions.md` — added `.copilot/tools/` link.
- `§11 — Tool Protocol` decision tree — added **step 2.5 COMPOSE**: before building, check whether 2+ existing toolbox tools can be assembled via pipe or import.
- `§11 — Tool Protocol` BUILD step — added **required inline header template** with six mandatory fields: `# purpose`, `# when`, `# inputs`, `# outputs`, `# risk`, `# source`.
- `§11 — Tool Protocol` INDEX.md format — added **`Output` and `Risk` columns**; updated example rows.
- `§11 — Tool Protocol` quality rules — verb-noun naming requirement; six-smell anti-pattern table (grounded in empirical analysis of 856 real-world MCP tools, arxiv 2602.14878); risk tier system (`safe` vs `destructive`); observability rule (≥3 uses → document workflow in TOOLS.md).
- `README.md` — added `docs/EXTENSION-REVIEW-GUIDE.md` to the human-readable guides table and file tree; fixed file content (backtick formatting restored).
- Template version stamp updated from `1.0.0` → `1.0.2`.

---

## [1.0.1] — 2026-02-19

### Added
- `.github/agents/setup.agent.md` — model-pinned Setup agent (Claude Sonnet 4.6). File existed in documentation but had never been committed to the repo; now present.
- `.github/agents/coding.agent.md` — model-pinned Coding agent (GPT-5.3-Codex). Same.
- `.github/agents/review.agent.md` — model-pinned Review agent (Claude Opus 4.6). Same.
- `.github/agents/fast.agent.md` — model-pinned Fast agent (Claude Haiku 4.5). Same.
- `docs/INSTRUCTIONS-GUIDE.md` — human-readable guide to `.github/copilot-instructions.md`.
- `docs/SETUP-GUIDE.md` — human-readable walkthrough of the setup process.
- `docs/UPDATE-GUIDE.md` — human-readable explanation of the update/restore protocol.
- `docs/AGENTS-GUIDE.md` — human-readable guide to trigger phrases and model-pinned agents.

### Changed
- `README.md` — added `.github/agents/`, `AGENTS.md`, `UPDATE.md` to "What this gives you" table; added `docs/` section with links to human guides; updated file tree to match actual repo structure.
- `AGENTS.md` — added four `.github/agents/*.agent.md` entries to file map and bootstrap outputs table.
- `UPDATE.md` — corrected all `## 10. Project-Specific Overrides` references to `## §10 — Project-Specific Overrides`; replaced ASCII-art pre-flight report block with clean markdown table (~1 400 chars saved); updated stale section names in diff example.
- `template/BIBLIOGRAPHY.md` — added "Model-pinned agents" section with all four agent file entries.
- `template/workspace/BOOTSTRAP.md` — added four agent file rows to setup outputs table.
- `SETUP.md` — Step 2.5 now offers fetching agent files directly from the template repo as the preferred option, with inline stubs as fallback.

### Fixed
- `CHANGELOG.md` (this file) — corrected six stale section names that no longer matched the live copilot-instructions.md headings (§1, §2, §5, §6, §7, §9).
- `UPDATE.md` — same six stale section names corrected in the diff table example.
- `AGENTS.md` — same stale section names corrected.

### Refactored
- `.github/copilot-instructions.md` — seven lossless token-saving compressions applied (~63 tokens saved); no semantic change.

---

## [1.0.0] — 2026-02-19

Initial public release. All features below ship in this version.

### Added

#### Core template
- `.github/copilot-instructions.md` — generic Lean/Kaizen instructions template with `{{PLACEHOLDER}}` tokens throughout.
  - §1 Lean Principles (five Lean principles)
  - §2 Operating Modes (Implement / Review / Refactor / Planning)
  - §3 Standardised Work Baselines (LOC, dep budget, test count, type errors)
  - §4 Coding Conventions (language/runtime/patterns/anti-patterns)
  - §5 PDCA Cycle (Plan–Do–Check–Act applied to every change)
  - §6 Waste Catalogue / Muda (seven categories with code examples)
  - §7 Metrics (Kaizen baseline snapshot table + improvement targets)
  - §8 Living Update Protocol (self-edit triggers, procedure, prohibited edits, template update trigger)
  - §9 Subagent Protocol (modes, depth, compact delegation protocol)
  - §10 Project-Specific Overrides (placeholder resolution table + User Preferences slot)
- Template version stamp: `> **Template version**: 1.0.0 | **Applied**: {{SETUP_DATE}}`

#### Setup system
- `SETUP.md` — one-time agentic bootstrap, remote-executable (no manual file copying required).
  - Step 0a: existing instructions detection → Archive / Delete / Merge choice with full merge protocol.
  - Step 0b: existing workspace identity files detection → Keep all / Overwrite all / Selective.
  - Step 0c: existing documentation stubs detection → skip / append entries / create missing only.
  - Step 0d: User Preference Interview — Simple Setup (5 questions) or Advanced Setup (10 questions) or skip-to-defaults.
    - S1 Response style (Concise / Balanced / Thorough)
    - S2 Experience level (Novice / Intermediate / Expert)
    - S3 Primary working mode (Ship / Quality / Learning / Production hardening)
    - S4 Testing expectations (Write always / Suggest / On request / None)
    - S5 Autonomy level (Ask first / Act then summarise / Ask only for risky)
    - A6 Naming & formatting conventions
    - A7 Documentation standard
    - A8 Error handling philosophy
    - A9 Security sensitivity
    - A10 Change reporting format
  - Step 0e: pre-flight summary with 10-second countdown before any writes.
  - Step 2.5: write model-pinned agent files (`.github/agents/`) for VS Code 1.106+.
  - Steps 1–6: stack discovery, placeholder resolution, agent file creation, identity file scaffolding, METRICS baseline, documentation stubs, SETUP.md self-destruct.

#### Model-pinned agents (VS Code 1.106+)
- `.github/agents/setup.agent.md` — Setup agent pinned to Claude Sonnet 4.6 (onboarding & template operations). Fallback: Claude Sonnet 4.5 → GPT-5.1 → GPT-5 mini.
- `.github/agents/coding.agent.md` — Coding agent pinned to GPT-5.3-Codex (implementation & refactoring, GA Feb 9 2026, 25% faster than 5.2-Codex, real-time steering). Fallback: GPT-5.2-Codex → GPT-5.1-Codex → GPT-5.1 → GPT-5 mini.
- `.github/agents/review.agent.md` — Review agent pinned to Claude Opus 4.6 (architectural review, Agent Teams capability, 3× multiplier). Fallback: Claude Opus 4.5 → Claude Sonnet 4.6 → GPT-5.1.
- `.github/agents/fast.agent.md` — Fast agent pinned to Claude Haiku 4.5 (quick questions, 0.33× cost). Fallback: Grok Code Fast 1 → GPT-5 mini → GPT-4.1.

#### Update system
- `UPDATE.md` — update protocol Copilot follows when triggered by "Update your instructions".
- `VERSION` — semver file; read by update pre-flight to detect whether an update is available.
- `CHANGELOG.md` — this file; read by update pre-flight to show changes between versions.

#### Remote operation
- `AGENTS.md` — AI agent entry point. Defines trigger phrases for setup and update. Provides Remote Bootstrap Sequence and Remote Update Sequence.

#### Workspace identity files
- `template/workspace/IDENTITY.md` — agent self-description stub.
- `template/workspace/SOUL.md` — values & reasoning patterns stub.
- `template/workspace/USER.md` — user profile stub.
- `template/workspace/TOOLS.md` — tool usage patterns stub.
- `template/workspace/MEMORY.md` — memory strategy stub.
- `template/workspace/BOOTSTRAP.md` — permanent setup origin record stub.

#### Documentation stubs
- `template/CHANGELOG.md` — Keep-a-Changelog format stub (for consumer projects).
- `template/JOURNAL.md` — ADR-style journal stub.
- `template/BIBLIOGRAPHY.md` — file catalogue stub (includes model-pinned agent file entries).
- `template/METRICS.md` — Kaizen baseline snapshot table stub.

#### Examples
- `examples/valis/README.md` — reference implementation (asafelobotomy/Valis, the first consumer of this template).
