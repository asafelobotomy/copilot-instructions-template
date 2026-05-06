# Research: Agent-to-Agent Communication Efficiency for LLM Multi-Agent Systems

> Date: 2026-05-01 | Agent: Researcher | Status: complete

## Summary

The state of the art in agent-to-agent (A2A) communication efficiency has advanced substantially since early 2025. Google's A2A Protocol (now Linux Foundation, 150+ adopters) standardised a JSON Agent Card model for capability discovery, separating the orchestrator's view of an agent from the agent's internal instructions. Anthropic's production multi-agent Research system demonstrated 90.2% improvement over single agents by applying explicit delegation contracts, parallel subagent execution, and interleaved thinking — at the cost of 15× token usage. VS Code Copilot's subagent architecture formalises context isolation: the orchestrator passes only a focused subtask; the subagent returns only a summary. Prompt compression research (LLMLingua, LongLLMLingua) shows that shorter, higher-signal context improves both cost and accuracy due to the "lost in the middle" effect. Taken together, these strands converge on a single design principle: **separate the orchestrator's routing view from the agent's working view, and pass only task-scoped context at invocation time**.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://a2a-protocol.org/latest/topics/key-concepts/> | A2A core concepts: Agent Card schema, Tasks, Messages, Parts, Artifacts |
| <https://a2a-protocol.org/latest/topics/agent-discovery/> | Agent Card discovery strategies; caching guidance; security |
| <https://www.ietf.org/archive/id/draft-aevum-agentcard-00.html> | IETF draft AgentCard: ULID identity, dot-namespaced capabilities, MCP-compatible schemas |
| <https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/> | Google A2A announcement and design rationale |
| <https://www.anthropic.com/engineering/building-effective-agents> | Anthropic: simplicity, ACI, workflow patterns (routing, parallelization, orchestrator-workers) |
| <https://cuizhanming.com/anthropic-multi-agent-research-architecture/> | Anthropic multi-agent Research system deep dive: 90.2% gain, delegation contracts, scaling heuristics |
| <https://www.anthropic.com/engineering/built-multi-agent-research-system> | Primary Anthropic engineering blog post for the Research system |
| <https://code.visualstudio.com/docs/copilot/agents/subagents> | VS Code Copilot subagent docs: context isolation, coordinator-worker pattern, model selection |
| <https://developers.openai.com/cookbook/examples/orchestrating_agents> | OpenAI routines + handoffs; function-schema tool description pattern |
| <https://www.morphllm.com/prompt-compression> | Prompt compression survey: LLMLingua, LLMLingua-2, LongLLMLingua, code vs prose asymmetry |
| <https://microsoft.github.io/multi-agent-reference-architecture/docs/reference-architecture/Reference-Architecture.html> | Microsoft multi-agent reference architecture: NLU→SLM→LLM classifier cascade; supervisor pattern |
| <https://arxiv.org/abs/2410.12388> | Survey: prompt compression techniques for LLMs (NAACL 2025) |

---

## Findings

### 1. Google A2A Protocol — Agent Cards as Minimal Capability Declarations

**Released**: April 9 2025. **Now**: Linux Foundation, 150+ organisations, production use at Google, Microsoft, AWS.

The A2A protocol draws a hard boundary between two kinds of information an orchestrator needs:

| Information type | Where it lives | Size target |
|-----------------|---------------|-------------|
| What can this agent do? | **Agent Card** (JSON, cached, fetched once) | ~1–5 KB |
| How does this agent behave? | Agent's internal system prompt | Unconstrained |

The Agent Card schema (`/.well-known/agent-card.json`) contains:

```json
{
  "name": "string",
  "description": "string (1-3 sentences)",
  "url": "https://...",
  "capabilities": { "streaming": true, "pushNotifications": false },
  "authentication": { "schemes": ["Bearer"] },
  "skills": [
    {
      "id": "research.web",
      "name": "Web Research",
      "description": "Search and synthesise web content",
      "inputModes": ["text"],
      "outputModes": ["text"],
      "examples": ["Find the latest changelog for X"]
    }
  ]
}
```

**Key efficiency insight**: The orchestrator does not need to read the agent's full system prompt to decide whether to delegate. The Agent Card is fetched once, cached via HTTP `Cache-Control`/`ETag`, and reused across thousands of invocations. Per-invocation orchestrator overhead is near zero.

