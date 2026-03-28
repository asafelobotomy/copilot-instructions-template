# Research: VS Code Copilot Thinking Effort and Model Lineup

> Date: 2026-03-28 | Agent: Researcher | Status: complete

## Summary

VS Code Copilot (v1.109+) exposes a per-model Thinking Effort picker (None / Low / Medium / High)
directly in the model picker UI. Thinking effort controls the volume of internal "thinking tokens"
the model generates before producing its response, trading latency and token cost for reasoning
depth. The feature is model-specific: only reasoning-capable models expose the submenu. A parallel
"Thinking Tool" (agent mode only) gives any model a structured think-between-tool-calls step. Model
multipliers (0x / 0.25x / 0.33x / 1x / 3x) are billing coefficients that scale the premium-request
deduction per chat turn. Agents can pin a model via the `model:` frontmatter field but cannot
specify thinking effort; that setting lives in user state in the model picker and persists across
conversations.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://code.visualstudio.com/docs/copilot/customization/language-models> | Primary reference — configure thinking effort, multipliers, BYOK, model picker |
| <https://code.visualstudio.com/docs/copilot/concepts/language-models> | Concepts: thinking tokens, context window, adaptive reasoning |
| <https://code.visualstudio.com/docs/copilot/customization/custom-agents> | Agent frontmatter schema incl. `model:` field |
| <https://code.visualstudio.com/updates/v1_99> | v1.99 (Mar 2025) — introduced Thinking Tool (experimental) for agent mode |
| <https://code.visualstudio.com/updates/v1_109> | v1.109 (Jan 2026) — Anthropic thinking tokens surfaced in chat UX |
| <https://code.visualstudio.com/updates/v1_110> | v1.110 (Feb 2026) — current stable (as of Mar 2026) |
| <https://docs.github.com/en/copilot/concepts/billing/copilot-requests> | Model multipliers and premium request accounting |
| <https://docs.github.com/en/copilot/reference/ai-models/model-comparison> | Task-based model comparison table with all current models |
| <https://docs.github.com/en/copilot/using-github-copilot/ai-models/supported-ai-models-in-copilot> | Canonical model list, plan availability, LTS models |
| <https://docs.github.com/en/copilot/concepts/auto-model-selection> | Auto model selection — which models qualify, multiplier discounts |

---

## Findings

### 1. Thinking Effort Levels

#### What the levels mean

Thinking effort controls how many "thinking tokens" the model generates internally before emitting
its response. These tokens represent hidden chain-of-thought reasoning that is not directly visible
in the response (it may be summarised or omitted entirely). They do count against the model's
context window.

| Level | Effect |
|-------|--------|
| **None** | No thinking tokens generated. Model answers directly. Fastest, cheapest, lowest reasoning depth. |
| **Low** | Small thinking budget. Useful for straightforward tasks where some deliberation helps but full reasoning chains are unnecessary. |
| **Medium** | Moderate thinking budget. The VS Code documented default for most reasoning models — balances latency and quality for mixed workloads. |
| **High** | Large thinking budget. Recommended for complex multi-step debugging, architectural planning, and tasks requiring deep trade-off analysis. Highest latency and token use. |

VS Code's own documentation states:

> "VS Code sets recommended default effort levels based on evaluations and online performance data,
> and has adaptive reasoning enabled. Adaptive reasoning lets the model dynamically determine when
> and how much to think based on the complexity of each request."

**Key implication**: VS Code does not force a fixed budget on every request at the selected level.
It enables *adaptive reasoning* where supported, meaning the model itself decides whether to use its
thinking budget for a given prompt. The effort level sets a ceiling or default, not a constant.

#### Are levels model-specific or universal?

**Model-specific.** The thinking effort submenu only appears in the picker for **reasoning-capable**
models. The docs explicitly state: "Non-reasoning models, such as GPT-4.1 and GPT-4o, do not show
the thinking effort submenu." Each provider maps the VS Code effort label to a different underlying
API parameter (see §3 below).

#### Effect on token usage and response quality

- Higher effort → more thinking tokens → longer time-to-first-token and higher total latency.
- Thinking tokens count toward the context window even though they are not visible.
- The actual reasoning output returned is typically summarised; detailed thinking traces can be
  rendered when supported (v1.109 added rendering of Anthropic thinking tokens in the chat UX).
