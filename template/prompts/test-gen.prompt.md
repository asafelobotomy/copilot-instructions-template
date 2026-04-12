---
description: Generate tests following project conventions with arrange/act/assert structure
argument-hint: Select code or name the module to test
agent: agent
tools: [editFiles, runCommands, codebase]
---

# Generate Tests

Generate tests for the selected code following project conventions.

1. Use the project test framework: `{{TEST_FRAMEWORK}}`.
2. Mirror the source file path in the test directory.
3. Cover:
   - The main success path
   - At least one error/edge case
   - Boundary conditions if applicable
4. Follow the arrange/act/assert pattern.
5. Use descriptive test names: `"should <expected behaviour> when <condition>"`.
6. Mock external dependencies but not the module under test.
7. During iterative work, run the narrowest relevant targeted tests first.
8. If the repo documents a targeted-test selector or phase-test command, use it to choose phase checks from changed paths instead of defaulting to `{{TEST_COMMAND}}`.
9. Run `{{TEST_COMMAND}}` once only if the generated tests finish the full task, or if a targeted failure required broader re-verification.

Do not modify the source code — only create or update test files.