**Opacity principle**: A remote A2A agent is an *opaque black box* from the orchestrator's perspective — internal memory, tools, and logic are not shared. This is architecturally enforced, not just a convention.

**IETF Draft (April 2026)**: A framework-neutral AgentCard format is now progressing through IETF standardisation, with ULID-based identity and dot-namespaced capability IDs compatible with both OpenAI function-calling schemas and MCP tool definitions.

---

### 2. Anthropic — Building Effective Agents: Core Principles

Anthropic's canonical guidance (updated 2025) identifies three principles for efficient multi-agent systems:

1. **Simplicity** — Start with a single LLM + retrieval + tools. Add agents only when this demonstrably fails.
2. **Transparency** — Show planning steps explicitly. Agents should externalise reasoning.
3. **ACI (Agent-Computer Interface)** — Tool documentation is as important as the tools themselves. Bad descriptions send agents down wrong paths.

Five workflow patterns in ascending complexity:

| Pattern | When to use | Context passed |
|---------|------------|----------------|
| Prompt chaining | Fixed, sequential subtasks | Full history per call |
| Routing | Distinct categories (query type, complexity) | Routed subset only |
| Parallelisation (sectioning) | Independent subtasks | Per-subtask only |
| Orchestrator-workers | Dynamic, unpredictable subtasks | Task-scoped per worker |
| Evaluator-optimizer | Iterative refinement needed | Generation + feedback loop |

**Key message**: Add complexity only when it demonstrably improves outcomes. The orchestrator-workers pattern yields the best efficiency per token when subtask boundaries are clear.

---

### 3. Anthropic Multi-Agent Research System — Production Numbers and Delegation Contracts

Anthropic's Research feature (production, 2025) uses an orchestrator-worker architecture with an Opus 4 lead agent and parallel Sonnet 4 workers.

**Measured outcomes**:

| Metric | Value |
|--------|-------|
| Performance improvement (multi vs single) | **90.2%** |
| Token usage vs single-agent chat | **15× more** |
| Performance variance explained by token usage | **80%** |
| Task completion time reduction (better tool descriptions) | **40%** |
| Research time reduction (parallel tool calling) | **up to 90%** |

**Delegation contract pattern** — the most actionable finding:

Early delegation used vague instructions ("Research the semiconductor shortage"). Two subagents duplicated work; one missed a key angle. The fix was to make every delegation message include four components:

```
1. Clear objective:        "Find all S&P 500 IT board members appointed after 2023"
2. Expected output format: "Return a JSON array: [{name, company, appointment_date}]"
3. Tools/sources to use:   "Use web search; prefer SEC filings and official company pages"
4. Explicit task boundary: "Cover companies A–M only; do not research N–Z"
```

**Scaling heuristics** (embedded in orchestrator system prompt):

| Query complexity | Subagent count | Tool calls per agent |
|-----------------|---------------|---------------------|
| Simple fact-finding | 1 | 3–10 |
| Direct comparisons | 2–4 | 10–15 each |
| Complex research | 10+ | 15–25 each |

**Memory persistence pattern**: When context exceeds 200K tokens, the lead agent saves its plan to persistent memory before truncation happens. Workers operate with clean context windows.

---

### 4. VS Code Copilot Subagent Architecture — Practical Context Isolation

VS Code Copilot's subagent model (v1.109+) provides the most directly applicable patterns for markdown-based `.agent.md` files.

**Core flow**:

1. Main agent identifies a subtask that benefits from isolated context.
2. Main agent invokes `runSubagent` with only the focused subtask prompt.
3. Subagent works autonomously in a **clean context window**.
4. Main agent receives only the **final summary**, not the subagent's intermediate work.

**Frontmatter properties that control delegation efficiency**:

| Property | Effect on context/efficiency |
|----------|------------------------------|
| `user-invocable: false` | Hides from picker; makes agent subagent-only — description need only serve orchestrators, not humans |
| `disable-model-invocation: true` | Prevents AI-initiated invocation; agent is user-explicit only |
| `agents: ['A', 'B']` | Restricts which subagents coordinator can invoke — prevents accidental generic fallback |
| `model: [...]` | Pins a cost tier; subagent cannot use more expensive model than parent |
| `argument-hint: ...` | Single-sentence capability hint that appears in the orchestrator's routing view |

