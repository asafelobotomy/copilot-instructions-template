# Research: Model Availability and Agent Model Assignment — Delta Update

> Date: 2026-04-04 | Agent: Researcher | Status: complete
> Supersedes: `archive/2026-03/thinking-effort-and-model-lineup-2026-03-28.md` for new findings only.
> The March 28 file remains the canonical reference for thinking effort mechanics.

## Summary

Between 2026-03-28 and 2026-04-04, three notable changes occurred: (1) GPT-5.3-Codex was
officially designated the GitHub Copilot **base model and LTS model** on 2026-03-18; (2) the
auto model selection pool was updated to include GPT-5.4, GPT-5.4 mini, Grok Code Fast 1, and
Raptor mini, replacing GPT-5.2-Codex and Claude Sonnet 4.5 from the prior pool; and (3) VS Code
advanced from v1.110 to v1.114 (released 2026-04-01) — Autopilot mode and agent-scoped hooks
shipped in v1.111 (2026-03-09), but no per-agent thinking effort field was added to `.agent.md`.
In the current repo, `GPT-5.1-Codex` (a coding fallback) has a model card listed as "Not
available" in official docs, no longer appears in the VS Code Copilot model picker observed in
this workspace, and should be removed from the active coding chain. `GPT-5.4 mini` is a new
0.33x option specifically noted for "codebase exploration and grep-style tools" and is
recommended for the Explore agent.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://docs.github.com/en/copilot/concepts/fallback-and-lts-models> | GPT-5.3-Codex designated base+LTS 2026-03-18; GPT-4.1 is premium-exhausted fallback |
| <https://docs.github.com/en/copilot/reference/ai-models/model-comparison> | Full task-based model comparison table; all 27+ current models and task categories |
| <https://docs.github.com/en/copilot/concepts/auto-model-selection> | Auto pool as of April 2026; multiplier discounts |
| <https://docs.github.com/en/copilot/using-github-copilot/ai-models/supported-ai-models-in-copilot> | Retirement history pointer (tables behind JS); included models list |
| <https://docs.github.com/en/copilot/concepts/billing/copilot-requests> | Included models (0x): GPT-5 mini, GPT-4.1, GPT-4o; Sonnet 4.6 multiplier may change |
| <https://code.visualstudio.com/docs/copilot/customization/custom-agents> | `model:` supports string or ordered array; no thinking-effort field as of v1.114 |
| <https://code.visualstudio.com/docs/copilot/customization/language-models> | Thinking effort still per-user/per-model only; both legacy settings deprecated |
| <https://code.visualstudio.com/updates/v1_111> | v1.111 (2026-03-09): Autopilot, agent-scoped hooks Preview; no per-agent thinking effort |
| <https://code.visualstudio.com/updates> | Current stable: v1.114.0 (2026-04-01) |

---

## Findings

### 1. Current Model Inventory (April 4, 2026)

The complete set of models listed in the official GitHub Copilot comparison docs:

#### OpenAI / GPT family

| Model | Category | Multiplier | Notes |
|-------|----------|------------|-------|
| GPT-4.1 | General-purpose | 0x | Included; premium-exhausted fallback when GPT-5.3-Codex unavailable |
| GPT-4o | General-purpose | 0x | Included |
| GPT-5 mini | General-purpose / fast | 0x | Included on paid plans; 1x on Copilot Free |
| GPT-5.1 | Deep reasoning | 1x | Multi-step reasoning and architecture analysis |
| GPT-5.1-Codex | Deep reasoning | 1x | Older Codex-series option; no public model card and not present in the current VS Code picker observed in this session |
| GPT-5.1 Codex Max | Agentic | 1x | Largest Codex-series; model card available |
| GPT-5.1-Codex-Mini | Deep reasoning | 0.33x | Preview; lighter Codex variant |
| GPT-5.2 | Deep reasoning | 1x | Successor to GPT-5.1 for reasoning |
| GPT-5.2-Codex | Agentic | 1x | Model card available; code-optimised |
| GPT-5.3-Codex | Agentic | 1x | **Base model + LTS (2026-03-18)**; in auto pool |
| GPT-5.4 | Deep reasoning | 1x | In auto pool; "complex reasoning and code analysis" |
| GPT-5.4 mini | Agentic | 0.33x | In auto pool; "codebase exploration, grep-style tools" |

