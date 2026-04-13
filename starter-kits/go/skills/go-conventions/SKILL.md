---
name: go-conventions
description: "Idiomatic Go conventions — naming, package design, error handling, concurrency, and project layout"
compatibility: ">=1.4"
---

# Go Conventions

> Skill metadata: version "1.0"; license MIT; tags [go, golang, conventions, error-handling]; recommended tools [codebase, editFiles].

## When to use

- Writing or reviewing Go source files
- Enforcing idiomatic Go patterns and project layout

## File scope

Applies to: `**/*.go`

## Conventions

- Follow Effective Go and the Go Code Review Comments guide.
- Use `camelCase` for unexported identifiers and `PascalCase` for exported ones. Acronyms are all-caps (`HTTPClient`, `ID`).
- Keep packages small and focused. Name packages as single lowercase words — no underscores or mixed case.
- Accept interfaces, return structs. Define interfaces at the point of use, not at the point of implementation.
- Handle errors immediately after function calls. Do not use `_` to discard errors.
- Wrap errors with `fmt.Errorf("context: %w", err)` for debuggable error chains.
- Use `context.Context` as the first parameter for functions that perform I/O or may be cancelled.
- Prefer goroutine-safe designs. Use channels for communication and `sync.Mutex` only when channels add complexity.
- Use `defer` for cleanup — but be aware of its cost in tight loops.
- Avoid `init()` functions — prefer explicit initialization in `main()` or constructors.
- Write godoc comments for all exported types, functions, and methods. Start with the identifier name.
- Use `go vet` and `golangci-lint` in CI. Fix all warnings.
- Follow the standard project layout: `cmd/`, `internal/`, `pkg/` (if exposing a library).
