# Research: Automated Release Process Tooling Comparison

> Date: 2026-03-30 | Agent: Researcher | Status: final

## Summary

This report evaluates five release automation tools against the current setup
(`googleapis/release-please-action` v4 with a custom `plan-release.sh` wrapper)
for a single-package GitHub-hosted template repository. The core requirements
are: (1) only release when consumer-facing paths change, (2) infer semver bump
for non-conventional commits, (3) prevent release-loop commits from re-triggering.

**Headline finding**: the current setup is the correct choice for this repo.
None of the alternatives handles the combination of PR-based workflow, path-gating,
and conventional-commit inference without equal or greater custom scripting.
However, two concrete simplifications are available within the existing toolchain:
passing `release-as` as a direct action input (removing config-file mutation) and
optionally switching the trigger from `workflow_run` to `push` (enabling native
`paths:` filtering to absorb part of plan-release.sh).

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://github.com/googleapis/release-please | Official release-please README — releasable units, path config, release-as |
| https://raw.githubusercontent.com/googleapis/release-please/main/docs/manifest-releaser.md | Manifest config — exclude-paths, release-as per package, skip-github-release |
| https://raw.githubusercontent.com/googleapis/release-please/main/docs/customizing.md | Subdirectory path config, versioning strategies, extra-files |
| https://github.com/googleapis/release-please-action | Action inputs — release-as, skip-github-release, skip-github-pull-request |
| https://github.com/changesets/changesets | Changesets concept, intent file workflow, single-package support |
| https://github.com/changesets/action | Changesets CI action — hasChangesets output, version/publish commands |
| https://github.com/semantic-release/semantic-release | semantic-release — full automation, no path filter, skip-ci pattern |
| https://raw.githubusercontent.com/semantic-release/semantic-release/master/docs/usage/configuration.md | CI configuration, plugins, branches config |
| https://github.com/release-drafter/release-drafter | release-drafter — draft-only, include-paths for changelog filtering |
| https://github.com/tj-actions/changed-files | Changed-files action — glob patterns, any_changed output, workflow_run SHA handling |

---

## Findings

### 1. Path Filtering — what each tool natively supports

| Tool | Native path-gating | Notes |
|------|-------------------|-------|
| release-please v4 | Partial | `path` config scopes a package to a single subdirectory. `exclude-paths` per-package excludes specific paths from commit collection. No multi-path `include-paths` equivalent. |
| Changesets | No path concept | Gated on presence of `.changeset/*.md` intent files, not file paths. |
| semantic-release | None | Processes all commits since last tag; no path filter API. |
| release-drafter | Changelog filter only | `include-paths` restricts which PRs appear in notes, not whether a release runs. |
| tj-actions/changed-files | Full | Accepts glob patterns, emits `any_changed` boolean; designed to gate jobs. |
| GitHub native `paths:` | Full (push/PR only) | `on: push: paths:` skips the workflow entirely. Does **not** apply to `on: workflow_run:`. |

**Key finding**: release-please's `path` config applies to a single directory and
controls which commits are *considered* (not whether the action runs at all). It
cannot replicate the current multi-path check (`template/`, `.github/agents/`,
`starter-kits/`, `SETUP.md`, `UPDATE.md`) natively. A custom gating layer is
unavoidable with the current `workflow_run` trigger architecture.

**Alternative**: switching from `workflow_run` to `on: push: branches: [main]`
would allow `paths:` to gate the whole release workflow at zero cost. The
tradeoff is losing the "run only after CI passes" guarantee. This can be
partially recovered with a `concurrency` group and a job dependency, but it
is not identical to the current design.

---

### 2. Non-Conventional Commit Handling

| Tool | What happens with `docs:`, `chore:`, `WIP:`, etc. |
|------|--------------------------------------------------|
| release-please v4 | Only `feat`, `fix`, `deps` (and language-specific types) are "releasable units". Non-releasable commits do not open a release PR unless `release-as` overrides. |
| Changesets | Commit messages are irrelevant; release intent comes from changeset files. |
| semantic-release | No releasable commit → no release. The tool exits 0 silently. |
| release-drafter | Drafts update on every PR merge; version is set by PR label, not commit type. |
| release-please (via `release-as`) | A `release-as` value in the action input or commit body footer forces a specific version regardless of commit types. |

**Key finding**: the custom Python inference in `plan-release.sh` fills an
official gap: when consumer paths change but commits are non-conventional
(e.g., `docs:`, `WIP:`), release-please would ordinarily not create a PR.
The script bridges this through `release-as`. This logic has no native
equivalent in any of the compared tools.

**Simplification opportunity**: instead of injecting `release-as` into the
config JSON file, pass it directly as the `release-as` action input:

