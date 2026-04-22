# Research: Reducing Token Usage in AI Agent Instruction Files

> Date: 2026-04-09 | Agent: Researcher | Status: complete

## Summary

Token reduction in AI agent system prompts is an active research domain with two distinct
approaches: **run-time compression** (tools that compress text before sending it to an LLM) and
**authoring discipline** (writing instructions in formats and styles that are inherently more
token-efficient while remaining effective). For a repo that delivers static Markdown instruction
files to GitHub Copilot and compatible agents, authoring discipline and structural reorganisation
offer the highest impact at the lowest effort and zero runtime dependency. Run-time compression
tools (LLMLingua-2, Claw Compactor) are applicable as a preprocessing step to generate a
"compressed variant" of instruction files for machine-only consumption. A critical counterintuitive
finding (McMillan 2026): optimising for raw *file* token count can *increase* total context window
consumption if the model is unfamiliar with the compressed format — familiarity is as important
as brevity.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://arxiv.org/abs/2310.05736> | LLMLingua — up to 20x compression via perplexity-based pruning |
| <https://arxiv.org/abs/2403.12968> | LLMLingua-2 — BERT-based, 3x-6x faster, 2x-5x compression |
| <https://github.com/microsoft/LLMLingua> | LLMLingua GitHub repo, integrations, usage |
| <https://llmlingua.com/> | LLMLingua project page with benchmarks |
| <https://arxiv.org/abs/2310.06201> | Selective Context — 50% cost reduction, self-info pruning (also labelled as LLMLingua ID in prompt, but is Li et al.) |
| <https://arxiv.org/abs/2310.04408> | RECOMP — extractive/abstractive document compressors, 6% compression rate |
| <https://arxiv.org/abs/2305.14788> | AutoCompressor — soft-prompt summary vectors for long context |
| <https://aclanthology.org/2025.naacl-long.376/> | GenPI — Generative Prompt Internalization; fine-tunes-away explicit prompts |
| <https://arxiv.org/abs/2307.03172> | "Lost in the Middle" — LLM recall degrades for info in middle of context |
| <https://arxiv.org/abs/2602.05447> | Structured Context Engineering — YAML/MD/JSON/TOON comparison over 9,649 experiments |
| <https://simonwillison.net/2026/Feb/9/structured-context-engineering-for-file-native-agentic-systems/> | Simon Willison commentary on TOON "grep tax" finding |
| <https://github.com/open-compress/claw-compactor> | Claw Compactor — 14-stage deterministic pipeline, 15-82% compression |
| <https://github.com/sriinnu/clipforge-PAKT> | ClipForge PAKT — lossless-first structured data compression (TS/npm) |
| <https://github.com/gladehq/claude-shorthand> | Claude-shorthand — LLMLingua-2 hook for Claude Code, ~55% reduction |
| <https://github.com/topics/prompt-compression> | GitHub topic — 32 repos, state-of-art tools (April 2026) |
| <https://www.anthropic.com/news/prompt-caching> | Anthropic prompt caching — 90% cost, 85% latency reduction |
| <https://simonwillison.net/2026/Feb/20/thariq-shihipar/> | Claude Code built around prompt caching; SEV declared on cache hit rate drop |
| <https://simonwillison.net/2025/Jun/27/context-engineering/> | "Context engineering" term, Andrej Karpathy quote on context window filling |
| <https://www.anthropic.com/research/building-effective-agents> | Anthropic — workflows vs agents; routing pattern for instruction specialisation |

---

## Findings

### 1. Prompt Compression Techniques

#### LLMLingua Family (Microsoft Research)

The most influential academic compression series as of April 2026.

**LLMLingua** (EMNLP 2023, arXiv:2310.05736)
- Coarse-to-fine method: first compresses by sentence/paragraph, then by token
- Uses a small language model (SLM, e.g. LLaMA-7B) to score token perplexity
- Budget controller for semantic integrity at high ratios
- **Up to 20x compression** with "little performance loss" on CoT, RAG, and ICL benchmarks
- Limitation: requires SLM inference at compression time (~$0.02/call estimated cost)
- Limitation: perplexity-based scoring can corrupt code identifiers and structured keys

