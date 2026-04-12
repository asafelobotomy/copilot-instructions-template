---
description: Generate tests following project conventions with arrange/act/assert structure
argument-hint: Select code or name the module to test
agent: agent
tools: [editFiles, runCommands, codebase]
---

# Generate Tests

Generate tests for the selected code following project conventions.

1. Use the project test framework: `bash (custom shell test scripts)`.
2. Mirror the source file path in the test directory.
3. Cover:
   - The main success path
   - At least one error/edge case
   - Boundary conditions if applicable
4. Follow the arrange/act/assert pattern.
5. Use descriptive test names: `"should <expected behaviour> when <condition>"`.
6. Mock external dependencies but not the module under test.
7. During iterative work, run the narrowest relevant targeted tests first. In this repo, prefer `bash scripts/harness/select-targeted-tests.sh <paths...>` to choose the phase checks from changed paths.
8. Run `bash tests/run-all.sh` once only if the generated tests finish the full task, or if a targeted failure required broader re-verification.

Do not modify the source code — only create or update test files.
