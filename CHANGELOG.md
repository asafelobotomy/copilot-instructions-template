# Changelog — copilot-instructions-template

All notable changes to the **template itself** are recorded here.
This is the upstream version history — not a stub for consumer projects.

Format follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [Semantic Versioning](https://semver.org/).

> **Consumer projects**: your own `CHANGELOG.md` records your project's changes, not this file.

---

## [Unreleased]

### Added
- `§11 — Tool Protocol` in `.github/copilot-instructions.md` — structured decision tree for tool use, adaptation, online search (MCP registry → GitHub → Awesome lists → stack registries → official docs), building from scratch, evaluating reusability, and saving to the toolbox.
- `.copilot/tools/` toolbox convention — lazy-created directory with `INDEX.md` catalogue where agents save reusable tools.
- `AGENTS.md` — "Tool operations" trigger phrase section; `.copilot/tools/INDEX.md` added to setup outputs table and file map; toolbox canonical triggers added.
- `template/workspace/TOOLS.md` — toolbox section explaining how to use `.copilot/tools/` and when to save.
- `template/BIBLIOGRAPHY.md` — Toolbox section stub.
- `template/workspace/BOOTSTRAP.md` — toolbox lazy-creation note.

### Changed
- `§9 — Subagent Protocol` — added sentence: subagents inherit the full Tool Protocol (§11) and must flag proposed toolbox saves to the parent before writing.
- Footer of `.github/copilot-instructions.md` — added `.copilot/tools/` link.

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