#### Anthropic / Claude family

| Model | Category | Multiplier | Notes |
|-------|----------|------------|-------|
| Claude Haiku 4.5 | Fast | 0.33x | In auto pool; lightweight questions |
| Claude Sonnet 4.0 | Deep reasoning | 1x | Older generation; still available |
| Claude Sonnet 4.5 | General-purpose + agents | 1x | Predecessor to 4.6 |
| Claude Sonnet 4.6 | General-purpose + agents | 1x* | In auto pool; **multiplier subject to change** |
| Claude Opus 4.5 | Deep reasoning | 3x | Still available; predecessor to Opus 4.6 |
| Claude Opus 4.6 | Deep reasoning | 3x | Anthropic's strongest; "improves on Opus 4.5" |
| Claude Opus 4.6 (fast mode) | Deep reasoning | ? | Preview |

#### Google / Gemini family

| Model | Category | Multiplier | Notes |
|-------|----------|------------|-------|
| Gemini 2.5 Pro | Deep reasoning | 1x | Complex code + research workflows |
| Gemini 3 Flash | Fast | 0.33x | Preview; lightweight questions |
| Gemini 3 Pro | Deep reasoning | 1x | Model card available |
| Gemini 3.1 Pro | Deep reasoning | 1x | "Edit-then-test loops with high tool precision" |

#### Others

| Model | Category | Multiplier | Notes |
|-------|----------|------------|-------|
| Grok Code Fast 1 | General-purpose | 0.25x | In auto pool; xAI coding model |
| Qwen2.5 | General-purpose | ? | Evaluation model; may be removed without notice |
| Raptor mini | General-purpose | 0x | In auto pool; 0x = included; GitHub-developed |
| Goldeneye | Deep reasoning | ? | Mentioned in comparison docs; possibly evaluation/gated |

#### Auto model selection pool (current)

When `Auto` is selected in VS Code Copilot Chat:
`GPT-4.1`, `GPT-5.3-Codex`, `GPT-5.4`, `GPT-5.4 mini`, `Claude Haiku 4.5`,
`Claude Sonnet 4.6`, `Grok Code Fast 1`, `Raptor mini`

**Changed from March 28**: GPT-5.2-Codex and Claude Sonnet 4.5 removed; GPT-5.4, GPT-5.4 mini,
Grok Code Fast 1, and Raptor mini added.

---

### 2. Base Model and LTS Designation

On **2026-03-18**, GitHub designated **GPT-5.3-Codex** as both:
- The **base model** — default model for Copilot Business/Enterprise when no model is enabled.
- The **LTS model** — committed to availability for one year from designation (until ~2027-03-18).

Previous base model (GPT-4.1) is now the **premium-exhausted fallback only**: when a user's
monthly premium requests run out, Copilot falls back to GPT-4.1 at no additional cost.

**Implication for agent design**: GPT-5.3-Codex is the safest fallback position in any agent
`model:` array. It will not be retired for at least one year and is the most likely model to be
available in all environments.

---

### 3. `.agent.md` `model:` Field — Confirmed Behaviour

The VS Code docs for custom agents explicitly document ordered fallback arrays:

```yaml
model: ['Claude Opus 4.5', 'GPT-5.2']  # Tries models in order
```

> "When you specify an array, the system tries each model in order until an available one is found."

**No per-agent thinking effort field exists in v1.114.** This gap from the March 28 research is
confirmed: v1.111 through v1.114 added Autopilot, agent-scoped hooks (Preview), debug snapshots,
and chat UX improvements — none added a `thinking-effort:` frontmatter key.

Thinking effort remains a **per-user, per-model** setting in the model picker. The two legacy
settings are deprecated and should not appear in template `settings.json` stubs.

---

### 4. Model Names in the Repo — Risk Assessment

