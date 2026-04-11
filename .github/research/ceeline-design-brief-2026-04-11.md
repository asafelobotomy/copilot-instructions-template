# Design Brief: Ceeline for Copilot Internal Communication

> Date: 2026-04-11 | Author: Copilot | Status: draft

## Summary

Ceeline is a proposed internal shorthand and transport layer for GitHub Copilot
customizations. Its purpose is to reduce token use on internal-only surfaces
without changing user-facing communication or human-authored instruction source
files.

Ceeline should not replace normal English in prompts, instructions, or user
chat. It should compress only surfaces that this repository owns end-to-end,
such as internal memory, heartbeat digests, MCP outputs, and subagent handoff
payloads.

The best architecture is not MCP alone. The best architecture is a small
translation core first, with an optional MCP wrapper, optional hook helpers,
and strict no-leak rules. When Ceeline needs to mediate between the user and
the model, the control plane should be an extension-owned chat surface rather
than MCP alone.

---

## Define the Problem

This repository carries a growing set of internal communication surfaces:

- Agent handoff prompts in [../agents](../agents)
- Heartbeat and reflection output in [../hooks/scripts/mcp-heartbeat-server.py](../hooks/scripts/mcp-heartbeat-server.py)
- Routing and digest text in [../hooks/scripts/pulse_runtime.py](../hooks/scripts/pulse_runtime.py)
- Workspace memory in [../../.copilot/workspace/knowledge/MEMORY.md](../../.copilot/workspace/knowledge/MEMORY.md)
- Workspace research notes in [../../.copilot/workspace/knowledge/RESEARCH.md](../../.copilot/workspace/knowledge/RESEARCH.md)

These surfaces consume tokens repeatedly. Many of them are machine-consumed or
agent-consumed. Most do not need polished prose.

At the same time, this repository also contains contract-heavy and
CI-sensitive files:

- [../copilot-instructions.md](../copilot-instructions.md)
- [../../template/copilot-instructions.md](../../template/copilot-instructions.md)
- [../../SETUP.md](../../SETUP.md)
- [../../UPDATE.md](../../UPDATE.md)
- [../../MIGRATION.md](../../MIGRATION.md)

These files must remain human-readable, stable, and structurally safe.

The design problem is therefore selective, not universal:

1. Reduce tokens where the repo controls the internal wire.
2. Preserve normal English where humans or CI contracts depend on it.
3. Avoid internal shorthand leaking into user-visible output.

---

## Set Goals

Ceeline should:

- Reduce token use on internal-only surfaces.
- Preserve exact technical tokens such as file paths, commands, tool names,
  env vars, versions, placeholders, and policy keys.
- Support deterministic encode and decode for high-risk flows.
- Fit the current VS Code and Copilot customization model.
- Work with hooks, MCP, agents, skills, and subagents.
- Be testable with golden fixtures and leak checks.

---

## Set Non-Goals

Ceeline should not:

- Change how Copilot talks to users by default.
- Rewrite all inbound and outbound chat turns transparently in stock VS Code.
- Replace normal English in source instruction files.
- Compress user-facing documentation.
- Require model fine-tuning.
- Depend on lossy LLM rewriting for contract-sensitive surfaces.

---

## Capture Research Findings

### Official platform constraints

The official MCP model exposes capabilities. It does not act as transparent
middleware for every chat turn.

- MCP servers provide tools, resources, prompts, apps, and optional sampling.
- MCP servers are called by the host when needed.
- MCP does not automatically sit between user prompt submission and agent
  prompt construction.
- MCP does not automatically rewrite the final assistant response before the
  user sees it.

The official VS Code hook model is useful, but limited.

- `SessionStart` and `SubagentStart` can inject context.
- `PreToolUse` can modify tool input and inject context.
- `PostToolUse` can add context or block further processing.
- `UserPromptSubmit` can observe the prompt, but does not provide a prompt
  rewrite contract.
- There is no general-purpose final-response rewrite hook.

Custom agents and subagents improve orchestration, but they do not own the
transport layer.

