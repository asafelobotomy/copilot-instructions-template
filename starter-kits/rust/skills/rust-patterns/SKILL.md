---
name: rust-patterns
description: Idiomatic Rust patterns — error handling, ownership, testing, unsafe review, and cargo tooling
compatibility: ">=1.4"
---

# Rust Patterns

> Skill metadata: version "1.0"; license MIT; tags [rust, cargo, clippy, testing, ownership]; recommended tools [codebase, runCommands, editFiles].

## When to use

- Writing or reviewing Rust code for idiomatic patterns
- Setting up cargo configuration and CI pipelines
- Reviewing `unsafe` code blocks
- Designing error handling strategies

## Error handling

### Library code

Use `thiserror` for library error types:

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),

    #[error("not found: {entity} with id {id}")]
    NotFound { entity: &'static str, id: String },

    #[error("validation failed: {0}")]
    Validation(String),
}
```

### Application code

Use `anyhow` for application-level error propagation:

```rust
use anyhow::{Context, Result};

fn load_config(path: &Path) -> Result<Config> {
    let content = fs::read_to_string(path)
        .with_context(|| format!("failed to read config from {}", path.display()))?;
    toml::from_str(&content).context("failed to parse config")
}
```

### Rules

- Never use `.unwrap()` in production code — use `?`, `.expect("reason")`, or match.
- Use `.expect("descriptive reason")` only when the invariant is guaranteed.
- Propagate errors with `?` — do not `match` just to re-wrap.

## Testing

### Unit tests

Place unit tests in the same file with `#[cfg(test)]`:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_valid_input() {
        let result = parse("valid");
        assert_eq!(result, Ok(Expected::Value));
    }

    #[test]
    fn test_parse_invalid_input() {
        let result = parse("");
        assert!(result.is_err());
    }
}
```

### Integration tests

Place integration tests in `tests/` at the crate root:

```text
src/
  lib.rs
tests/
  integration_test.rs
```

### Test patterns

- Use `#[should_panic(expected = "message")]` for panic tests.
- Use `proptest` or `quickcheck` for property-based testing.
- Use `mockall` for mocking traits in tests.
- Run: `cargo test`, `cargo test -- --nocapture` for output.

## Clippy

Run clippy with pedantic lints:

```bash
cargo clippy -- -W clippy::pedantic -W clippy::nursery
```

Configure in `Cargo.toml`:

```toml
[lints.clippy]
pedantic = { level = "warn", priority = -1 }
module_name_repetitions = "allow"
must_use_candidate = "allow"
```

## Unsafe review checklist

When reviewing `unsafe` blocks:

- [ ] Is there a `// SAFETY:` comment explaining why this is sound?
- [ ] Are all preconditions documented and enforced by the caller?
- [ ] Is the `unsafe` scope minimized to the smallest possible block?
- [ ] Is there a safe wrapper function that encapsulates the unsafety?
- [ ] Are there tests that exercise the boundary conditions?
- [ ] Does Miri pass? (`cargo +nightly miri test`)

## Cargo commands

```bash
cargo fmt           # Format
cargo clippy        # Lint
cargo test          # Test
cargo doc --open    # Generate and view docs
cargo audit         # Security audit dependencies
cargo deny check    # License and advisory checks
```

## Verify

- [ ] Error strategy distinguishes library-grade typed errors from app-level propagation
- [ ] Tests cover both happy path and failure semantics
- [ ] Any `unsafe` usage has explicit safety invariants and boundary tests
- [ ] Cargo quality commands (`fmt`, `clippy`, `test`) pass on changed code
