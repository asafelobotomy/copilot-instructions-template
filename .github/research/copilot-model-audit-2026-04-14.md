# Research: GitHub Copilot Model Audit — Full Table Dump

> Date: 2026-04-14 | Agent: Researcher | Status: complete
> Sources: github/docs raw data YAML files (canonical — not rendered HTML)

## Summary

Full extraction of all GitHub Copilot model data as of 2026-04-14, sourced directly from the
`github/docs` repository data YAML files that power the rendered docs pages. The original URLs
requested (under `using-github-copilot/ai-models/`) now redirect to the restructured paths under
`reference/ai-models/` and `how-tos/`. Table data lives in `data/tables/copilot/*.yml`.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-release-status.yml | Canonical model list with GA/preview/closing-down status and mode support |
| https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-deprecation-history.yml | Full retirement history with dates and suggested alternatives |
| https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-multipliers.yml | Premium request multipliers per model (paid and free plans) |
| https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-supported-clients.yml | Per-model client availability matrix |
| https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-supported-plans.yml | Per-model plan availability matrix |
| https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-comparison.yml | Task-to-model recommendation data |
| https://raw.githubusercontent.com/github/docs/main/content/copilot/reference/ai-models/supported-models.md | Supported models page source (template only, data injected from YAMLs above) |
| https://raw.githubusercontent.com/github/docs/main/content/copilot/reference/ai-models/model-comparison.md | Model comparison page source |
| https://raw.githubusercontent.com/github/docs/main/content/copilot/concepts/fallback-and-lts-models.md | Base model and LTS model definitions |

---

## Findings

### 1. Supported Models — Release Status (model-release-status.yml)

All modes (agent, ask, edit) are `true` for every model in this table.

#### OpenAI

| Model | Provider | Release Status |
|-------|----------|----------------|
| GPT-4.1 | OpenAI | GA |
| GPT-5 mini | OpenAI | GA |
| GPT-5.1 | OpenAI | **Closing down: 2026-04-15** |
| GPT-5.2 | OpenAI | GA |
| GPT-5.2-Codex | OpenAI | GA |
| GPT-5.3-Codex | OpenAI | GA |
| GPT-5.4 | OpenAI | GA |
| GPT-5.4 mini | OpenAI | GA |

#### Anthropic

| Model | Provider | Release Status |
|-------|----------|----------------|
| Claude Haiku 4.5 | Anthropic | GA |
| Claude Opus 4.5 | Anthropic | GA |
| Claude Opus 4.6 | Anthropic | GA |
| Claude Opus 4.6 (fast mode) (preview) | Anthropic | Public preview |
| Claude Sonnet 4 | Anthropic | GA |
| Claude Sonnet 4.5 | Anthropic | GA |
| Claude Sonnet 4.6 | Anthropic | GA |

#### Google

| Model | Provider | Release Status |
|-------|----------|----------------|
| Gemini 2.5 Pro | Google | GA |
| Gemini 3 Flash | Google | Public preview |
| Gemini 3.1 Pro | Google | Public preview |

#### xAI

| Model | Provider | Release Status |
|-------|----------|----------------|
| Grok Code Fast 1 | xAI | GA |

#### Fine-tuned / Evaluation

| Model | Provider | Release Status |
|-------|----------|----------------|
| Raptor mini | Fine-tuned GPT-5 mini | Public preview |
| Goldeneye | Fine-tuned GPT-5.1-Codex | Public preview |

> **Note**: `Qwen2.5` appears in `model-comparison.yml` (task area: General-purpose coding) but
> is absent from `model-release-status.yml`, `model-supported-clients.yml`, and
> `model-supported-plans.yml`. This indicates it is either an evaluation-only model or pending
> full table integration.

---

### 2. Model Retirement History (model-deprecation-history.yml)

Sorted newest to oldest. Today is 2026-04-14.