The official VS Code extension APIs introduce an important distinction.

- A custom chat participant can own the end-to-end prompt and response flow for
   that participant.
- A chat participant request handler receives the user's prompt directly.
- A participant can use the model chosen in chat via `request.model`.
- An extension can also select Copilot-accessible models directly through the
   Language Model API.
- A webview can provide a separate dedicated chat panel that the extension fully
   controls.
- These extension surfaces create a new front door. They do not transparently
   intercept the built-in Copilot chat pipeline.

### Community patterns

Two external patterns are relevant.

**caveman / caveman-compress**

- Strong for prose compression.
- Useful for internal notes and memory.
- Weak as a universal runtime layer for this repo.
- Risky on contract files and placeholder-rich templates.

**ClawTalk / ClosedClaw**

- Strong architectural pattern.
- Keep prompt-visible content in clean natural language.
- Compress only the internal wire.
- Add a translation device and an outbound sanitizer.
- Treat transport compression and user-visible output as separate concerns.

This second pattern maps well to this repository.

---

## Define Design Principles

Ceeline should follow these principles:

1. **Source stays readable**
   Human-authored source files stay in normal English unless the file is clearly
   internal and machine-oriented.

2. **Transport can be compact**
   Internal payloads may use compact envelopes, shorthands, or compiled forms.

3. **Deterministic first**
   Prefer rule-based transforms over LLM rewriting for high-risk surfaces.

4. **Compile, do not hand-author**
   Authors should write normal source. Tooling should derive Ceeline forms.

5. **No visible leaks**
   User-facing output must never show raw Ceeline artifacts.

6. **Typed where possible**
   Machine-consumed payloads should prefer schemas over prose.

7. **Preserve exact tokens**
   Paths, tool names, ids, placeholders, versions, and keys remain exact.

---

## Evaluate Architecture Options

| Option | Description | Feasibility | Main weakness |
|---|---|---:|---|
| MCP-only translator | Put all translation in an MCP server and call it everywhere | Medium for explicit use, low for global mediation | MCP is not universal chat middleware |
| Hook-only translator | Use hooks as the primary translation layer | Medium | Hooks do not own all inbound and outbound message paths |
| Core library + optional MCP | Build a Ceeline core first, then expose it through MCP and hook helpers | High | Requires disciplined integration work |
| Custom chat participant extension | Build an extension-owned chat participant that translates verbose input to Ceeline, uses Copilot models, and renders verbose output | High | It creates a new chat surface rather than patching the built-in Copilot participant |
| Dedicated webview chat extension | Build a separate Claude Code-style chat panel with full Ceeline mediation | Medium | More UI, state, and security work than a participant |
| Transparent built-in Copilot interceptor | Try to rewrite every turn of the built-in Copilot chat pipeline automatically | Low | Not supported by the official extension, hook, or MCP model |

The recommended path is two-layered: start with the third option for Ceeline
core infrastructure, then add the fourth option when true verbose-in and
verbose-out mediation is required.

---

## Recommend the Architecture

### Core idea

Build Ceeline as a translation core with three layers:

1. **Canonical source layer**
   Human-readable source content.

2. **Internal transport layer**
   Compact Ceeline payloads for machine-only and agent-only flows.

3. **Render layer**
   Clean English output for user-visible responses.

### Recommended components

#### 1. Ceeline core library

This is the real product. It should exist before any MCP server.

Core functions:

- `encode_verbose_to_ceeline(text, surface)`
- `decode_ceeline_to_verbose(text, surface)`
- `compress_memory(text)`
- `normalize_handoff(payload)`
- `render_user_facing(text)`
- `validate_roundtrip(input, output, preserve_set)`
- `detect_leak(text)`

The core should be deterministic for the first version.

#### 2. Ceeline MCP server

This is optional, but useful.

The MCP server should expose explicit capabilities such as:

- `translate_to_ceeline`
- `translate_from_ceeline`
- `compress_memory_note`
- `validate_ceeline_payload`
- `render_verbose_summary`

This server is useful when an agent or hook wants translation on demand. It is
not a transparent chat proxy.

