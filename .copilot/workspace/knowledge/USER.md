# User Profile — copilot-instructions-template

<!-- workspace-layer: L1 | budget: ≤200 tokens | trigger: always -->
> **Domain**: Preferences — observed user behaviours, communication style, and project-scoped interaction patterns.
> **Boundary**: No project facts, agent reasoning, or cross-project preferences (use built-in `/memories/`).

> **Coexistence note**: VS Code's built-in user memory (`/memories/`) stores personal preferences that persist across all workspaces. This file is different — it captures **project-scoped** observations about how the user works within *this specific project*. Use built-in memory for cross-project preferences; use this file for project-specific interaction patterns that help the agent tailor its behaviour to this codebase.

| Attribute | Observed value |
|-----------|---------------|
| Communication style | Architectural, analytical — prefers structured analysis before implementation |
| Domain expertise | AI agent design, template systems, Lean/Kaizen methodology |
| Preferences | Additive changes over removal; enhance existing capabilities rather than limit them |
| Working hours / pace | *(to be discovered)* |
| Preferred review depth | Thorough — wants full inventory with tradeoff analysis before deciding |
| Correction style | Uses targeted quotes to clarify scope. Precise, non-confrontational. |
| Investigation preference | Prefers research and design confirmation before any implementation starts |
| UX sensitivity | Dislikes disruptive mid-conversation interruptions; prefers optional, non-blocking retrospectives |
| External project evaluation | Rejects wholesale adoption; insists on examining what's better and building a detailed plan before any code changes |

## Interaction history notes

*(Copilot appends brief notes here after sessions where user behaviour reveals a meaningful preference.)*

- **2026-04-02** — Scope clarification: user corrected "chat button extension" framing to mean native Copilot chat button. Used targeted quotes to clarify scope. Precise, non-confrontational.
- **2026-04-09** — External evaluation: user explicitly said "I want to build a deep, detailed and well thought out plan before changing any code" when evaluating MemPalace patterns. Rejects wholesale adoption; extract patterns only.
