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
| **Review** | GPT-5.4 | Deep code review, architectural analysis, Lean/Kaizen critique |
| **Fast** | Claude Haiku 4.5 | Quick questions, syntax lookups, single-file lightweight edits |
| **Update** | Claude Sonnet 4.6 | Fetch and apply upstream instruction updates from the template repo |
| **Doctor** | Claude Sonnet 4.6 | Read-only health check on all Copilot instruction and config files |

Each agent has a fallback chain so it degrades gracefully if a model is unavailable on your plan.

---

## Model selection rationale

| Model | Reason chosen |
|-------|--------------|
| **Claude Sonnet 4.6** (Setup, Update) | Strong instruction-following; handles the 3-tier preference interview (5-23 questions) and complex conditional logic in setup well. Also used for Update: reliable at fetch → compare → apply workflows |
| **GPT-5.3-Codex** (Code) | GitHub's latest agentic coding model (GA Feb 9 2026); ~25% faster than its predecessor; supports real-time mid-task steering. Stays in the Codex lineage for clean fallbacks |
| **GPT-5.4** (Review) | GitHub Copilot now recommends GPT-5.4 for deep reasoning and debugging. It gives the review agent stronger code analysis at a 1x multiplier while preserving GPT-style reasoning continuity with the coding agent. |
| **Claude Haiku 4.5** (Fast) | 0.33× cost multiplier; fastest response time. Right-sized for questions that don't warrant a premium model |
| **Claude Sonnet 4.6** (Doctor) | Primary model for mechanical checks (line counts, grep patterns, file presence). 1× cost; fast and accurate for all D1–D10 checks. Opus 4.6 is the fallback if a subtle semantic issue requires deeper reasoning |

---

## Fallback chains

If a model is unavailable on your plan, the agent falls back in order:

| Agent | Fallback order |
|-------|---------------|
| Setup | Claude Sonnet 4.6 → Claude Sonnet 4.5 → GPT-5.1 → GPT-5 mini |
| Code | GPT-5.3-Codex → GPT-5.2-Codex → GPT-5.1-Codex → GPT-5.1 → GPT-5 mini |
| Review | GPT-5.4 → Claude Opus 4.6 → Claude Sonnet 4.6 → GPT-5.1 |
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

> **Important**: The `agent:` value in a handoff must match the target agent's `name:` frontmatter field exactly. For example, `coding.agent.md` is referenced as `agent: Code` because the file declares `name: Code`.

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

---

## Agent plugins (VS Code 1.110+ — experimental)

Agent plugins are a new distribution mechanism that bundles skills, agents, hooks, MCP servers, and custom commands into a single installable package. Plugins are discovered through the Extensions view (`@agentPlugins` filter).

| Concept | Description |
|---------|-------------|
| **What they contain** | Pre-packaged bundles of `.agent.md` files, `SKILL.md` files, hook scripts, MCP server configs, and slash commands |
| **Where to find them** | Extensions view → search `@agentPlugins`, or browse curated marketplaces |
| **Settings** | `chat.plugins.enabled` (boolean), `chat.plugins.marketplaces` (URLs), `chat.plugins.paths` (local paths for development) |
| **Relationship to this template** | This template is not yet packaged as a plugin, but could be in a future major version. Agent plugins are complementary — plugins from the marketplace can extend your workspace alongside the template's own agents and skills. |

> **Status**: Agent plugins are in Preview. The API and distribution format may change.

### Template as an agent plugin — strategic outlook

The template's structure (agents, skills, hooks, MCP config) aligns closely with what agent plugins bundle. Packaging the template as an installable plugin would allow one-click adoption instead of the current fetch-and-populate setup flow.

**Why defer to v4.0**:

- The plugin format is still Preview — breaking changes are expected before GA
- The template's core value is the interactive setup interview that resolves `{{PLACEHOLDER}}` tokens to the consumer's stack, which plugins cannot currently replicate (plugins install static files)
- Marketplace discovery (`chat.plugins.marketplaces`) uses Git repositories as plugin sources, which conflicts with the template's current role as a *source* repo rather than a *distribution* package

**What a v4.0 plugin version could look like**:

| Component | Plugin packaging |
|-----------|------------------|
| Six agents | Installed directly into the user's agent dropdown |
| Thirteen skills | Available on-demand without copying to `.github/skills/` |
| Five hooks | Registered via the plugin's hook manifest |
| Prompt files | Appear as slash commands contributed by the plugin |
| Setup interview | Remains a separate flow — the plugin would include a `/setup` command that triggers it |

