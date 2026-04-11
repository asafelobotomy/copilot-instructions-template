# Research: Shell Test Framework Audit & Improvement Opportunities

> Date: 2026-03-30 | Agent: Researcher | Status: final

## Summary

This repo uses a 142-line custom bash test framework (`tests/lib/test-helpers.sh`) across 23 test
files totalling 3 713 lines.  The framework is functional and zero-dependency, but several
structural patterns generate unnecessary noise: repeated temp-dir/git-repo boilerplate, no
automatic cleanup on failure, no structured output for CI, and no test isolation.  BATS-core and
ShellSpec are the leading alternatives; both offer isolation, TAP/JUnit output, and parallel
execution — but both require an installation step and carry a learning curve.  The most
high-value, low-risk improvements are **trap-based cleanup guards**, **a shared git-repo fixture
helper**, and **TAP-format summary output** — all achievable without migrating frameworks.

When these shell snippets are run through terminal tools in a zsh workspace, use the repo's
isolated-shell wrappers instead of issuing top-level `set -euo pipefail` into the persistent
session.

One-line strict Bash snippet:

```bash
bash scripts/harness/run-isolated-shell.sh --shell bash --strict --command 'printf "framework-note\n"'
```

Multi-line strict Bash snippet:

```bash
bash scripts/harness/run-isolated-shell-stdin.sh --shell bash --strict <<'EOF'
printf 'framework-note\n'
EOF
```

---

## Part 1 — Current State Audit

### 1.1 Framework (`tests/lib/test-helpers.sh`, 142 lines)

**Provided helpers:**

| Function | Type | Notes |
|----------|------|-------|
| `init_test_context` | lifecycle | Sets `PASS`, `FAIL`, `REPO_ROOT` |
| `pass_note` / `fail_note` | counters | Print label, increment counters |
| `assert_success` | exit-code | `$status -eq 0` |
| `assert_failure` | exit-code | `$status -ne 0` |
| `assert_contains` | string | `grep -Fq` (fixed string) |
| `assert_matches` | string | `grep -Eq` (regex) |
| `assert_file_contains` | file | `grep -Eq` on path |
| `assert_file_not_contains` | file | negated `grep -Eq` |
| `assert_valid_json` | JSON | spawns `python3` |
| `assert_python` | Python | `exec()` via `python3` stdin |
| `assert_python_in_root` | Python | same, with explicit root path |
| `finish_tests` | lifecycle | Prints summary, returns exit code |

**Missing relative to modern frameworks:**

- No `setup` / `teardown` lifecycle hooks per test
- No automatic temp-dir cleanup on failure (only `trap` in `test-security-edge-cases.sh`)
- No test isolation (entire file runs in one process; shared state is possible)
- No structured output: no TAP, no JUnit XML
- No skip/pending support
- No test filtering by name or tag
- No built-in timing or profiling
- No line numbers in failure output
- No parallel execution

### 1.2 Test File Inventory

