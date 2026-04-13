---
name: cpp-safety
description: "C++ memory safety and undefined behaviour prevention — bounds checking, lifetime management, and sanitizer usage"
compatibility: ">=1.4"
---

# C++ Safety

> Skill metadata: version "1.0"; license MIT; tags [cpp, c++, safety, sanitizers, memory]; recommended tools [codebase, editFiles, runCommands].

## When to use

- Reviewing C++ code for memory safety and undefined behaviour
- Configuring sanitizers for debug/test builds

## File scope

Applies to: `**/*.cpp`, `**/*.hpp`, `**/*.cc`, `**/*.hh`, `**/*.cxx`, `**/*.hxx`, `**/*.h`

## Conventions

- Enable AddressSanitizer (`-fsanitize=address`) and UndefinedBehaviorSanitizer (`-fsanitize=undefined`) in debug/test builds.
- Use `std::array` or `std::vector` instead of C-style arrays. Access elements via `.at()` in debug code for bounds checking.
- Never return pointers or references to local variables.
- Avoid dangling references — ensure referenced objects outlive the reference.
- Use `std::move` explicitly when transferring ownership. Don't access moved-from objects.
- Initialize all variables at declaration. Use braced initialization to catch narrowing conversions.
- Check iterator validity after container modifications (insert, erase, resize).
- Use `nullptr` instead of `NULL` or `0` for null pointers.
- Avoid `reinterpret_cast` — use `static_cast` or `std::bit_cast` (C++20) when type punning is needed.
- Run clang-tidy with `clang-analyzer-*`, `bugprone-*`, and `cppcoreguidelines-*` checks.
- Avoid `goto` — use structured control flow, RAII, or scope guards.
- Use thread sanitizer (`-fsanitize=thread`) for concurrent code in test builds.
