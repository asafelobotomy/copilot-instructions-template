---
name: cpp-conventions
description: "Modern C++ coding conventions — naming, RAII, smart pointers, const correctness, and standard library usage"
compatibility: ">=1.4"
---

# C++ Conventions

> Skill metadata: version "1.0"; license MIT; tags [cpp, c++, conventions, raii, smart-pointers]; recommended tools [codebase, editFiles].

## When to use

- Writing or reviewing C++ source or header files
- Enforcing modern C++ idioms and naming conventions

## File scope

Applies to: `**/*.cpp`, `**/*.hpp`, `**/*.cc`, `**/*.hh`, `**/*.cxx`, `**/*.hxx`, `**/*.h`

## Conventions

- Target C++17 minimum, C++20 preferred. Specify the standard in CMakeLists.txt, not in source files.
- Use `snake_case` for functions and variables, `PascalCase` for types and classes, `SCREAMING_SNAKE_CASE` for macros.
- Use RAII for resource management. Acquire in the constructor, release in the destructor.
- Prefer `std::unique_ptr` over raw `new`/`delete`. Use `std::shared_ptr` only when shared ownership is genuinely needed.
- Use `std::make_unique` and `std::make_shared` — never raw `new` except in factory patterns.
- Mark single-argument constructors `explicit` to prevent implicit conversions.
- Use `const` and `constexpr` by default. Remove `const` only when mutation is required.
- Prefer `std::string_view` over `const std::string&` for read-only string parameters.
- Prefer `std::span` over pointer+size pairs (C++20).
- Use range-based for loops. Avoid raw index loops unless the index is needed.
- Use `std::optional` for values that may be absent — not sentinel values or out-parameters.
- Use `std::variant` over union types for type-safe alternatives.
- Use `[[nodiscard]]` on functions whose return value must not be ignored.
- Avoid macros. Use `constexpr` functions, `inline` variables, or templates instead.
- Include what you use — do not rely on transitive includes.
