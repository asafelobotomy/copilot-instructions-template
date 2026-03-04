# Test Coverage Review — Human Guide

> **What is it?** A structured code-health audit that Copilot performs on demand —
> scanning your repository for test gaps, measuring current coverage, and
> recommending both local tests to write and GitHub Actions workflows to add.

---

## How to trigger it

Say any of the following in a Copilot chat in your project:

- *"Review my tests"*
- *"What tests should I add?"*
- *"Check test coverage"*
- *"Repo health review"*
- *"Recommend CI tests"*
- *"What CI workflows should I add?"*

No flags, no arguments — Copilot takes it from there.

---

## What Copilot needs from you

Copilot chat cannot run terminal commands directly.
After identifying your test runner, it will ask you to run a coverage command and paste the output. Example for common stacks:

| Stack | Command to run and paste |
|-------|--------------------------|
| Jest (JS/TS) | `npx jest --coverage` |
| Vitest | `npx vitest run --coverage` |
| pytest | `pytest --cov=. --cov-report=term-missing` |
| Go | `go test ./... -coverprofile=cov.out && go tool cover -func=cov.out` |
| Rust | `cargo tarpaulin --out Lcov` |
| .NET | `dotnet test --collect:"XPlat Code Coverage"` |
| Java (Maven) | `mvn test jacoco:report` |
| Java (Gradle) | `./gradlew test jacocoTestReport` |

If you haven't set up coverage tooling yet, Copilot will do a static analysis
(scanning for test files vs. source files) and tell you what to install.

---

## What Copilot does (seven steps)

### Step 0 — Discover test stack

Reads test config files (`jest.config.*`, `pytest.ini`, `Cargo.toml`, etc.) and
your existing CI workflows to identify the framework and coverage command.

### Step 1 — Get coverage data

Asks you to run and paste the coverage command output. If no tooling is
configured, moves to static scan only and flags the gap.

### Step 2 — Scan test files statically

Counts test files, lists source files with no corresponding test file, and
notes which modules are most imported (highest-value candidates for testing).

### Step 3 — Identify gaps

Classifies every module into:

- **Zero coverage** — no tests at all
- **Low coverage** — < 50% line coverage
- **Missing test types** — no integration / edge-case / error-path tests

### Step 4 — Recommend local tests

For each gap, recommends what to test, what type of test (unit, integration,
property-based, snapshot), and the priority (critical / high / medium / low).

### Step 5 — Recommend CI workflows

Proposes specific GitHub Actions with ready-to-copy YAML snippets:

- **Coverage gate** — fail PR if overall coverage drops
- **Coverage diff comments** — post coverage change as a PR comment
- **Nightly full run** — slower suites on a schedule
- **Test matrix** — multiple runtime versions
- **Mutation testing** — verify test *quality*, not just line coverage
- **Contract / API tests** — validate API contracts don't break consumers

### Step 6 — Present report

Delivers a structured markdown report in chat covering all of the above,
grouped into: ✅ Well-covered · ⚠️ Partial · ❌ Untested, plus tables of
recommended tests and copy-paste workflow YAML.

### Step 7 — Wait

Copilot presents the report and waits. It does **not** write any test files
or workflow files until you explicitly say so.

---

## What it WON'T do

- Write test files or CI workflows automatically — you decide what to apply
- Run commands on your machine — it asks you to run them and paste output
- Enforce a coverage threshold — it recommends one; you set the gate
- Replace a full CI setup — it complements it

---

## Understanding the report

```markdown
## Test Coverage Review — MyProject

### 📊 Current coverage snapshot
- Framework: Jest | Runner: `npx jest --coverage`
- Overall coverage: 61%
- Test files: 12 | Source files without tests: 4

### ✅ Well-covered (≥ 80%)
- src/utils.ts — 94%
- src/parser.ts — 88%

### ⚠️ Partially covered (20–79%)
- src/api.ts — 54% — missing: error branch line 42, rate-limit path

### ❌ Untested or near-zero (< 20%)
- src/auth.ts — 0%  ← critical: handles user credentials

### 🧪 Recommended local tests
| File       | Type | Priority | What to cover              |
|------------|------|----------|----------------------------|
| src/auth.ts | Unit | critical | Token validation, expiry   |
| src/api.ts  | Unit | high     | Error branch at line 42    |

### ⚙️ Recommended CI workflows
**Coverage gate** (copy to .github/workflows/coverage.yml):
\'\'\'yaml
name: Coverage gate
on: [pull_request]
jobs:
  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4
        with: { node-version: 20 }
      - run: npm ci
      - run: npx jest --coverage
      - uses: codecov/codecov-action@b9fd7d16f6d7d1b5d2bec1a2887e65ceed900238 # v4
        with:
          fail_ci_if_error: true
          token: ${{ secrets.CODECOV_TOKEN }}
\'\'\'

### ℹ️ Notes
- No mutation testing configured — consider Stryker for JS/TS
- auth.ts handles user input with no test coverage — highest priority
```

---

## Applying recommendations

After reviewing the report, you can say things like:

- *"Write the coverage gate workflow"* — Copilot writes the YAML file
- *"Write unit tests for src/auth.ts"* — Copilot writes the test file
- *"Install pytest-cov and set up coverage"* — Copilot configures coverage tooling
- *"Add a Codecov badge to the README"* — Copilot adds the badge and setup instructions
- *"Apply all CI recommendations"* — Copilot writes all suggested workflow files

---

*Back to [README.md](../README.md) · [AGENTS-GUIDE.md](AGENTS-GUIDE.md)*