| Model | Retirement Date | Status | Suggested Alternative |
|-------|-----------------|--------|-----------------------|
| GPT-5.1 | 2026-04-15 | **Closing down tomorrow** | GPT-5.3-Codex |
| GPT-5.1-Codex | 2026-04-01 | Retired | GPT-5.3-Codex |
| GPT-5.1-Codex-Max | 2026-04-01 | Retired | GPT-5.3-Codex |
| GPT-5.1-Codex-Mini | 2026-04-01 | Retired | GPT-5.3-Codex |
| Gemini 3 Pro | 2026-03-26 | Retired | Gemini 3.1 Pro |
| Claude Opus 4.1 | 2026-02-17 | Retired | Claude Opus 4.6 |
| GPT-5 | 2026-02-17 | Retired | GPT-5.2 |
| GPT-5-Codex | 2026-02-17 | Retired | GPT-5.2-Codex |
| Claude Sonnet 3.5 | 2025-11-06 | Retired | Claude Haiku 4.5 |
| Claude Opus 4 | 2025-10-23 | Retired | Claude Opus 4.6 |
| Claude Sonnet 3.7 | 2025-10-23 | Retired | Claude Sonnet 4.6 |
| Claude Sonnet 3.7 Thinking | 2025-10-23 | Retired | Claude Sonnet 4.6 |
| Gemini 2.0 Flash | 2025-10-23 | Retired | Gemini 2.5 Pro |
| o1-mini | 2025-10-23 | Retired | GPT-5 mini |
| o3 | 2025-10-23 | Retired | GPT-5.2 |
| o3-mini | 2025-10-23 | Retired | GPT-5 mini |
| o4-mini | 2025-10-23 | Retired | GPT-5 mini |

---

### 3. Task-to-Model Recommendation Table (model-comparison.yml)

#### Quick reference (all models)

| Model | Task Area | Excels At |
|-------|-----------|-----------|
| GPT-4.1 | General-purpose coding and writing | Fast, accurate code completions and explanations |
| GPT-5 mini | General-purpose coding and writing | Fast, accurate code completions and explanations |
| GPT-5.1 | Deep reasoning and debugging | Multi-step problem solving and architecture-level code analysis |
| GPT-5.2 | Deep reasoning and debugging | Multi-step problem solving and architecture-level code analysis |
| GPT-5.2-Codex | Agentic software development | Agentic tasks |
| GPT-5.3-Codex | Agentic software development | Agentic tasks |
| GPT-5.4 | Deep reasoning and debugging | Multi-step problem solving and architecture-level code analysis |
| GPT-5.4 mini | Agentic software development | Codebase exploration, especially effective with grep-style tools |
| Claude Haiku 4.5 | Fast help with simple or repetitive tasks | Fast, reliable answers to lightweight coding questions |
| Claude Opus 4.5 | Deep reasoning and debugging | Complex problem-solving challenges, sophisticated reasoning |
| Claude Opus 4.6 | Deep reasoning and debugging | Complex problem-solving challenges, sophisticated reasoning |
| Claude Opus 4.6 (fast mode) (preview) | Deep reasoning and debugging | Complex problem-solving challenges, sophisticated reasoning |
| Claude Sonnet 4.0 | Deep reasoning and debugging | Performance and practicality, balanced for coding workflows |
| Claude Sonnet 4.5 | General-purpose coding and agent tasks | Complex problem-solving challenges, sophisticated reasoning |
| Claude Sonnet 4.6 | General-purpose coding and agent tasks | Complex problem-solving challenges, sophisticated reasoning |
| Gemini 2.5 Pro | Deep reasoning and debugging | Complex code generation, debugging, and research workflows |
| Gemini 3 Flash | Fast help with simple or repetitive tasks | Fast, reliable answers to lightweight coding questions |
| Gemini 3.1 Pro | Deep reasoning and debugging | Effective and efficient edit-then-test loops with high tool precision |
| Grok Code Fast 1 | General-purpose coding and writing | Fast, accurate code completions and explanations |
| Qwen2.5 | General-purpose coding and writing | Code generation, reasoning, and code repair / debugging |
| Raptor mini | General-purpose coding and writing | Fast, accurate code completions and explanations |

#### Recommended models by task category (from model-comparison.md)

