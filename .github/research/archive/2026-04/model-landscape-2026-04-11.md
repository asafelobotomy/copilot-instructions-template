# Research: GitHub Copilot / VS Code Agent Model Landscape

> Date: 2026-04-11 | Agent: Researcher | Status: final

## Summary

As of 2026-04-11 the repository's eleven local model pins are mostly current,
but **GPT-5.1 is retiring in four days (2026-04-15)** and must be replaced across
all surfaces. The authoritative replacement GitHub recommends is GPT-5.3-Codex
(the designated base + LTS model since 2026-03-18). GPT-5.2 is available as a
GA non-Codex alternative for agents where agentic tool-use focus is unwanted.
No other local model names are deprecated or scheduled for retirement.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://docs.github.com/en/copilot/reference/ai-models/supported-models | Official supported-models list, retirement history, per-client and per-plan tables, multipliers |
| https://docs.github.com/en/copilot/concepts/fallback-and-lts-models | Base + LTS model designation history, premium-exhausted fallback clarification |
| https://code.visualstudio.com/docs/copilot/customization/custom-agents | Agent `.agent.md` frontmatter schema including `model:` field syntax |
| https://docs.github.com/en/copilot/using-github-copilot/ai-models/changing-the-ai-model-for-copilot-chat | Model switching UX, limitations note |

---

## Findings

### 1. Per-model status for all names currently in the repository

| Local model name in repo | GitHub Copilot status (2026-04-11) | Assessment |
|---|---|---|
| GPT-5.4 | GA, 1x multiplier | **Current** |
| GPT-5.4 mini | GA, 0.33x multiplier (multiplier subject to change) | **Current** |
| GPT-5.3-Codex | GA, 1x multiplier, **Base + LTS since 2026-03-18** | **Current — LTS anchor** |
| GPT-5.2-Codex | GA, 1x multiplier | **Current** |
| GPT-5.1 | GA but **closing down 2026-04-15** | **DEPRECATED — 4 days** |
| GPT-5 mini | GA, 0x multiplier (Copilot-free included) | **Current** |
| GPT-4.1 | GA, 0x multiplier (premium-exhausted fallback) | **Current** |
| Claude Opus 4.6 | GA, 3x multiplier | **Current** |
| Claude Sonnet 4.6 | GA, 1x multiplier (multiplier subject to change) | **Current** |
| Claude Sonnet 4.5 | GA, 1x multiplier | **Current** |
| Claude Haiku 4.5 | GA, 0.33x multiplier | **Current** |

### 2. Full retirement history from the GitHub docs (for context)

| Retired model | Retirement date | Suggested replacement |
|---|---|---|
| GPT-5.1 | **2026-04-15** | GPT-5.3-Codex |
| GPT-5.1-Codex | 2026-04-01 (already retired) | GPT-5.3-Codex |
| GPT-5.1-Codex-Max | 2026-04-01 (already retired) | GPT-5.3-Codex |
| GPT-5.1-Codex-Mini | 2026-04-01 (already retired) | GPT-5.3-Codex |
| Gemini 3 Pro | 2026-03-26 (already retired) | Gemini 3.1 Pro |
| Claude Opus 4.1 | 2026-02-17 | Claude Opus 4.6 |
| GPT-5 | 2026-02-17 | GPT-5.2 |
| GPT-5-Codex | 2026-02-17 | GPT-5.2-Codex |

### 3. New GA models available but not yet in the repository

These are offered by Copilot at GA tier but not present in any local agent file
or MODELS.md. They are gaps, not breakages.

| Model | Vendor | Tier | Notes |
|---|---|---|---|
| GPT-5.2 | OpenAI | GA, 1x | General-purpose non-Codex at GPT-5.1 tier; natural replacement for non-agentic slots |
| Claude Opus 4.5 | Anthropic | GA, 3x | Between Opus 4.6 and Opus 4.6 fast mode |
| Claude Sonnet 4 | Anthropic | GA, 1x | Older Sonnet generation, 1x |
| Gemini 2.5 Pro | Google | GA, 1x | Cross-client; not in VS Code only (Copilot.com + github.com) |
| Grok Code Fast 1 | xAI | GA, 0.25x | Included in all Copilot plans |

### 4. LTS / base model context

