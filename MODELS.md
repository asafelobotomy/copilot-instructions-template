# Model Registry

Single source of truth for all agent model assignments in this repository.

Current external review date: 2026-04-26. GitHub designates GPT-5.3-Codex as
the Copilot base + LTS model. GPT-5.1 was retired April 15, 2026; GPT-5.2 is
the current GA non-Codex general-purpose model. GPT-5.4 mini (0.33×) covers
agentic grep/exploration tasks; Grok Code Fast 1 (0.25×) is code-specialized
at low cost; Raptor mini (0×, preview) is a fine-tuned GPT-5 mini for fast
coding suggestions. Models at 7.5× promotional rates (Claude Opus 4.7, GPT-5.5)
are excluded from this registry to avoid cost instability. GitHub's
supported-models docs note that Claude Sonnet 4.6 and GPT-5.4 mini multipliers
are subject to change.

`llms.txt` includes a machine-readable repo catalog and mirrors the
primary-model and thinking-effort summary for quick navigation.
Edit this file to change assignments; `sync-models.sh` propagates only the
primary-model and thinking-effort summary table within `llms.txt`
automatically.

Runtime note: repo-controlled usage excludes `GPT-5 mini` because VS Code
currently rejects deferred-tool loading on that model with
`Tool 'tool_search' is not supported with gpt-5-mini-2025-08-07`, and this
repo relies on deferred-tool flows in both agent lineups and workspace tool
sampling.

The `model:` list in each `.agent.md` file is ordered: VS Code Copilot picks the
first available model and falls back down the list. Edit this file to change any
assignment, then propagate with:

```bash
bash scripts/sync/sync-models.sh --write
```

Verify sync (run automatically by CI):

```bash
bash scripts/sync/sync-models.sh --check
```

---

## Thinking Effort Guide

VS Code exposes a **Thinking Effort** setting per reasoning-capable model (Low /
Medium / High). This controls the native extended thinking budget — how many
reasoning tokens the model allocates before responding. Higher effort means deeper
analysis but more latency and token cost. The setting is adaptive: models can
stop thinking early for simple prompts even at High.

Recommended effort levels per agent:

| Agent | Effort | Rationale |
|-------|--------|-----------|
| coding | High | Complex multi-step implementation needs full reasoning depth |
| organise | Medium | Structural moves and path repair need planning, but not the full depth of architectural review |
| cleaner | Medium | Hygiene cleanup needs cautious classification and approval gating without the full depth of implementation work |
| audit | High | Health checks + vulnerability analysis require thorough reasoning |
| fast | Low | Speed is the goal; minimal thinking overhead |
| review | High | Deep architectural analysis requires maximum reasoning |
| setup | Medium | Structured interview + mechanical diff-and-merge; adaptive reasoning sufficient |
| explore | Low | Read-only lookup; speed over depth |
| extensions | Medium | Evaluation involves trade-offs but not deep reasoning |
| researcher | High | Research synthesis benefits from deep analytical thinking |
| commit | Low | Commit operations are low-context; fast responses preferred |
| planner | High | Read-only planning and task decomposition benefit from deep reasoning before implementation |
| docs | Medium | Documentation synthesis needs accuracy and structure without the full cost of architectural review |
| debugger | High | Root-cause analysis and regression triage need disciplined narrowing and deep reasoning |

> **User override**: these are recommendations. Users set thinking effort per model
> in the VS Code model picker (click `>` next to the model name). The setting
> persists across conversations for each model. There is no per-agent override in
> `.agent.md` frontmatter as of VS Code 1.114.

---

## coding

Implementation, refactoring, and multi-step coding tasks. GPT-5.3-Codex is the
primary because GitHub treats it as the Copilot base + LTS model for agentic
software development; GPT-5.2-Codex is the like-for-like Codex fallback;
Grok Code Fast 1 is the code-specialized cost-efficient fallback (0.25×).

- GPT-5.3-Codex
- GPT-5.2-Codex
- GPT-5.2
- Grok Code Fast 1
- Claude Sonnet 4.6

## organise

Structural cleanup, directory reorganisation, file moves, and path repair.

GPT-5.3-Codex is primary because this role is explicitly agentic and benefits
from the Copilot base + LTS coding model.

