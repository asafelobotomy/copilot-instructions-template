# Agents Guide — Human Reference

> **Machine-readable version**: `AGENTS.md`
> This document explains the trigger phrase system and the model-pinned agent files.

---

## Two ways to use the template

### Option A — Trigger phrases (any editor or IDE)

In any Copilot chat, say one of the canonical trigger phrases. Copilot reads the template repo, executes the operation in your current project, and returns with a result. No setup needed.

| What you want | Say this |
|--------------|----------|
| First-time setup | *"Setup from asafelobotomy/copilot-instructions-template"* |
| Check for updates | *"Update your instructions"* |
| Force a full comparison | *"Force check instruction updates"* |
| Restore a backup | *"Restore instructions from backup"* |
| List available backups | *"List instruction backups"* |

There are also variations:

- *"Bootstrap this project from copilot-instructions-template"*
- *"Use the Lean/Kaizen Copilot template to set up this project"*
- *"Sync instructions with the template"*

---

### Option B — Model-pinned agents (VS Code 1.106+)

The template creates four agent files in `.github/agents/`. These appear in the Copilot agent dropdown in VS Code. When you select an agent, Copilot automatically switches to the pinned model for that session — no manual model selection needed.

| Agent | Model | Best for |
|-------|-------|----------|
| **Setup** | Claude Sonnet 4.6 | First-time setup, onboarding, template operations |
| **Code** | GPT-5.3-Codex | Implementation, refactoring, multi-step coding tasks |
| **Review** | Claude Opus 4.6 | Deep code review, architectural analysis, Lean/Kaizen critique |
| **Fast** | Claude Haiku 4.5 | Quick questions, syntax lookups, single-file lightweight edits |

Each agent has a fallback chain so it degrades gracefully if a model is unavailable on your plan.

---

## Model selection rationale

| Model | Reason chosen |
|-------|--------------|
| **Claude Sonnet 4.6** (Setup) | Strong instruction-following; handles the 3-tier preference interview (5–19 questions) and complex conditional logic in setup well |
| **GPT-5.3-Codex** (Code) | GitHub's latest agentic coding model (GA Feb 9 2026); ~25% faster than its predecessor; supports real-time mid-task steering. Stays in the Codex lineage for clean fallbacks |
| **Claude Opus 4.6** (Review) | Agent Teams capability — delegates sub-tasks to specialised virtual agents in parallel, making it ideal for systematic Lean/Kaizen architectural review. 3× multiplier cost; reserve for genuine deep reviews |
| **Claude Haiku 4.5** (Fast) | 0.33× cost multiplier; fastest response time. Right-sized for questions that don't warrant a premium model |

---

## Fallback chains

If a model is unavailable on your plan, the agent falls back in order:

| Agent | Fallback order |
|-------|---------------|
| Setup | Claude Sonnet 4.6 → Claude Sonnet 4.5 → GPT-5.1 → GPT-5 mini |
| Code | GPT-5.3-Codex → GPT-5.2-Codex → GPT-5.1-Codex → GPT-5.1 → GPT-5 mini |
| Review | Claude Opus 4.6 → Claude Opus 4.5 → Claude Sonnet 4.6 → GPT-5.1 |
| Fast | Claude Haiku 4.5 → Grok Code Fast 1 → GPT-5 mini → GPT-4.1 |

---

## Updating model assignments

Model names and availability change over time. If a model disappears from your Copilot picker:

1. Check the [Supported AI models](https://docs.github.com/en/copilot/reference/ai-models/supported-models) page.
2. Update the `model:` array in the relevant `.github/agents/*.agent.md` file.
3. Or run *"Update your instructions"* — template updates refresh agent file recommendations when models change.

---

## Agent handoffs

The Code and Review agents have pre-configured handoffs:

- **Code → Review**: After implementing changes, Copilot offers "Review changes" — one click hands off to the Review agent.
- **Review → Code**: After a review, Copilot offers "Implement fixes" — hands off back to the Code agent.

These handoffs keep the model selection optimal throughout your workflow without requiring manual switching.