#### 3. Ceeline hook helpers

Hooks can call the Ceeline core or MCP server at repo-owned lifecycle points.

Good targets:

- session-start context injection
- heartbeat digest generation
- subagent-start context preparation
- stop-hook reflection rendering

Hooks should not attempt to become a universal final-response interceptor.

#### 4. Ceeline validators

Add deterministic safety checks:

- preserve-list validation
- no-leak validation
- roundtrip validation
- banned-surface validation

These checks should run in tests and CI.

#### 5. Optional lexicon store

Ceeline may later want a lexicon, abbreviation registry, or translation memory.

Use a database only if scale demands it. For v1, a checked-in JSON or YAML file
is enough.

#### 6. Optional Ceeline extension front-end

This is the right control plane if Ceeline needs to sit between the user and
the model.

Two shapes are viable.

**Preferred: custom chat participant**

- register a Ceeline participant through the Chat Participant API
- accept verbose user input
- translate verbose input to Ceeline before prompt composition
- use `request.model` or the Language Model API to access Copilot models
- orchestrate tools and internal context in Ceeline-friendly form
- render verbose output back to the user

**Alternative: dedicated webview chat**

- create a separate panel with a custom chat UI
- keep all Ceeline artifacts private to the extension layer
- use message passing between the webview and the extension host
- call the Ceeline core and the Language Model API from extension code

The participant path is better for first adoption because it stays inside the
native VS Code chat experience.

---

## Explain Why MCP Is Not the Whole Answer

MCP is useful for Ceeline, but it is not the transport owner.

MCP works best here as:

- a callable translator
- a validator
- a compressor for internal notes
- an on-demand summarizer for subagent payloads

MCP does not give this repo a guarantee that every user prompt and every final
assistant reply will flow through Ceeline automatically.

That means the following model is not fully achievable in stock Copilot today:

```text
Verbose user chat -> automatic MCP translation -> Ceeline agent loop -> automatic MCP decode -> verbose user reply
```

The following model is achievable:

```text
Verbose source -> Ceeline core encode -> internal payload -> agent/tool/subagent work -> Ceeline core decode -> clean user-facing result
```

The difference is control. The repo controls the second path. It does not fully
control the first one.

---

## Explain Why an Extension Is the Right Middleman

An extension is the correct middleman when the goal is:

```text
Verbose user view -> Ceeline internal transport -> verbose user view
```

This is feasible because a VS Code extension can own a complete user-facing chat
surface.

### What an extension can do

- receive user input directly through a chat participant request handler
- compose the model prompt itself
- translate the user's input before the model sees it
- call Copilot-accessible models through `request.model` or
   `vscode.lm.selectChatModels(...)`
- stream the response back to the user after decoding or sanitizing it
- present a custom UI through a webview if needed

### What an extension cannot do

- transparently patch the built-in Copilot participant pipeline
- guarantee that built-in `@workspace` or other built-in participants route
   through Ceeline
- use MCP alone to become a hidden universal message interceptor

### Practical implication

If Ceeline should mediate the full conversation, then Ceeline must become the
front door. The user interacts with a Ceeline-owned participant or panel. The
built-in Copilot experience remains separate.

---

## Explain Why a Database Is Optional

A database is support infrastructure, not the translation mechanism.

A database could store:

- abbreviation tables
- phrase tables
- translation memory
- telemetry and compression metrics
- content hashes and provenance

It cannot, by itself, intercept or transform traffic.

For v1, prefer a simple checked-in data file. Move to SQLite only if one of
these becomes true:

- the lexicon becomes large and query-heavy
- per-project and per-user overlays are needed
- telemetry grows beyond simple file storage

---

## Define Ceeline Surface Classes

### Safe pilot surfaces

These are strong first targets.