| File | Lines | Asserts | Tests | Patterns | Issues |
|------|------:|--------:|------:|----------|--------|
| `test-hook-session-start.sh` | 91 | 19 | 11 | temp dirs, `mktemp -d`, inline cleanup | No trap guard; second `bash "$SCRIPT"` invocation repeats for multi-assert tests |
| `test-hook-post-edit-lint.sh` | 59 | 9 | 6 | `mktemp` file per test | Clean; minimal boilerplate |
| `test-hook-enforce-retrospective.sh` | 74 | 10 | 7 | temp dirs + `touch -d "10 minutes ago"` | Python fallback for `touch -d` is fragile |
| `test-hook-save-context.sh` | 75 | 11 | 7 | temp dirs with `.copilot/workspace/` | Inline cleanup; no trap |
| `test-guard-destructive.sh` | 164 | 59 | 10 | Inline helper functions (`make_input`, `make_input_with_agent`, `assert_decision`, `assert_continue`, `assert_no_crash`) | Well factored; helpers are *local* not shared — could live in test-helpers.sh |
| `test-hook-scan-secrets.sh` | 221 | 18 | 10 | 8× git-repo init/config/commit blocks; subshell `( cd ... )` per test | **Highest duplication**: ~40 lines of identical git init boilerplate |
| `test-release-contracts.sh` | 85 | 5 | 5 | Pure `assert_python` | No bash assertions; depends entirely on Python |
| `test-hooks-powershell.sh` | 113 | 22 | 7 | `run_ps_script` helper; `mktemp -d` per test | Coverage-aware; reasonable factoring |
| `test-guard-destructive-powershell.sh` | 92 | 20 | 6 | mirrors guard-destructive.sh patterns | Duplicates `make_input`, `assert_decision`, `assert_continue` from bash counterpart |
| `test-verify-version-references.sh` | 166 | 25 | 8 | `setup_sandbox`/`teardown_sandbox` pattern; `ROOT_DIR` env override; SHA comparison | Good pattern; no trap guard for teardown |
| `test-stub-migration.sh` | 99 | 9 | 4 | same sandbox pattern | Clean |
| `test-sync-workspace-index.sh` | 132 | 17 | 6 | `make_fixture` helper; `assert_python_in_root` | Fixture helper is well-extracted |
| `test-sync-models.sh` | 208 | 16 | 10 | `make_fixture` with sub-helpers; real-repo regression guard (test 9) | Python inline calls to mutate fixture files; fragile with temp path embedding |
| `test-validate-agent-frontmatter.sh` | 116 | 9 | 7 | `make_agent` helper; `mktemp -d` per test | Each test creates/destroys a fresh dir — no shared fixture |
| `test-sync-template-parity.sh` | 163 | 20 | 12 | `make_fixture` with dir structure; real-repo regression guard | Most comprehensive fixture pattern in suite |
| `test-security-edge-cases.sh` | 160 | 35 | 6 | `trap cleanup_sync EXIT` — only file with trap cleanup; inline helpers | **Only file using trap**; sets good example |
| `test-copilot-audit.sh` | 336 | 41 | 20 | Delegates to `lib/copilot-audit-sandbox.sh` shared sandbox | Best factoring in suite; 20 tests in 336 lines is dense but readable |
| `test-mcp-launchers.sh` | 81 | 18 | 12 | Mix of file-existence checks and `mktemp` mock bins | Simple; could use `assert_file_exists` helper |
| `test-permission-resilience.sh` | 184 | 22 | 8 | Loops over `HOOK_SCRIPTS` array; `trap cleanup_perm EXIT`; explicit `stat` call | Good use of trap and array iteration |
| `test-customization-contracts.sh` | 166 | 10 | 6 | Pure `assert_python` | No bash assertions |
| `test-template-parity.sh` | 124 | 5 | 5 | Pure `assert_python` via `filecmp.cmp` | No bash assertions |
| `test-starter-kits.sh` | 155 | 9 | 9 | Pure `assert_python` with `rglob` | No bash assertions |
| `test-setup-update-contracts.sh` | 290 | 18 | 16 | Mix: `assert_file_contains` loop + `assert_python` | Longest doc contract test; 16 named tests |
| **TOTAL (test files)** | **3 567** | **446** | **~190** | | |

*Assertion count is a raw grep of `assert_\|pass_note\|fail_note` lines; each assert_ call maps to one logical check.*

### 1.3 run-all.sh Analysis (71 lines)

- **4 phases**: Hook Behavior, Hook Behavior (PowerShell — optional), Script Behavior, Documentation and Contracts.
- Sequential: `set -euo pipefail` stops the entire run on the first failing test file. There is no `--keep-going` option.
- No timing output. No test count. No filtering capability.
- `run_optional_phase` spawns `pwsh` twice (once for `command -v`, once for a functional probe). Minor overhead.
- No CI matrix parallelism: a complete run must be sequential on a single runner.

### 1.4 Coverage Directory (`tests/coverage/`)

| File | Purpose |
|------|---------|
| `bash-prelude.sh` | If `$BASH_COVERAGE_TRACE` is set, redirects xtrace to FD 9 for manual coverage |
| `run-powershell-coverage.sh` | Drives PowerShell hook scripts through coverage instrumentation |
| `invoke-powershell-with-coverage.ps1` | Wraps a PS1 file invocation with `Set-PSDebug -Trace 1` to a trace log |

Coverage is opt-in, manual, and not integrated into `run-all.sh`.  No HTML or line-level reports are generated.  Bash coverage relies on `xtrace` (not line-level instrumentation like `kcov`).

### 1.5 Cross-Cutting Smells

