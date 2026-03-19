---
description: "Systematic Go debugging workflow — test output, delve, race detector, fix, verify"
agent: copilot
---

# Go Debug

Systematic debugging workflow for Go issues.

## Steps

1. **Reproduce** — get the exact error:
   - Compile errors: `go build ./...` — read the diagnostic
   - Test failures: `go test -v ./path/to/package` for verbose output
   - Runtime panics: read the goroutine stack trace

2. **Isolate** — narrow the scope:
   - Run a single test: `go test -run TestName -v ./package/`
   - Use `-count=1` to disable test caching
   - Use the race detector: `go test -race ./...`
   - Check for nil pointer dereferences, slice out-of-bounds, or map access issues

3. **Inspect** — gather state:
   - Use `fmt.Printf("%+v\n", value)` for quick inspection
   - Use Delve debugger: `dlv test ./package/ -- -test.run TestName`
   - Check goroutine leaks with `runtime.NumGoroutine()` in tests
   - Verify interface satisfaction at compile time: `var _ Interface = (*Impl)(nil)`

4. **Fix** — make the minimal change:
   - Fix the root cause, not the symptom
   - Write a table-driven test case that reproduces the failure
   - Handle the error that was previously unchecked

5. **Verify** — confirm the fix:
   - `go build ./...` — compiles cleanly
   - `go test ./...` — all tests pass
   - `go test -race ./...` — no race conditions
   - `go vet ./...` — no suspicious constructs
   - `golangci-lint run ./...` — linter passes
