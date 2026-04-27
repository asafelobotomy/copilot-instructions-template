---
name: dependency-update
description: Update project dependencies across npm/pip/cargo/go/maven/gradle — check for outdated packages, apply updates, run vulnerability scan, verify tests pass
compatibility: ">=0.7.0"
---

# Dependency Update

> Skill metadata: version "1.0"; license MIT; tags [dependencies, security, npm, pip, cargo, go, maven]; compatibility ">=0.7.0"; recommended tools [codebase, runCommands, editFiles].

Update project dependencies safely: detect the package manager(s), check for outdated and vulnerable packages, apply updates in a staged manner, and verify nothing breaks.

## When to use

- User asks to "update dependencies", "bump packages", "check for outdated deps", or "run a vulnerability scan"
- CI reports dependency vulnerabilities or outdated package warnings
- Preparing a release and want a clean dependency state

## When not to use

- Major version upgrades with known breaking changes — those need a dedicated migration plan, not this skill
- Lock-file-only repositories where dependency versions are pinned by policy

## Steps

### 1. Detect package managers

Probe for manifest files:

| File | Manager | Update command |
|------|---------|---------------|
| `package.json` | npm / yarn / pnpm | `npm outdated`, `yarn outdated`, `pnpm outdated` |
| `requirements.txt` / `pyproject.toml` | pip / uv | `pip list --outdated`, `uv lock --upgrade` |
| `Cargo.toml` | cargo | `cargo outdated`, `cargo update` |
| `go.mod` | go modules | `go list -u -m all`, `go get -u ./...` |
| `pom.xml` | Maven | `mvn versions:display-dependency-updates` |
| `build.gradle` / `build.gradle.kts` | Gradle | `./gradlew dependencyUpdates` |

Multiple package managers can coexist — process each one.

### 2. Audit for vulnerabilities first

Run the vulnerability scanner before any updates:

| Manager | Command |
|---------|---------|
| npm | `npm audit` |
| yarn | `yarn audit` |
| pip | `pip-audit` or `safety check` |
| cargo | `cargo audit` |
| go | `govulncheck ./...` |

Record the pre-update vulnerability count. This is the baseline.

### 3. Categorise outdated packages

Group packages by update type:

- **Patch** (`x.y.Z → x.y.Z+1`) — safe, apply automatically
- **Minor** (`x.Y.z → x.Y+1.0`) — generally safe; check changelog for deprecations
- **Major** (`X.y.z → X+1.0.0`) — breaking changes likely; list separately, do not auto-update

Ask the user before applying major version bumps.

### 4. Apply updates

Apply in order: patches first, then minor, then discuss majors.

```bash
# npm — patch + minor
npm update

# pip — all
pip install --upgrade -r requirements.txt

# cargo — compatible updates only
cargo update

# go — all indirect + direct
go get -u ./... && go mod tidy

# Maven
mvn versions:use-latest-versions -DallowMajorUpdates=false
```

### 5. Run post-update checks

After applying updates, in order:

1. **Build** — confirm the project still compiles
2. **Tests** — run the test suite (`npm test`, `pytest`, `cargo test`, etc.)
3. **Lint** — run the linter if configured
4. **Vulnerability scan** — re-run the audit from step 2

If tests fail, identify which update caused the regression. Revert that package and note it for manual follow-up.

### 6. Report

Summarise:

- Packages updated (count by patch/minor)
- Vulnerability count before → after
- Packages skipped (major bumps) with latest available version
- Any regressions found and reverted

## Verify

- [ ] No new vulnerabilities introduced
- [ ] Test suite passes after updates
- [ ] Lock file committed alongside manifest changes (`package-lock.json`, `Cargo.lock`, `go.sum`, etc.)
- [ ] Major version bumps listed explicitly for human review