**General-purpose coding and writing**
- GPT-5.3-Codex: Higher-quality code on complex engineering tasks
- GPT-5 mini: Reliable default, fast, accurate across languages and frameworks
- Grok Code Fast 1: Specialized for coding, code generation and debugging
- Raptor mini: Specialized for fast, accurate inline suggestions and explanations

**Fast help with simple or repetitive tasks**
- Claude Haiku 4.5: Balances fast responses with quality output

**Deep reasoning and debugging**
- GPT-5 mini: Deep reasoning with faster responses and lower resource usage
- GPT-5.4: Complex reasoning, code analysis, technical decision-making
- Claude Sonnet 4.6: More reliable completions and smarter reasoning under pressure
- Claude Opus 4.6: Anthropic's most powerful model
- Gemini 3.1 Pro: Advanced reasoning across long contexts and scientific/technical analysis
- Goldeneye: Complex problem-solving and sophisticated reasoning

**Working with visuals (diagrams, screenshots)**
- GPT-5 mini: Supports multimodal input for visual reasoning tasks
- Claude Sonnet 4.6: More reliable completions and smarter reasoning under pressure
- Gemini 3.1 Pro: Deep reasoning and debugging for complex code generation

---

### 4. Model Multipliers (model-multipliers.yml)

> **Note from docs**: Multipliers for Claude Sonnet 4.6 and GPT-5.4 mini are subject to change.

| Model | Multiplier (Paid) | Multiplier (Free) |
|-------|-------------------|-------------------|
| **0x — No premium cost on paid plans** | | |
| GPT-4.1 | 0 | 1 |
| GPT-4o | 0 | 1 |
| GPT-5 mini | 0 | 1 |
| Raptor mini | 0 | 1 |
| **0.25x — Very low cost** | | |
| Grok Code Fast 1 | 0.25 | 1 |
| **0.33x — Low cost** | | |
| Claude Haiku 4.5 | 0.33 | 1 |
| Gemini 3 Flash | 0.33 | N/A |
| GPT-5.4 mini | 0.33 | N/A |
| **1x — Standard** | | |
| Claude Sonnet 4 | 1 | N/A |
| Claude Sonnet 4.5 | 1 | N/A |
| Claude Sonnet 4.6 | 1 | N/A |
| Gemini 2.5 Pro | 1 | N/A |
| Gemini 3.1 Pro | 1 | N/A |
| GPT-5.1 | 1 | N/A |
| GPT-5.2 | 1.0 | N/A |
| GPT-5.2-Codex | 1.0 | N/A |
| GPT-5.3-Codex | 1.0 | N/A |
| GPT-5.4 | 1.0 | N/A |
| **3x — High cost** | | |
| Claude Opus 4.5 | 3 | N/A |
| Claude Opus 4.6 | 3 | N/A |
| **30x — Very high cost** | | |
| Claude Opus 4.6 (fast mode) (preview) | 30 | N/A |
| **Evaluation only** | | |
| Goldeneye | N/A | 1 |

---

### 5. LTS and Base Model Designations (fallback-and-lts-models.md)

**Current base model**: GPT-5.3-Codex (designated 2026-03-18)
**Current LTS model**: GPT-5.3-Codex (designated 2026-03-18, 1-year commitment → until 2027-03-18)

Both designations apply only to Copilot Business and Copilot Enterprise.

Base model enablement timeline:
| Phase | Timeline | What happens |
|-------|----------|--------------|
| Announcement | Day 0 (2026-03-18) | GitHub announces new base model |
| Upgrade window | Day 0–60 | Customers upgrade IDE extensions |
| Enablement | Day 60 (~2026-05-17) | Auto-enabled for all Business/Enterprise orgs |

Fallback behaviour when premium requests are exhausted:
- Quota exhausted → automatic fallback to **GPT-4.1** (0x cost, former base model)
- Overage controls disabled → fallback to **GPT-4.1**

Base/LTS model multiplier: 1x premium request on paid plans.

---

### 6. Client Availability — Notable VS Code Distinctions

#### VS Code exclusive models (not available on any other client)

| Model | dotcom | CLI | VS Code | VS | Eclipse | Xcode | JetBrains |
|-------|--------|-----|---------|-----|---------|-------|-----------|
| Raptor mini | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Goldeneye | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |

