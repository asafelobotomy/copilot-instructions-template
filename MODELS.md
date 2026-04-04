# Model Registry

Single source of truth for all agent model assignments in this repository.

Current external review date: 2026-04-04. GitHub now designates GPT-5.3-Codex
as the Copilot base + LTS model. GitHub's supported-models docs also note that
Claude Sonnet 4.6 and GPT-5.4 mini multipliers are subject to change.

`llms.txt` mirrors only the primary-model and thinking-effort summary for quick
navigation. Edit this file to change assignments.

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
| audit | High | Health checks + vulnerability analysis require thorough reasoning |
| fast | Low | Speed is the goal; minimal thinking overhead |
| review | High | Deep architectural analysis requires maximum reasoning |
| setup | Medium | Structured interview + mechanical diff-and-merge; adaptive reasoning sufficient |
| explore | Low | Read-only lookup; speed over depth |
| extensions | Medium | Evaluation involves trade-offs but not deep reasoning |
| researcher | High | Research synthesis benefits from deep analytical thinking |
| commit | Low | Commit operations are low-context; fast responses preferred |

> **User override**: these are recommendations. Users set thinking effort per model
> in the VS Code model picker (click `>` next to the model name). The setting
> persists across conversations for each model. There is no per-agent override in
> `.agent.md` frontmatter as of VS Code 1.114.

---

## coding

Implementation, refactoring, and multi-step coding tasks. GPT-5.3-Codex is the
primary because GitHub now treats it as the Copilot base + LTS model for
agentic software development; GPT-5.2-Codex is the like-for-like fallback.

- GPT-5.3-Codex
- GPT-5.2-Codex
- GPT-5.1
- Claude Sonnet 4.6
- GPT-5 mini

## organise

Structural cleanup, directory reorganisation, file moves, and path repair.

- GPT-5.1
- Claude Sonnet 4.6
- GPT-5 mini

## audit

Read-only health check and security audit — structural validation, upstream
comparison, OWASP Top 10, secrets, injection patterns, supply chain, shell
hardening. GPT-5.4 for deep analytical capability; Opus as fallback.

- GPT-5.4
- Claude Opus 4.6
- Claude Sonnet 4.6
- GPT-5.1

## fast

Quick questions, syntax lookups, and lightweight single-file edits.

- Claude Haiku 4.5
- GPT-5 mini
- GPT-4.1

## review

Deep code review and architectural analysis with Lean/Kaizen critique.
GPT-5.4 is the primary; Claude Opus 4.6 provides Agent Teams capability.

- GPT-5.4
- Claude Opus 4.6
- Claude Sonnet 4.6
- GPT-5.1

## setup

Template lifecycle — first-time setup, upstream updates, backup restore, and factory restore.
Requires interactive question capability (never use Codex/autonomous models).

- Claude Sonnet 4.6
- Claude Sonnet 4.5
- GPT-5.1
- GPT-5 mini

## explore

Fast read-only codebase exploration and Q&A. Uses lightweight models for speed;
GPT-5.4 mini is the tool-using fallback for grep-heavy exploration, and Sonnet
is the capability fallback for complex queries.

- Claude Haiku 4.5
- GPT-5.4 mini
- GPT-5 mini
- Claude Sonnet 4.6

## extensions

VS Code extension management, profile isolation, and workspace configuration.

- Claude Sonnet 4.6
- Claude Opus 4.6
- GPT-5.1

## researcher

Online and offline research — fetch documentation, track URLs, and produce
structured research output.

- Claude Sonnet 4.6
- Claude Sonnet 4.5
- GPT-5 mini

## commit

Stage, commit, push, tag, and manage releases. Low-context operations; fast
models are preferred for commit message formatting.

- GPT-5.1
- Claude Sonnet 4.6
- GPT-5 mini