```yaml
- uses: googleapis/release-please-action@v4
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    config-file: release-please-config.json          # unmodified
    manifest-file: .release-please-manifest.json
    release-as: ${{ steps.plan.outputs.force_release_as == 'true'
                    && steps.plan.outputs.next_version || '' }}
```

This eliminates the `--write-config` flag, the temp-file copy step, and the
risk of leaving a mutated config if the step fails mid-execution. The
`release-as` input is documented in the official action README.

---

### 3. Release Loop Prevention

| Tool | Mechanism |
|------|-----------|
| release-please v4 | Tracks release state via `autorelease: pending/tagged` PR labels and the merged PR commit SHA. The action does not re-open a PR while one is already open and labelled `autorelease: pending`. It does not, however, guard against being *invoked* from a loop trigger. |
| The current custom script | Guards at the plan layer: if `HEAD` is `chore(main): release x.y.z`, `should_release=false` is emitted before release-please runs at all. This is necessary because `workflow_run` fires again after release-please pushes the release commit to `main`. |
| semantic-release | `@semantic-release/git` plugin appends `[skip ci]` to its commits by default, preventing re-trigger on most CI platforms. GitHub Actions respects `[skip ci]` in the commit title. |
| Changesets | The action only creates a PR when changesets are present; once consumed they are deleted, so no loop is possible. |
| release-drafter | No releases are created automatically; no loop risk. |

**Key finding**: the current guard is necessary and correctly placed. If the
`workflow_run` trigger were replaced with a direct `push` trigger and `[skip ci]`
were added to release-please's generated commit messages (via
`skip-github-release: true` + a custom tagging step), the guard could be
removed from the script. However, release-please does not natively add
`[skip ci]` to its own commits.

An alternative guard approach: use a `concurrency` group on the workflow so
that only one `release-please` job can run at once, combined with a
`if: !startsWith(github.event.head_commit.message, 'chore(main): release')`
condition at the job level (for direct push), moving the guard out of the
custom script.

---

### 4. Automation / Auto-Merge

| Tool | Auto-merge support |
|------|-------------------|
| release-please-action | None built-in; relies on `gh pr merge` or GitHub auto-merge settings. |
| Changesets action | None built-in; same reliance on external merge tooling. |
| semantic-release | No PR; creates tag and release directly — no merge step needed. |
| release-drafter | Draft release only; human publishes. |

The current `gh pr merge --squash` pattern with `--auto` fallback is standard
practice. The GitHub CLI supports auto-merge via `gh pr merge --auto --squash`
in a single invocation, making the current two-branch logic (try direct, fall
back to auto) slightly redundant. It could be simplified to always use `--auto`
if the repository consistently has branch protection.

---

### 5. Simplification Opportunities

Listed by impact (highest first).

#### S1 — Pass `release-as` as action input (remove config mutation)

**Current**: `plan-release.sh --write-config "$PLAN_CONFIG"` copies and mutates
`release-please-config.json`, injects `release-as`, passes the temp file to the
action.

**Simplified**: keep the Python logic that infers bump type; emit
`force_release_as=true/false` and `next_version`; pass `release-as` directly:

```yaml
- uses: googleapis/release-please-action@...
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    config-file: release-please-config.json
    manifest-file: .release-please-manifest.json
    release-as: ${{ steps.plan.outputs.force_release_as == 'true'
                    && steps.plan.outputs.next_version || '' }}
```

**Removes**: `--write-config` flag, `runner.temp` path, config-file copy step,
file I/O in the Python block, `config_file` output variable.

**Risk**: low. `release-as` input is documented; the action gives it precedence
when set.

---

#### S2 — Simplify auto-merge step

**Current**: try direct merge, parse error string, fall back to `--auto`.

**Simplified**: always use `--auto`:

```yaml
gh pr merge "$pr_number" --squash --auto \
  || echo "::warning::Auto-merge unavailable; merge the release PR manually."
```

Requires "Allow auto-merge" to be enabled in repository settings (it already is
in practice, given the `--auto` fallback path exists). Removes ~10 lines of error
string parsing.

---

#### S3 — Switch trigger from `workflow_run` to `push + paths`

**Current**: `on: workflow_run:` fires after CI completes; custom script guards
against the release commit re-triggering.

**Alternative**:

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'template/**'
      - '.github/agents/**'
      - 'starter-kits/**'
      - 'SETUP.md'
      - 'UPDATE.md'
```

**Gains**:
- Eliminates the `chore(main): release` guard in the script (native `paths:`
  won't match since the release PR only touches `CHANGELOG.md`, `VERSION.md`,
  `.release-please-manifest.json` — none of which are in the paths list).
- Eliminates the `should_release` check entirely.
- Reduces `plan-release.sh` to pure bump-inference logic.

**Loses**:
- The "only run after CI passes" guarantee. The release workflow would fire
  immediately on push, potentially before CI validates the commit.
- If CI fails after the release PR is opened, the PR exists against a broken
  commit.

**Mitigation**: add a CI status check to the release workflow:

```yaml
- name: Wait for CI
  run: |
    gh run list --workflow ci.yml --branch main --limit 1 \
      --json status,conclusion,headSha \
      | jq -e '.[0] | .headSha == "${{ github.sha }}" and .conclusion == "success"'