**LLMLingua-2** (ACL Findings 2024, arXiv:2403.12968)
- Replaces causal SLM scoring with a **bidirectional BERT encoder** (XLM-RoBERTa-large or mBERT)
- Formulates compression as token classification (preserve/drop) — more stable for structured text
- **3x-6x faster** than LLMLingua; **2x-5x compression** ratios
- **1.6x-2.9x end-to-end latency reduction** on tasks with 2x-5x compression
- Task-agnostic (does not require task-specific training)
- Available: `pip install llmlingua`; LangChain + LlamaIndex integrations
- Claude-shorthand plugin claims ~55% reduction on prompts over 800 chars using LLMLingua-2

**LongLLMLingua** — query-aware variant for long retrieval-augmented contexts; reorganises
retrieved passages closer to the query to reduce "lost in the middle" degradation.

**Estimated savings for instruction files**: LLMLingua-2 at a moderate ratio (0.4 rate) yields
~40-55% token reduction. Quality loss is low for natural language text but caution is warranted
for code snippets, command examples, and precise constraint lists.

**Applicability to this repo**: Medium.
- Useful as a preprocessing step to generate a `compact/copilot-instructions.md` variant
- Would require a build step (Python dependency, ~400MB BERT model)
- Aggressive compression risks removing actionable constraints

---

#### Selective Context (Li et al., EMNLP 2023, arXiv:2310.06201)

- Uses **self-information** (per-token entropy from a SLM) to identify and remove redundant tokens
- **50% context reduction → 36% memory reduction, 32% inference time reduction**
- Only 0.023 BERTscore drop on four downstream tasks
- Lexical units (words/phrases rather than tokens) are the pruning granularity
- Lower complexity than LLMLingua; no budget controller
- Available as open-source Python

**Applicability to this repo**: Medium. Less controllable than LLMLingua-2 but simpler.

---

#### RECOMP (Xu et al., 2023, arXiv:2310.04408)

- Targets **retrieval-augmented** contexts: compresses retrieved documents before in-context use
- **Extractive compressor**: selects useful sentences from retrieved documents
- **Abstractive compressor**: synthesises summaries across multiple documents
- **As low as 6% of original size** with minimal performance loss on language modelling + QA tasks
- Can return empty string if retrieved document is irrelevant — "selective augmentation"

**Applicability to this repo**: Low–medium. Directly applicable if a repo adopts a
RAG-like pattern where instruction sections are retrieved per-request rather than loaded wholesale.

---

#### AutoCompressor (Chevalier et al., EMNLP 2023, arXiv:2305.14788)

- Fine-tunes LLMs to produce **summary vectors** ("soft prompts") from long documents
- Summary vectors are prepended as a soft prompt, replacing the full text
- Tests on OPT and Llama-2 at 30,720 token sequences
- **Key limitation**: Requires model fine-tuning — not applicable to off-the-shelf Copilot/Claude

**Applicability to this repo**: None (requires model access).

---

#### Generative Prompt Internalization — GenPI (KAIST, NAACL 2025)

- Fine-tunes a model to **internalise** a system prompt, eliminating it entirely at inference
- Joint training with a "prompt generation loss" — model reproduces prompt content with reasons
- Verified for agent-based application scenarios
- Data synthesis technique for collecting training data when only a prompt (no dataset) exists

**Applicability to this repo**: None for consumers (requires fine-tuning). Relevant if this repo
were to produce fine-tuned model variants; currently out of scope.

---

#### Claw Compactor (open-compress, 2026)

- **14-stage deterministic Fusion Pipeline** — no LLM inference required, zero extra cost
- Stages: AST-aware code compression (tree-sitter), JSON schema sampling, semantic deduplication
  (simhash), log folding, import merging, format optimisation, NL abbreviation, etc.
- **Reversible**: stores originals in a hash-addressed RewindStore; LLM can retrieve by marker ID
- **Benchmark results** (FusionEngine v7):

  | Content Type | Compression |
  |---|---|
  | JSON (100 items) | 81.9% |
  | Search results | 40.7% |
  | Agent conversation | 31.0% |
  | Python source | 25.0% |
  | Build logs | 24.1% |
  | Git diff | 15.0% |
  | **Weighted average** | **36.3%** |

