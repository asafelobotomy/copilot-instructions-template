# User Profile — {{PROJECT_NAME}}

<!-- workspace-layer: L1 | budget: ≤200 tokens | trigger: always -->
> **Domain**: Preferences — observed user behaviours, communication style, and project-scoped interaction patterns.
> **Boundary**: No project facts, agent reasoning, or cross-project preferences (use built-in `/memories/`).

Copilot populates this from direct user statements and observations across sessions. Setup may seed a few rows from explicit interview answers when the mapping is unambiguous.

> **Coexistence note**: VS Code's built-in user memory (`/memories/`) stores personal preferences that persist across all workspaces. This file is different — it captures **project-scoped** observations about how the user works within *this specific project*. Use built-in memory for cross-project preferences; use this file for project-specific interaction patterns that help the agent tailor its behaviour to this codebase.

| Attribute | Observed value |
|-----------|---------------|
| Communication style | *(to be discovered)* |
| Domain expertise | *(to be discovered)* |
| Preferred review depth | *(to be discovered)* |
| Working pace / batch size preference | *(to be discovered)* |
| Tolerance for uncertainty | *(to be discovered)* |
| Preferred output format | *(to be discovered)* |
| Known strong opinions | *(to be discovered)* |

## Interaction history notes

Copilot appends brief notes here after sessions where user behaviour reveals a meaningful preference.
