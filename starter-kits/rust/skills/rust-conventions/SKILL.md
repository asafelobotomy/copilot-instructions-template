---
name: rust-conventions
description: "Idiomatic Rust conventions — ownership, naming, module structure, documentation, and dependency management"
compatibility: ">=1.4"
---

# Rust Conventions

> Skill metadata: version "1.0"; license MIT; tags [rust, cargo, ownership, conventions]; recommended tools [codebase, editFiles].

## When to use

- Writing or reviewing Rust source files
- Enforcing idiomatic Rust patterns and API guidelines

## File scope

Applies to: `**/*.rs`

## Conventions

- Follow Rust API Guidelines (<https://rust-lang.github.io/api-guidelines/>) for public API design.
- Use `snake_case` for functions, methods, variables, and modules. Use `PascalCase` for types, traits, and enum variants. Use `SCREAMING_SNAKE_CASE` for constants and statics.
- Prefer borrowing (`&T`, `&mut T`) over ownership transfer unless the function needs to consume the value.
- Use `impl Trait` in argument position for simple generic bounds. Use named generics for complex bounds.
- Derive standard traits (`Debug`, `Clone`, `PartialEq`) for data types unless there is a reason not to.
- Use `pub(crate)` for internal visibility — avoid `pub` on implementation details.
- Write doc comments (`///`) for all public items. Include examples in doc comments for complex functions.
- Use `cargo fmt` for formatting — do not override rustfmt defaults without team agreement.
- Pin dependency versions in `Cargo.lock` for binaries. Libraries should use semver ranges in `Cargo.toml`.
- Avoid `.clone()` unless necessary — prefer references. When cloning, consider whether `Cow<'_, T>` is more appropriate.
- Use iterators and combinators (`map`, `filter`, `collect`) over manual loops where readability is preserved.
- Prefer `String` for owned data and `&str` for borrowed string parameters.
