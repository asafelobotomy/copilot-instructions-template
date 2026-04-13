---
name: java-conventions
description: "Java coding conventions — naming, records, Optional, streams, logging, and dependency injection"
compatibility: ">=1.4"
---

# Java Conventions

> Skill metadata: version "1.0"; license MIT; tags [java, conventions, records, streams, spring-boot]; recommended tools [codebase, editFiles].

## When to use

- Writing or reviewing Java source files
- Enforcing modern Java idioms and patterns

## File scope

Applies to: `**/*.java`

## Conventions

- Target the latest LTS Java version (21+). Use records, sealed classes, pattern matching where applicable.
- Use `PascalCase` for classes and interfaces, `camelCase` for methods and variables, `SCREAMING_SNAKE_CASE` for constants.
- Use `record` types for immutable value objects instead of mutable POJOs with getters/setters.
- Use `Optional<T>` as a return type for methods that may not produce a result. Never use `Optional` as a field or parameter type.
- Prefer `var` for local variables when the type is obvious from the right-hand side.
- Use `Stream` API for collection transformations — avoid manual loops for filter/map/reduce operations.
- Use `try-with-resources` for all `AutoCloseable` objects (I/O, database connections, HTTP clients).
- Use SLF4J with parameterized messages for logging: `log.info("User {} logged in", userId)`. Never concatenate log messages.
- Prefer constructor injection over field injection for dependency injection frameworks.
- Use `final` on classes, methods, and parameters where mutability is not needed.
- Follow the Effective Java guidelines: minimize mutability, prefer composition over inheritance, design for extension or prohibit it.
- Pin dependency versions explicitly in the build file. Use dependency management BOMs for version alignment.