- **GPT-5.3-Codex** is the current base model and LTS model (designated 2026-03-18,
  LTS commitment = 1 year → until ~2027-03-18).
- **GPT-4.1** is the free, zero-multiplier premium-exhausted fallback. It is
  unchanged and still appropriate for the `fast` agent's third slot.
- When premium requests are exhausted Copilot silently falls back to GPT-4.1.
  Agents that rely on GPT-5.1 as primary (organise, commit) would therefore
  both lose their primary and their fallback simultaneously on 2026-04-15.

### 5. VS Code agent frontmatter model field constraints

From the official VS Code custom-agents docs (updated 2026-04-08):

- **`model:` (agent-level)** — accepts a string or a YAML array of plain
  display names, e.g. `- GPT-5.3-Codex`. VS Code tries each in order until
  one is available. **No vendor qualifier expected** in this field.
- **`handoffs.model`** — uses a qualified format: `Model Name (vendor)`, e.g.
  `GPT-5.2 (copilot)` or `Claude Sonnet 4.5 (copilot)`. Different from the
  top-level model array.
- If no model is specified, VS Code uses whichever model is active in the
  model picker.
- The `> Thinking Effort` submenu in the VS Code model picker is a user
  setting — there is no per-agent frontmatter override for thinking effort.

### 6. Agents most critically affected by GPT-5.1 retirement

These agents list GPT-5.1 as their **first or second** model (highest impact):

| Agent file | GPT-5.1 position | Notes |
|---|---|---|
| `commit.agent.md` | 1st (primary) | Commit operations use GPT-5.1 as the lead model |
| `organise.agent.md` | 1st (primary) | Structural cleanup uses GPT-5.1 as the lead model |
| `planner.agent.md` | 2nd | Falls back to GPT-5.1 immediately after Claude Sonnet 4.6 |
| `docs.agent.md` | 2nd | Same pattern as planner |

Agents where GPT-5.1 is 3rd or 4th (lower impact — earlier models absorb load):
`coding.agent.md`, `review.agent.md`, `setup.agent.md`, `extensions.agent.md`,
`debugger.agent.md`, `audit.agent.md`

---

## Recommendations

### Immediate (before 2026-04-15)

1. **Replace GPT-5.1 in MODELS.md** — this is the single source of truth;
   `sync-models.sh --write` propagates to all `.agent.md` files.
2. **Recommended replacement by context:**
   - Agents with agentic/autonomous tool use (commit, coding, organise):
     `GPT-5.2-Codex` or `GPT-5.3-Codex` (LTS, 1x)
   - Agents with conversational or mixed tasks (planner, docs, setup):
     `GPT-5.2` (plain, no Codex suffix) if added, otherwise `GPT-5.3-Codex`
   - Note: `GPT-5.2` is GA but **not currently in any repo model list** — it would
     need to be introduced as a new name if used.
3. **Run `bash scripts/sync/sync-models.sh --write` after editing `MODELS.md`**
  — local verification in this repo shows that the sync step updates both the
  `.agent.md` model lists and the `llms.txt` primary-model and effort summary.

### Low-priority (no breaking deadline)

4. Consider adding `GPT-5.2` to the non-Codex general-purpose fallback slots
   to avoid over-routing every agent through a Codex-optimised model.
5. Consider adding `Grok Code Fast 1` (0.25x, GA in all plans) to the `fast`
   or `explore` agents as an economical high-speed option.
6. Review `Claude Opus 4.5` availability for plans that need flagship Anthropic
   capability below Opus 4.6 tier.

---

## Gaps / Further research needed

- The GitHub docs do not publish exact API model identifiers used in agent
  frontmatter (e.g., whether `GPT-5.3-Codex` is the literal string VS Code
  resolves). Verification via the VS Code model picker UI or
  `Chat: Open Chat Customizations` diagnostics view is recommended after any
  frontmatter change.
- `Claude Sonnet 4.6` and `GPT-5.4 mini` multipliers are explicitly flagged as
  "subject to change" in the docs — worth rechecking if billing is a concern.
- The `Goldeneye` evaluation model is a fine-tuned GPT-5.1-Codex — its
  relationship to the GPT-5.1 retirement (same base or independent) is not
  documented; it remains in preview and out of scope for production agents.