| Model name (in MODELS.md) | Risk | Reason |
|---------------------------|------|--------|
| `GPT-5.1-Codex` (coding fallback) | **Medium** | Older fallback with no public model card and absent from the current VS Code picker observed in this session. Superseded in this repo by GPT-5.2-Codex and GPT-5.3-Codex. |
| `Claude Sonnet 4.5` (setup, researcher fallbacks) | Low | Still in comparison table; superseded by 4.6 but stable as a fallback. |
| `Claude Opus 4.6` (audit, review primary) | Low | Current Opus generation; valid. |
| `GPT-5.4` (audit, review primary) | Low | In auto pool; validated for deep reasoning. |
| `GPT-5.2-Codex` (coding fallback) | Low | Model card available; valid agentic fallback. |
| `GPT-5.3-Codex` (coding fallback) | Low | Now the LTS model; safest fallback available. |
| `GPT-5 mini` (fast, setup, explore fallbacks) | Low | Included model; zero premium cost on paid plans. |
| `GPT-4.1` (fast fallback) | Low | Included model; premium-exhausted fallback. Valid. |
| `Claude Haiku 4.5` (fast, explore primary) | Low | In auto pool; docs-recommended for lightweight tasks. |
| `Claude Sonnet 4.6` (setup, researcher, etc.) | **Note** | Multiplier "may be subject to change" per billing docs. Not a stability risk — model is current — but cost could increase. |
| `GPT-5.1` (primary for coding, commit, etc.) | Low | Solid deep reasoning model; 1x multiplier; currently valid. |

---

### 5. VS Code Release Delta (v1.110 → v1.114)

| Version | Date | Key agent-relevant changes |
|---------|------|---------------------------|
| v1.111 | 2026-03-09 | Autopilot (Preview), agent permission levels (Default/Bypass/Autopilot), **agent-scoped hooks Preview** (`hooks:` in `.agent.md` frontmatter), debug events snapshot |
| v1.112 | ~2026-03-16 | (not fetched; no major agent schema changes known) |
| v1.113 | ~2026-03-23 | Image carousel for chat attachments |
| v1.114 | 2026-04-01 | Preview videos in image carousel, `/troubleshoot` command for chat customizations, workspace search simplification (`#codebase` now semantic-only) |

No per-agent thinking effort field was added in any of these releases.

**Notable for this repo**: v1.111 agent-scoped hooks are now in Preview and this repo already
uses them (`chat.useCustomAgentHooks` setting). The RESEARCH.md URL tracker only references
v1.110 as the current stable — should add v1.111 through v1.114.

---

## Recommendations

### For MODELS.md

1. **Move `GPT-5.3-Codex` to the front of the coding agent model list.** GitHub now designates
   it as both the Copilot base model and the LTS model, and the current model-comparison docs
   recommend it for feature work, tests, debugging, refactors, and reviews.

2. **Remove `GPT-5.1-Codex`** from the coding agent fallback list. The model no longer appears in
   the VS Code Copilot picker observed in this workspace, and newer Codex options already cover
   the same task shape.

3. **Add `GPT-5.4 mini` to the Explore agent** near the front of the lightweight fallback chain.
   Official docs single it out as "especially effective when using grep-style tools" — exactly
   what Explore does. Multiplier is 0.33x, making it cost-appropriate for a read-only exploration
   agent.

4. **Update the "per-agent override" note** from "as of VS Code 1.110" to "as of VS Code 1.114".
   The answer is still no, and four more releases have confirmed it.

5. **Annotate GPT-5.3-Codex** as the base + LTS coding default and surface the supported-models
   billing note that Claude Sonnet 4.6 and GPT-5.4 mini multipliers are subject to change.

### For llms.txt

Update the coding primary summary to `GPT-5.3-Codex`. Other primary assignments remain valid.

### For template consumers

- Remove deprecated settings `github.copilot.chat.anthropic.thinking.effort` and
  `github.copilot.chat.responsesApiReasoningEffort` from any `settings.json` stubs.
- Do NOT add these settings back — thinking effort is now configured exclusively via the
  VS Code model picker UI.

---

## Gaps / Further Research Needed

- v1.112 and v1.113 release notes were not fetched; confirm no agent schema changes.
- `Goldeneye` model: listed in comparison docs for deep reasoning but absent from the main model
  comparison table header row. Possibly an evaluation or renamed model (may be GPT-5.4 alias).
- `Raptor mini` model card: "coming soon" in April 2026 docs. Monitor for public card.
- Whether a future VS Code release will add per-agent `thinking-effort:` to `.agent.md` —
  this remains an open feature gap. Watch release notes for 1.115+.
