# Memory Strategy — copilot-instructions-template

<!-- workspace-layer: L1 | budget: ≤300 tokens | trigger: always -->
> **Domain**: Facts — verified project facts, error patterns, team conventions, baselines, and gotchas.
> **Boundary**: No opinions, preferences, reasoning heuristics, or session-specific state.
> **Guide**: See `MEMORY-GUIDE.md` for principles, coexistence rules, and maintenance protocol.

## Metrics Freshness

| Metric | Last reviewed | Expires | Priority | Source | Notes |
|--------|--------------|---------|----------|--------|-------|
| Test count baseline | 2026-03-19 | 2026-06-19 | P1 | `tests/run-all.sh` | 222 tests, 0 failures |
| Starter-kit count | 2026-03-19 | 2026-06-19 | P2 | `starter-kits/REGISTRY.json` | 8 kits in REGISTRY.json |
| Skill count | 2026-04-15 | 2026-07-15 | P2 | `skills/` | 18 in skills/ (repo-root plugin dir); consumer path is `.github/skills/` (not present in this repo) |
| Agent count | 2026-04-15 | 2026-07-15 | P2 | `agents/` | 14 in agents/ (repo-root plugin dir); consumer path is `.github/agents/` (not present in this repo) |

> **Priority**: P1 = critical baseline, P2 = important inventory, P3 = informational.
> **Expires**: review-by date; heartbeat flags rows past expiry. Default: 3 months from last review.

## Known Gotchas — Hooks System

| Gotcha | Impact | Observed | Source | Notes |
|--------|--------|----------|--------|-------|
| Stop hook output: only `decision: "block"` + `reason` (string) | critical | 2026-04-01 | [hooks docs](https://code.visualstudio.com/docs/copilot/customization/hooks) | No button, confirmation title, follow-up chip, or interactive UI output |
| PostToolUse input includes `tool_name` + `tool_input` | notable | 2026-04-01 | [hooks docs](https://code.visualstudio.com/docs/copilot/customization/hooks) | Usable for tracking Copilot edit activity in `soft_post_tool` |
| Active-work-time model for retrospective gating | notable | 2026-04-02 | `template/hooks/scripts/pulse_state.py` | Tracks epoch, active seconds, git count, edit count, tool counter in state.json |

## Known Gotchas

| Gotcha | Impact | Observed | Source | Notes |
|--------|--------|----------|--------|-------|
| Doctor↔Security circular handoffs | notable | 2026-04-02 | `.github/agents/` | Consider merging into unified Audit agent |
| Explore agent read-only guarantee (no editFiles) | critical | 2026-04-02 | `.github/agents/explore.agent.md` | Required for parallel subagent safety — do not add editFiles |

## Archived

*(Expired or superseded entries move here instead of being deleted. Prune quarterly.)*

| Entry | Archived | Reason |
|-------|----------|--------|
