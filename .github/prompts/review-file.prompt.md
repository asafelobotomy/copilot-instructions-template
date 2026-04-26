---
description: Review a file for waste categories, baseline violations, and coding convention issues
argument-hint: Open the file to review, or name it here
agent: ask
tools: [codebase]
---

# Review File

Review the current file using the Review Mode protocol from `.github/copilot-instructions.md`.

1. Read the file in full before making any observations.
2. For each finding, classify by:
   - **Severity**: critical / major / minor / advisory
   - **Waste category**: W1–W16 from the Waste Catalogue (or "none" if not applicable)
3. Check baselines: file LOC (warn 250, hard 400), dependency count (max 6 runtime deps).
4. Note any patterns that violate the Coding Conventions section.
5. Produce a structured report — do not apply fixes.

Format findings as a table:

| # | Severity | Waste | Line(s) | Finding | Suggestion |
|---|----------|-------|---------|---------|------------|
