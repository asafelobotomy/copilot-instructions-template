# Implementation Plan: copilot-instructions-template Enhancements

Based on comprehensive research across GitHub Copilot docs (v1.97-v1.101), Agent Skills spec (agentskills.io), MCP ecosystem (300+ servers), DORA 2025 research, GitHub Actions 2025-2026 features, and community frameworks (awesome-copilot 21.9k stars, awesome-cursorrules 37.9k stars, Claude Code sub-agent system).

---

## Release 1: v1.2.0 -- "Waste Taxonomy & CI Hardening"

**Impact: HIGH | Effort: LOW | Risk: LOW**
Pure documentation + config changes. No structural changes to SETUP.md steps.

### Changes

| # | Change | Files | Priority |
|---|--------|-------|----------|
| 1 | **Add W9-W16 to section 6 Waste Catalogue** -- 8 AI-specific waste categories: Prompt Waste, Context Window Waste, Hallucination Rework, Verification Overhead, Prompt Engineering Debt, Model-Task Mismatch, Tool Friction, Over/Under-Trust | `.github/copilot-instructions.md` (append to section 6 table after W8) | HIGH |
| 2 | **Add DORA + AI metrics to METRICS.md** -- 6 new columns: Deploy Freq, Lead Time, CFR, MTTR, AI Accept Rate, Context Resets. New `## DORA definitions` section with Green/Warn/High thresholds. 4 new placeholder tokens (`{{DEPLOY_FREQ_TARGET}}`, `{{LEAD_TIME_TARGET}}`, `{{CFR_TARGET}}`, `{{MTTR_TARGET}}`) | `template/METRICS.md` | HIGH |
| 3 | **Add actionlint to CI** -- New `actionlint:` job using `raven-actions/actionlint@v2`. Catches expression errors, script injection, unknown inputs in workflow files | `.github/workflows/ci.yml` | HIGH |
| 4 | **Create dependabot.yml** -- `github-actions` ecosystem, weekly schedule, `groups:` to batch minor/patch updates, `commit-message.prefix: "ci"`, `open-pull-requests-limit: 5` | `.github/dependabot.yml` (new) | HIGH |
| 5 | **Upgrade stale to v10** -- `actions/stale@v9` to `@v10` (Node 24). Add `exempt-draft-pr: true` | `.github/workflows/stale.yml` | MEDIUM |
| 6 | **Upgrade markdownlint-cli2-action to v22** -- `@v16` to `@v22` | `.github/workflows/ci.yml` | MEDIUM |
| 7 | **Enhance MEMORY.md stub** -- Add 4 structured sections: Architectural Decisions, Recurring Error Patterns, Team Conventions Discovered, Known Gotchas (all as agent-writable tables). Add `## Maintenance Protocol` referencing quarterly review cadence | `template/workspace/MEMORY.md` | MEDIUM |
| 8 | **Update issue template area dropdowns** -- Add: `Skills Protocol (section 12)`, `Waste Catalogue (section 6)`. In feature_request.yml also add forward-looking: `Path-Specific Instructions`, `Prompt Files`, `MCP Integration` | `.github/ISSUE_TEMPLATE/bug_report.yml`, `.github/ISSUE_TEMPLATE/feature_request.yml` | LOW |
| 9 | **Fix CONTRIBUTING.md stale reference** -- `section 1-section 11` to `section 1-section 12` (section 12 was added in v1.1.0 but CONTRIBUTING.md was not updated) | `CONTRIBUTING.md` | LOW |

### All files touched

| Path | Action |
|------|--------|
| `.github/copilot-instructions.md` | Modify: append W9-W16 to section 6 |
| `.github/workflows/ci.yml` | Modify: add actionlint job, upgrade markdownlint |
| `.github/workflows/stale.yml` | Modify: upgrade v9 to v10, add exempt-draft-pr |
| `.github/dependabot.yml` | **Create** |
| `template/METRICS.md` | Modify: add DORA columns + definitions |
| `template/workspace/MEMORY.md` | Modify: add structured sections |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Modify: add area options |
| `.github/ISSUE_TEMPLATE/feature_request.yml` | Modify: add area options |
| `CONTRIBUTING.md` | Modify: fix section reference |
| `CHANGELOG.md` | Modify: add v1.2.0 entry |
| `VERSION` | Modify: 1.1.0 -> 1.2.0 |

### Verification

