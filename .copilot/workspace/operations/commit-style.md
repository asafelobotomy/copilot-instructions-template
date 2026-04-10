# Commit Style — copilot-instructions-template

This file is read by the Commit agent on every invocation.

## Format

```yaml
format: conventional-commits
```

## Scope style

```yaml
scope-style: kebab-case
```

## Types allowed

```yaml
types:
  - feat
  - fix
  - docs
  - style
  - refactor
  - perf
  - test
  - build
  - ci
  - chore
```

## Body

```yaml
body: optional
```

When the change is non-trivial, include a brief body explaining the *why*, not the *what*.

## Footer / trailer

```yaml
footer: optional
auto-close-issue: false
```

## Sign-off

```yaml
sign-off: false
```

## Squash policy

```yaml
squash-fixups: false
```

## Notes

- Scopes are typically directory names: `template`, `hooks`, `skills`, `agents`, `tests`, `scripts`, `docs`.
- Do not use the root package name as a scope.
- Breaking changes must include a `BREAKING CHANGE:` footer.
- For release-driving changes, use `feat` only for a real consumer-facing addition. Use `fix`, `deps`, `docs`, `refactor`, `perf`, `build`, `ci`, `test`, or `chore` for patch-level work.
- Release commits follow `release-please` format and should not be hand-authored.
