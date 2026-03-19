---
description: "Systematic Rust debugging workflow — compiler diagnostics, tests, sanitizers, fix, verify"
agent: copilot
---

# Rust Debug

Systematic debugging workflow for Rust issues.

## Steps

1. **Reproduce** — get the exact error:
   - Compile errors: `cargo build 2>&1` — read the full diagnostic
   - Test failures: `cargo test -- --nocapture` for output
   - Runtime panics: read the backtrace (`RUST_BACKTRACE=1 cargo run`)

2. **Isolate** — narrow the scope:
   - Compiler errors: focus on the first error — later ones often cascade
   - Borrow checker: identify which lifetime or ownership rule is violated
   - Use `cargo check` for faster type-checking without building
   - Run Miri for undefined behaviour: `cargo +nightly miri test`

3. **Inspect** — gather state:
   - Use `dbg!()` macro for quick value inspection (removed before commit)
   - Check for moved values used after move
   - Verify trait bounds are satisfied for generic code
   - Check `match` exhaustiveness for enum changes

4. **Fix** — make the minimal change:
   - Fix the root cause, not the symptom
   - Write a test that fails before the fix
   - Run `cargo clippy` for additional suggestions

5. **Verify** — confirm the fix:
   - `cargo check` — type checks pass
   - `cargo test` — all tests pass
   - `cargo clippy` — no warnings
   - `cargo fmt --check` — formatting is clean
