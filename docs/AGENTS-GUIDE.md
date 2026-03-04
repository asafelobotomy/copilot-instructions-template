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
| Check heartbeat | *"Check your heartbeat"* / *"Run heartbeat checks"* |
| Show heartbeat status | *"Show heartbeat status"* / *"Heartbeat history"* |

There are also variations:

- *"Bootstrap this project from copilot-instructions-template"*
- *"Use the Lean/Kaizen Copilot template to set up this project"*
- *"Sync instructions with the template"*

---

### Option B — Model-pinned agents (VS Code 1.106+)

The template creates six agent files in `.github/agents/`. These appear in the Copilot agent dropdown in VS Code. When you select an agent, Copilot automatically switches to the pinned model for that session — no manual model selection needed.

| Agent | Model | Best for |
|-------|-------|----------|
| **Setup** | Claude Sonnet 4.6 | First-time setup, onboarding, template operations |
| **Code** | GPT-5.3-Codex | Implementation, refactoring, multi-step coding tasks |
| **Review** | Claude Opus 4.6 | Deep code review, architectural analysis, Lean/Kaizen critique |
| **Fast** | Claude Haiku 4.5 | Quick questions, syntax lookups, single-file lightweight edits |
| **Update** | Claude Sonnet 4.6 | Fetch and apply upstream instruction updates from the template repo |
| **Doctor** | Claude Sonnet 4.6 | Read-only health check on all Copilot instruction and config files |

Each agent has a fallback chain so it degrades gracefully if a model is unavailable on your plan.

---

## Model selection rationale

| Model | Reason chosen |
|-------|--------------|
| **Claude Sonnet 4.6** (Setup, Update) | Strong instruction-following; handles the 3-tier preference interview (5–24 questions) and complex conditional logic in setup well. Also used for Update: reliable at fetch → compare → apply workflows |
| **GPT-5.3-Codex** (Code) | GitHub's latest agentic coding model (GA Feb 9 2026); ~25% faster than its predecessor; supports real-time mid-task steering. Stays in the Codex lineage for clean fallbacks |
| **Claude Opus 4.6** (Review) | Agent Teams capability — delegates sub-tasks to specialised virtual agents in parallel, making it ideal for systematic Lean/Kaizen architectural review. 3× multiplier cost; reserve for genuine deep reviews |
| **Claude Haiku 4.5** (Fast) | 0.33× cost multiplier; fastest response time. Right-sized for questions that don't warrant a premium model |
| **Claude Sonnet 4.6** (Doctor) | Primary model for mechanical checks (line counts, grep patterns, file presence). 1× cost; fast and accurate for all D1–D10 checks. Opus 4.6 is the fallback if a subtle semantic issue requires deeper reasoning |

---

## Fallback chains

If a model is unavailable on your plan, the agent falls back in order:

| Agent | Fallback order |
|-------|---------------|
| Setup | Claude Sonnet 4.6 → Claude Sonnet 4.5 → GPT-5.1 → GPT-5 mini |
| Code | GPT-5.3-Codex → GPT-5.2-Codex → GPT-5.1-Codex → GPT-5.1 → GPT-5 mini |
| Review | Claude Opus 4.6 → Claude Opus 4.5 → Claude Sonnet 4.6 → GPT-5.1 |
| Fast | Claude Haiku 4.5 → GPT-5 mini → GPT-4.1 |
| Update | Claude Sonnet 4.6 → Claude Sonnet 4.5 → GPT-5.1 |
| Doctor | Claude Sonnet 4.6 → Claude Opus 4.6 → Claude Opus 4.5 |

---

## Updating model assignments

Model names and availability change over time. If a model disappears from your Copilot picker:

1. Check the [Supported AI models](https://docs.github.com/en/copilot/reference/ai-models/supported-models) page.
2. Update the `model:` array in the relevant `.github/agents/*.agent.md` file.
3. Or run *"Update your instructions"* — template updates refresh agent file recommendations when models change.

---

## Agent handoffs

Handoffs wire guided one-click transitions between agents:

| From | Button | To | When |
|------|--------|----|------|
| **Code** | Review changes | Review | After implementing, get a Lean/Kaizen review |
| **Review** | Implement fixes | Code | After a review, apply the identified fixes |
| **Setup** | Run health check | Doctor | After first-time setup, verify everything is well-formed |
| **Update** | Run health check | Doctor | After an instruction update, verify the result is healthy |
| **Doctor** | Apply fixes | Code | Doctor found file-content issues to fix |
| **Doctor** | Update instructions | Update | Doctor found instructions are behind the template |

These handoffs keep the model selection optimal throughout your workflow without requiring manual switching.

---

## Invocation controls

Two frontmatter properties control how agents are discovered and invoked:

| Property | Default | Description |
|----------|---------|-------------|
| `user-invokable` | `true` | Whether the agent appears in the agents dropdown. Set `false` for subagent-only agents. |
| `disable-model-invocation` | `false` | Prevents the model from autonomously invoking this agent as a subagent. Handoffs are unaffected. |

The template sets `disable-model-invocation: true` on **Setup** and **Update** because both run interactive processes (interviews, pre-flight reports) unsuitable for autonomous subagent invocation.

> **Important**: The `agent:` value in a handoff must match the **filename stem** of the target `.agent.md` file, not the `name:` frontmatter field. For example, `coding.agent.md` is referenced as `agent: coding`, not `agent: Code`.

---

## Sub-directory instruction scoping

GitHub Copilot resolves instruction files hierarchically. You can place a scoped instruction file inside any subdirectory to override or extend the root-level `copilot-instructions.md` for that path.

### AGENTS.md / CLAUDE.md

Placing an `AGENTS.md` file in a subdirectory gives Copilot path-scoped instructions that apply only when working in that directory tree. `CLAUDE.md` is treated as an alias — Copilot reads it with the same precedence.

**Common use cases**:

| Location | Purpose |
|----------|---------|
| `src/api/AGENTS.md` | REST API conventions, authentication rules, response shape standards |
| `src/ui/AGENTS.md` | Component library patterns, accessibility rules, styling conventions |
| `scripts/AGENTS.md` | Shell scripting standards, safety rules for destructive commands |
| `tests/AGENTS.md` | Test naming conventions, fixture patterns, coverage expectations |

**Priority**: Sub-directory `AGENTS.md` instructions are additive — they extend root-level instructions. When a sub-directory rule conflicts with a root rule, the sub-directory rule takes precedence for files within its path.

### excludeAgent frontmatter

You can prevent specific `.github/instructions/*.instructions.md` files from being applied within a path by adding `excludeAgent:` to their frontmatter alongside the `applyTo:` glob:

```yaml
---
applyTo: "**"
excludeAgent: "src/generated/**"
---
```

Use this to stop formatting or lint instructions from firing on auto-generated or vendored code paths that should not be edited manually.

### Practical workflow

1. Create `src/<area>/AGENTS.md` with a concise set of area-specific rules.
2. Keep root-level `copilot-instructions.md` as the universal baseline — avoid duplicating area rules there.
3. Run the Doctor agent after adding any new instruction file to verify Copilot detects and respects it correctly.