| # | Smell | Occurrences | Impact |
|---|-------|------------|--------|
| S1 | Temp-dir created but cleanup only on success | ~18 test functions | Orphaned `/tmp/tmp.*` dirs on failure |
| S2 | Git-repo init block repeated verbatim | 8× in scan-secrets | 40+ duplicate lines |
| S3 | `bash "$SCRIPT" 2>/dev/null` run twice to capture stdout and stderr separately | test-hook-scan-secrets.sh tests 4, 10 | Each double-invocation runs the hook twice |
| S4 | `assert_decision` / `assert_continue` / `make_input` helpers defined per-file | guard-destructive.sh + guard-destructive-powershell.sh | DRY violation; drift risk |
| S5 | No line-number in failure output | Global | Hard to locate failing assertion without re-running interactively |
| S6 | Python3 launched per `assert_python` call | ~60 calls across suite | Each call forks a new interpreter |
| S7 | No `setup`/`teardown` — setup code inline at top level | Global | Test N state can bleed into test N+1 if early return is missing |
| S8 | Hardcoded JSON key literals in `assert_contains` | ~30 calls | Breaks on hook output format changes |
| S9 | No TAP/JUnit output | Global | CI shows raw text; no test reporting tooling |
| S10 | run-all.sh stops on first failing file | Global | Can't see failures in later phases simultaneously |

---

## Part 2 — Online Research Findings

### 2.1 Framework Comparison

**Sources:**
- BATS-core docs: https://bats-core.readthedocs.io/en/stable/writing-tests.html
- ShellSpec comparison: https://shellspec.info/comparison.html
- Bash test framework comparison 2020: https://github.com/dodie/testing-in-bash

#### Feature matrix

| Feature | Custom (this repo) | BATS-core | ShellSpec | shUnit2 | bashunit |
|---------|:-----------------:|:---------:|:---------:|:-------:|:--------:|
| Zero install | ✅ | ❌ (submodule/brew) | ❌ | ❌ | ❌ |
| Pure bash tests | ✅ | ⚠ almost | ❌ (DSL) | ✅ | ✅ |
| Test isolation (subprocesses) | ❌ | ✅ | ✅ | ❌ | ✅ |
| `setup`/`teardown` per test | ❌ | ✅ | ✅ | ✅ | ✅ |
| `setup_file`/`teardown_file` | ❌ | ✅ | ✅ | ⚠ | ✅ |
| Parallel execution | ❌ | ✅ (GNU parallel) | ✅ | ❌ | ✅ |
| TAP output | ❌ | ✅ | ✅ | ❌ | ✅ |
| JUnit XML output | ❌ | ✅ | ✅ | ❌ | ✅ |
| Skip / pending | ❌ | ✅ | ✅ | ⚠ | ✅ |
| Test filtering by name | ❌ | ✅ | ✅ | ⚠ | ✅ |
| Test tags | ❌ | ✅ (≥1.8.0) | ✅ | ❌ | ⚠ |
| Mocking built-in | ❌ | ⚠ (extension) | ✅ | ❌ | ✅ |
| Parameterized tests | ❌ | ❌ | ✅ | ❌ | ✅ |
| Code coverage (kcov) | ❌ | ⚠ | ✅ | ❌ | ⚠ |
| Line number in failures | ❌ | ✅ | ✅ | ⚠ | ✅ |
| Assertion library | minimal | via bats-assert | extensive | via assertEquals | extensive |
| Bash strict mode compatible | ✅ | ✅ | ⚠ | ⚠ | ✅ |