```

This is fragile (race condition) and adds complexity. The `workflow_run` approach
is architecturally cleaner. **Recommendation: keep `workflow_run`; skip S3.**

---

#### S4 — Move release-loop guard to workflow YAML

If staying on `workflow_run`, the guard can move out of the script into a
workflow-level `if:` condition on the job:

```yaml
jobs:
  release-please:
    if: |
      github.event.workflow_run.conclusion == 'success' &&
      github.event.workflow_run.head_branch == 'main' &&
      !startsWith(github.event.workflow_run.head_commit.message, 'chore(main): release')
```

`github.event.workflow_run.head_commit.message` is available in the event
payload. This removes the guard from `plan-release.sh` entirely, simplifying
the script. However, it introduces a GitHub Actions expression that is harder
to unit-test than bash.

---

### 6. Alternative Tool Assessment

#### Changesets

**Verdict: not suitable.** The intent-file model is designed for multi-package
npm repositories where developers declare release intent alongside code changes.
For a template repo where releases are fully automated and inferred from commit
history, changesets would require every contributor to run `changeset add`
before merging — a significant workflow change with no automation benefit.

#### semantic-release

**Verdict: possible but a regression.** semantic-release would simplify the
toolchain (no custom script, no PR, direct tag on push) but eliminates the
release PR review step, makes it harder to batch changes, and has no native
path filtering. Adding path filtering requires either a pre-check job that
conditionally skips semantic-release, or a custom `@semantic-release/exec` step
— approximately equal complexity to the current custom script. The tool also
has no concept of `VERSION.md` and requires configuring a custom file-updater
plugin.

#### release-drafter

**Verdict: complementary but not a replacement.** Useful as an audit trail of
what will be in the next release. Does not automate versioning or release
creation. Could be layered on top of the current setup for richer draft release
notes, but adds no value to the gating logic.

#### tj-actions/changed-files

**Verdict: viable partial replacement, not a net improvement.** Could replace
the bash `git diff` path-check inside `plan-release.sh`. For a `workflow_run`
trigger, you must pass `sha: ${{ github.event.workflow_run.head_sha }}` to
correctly target the triggering commit. The path-check in `plan-release.sh`
is only ~5 lines of bash; replacing it with an extra action step adds latency
and a third-party dependency with questionable benefit. Keep the current inline
approach.

---

## Recommendations

### Recommended approach: keep current setup, apply S1 + S2

The current `workflow_run` + custom `plan-release.sh` architecture is sound.
No available off-the-shelf tool can replicate the three-way combination of:
- Multi-path consumer gating
- Non-conventional commit bump inference
- Post-CI guarantee

**Apply S1** (remove config mutation, pass `release-as` as action input).
This is a direct simplification with no functional change. The `--write-config`
file-mutation pattern is a workaround for a feature that the action already
exposes natively.

**Apply S2** (simplify auto-merge to always use `--auto`). Minor cleanup,
reduces error-handling surface.

**Do not apply S3** (switching trigger). The architecture benefit of
`workflow_run` outweighs the complexity of the release-loop guard.

**Consider S4** (move guard to workflow YAML `if:`) as a future refactor.
It distributes logic to YAML, which is less testable but more visible. Worth
doing only if `plan-release.sh` is being refactored for other reasons.

### Priority matrix

| Change | Complexity | Benefit | Recommend |
|--------|-----------|---------|-----------|
| S1: release-as as action input | Low | Medium (removes file I/O, fragile mutation) | ✅ Yes |
| S2: always use --auto merge | Very low | Low (cleanup) | ✅ Yes |
| S3: switch to push + paths | High | Low (introduces race condition) | ❌ No |
| S4: move guard to workflow if | Medium | Low (testability tradeoff) | ⬜ Optional |
| Migrate to Changesets | High | Negative (breaks automation) | ❌ No |
| Migrate to semantic-release | High | Neutral (equal complexity) | ❌ No |

---

## Gaps / Further Research Needed

1. **`release-as` empty string behaviour**: does passing `release-as: ''` to the
   action cause it to be treated as "not set" or as an empty override? The
   action README does not document this edge case. Test before shipping S1.

2. **`workflow_run.head_commit.message` availability**: confirm this field
   exists in the `workflow_run` event payload before implementing S4. The
   standard `head_commit` object is documented for `push` events but not
   explicitly for `workflow_run`.

3. **release-please v5**: the repo's `main` branch shows ongoing v5
   development. Review the v5 changelog for native `include-paths` additions
   before any future toolchain review.
