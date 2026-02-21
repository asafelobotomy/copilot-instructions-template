---
applyTo: "**/*.test.*,**/*.spec.*,**/tests/**,**/test/**,**/__tests__/**"
---

# Test File Instructions

- Testing framework: {{TEST_FRAMEWORK}}
- Run tests: `{{TEST_COMMAND}}`
- Name test files to mirror the source file they cover (e.g. `utils.ts` → `utils.test.ts`).
- Each test should have a clear arrange/act/assert structure.
- Prefer testing behaviour over implementation details — avoid asserting internal state.
- Mock external dependencies; do not mock the module under test.
- Use descriptive test names that explain the expected behaviour, not the method name.
- When fixing a bug, write a failing test first, then fix the code.
