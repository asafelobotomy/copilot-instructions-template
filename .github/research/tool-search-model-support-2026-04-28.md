# Research: tool_search / Deferred Tool Support by Model (GPT-5 mini, GPT-5.4 mini)

> Date: 2026-04-28 | Agent: Researcher | Status: final

## Summary

No official VS Code or GitHub Copilot documentation mentions `tool_search` as a named platform feature, nor documents any model-specific restriction on deferred tool loading. Both GPT-5 mini and GPT-5.4 mini are fully GA with `agent_mode: true`, meaning VS Code routes tool calls to them without restriction. The deferred tool pattern is an instruction-layer convention, not a platform API. The risk with lightweight models is behavioral reliability, not platform support. GPT-5.4 mini is the better choice for tool-heavy agents because official docs explicitly endorse it for agentic/grep-style tool use; GPT-5 mini has no corresponding endorsement and a well-documented "fast, lightweight" positioning that may reduce instruction-following fidelity on complex meta-tool flows.

## Sources

| URL | Relevance |
|-----|-----------|
| https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-release-status.yml | Canonical agent_mode/ask_mode/edit_mode flags per model — both GPT-5 mini and GPT-5.4 mini show all three as true |
| https://docs.github.com/en/copilot/reference/ai-models/model-comparison | Task-based model comparison — GPT-5.4 mini explicitly recommended for "Agentic software development / codebase exploration and grep-style tools"; GPT-5 mini positioned as general-purpose fast default |
| https://code.visualstudio.com/docs/copilot/customization/custom-agents | Custom agents frontmatter spec — model array, tools, agents fields; no mention of deferred tools or tool_search |
| https://code.visualstudio.com/docs/copilot/agents/agent-tools | Agent tools overview — built-in, MCP, and extension tools; no model-specific restrictions documented |
| https://code.visualstudio.com/api/extension-guides/ai/tools | Extension LM tools API — deferred/lazy loading mechanism exists at the extension-API level but no named `tool_search` surface documented |
| https://raw.githubusercontent.com/github/docs/main/data/tables/copilot/model-multipliers.yml | Multipliers: GPT-5 mini 0x (included free), GPT-5.4 mini 0.33x |
| https://code.visualstudio.com/updates/v1_114 | v1.114 (Apr 1 2026) — no tool_search mentions |
| https://code.visualstudio.com/updates/v1_115 | v1.115 (Apr 8 2026) — no tool_search mentions |
| https://code.visualstudio.com/updates/v1_116 | v1.116 (Apr 15 2026) — no tool_search mentions |
| https://code.visualstudio.com/updates/v1_117 | v1.117 (Apr 22 2026) — no tool_search mentions |

## Findings

### 1. `tool_search` is not a documented public VS Code/Copilot feature

Searches across the VS Code documentation (custom agents, agent tools, extension LM tools, release notes v1.114–v1.117), GitHub Copilot documentation (supported models, model comparison, billing), and the VS Code extension API returned zero mentions of `tool_search` as a named platform surface. The pattern exists at the instruction layer: VS Code Copilot Chat injects a list of "available deferred tools" into the system prompt and instructs the model to call `tool_search` before first use. This is not a documented public API, and no version-specific release notes describe it.

### 2. Both models are fully GA with agent_mode support

The canonical `model-release-status.yml` (fetched 2026-04-28) shows:

| Model | Provider | Release Status | agent_mode | ask_mode | edit_mode |
|-------|----------|---------------|-----------|---------|---------|
| GPT-5 mini | OpenAI | GA | ✓ | ✓ | ✓ |
| GPT-5.4 mini | OpenAI | GA | ✓ | ✓ | ✓ |

Neither model has any documented restriction on tool calling, tool quantity, or tool discovery.

### 3. Official task positioning differs significantly

From `model-comparison.yml` (and the rendered docs page):

