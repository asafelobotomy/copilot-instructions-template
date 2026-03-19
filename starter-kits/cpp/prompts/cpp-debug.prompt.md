---
description: "Systematic C++ debugging workflow — build diagnostics, sanitizers, debugger, fix, verify"
agent: copilot
---

# C++ Debug

Systematic debugging workflow for C++ issues.

## Steps

1. **Reproduce** — get the exact error:
   - For compile errors: run `cmake --build build/ 2>&1` and copy the full diagnostic
   - For runtime errors: run under sanitizers (`-fsanitize=address,undefined`)
   - For test failures: run `ctest --test-dir build/ --output-on-failure`
   - Note: is it a compile error, linker error, or runtime crash?

2. **Isolate** — narrow the scope:
   - Compile errors: read the first error in the diagnostic chain (later errors are often cascading)
   - Linker errors: check for missing `target_link_libraries`, undefined symbols, or ODR violations
   - Runtime: run under AddressSanitizer to get a stack trace with source locations
   - Use `compile_commands.json` to verify the file is being compiled with expected flags

3. **Inspect** — gather state:
   - Use GDB/LLDB: `break`, `print`, `backtrace`, `watch` on variables
   - Check for uninitialized memory, use-after-free, buffer overflows (sanitizer output)
   - Verify template instantiation if the error is in templated code
   - Check include ordering and forward declarations

4. **Fix** — make the minimal change:
   - Fix the root cause, not the symptom
   - Add a test case that reproduces the failure
   - Run clang-tidy on the changed files

5. **Verify** — confirm the fix:
   - Rebuild: `cmake --build build/`
   - Run tests: `ctest --test-dir build/`
   - Run sanitizers: rebuild with `-fsanitize=address,undefined` and re-test
   - Run clang-tidy: `clang-tidy --fix src/changed_file.cpp`
