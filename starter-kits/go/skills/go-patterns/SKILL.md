---
name: go-patterns
description: Idiomatic Go patterns — testing with table tests, error handling, concurrency, module management, and linting
---

# Go Patterns

> Skill metadata: version "1.0"; license MIT; tags [go, golang, testing, modules, linting]; recommended tools [codebase, runCommands, editFiles].

## When to use

- Writing or reviewing Go code for idiomatic patterns
- Setting up Go testing strategies
- Configuring golangci-lint
- Managing Go modules and dependencies

## Testing

### Table-driven tests

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 1, 2, 3},
        {"zero", 0, 0, 0},
        {"negative", -1, -2, -3},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.expected {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.expected)
            }
        })
    }
}
```

### Test helpers

Use `t.Helper()` in test helper functions for accurate line reporting:

```go
func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}
```

### Subtests and parallel

```go
func TestAPI(t *testing.T) {
    t.Run("Create", func(t *testing.T) {
        t.Parallel()
        // ...
    })
    t.Run("Delete", func(t *testing.T) {
        t.Parallel()
        // ...
    })
}
```

### Mocking

- Define interfaces at the consumer site (not the provider).
- Use hand-written mocks or `gomock` / `mockery` for generated mocks.
- Use `httptest.NewServer` for HTTP client testing.

### Test files

Place test files alongside source: `handler.go` + `handler_test.go` in the same package.

## Error handling

```go
// Wrap errors with context
if err != nil {
    return fmt.Errorf("loading config from %s: %w", path, err)
}
```

- Always wrap errors with `%w` for `errors.Is` / `errors.As` compatibility.
- Define sentinel errors for expected conditions: `var ErrNotFound = errors.New("not found")`.
- Check errors immediately — never defer error handling.
- Use custom error types when callers need to extract structured information.

## Linting

### golangci-lint configuration

Create `.golangci.yml`:

```yaml
linters:
  enable:
    - errcheck
    - govet
    - staticcheck
    - unused
    - gosimple
    - ineffassign
    - gocritic
    - revive
    - errorlint
    - exhaustive

linters-settings:
  gocritic:
    enabled-checks:
      - rangeValCopy
      - hugeParam
  revive:
    rules:
      - name: exported
        arguments: [checkPrivateReceivers]

run:
  timeout: 5m
```

Run: `golangci-lint run ./...`

## Module management

```bash
go mod init example.com/myproject   # Initialize
go mod tidy                          # Clean up unused deps
go mod verify                        # Verify dependency integrity
go get -u ./...                      # Update all dependencies
```

- Use `go.sum` for integrity verification — always commit it.
- Avoid `replace` directives in published modules.
- Use major version suffixes (`/v2`) for breaking API changes.

## Commands

```bash
go test ./...                    # Test all packages
go test -race ./...              # Test with race detector
go test -cover ./...             # Test with coverage
go vet ./...                     # Vet for suspicious constructs
go build ./...                   # Build all packages
```