**Coordinator-worker pattern** (VS Code canonical example):

The coordinator's body contains only the workflow choreography — it does not contain the worker's behavioral rules. Workers are separate agents with `user-invocable: false` and minimal, focused bodies.

```yaml
# Coordinator — only needs workflow logic
---
name: Feature Builder
agents: ['Planner', 'Implementer', 'Reviewer']
tools: ['agent', 'edit', 'search', 'read']
---
For each feature request:
1. Use Planner to break into tasks.
2. Use Implementer to write code.
3. Use Reviewer to check. Iterate until convergence.
```

```yaml
# Worker — only needs its narrow task behavior
---
name: Planner
user-invocable: false
tools: ['read', 'search']
---
Break feature requests into implementation tasks.
```

**Nested subagents**: Max depth 5. Disabled by default. Enable only when divide-and-conquer patterns are explicitly needed.

**Model selection for cost efficiency**: Light models (`Claude Haiku 4.5`, `Gemini 3 Flash`) are appropriate for workers with narrow focus. The coordinator uses the flagship model only for orchestration decisions, not for routine subtask execution.

---

### 5. OpenAI — Routines and Handoffs (Swarm / Agents SDK)

OpenAI's Swarm (2024, educational) and Agents SDK (March 2025, production) established two primitives:

- **Routine**: a system prompt + toolset defining one agent's behavior scope
- **Handoff**: a function call that transfers the conversation to a different agent

**Key efficiency pattern**: Each agent's system prompt is scoped narrowly to its task domain. When an agent's scope ends, it calls a `transfer_to_X()` function which is the only mechanism for cross-agent communication. The receiving agent starts with the accumulated messages — not the sending agent's system prompt.

**Tool description as context compression**: OpenAI's canonical example shows that the function docstring *is* the tool description that appears in the model's context at every invocation. Short, precise docstrings reduce per-call overhead:

```python
def look_up_item(search_query):
    """Use to find item ID.
    Search query can be a description or keywords."""
    ...
```

---

### 6. Prompt Compression — Techniques Applicable to Agent Context

The "lost in the middle" effect (Liu et al. 2023) demonstrates that LLMs access information well at the start and end of a prompt, with substantial degradation in the middle. This has direct implications for delegation messages.

**Quantified impact**:

| Technique | Compression ratio | Quality effect |
|-----------|------------------|----------------|
| LLMLingua (MS Research, EMNLP 2023) | Up to 20× | −1.5 pts at 20× |
| LLMLingua-2 (ACL 2024) | 3–6× faster than v1 | Higher precision via bidirectional context |
| LongLLMLingua | 4× fewer tokens | **+21.4%** accuracy (relevance reordering) |
| Selective Context | 2× | −minimal |
| Verbatim compaction (Morph) | ~3–5× | 0% hallucination risk |

**Critical asymmetry**: Natural language compresses well (grammar is redundant). Code does not — exact paths, line numbers, and identifiers are high-information even when perplexity-predicted as "low entropy". Use verbatim semantic-unit extraction for code contexts; use perplexity-based pruning only for prose.

**Context rot**: As agentic sessions accumulate tool outputs, earlier investigation steps become noise. Claude Code auto-compacts at 95% capacity. Codex compacts after every turn. The practical implication: agent delegation messages should contain only current-task-relevant context, not the full conversation history.

**Relevance reordering** (LongLLMLingua principle, directly applicable): Place the most task-relevant information at the beginning of a delegation message. This exploits the U-shaped attention curve rather than fighting it.

---

### 7. Microsoft Multi-Agent Reference Architecture — Classifier Cascade

Microsoft's reference architecture (Semantic Kernel, updated August 2025) introduces a classifier cascade for intent routing that reduces expensive flagship model calls:

```
NLU (rule/regex) → SLM (small model) → LLM (flagship)
                                             ↑ only if uncertain
```

This pattern has direct applicability to routing manifests: simple intent matches should be dispatched without involving the orchestrator LLM at all.

**Agent registry** pattern: Maintain a central catalogue of agent capabilities (analogous to A2A Agent Cards). Agents register on startup; orchestrators query the registry for capability matching rather than enumerating all available agents in the system prompt.

