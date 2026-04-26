---
description: Refactor selected code using PDCA cycle and Lean waste elimination
argument-hint: Select code first, or name the file and waste category to target
agent: agent
tools: [editFiles, runCommands, codebase]
---

# Refactor Code

Refactor the selected code following Lean principles and the PDCA cycle documented in `.github/copilot-instructions.md`.

1. **Plan**: Identify the specific waste (W1–W16 waste categories) or baseline violation being addressed. State the goal and expected LOC delta.
2. **Do**: Perform the refactoring. Preserve all existing behaviour — no feature changes.
3. **Check**: Run targeted tests first: `bash scripts/harness/select-targeted-tests.sh <changed-paths>`. Run `bash tests/run-all.sh` only when the full task is complete, or if a targeted failure requires broader re-verification.
4. **Act**: If baselines are exceeded, address them. Summarise what changed and why.

Do not add features, change APIs, or modify tests unless the refactoring requires it.
