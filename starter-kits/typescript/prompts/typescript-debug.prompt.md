---
description: "Systematic TypeScript/JavaScript debugging workflow — reproduce, isolate, inspect, fix, verify"
agent: copilot
---

# TypeScript Debug

Systematic debugging workflow for TypeScript/JavaScript issues.

## Steps

1. **Reproduce** — get the exact error:
   - Run the failing test: `npx vitest run <file> --reporter=verbose` or `npx jest <file> --verbose`
   - Copy the full stack trace including the error type and message
   - Note whether the error is a type error (compile time) or runtime error

2. **Isolate** — narrow the scope:
   - Check the stack trace — is it in project code or a dependency?
   - Run the type checker: `npx tsc --noEmit` to see if types are consistent
   - Comment out code to find the minimal reproduction
   - Use `console.log()` or the VS Code debugger to trace execution

3. **Inspect** — gather state:
   - Check for `undefined` or `null` where an object is expected
   - Verify async operations are properly `await`ed
   - Check for stale closures in callbacks or event handlers
   - Verify import paths and module resolution

4. **Fix** — make the minimal change:
   - Fix the root cause, not the symptom
   - Write a regression test that fails before the fix
   - Run the type checker after the fix

5. **Verify** — confirm the fix:
   - Run the specific failing test
   - Run the full test suite: `npm test`
   - Run the type checker: `npx tsc --noEmit`
   - Run the linter: `npx eslint .`