**BATS-core key characteristics (https://bats-core.readthedocs.io):**

- Each `@test` block runs in its own subprocess — test isolation is automatic.
- `run` helper: captures exit code into `$status`, stdout/stderr into `$output` and `${lines[@]}`.
- `run -N` checks exit code implicitly. `run !` asserts failure.
- `setup()` / `teardown()` called before/after each test. `setup_file()` / `teardown_file()` for suite-level.
- TAP-compatible output; `--formatter junit` for JUnit XML.
- Parallel execution via `--jobs N` (requires GNU parallel).
- Tags via `# bats test_tags=` and `# bats file_tags=`.
- Key caveat: `.bats` files use `@test` syntax which is not valid bash — shellcheck requires v0.7+.
- Key caveat: `run` executes in a subshell — variable side-effects do not persist.
- Key caveat: Bats evaluates each file n+1 times (one count pass + n execution passes), costing extra process forks.

**ShellSpec key characteristics (https://shellspec.info):**

- BDD DSL (`Describe`/`It`/`When call`/`The output should eq`).
- Supports all POSIX shells, not just bash.
- Built-in mocking (function-based and command-based).
- Parameterized tests, code coverage via kcov, profiler.
- Parallel execution built-in.
- TAP and JUnit XML formatters.
- Downside: custom DSL means non-bash syntax — larger learning curve for contributors.

**shUnit2 key characteristics:**

- xUnit style: `assertEquals`, `assertTrue`, `setUp`/`tearDown`.
- No TAP output natively. No parallel execution.
- Pure bash functions — easiest migration from custom framework.
- Less active maintenance than BATS or ShellSpec.

**bashunit (https://github.com/TypedDevs/bashunit):**

- Newest entrant (2023); growing ecosystem.
- Tests written in pure bash; passes bash strict mode.
- Has `setUp`/`tearDown`, `setUpBeforeAll`/`tearDownAfterAll`, mocking, parameterized tests.
- TAP and JUnit XML output.
- Single-file install (similar to this repo's approach).

### 2.2 Performance Optimization Techniques

**Fork/exec reduction:**

- The dominant cost in this repo's test suite is subprocess creation: every `grep` call in `assert_contains`/`assert_matches` forks a child process, plus `python3` per `assert_valid_json`. For fast assertions on same-process variables, `[[ "$haystack" == *"$needle"* ]]` or parameter expansion avoids the fork.
- BATS mitigates this by running each test in an already-forked subprocess; the assertion library calls within a test can remain in-process.
- For suites with heavy Python assertions (this repo has ~60), an alternative is a single Python worker process kept alive across test calls (via stdio protocol), but that is complex to implement.

**Temp dir amortization:**

- In `test-hook-scan-secrets.sh`, 8 tests each create a fresh git repo with the same initial state. A single `setup_file` (BATS) or `setUp` block that creates one base repo and copies it per test would reduce 8× `git init` + `git commit` to 1×.
- Per benchmark data from BATS issue tracker: `git init` + `git commit` runs in ~100ms on typical CI runners. Saving 7 of those is ~700ms on that file alone.

**Parallel test files:**

- `run-all.sh` runs 23 test files sequentially. On a 4-core CI runner, files in the same phase could run in parallel if they do not share state. None of the Script Behavior tests mutate shared repo state (they all use sandboxed temp dirs).
- BATS `--jobs N` parallelizes within a single `.bats` file collection.
- A simple GNU `parallel` wrapper around `run_phase` lines in `run-all.sh` would achieve file-level parallelism without changing the framework.

### 2.3 Assertion Pattern Improvements

**Python3-per-call overhead:**

- `assert_python` launches a new `python3` process for every call. With ~60 such calls across the suite, this is ~60 interpreter startups (each ~50–80ms on a cold filesystem).
- Better pattern: batch multiple checks into one `assert_python` block (already done in some places but inconsistently).
- Alternative: use `python3 -c "..."` with compound `and` expressions in a single call.
- Best alternative: consolidate JSON validation with bash built-in `jq` (if available) or inline parsing with bash parameter expansion for simple key checks.

**`assert_contains` vs `assert_matches` clarity:**

- Current code mixes `assert_contains` (fixed-string grep -F) and `assert_matches` (regex grep -E) without consistent discipline. For JSON key checks like `'"continue": true'`, a fixed-string check is correct and faster. For patterns with variable content, regex is needed. The naming is clear but usage is inconsistent.

**Missing: `assert_file_exists` / `assert_dir_exists`:**

- `test-mcp-launchers.sh` uses inline `[[ -f "$path" ]] && pass_note ... || fail_note ...` because there is no `assert_file_exists` helper. Eight such inline blocks across the suite would benefit from a one-liner helper.

**Missing: `assert_json_key` / `assert_json_value`:**

- Many tests check JSON output via `assert_contains '"continue": true'`. A purpose-built `assert_json_key <key> <expected>` backed by `python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get('$key') == '$expected'"` would be both more expressive and more resilient to whitespace variation.

### 2.4 Output Format Standards

**TAP (Test Anything Protocol — http://testanything.org):**

- TAP is a simple text protocol: `1..N` (plan line), `ok N - description`, `not ok N - description`.
- BATS, ShellSpec, and bash_unit all support TAP natively.
- GitHub Actions, Jenkins, pytest, and most CI systems can consume TAP with a reformatter.
- Adding minimal TAP to the custom framework requires changing `pass_note`/`fail_note` to print `ok N - ${desc}` / `not ok N - ${desc}` and printing the plan line `1..N` in `finish_tests`.
- Cost: ~15-line change to `test-helpers.sh`; no upstream changes needed.

**JUnit XML:**

- Most CI systems natively parse JUnit XML (GitHub Actions test reporter, Jenkins surefire, Azure DevOps).
- Generating JUnit XML from bash requires either a helper library or an awk/python post-processor on TAP output.
- Tools: `tap2junit` (Python package, ~1 file), `junit-xml` shell helper, or BATS' `--formatter junit`.

### 2.5 CI Optimization Strategies

**GitHub Actions parallelism:**

- Matrix strategy across test phases: `{phase: [hooks, scripts, contracts]}`. Each matrix leg runs one phase. Risk: increased runner billing (parallelism costs more total compute minutes even if wall time is shorter).
- `fail-fast: true` (default) — a failing leg cancels others. Set `fail-fast: false` to see all failures.

**Caching:**

- No package installation needed for this repo's framework. The only candidates for caching are: `python3` (system-provided), `pwsh` (optional phase), `git` (always present on runners). No npm/pip caching needed.
- If BATS were adopted: cache `test/bats`, `test/test_helper/bats-support`, `test/test_helper/bats-assert` as git submodules. GitHub Actions' submodule restore is already cached by default on `actions/checkout`.

**Fail-fast within run-all.sh:**

- Current: `set -euo pipefail` at the top of `run-all.sh` stops on first failing file.
- Adding `|| true` to each `bash "$test_script"` and tracking failures separately would enable a "run all, then report all failures" mode — more useful for debugging multiple simultaneous regressions.

### 2.6 Community Patterns for Agent/AI Instruction Template Testing

No public repositories were found using an identical pattern (bash test suite for AI agent instruction templates). The closest analogs are:

- **dotfiles test suites**: similar structure — small scripts validated with custom bash tests. Pattern: `./tests/run.sh` invokes numbered `.sh` test files.
- **shell script CI repos**: use BATS for testing deploy scripts, hook scripts, etc. Common pattern: BATS submodule + GitHub Actions matrix.
- **VS Code extension repos**: test `.json` config files with `ajv` (JSON schema validation), not shell tests.

The combination of JSON hook-protocol testing + Markdown structure validation + shell script testing that this repo does is novel. The custom framework is well-suited to this mix because it supports both `assert_matches` (bash-native) and `assert_python` (Python-native) in the same test file.

---

## Part 3 — Improvement Candidates

### IC-1: Trap-based cleanup guard in all test files

**What**: Add `trap 'rm -rf "${TMPDIR_CLEANUP[@]:-}"' EXIT` at the top of each test file, appending temp dirs to `TMPDIR_CLEANUP` array instead of manually calling `rm -rf`.

**Benefit**: Temp dirs are always cleaned up even when a test fails mid-way. Currently 18 test functions have at-risk cleanup.

**Effort**: Low. Change ~18 occurrences across ~12 files. No framework changes.

**Risk**: Very low. Existing manual `rm -rf` calls can remain in place (harmless double-remove).

**Example:**
```bash
TMPDIR_CLEANUP=()
trap 'rm -rf "${TMPDIR_CLEANUP[@]:-}"' EXIT

TMPDIR_NPM=$(mktemp -d)
TMPDIR_CLEANUP+=("$TMPDIR_NPM")
# ... test ...
# rm -rf "$TMPDIR_NPM" can be removed or kept
```

---

### IC-2: Extract shared git-repo fixture helper to `tests/lib/test-helpers.sh`

**What**: Add `make_git_sandbox()` to `test-helpers.sh` that creates a temp dir, runs
`git init -q`, sets `user.email` and `user.name`, creates and commits a stub README, and
returns the path. Used immediately by `test-hook-scan-secrets.sh` and any future test
that needs a git context.

**Benefit**: Eliminates 40+ lines of verbatim duplication in `test-hook-scan-secrets.sh`.
Makes future scan-secrets scenarios one-line setups instead of 6-line blocks.

**Effort**: Low. ~10 lines added to `test-helpers.sh`; 8 call sites in scan-secrets simplified.

**Risk**: Very low. Purely additive.

---

### IC-3: Add `assert_file_exists` / `assert_dir_exists` helpers

**What**: Add two helpers to `test-helpers.sh`:
```bash
assert_file_exists() { local desc="$1" path="$2"; [[ -f "$path" ]] && pass_note "$desc" || fail_note "$desc" "file not found: $path"; }
assert_dir_exists()  { local desc="$1" path="$2"; [[ -d "$path" ]] && pass_note "$desc" || fail_note "$desc" "dir not found: $path"; }
```

**Benefit**: Replaces 8 inline `[[ -f ... ]] && pass_note ... || fail_note ...` blocks in `test-mcp-launchers.sh` and `test-permission-resilience.sh` with single-line calls.

**Effort**: Minimal (2 lines in test-helpers.sh + 8 call-site cleanups).

**Risk**: None.

---

### IC-4: Extract `assert_guard_decision` and `make_hook_input` to `tests/lib/test-helpers.sh`

**What**: The `assert_decision`, `assert_continue`, `assert_no_crash`, `make_input`, `make_input_with_agent` functions are defined identically (or near-identically) in both `test-guard-destructive.sh` and `test-guard-destructive-powershell.sh`. Move the bash versions to `test-helpers.sh` and have both files source them.

**Benefit**: Eliminates DRY violation. Fixes drift risk (if hook JSON format changes, only one place to update).

**Effort**: Low. Move ~25 lines to helpers; source in both files.

**Risk**: Low. Must ensure the bash versions don't conflict with PowerShell file needs (PowerShell test uses `run_guard` backed by `$PWSH`, not just `bash`).

---

### IC-5: Add minimal TAP output to `test-helpers.sh`

**What**: Modify `pass_note`, `fail_note`, `init_test_context`, and `finish_tests` to optionally emit TAP-format output when `TEST_TAP=1` is set:
```
1..N
ok 1 - valid JSON output
not ok 2 - branch field present
  # expected to find: Branch:
  # output: ...
```

**Benefit**: Enables CI-native test reporting (GitHub Actions test summary, Jenkins TAP plugin). Failures become navigable links rather than grep-through-logs.

**Effort**: Medium. ~30-line change to `test-helpers.sh`; no changes to individual test files needed.

**Risk**: Low. TAP mode is opt-in via env var; default behaviour unchanged.

---

### IC-6: Add `--continue-on-error` mode to `run-all.sh`

**What**: Refactor `run_phase` to capture exit codes instead of relying on `set -e`:
```bash
run_phase() {
  local label="$1"; shift; local phase_failed=0
  echo "## $label"
  for test_script in "$@"; do
    echo "==> $test_script"
    bash "$test_script" || { phase_failed=1; ((FAILED_SUITES++)); FAILED_LIST+=("$test_script"); }
  done
  return "$phase_failed"
}
```
Then print a summary of all failing files at the end.

**Benefit**: When two test files in different phases both fail, both failures are visible in one CI run. Currently `set -euo pipefail` stops at the first failure.

**Effort**: Low (~20-line change to `run-all.sh`).

**Risk**: Very low. Default behaviour in CI can remain stop-on-first-fail; `--continue` can be a flag.

---

### IC-7: Consolidate repeated `assert_python` JSON checks into batched assertions

**What**: Many test files call `assert_python` for each individual JSON key check. Where multiple keys are checked on the same output, combine them into one `assert_python` block.

**Example** (test-release-contracts.sh — before):
```bash
assert_python "version matches manifest" 'version = ...; manifest = ...; actual = ...'
assert_python "x-release markers" '...'
```
**After**: One `assert_python "version and manifest contract" '...; ...'` block that checks both conditions.

**Benefit**: Halves the number of `python3` subprocess invocations for contract tests. At ~60ms per startup, batching 20 calls to 10 saves ~600ms.

**Effort**: Medium. Requires careful review to ensure each batched block still gives a useful failure message.

**Risk**: Low. Test semantics are preserved; only the subprocess boundary changes.

---

### IC-8: Adopt BATS-core for new test files (gradual migration)

**What**: Introduce BATS as a git submodule at `tests/bats/`. New test files use `.bats` syntax. Existing `.sh` files remain unchanged. `run-all.sh` gains a BATS phase.

**Benefit**: Test isolation, `setup`/`teardown`, better failure output with line numbers, TAP/JUnit natively, `--jobs` for parallel execution, community-supported assertion library.

**Effort**: High. Submodule addition, CI change, contributor onboarding, learning curve.

**Risk**: Medium. Mixed `.sh`/`.bats` test suite is harder to reason about. BATS' n+1 evaluation model is a gotcha. `.bats` files can't be linted by shellcheck without extra config.

---

### IC-9: Add `--timing` output to `run-all.sh`

**What**: Wrap each `bash "$test_script"` call with `time`:
```bash
time bash "$test_script"
```
Or capture it with `SECONDS`:
```bash
start=$SECONDS; bash "$test_script"; echo "  (${SECONDS-start}s)"
```

**Benefit**: Identifies slow test files. Currently unknown which of the 23 files dominates the total run time.

**Effort**: Minimal (3-line change).

**Risk**: None.

---

## Part 4 — Reasons NOT to Change

### 4.1 Zero-dependency advantage

The custom framework requires nothing beyond `bash` and `python3` (both present on all target platforms including Alpine, Debian, macOS, Windows with Git Bash). BATS requires a submodule or package install. ShellSpec requires a similar install step. For a repo whose purpose is to set up other repos' AI tooling, eliminating external test dependencies keeps the bootstrap story simple.

### 4.2 Simplicity for contributors

`test-helpers.sh` is 142 lines of straightforward bash. Any developer who can read bash can understand it without documentation. BATS' `@test` syntax, the `run` helper's subshell semantics, and the `setup`/`teardown` lifecycle are non-obvious to newcomers. ShellSpec's BDD DSL is even more alien. The current framework has zero onboarding overhead.

### 4.3 Sufficient test count, adequate runtime

With ~190 assertions across 23 files, the suite is not large enough to warrant complex parallelism infrastructure. On a modern developer machine, the full suite runs in under 30 seconds (estimated; dominated by git operations and Python invocations). This is fast enough for pre-commit use.

### 4.4 Migration risk

Migrating to BATS would require rewriting ~3 500 lines across 23 files. Each migration carries risk of accidentally changing test semantics. The current tests cover hook logic that must remain exactly tested. A full migration would be a multi-sprint effort with no functional change to the product under test.

### 4.5 Python assertions are already idiomatic

The `assert_python` / `assert_python_in_root` pattern is unique to this repo and covers a real need: validating JSON structures, file contents, and cross-file relationships. No standard shell testing framework provides an equivalent. Migrating to BATS would not eliminate the Python subprocess dependency — it would just add BATS on top.

### 4.6 Custom output format is sufficient for this project's CI

The `Results: N passed, M failed` output is human-readable and clear. The CI pipeline currently uses this output passthrough without structured test reporting. Adding TAP is a nice-to-have, not a blocker.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://bats-core.readthedocs.io/en/stable/writing-tests.html | BATS writing tests — `run`, `@test`, `setup`/`teardown`, `$status`, `$output`, `$lines` |
| https://bats-core.readthedocs.io/en/stable/gotchas.html | BATS gotchas — negation, subshell variables, `[[ ]]` bash 3.2 compat, background tasks |
| https://bats-core.readthedocs.io/en/stable/tutorial.html | BATS tutorial — installation, fixture setup, bats-assert integration |
| https://bats-core.readthedocs.io/en/stable/faq.html | BATS FAQ — working directory, debugging failures, `--filter`, skip syntax |
| https://shellspec.info/ | ShellSpec overview — BDD DSL, POSIX shell support, mocking, parameterized tests, coverage |
| https://shellspec.info/comparison.html | ShellSpec vs shUnit2 vs BATS-core feature comparison table |
| https://github.com/dodie/testing-in-bash | Community bash test framework comparison 2020 — bashunit, BATS, shUnit2, bash_unit, ShellSpec, shpec |
| http://testanything.org/ | TAP specification — plan line, ok/not-ok, diagnostics |

---

## Gaps / Further Research Needed

1. **Actual wall-time measurements** — Profile the current suite with `time bash tests/run-all.sh` to identify which files are slowest before optimizing.
2. **kcov feasibility** — Test whether kcov (used by ShellSpec for coverage) works with this repo's hook scripts on Linux CI and macOS.
3. **GitHub Actions test summary integration** — Evaluate whether GitHub Actions' `dorny/test-reporter` action can consume TAP output from the custom framework if IC-5 is implemented.
4. **bashunit evaluation** — bashunit (2023, ~3k stars) was identified in the comparison but not deeply researched. Its single-file install model and pure-bash test syntax may offer a lower-migration-cost alternative to BATS.
