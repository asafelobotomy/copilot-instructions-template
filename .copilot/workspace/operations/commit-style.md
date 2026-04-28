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
  - revert
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

## Pull strategy

```yaml
pull-strategy: merge
```

Options: `merge` | `rebase`

## Squash policy

```yaml
squash-fixups: false
```

## Notes

- Scopes are typically directory names: `template`, `hooks`, `skills`, `agents`, `tests`, `scripts`, `docs`.
- Do not use the root package name as a scope.
- Breaking changes must include a `BREAKING CHANGE:` footer.
- For release-driving changes, use `feat` only for a real consumer-facing addition. Use `fix`, `docs`, `refactor`, `perf`, `build`, `ci`, `test`, or `chore` for patch-level work.
- Dependency updates use `chore(deps)` (scope-qualified chore), not a standalone `deps` type.
- Release commits follow `release-please` format and should not be hand-authored.
- Revert commits: use `revert: <original subject>` or `revert(<scope>): <original subject>` and include `This reverts commit <hash>.` in the body.