**Recommendation**: Avoid registering highly similar agents. Overlapping capability descriptions degrade the classifier's routing precision.

---

### 8. Agent Description vs Agent Instructions — The Two-Surface Model

Every agent in a delegation-capable system has two distinct text surfaces:

| Surface | Reader | Size target | Content |
|---------|--------|------------|---------|
| **Agent description** (Card/frontmatter `description` + `argument-hint`) | Orchestrator, at routing time | 50–150 tokens | What the agent does; when to invoke it; expected input/output shape |
| **Agent instructions** (system prompt / `.agent.md` body) | The agent itself, at execution time | 500–5000 tokens | Behavioral rules, workflow steps, tool guidance, constraints, personas |

**Critical mistake to avoid**: Including agent instructions in the description surface. If the orchestrator loads the full agent body to decide whether to delegate, delegation decisions consume 5–50× more tokens than necessary.

**VS Code `.agent.md` model**: The `description` frontmatter field + `argument-hint` are the orchestrator-visible surface. The body text is agent-visible only. These are already separate — but this separation must be deliberately maintained. A bloated `description` degrades routing efficiency for every downstream orchestrator invocation.

**A2A Agent Card skills** are the precise equivalent: each skill has a concise `description` (1–2 sentences) and optional `examples` (1–3 input samples). The agent's full behavior is never exposed to the client agent.

---

## Top 5 Actionable Techniques (Ranked by Impact/Effort Ratio)

### Rank 1 — Structured Delegation Contracts (Impact: ★★★★★ | Effort: ★)

**Source**: Anthropic Research system; VS Code subagent docs

**Technique**: Every subagent invocation must include four fields — objective, output format, tools/sources, and task boundary. No freeform delegation.

**Applicable in markdown agents**: Add a delegation template to the coordinator's instructions:

```markdown
## Delegation template
When invoking a subagent, always include:
1. **Objective**: One sentence stating the specific goal
2. **Output format**: Exact schema or structure expected back
3. **Tools/sources**: Which tools to prefer; which to avoid
4. **Boundary**: What is explicitly out of scope for this subtask
```

**Expected gain**: Eliminates duplicated work between parallel subagents; 40% task completion time reduction in Anthropic's production system.

---

### Rank 2 — Separate Description from Instructions (Impact: ★★★★★ | Effort: ★)

**Source**: A2A Agent Card model; VS Code `argument-hint` field

**Technique**: Keep `description` in `.agent.md` frontmatter to ≤ 3 sentences / ≤ 150 tokens. Move all behavioral detail into the body. Use `argument-hint` for the single-sentence routing hint.

**Applicable in markdown agents**:

```yaml
---
description: Online and offline research — fetch documentation and produce structured output
argument-hint: Describe what to research — e.g. "research MCP server patterns"
---
# Full behavioral instructions follow in the body (not visible to orchestrators)
```

**Why it matters**: The orchestrator loads the description for every routing decision. A 500-token description vs a 50-token description is 10× more routing overhead per agent invocation at zero behavioral benefit.

---

### Rank 3 — Context-Isolated Workers with Lightweight Models (Impact: ★★★★ | Effort: ★★)

**Source**: VS Code subagent docs; Anthropic orchestrator-worker pattern

**Technique**: Subagent-only workers (`user-invocable: false`) with a lighter model (`Claude Haiku 4.5` or `Gemini 3 Flash`) for narrow, well-defined tasks. The worker's context window starts fresh; the coordinator receives only the worker's summary.