- Heartbeat and reflection text in [../hooks/scripts/mcp-heartbeat-server.py](../hooks/scripts/mcp-heartbeat-server.py)
- Routing and digest text in [../hooks/scripts/pulse_runtime.py](../hooks/scripts/pulse_runtime.py)
- Policy message values in [../hooks/scripts/heartbeat-policy.json](../hooks/scripts/heartbeat-policy.json)
- Workspace memory in [../../.copilot/workspace/knowledge/MEMORY.md](../../.copilot/workspace/knowledge/MEMORY.md)
- Workspace research notes in [../../.copilot/workspace/knowledge/RESEARCH.md](../../.copilot/workspace/knowledge/RESEARCH.md)
- Generated subagent handoff payloads derived from agent source files in
  [../agents](../agents)

### Safe future extension surfaces

If a Ceeline extension is built, these become viable controlled surfaces:

- participant-local chat history
- extension-composed model prompts
- extension-owned tool summaries
- extension-owned subagent envelopes
- webview session state and translation telemetry

### Later candidate surfaces

- Internal skill summaries
- Planner-to-implementer summaries
- Review synthesis payloads
- Research result condensation before parent-agent injection

### Unsafe surfaces

Do not compress these with Ceeline v1.

- [../copilot-instructions.md](../copilot-instructions.md)
- [../../template/copilot-instructions.md](../../template/copilot-instructions.md)
- [../../SETUP.md](../../SETUP.md)
- [../../UPDATE.md](../../UPDATE.md)
- [../../MIGRATION.md](../../MIGRATION.md)
- mirrored template and `.github` source files unless updated atomically
- any source file with `{{PLACEHOLDER}}` tokens or CI-enforced section contracts

---

## Propose the Ceeline Forms

Ceeline should not be one single syntax. It should be a family of related
compact forms.

### 1. Ceeline Envelope

Use this for machine-consumed payloads.

Example:

```json
{
  "surface": "handoff",
  "intent": "review.security",
  "scope": ["hooks", "heartbeat"],
  "constraints": ["read-only", "no-user-visible-change"],
  "facts": [
    "heartbeat emits compact summaries",
    "template parity must hold"
  ],
  "ask": "return findings only",
  "output": "severity-ordered list"
}
```

This form is easy to validate and easy to test.

### 2. Ceeline Text

Use this for compact human-readable internal notes.

Style rules:

- Drop filler.
- Keep one idea per clause.
- Preserve exact tokens.
- Prefer labels over prose.

Example:

```text
surf=heartbeat ; mag=medium ; files=6 ; active=24m ; ask=check scope,test,mem
```

### 3. Ceeline Memory

Use this for workspace memory and research summaries.

Pattern:

```text
fact: MCP exposes callable capabilities, not universal chat middleware.
use: explicit translation, validation, note compression.
avoid: assume automatic full-turn interception.
```

---

## Define Preserve Rules

Ceeline must preserve these classes exactly:

- file paths
- tool identifiers
- agent names
- model names
- commands
- environment variables
- version numbers
- JSON keys when used in envelopes
- `{{PLACEHOLDER}}` tokens
- section labels such as `§1`, `D1`, `S1`
- URLs
- code fences and inline code

If a transform changes any preserved token, validation must fail.

---

## Define Leak Prevention Rules

Ceeline must never leak into user-visible output.

Leak classes include:

- raw Ceeline envelopes
- shorthand sigils and abbreviations not intended for users
- internal routing metadata
- internal-only policy markers

The render layer should include a sanitizer. The sanitizer should run before any
final user-facing output is accepted.

---

## Plan Validation

Validation should be simple and deterministic.

### Unit tests

- preserve-list tests
- roundtrip tests
- leak-detection tests
- bad-surface rejection tests

### Fixture tests

Use golden inputs for:

- heartbeat digests
- reflection prompts
- planner handoffs
- memory notes

### Contract tests

- no user-visible Ceeline artifacts
- no changes to preserved tokens
- no parity breakage on mirrored files

### Metrics

Track:

- token reduction percentage
- encode and decode latency
- roundtrip pass rate
- leak count
- fallback rate to verbose English

---

## Define a Rollout Plan

### Phase 0: Write the spec

- define Ceeline forms
- define preserve rules
- define leak rules
- define safe and unsafe surfaces