- For simple tasks (boilerplate, syntax lookups), higher effort "adds latency without significant
  benefit" per the VS Code concepts doc.

---

### 2. Current Model Lineup in VS Code Copilot (March 2026)

The user's picker shows models from the current stable version (v1.110, released 2026-03-04, latest
update 1.110.1). The "Medium·" or "High·" prefix shown next to a model name is the **currently
selected thinking effort level** for that model stored in user state. It is not a property of the
model itself.

The multiplier (e.g. `3x`, `1x`, `0.33x`, `0x`) is the **premium request billing coefficient**.
One chat turn with a 3x model costs 3 premium requests; a 0x model costs nothing on paid plans.

#### Featured models (as seen by the user)

| Model | Default Effort | Multiplier | Notes |
|-------|---------------|------------|-------|
| Claude Opus 4.6 | Medium | 3x | Anthropic's strongest reasoning model; "most powerful", improves on Opus 4.5 |
| Claude Sonnet 4.6 | High | 1x | General-purpose + agent tasks; "more reliable completions and smarter reasoning under pressure" — multiplier flagged as subject to change |
| GPT-5.3-Codex | Medium | 1x | Agentic software development; "higher-quality code on complex engineering tasks without lengthy instructions" |
| GPT-5.4 | Medium | 1x | Deep reasoning and debugging; "complex reasoning, code analysis, and technical decision-making" |

#### Other models enumerated

| Model | Multiplier | Category | Notes |
|-------|------------|----------|-------|
| Claude Haiku 4.5 | 0.33x | Fast | Lightweight coding questions, fast responses |
| Claude Opus 4.5 | 3x | Deep reasoning | Predecessor to Opus 4.6; still available |
| Claude Sonnet 4 (4.0) | 1x | Deep reasoning | Earlier Sonnet; "performance and practicality, balanced for coding" |
| Claude Sonnet 4.5 | 1x | General-purpose | Predecessor to Sonnet 4.6 |
| Gemini 2.5 Pro | 1x | Deep reasoning | "Complex code generation, debugging, and research workflows" |
| Gemini 3 Flash Preview | 0.33x | Fast | "Fast, reliable answers to lightweight coding questions" |
| Gemini 3.1 Pro Preview | 1x | Deep reasoning | "Effective edit-then-test loops with high tool precision" |
| GPT-4.1 | 0x | Included | General-purpose; no premium requests on paid plans |
| GPT-4o | 0x | Included | General-purpose; no premium requests on paid plans |
| GPT-5 mini | Medium · 0x | Included | "Fast, reliable default for most coding tasks"; 0x = included on paid plans (1 premium request on Free) |
| GPT-5.1 | Medium · 1x | Deep reasoning | Multi-step problem-solving, architecture-level analysis |
| GPT-5.1-Codex | Medium · 1x | Agentic | Same task area as GPT-5.1, code-optimised variant |
| GPT-5.1-Codex-Max | Medium · 1x | Agentic | "Agentic tasks" — largest Codex-series model |
| GPT-5.1-Codex-Mini Preview | Medium · 0.33x | Agentic | Lighter Codex variant; preview status |
| GPT-5.2 | Medium · 1x | Deep reasoning | Successor to GPT-5.1 for reasoning tasks |
| GPT-5.2-Codex | Medium · 1x | Agentic | Codex-optimised variant of GPT-5.2 |
| GPT-5.4 mini | Medium · 0.33x | Agentic | "Codebase exploration, especially effective with grep-style tools" |
| Grok Code Fast 1 | 0.25x | General | xAI model; "fast, accurate code completions" |
| Raptor mini Preview | 0x | General | GitHub's own model; "fast, accurate inline suggestions" — 0x = included |

**Notes on specific models:**

- **GPT-5 mini**: The "Medium" label indicates thinking effort is enabled at Medium for this model.
  It is listed as 0x, meaning it is one of the three *included* models (alongside GPT-4.1 and
  GPT-4o) that consume zero premium requests on paid plans.
- **Raptor mini**: A GitHub-developed model. "0x" means it is included (free on paid plans).
  Model card listed as "coming soon" in the comparison doc.
- Models with "Preview" or "(preview)" in the name are pre-release/experimental.
- The user's display label `"Medium·3x"` means: thinking effort = Medium, multiplier = 3x.