- **GPT-5.4 mini** — task area: "Agentic software development". Primary use case: "Codebase exploration and is **especially effective when using grep-style tools**." This is the only lightweight model explicitly endorsed for tool-heavy agentic work.
- **GPT-5 mini** — task area: "General-purpose coding and writing" and "Deep reasoning and debugging". No tool-use endorsement. Positioned as "Fast, accurate, and works well across languages and frameworks" and "delivers deep reasoning and debugging with faster responses and lower resource usage than GPT-5."

### 4. No model-specific restrictions on extension tool calling

The VS Code extension LM tools API allows extensions to mark tools with a `when` clause but this is capability-gated on VS Code context (e.g., `debugState == 'running'`), not model family. There is no API surface that restricts which tool names a given model can be offered. VS Code presents the same tool list to all models when agent_mode is active.

### 5. The deferred tool concern is behavioral, not platform-level

The `tool_search` instruction is behavioral: the model must choose to call `tool_search` as a first step rather than skipping to calling the extension tool directly (which would fail silently). Lightweight models optimized for speed and low reasoning overhead are more likely to skip multi-step preamble instructions. This is not documented by Microsoft or GitHub — it is an operational inference based on model design positioning.

### 6. GPT-5 mini current usage in this repo

Based on `MODELS.md`, GPT-5 mini appears as:
- **Primary** in `commit` (low-complexity git lifecycle operations — no extension tools needed)
- **Last fallback** in `coding`, `organise`, `cleaner`, `setup`, `researcher`, `docs`

Agents that call `mcp_heartbeat_session_reflect` via `tool_search` are principally those using the main/default Researcher or Code agent (Claude Sonnet 4.6 is primary in both). GPT-5 mini only reaches these code paths as a last resort when all higher-capability models are unavailable.

### 7. GPT-5.4 mini and tool_search

GPT-5.4 mini appears as **second choice** (after Claude Haiku 4.5) in both `fast` and `explore` agents. These agents do not themselves call `mcp_heartbeat_session_reflect`, but the Researcher/Code agents that use `tool_search` extensively almost never reach GPT-5.4 mini. GPT-5.4 mini is well-positioned for the tool-heavy tasks where it appears.

## Gaps / Further research needed

- Microsoft/GitHub have not published any model-specific behavioral benchmarks for instruction-following on multi-step tool preambles. Empirical testing in this repo would be needed to determine whether GPT-5 mini reliably executes `tool_search` before calling deferred extension tools.
- The `tool_search` mechanism itself is undocumented in public VS Code docs as of v1.117 (2026-04-22). A future release may formalize it.

## Recommendations

### Should GPT-5 mini be removed from agent model lists?

**No broad removal is warranted** based on available documentation. The specific guidance is:

1. **Keep GPT-5 mini in `commit`** (primary) — commit operations do not invoke extension tools; the model is fit for purpose.
2. **Keep GPT-5 mini as last fallback** in agents where it currently occupies that position — it only runs if all higher-capability models are unavailable, and at that tier a degraded experience is acceptable.
3. **Do not promote GPT-5 mini** to a position where it is primary in any agent that routinely calls deferred extension tools (e.g., `mcp_heartbeat_session_reflect` via `tool_search`). No current agent does this.
4. **If empirical failures are observed** (model skips `tool_search` and calls extension tools directly resulting in silent failures), the targeted fix is to remove GPT-5 mini from the specific failing agent's fallback list, not a repo-wide sweep.

### Should GPT-5.4 mini be retained?

**Yes, unambiguously.** Official docs explicitly endorse it for tool-heavy agentic tasks. It is the correct lightweight choice for `fast` and `explore` agents where grep-style tool use is expected. It should not be touched.

### Summary table

| Model | Remove from agents? | Rationale |
|-------|--------------------|----|
| GPT-5 mini | No (targeted review only) | No documented platform restriction; only behavioral risk at fallback position; empirical failures would justify targeted removal |
| GPT-5.4 mini | No | Explicitly recommended for agentic/tool-heavy tasks; strongest lightweight fit |