### Phase 1: Build the core

- implement deterministic encode and decode helpers
- add golden fixtures
- add preserve validation

### Phase 2: Pilot on heartbeat

- generate Ceeline-aware internal digests in
  [../hooks/scripts/pulse_runtime.py](../hooks/scripts/pulse_runtime.py)
- render clean English in user-visible places
- validate zero leaks

### Phase 3: Pilot on memory

- compress internal note formats in
  [../../.copilot/workspace/knowledge/MEMORY.md](../../.copilot/workspace/knowledge/MEMORY.md)
  and related internal notes

### Phase 4: Add optional MCP wrapper

- expose translation and validation as callable tools
- keep it opt-in and explicit

### Phase 5: Pilot on subagent handoffs

- derive compact envelopes from agent handoff intents
- keep source `.agent.md` files readable

### Phase 6: Prototype a custom chat participant

- build a minimal Ceeline participant
- translate verbose input to Ceeline internally
- use the selected Copilot model through `request.model`
- render verbose output back to the user

### Phase 7: Evaluate whether a dedicated webview is worth it

- only if a separate Claude Code-style panel is materially better than a native
   participant

---

## State the Recommendation

Build Ceeline as a translation core first.

Do not start with an MCP-only design. Do not start with a database. Do not
start by rewriting core instruction files.

The correct order is:

1. spec
2. deterministic core
3. tests and leak checks
4. pilot on heartbeat and memory
5. optional MCP wrapper
6. custom chat participant if verbose-in and verbose-out mediation is required
7. only later evaluate a dedicated webview chat panel

This path matches the platform limits, the repo's invariants, and the strongest
lesson from ClawTalk: keep the internal wire compact, and keep prompt-visible
and user-visible content clean.

---

## List Open Questions

1. Should Ceeline standardize on a typed JSON envelope first, with text
   shorthand only as a render format?
2. Should heartbeat and reflection use the same Ceeline form, or separate ones?
3. Should the first lexicon live in JSON, YAML, or code constants?
4. Should the optional MCP server use deterministic translation only, or also
   support sampling-based compression experiments?
5. Should Ceeline outputs be stored directly, or generated on demand from
   canonical verbose source?
6. Should the first extension surface be a native chat participant, or is a
   dedicated webview worth the extra complexity?
7. How much of the built-in tool-calling flow should be reimplemented inside the
   extension, versus delegated to existing participant utilities?

---

## Sources

| Source | Relevance |
|---|---|
| <https://modelcontextprotocol.io/docs/learn/architecture> | Official MCP architecture and capability model |
| <https://modelcontextprotocol.io/specification> | Official MCP specification and trust model |
| <https://code.visualstudio.com/docs/copilot/customization/mcp-servers> | VS Code MCP behavior, capabilities, and limits |
| <https://code.visualstudio.com/docs/copilot/customization/hooks> | Hook lifecycle and supported influence points |
| <https://code.visualstudio.com/api/extension-guides/chat> | Chat Participant API for extension-owned end-to-end chat flows |
| <https://code.visualstudio.com/api/extension-guides/language-model> | Language Model API for Copilot-accessible model requests from extensions |
| <https://code.visualstudio.com/api/extension-guides/webview> | Webview API for a dedicated separate chat panel |
| <https://code.visualstudio.com/docs/copilot/customization/custom-agents> | Custom agent behavior and limits |
| <https://code.visualstudio.com/docs/copilot/agents/subagents> | Subagent orchestration patterns |
| <https://code.visualstudio.com/docs/copilot/customization/agent-plugins> | Plugin packaging model for hooks, MCP servers, and agents |
| <https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions> | GitHub Copilot repository instruction behavior |
| <https://github.com/JuliusBrussee/caveman> | Community pattern for prose compression |
| <https://github.com/asafelobotomy/ClosedClaw> | Community pattern for internal transport architecture |
| <https://github.com/asafelobotomy/ClosedClaw/commit/63bb200b316c29d3428fbfc37151730e2587f8f4> | ClawTalk Translation Device direction and design rationale |