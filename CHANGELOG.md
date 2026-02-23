# Changelog — copilot-instructions-template

All notable changes to the **template itself** are recorded here.
This is the upstream version history — not a stub for consumer projects.

Format follows [Keep a Changelog](https://keepachangelog.com/). Versions follow [Semantic Versioning](https://semver.org/).

> **Consumer projects**: your own `CHANGELOG.md` records your project's changes, not this file.

---

## [Unreleased]

### Added

- `template/hooks/copilot-hooks.json` — agent lifecycle hooks configuration template. Defines five hook events (SessionStart, PreToolUse, PostToolUse, Stop, PreCompact) with bash scripts and Windows PowerShell overrides. Hooks provide deterministic enforcement of security, formatting, and retrospective rules that soft instructions cannot guarantee.
- `template/hooks/scripts/session-start.sh` — SessionStart hook: auto-detects project manifest (package.json, pyproject.toml, Cargo.toml), gathers git branch/commit, runtime versions, and heartbeat pulse; emits project context as `additionalContext` JSON.
- `template/hooks/scripts/guard-destructive.sh` — PreToolUse hook: two-tier pattern matching for dangerous commands. BLOCKED tier (hard deny): `rm -rf /`, `DROP TABLE`, fork bombs, pipe-to-shell. CAUTION tier (user confirmation): `rm -rf`, `git push --force`, `npm publish`. Only intercepts terminal/command tools. Enforces §5 ("Secure by default") deterministically.
- `template/hooks/scripts/post-edit-lint.sh` — PostToolUse hook: language-aware auto-formatting after agent edits. Detects file extension and runs the appropriate formatter (Prettier for JS/TS, Black/Ruff for Python, rustfmt for Rust, gofmt for Go). Only activates for edit/create/write/replace tools. Eliminates W9 (manual repetition) for formatting.
- `template/hooks/scripts/enforce-retrospective.sh` — Stop hook: prevents agent session end if retrospective has not been run. Checks session transcript for retrospective keywords and HEARTBEAT.md mtime. Includes `stop_hook_active` infinite-loop guard.
- `template/hooks/scripts/save-context.sh` — PreCompact hook: preserves critical workspace state before conversation context compaction. Captures heartbeat pulse, recent MEMORY.md entries, SOUL.md heuristics, and git status as `additionalContext`.
- `docs/HOOKS-GUIDE.md` — human-readable hooks guide: hook overview table, five starter hook descriptions, configuration format, adding/disabling hooks, interaction with §5/§6/§8/§10 systems, troubleshooting, security considerations, customisation examples.
- `.github/copilot-instructions.md` — new `### Agent Hooks` subsection in §8: five-hook starter table, JSON protocol description, cross-system interaction summary, link to HOOKS-GUIDE.md.
- `AGENTS.md` — "Hook operations" trigger phrase section (5 phrases); hook entries added to canonical triggers table; hook template files added to file map; hooks line added to "What this repo is" description; `.github/hooks/` added to bootstrap output table.
- `.github/copilot-instructions.md` — new `### 1.5 BUILT-IN` step in §11 Tool Protocol decision tree: documents VS Code's native tools (`list_code_usages`, `get_errors`, `fetch_webpage`, `semantic_search`, `grep_search`) as a discovery step between local toolbox lookup and online search.
- `.github/copilot-instructions.md` — W15 (Tool friction) examples expanded with concrete built-in tool names (`list_code_usages`, `semantic_search`, `get_errors`, `fetch_webpage`) replacing generic descriptions.
- `.github/copilot-instructions.md` — §7 Metrics: `get_errors` built-in added as alternative to `{{TYPE_CHECK_COMMAND}}` for type error tracking.
- `template/workspace/MEMORY.md` — new "Copilot Memory coexistence" section documenting how project-scoped MEMORY.md complements VS Code's native Copilot Memory feature; includes priority rule (MEMORY.md wins for project facts), scope comparison table, and duplication avoidance guidance.
- `docs/INSTRUCTIONS-GUIDE.md` — new "Instruction priority chain" section documenting the four-tier instruction resolution order (file-scoped → repository → organisation → personal) with scope table, practical placement guidance, template interaction notes, and prompt files reference.
- `docs/SECURITY-GUIDE.md` — new `### Custom tier format` subsection under Graduated Trust Model: concrete Markdown table example showing `{{TRUST_OVERRIDES}}` format, glob pattern rules, and tier precedence logic.
- `docs/UPDATE-GUIDE.md` — new `## Notable version migrations` section with manual-action tables for `v1.x → v2.0.0` and `v1.0.x → v1.4.0` upgrades covering companion files (MCP config, skills, release automation) that the update protocol does not touch automatically.
- `template/workspace/HEARTBEAT.md` — event-driven health check checklist template. Agent-writable file with Pulse status, 6 event triggers (session start, large change, refactor/migration, dependency update, CI resolution, explicit), 6 health checks (dependency audit, test coverage delta, waste scan, memory consolidation, metrics freshness, settings drift), Agent Notes, and append-only History table. Adapted from [OpenClaw's heartbeat mechanism](https://docs.openclaw.ai/gateway/heartbeat) with event-triggered execution replacing timed intervals.
- `docs/HEARTBEAT-GUIDE.md` — human-readable guide: event triggers vs OpenClaw's timed approach, cross-file wiring specification, adding custom triggers and checks, silent-when-healthy contract, interaction with §6/§8/§10/MEMORY.md/METRICS.md/TOOLS.md/SOUL.md.
- `.github/copilot-instructions.md` — new `### Heartbeat Protocol` subsection in §8: event trigger list, 6-step procedure (read → check → update Pulse → log History → write Agent Notes → report alerts only), cross-file references.
- `AGENTS.md` — "Heartbeat operations" trigger phrase section (6 phrases); heartbeat entries added to canonical triggers table; `template/workspace/HEARTBEAT.md` and `.copilot/workspace/HEARTBEAT.md` added to file map and bootstrap outputs.
- `template/workspace/HEARTBEAT.md` — Retrospective introspection section: 7 self-reflection questions with cross-file persistence wiring (SOUL.md for reasoning heuristics, USER.md for user profile observations, MEMORY.md for gap analysis and lessons learned, Agent Notes for self-assessment). Q4 (issue report) and Q5 (agent questions) surface directly to the user.
- `template/workspace/HEARTBEAT.md` — "Task completion" event trigger: fires the heartbeat (including retrospective) after completing any user-requested task.
- `AGENTS.md` — "Run retrospective" trigger phrase added to heartbeat operations section and canonical triggers table.

### Changed

- `template/skills/skill-creator/SKILL.md` — trimmed `description` field to a concise one-sentence form matching the §12 recommendation for reliable agent discovery.
- `template/skills/conventional-commit/SKILL.md` — expanded opaque `§10` and `§4`/`§10` references in "When NOT to use" to include `of their project's Copilot instructions`, improving readability when the skill is used outside the template context.
- `SETUP.md` — added release automation callout after Step 2.11 pointing to `docs/RELEASE-AUTOMATION-GUIDE.md` and noting the `release-please-config.json` / `.release-please-manifest.json` requirement for the release-please strategy; Step 0b updated from 6 to 7 identity files (HEARTBEAT.md added); Step 3 expanded with HEARTBEAT.md scaffold section; BOOTSTRAP.md stub updated from "all six" to "all seven" identity files.
- `AGENTS.md` — "Six workspace identity files" → "Seven workspace identity files" in project description.
- `README.md` — added "Event-driven heartbeat" feature section; workspace identity table expanded from 6 to 7 rows (HEARTBEAT.md added); `docs/HEARTBEAT-GUIDE.md` added to human-readable guides table; file tree updated with `HEARTBEAT.md`.
- `template/workspace/BOOTSTRAP.md` — HEARTBEAT.md row added to "Files created during setup" table.
- `template/BIBLIOGRAPHY.md` — HEARTBEAT.md row added to "Workspace identity" section.
- `.github/workflows/ci.yml` — `docs/HEARTBEAT-GUIDE.md` and `template/workspace/HEARTBEAT.md` added to required files check.
- `docs/INSTRUCTIONS-GUIDE.md` — §8 section expanded with "Heartbeat Protocol" subsection explaining event triggers, cross-file wiring, and silent-when-healthy contract.
- `docs/INSTRUCTIONS-GUIDE.md` — §8 Heartbeat Protocol explanation expanded with retrospective self-reflection description and cross-file persistence (SOUL.md, USER.md, MEMORY.md).
- `docs/HEARTBEAT-GUIDE.md` — retrospective section added: 7-question table with cross-file wiring, reporting contract exception for Q4/Q5, customisation example for custom retrospective questions; "How it works" flow updated from 7 to 8 steps; "Sections of HEARTBEAT.md" expanded with Retrospective; interaction table expanded for SOUL.md/USER.md/MEMORY.md retrospective writes; "Run retrospective" trigger phrase added.
- `.github/copilot-instructions.md` — §8 Heartbeat Protocol procedure expanded from 6 to 7 steps: new step 3 runs the Retrospective on task-completion and explicit triggers; "When to fire" list expanded with task completion; step 7 updated with retrospective Q4/Q5 exception to silent-when-healthy rule.
- `docs/SETUP-GUIDE.md` — "Six files" → "Seven files" in Step 3; HEARTBEAT.md row added to identity files table.
- `docs/AGENTS-GUIDE.md` — heartbeat trigger phrases added to canonical triggers table.
- `template/workspace/HEARTBEAT.md` — retrospective questions rewritten for observable anchoring: Q1 now references concrete errors/corrections/backtracking; Q2 replaced ("Ambition check" → "Scope audit") targeting factual scope drift with write target changed from Agent Notes to MEMORY.md (Known Gotchas); Q3 sharpened to compare original request against delivered result; Q4 expanded with example issue categories; Q6 redesigned to remove emotion inference (observable signals only); Q7 now enforces structured "When [situation], do [action]" format. New Q8 "Correction log" added — captures user corrections as highest-value feedback signal. Research grounding: Reflexion (Shinn et al., NeurIPS 2023), ExpeL (Zhao et al., 2024), Limits of Self-Correction (Huang et al., 2024).
- `docs/INSTRUCTIONS-GUIDE.md` — retrospective description updated from 7 to 8 questions; "reasoning" → "reasoning heuristics"; "observable events" qualifier added.
- `docs/HEARTBEAT-GUIDE.md` — retrospective section updated from 7 to 8 questions; question table rewritten with observable-anchored wording; new "Design rationale" subsection with research citations; reporting contract updated (Q1–3, Q6–8 silent); interaction table updated for scope audit (Q2), correction log (Q8); customisation example renumbered.

### Fixed

- `docs/UPDATE-GUIDE.md` — stale `§1–§12` section range in v1.x→v2.0.0 migration note changed to "§1 through §12"; resolves cross-reference consistency CI failure.
- `.github/workflows/ci.yml` — replaced SC2015-flagged `A && B || C` patterns in "Release workflow mutual exclusion" step with `if` statements; resolves actionlint (Workflow lint) CI failure.

---

## [2.0.0] — 2026-02-21

### Breaking changes

- **New §13 — Model Context Protocol (MCP)** — section count changes from 12 to 13. CI, CONTRIBUTING.md, and UPDATE.md all reference section count and are updated accordingly. Existing consumer repos running the update protocol will encounter the new section.
- **Step 2.12** generates `.vscode/mcp.json` — changes the scaffolding file output. Existing setups are unaffected (MCP defaults to "None").
- **22 interview questions** (was 21) — E22 added to Expert tier. Simple and Advanced tiers get sensible defaults.

### Added

- **§13 — Model Context Protocol (MCP)** in `.github/copilot-instructions.md` — subsections: MCP server tiers (always-on / credentials-required / stack-specific), server configuration (references `.vscode/mcp.json`), MCP decision tree (built-in tool → MCP server → community package → custom tool), server quality gate (4 checks), available server reference table with `{{MCP_STACK_SERVERS}}` and `{{MCP_CUSTOM_SERVERS}}` placeholders.
- **`template/vscode/mcp.json`** — preconfigured MCP server template with 5 official servers: filesystem, memory, git (always-on, enabled), github, fetch (credentials-required, disabled by default). Uses `${workspaceFolder}` and `${env:GITHUB_TOKEN}` variables.
- **`template/skills/mcp-builder/SKILL.md`** — starter skill adapted from Anthropic's official library. 7-step workflow: clarify purpose, choose transport (stdio/SSE/streamable HTTP), scaffold project, implement handlers, test with MCP Inspector, register in `.vscode/mcp.json`, document.
- **`template/skills/webapp-testing/SKILL.md`** — starter skill adapted from Anthropic's official library. 7-step Playwright-based e2e testing workflow: detect framework, install runner, scaffold test structure, write first test, verify passing, add to CI, document.
- **E22 — MCP server configuration** interview question added to `SETUP.md` Expert tier (batch 7). Three options: None (default) / Always-on only / Full configuration. Maps to `{{MCP_STACK_SERVERS}}` and `{{MCP_CUSTOM_SERVERS}}` placeholders.
- **SETUP.md Step 2.12** — MCP configuration scaffolding: fetch template, create `.vscode/mcp.json`, configure by E22 answer, stack-specific server discovery from Step 1 dependencies (PostgreSQL, SQLite, Redis, Docker, AWS, Puppeteer), populate §13 placeholders.
- **`docs/MCP-GUIDE.md`** — human-readable guide: MCP overview, three-tier server classification, `.vscode/mcp.json` configuration, adding custom servers, stack-specific discovery, credential security, quality gate, troubleshooting, interaction with §11 Tool Protocol and §12 Skill Protocol.
- **`.github/workflows/release-please.yml`** — automated release workflow using `googleapis/release-please-action@v4` (SHA-pinned). Generates PRs from Conventional Commits, auto-bumps VERSION, creates GitHub releases. Coexists with manual workflow — enable one, disable the other.
- **`docs/RELEASE-AUTOMATION-GUIDE.md`** — human-readable guide comparing manual (`release-manual.yml`) and automated (`release-please.yml`) release strategies with trade-off table, switching instructions, configuration reference, and Conventional Commits quick reference.
- MCP operations trigger phrases in `AGENTS.md`: "Configure MCP servers", "Add an MCP server", "Show MCP servers", "Check MCP configuration".

### Changed

- `.github/copilot-instructions.md` — added §13 MCP Protocol; §9 Subagent Protocol updated to reference §13; §10 User Preferences table expanded from 21 to 22 rows (E22 added); template version stamp updated to `2.0.0`.
- `.github/workflows/ci.yml` — §1–§12 section check updated to §1–§13; `docs/MCP-GUIDE.md`, `docs/RELEASE-AUTOMATION-GUIDE.md`, and `template/vscode/mcp.json` added to required files check.
- `.github/workflows/release.yml` → renamed to `.github/workflows/release-manual.yml` (content unchanged).
- `SETUP.md` — Expert tier expanded from 6 to 7 questions (E16–E22); batch 7 updated (E20, E21, E22); all defaults tables, verification gate counts, pre-flight summary, and Step 6 summary updated from 21 → 22 dimensions; Step 2.12 added after Step 2.11; MCP CONFIGURATION section added to Step 6 summary.
- `CONTRIBUTING.md` — CI checklist reference updated from §1–§12 to §1–§13.
- `AGENTS.md` — MCP operations trigger phrase section added; file map expanded with `template/vscode/mcp.json`, `template/skills/mcp-builder/SKILL.md`, `template/skills/webapp-testing/SKILL.md`; bootstrap outputs expanded with `.vscode/mcp.json`; skills count 4 → 6; canonical triggers table expanded with MCP entries.
- `docs/INSTRUCTIONS-GUIDE.md` — "twelve numbered sections" → "thirteen numbered sections (§1–§13)"; §13 MCP section guide added.
- `docs/SETUP-GUIDE.md` — Expert question count E16–E20 → E16–E22; "20-row" → "22-row"; E21 and E22 added to question table; Step 2.12 section added.
- `.github/ISSUE_TEMPLATE/bug_report.yml` — "MCP Protocol (§13)" added to area dropdown.
- `README.md` — version badge `2.0.0`; "Thirteen-section" heading; "MCP integration" feature section; 6 starter skills (was 4); `.vscode/mcp.json` in scaffolding table; `docs/MCP-GUIDE.md` and `docs/RELEASE-AUTOMATION-GUIDE.md` in docs table; file tree updated with MCP files, release workflows, and new skills.

---

## [1.4.0] — 2026-02-21

### Added

- **SHA-pinned all GitHub Actions** — every `uses:` reference across all 6 workflow files now points to an immutable commit SHA (e.g., `actions/checkout@34e114876b…`). Dependabot auto-updates pinned SHAs via `.github/dependabot.yml`.
- **`step-security/harden-runner`** added as the first step in every CI job across all workflows — monitors network egress in `audit` mode to detect supply-chain compromise.
- **`.github/workflows/scorecard.yml`** — OpenSSF Scorecard analysis runs weekly and on push to `main`. Uploads SARIF results to GitHub code scanning for continuous security posture monitoring.
- **Graduated Trust Model** in `§10 — Project-Specific Overrides` — new `### Verification Levels` subsection with a three-tier table (High / Standard / Guarded) that maps file path patterns to verification behaviour (auto-approve / review / pause). New `{{TRUST_OVERRIDES}}` placeholder for project-specific trust customisation.
- **`compatibility` and `allowed-tools`** optional frontmatter fields added to the §12 Skill Protocol anatomy. `compatibility` declares the minimum template version a skill requires; `allowed-tools` declares which tool categories a skill may use.
- **E21 — Verification trust** interview question added to `SETUP.md` Expert tier (batch 7). Four options: Use defaults / Trust everything / Review everything / Custom tiers. Maps to `{{TRUST_OVERRIDES}}` placeholder.
- **`docs/SECURITY-GUIDE.md`** — human-readable guide covering SHA-pinning rationale, harden-runner usage (audit → block upgrade path), OpenSSF Scorecard interpretation, Graduated Trust Model, skill security fields, Dependabot configuration, and a security checklist.

### Changed

- `.github/workflows/ci.yml` — SHA-pinned all actions; added harden-runner to all 3 jobs; new advisory (non-blocking) check for `compatibility` and `allowed-tools` fields in template skills; added `docs/SECURITY-GUIDE.md` to required files.
- `.github/workflows/release.yml` — SHA-pinned all actions; added harden-runner.
- `.github/workflows/stale.yml` — SHA-pinned all actions; added harden-runner.
- `.github/workflows/links.yml` — SHA-pinned all actions; added harden-runner.
- `.github/workflows/vale.yml` — SHA-pinned all actions; added harden-runner.
- `.github/copilot-instructions.md` — §10 expanded with Graduated Trust Model and `Verification trust` row in User Preferences table; §12 skill anatomy expanded with `compatibility` and `allowed-tools` fields and explanatory text.
- All 4 starter skills (`skill-creator`, `fix-ci-failure`, `lean-pr-review`, `conventional-commit`) — added `compatibility: ">=1.4"` and role-appropriate `allowed-tools` frontmatter.
- `SETUP.md` — Expert tier expanded from 5 to 6 questions (E16–E21); batch 7 updated (E20, E21); all defaults tables, verification gate counts, pre-flight summary, and Step 6 summary updated from 20 → 21 dimensions.
- `README.md` — version badge `1.4.0`; OpenSSF Scorecard badge; "Security hardening" feature section; `scorecard.yml` in file tree; `SECURITY-GUIDE.md` in docs table and file tree.

---

## [1.3.0] — 2026-02-21

### Added

- **Path-specific instruction files** (`.github/instructions/`) — 4 starter stubs with `applyTo:` glob frontmatter for context-aware Copilot guidance:
  - `tests.instructions.md` — rules for test files (`**/*.test.*`, `**/*.spec.*`, `**/tests/**`, `**/__tests__/**`)
  - `api-routes.instructions.md` — rules for API route handlers (`**/api/**`, `**/routes/**`, `**/controllers/**`, `**/handlers/**`)
  - `config.instructions.md` — rules for configuration files (`**/*.config.*`, `**/.*rc`, `**/.*rc.json`)
  - `docs.instructions.md` — rules for documentation (`**/*.md`, `**/docs/**`)
- **Reusable prompt files** (`.github/prompts/`) — 5 starter prompt files that become VS Code slash commands:
  - `explain.prompt.md` → `/explain` — waste-aware code explanation using §6 categories
  - `refactor.prompt.md` → `/refactor` — Lean-principled refactoring with full PDCA cycle
  - `test-gen.prompt.md` → `/test-gen` — generate tests following project conventions and framework
  - `review-file.prompt.md` → `/review-file` — single-file review using §2 Review Mode protocol
  - `commit-msg.prompt.md` → `/commit-msg` — Conventional Commits message from staged changes
- **`template/copilot-setup-steps.yml`** — GitHub Actions workflow template for Copilot coding agent environment setup. Contains commented-out sections for Node.js/Bun, Python, Go, and Rust runtimes; populated during setup based on detected stack.
- **`SETUP.md` Steps 2.9, 2.10, 2.11** — three new setup steps between the skills scaffold (2.8) and workspace identity (3):
  - Step 2.9: path-specific instruction scaffolding — detects relevant file patterns, copies matching stubs, populates placeholders
  - Step 2.10: prompt file scaffolding — copies all five starter prompts, substitutes placeholders
  - Step 2.11: copilot-setup-steps scaffolding — detects runtime, generates `.github/workflows/copilot-setup-steps.yml` for the Copilot coding agent
- **`.github/workflows/links.yml`** — Lychee link checker: weekly cron schedule + PR-triggered on `*.md` changes. Validates all Markdown links with configurable exclusions.
- **`.github/workflows/vale.yml`** — Vale prose linter: PR-triggered on `*.md` changes. Posts review comments via `errata-ai/vale-action@v2.1.1`.
- **`.vale.ini`** — Vale configuration file using built-in Vale style as baseline. Custom styles go in `.github/vale/styles/`.
- **`docs/PATH-INSTRUCTIONS-GUIDE.md`** — human-readable guide: `applyTo:` glob syntax, precedence rules, how path instructions augment the main file, starter stubs, creating custom instruction files.
- **`docs/PROMPTS-GUIDE.md`** — human-readable guide: how prompt files become slash commands, naming conventions, variable substitution (`${file}`, `${selection}`, `${input:varName}`), the 5 starters, creating custom prompts.

### Changed

- `.github/workflows/ci.yml` — added `docs/PATH-INSTRUCTIONS-GUIDE.md`, `docs/PROMPTS-GUIDE.md`, and `template/copilot-setup-steps.yml` to required files check.
- `.github/PULL_REQUEST_TEMPLATE.md` — added 3 checklist items: path-specific instructions updated, prompt files reviewed, copilot-setup-steps.yml updated.
- `README.md` — version badge `1.3.0`; added "Path-specific instructions" and "Reusable prompt files" feature sections; scaffolding table expanded with instruction stubs, prompt files, and copilot-setup-steps; docs table expanded with PATH-INSTRUCTIONS-GUIDE and PROMPTS-GUIDE; file tree updated with `instructions/`, `prompts/`, `links.yml`, `vale.yml`, `copilot-setup-steps.yml`, `.vale.ini`, `dependabot.yml`, and 2 new doc guides.

---

## [1.2.0] — 2026-02-20

### Added

- `§6 — Waste Catalogue` expanded with 8 AI-specific waste categories (W9–W16): Prompt waste, Context window waste, Hallucination rework, Verification overhead, Prompt engineering debt, Model-task mismatch, Tool friction, Over/under-trust. Grounded in DORA 2025 research, Stack Overflow Developer Survey 2024, and Claude Code best practices documentation.
- `template/METRICS.md` — 6 new columns: Deploy Freq, Lead Time, CFR, MTTR, AI Accept Rate, Context Resets. New `## DORA definitions` section with Green/Warn/High thresholds. 4 new placeholder tokens (`{{DEPLOY_FREQ_TARGET}}`, `{{LEAD_TIME_TARGET}}`, `{{CFR_TARGET}}`, `{{MTTR_TARGET}}`).
- `.github/workflows/ci.yml` — new `actionlint:` job using `raven-actions/actionlint@v2`; catches expression type errors, script injection, and unknown inputs in workflow files.
- `.github/dependabot.yml` — GitHub Actions dependency management with weekly schedule, grouped minor/patch updates, conventional commit prefix (`ci`), and 5-PR limit.
- `template/workspace/MEMORY.md` — 4 new structured agent-writable sections: Architectural Decisions, Recurring Error Patterns, Team Conventions Discovered, Known Gotchas (all as append-only tables). New `## Maintenance Protocol` section with quarterly review cadence.
- `.github/ISSUE_TEMPLATE/bug_report.yml` — added area options: Skills Protocol (§12), Waste Catalogue (§6).
- `.github/ISSUE_TEMPLATE/feature_request.yml` — added area options: Skills Protocol (§12), Waste Catalogue (§6), Path-Specific Instructions, Prompt Files, MCP Integration.

### Changed

- `.github/workflows/stale.yml` — upgraded from `actions/stale@v9` to `@v10` (Node 24 runtime); added `exempt-draft-pr: true`.
- `.github/workflows/ci.yml` — upgraded `DavidAnson/markdownlint-cli2-action` from `@v16` to `@v22`.

### Fixed

- `CONTRIBUTING.md` — corrected stale CI checklist reference from `§1–§11` to `§1–§12` (§12 was added in v1.1.0 but CONTRIBUTING.md was not updated).

---

## [1.1.0] — 2026-02-19

### Added

- `§12 — Skill Protocol` in `.github/copilot-instructions.md` — structured discovery decision tree (SCAN local → SEARCH registries → CREATE), scope hierarchy (project → personal → community), community quality gate checklist, seven authoring rules, lifecycle table, Skill vs Tool comparison table, subagent skill-save rules.
- `A15 — Skill search preference` — new Advanced-tier interview question with three options: `local-only` (default), `official-only`, `official-and-community`. Written to `{{SKILL_SEARCH_PREFERENCE}}` placeholder in §10 User Preferences.
- `template/skills/skill-creator/SKILL.md` — meta-skill that teaches the agent how to author new skills following §12.
- `template/skills/fix-ci-failure/SKILL.md` — systematic CI / GitHub Actions failure diagnosis and resolution skill.
- `template/skills/lean-pr-review/SKILL.md` — Lean waste-categorised PR review skill with severity ratings and structured report template.
- `template/skills/conventional-commit/SKILL.md` — Conventional Commits message authoring skill with type table and scope rules.
- `SETUP.md` Step 2.8 — skills scaffolding step: fetches four starter skills from the template repo (with inline-stub fallback), writes to `.github/skills/`, populates `SKILL_SEARCH_PREFERENCE` in §10.
- `docs/SKILLS-GUIDE.md` — human-readable guide to Agent Skills: what they are, where they live, discovery, anatomy, search preference, creating skills, Skills vs Tools comparison, community ecosystem, quality gate, trigger phrases.
- `AGENTS.md` — "Skill operations" trigger phrase section (5 phrases); four template skill files and `.github/skills/<name>/SKILL.md` added to file map; skills row in bootstrap output table; three skill-related canonical triggers.
- `.github/workflows/ci.yml` — new "Template skills have valid SKILL.md" validation step (checks `name` + `description` frontmatter in every `template/skills/*/SKILL.md`).

### Changed

- `.github/copilot-instructions.md` — §9 Subagent Protocol updated to reference §12 skill inheritance; §10 User Preferences table expanded from 19 to 20 rows (`SKILL_SEARCH_PREFERENCE` added as A15); Expert questions renumbered E16–E20 (were E15–E19). Template version stamp updated from `1.0.3` to `1.1.0`.
- `SETUP.md` — batch plan updated (batch 5 now covers A14 + A15); question counts updated (Advanced: 14 → 15, Expert: 19 → 20); Expert headings renumbered E16–E20; all defaults tables updated; verification gate counts changed to 5/15/20; §0e pre-flight template expanded (20 prefs, Skill search label, Step 2.8 in NEXT STEPS); Step 6 summary template updated (SKILLS section, skills in BIBLIOGRAPHY stub); BOOTSTRAP stub updated.
- `README.md` — version badge `1.1.0`; "Twelve-section" heading; "📚 Agent Skills library" feature block; skills scaffolding entry in "What gets scaffolded" table; `SKILLS-GUIDE.md` in docs table; layout tree expanded with `skills/` directories and `SKILLS-GUIDE.md`; §1–§12 references updated throughout.
- `.github/workflows/ci.yml` — §1–§11 section check updated to §1–§12; `docs/SKILLS-GUIDE.md` added to required files.
- `docs/INSTRUCTIONS-GUIDE.md` — "eleven numbered sections" → "twelve numbered sections (§1–§12)"; added full §12 writeup with Scan/Search/Create stages and customisation guidance.
- `docs/SETUP-GUIDE.md` — question counts updated (14 → 15, 19 → 20); A15 row added to question table; Expert rows renumbered E16–E20; "19-row" → "20-row" User Preferences; Step 2.8 skills scaffolding section added.
- `template/workspace/BOOTSTRAP.md` — skills row added to files table; new "Skills" section explaining `.github/skills/`.

---

## [1.0.3] — 2026-02-19

### Fixed

- `docs/SETUP-GUIDE.md` §0d — rewrote preference interview section for 3-tier system (was still describing old 2-tier with "5 or 10 questions" and missing A11–A14 / E15–E19).
- `docs/INSTRUCTIONS-GUIDE.md` — corrected "ten numbered sections (§1–§10)" → "eleven numbered sections (§1–§11)"; added full §11 Tool Protocol section writeup.
- `docs/AGENTS-GUIDE.md` — corrected stale "handles the 10-question interview" → "handles the 3-tier preference interview (5–19 questions)".
- `README.md` file tree — moved `SETUP.md` to correct root-level position (was shown inside `.github/`); removed phantom `.copilot/tools/` directory that doesn't exist in the template repo.
- `README.md` "What this gives you" table — clarified that paths are scaffolded into consumer projects during setup (was showing raw `template/` paths).
- `README.md` manual setup instructions — fixed reversed copy paths (step 1 = `copilot-instructions.md` → `.github/`, step 2 = `SETUP.md` → project root).
- Markdownlint: 149 pre-existing errors across 17 files (MD022, MD028, MD031, MD032, MD040, MD024, MD012) — all resolved. CI markdown lint job now passes clean.
- `SETUP.md` §0d — root-cause fix: `ask_questions` tool hard-limits 4 questions/call and 6 options/question; the previous instruction to "present all questions in a single interaction" was physically impossible and caused agent models to improvise or skip the interview entirely. Restructured into mandatory batched calls.
- `SETUP.md` E16 (Persona) — reduced from 7 options (A–G) to 6 options (A–F) to fit the tool's 6-option hard limit; the tool's built-in "Other" option now covers custom persona input (option G was redundant).

### Added

- `LICENSE` — MIT license (README referenced MIT but no file existed).
- `CONTRIBUTING.md` — contributor guide covering issue reporting, PR process, style conventions, and code of conduct.
- `.gitignore` — excludes `node_modules/`, `package.json`, `package-lock.json`.
- CI infrastructure:
  - `.github/workflows/ci.yml` — validates VERSION semver, CHANGELOG entries, all required files, §1–§11 sections, README docs-table links, merge-conflict markers, and placeholder token count on every push and PR
  - `.github/workflows/release.yml` — auto-creates a tagged GitHub release when `VERSION` is bumped on `main`; extracts notes from the matching CHANGELOG section
  - `.github/workflows/stale.yml` — marks issues/PRs stale after 30 days, closes after 37
  - `.markdownlint.json` — markdown lint rules (MD013/MD033/MD036/MD041 disabled; MD024 siblings-only)
  - `.github/PULL_REQUEST_TEMPLATE.md` — PR checklist auto-shown on new PRs
  - `.github/ISSUE_TEMPLATE/bug_report.yml` — structured bug report form
  - `.github/ISSUE_TEMPLATE/feature_request.yml` — structured feature request form
- `§2 Test Coverage Review` subsection in `.github/copilot-instructions.md`.
- `AGENTS.md` — test coverage review and extension review trigger phrase sections.
- `docs/TEST-REVIEW-GUIDE.md` — plain-English guide to the test coverage review feature.
- `SETUP.md` — ⛔ **Mandatory Interactive Protocol** stop-sign block in preamble: explains that Codex/autonomous models cannot present interactive prompts and instructs the agent to stop and warn the user if it cannot ask questions interactively.
- `SETUP.md` — dedicated **Tooling and Batch Plan** sub-section with a full 7-batch table (Batches 1–2: Simple, 3–5: Advanced, 6–7: Expert), tool constraint notes, suggested `ask_questions` headers, and per-tier question manifests.
- `SETUP.md` — ⛔ **Interactive checkpoint** inside the §0d section header, instructing the agent to ask every batch and wait for the user's typed response.
- `SETUP.md` — **Interview Verification Gate** between the interview and §0e: tier/count check table with explicit STOP instruction if the answer count doesn't match the selected tier.
- `SETUP.md` — **Rigid template directives** above §0e and the Step 6 summary: "Output the template below exactly — fill every `<label>` field."
- `SETUP.md` inline `setup.agent.md` stub + `.github/agents/setup.agent.md` — four new guidelines: interactive interview rule, batch plan usage, answer count verification, template-copy requirement.
- `.github/copilot-instructions.md` — ⚠️ Codex model warning in **Model Quick Reference** table: Codex models are autonomous and cannot present interactive prompts; never use for setup.
- `AGENTS.md` — ⚠️ Codex model warning in "What this repo is" section.
- `README.md` — ⚠️ Codex model warning in Quickstart section.

### Changed

- `.github/copilot-instructions.md` §10 User Preferences — expanded blank stub to a 19-row table template showing all preference dimensions (S1–E19) with empty Setting / Instruction columns ready for population.
- `.github/workflows/ci.yml` — added `LICENSE` and `CONTRIBUTING.md` to required-files check.
- `SETUP.md` §0d — preference interview expanded from 2-tier (Simple 5 / Advanced 10) to **3-tier** (Simple 5 / Advanced +9 / Expert +5 = 19 total). All tiers produce an equally-capable agent; higher tiers unlock deeper customisation:
  - Simple (S1–S5): response style, experience level, primary mode, testing, autonomy
  - Advanced (A6–A14): code style, file size discipline, dependency management, instruction self-editing, refactoring appetite, change reporting
  - Expert (E15–E19): tool/dependency availability, agent persona, VS Code settings, global autonomy failsafe, mood lightener
- `README.md` — full overhaul: centred header, CI/version/license/VS Code badges, Key Features section (eleven-section architecture, four model-pinned agents, living update protocol, workspace identity system, Kaizen baseline, extension and test-coverage review), scaffolding table, human-readable guides table, repository layout tree, philosophy section, reference implementation section.
- `README.md` — Setup agent role updated in agents table to reflect "batched interview with verification gate".
- Template version stamp updated from `1.0.0` → `1.0.3`.

### Performance

- Lossless token-reduction pass across `copilot-instructions.md` and `AGENTS.md` (23 targeted substitutions, zero semantic change):
  - `copilot-instructions.md`: −163 words / −1 048 chars
  - `AGENTS.md`: −254 words / −1 614 chars
  - Combined: −417 words / −2 662 chars (**7.6% reduction**)

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
