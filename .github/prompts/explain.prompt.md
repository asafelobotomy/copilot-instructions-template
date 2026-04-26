---
description: Explain selected code with waste category analysis and baseline checks
argument-hint: Select code first, or describe what to explain
agent: ask
---

# Explain Code

Explain the selected code. For each significant block:

1. State what it does in one sentence.
2. Identify any W1–W16 waste categories present in the code.
3. Note any LOC or dependency baseline violations (warn at 250 lines / 6 runtime deps; see `.github/copilot-instructions.md`).
4. Suggest one concrete improvement if applicable — do not refactor, only describe.

Reference the project instructions in `.github/copilot-instructions.md` for baselines and conventions.
