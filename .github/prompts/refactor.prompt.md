# Refactor Code

Refactor the selected code following Lean principles from §1 and the PDCA cycle from §5.

1. **Plan**: Identify the specific waste (§6 W1–W16) or baseline violation (§3) being addressed. State the goal and expected LOC delta.
2. **Do**: Perform the refactoring. Preserve all existing behaviour — no feature changes.
3. **Check**: Run `{{THREE_CHECK_COMMAND}}` and confirm no regressions.
4. **Act**: If baselines are exceeded, address them. Summarise what changed and why.

Do not add features, change APIs, or modify tests unless the refactoring requires it.