#### What the multipliers mean technically

Per the GitHub billing documentation:

> "Each model has a premium request multiplier, based on its complexity and resource usage. If you
> are on a paid Copilot plan, your premium request allowance is deducted according to this
> multiplier."

- **0x**: Included model. Zero premium requests consumed on paid plans (GPT-4.1, GPT-4o, Raptor
  mini). On Copilot Free, all models consume exactly 1 premium request regardless of multiplier.
- **0.25x**: Grok Code Fast 1. One chat turn consumes 0.25 premium requests.
- **0.33x**: Light-tier premium models (Haiku 4.5, Gemini 3 Flash, GPT-5.1-Codex-Mini, GPT-5.4
  mini). One turn = 0.33 premium requests.
- **1x**: Standard premium (Sonnet 4.6, GPT-5.1, GPT-5.2, Gemini 2.5 Pro, etc.). One turn = 1
  premium request.
- **3x**: Flagship/heaviest models (Opus 4.5, Opus 4.6). One turn = 3 premium requests.

**Auto model selection discount**: On paid plans, using the **Auto** picker applies a 10%
multiplier discount. E.g., Sonnet 4 under Auto = 0.9x instead of 1x. Auto currently selects
from: GPT-4.1, GPT-5.2-Codex, GPT-5.3-Codex, Claude Haiku 4.5, Claude Sonnet 4.5, Grok Code
Fast 1, Raptor mini.

---

### 3. How Thinking Effort Maps to Underlying API Parameters

VS Code abstracts thinking effort behind a unified Low/Medium/High/None UI but maps to
provider-specific parameters under the hood. The two deprecated settings reveal the split:

| Setting (deprecated) | Provider | API Parameter |
|----------------------|----------|---------------|
| `github.copilot.chat.anthropic.thinking.effort` | Anthropic (Claude) | `thinking.budget_tokens` in the Messages API |
| `github.copilot.chat.responsesApiReasoningEffort` | OpenAI (Responses API) | `reasoning.effort` (`low` / `medium` / `high`) |

The GitHub Copilot proxy service translates the VS Code effort level to the appropriate upstream
parameter before forwarding the request to the model provider.

#### Anthropic mapping

Anthropic's extended thinking API uses a `thinking` block with:

- `type: "enabled"`
- `budget_tokens: <integer>` — upper bound on thinking tokens

VS Code's Low/Medium/High labels correspond to different `budget_tokens` values. The exact numeric
values are determined by VS Code's internal evaluation data and are not publicly documented. The
adaptive reasoning mode maps to Anthropic's dynamic budget behaviour where the model stops thinking
early if it concludes the reasoning is sufficient.

In v1.109, VS Code began rendering Anthropic thinking tokens in the chat UI, controlled by:

- `chat.thinking.style` — `detailed` or `compact`
- `chat.agent.thinking.collapsedTools` — whether thinking during tool calls collapses
- `chat.agent.thinking.terminalTools` — show thinking interleaved with terminal tool calls

#### OpenAI mapping

OpenAI's Responses API exposes `reasoning.effort` as a first-class string enum. VS Code maps:

- Low → `"low"`
- Medium → `"medium"`
- High → `"high"`

GPT models that support reasoning (GPT-5.x series) expose the thinking effort submenu. Classic
models (GPT-4.1, GPT-4o) do not.

#### Gemini mapping

Gemini 2.5 Pro and Gemini 3.x Pro models support extended thinking via Google's API. The exact
parameter name in Gemini's API is not documented in VS Code's public changelog; VS Code applies the
same Low/Medium/High abstraction.

---

### 4. Agent `.agent.md` Model Pinning and Thinking Effort

#### `model:` field in agent frontmatter

Agents can specify a preferred model using the `model:` frontmatter field:

```yaml
---
name: Planner
model: Claude Opus 4.6          # single model
# or a prioritised fallback list:
model: ['Claude Opus 4.6', 'GPT-5.2']
---
```

When `model:` is an array, VS Code tries each model in order until one is available. If `model:`
is omitted, the model currently selected in the picker is used.

**Qualified model names** for handoffs use the format `Model Name (vendor)`, e.g.
`GPT-5 (copilot)` or `Claude Sonnet 4.5 (copilot)`.

#### Can agents specify thinking effort in frontmatter?

