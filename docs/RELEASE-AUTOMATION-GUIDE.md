# Release Automation Guide

> Human-readable companion to `.github/workflows/release-manual.yml` and `.github/workflows/release-please.yml`.

---

## Two release strategies

This template ships with two release workflows. **Use one or the other** — having both active will create duplicate releases.

### Option A: Manual release (`release-manual.yml`)

**How it works**: When you push a change to `VERSION` on `main`, the workflow reads the new version, extracts matching changelog notes from `CHANGELOG.md`, and creates a GitHub release with that tag.

**You are responsible for**:

- Bumping `VERSION` manually
- Writing the `CHANGELOG.md` entry manually (following Keep a Changelog format)
- Ensuring the version in `VERSION` matches the `## [x.y.z]` heading in `CHANGELOG.md`

**Best for**: Projects that want full control over version numbers and changelog prose. The CI validation job already enforces that `VERSION` and `CHANGELOG.md` stay in sync.

### Option B: Release Please (`release-please.yml`)

**How it works**: [Release Please](https://github.com/googleapis/release-please) reads your commit history (expecting [Conventional Commits](https://www.conventionalcommits.org/)), determines the next semver bump, generates a changelog, and opens a "release PR". Merging that PR triggers the actual GitHub release.

**You are responsible for**:

- Writing commit messages in Conventional Commits format (`feat:`, `fix:`, `chore:`, etc.)
- Reviewing and merging the release PR when you are ready to cut a release

**Release Please handles**:

- Determining the version bump (patch for `fix:`, minor for `feat:`, major for `feat!:` or `BREAKING CHANGE:`)
- Updating `CHANGELOG.md` with auto-generated notes
- Updating `VERSION` via the `extra-files` configuration
- Creating the GitHub release and git tag

**Best for**: Projects that follow Conventional Commits and want fully automated versioning.

---

## Choosing a strategy

| Consideration | Manual | Release Please |
|--------------|--------|----------------|
| Changelog quality | Hand-written, narrative style | Auto-generated from commits |
| Version control | You choose every number | Computed from commit types |
| Commit discipline | Any commit style | Requires Conventional Commits |
| Release timing | Push `VERSION` change when ready | Merge the release PR when ready |
| CI dependencies | None beyond existing checks | Needs `contents: write` + `pull-requests: write` |

### Switching strategies

**To use Manual** (default): Disable `release-please.yml` by renaming it to `release-please.yml.disabled` or deleting it.

**To use Release Please**: Disable `release-manual.yml` by renaming it to `release-manual.yml.disabled` or deleting it.

Both workflows are SHA-pinned and include `step-security/harden-runner` for supply-chain security.

---

## Configuration reference

### release-manual.yml

```yaml
on:
  push:
    branches: [main]
    paths:
      - VERSION        # Only triggers when VERSION file changes
```

No additional configuration needed. The workflow reads `VERSION` and `CHANGELOG.md` directly.

### release-please.yml

```yaml
on:
  push:
    branches: [main]   # Triggers on every push to main
```

Key configuration in the action step:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `release-type` | `simple` | Uses `VERSION` file for version tracking (no `package.json` needed) |
| `extra-files` | `VERSION` | Tells release-please to update the `VERSION` file when bumping |

For advanced configuration (monorepo support, custom changelog sections, bootstrap versions), see the [release-please documentation](https://github.com/googleapis/release-please).

---

## Conventional Commits quick reference

If using Release Please, format your commits as:

```text
feat: add MCP server configuration scaffolding
fix: correct section numbering in CI validation
docs: update README with v2.0.0 features
chore: upgrade markdownlint-cli2-action to v22
feat!: add §13 MCP Protocol (breaking: changes section count)
```

| Prefix | Version bump | Description |
|--------|-------------|-------------|
| `feat:` | Minor (0.x.0) | New feature |
| `fix:` | Patch (0.0.x) | Bug fix |
| `docs:` | Patch | Documentation only |
| `chore:` | Patch | Maintenance, dependencies |
| `feat!:` or `BREAKING CHANGE:` | Major (x.0.0) | Breaking change |

---

*See also: `.github/workflows/release-manual.yml` (VERSION-triggered release) · `.github/workflows/release-please.yml` (automated release) · `CHANGELOG.md` (version history) · `VERSION` (current version)*