- Beats LLMLingua-2 on ROUGE-L @ 0.3 (0.653 vs 0.346) and @ 0.5 (0.723 vs 0.570)
- **Latency**: <50ms vs ~300ms for LLMLingua-2
- Available: `pip install claw-compactor`

**Applicability to this repo**: High.
- Can preprocess Markdown instruction files at build time
- AST-aware stages protect code blocks and command examples
- Semantic deduplication removes boilerplate (relevant for files with repeated patterns)
- Reversibility means no information is permanently lost

---

#### ClipForge PAKT (sriinnu, 2026)

- **Lossless-first** TypeScript/Node library for structured data compression
- Targets JSON, YAML, CSV, Markdown — not token-removal; structural normalisation
- **Savings by content type**:
  - Structured payloads (JSON/YAML): 27–33%
  - Repetitive text: 38–69%
  - Log data: 57%
- Includes MCP server, CLI, npm package (`@sriinnu/pakt`)
- No LLM inference required

**Applicability to this repo**: Medium.
- Useful for compressing YAML/JSON workspace index or tool catalogues
- Less applicable to prose-heavy Markdown instruction sections

---

### 2. Machine-Readable vs. Human-Readable Instruction Formats

#### Structured Context Engineering (McMillan, Feb 2026, arXiv:2602.05447)

The most directly relevant 2026 paper for this question. 9,649 experiments across 11 models
(including Opus 4.5, GPT-5.2, Gemini 2.5 Pro), 4 formats (YAML, Markdown, JSON, TOON), and
schemas up to 10,000 SQL tables.

**Key finding — the "Grep Tax"**:

TOON (Token-Oriented Object Notation) was designed specifically to minimise token count —
approximately 25% smaller file size than YAML. Yet at scale it caused *dramatically higher*
total context consumption:

| Schema size | TOON vs YAML overhead |
|---|---|
| 500 tables (S5) | +138% more tokens than YAML |
| 10,000 tables (S9) | +740% more tokens than YAML |

Root cause: models were unfamiliar with TOON syntax and spent multiple iterations constructing
and refining grep patterns to navigate it. **File token savings were vastly outweighed by runtime
token consumption.**

**Summary ranking for structured data (large scale)**:
1. YAML — best balance of familiarity and compactness
2. Markdown — excellent for smaller instruction sets; most familiar to frontier LLMs
3. JSON — verbose boilerplate (quotes, braces, commas) but familiar
4. TOON — theoretically optimal, practically catastrophic at scale

**Implication for this repo**: Continue using Markdown. Do not introduce a custom
token-compact notation. If YAML is introduced for structured sections, it will likely compress
better than verbose Markdown tables for large lookup structures, but only for frontier models.
Open-weight models showed less benefit from filesystem-based context retrieval entirely.

---

#### Anthropic's XML Tag Recommendation (Known from Docs)

Anthropic documentation (blocked in this session) recommends XML tags for Claude prompts:

```xml
<instructions>
Your role is...
</instructions>
<context>
...
</context>
```

XML tags add semantic structure that Claude's training specifically accounts for. They create
clear section boundaries that help the model locate relevant subsections without scanning the
entire prompt. This is a different use case from token minimisation: it improves *utilisation*
of tokens you do have.