**Current recommendation**: Use the template via the existing setup flow (SETUP.md / Setup agent). Monitor the plugin API for GA status. When plugins support dynamic configuration (placeholder resolution, user interviews), revisit packaging.

**For plugin development/testing today**: Clone the template repo locally and register it via `chat.plugins.paths` in your VS Code settings to preview how its files would appear as plugin-contributed customizations:

```json
"chat.plugins.paths": {
    "/path/to/copilot-instructions-template": true
}
```

---

## Built-in `/create-*` commands (VS Code 1.110+)

VS Code 1.110 introduced built-in slash commands for scaffolding Copilot customization files:

| Command | Creates | Template equivalent |
|---------|---------|-------------------|
| `/create-prompt` | `.github/prompts/<name>.prompt.md` | Manual creation / skill-creator |
| `/create-instruction` | `.github/instructions/<name>.instructions.md` | Manual creation |
| `/create-skill` | `.github/skills/<name>/SKILL.md` | `skill-creator` skill |
| `/create-agent` | `.github/agents/<name>.agent.md` | Manual creation |
| `/create-hook` | `.github/hooks/scripts/<name>.sh` + JSON config | Manual creation |

These built-in commands generate starter templates. The template's `skill-creator` skill provides additional Lean/Kaizen guidance beyond the basic scaffold (e.g., waste-aware naming, PDCA verification steps, quality gate checks).

---

## Organization-level agents

GitHub supports publishing custom agents at the organization and enterprise level. Org-level agents are available to all members without requiring per-repository setup.

### How it works

1. An organization or enterprise owner creates a **`.github-private`** repository in the organization (this is a special GitHub repository name).
2. Agent `.agent.md` files are placed in a root-level **`agents/`** directory in that repository — **not** `.github/agents/`, which is the per-repo convention.
3. The files are committed and merged to the default branch.
4. Members enable discovery in VS Code via:

   ```json
   "github.copilot.chat.organizationCustomAgents.enabled": true
   ```

5. Org-level agents then appear in the Copilot agent dropdown alongside workspace and user-profile agents for all org members.

### File structure

```text
.github-private/              ← special org-level repository
└── agents/
    ├── review.agent.md       ← org-wide review agent
    ├── security.agent.md     ← org-wide security agent
    └── onboarding.agent.md   ← org-wide onboarding agent
```

### Agent format

Org-level agents use the same `.agent.md` format as workspace agents — YAML frontmatter with `name`, `description`, `tools`, `model`, and Markdown body. The `target` property can restrict an agent to `vscode` or `github-copilot` if needed.

### How to identify agent source

When multiple agents share the same name, VS Code shows the source (workspace, user profile, organization, or plugin) in a tooltip. Use **Configure Custom Agents** from the agents dropdown to see all loaded agents and their origins.

### Using this template with org-level agents

Consumer projects using this template can publish shared agents at the org level:

1. **Domain-specific agents**: Create agents with team knowledge baked in (e.g., a Review agent that knows your API conventions, a Security agent that knows your compliance requirements).
2. **Standardised workflows**: Push the template's six agents to the org `.github-private` repo so all teams get the same Lean/Kaizen workflow without per-repo setup.
3. **Layered approach**: Use org-level agents for shared conventions and workspace agents for project-specific overrides.

> **Reference**: [Creating custom agents for your organization](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents) — GitHub docs.

---

## Claude agent format compatibility

