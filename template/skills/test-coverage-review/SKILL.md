---
name: test-coverage-review
description: Audit test coverage, identify gaps, and recommend local tests plus CI workflows
compatibility: ">=3.2"
---

# Test Coverage Review

> Skill metadata: version "1.0"; license MIT; tags [tests, coverage, ci, review, quality]; compatibility ">=3.2"; recommended tools [codebase, runCommands, githubRepo].

Review the current project's test coverage posture and recommend what to test next, what coverage tooling is missing, and which CI workflows would add the most value.

## When to use

- User asks to "review my tests", "check test coverage", or "what tests should I add"
- User wants help identifying untested code or CI coverage recommendations

## When NOT to use

- User asked for a specific test file to be written
- Task is to fix a single failing test

## Steps

1. **Discover test stack** — Detect runners and coverage tooling from config files, manifests, CI.

2. **Get coverage output** — If coverage command exists, ask user to run it and paste output.

3. **Static analysis fallback** — If no coverage tooling, scan for source/test files and obvious gaps.

4. **Identify gaps** — Classify: zero coverage, low coverage (<50%), missing test types (integration, edge-case, error-path).

5. **Recommend local tests** — Per gap: file/module, test type (unit/integration/e2e/property/snapshot), priority (critical/high/medium/low), brief description.

6. **Recommend CI workflows** — Coverage gate, diff comments, nightly suite, runtime matrix, mutation testing, contract tests.

7. **Present report** — Sections: current snapshot, well-covered, partially covered, untested, recommended tests, recommended CI, notes.

8. **Wait** — Do not write tests, workflows, or config until user asks.

## Verify

- [ ] Test stack detection tied to real repo signals
- [ ] Coverage output requested when tooling exists
- [ ] Static analysis distinguishes assumptions from measurements
- [ ] Recommendations prioritized by impact and risk
- [ ] Nothing written automatically