- GPT-5.3-Codex
- GPT-5.2-Codex
- Claude Sonnet 4.6

## cleaner

Repository hygiene, stale artefact removal, cache and archive pruning, and
dead-file cleanup. GPT-5.3-Codex is primary because the role is agentic,
approval-gated, and benefits from strong file reasoning without taking on the
full breadth of general implementation.

- GPT-5.3-Codex
- GPT-5.2-Codex
- Claude Sonnet 4.6

## audit

Read-only health check and security audit — structural validation, upstream
comparison, OWASP Top 10, secrets, injection patterns, supply chain, shell
hardening. GPT-5.4 for deep analytical capability; Claude Sonnet 4.6 as the
Anthopic reasoning fallback; Gemini 3.1 Pro for long-context cross-file analysis.

- GPT-5.4
- Claude Sonnet 4.6
- Gemini 3.1 Pro
- GPT-5.2

## fast

Quick questions, syntax lookups, and lightweight single-file edits. Haiku 4.5
is the quality-speed sweet spot (0.33×); GPT-5.4 mini (0.33×) handles
tool-heavy lightweight tasks; Grok Code Fast 1 (0.25×) for code-specific
queries; Raptor mini is the free alternative.

- Claude Haiku 4.5
- GPT-5.4 mini
- Grok Code Fast 1
- Raptor mini
- GPT-4.1

## review

Deep code review and architectural analysis with Lean/Kaizen critique.
GPT-5.4 is the primary for Xhigh reasoning; Claude Sonnet 4.6 is the Anthropic
fallback; Gemini 3.1 Pro provides advanced reasoning across long contexts.

- GPT-5.4
- Claude Sonnet 4.6
- Gemini 3.1 Pro
- GPT-5.2

## setup

Template lifecycle — first-time setup, upstream updates, backup restore, and factory restore.
Requires interactive question capability (never use Codex/autonomous models).

- Claude Sonnet 4.6
- GPT-5.4 mini
- GPT-5.2

## explore

Fast read-only codebase exploration and Q&A. Uses lightweight models for speed;
GPT-5.4 mini is the grep/tool-use specialist (0.33×); Grok Code Fast 1 is the
code-specialized fast fallback (0.25×); Raptor mini provides free inline-speed
for simple lookups.

- Claude Haiku 4.5
- GPT-5.4 mini
- Grok Code Fast 1
- Raptor mini
- Claude Sonnet 4.6

## extensions

VS Code extension management, profile isolation, and workspace configuration.

- Claude Sonnet 4.6
- Gemini 3.1 Pro
- GPT-5.2

## researcher

Online and offline research — fetch documentation, track URLs, and produce
structured research output. Claude Sonnet 4.6 is primary for synthesis quality;
Gemini 3.1 Pro provides stronger analytical reasoning across long contexts;
Gemini 2.5 Pro is the GA Gemini fallback.

- Claude Sonnet 4.6
- Claude Sonnet 4.5
- Gemini 3.1 Pro
- Gemini 2.5 Pro

## commit

Stage, commit, push, tag, and manage releases. Low-context operations; fast
models preferred. GPT-5.2 is primary because it avoids the repo-wide
deferred-tool incompatibility on GPT-5 mini while staying fit for low-context
git operations; Claude Sonnet 4.6 is the quality fallback.

- GPT-5.2
- Claude Sonnet 4.6

## planner

Read-only planning, scoping, and execution sequencing before implementation.
GPT-5.4 is primary for deep reasoning depth; Claude Sonnet 4.6 is the
Anthopic reasoning fallback; Gemini 3.1 Pro for multi-document analysis.

- GPT-5.4
- Claude Sonnet 4.6
- Gemini 3.1 Pro
- GPT-5.2

## docs

Documentation generation, migration notes, README work, and user-facing guides.

- Claude Sonnet 4.6
- GPT-5.2

## debugger

Root-cause analysis, error diagnosis, and regression triage. GPT-5.4 is
primary; Claude Sonnet 4.6 as the Anthropic fallback; Gemini 3.1 Pro for
ambiguous multi-file failures requiring long-context reasoning.

- GPT-5.4
- Claude Sonnet 4.6
- Gemini 3.1 Pro
- GPT-5.2