**No.** As of v1.110 (current stable, March 2026), the `.agent.md` frontmatter schema does
**not** include a thinking effort field. Thinking effort is a per-user, per-model setting stored
in VS Code user state. It persists across conversations for a given model but cannot be pinned per
agent. This is documented on the language models reference page:

> "The effort level persists across conversations for the same model."

The practical implication: if a user has set Claude Sonnet 4.6 to High effort, all agents that
use Sonnet 4.6 (either explicitly or via Auto) will receive High effort. There is no per-agent
override.

This is consistent with the established `.agent.md` schema fields:
`description`, `name`, `argument-hint`, `tools`, `agents`, `model`, `user-invocable`,
`disable-model-invocation`, `target`, `mcp-servers`, `handoffs`, `hooks`.

No `thinking-effort:` or `reasoning-effort:` field exists.

---

### 5. VS Code Settings for Thinking Effort

| Setting | Status | Description |
|---------|--------|-------------|
| `github.copilot.chat.anthropic.thinking.effort` | **Deprecated** | Previous per-model effort for Anthropic; replaced by UI picker |
| `github.copilot.chat.responsesApiReasoningEffort` | **Deprecated** | Previous per-model effort for OpenAI Responses API; replaced by UI picker |
| `chat.thinking.style` | Active | `detailed` or `compact` — controls rendering verbosity of thinking tokens in the chat UX (v1.109+) |
| `chat.agent.thinking.collapsedTools` | Active | Whether thinking content during tool calls starts collapsed |
| `chat.agent.thinking.terminalTools` | Active | Show thinking interleaved with terminal tool call output |
| `github.copilot.chat.agent.thinkingTool` | Experimental (v1.99) | Enables the **Thinking Tool** in agent mode — gives any model (including non-reasoning models) a structured think-between-calls step, separate from native thinking tokens |

#### Thinking Tool vs. Thinking Effort — key distinction

These are two different mechanisms:

| | Thinking Tool | Thinking Effort |
|-|---------------|----------------|
| **What it is** | A tool the agent can call between other tool calls to "think out loud" | A parameter passed to the model controlling its internal reasoning token budget |
| **Works with** | Any model in agent mode | Only reasoning-capable models |
| **Introduced** | v1.99 (March 2025, experimental) | Formalised in UI in v1.109 (Jan 2026); deprecated settings existed earlier |
| **Inspired by** | Anthropic blog post on the `think` tool pattern | Provider native extended thinking APIs |
| **Visible to user** | Yes — appears as a tool call in the conversation | Rendered in v1.109+ via `chat.thinking.style` |

---

## Recommendations

1. **For this repo's `.agent.md` files**: Model selection via `model:` is the correct and only
   available mechanism. Agents cannot encode thinking effort preferences. Document this as an
   explicit known limitation in agent design notes.

2. **MODELS.md**: The `model:` field accepts qualified names. The current MODELS.md entries use
   names like `Claude Sonnet 4.6` without the `(copilot)` vendor qualifier — this is correct
   for standard Copilot-hosted models; the vendor qualifier is only needed for BYOK models or
   handoff targets.

3. **User-facing docs**: When documenting agent model selection, note that thinking effort is a
   user-level setting that applies globally per model, not per agent. Users wanting high effort
   for heavy reasoning agents must set it in the picker before invoking that agent.

4. **Template consideration**: The deprecated settings `github.copilot.chat.anthropic.thinking.effort`
   and `github.copilot.chat.responsesApiReasoningEffort` should be removed from any
   `settings.json` stubs in the template if present, in favour of the picker UI.

---

## Gaps / Further Research Needed

- Exact `budget_tokens` values that VS Code uses for Low/Medium/High on Anthropic models (not
  publicly documented; would require reading VS Code extension source or API logs).
- Whether the Gemini 3.x models use Google's `thinkingConfig.thinkingBudget` parameter and how
  VS Code maps Low/Medium/High to that.
- Whether the upcoming v1.111 (April 2026) introduces per-agent thinking effort configuration
  in `.agent.md` frontmatter — this would be a significant authoring improvement.
- `Raptor mini` model: GitHub's own model with minimal public documentation. Model card "coming
  soon" per comparison docs.
- `Goldeneye` appears in the comparison doc for deep reasoning but was not present in the user's
  picker — may be gated behind a flag or enterprise-only feature.
