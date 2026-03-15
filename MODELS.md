# Model Registry

Single source of truth for all agent model assignments in this repository.

The `model:` list in each `.agent.md` file is ordered: VS Code Copilot picks the
first available model and falls back down the list. Edit this file to change any
assignment, then propagate with:

```bash
bash scripts/sync-models.sh --write
```

Verify sync (run automatically by CI):

```bash
bash scripts/sync-models.sh --check
```

---

## coding

Implementation, refactoring, and multi-step coding tasks.

- GPT-5.1
- Claude Sonnet 4.6
- GPT-5 mini
- GPT-5.3-Codex
- GPT-5.2-Codex
- GPT-5.1-Codex

## doctor

Read-only health checks. Sonnet is accurate and 3× cheaper than Opus for
mechanical inspection tasks; Opus remains as a capability fallback.

- Claude Sonnet 4.6
- Claude Opus 4.6
- Claude Opus 4.5

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

First-time project setup and onboarding. Requires interactive question capability
(never use Codex/autonomous models for this agent).

- Claude Sonnet 4.6
- Claude Sonnet 4.5
- GPT-5.1
- GPT-5 mini

## update

Upstream instruction updates and restore-from-backup operations.

- Claude Sonnet 4.6
- Claude Sonnet 4.5
- GPT-5.1