#### Models NOT available in CLI

- Gemini 2.5 Pro, Gemini 3 Flash, Gemini 3.1 Pro (all Google models)
- Grok Code Fast 1, Raptor mini, Goldeneye

#### Models with limited IDE support (VS Code + VS only, not Eclipse/Xcode/JetBrains)

| Model | dotcom | CLI | VS Code | VS | Eclipse | Xcode | JetBrains |
|-------|--------|-----|---------|-----|---------|-------|-----------|
| Claude Sonnet 4.6 | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |

#### Models with dotcom-only restriction

| Model | dotcom | CLI | VS Code | VS | Eclipse | Xcode | JetBrains |
|-------|--------|-----|---------|-----|---------|-------|-----------|
| Claude Opus 4.6 (fast mode) (preview) | ✗ | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ |

#### Models available on all clients (dotcom + CLI + all IDEs)

Claude Haiku 4.5, Claude Opus 4.5, Claude Opus 4.6, Claude Sonnet 4, Claude Sonnet 4.5,
GPT-4.1, GPT-5 mini, GPT-5.1, GPT-5.2, GPT-5.2-Codex, GPT-5.3-Codex, GPT-5.4, GPT-5.4 mini

Note: Grok Code Fast 1 is on all clients except CLI.
Note: All Gemini models are on dotcom and all IDEs, but not CLI.

> **VS Code version requirement**: GPT-5-Codex (now retired, see footnote) required VS Code
> v1.104.1 or higher. The current retired successor path is GPT-5.2-Codex or GPT-5.3-Codex.

---

### 7. Plan Availability Summary (model-supported-plans.yml)

#### Available on Free plan

GPT-4.1, GPT-5 mini, Claude Haiku 4.5, Grok Code Fast 1, Raptor mini, Goldeneye

#### Available on Student plan (but not Free)

GPT-5.1, GPT-5.2, GPT-5.2-Codex, GPT-5.3-Codex, GPT-5.4 mini, Gemini 2.5 Pro, Gemini 3 Flash,
Gemini 3.1 Pro

#### Available on Pro/Business/Enterprise (but not Student/Free)

GPT-5.4, Claude Sonnet 4, Claude Sonnet 4.5, Claude Sonnet 4.6, Claude Opus 4.5, Claude Opus 4.6

#### Pro+ / Enterprise only (not Business)

Claude Opus 4.6 (fast mode) (preview)

#### Goldeneye note

Available on Free only — not on Student, Pro, Pro+, Business, or Enterprise. This is unusual
and suggests it is a free-tier evaluation model (confirmed: multiplier_free=1, multiplier_paid=N/A).

---

## Recommendations

For agent model pin auditing, the following changes since the last review (2026-04-11) are material:

1. **GPT-5.1 retires 2026-04-15** (tomorrow). Any agent pinned to GPT-5.1 must be migrated to
   GPT-5.3-Codex immediately.
2. **GPT-5.3-Codex** is now the base and LTS model (since 2026-03-18). It is the stable long-term
   pin for Business/Enterprise accounts through 2027-03-18.
3. **Claude Sonnet 4.6** is GA and available in VS Code, VS, dotcom, and CLI (but not Eclipse,
   Xcode, or JetBrains). Multiplier = 1x. Recommended for general coding and agent tasks.
4. **Claude Opus 4.6 (fast mode)** is preview-only and carries a 30x multiplier — avoid for
   default agent pins.
5. **Raptor mini and Goldeneye** are VS Code-exclusive and should not be pinned in agents that
   run outside VS Code.

---

## Gaps / Further research needed

- `Qwen2.5` appears in model-comparison.yml but has no release status, client, or plan entries —
  its availability and multiplier are unknown. May be an evaluation-only model.
- The `Claude Sonnet 4.0` name in model-comparison.yml vs `Claude Sonnet 4` in release-status.yml
  may be a display name inconsistency; treat as the same model.
- `GPT-5-Codex` is in the deprecation table (retired 2026-02-17) but the current live docs page
  still notes "GPT-5-Codex is supported in Visual Studio Code v1.104.1 or higher" — this note
  may not yet have been removed from the template.
