---
name: changelog-entry
description: Generate a CHANGELOG.md entry from staged changes, a commit range, or a PR diff — following Keep a Changelog format with conventional commit classification
compatibility: ">=0.7.0"
---

# Changelog Entry

> Skill metadata: version "1.0"; license MIT; tags [changelog, release-notes, commits, keep-a-changelog, conventional-commits]; compatibility ">=0.7.0"; recommended tools [codebase, runCommands, editFiles].

Generate a well-structured CHANGELOG entry from git history, staged changes, or a PR diff. Follows the [Keep a Changelog](https://keepachangelog.com) format.

## When to use

- User asks to "update the CHANGELOG", "write release notes", "add a changelog entry", or "what changed since last release"
- Before cutting a release
- After a PR is merged and CHANGELOG needs updating

## When not to use

- Fully automated tools like `release-please` or `semantic-release` are already configured — defer to them

## Steps

### 1. Determine the change scope

Identify what commits or changes to summarise:

```bash
# Staged changes (pre-commit)
git diff --staged --stat

# Changes since last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# PR diff (compare branches)
git log main..feat/my-feature --oneline

# Specific commit range
git log v1.2.0..v1.3.0 --oneline
```

### 2. Classify commits by change type

Map conventional commit prefixes to Keep a Changelog sections:

| Conventional commit prefix | CHANGELOG section |
|---------------------------|-------------------|
| `feat:`, `feat(scope):` | **Added** |
| `fix:`, `fix(scope):` | **Fixed** |
| `refactor:` (no behaviour change) | **Changed** |
| `perf:` | **Changed** |
| `deprecate:` | **Deprecated** |
| `remove:` | **Removed** |
| `security:`, security-related `fix:` | **Security** |
| `docs:`, `test:`, `chore:`, `ci:` | Omit from user-facing CHANGELOG |
| Breaking change (`!` suffix or `BREAKING CHANGE:` footer) | **Breaking Changes** (always first) |

For commits without conventional prefixes, infer the section from the message content.

### 3. Write the entry

Format:

```markdown
## [Unreleased] or ## [x.y.z](compare-url) (YYYY-MM-DD)

### Breaking Changes

* **scope**: description of what broke and migration path

### Added

* **scope**: description of new capability

### Changed

* **scope**: description of what changed

### Fixed

* **scope**: description of what was fixed

### Security

* **scope**: description of vulnerability or hardening applied
```

Rules:
- Omit empty sections
- Each bullet starts with `* **scope**:` (optional scope in bold) then a user-readable description
- Write in terms of **what the user can do differently**, not what line of code changed
- Link to issues or PRs using `([#123](https://github.com/org/repo/issues/123))`
- Keep bullets to one sentence

**Good:**

```markdown
### Added

* **auth**: users can now log in with GitHub OAuth in addition to email/password ([#88](…))
```

**Bad:**

```markdown
### Changed

* updated `auth/oauth.ts` to call the new GitHub endpoint
```

### 4. Determine version bump (if releasing)

Follow Semantic Versioning from the change set:

| Change type | Version bump |
|------------|-------------|
| Breaking change present | **Major** (`X.0.0`) |
| New feature, no breaking changes | **Minor** (`x.Y.0`) |
| Bug fixes only | **Patch** (`x.y.Z`) |
| Security fix only | **Patch** (`x.y.Z`) — expedite release |

### 5. Insert into CHANGELOG.md

Structure of `CHANGELOG.md`:

```markdown
# Changelog

...preamble...

## [Unreleased]

(new entries go here before release)

## [1.2.0](https://github.com/org/repo/compare/v1.1.0...v1.2.0) (2026-03-01)

...previous entries...
```

On release: rename `[Unreleased]` to `[x.y.z](compare-url) (YYYY-MM-DD)` and add a fresh empty `[Unreleased]` above it.

### 6. Add compare links

At the bottom of CHANGELOG.md, maintain compare links:

```markdown
[Unreleased]: https://github.com/org/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/org/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/org/repo/compare/v1.0.0...v1.1.0
```

## Verify

- [ ] Entry placed under `[Unreleased]` or the correct version header
- [ ] Each section heading only present if it contains at least one item
- [ ] Bullets written in user-facing language, not implementation details
- [ ] Breaking changes listed first with migration guidance
- [ ] Compare URL updated at bottom of file
- [ ] `docs:`, `test:`, `chore:` commits omitted from user-facing changelog