VS Code supports `.md` files in the `.claude/agents/` directory as an alternative agent format, following the [Claude sub-agents specification](https://code.claude.com/docs/en/sub-agents). This enables teams using both VS Code and Claude Code to share agent definitions.

### Format differences

| Property | `.agent.md` (VS Code) | `.claude/agents/*.md` (Claude) |
|----------|----------------------|-------------------------------|
| Tools | YAML array: `tools: [editFiles, runCommands]` | Comma-separated string: `tools: "Read, Grep, Glob, Bash"` |
| Tool blocking | Not supported natively | `disallowedTools: "Bash, Edit"` |
| Model pinning | `model: [Claude Sonnet 4.6, ...]` | Not supported (model chosen externally) |
| Handoffs | Supported (`handoffs:` frontmatter) | Not supported |
| Invocation control | `user-invocable`, `disable-model-invocation` | Not supported |

VS Code automatically maps Claude tool names to VS Code equivalents when loading `.claude/agents/` files.

### Should this template provide Claude-format stubs?

**Current decision: Not yet.** The `.agent.md` format in `.github/agents/` is the primary standard — it supports model pinning, handoffs, invocation controls, and the full tool vocabulary. The Claude format is a compatibility layer for teams already invested in Claude Code.

**When to reconsider**: If Claude Code adoption grows significantly, or if VS Code adds bidirectional sync between the two formats, shipping dual-format stubs would reduce friction for cross-tool teams. For now, teams needing Claude compatibility can manually create simplified `.claude/agents/*.md` files that reference the same instructions.

**Workaround for cross-tool teams today**: Create a `.claude/agents/` directory with lightweight stubs that `#include` your main instruction file:

```markdown
---
name: Code
description: Implement features and refactor code
tools: "Read, Edit, Bash, Grep, Glob"
---

Follow the project conventions in `.github/copilot-instructions.md`.
```

---

## Chat Customizations editor (VS Code 1.110+ — Preview)

VS Code 1.110 introduced a centralised **Chat Customizations editor** that provides a single UI to discover and manage all Copilot customization files across your workspace, user profile, and organization.

Open it via: `Copilot: Open Chat Customizations` (Command Palette) or the Copilot menu.

| What it shows | Details |
|--------------|--------|
| Instruction files | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` |
| Agent files | `.github/agents/*.agent.md` — workspace, user profile, and org-level |
| Skill files | `.github/skills/*/SKILL.md` |
| Prompt files | `.github/prompts/*.prompt.md` |
| Hook configuration | `.github/hooks/copilot-hooks.json` |

The editor also shows customizations from **user profiles** and **organization-level agents**, making it the best place to understand what Copilot is loading across all sources.

**Relationship to the Doctor agent**: The Doctor agent performs programmatic checks on these same files (structure, attention budget, placeholder leakage). The Chat Customizations editor is the visual counterpart — use the Doctor for automated audits, the editor for manual browsing.

---

## Session management (VS Code 1.110+)

VS Code 1.110 added several features for managing long agent sessions:

### Context compaction (`/compact`)

Type `/compact` to manually trigger context compaction. VS Code summarises the conversation and starts fresh with the summary as context. Automatic compaction happens when the context window fills.

The template's `save-context.sh` PreCompact hook fires before compaction, injecting structured project state to preserve agent awareness. See the [Hooks Guide](HOOKS-GUIDE.md#context-management-commands-vs-code-1110) for details.

### Session forking (`/fork`)

Type `/fork` to create a branching conversation from the current point. The forked session inherits the full conversation history. Use it to explore alternatives without losing the main thread.

### Session memory for plans

The built-in Plan agent persists plans across conversation turns using session memory. Plans survive context compaction — the agent can reference its plan even after `/compact`.

---

## Agent Debug Panel (VS Code 1.110+)

The Agent Debug Panel replaces the previous "Diagnostics" chat action. Open it via `Developer: Open Agent Debug Panel` (Command Palette).

| Feature | Description |
|---------|-------------|
| Loaded agents | See which `.agent.md` files are discovered and their frontmatter |
| Loaded instructions | View which `.instructions.md` files are active for the current file |
| Active skills | Check which skills matched the current task |
| Hook status | See loaded hooks and any validation errors |
| MCP servers | View configured servers and connection status |

**When to use**: If an agent, instruction, or hook isn't firing as expected, the Agent Debug Panel shows exactly what Copilot loaded. The Doctor agent references this panel in its troubleshooting output.

---

## Explore subagent (VS Code 1.110+)

The Explore subagent is a built-in, read-only codebase exploration agent that other agents can delegate to. It performs fast searches across the workspace without modifying files.

**How agents use it**: When an agent needs to understand unfamiliar code before making changes, it can delegate the search to Explore rather than performing multiple sequential file reads in the main conversation.

**In the template**: The Code and Review agents can leverage Explore transparently. It is listed as an available agent in `AGENTS.md` and can be used via subagent invocation.

---

## Custom thinking phrases (VS Code 1.110+)

The `chat.agent.thinking.phrases` setting lets you customise the status messages shown while an agent is processing. Add an array of strings in `.vscode/settings.json` — VS Code cycles through them randomly during agent thinking time.

```json
"chat.agent.thinking.phrases": [
    "Applying Lean principles...",
    "Checking waste categories...",
    "Running PDCA cycle..."
]
```

---

## askQuestions tool (VS Code 1.110+ — core)

The `askQuestions` tool (previously `vscode_askQuestions`) moved from the VS Code extension API to a core built-in tool in v1.110. Agents can use it to present structured questions to the user mid-task. The template's Setup agent relies on this tool for the preference interview — no additional configuration is needed.
