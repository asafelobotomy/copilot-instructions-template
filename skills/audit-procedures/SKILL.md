---
name: audit-procedures
description: Health check procedures D1–D14 for the Audit agent — structural validation, attention budget, version checks, workspace integrity, and static audit
compatibility: ">=2.0"
---

# Audit Procedures (D1–D14)

> Skill metadata: version "1.0"; license MIT; tags [audit, health, structural-validation, workspace, version]; compatibility ">=2.0"; recommended tools [codebase, runCommands, fetch].

Detailed health check definitions for the Audit agent. Load this skill before running health checks to get the full D1–D14 check specifications, thresholds, and flag levels.

---

## Health Checks (D1–D14)

Print a structured health report with sections D1–D14 showing findings, "OK", or "N/A" when a check does not apply to the detected repo shape. End with counts for CRITICAL/HIGH/WARN/INFO/OK and an overall health status.

### D1 — Attention Budget (template/copilot-instructions.md)

Developer template repo only.

Count total lines and per-section lines using `wc -l` and `grep -n "^## §"`.

| Scope | Limit |
|-------|-------|
| Entire file | ≤ 800 |
| §5 Operating Modes | ≤ 210 |
| §1–§4, §6–§9 (each) | ≤ 120 |
| §10 | No limit |
| §11, §12, §13, §14 (each) | ≤ 150 |

Flag: `[CRITICAL]` if any section exceeds limit. `[WARN]` if within 10 lines.

### D2 — Section structure (template/copilot-instructions.md)

Developer template repo only.

Verify §1–§14 all present and in order.
Flag: `[CRITICAL]` if missing. `[WARN]` if out of order.

### D3 — Placeholder separation

1. **All repos**: `.github/copilot-instructions.md` must have zero `{{` tokens → `[CRITICAL]` if found.
2. **Developer template repo only**: `template/copilot-instructions.md` must retain ≥ 3 `{{` tokens → `[HIGH]` if fewer.

### D4 — Agent file validity and delegation policy

For each `.github/agents/*.agent.md`: always check frontmatter present,
`name:` set, handoff targets resolve to existing agent names, and `model:` is
listed.

Developer template repo only: specialist delegation allow-lists match the repo
policy.

Consumer repos: skip repo-policy allow-list matching and only report
structural agent validity.

Flag: `[CRITICAL]` broken handoff. `[HIGH]` missing name/frontmatter or
required delegates in developer template repos. `[WARN]` missing model or
unexpected delegates in developer template repos.

### D5 — MCP configuration (.vscode/mcp.json)

If present: verify `mcp-server-git`/`mcp-server-fetch` use `uvx` not `npx`. Verify no `@modelcontextprotocol/server-git` or `server-fetch` references (npm 404s).

Flag: `[CRITICAL]` npx usage. `[HIGH]` @modelcontextprotocol references.

### D6 — Version file

Use the repo shape detection in the agent body.

**Developer template repo**: skip (mark N/A). **Consumer repo**: check
`.github/copilot-version.md` exists, starts with a valid semver, includes
`Applied:` and `Updated:` dates, and carries `section-fingerprints`,
`file-manifest`, and `setup-answers` blocks.

Flag: `[HIGH]` if absent or malformed. `[WARN]` if fingerprint tracking is absent.

### D7 — Workspace memory files

Check each file under `.copilot/workspace/` exists and is non-empty.
Exempt transient files from the non-empty check: any file matching `*.lock` or living under `.copilot/workspace/runtime/` or `.copilot/workspace/.tmp/` is a transient heartbeat artifact and may legitimately be zero-byte during or between sessions.
Flag: `[HIGH]` if `HEARTBEAT.md` or `IDENTITY.md` missing. `[WARN]` for others (excluding transient files).

### D8 — AGENTS.md

Present? References `.github/copilot-instructions.md`?
Flag: `[WARN]` if absent.

### D9 — Agent plugins

Check `.vscode/settings.json` for `chat.pluginLocations` — verify each enabled
path resolves. Accept a list only as a legacy fallback.
Check for naming conflicts between `.github/agents/` and plugin-contributed agents.
Check for skill name collisions between `.github/skills/` and plugin-contributed skills.

Flag: `[WARN]` for conflicts or non-existent paths. Skip silently if no plugin settings.

### D10 — Companion extension (copilot-extension)

Check if installed via `code --list-extensions`. If installed, verify it appears in
`.vscode/extensions.json` recommendations.

Flag: `[INFO]` if not installed. `[WARN]` if installed but missing from recommendations. Skip if `code` CLI unavailable.

### D11 — Upstream version check (consumer repos only)

Skip in developer repo. Fetch `raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/VERSION.md`, compare against `.github/copilot-version.md`.

Flag: `[HIGH]` behind by major version. `[WARN]` behind by minor/patch. `[INFO]` up to date. `[WARN]` if fetch fails.

### D12 — Section fingerprint integrity (consumer repos only)

Skip in developer repo. Parse `<!-- section-fingerprints -->` block from `.github/copilot-version.md`. For each §1–§9, compute fingerprint via `sha256sum` of section content and compare against stored value.

Flag: `[INFO]` per drifted section. `[WARN]` if ≥ 5 of 9 sections drifted. `[WARN]` if fingerprint block absent.

### D13 — Companion file completeness (consumer repos only)

Skip in developer repo. Fetch `raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.copilot/workspace/operations/workspace-index.json`. Verify local project has all expected agents, skills, prompts, instructions, hook scripts, hook config, the setup workflow, and core `.copilot/workspace/` files. Inspect installed starter-kit payloads under `.github/starter-kits/*/` when present, and verify `.vscode/settings.json`, `.vscode/extensions.json`, and `.vscode/mcp.json` when the corresponding consumer surfaces exist.

Flag: `[HIGH]` missing agent, shell hook, workflow, core workspace file, or installed starter-kit payload. `[WARN]` missing skill, prompt, instruction, or PS1 hook. `[INFO]` for user-added extras. `[WARN]` if fetch fails.

### D14 — Static audit (copilot_audit.py)

If `scripts/copilot_audit.py` exists, run the profile that matches the detected
repo shape and map findings to the report (CRITICAL→CRITICAL, HIGH→HIGH,
WARN→WARN, INFO→INFO).

- Developer template repo: `python3 scripts/copilot_audit.py --root . --output json`
- Consumer repo: `python3 scripts/copilot_audit.py --profile consumer --root . --output json`

Covers: A1–A4 (agents), C1 (consumer companion completeness), I1–I4 (instructions), V1 (version metadata), P1 (prompts), S1–S2 (skills), M1–M3 (MCP), H1–H2 (hooks), SH1–SH3 (shell), PS1 (PowerShell), K1–K2 (starter kits), and VS1 (VS Code settings).

Consumer static-audit subset covers: A1–A3 (agents), C1 (consumer companion completeness), I1, I3, and I4
(instructions), V1 (version metadata), P1 (prompts), S1–S2 (skills), M1–M3 (MCP), H1–H2 (hooks), SH1–SH3 (shell), PS1 (PowerShell), K1–K2 (starter kits), and VS1 (VS Code settings). It intentionally skips repo-only A4.

If absent: `[INFO]` — static audit skipped.

---

## Health report status levels

- **HEALTHY** — zero CRITICAL or HIGH findings.
- **DEGRADED** — WARN findings only (no CRITICAL or HIGH).
- **CRITICAL** — at least one CRITICAL or HIGH finding.