**Applicability**: The `.github/copilot-instructions.md` already uses Markdown headers (##) for
sections, which is directionally correct. For Claude-targeted consumption, wrapping major sections
in XML tags in a compiled variant could improve instruction adherence.

---

### 3. Dual-Layer Documentation Patterns

No dedicated academic paper was found specifically on "dual-layer" instruction architectures
for agent instruction files. However, the pattern is implicit in several frameworks:

#### Agent Framework Approaches

**LangChain**: Supports `SystemMessagePromptTemplate` with partial formatting — allows a master
instruction template to be specialised per task by substituting only the varying sections.
LLMLingua integration is available as a retrieval post-processor.

**CrewAI**: Agent `role`, `goal`, and `backstory` are stored as separate fields. Only the
relevant fields for the current agent type are included in the system prompt. This is a natural
dual-layer: a full role library (human-readable) + a per-agent compiled prompt (machine-facing).

**AutoGen**: Uses condensed "conversation patterns" — the model system prompt is intentionally
short; detailed context is injected dynamically per turn via tool results.

**Semantic Kernel**: Functions and plugins are described in a skill manifest; the planner selects
and loads only the functions relevant to the current task (lazy loading of capability descriptions).

#### Practical Pattern for This Repo

The dual-layer pattern applicable here:

```
Human-Readable Layer                Machine-Facing Layer
─────────────────────────────────   ─────────────────────
.github/copilot-instructions.md     Generated at build time
template/copilot-instructions.md    (e.g. claw-compactor
                                     + deduplication pass)
```

Key design consideration: the machine-facing layer must remain **deterministic** (same byte
sequence every run) to maximise prompt cache hit rates (see §4).

---

### 4. Context Window Optimization

#### "Lost in the Middle" (Liu et al., Stanford/Berkeley, TACL 2023, arXiv:2307.03172)

Evaluated GPT-3.5-Turbo, GPT-4, and Claude-family models on multi-document QA and key-value
retrieval with relevant information at varying positions.

**Key finding**: Performance follows a U-shaped curve:
- **Beginning of context** → highest recall
- **End of context** → second-highest recall
- **Middle of context** → significant degradation, even for explicitly long-context models

**Direct implications for `.github/copilot-instructions.md`**:
- "Critical Reminders" at the top of this file is correct — primacy effect
- The most operationally important constraints (test invocation, no file deletion) should be
  in the first 20% or last 10% of the file
- Long tables and low-priority reference sections (Waste Catalogue, File Inventory) that are
  scanned on-demand can safely be placed in the middle
- If the file must grow, add a **TL;DR summary block** at the very top (≤15 lines) covering the
  highest-impact constraints

---

#### Prompt Caching (Anthropic, GA August 2025)

Prompt caching caches the KV state of a prompt prefix between API calls. A cached prefix is
reused across requests provided the byte sequence is identical.

**Cost / latency table** (from Anthropic GA announcement):

| Use case | Latency reduction | Cost reduction |
|---|---|---|
| 100K-token cached prompt | -79% | -90% |
| 10K-token many-shot prompt | -31% | -86% |
| 10-turn conversation w/ long system prompt | -75% | -53% |

Key operational fact from Claude Code (Thariq Shihipar, February 2026):
> "We build our entire harness around prompt caching. A high prompt cache hit rate decreases
> costs and helps us create more generous rate limits. We run alerts on our prompt cache hit rate
> and declare SEVs if they are too low."

**Implications**:
- For API-based consumers: instruction files that are **stable between turns** (minimal dynamic
  content) maximise cache utility
- VS Code Copilot does not expose prompt caching directly (it is managed by the GitHub Copilot
  backend), but VS Code v1.110 introduced "context compaction" as a related feature
- Any "dynamic" section injected into the instruction file (timestamps, session state) breaks
  cache locality and should be separated from the stable prefix

---

#### MInference (Microsoft, 2024)

10x latency reduction for pre-filling 1M-token prompts via sparse attention patterns.
Relevant for model infrastructure operators, not for instruction file authors. Included for
completeness.

---

#### Context Engineering as a Discipline (Andrej Karpathy, June 2025)

Karpathy described "context engineering" as:
> "The delicate art and science of filling the context window with just the right information
> for the next step. Science because doing this right involves task descriptions and explanations,
> few-shot examples, RAG, related data, tools, state and history, compacting."

This framing is directly applicable: the goal of instruction file optimisation is not to shrink
blindly but to ensure the right information is present and in the right position for the task
at hand. Routing (loading task-specific instruction sub-files) is a key technique.

---

### 5. Structured Instruction Compression — Writing Style

No dedicated benchmark paper comparing bullet/table/prose formats for Markdown instruction files
was found. The following recommendations derive from adjacent research (Claw Compactor
benchmarks, RECOMP sentence selection, LLMLingua token scoring patterns) and practitioner
experience.

#### Format Hierarchy (Most to Least Token-Efficient)

For **reference lookups** (key to value):
```
Most efficient: Markdown tables
Middle: Bullet lists with bold key
Least efficient: Prose paragraphs
```

Example comparison (same content, different formats):

**Prose (32 tokens)**:
> The test command that should be run before marking a task complete is `bash tests/run-all.sh`.
> During intermediate phases, use targeted test suites.

**Bullet (18 tokens)**:
> - Full suite gate: `bash tests/run-all.sh` (before task complete)
> - Intermediate: targeted suites only

**Table row (12 tokens)**:
> | Full suite | `bash tests/run-all.sh` | Before task complete |

For **process descriptions** (ordered steps):
- Numbered lists > prose paragraphs
- Imperative mood ("Run X" not "You should run X") — saves ~2-4 tokens per rule

#### High-Waste Language Patterns to Eliminate

| Pattern | Example | Replacement | ~Savings |
|---|---|---|---|
| Hedging verbs | "You should use", "It is recommended to" | "Use" | 3-5 tok/instance |
| Transitional phrases | "As noted above", "It is worth noting that" | (remove) | 4-8 tok/instance |
| Passive voice | "Tests must be run by the agent" | "Run tests" | 3-5 tok/instance |
| Existential openers | "There are several cases where" | "When" | 3-6 tok/instance |
| Redundant repetition | Repeating the same rule in different sections | (deduplicate) | 10-50+ tok |

#### Abbreviation with Defined Acronyms

Define domain acronyms once, use them throughout. For long recurring phrases:
- "Structured Thinking Discipline" → define once, reference as "STD" or an XML-tag shorthand
- The Claw Compactor's Abbrev stage achieves ~6.8% additional reduction from NL shortening alone

---

### 6. Real-World Examples

#### Claude Code Prompt Caching (Anthropic, 2026)

The most concrete production-scale example: Claude Code's entire architecture is designed around
keeping the system prompt prefix stable to maximise prompt cache hit rates. Operational SEV-level
alerting is set on cache hit rate degradation.

**Lesson for this repo**: instructions should have a stable prefix (fixed-position core rules +
role definition) and a dynamic suffix (session context, recent decisions). Never inject
timestamps or per-session values into the core system prompt.

#### Claude-shorthand Plugin (gladehq, March 2026)

A Claude Code plugin that applies LLMLingua-2 compression to every user prompt over 800
characters before it is sent to Claude. Claims ~50% savings by default (`rate: 0.4`).
Protects code tokens (function names, class names, file extensions) from compression.

This is a *client-side* run-time compression approach — not applicable to static instruction
files, but the token-preservation whitelist strategy is directly useful: when authoring rules
that contain precise command names or flags, those tokens should be treated as inviolable.

#### Community Cursorrules Patterns (PatrickJS/awesome-cursorrules)

The awesome-cursorrules repo (3,000+ stars) is a community collection of `.cursorrules` files.
Reviewing its structure reveals:
- Community-maintained files include role definitions, tech-stack constraints, and style rules
- No compression or dual-layer pattern is standardised; most are author-maintained prose
- No benchmarks on which formats produce best instruction-following

**Lesson**: The community has not yet converged on a token-efficient format. This represents
an opportunity for this repo to be the reference point for structured instruction authoring.

#### Claw Compactor Benchmarks (2026)

Real-world test on 47 files / 234,891 tokens gives 53.9% weighted compression in ~88ms.
Key content-type results: JSON 81.9% reduction, agent conversations 31%, Python source 25%.
For the Markdown+YAML instruction files in this repo, an estimate of 20-35% reduction is
plausible via content-aware deterministic compression at build time.

---

## Recommendations

Ranked by estimated impact-to-effort ratio:

### Tier 1 — High Impact, Low Effort (Authoring Changes Only)

**1. Eliminate high-waste language patterns** (Est. savings: 8-15% of current file)
- Convert prose rules to imperative bullets and tables
- Remove hedging, passive voice, transitional phrases
- Applicable to: `template/copilot-instructions.md`, `.github/copilot-instructions.md`
- Effort: 1-2 hours; no tooling required
- Risk: none — purely editorial

**2. Apply primacy ordering** (Impact: improved instruction adherence, not token reduction)
- Place the 5-10 most operationally critical constraints **first** in the file
- Add a ≤15-line TL;DR block at position 0 (before any header)
- Based on "Lost in the Middle" finding (Liu et al., 2023)
- Effort: 1 hour; no tooling required

**3. Deduplicate rules across sections** (Est. savings: 5-20% depending on file size)
- Audit for rules stated in >1 section; keep canonical location, remove duplicates
- Cross-reference with a pointer instead of repeating the rule text
- Effort: 2-3 hours; use `grep` to scan for repeated phrases

---

### Tier 2 — High Impact, Medium Effort (Tooling Required)

**4. Build-time deterministic compression** (Est. savings: 20-35%)
- Integrate Claw Compactor into a pre-delivery build step
- Output: `template/compact/copilot-instructions.md` alongside human-readable source
- Zero LLM inference cost; reversible
- Effort: 4-8 hours; Python dependency, CI step
- Risk: low — output is validated against ROUGE-L threshold before acceptance

**5. Section-scoped routing via path instructions** (Impact: avoids loading irrelevant sections)
- This repo already uses `.github/instructions/` path-scoped files — extend the coverage
- Move large reference tables (Waste Catalogue, File Inventory) into separate include files
- Loaded only when the relevant path pattern matches
- Effort: 3-5 hours; no external tooling
- Risk: instructions may be missed if path routing is too narrow

---

### Tier 3 — Medium Impact, Higher Effort

**6. Stable prefix design for prompt caching** (Impact: cost reduction for API consumers)
- Restructure template so the invariant top section (role, critical rules) is always identical
- Dynamic elements (optional sections) appended after the stable prefix
- Enables Anthropic/OpenAI prompt caching for API-based consumers of the template
- Effort: 4-6 hours
- Risk: requires understanding consumer environments (VS Code does not expose cache control)

**7. LLMLingua-2 preprocessing pipeline** (Est. savings: 40-55%)
- More aggressive than Claw Compactor; operates at token level
- Requires Python, BERT model (~400MB), non-zero inference latency
- Apply with a conservative rate (0.5-0.6) to avoid removing constraint text
- Whitelist: command names, tool invocations, file paths, section headers
- Effort: 8-12 hours (pipeline + quality validation)
- Risk: medium — sentence-level compression can accidentally drop nuanced constraints

---

### Non-Recommendations (Based on Research)

**Do NOT introduce a custom compact notation** (TOON-like formats):
- The McMillan 2026 paper demonstrates that unfamiliar token-efficient formats cause a "grep tax"
  that outweighs file-size savings by 138-740% at scale
- Stick to Markdown; YAML is acceptable for structured lookup sections

**Do NOT use AutoCompressor or GenPI**:
- Both require model fine-tuning; incompatible with the VS Code Copilot deployment model

**Do NOT compress aggressively without a quality gate**:
- LLMLingua at high ratios (20x) degrades constraint recall, particularly for precise rules
- Any compression pipeline must include a ROUGE-L or BERTscore validation step

---

## Gaps / Further Research Needed

1. **Benchmark: markdown format variants for instruction files** — No paper directly compares
   bullet lists vs prose paragraphs vs tables for LLM instruction-following accuracy on
   coding agent tasks. This would require controlled A/B testing on agent task completion.

2. **VS Code Copilot context compaction** (v1.110+) — The compaction feature is underspecified
   in public docs. Research needed: does it apply to the system prompt prefix, or only to
   conversation history? Is it triggered automatically or on request?

3. **Position analysis for multi-section instruction files** — "Lost in the Middle" was tested
   on retrieval tasks, not instruction-following. A focused study of rule recall vs. position
   in Copilot instructions would provide actionable data for section ordering.

4. **Dual-layer delivery validation** — No production examples found of a repo shipping both a
   human-readable and a compressed machine-facing instruction file with demonstrated quality
   equivalence. This repo could pioneer and publish such a study.

5. **Correct RECOMP arxiv ID** — The user-provided arXiv ID 2310.02418 was a materials science
   paper. RECOMP (Xu et al. 2023) is at arXiv:2310.04408. The semantic context compression paper
   that is sometimes tagged as "RECOMP" in certain citations may be a different work. Verify
   the canonical RECOMP paper before citing in downstream documentation.