1. `actionlint .github/workflows/*.yml` -- passes with no errors
2. `grep -c '| W' .github/copilot-instructions.md` -- returns 16 (W1-W16)
3. `grep 'section 1.*section 12' CONTRIBUTING.md` -- finds corrected reference
4. Push to branch, confirm all CI checks pass including new actionlint job

---

## Release 2: v1.3.0 -- "Context Precision"

**Impact: HIGH | Effort: MEDIUM | Risk: LOW**
Introduces path-specific instructions, reusable prompt files, link checking, and prose linting. Adds 3 new SETUP.md steps (2.9, 2.10, 2.11).

### Changes

| # | Change | Files | Priority |
|---|--------|-------|----------|
| 1 | **Path-specific `.instructions.md` stubs** -- 4 starter files with `applyTo:` glob frontmatter for tests, API routes, config files, and docs. Each has `{{PLACEHOLDER}}` tokens for project customization | `.github/instructions/tests.instructions.md`, `api-routes.instructions.md`, `config.instructions.md`, `docs.instructions.md` (all new) | HIGH |
| 2 | **Reusable `.prompt.md` slash commands** -- 5 starter prompt files: `/explain` (waste-aware code analysis), `/refactor` (Lean-principled), `/test-gen` (convention-following), `/review-file` (section 2 Review Mode), `/commit-msg` (conventional commit) | `.github/prompts/explain.prompt.md`, `refactor.prompt.md`, `test-gen.prompt.md`, `review-file.prompt.md`, `commit-msg.prompt.md` (all new) | HIGH |
| 3 | **SETUP.md Step 2.9** -- Path-specific instruction scaffolding: detect relevant globs from Step 1 stack discovery, copy matching stubs, populate placeholders, skip irrelevant files | `SETUP.md` | HIGH |
| 4 | **SETUP.md Step 2.10** -- Prompt file scaffolding: copy all starter prompts, customize section references | `SETUP.md` | HIGH |
| 5 | **SETUP.md Step 2.11** -- Copilot setup steps scaffolding: detect runtime, generate `.github/copilot-setup-steps.yml` with install/build/test steps for the coding agent | `SETUP.md` + `template/copilot-setup-steps.yml` (new) | MEDIUM |
| 6 | **Lychee link checking workflow** -- Weekly cron + PR-triggered for `*.md` changes. `lycheeverse/lychee-action@v2` | `.github/workflows/links.yml` (new) | MEDIUM |
| 7 | **Vale prose linting workflow** -- PR-triggered for `*.md` changes. `errata-ai/vale-action@v2.1.1` with PR review reporter | `.github/workflows/vale.yml` (new), `.vale.ini` (new), `.github/vale/styles/.gitkeep` (new) | MEDIUM |
| 8 | **docs/PATH-INSTRUCTIONS-GUIDE.md** -- Human guide: `applyTo:` glob syntax, precedence rules, how path instructions augment (not replace) the main file, examples from stubs | `docs/PATH-INSTRUCTIONS-GUIDE.md` (new) | MEDIUM |
| 9 | **docs/PROMPTS-GUIDE.md** -- Human guide: how prompt files become VS Code slash commands, naming conventions, variable substitution (`${file}`, `${selection}`, `${input:varName}`), the 5 starters | `docs/PROMPTS-GUIDE.md` (new) | MEDIUM |
| 10 | **Enhance PR template** -- Add 3 checklist items: path-specific instructions updated, prompt files reviewed, copilot-setup-steps.yml updated | `.github/PULL_REQUEST_TEMPLATE.md` | LOW |
| 11 | **Update CI required files** -- Add `docs/PATH-INSTRUCTIONS-GUIDE.md`, `docs/PROMPTS-GUIDE.md` to presence check | `.github/workflows/ci.yml` | LOW |
| 12 | **Update README docs-table** -- Add rows for 2 new guides | `README.md` | LOW |

### All files touched