**Model assignment heuristic** (from Anthropic's routing guidance):

| Task type | Model |
|-----------|-------|
| Simple fact retrieval, formatting | Light (Haiku, Flash) |
| Code generation, comparison, analysis | Standard (Sonnet) |
| Orchestration, planning, complex reasoning | Flagship (Opus, Gemini Pro) |

**Expected gain**: 3–10× cost reduction per subagent call when routing appropriately.

---

### Rank 4 — Relevance Reordering in Delegation Messages (Impact: ★★★★ | Effort: ★)

**Source**: LongLLMLingua (Microsoft Research); "lost in the middle" effect (Liu et al. 2023)

**Technique**: Structure delegation messages with the most important context **first**, supporting context **last**, and avoid placing critical information in the middle of long messages.

**Template**:

```
[TASK: one sentence]
[KEY FACTS: the 3-5 most critical facts for this task]
[CONSTRAINTS: what not to do]
[SUPPORTING CONTEXT: background, if any]
```

**Applicable in markdown agents**: Add a "message structure" section to coordinator instructions specifying this ordering. No external tool needed.

**Expected gain**: LongLLMLingua achieved +21.4% accuracy on NaturalQuestions at 4× fewer tokens using this principle alone.

---

### Rank 5 — Scaling Heuristics in Orchestrator Prompt (Impact: ★★★ | Effort: ★)

**Source**: Anthropic Research system

**Technique**: Embed explicit effort-to-complexity matching rules in the orchestrator's system prompt. Without these, agents systematically over-invest in simple tasks and under-invest in complex ones.

**Template for orchestrator instructions**:

```markdown
## Effort scaling
- Simple lookups: 1 subagent, 3–10 tool calls
- Comparative analysis: 2–4 subagents, 10–15 calls each  
- Complex multi-domain research: 5–10+ subagents, 15–25 calls each
Terminate as soon as the task objective is satisfied. Do not continue for completeness.
```

**Expected gain**: Eliminates systematic over-investment; prevents runaway token usage on simple queries.

---

## Schema/Format Recommendations for Agent Delegation Messages

### Minimal delegation message schema

```json
{
  "objective": "string (1 sentence, verb + object + success criterion)",
  "output": {
    "format": "json | markdown | text",
    "schema": "{ ... } or description"
  },
  "tools": {
    "prefer": ["tool_a", "tool_b"],
    "avoid": ["tool_c"]
  },
  "boundary": "string (explicit out-of-scope statement)",
  "context": "string (optional, only task-relevant facts, relevance-ordered)"
}
```

### Minimal Agent Card / description surface

For markdown-based agents, the orchestrator-visible surface should be:

```yaml
---
name: [Agent Name]
description: [What it does]. [When to use it]. [What it returns].
argument-hint: [Single-sentence example invocation pattern]
user-invocable: [true|false]
---
```

The body (agent instructions) should NOT repeat the description. It should start with the agent's behavioral rules, tools guidance, and constraints.

---

## Techniques Applicable to Markdown-Based Agent Definition Files

| Technique | Where to apply in `.agent.md` | Implementation |
|-----------|------------------------------|----------------|
| Lean description surface | `description:` frontmatter | Cap at 3 sentences; remove behavioral details |
| Routing hint separation | `argument-hint:` frontmatter | One example invocation pattern, not a summary |
| Worker isolation | `user-invocable: false` | Prevents description from needing to serve human readers |
| Subagent allow-list | `agents: [...]` | Prevents fallback to generic agents; reduces ambiguous routing |
| Model tier assignment | `model: [...]` | Route narrow workers to light models |
| Delegation template | Body: `## Delegation` section | Standard 4-field template for every outbound subtask |
| Scaling heuristics | Body: `## Effort scaling` section | Complexity-to-subagent-count table |
| Output contract | Body: `## Output format` section | Schema the calling orchestrator can parse deterministically |

---

## Gaps / Further Research Needed

1. **Quantified compression ratios for markdown agent bodies**: No published data on optimal body length vs. routing accuracy in VS Code Copilot specifically. Empirical testing in this repo would be valuable.

2. **A2A adoption in VS Code Copilot**: VS Code's subagent model is structurally compatible with A2A Agent Cards, but there is no published integration path. Monitor VS Code release notes for A2A SDK integration.

3. **Structured output parsing from subagents**: VS Code subagent results return as plain text summaries. Semantic Kernel supports typed structured outputs from agents; this capability is not yet available in VS Code Copilot subagents as of May 2026.

4. **Cross-session agent memory for subagents**: VS Code's memory tool works within a session. Persistent cross-session capability declaration (analogous to A2A Agent Cards hosted at well-known URIs) is not yet standardised for local markdown agents.

5. **Compression benchmarks on agent instruction files**: LLMLingua benchmarks are on QA/NLP tasks. Code agent instruction files (tool documentation, workflow steps, behavioral rules) have different information density profiles. No published benchmarks exist for this specific use case.
