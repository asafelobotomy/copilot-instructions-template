---
name: Test Files
applyTo: "**/*.test.*,**/*.spec.*,**/tests/**,**/test/**,**/__tests__/**"
description: "Conventions for test and spec files — naming, structure, mocking, and the arrange/act/assert pattern"
---

# Test File Instructions

- Testing framework: {{TEST_FRAMEWORK}}
- During iterative work, run the narrowest relevant targeted tests first.
- If the repo documents a targeted-test selector or phase-test command, use it to choose phase checks from changed paths instead of defaulting to `{{TEST_COMMAND}}`.
- Run `{{TEST_COMMAND}}` once only when the full task is complete, or earlier only if a targeted failure required broader re-verification.
- Name test files to mirror the source file they cover (e.g. `utils.ts` → `utils.test.ts`).
- Each test should have a clear arrange/act/assert structure.
- Prefer testing behaviour over implementation details — avoid asserting internal state.
- Mock external dependencies; do not mock the module under test.
- Use descriptive test names that explain the expected behaviour, not the method name.
- When fixing a bug, write a failing test first, then fix the code.
- Every test must emit output on both pass and fail — silent tests are forbidden. Use the project's standard result-reporting helper (e.g. `finish_tests` / `print_results`) at the end of every suite.
- On failure, the output must identify which specific assertion failed and include the actual vs expected values. Never emit blank output when a test fails.