| Path | Action |
|------|--------|
| `.github/instructions/tests.instructions.md` | **Create** |
| `.github/instructions/api-routes.instructions.md` | **Create** |
| `.github/instructions/config.instructions.md` | **Create** |
| `.github/instructions/docs.instructions.md` | **Create** |
| `.github/prompts/explain.prompt.md` | **Create** |
| `.github/prompts/refactor.prompt.md` | **Create** |
| `.github/prompts/test-gen.prompt.md` | **Create** |
| `.github/prompts/review-file.prompt.md` | **Create** |
| `.github/prompts/commit-msg.prompt.md` | **Create** |
| `template/copilot-setup-steps.yml` | **Create** |
| `.github/workflows/links.yml` | **Create** |
| `.github/workflows/vale.yml` | **Create** |
| `.vale.ini` | **Create** |
| `.github/vale/styles/.gitkeep` | **Create** |
| `docs/PATH-INSTRUCTIONS-GUIDE.md` | **Create** |
| `docs/PROMPTS-GUIDE.md` | **Create** |
| `SETUP.md` | Modify: add Steps 2.9, 2.10, 2.11 |
| `.github/PULL_REQUEST_TEMPLATE.md` | Modify: add checklist items |
| `.github/workflows/ci.yml` | Modify: add required files |
| `README.md` | Modify: add docs-table rows |
| `CHANGELOG.md` | Modify: add v1.3.0 entry |
| `VERSION` | Modify: 1.2.0 -> 1.3.0 |

### SETUP.md step numbering after this release

```
0a-0e (preflight) -> 1 (stack discovery) -> 2 (populate instructions) ->
2.5 (agents) -> 2.8 (skills) -> 2.9 (path instructions) -> 2.10 (prompts) ->
2.11 (copilot-setup-steps) -> 3 (workspace) -> 4 (metrics) -> 5 (doc stubs) ->
6 (finalize)
```

### Verification

1. Each `.instructions.md` has valid YAML frontmatter: `head -3 .github/instructions/*.instructions.md`
2. Each `.prompt.md` has a `#` title and references at least one `section N`
3. `actionlint .github/workflows/links.yml .github/workflows/vale.yml` -- passes
4. `gh workflow run links.yml` -- manual trigger succeeds
5. Open test PR modifying a `.md` file -- vale runs and posts review comments
6. All CI checks pass

---

## Release 3: v1.4.0 -- "Security & Trust"

**Impact: HIGH | Effort: MEDIUM | Risk: LOW-MEDIUM**
SHA-pinning all actions is a systematic change across all workflow files.

### Changes

| # | Change | Files | Priority |
|---|--------|-------|----------|
| 1 | **SHA-pin all GitHub Actions** -- Convert every `uses: org/action@vN` to `uses: org/action@<sha> # vN` across all 5+ workflow files. Dependabot will auto-update pinned SHAs | All `.github/workflows/*.yml` | HIGH |
| 2 | **Add harden-runner to all CI jobs** -- `step-security/harden-runner@v2` with `egress-policy: audit` as first step in every job | All `.github/workflows/*.yml` | HIGH |
| 3 | **Add OpenSSF Scorecard workflow** -- Weekly + push-to-main. Uploads SARIF to GitHub code scanning | `.github/workflows/scorecard.yml` (new) | HIGH |
| 4 | **Graduated Trust Model in section 10** -- New `### Verification Levels` subsection. 6-row table mapping path patterns to trust tiers (High/Standard/Guarded) with verification behavior (auto-approve / review / pause). New `{{TRUST_OVERRIDES}}` placeholder | `.github/copilot-instructions.md` | HIGH |
| 5 | **Add `compatibility` + `allowed-tools` to skill spec (section 12)** -- New optional frontmatter fields per updated agentskills.io spec. Update all 4 starter skills | `.github/copilot-instructions.md` (section 12), all 4 `template/skills/*/SKILL.md` | MEDIUM |
| 6 | **New interview question E21** -- "Verification trust: Which directories get auto-approve, review, or pause?" Maps to `{{TRUST_OVERRIDES}}`. Expert batch 7 becomes `E20, E21`. Total Expert: 21 questions | `SETUP.md` | MEDIUM |
| 7 | **CI skill validation update** -- Warn (not fail) on missing `compatibility` and `allowed-tools` fields | `.github/workflows/ci.yml` | LOW |
| 8 | **docs/SECURITY-GUIDE.md** -- Trust model, SHA pinning rationale, harden-runner, scorecard interpretation | `docs/SECURITY-GUIDE.md` (new) | MEDIUM |

### All files touched

| Path | Action |
|------|--------|
| `.github/workflows/scorecard.yml` | **Create** |
| `docs/SECURITY-GUIDE.md` | **Create** |
| `.github/copilot-instructions.md` | Modify: Graduated Trust in section 10, new fields in section 12 |
| `.github/workflows/ci.yml` | Modify: harden-runner, SHA-pin, skill check, required file |
| `.github/workflows/release.yml` | Modify: harden-runner, SHA-pin |
| `.github/workflows/stale.yml` | Modify: harden-runner, SHA-pin |
| `.github/workflows/links.yml` | Modify: harden-runner, SHA-pin |
| `.github/workflows/vale.yml` | Modify: harden-runner, SHA-pin |
| `template/skills/skill-creator/SKILL.md` | Modify: add compatibility + allowed-tools |
| `template/skills/fix-ci-failure/SKILL.md` | Modify: add compatibility + allowed-tools |
| `template/skills/lean-pr-review/SKILL.md` | Modify: add compatibility + allowed-tools |
| `template/skills/conventional-commit/SKILL.md` | Modify: add compatibility + allowed-tools |
| `SETUP.md` | Modify: add E21, update Expert batch 7, update count |
| `README.md` | Modify: add docs-table row |
| `CHANGELOG.md` | Modify: add v1.4.0 entry |
| `VERSION` | Modify: 1.3.0 -> 1.4.0 |

### Verification

1. `actionlint .github/workflows/*.yml` -- validates SHA pins
2. `grep -c 'harden-runner' .github/workflows/*.yml` -- matches total job count
3. `grep 'compatibility' template/skills/*/SKILL.md | wc -l` -- returns 4
4. Section 10 Graduated Trust table renders correctly in GitHub Markdown preview
5. All CI checks pass

---

## Release 4: v2.0.0 -- "MCP Integration & Ecosystem"

**Impact: HIGH | Effort: HIGH | Risk: MEDIUM**
Major version: adds section 13 (breaking change for CI section count check), new SETUP step, and changes scaffolding output.

### Breaking changes justifying major version

- New section 13 changes section count from 12 to 13 (CI check, CONTRIBUTING.md, UPDATE.md all reference section count)
- Step 2.12 generates `.vscode/mcp.json` -- changes the scaffolding file output
- Existing consumer repos running the update protocol will encounter the new section
- Skill `compatibility` ranges from v1.4.0 will not claim v2.0.0 compatibility unless updated

### Changes

| # | Change | Files | Priority |
|---|--------|-------|----------|
| 1 | **New section 13 -- Model Context Protocol (MCP)** -- Subsections: MCP server tiers (always-on / credentials-required / stack-specific), server configuration (references `.vscode/mcp.json`), MCP decision tree (built-in tool > MCP server > community package > custom tool), server quality gate (4 checks), available server reference table with `{{MCP_*}}` placeholders | `.github/copilot-instructions.md` | HIGH |
| 2 | **`.vscode/mcp.json` template** -- Preconfigured with 5 official MCP servers: git, filesystem, memory (always-on), github, fetch (credentials-required). Uses `${workspaceFolder}` and `${env:GITHUB_TOKEN}` variables | `template/vscode/mcp.json` (new) | HIGH |
| 3 | **SETUP.md Step 2.12** -- MCP configuration scaffolding: ask user, create `.vscode/mcp.json`, enable always-on servers by default, ask about credentials-required servers, suggest stack-specific servers from Step 1 discovery, populate section 13 placeholders | `SETUP.md` | HIGH |
| 4 | **Port mcp-builder skill** -- Adapted from Anthropic's official library. Teaches agents to create MCP servers: clarify purpose, choose transport, scaffold, implement, test with MCP Inspector, register | `template/skills/mcp-builder/SKILL.md` (new) | HIGH |
| 5 | **Port webapp-testing skill** -- Adapted from Anthropic's official library. Playwright-based e2e testing: detect framework, install runner, scaffold tests, write first test, verify, add to CI | `template/skills/webapp-testing/SKILL.md` (new) | MEDIUM |
| 6 | **New interview question E22** -- "MCP servers: Which external services should be connected via MCP? (none / always-on only / full configuration)". Expert batch 7 becomes `E20, E21, E22`. Total Expert: 22 | `SETUP.md` | MEDIUM |
| 7 | **docs/MCP-GUIDE.md** -- MCP overview, three-tier classification, `.vscode/mcp.json` configuration, adding custom servers, credential security, troubleshooting, interaction with section 11 + section 12 | `docs/MCP-GUIDE.md` (new) | MEDIUM |
| 8 | **Evaluate release-please** -- Add `release-please.yml` as alternative to current awk-based `release.yml`. Rename existing to `release-manual.yml`. Create `docs/RELEASE-AUTOMATION-GUIDE.md` explaining trade-offs | `.github/workflows/release-please.yml` (new), rename `release.yml` to `release-manual.yml`, `docs/RELEASE-AUTOMATION-GUIDE.md` (new) | LOW |
| 9 | **Update CI section check** -- `section 1-section 12` to `section 1-section 13` | `.github/workflows/ci.yml` | HIGH |
| 10 | **Update CONTRIBUTING.md** -- `section 1-section 12` to `section 1-section 13` | `CONTRIBUTING.md` | LOW |

### All files touched

| Path | Action |
|------|--------|
| `.github/copilot-instructions.md` | Modify: add section 13 |
| `template/vscode/mcp.json` | **Create** |
| `template/skills/mcp-builder/SKILL.md` | **Create** |
| `template/skills/webapp-testing/SKILL.md` | **Create** |
| `.github/workflows/release-please.yml` | **Create** |
| `.github/workflows/release.yml` | **Rename** to `release-manual.yml` |
| `docs/MCP-GUIDE.md` | **Create** |
| `docs/RELEASE-AUTOMATION-GUIDE.md` | **Create** |
| `SETUP.md` | Modify: add Step 2.12, add E22 |
| `.github/workflows/ci.yml` | Modify: section check, required files |
| `CONTRIBUTING.md` | Modify: section reference |
| `README.md` | Modify: docs-table rows |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Modify: add area option |
| `.github/ISSUE_TEMPLATE/feature_request.yml` | Modify: add area option |
| `CHANGELOG.md` | Modify: add v2.0.0 entry |
| `VERSION` | Modify: 1.4.0 -> 2.0.0 |

### SETUP.md step numbering after this release

```
0a-0e (preflight) -> 1 (stack discovery) -> 2 (populate instructions) ->
2.5 (agents) -> 2.8 (skills) -> 2.9 (path instructions) -> 2.10 (prompts) ->
2.11 (copilot-setup-steps) -> 2.12 (MCP config) -> 3 (workspace) ->
4 (metrics) -> 5 (doc stubs) -> 6 (finalize)
```

### Verification

1. `grep -c 'section' .github/copilot-instructions.md` shows references through section 13
2. `python3 -m json.tool template/vscode/mcp.json` -- valid JSON
3. `ls template/skills/*/SKILL.md | wc -l` -- returns 6 (4 original + 2 new)
4. CI passes with section 13 check
5. Manual test: create test repo, run setup, verify `.vscode/mcp.json` is generated

---

## Progression Summary

| Version | Theme | New Files | Modified Files | Sections | Wastes | Questions | Steps |
|---------|-------|-----------|----------------|----------|--------|-----------|-------|
| v1.1.0 (current) | -- | -- | -- | 12 | W1-W8 | 20 | 0-6 + 2.5, 2.8 |
| **v1.2.0** | Waste & CI | 1 | 10 | 12 | **W1-W16** | 20 | same |
| **v1.3.0** | Context | 16 | 6 | 12 | W1-W16 | 20 | **+2.9, 2.10, 2.11** |
| **v1.4.0** | Security | 2 | 14 | 12 | W1-W16 | **21 (+E21)** | same |
| **v2.0.0** | MCP | 6 | 10 | **13** | W1-W16 | **22 (+E22)** | **+2.12** |

### Workflow count progression

| Version | Workflows |
|---------|-----------|
| v1.1.0 | ci, release, stale (3) |
| v1.2.0 | ci, release, stale (3) -- but with actionlint job added to ci |
| v1.3.0 | ci, release, stale, **links**, **vale** (5) |
| v1.4.0 | ci, release, stale, links, vale, **scorecard** (6) |
| v2.0.0 | ci, **release-manual**, **release-please**, stale, links, vale, scorecard (7) |

### Doc guides progression

| Version | Guides |
|---------|--------|
| v1.1.0 | 7 (AGENTS, EXTENSION-REVIEW, INSTRUCTIONS, SETUP, SKILLS, TEST-REVIEW, UPDATE) |
| v1.3.0 | **9** (+PATH-INSTRUCTIONS, PROMPTS) |
| v1.4.0 | **10** (+SECURITY) |
| v2.0.0 | **12** (+MCP, RELEASE-AUTOMATION) |

Used tool: AskUserQuestion

Made changes.
