# Research: Optimal Test Execution Strategies for Iterative Development

> Date: 2026-04-12 | Agent: Researcher | Status: final

## Summary

Running full test suites after every change is a well-documented productivity antipattern.
Decades of research and industry practice at Google, Meta/Facebook, and Microsoft converge on
a tiered model: fast targeted tests run immediately after changes; broader suites run
asynchronously or periodically; full suites gate commits or releases. ML-based predictive
selection (Meta's approach) can run as few as one-third of tests while catching >99.9% of
regressions. For a bash-based suite of 47 tests, the practical answer is a
path-to-test mapping with a targeted tier, a pre-commit tier, and a full-suite gate before
marking work complete.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://devblogs.microsoft.com/devops/accelerated-continuous-testing-with-test-impact-analysis-part-1/ | Microsoft TIA — what it is, when to apply, how it works |
| https://engineering.fb.com/2018/11/21/developer-tools/predictive-test-selection/ | Meta predictive test selection — ML approach, 99.9% accuracy, 3x efficiency |
| https://engineering.fb.com/2026/02/11/developer-tools/the-death-of-traditional-testing-agentic-development-jit-testing-revival/ | Meta JiTTesting — LLM-generated tests for AI agent workflows |
| https://abseil.io/resources/swe-book/html/ch23.html | Google SWE Book Ch.23 — TAP, presubmit/post-submit strategy, 11-min avg wait |
| https://martinfowler.com/articles/practical-test-pyramid.html | Test Pyramid — canonical guide on layered testing strategy |
| https://www.nngroup.com/articles/response-times-3-important-limits/ | Nielsen's 10-second rule — cognitive basis for test feedback timing |
| https://testmon.org/ | pytest-testmon — incremental test selection via Coverage.py |
| https://github.com/tarpas/pytest-testmon | pytest-testmon source — 965 stars, Python 3.10+, Coverage.py based |
| https://aider.chat/docs/usage/lint-test.html | Aider lint/test integration — --auto-test, --test-cmd, agent self-repair loop |
| https://www.swebench.com/ | SWE-bench — AI agent benchmark; current SOTA ~76.8% on Verified |
| https://arxiv.org/abs/2310.06770 | SWE-bench paper — original 2023 benchmark, 2294 GitHub issues |
| https://arxiv.org/abs/1810.05286 | Meta predictive test selection paper (cited by FB blog) |

---

## Findings

### 1. Test Impact Analysis (TIA)

**What it is:** TIA runs only the tests that are directly impacted by a specific code change,
determined by tracing which source files each test transitively depends on.

**Microsoft's implementation (Azure DevOps / Visual Studio Test task v2):**
- Enabled via "Run only impacted tests" in VSTest v2 task
- Maintains a dependency database mapping source files to tests via instrumentation
- Automatically includes: (a) impacted tests, (b) previously failing tests, (c) newly added tests
- Recommended only when a full test run takes >15 minutes (overhead pays off at that threshold)
- Supports Git, GitHub, TFVC; requires managed .NET code; does **not** yet support .NET Core (2017 post)
- Source: https://devblogs.microsoft.com/devops/accelerated-continuous-testing-with-test-impact-analysis-part-1/

**Google's TAP (Test Automation Platform):**
- Handles >50,000 unique code changes per day; runs >4 billion individual test cases per day
- Uses a near-real-time global dependency graph (maintained by Forge/Blaze build tools) to determine which tests are downstream of any change
- Average submit wait time: ~11 minutes, run in the background while engineers continue working
- Changes that pass presubmit have a "95%+" likelihood of passing all tests (empirical)
- Engineers write a fast presubmit subset (usually unit tests); TAP runs the broader suite asynchronously post-submit
- Source: https://abseil.io/resources/swe-book/html/ch23.html

**Open-source implementations:**
- `pytest-testmon`: Python-only, uses Coverage.py to build a dependency map; ~965 GitHub stars; v2.2.0 (Dec 2025)
  - `pytest --testmon` on first run builds the `.testmondata` database
  - Subsequent runs automatically select only affected tests
  - Works with `pytest-watch` for continuous watch-mode execution
  - Tracks: source code changes, environment variables, Python version, third-party package versions
  - Does NOT track: static files (txt/xml/assets), external network services
  - Source: https://testmon.org/
- `jest --onlyChanged` / `--changedSince`: built into Jest; uses Git-based heuristics rather than instrumentation
- `cargo test --test-threads` + incremental compilation: Rust's `cargo` does compile-level TIA natively
- **Bash/shell scripts**: No general-purpose TIA tool exists; the `select-targeted-tests.sh` pattern
  (as used in this very repo) is the practical equivalent — a path-to-test mapping in JSON,
  consulted by the harness to select only suites relevant to changed files.

**Concrete numbers:**
- No published efficiency figure from Microsoft's TIA blog; Google TAP's approach cuts test
  execution to "the minimal set" without a specific percentage claim in the SWE Book chapter
- Meta's ML-based approach (§2 below) outperforms dependency-graph TIA numerically

---

### 2. Predictive Test Selection (ML-Based)

**Meta/Facebook (2018, still in production):**
- Model: gradient-boosted decision-tree (explainable, easy to train, fits existing ML infra)
- Training data: large dataset of historical code changes + test outcomes
- Features: abstracted representations of code changes; model learns which changes co-occur
  with which test failures
- Production results (as of Nov 2018 blog post; running for >1 year at that time):
  - **Catches >99.9% of all regressions** before they reach trunk code
  - **Runs only 1/3 of transitively-impacted tests** (vs. previous build-dependency approach selecting ~25% of all tests — itself already a reduction)
  - **Doubles efficiency** of testing infrastructure
- Key insight: instead of asking "could this test be impacted?" (build dependency TIA), the model asks "what is the probability this test will actually fail?"
- Handles test flakiness by aggressively retrying failed tests during training data collection, distinguishing true regressions from flaky failures
- Model is regularly retrained on recent changes as codebase evolves
- Accuracy requirement in production: >95% prediction accuracy; catch at least one failing test for >99.9% of problematic changes
- Paper: https://arxiv.org/abs/1810.05286
- Source: https://engineering.fb.com/2018/11/21/developer-tools/predictive-test-selection/

**Launchable (acquired by CloudBees ~2024):**
- Commercial SaaS implementing predictive test selection; supports Java, Python, Ruby, Go, and others
- Applies ML trained on per-project historical test data
- Typical advertised savings: "reduce CI time by 80% while catching 95% of failures" (marketing claims)
- Uses a client-side CLI that sends change metadata to the Launchable API to receive an ordered/filtered test list
- Applicable to any test framework that can produce a list of tests to run
- Note: Launchable's blog was migrated to cloudbees.com after acquisition; original URLs redirected

**Spotify's test intelligence:**
- Less publicly documented than Meta's; Spotify Engineering has referenced "test prioritization"
  within their CI systems, ordering tests by historical failure rate and change relevance
- No concrete percentage numbers were published in accessible public sources as of this research date

**Academic research:**
- The field is called "Regression Test Selection" (RTS) or "Test Case Prioritization" (TCP)
- Key result from Elbaum et al. (2014, cited widely): average-case TCP techniques can expose
  faults 20-50% earlier in test execution order compared to random ordering
- Safe RTS (never excludes a test that would fail) vs. unsafe RTS (excludes some improbable failures) — Meta's approach is "unsafe" (probabilistic) but calibrated to 99.9% recall

---

### 3. The Test Pyramid and Execution Tiers

**Mike Cohn's original pyramid (Succeeding with Agile):** Unit → Service → UI

**Martin Fowler's practical interpretation:**
- Write many small, fast unit tests
- Write some coarse-grained integration tests
- Write very few high-level end-to-end tests
- The pyramid shape prevents "ice cream cone" anti-pattern (inverted pyramid: mostly E2E)
- Key rule: "Push tests as far down the test pyramid as you can"
- Key rule: "If a higher-level test spots an error and there's no lower-level test failing, write a lower-level test"
- "Every single test in your test suite is additional baggage and doesn't come for free"
- Source: https://martinfowler.com/articles/practical-test-pyramid.html

**Speed differences between tiers (indicative, not from a single study):**
- Unit tests: milliseconds each; thousands per minute on modern hardware
- Integration tests: seconds each; includes DB spin-up, HTTP calls
- E2E / UI tests: 10s–minutes each; browser/process launch overhead; high flake rate
- Bash script tests (this repo): intermediate — no I/O to stub out, but process launch per suite adds overhead

**Google's size taxonomy (from SWE Book Ch.11, referenced in Ch.23):**
- Small tests (unit-equivalent): must complete in <1 minute; run thousands
- Medium tests (integration-equivalent): complete in <5 minutes
- Large tests (E2E-equivalent): no time limit; run sparingly

**Recommended ratio (Google's empirical guidance):**
- "Most teams at Google run their small tests (like unit tests) on presubmit"
- "Whether and how to run larger-scoped tests on presubmit is the more interesting question"
- Google Assistant case: going fully hermetic on presubmit cut runtime by **14x** with "virtually no flakiness"

---

### 4. When to Run Which Tests — Evidence-Based Guidelines

| Trigger | Recommended tier | Rationale |
|---------|-----------------|-----------|
| After single file edit (local) | Path-targeted tests only | Immediate signal; respects the 10-second attention limit (§5) |
| After multi-file refactor (local) | Targeted + affected suite | Broader surface; still avoid full suite |
| Before commit (pre-commit hook) | Fast presubmit subset | Google: 95%+ pass rate on full suite if presubmit passes |
| Before push (pre-push hook) | Broader/full targeted suite | Catch what presubmit missed before sharing with team |
| In CI (post-submit/PR) | Full suite + slow tests | Async; engineer not blocked; catches mid-air collisions |
| Periodic (nightly/weekly) | Full suite including all tiers | Catch integration drift; reset baseline |

**Google Takeout case study (concrete lessons):**
- Tests moved "after nightly deploy" → presubmit: prevented **95% of broken servers** from bad configuration; reduced nightly deployment failures by **50%**
- End-to-end tests moved from "after nightly deploy" → "post-submit within 2 hours": cut the culprit set by **12x** (12 hours of changes → 2 hours of changes)
- Source: https://abseil.io/resources/swe-book/html/ch23.html

**Microsoft TIA guideline:**
- Apply TIA only when full test runs take >15 minutes (TIA has its own overhead)
- Always run all tests at a configured periodicity (e.g., nightly) regardless of TIA

---

### 5. Test Execution Time Benchmarks and the Attention Threshold

**Nielsen's Three Response Time Limits (1993, still valid as of 2026):**
- **0.1 seconds**: user feels direct manipulation; system reacts "instantaneously"
- **1.0 second**: upper limit for uninterrupted flow of thought; user notices delay but doesn't lose context
- **10 seconds**: limit for keeping the user's **attention focused on the dialogue**; beyond this, user will want to do other tasks while waiting; reorientation required on return
- Source: https://www.nngroup.com/articles/response-times-3-important-limits/

**Application to test feedback loops:**
- The "10-second rule" for tests: any targeted test run that fits in <10 seconds keeps the engineer in flow
- A full suite taking >10 seconds should not block the edit-save-test inner loop
- Google's 11-minute average presubmit time works because it runs asynchronously (engineer doesn't wait)

**Practical thresholds used in industry:**
- <10s: inner-loop targeted tests (run synchronously, block the developer)
- 10s–5min: pre-commit / pre-push gate (acceptable blocking for a deliberate boundary crossing)
- 5–30min: CI post-submit (fully async; engineer continues working)
- >30min: release candidate testing / nightly (batch)

**Context switching cost:**
- Microsoft Research (Iqbal & Bailey, various studies) and Gloria Mark's work estimate 10–23 minutes
  to fully recover deep focus after an interruption — cited extensively in productivity literature
  though the exact source varies by publication. The conservative version (10 min) is consistent
  with research on developer interruption patterns.
- Implication: a test run that forces active waiting for >1 minute represents a context switch cost
  orders of magnitude larger than the wait itself.

---

### 6. Incremental and Watch-Mode Testing

**pytest-testmon (Python):**
- Mechanism: Coverage.py instruments every test run, building a mapping of which source lines each test touches; subsequent runs compare the changed files against this map
- `pip install pytest-testmon && pytest --testmon` — first run builds DB; subsequent runs auto-select
- `--testmon-noselect`: reorders tests by failure probability without deselecting any (safe mode)
- Limitations: does not track static files or network services; may select "too many" tests when a method signature changes (entire module hierarchy is marked changed)
- Works with `pytest-watch` for file-save-triggered re-execution
- Stars: 965 (GitHub); maintained; v2.2.0 released Dec 2025

**Jest --watch / --watchAll (JavaScript/TypeScript):**
- `jest --watch`: only runs tests related to changed files (Git-based); interactive filter mode
- `jest --watchAll`: runs all tests on every change — the antipattern to avoid
- `jest --onlyChanged`: CI-friendly single-run equivalent of --watch
- `jest --changedSince=<branch>`: tests affected by changes since a branch divergence

**cargo test (Rust):**
- Rust's incremental compiler (`-C incremental`) prevents recompilation of unchanged crates
- `cargo nextest run` (nextest): parallel test runner with per-test caching and retry support
- Faster than default `cargo test` for large projects; built-in "run only changed" when combined with git status

**Bash/shell scripts (this repo's context):**
- No general instrumentation layer like Coverage.py exists for bash
- The `scripts/harness/select-targeted-tests.sh` + `targeted-test-map.json` pattern implements
  manual TIA: a path-to-suite mapping maintained by developers
- This is the correct approach for shell-based test suites — instrumentation overhead would exceed savings
- Practical recommendation: maintain the targeted-test-map.json as test-to-file coverage mapping grows

---

### 7. AI Agent-Specific Test Strategies

**The fundamental tension for AI coding agents:**
- AI agents change files faster than a human; running full suites after every AI edit would be
  prohibitively slow (e.g., an agentic loop making 20 edits would run the full suite 20 times)
- AI agents also make more mistakes per edit than humans on average; early test feedback is
  especially valuable to prevent error accumulation

**Meta's JiTTesting (Just-in-Time Testing) — February 2026:**
- Key claim: "Agentic development dramatically increases the pace of code change, straining test
  development burden and scaling the cost of false positives and test maintenance to breaking point"
- JiTTests are **LLM-generated tests created on-the-fly for each code change** — no maintenance, no test code review
- Process: code lands → system infers intent → generates mutants (deliberate faults) → generates tests to catch those faults → LLM + rule-based assessors filter false positives → engineer receives signal only when a real bug is caught
- Key advantage: tests are tailored to the specific change; lower false positive rate than static test suites
- Paper: https://arxiv.org/pdf/2601.22832
- Source: https://engineering.fb.com/2026/02/11/developer-tools/the-death-of-traditional-testing-agentic-development-jit-testing-revival/

**Aider (AI pair programming CLI):**
- `--auto-lint`: lints each edited file immediately; blocks further AI edits if lint fails
- `--test-cmd <cmd> --auto-test`: runs specified test command after each AI edit; if tests fail,
  aider reads the error output and attempts to fix the failure automatically
- Enables a tight: edit → lint → test → fix loop driven entirely by the AI agent
- Practical implication: `--test-cmd` should be a **targeted test command** (not full suite) to keep
  each loop iteration under 10 seconds; reserve full suite for a final `/test` command
- Source: https://aider.chat/docs/usage/lint-test.html

**GitHub Copilot (agent mode / Autopilot):**
- Copilot in agent mode (VS Code v1.111+) can run terminal commands including tests
- The `--auto-test` pattern is philosophically similar: each tool-call cycle should run a narrow
  targeted test, not the full suite
- Instruction files (`.github/copilot-instructions.md`) can encode the tiered test policy:
  "during intermediate phases run targeted suites; run full suite before marking task complete"

**SWE-bench benchmark observations:**
- SWE-bench evaluates AI agents on resolving real GitHub issues in Python repos (2,294 tasks)
- Current SOTA (Claude 4.5 Opus high reasoning): **76.8% on SWE-bench Verified** (April 2026)
- Test execution is central to SWE-bench tasks — agents that run tests to verify their changes
  significantly outperform those that do not
- The benchmark itself uses existing test suites to validate solutions; agents that understand
  test output and iterate on failures score dramatically higher
- Source: https://www.swebench.com/

**Key synthesis for AI agents:**
1. Configure target test command to be path-scoped or module-scoped (not `--all`)
2. Let the agent self-repair against fast targeted test failures
3. Gate on full suite at explicit phase boundaries (pre-commit, task-complete)
4. Consider JiTTest-style generation for high-velocity agentic sessions where traditional tests
   are too slow or too coarse to catch AI-introduced regressions

---

### 8. Cost of Over-Testing vs. Under-Testing

**Risk model for under-testing:**
- Bug cost grows "almost exponentially" the later it is caught (Google SWE Book Ch.23)
  - Local catch: developer fixes immediately, no downstream impact
  - Post-submit catch: requires rollback, blocks other engineers
  - Staging catch: QA tester involved, delays release
  - Production catch: affects end users, full incident response cost
- Google Takeout: moving tests earlier prevented 95% of broken deploys, reduced nightly failures 50%

**Diminishing returns from over-testing (full-suite abuse):**
- Martin Fowler: "Every single test is additional baggage. Writing and maintaining tests takes time.
  Reading and understanding other people's tests takes time. Running tests takes time."
- Google SWE Book: "Having a 100% green rate on CI, just like having 100% uptime for a production
  service, is awfully expensive."
- Test duplication across pyramid layers wastes maintenance effort without adding new confidence
- The "ice cream cone" anti-pattern (mostly E2E) is the worst case: slow, flaky, expensive, and
  hard to debug; failures often mask root causes

**Flakiness as a specific over-testing failure mode:**
- Flaky tests "erode confidence similar to a broken test" (Google SWE Book)
- When engineers routinely see flaky failures, they start ignoring test output — the entire CI
  signal degrades
- Google's heuristic: "if it isn't actionable, it shouldn't be a failure" — flaky tests should be
  disabled (with tracking bugs) rather than ignored

**The right balance:**
- Google's explicit policy: "CI should optimize quicker, more reliable tests on presubmit and
  slower, less deterministic tests on post-submit"
- Running the full suite on every commit is the correct policy only when the full suite takes <10
  seconds — at which point the distinction between targeted and full becomes moot
- For suites taking >10 seconds: tiered execution is always worth implementing

---

## Recommendations for a 47-Suite Bash Test Framework

1. **Maintain the targeted-test-map.** The `scripts/harness/select-targeted-tests.sh` +
   `targeted-test-map.json` pattern is the correct TIA approach for shell-based tests.
   Keep it current as new tests are added.

2. **Define three explicit tiers:**
   - **Tier 1 (inner loop, <10s target):** `select-targeted-tests.sh <changed-paths>` — run after each significant change
   - **Tier 2 (pre-commit gate, <2min target):** a curated fast subset of high-confidence suites covering shared helpers and critical paths
   - **Tier 3 (full suite gate):** `bash tests/run-all.sh` — run once before marking the full task complete, not after every edit

3. **For AI agent sessions (Copilot, aider, etc.):**
   - Configure `--test-cmd` or equivalent to run Tier 1 (targeted), not Tier 3
   - Let the agent self-repair against Tier 1 failures; only invoke Tier 3 at explicit phase boundaries
   - This is exactly the PDCA cycle in this repo's instructions: intermediate phases use targeted suites; full suite gates task completion

4. **Periodic full-suite run regardless of TIA:**
   - Microsoft TIA docs explicitly recommend running all tests at a configured periodicity
   - Google TAP runs full suites post-submit even when presubmit passed
   - For this repo: `bash tests/run-all.sh` in CI on every PR; locally at task-complete gate

5. **Watch for the 10-second threshold:**
   - If Tier 1 (targeted) grows beyond ~10 seconds, it has become too broad — revisit the targeted-test-map
   - If the full suite grows beyond ~5 minutes, consider parallelizing (the harness already supports isolation; add `-P <n>` parallelism if available)

6. **On test flakiness:**
   - Flaky shell tests (network/timing-sensitive) should be tagged and excluded from pre-commit tiers
   - Include them in CI-only runs with retry logic (e.g., `|| <retry>`) rather than silencing them

---

## Gaps / Further Research Needed

1. **Spotify's test intelligence:** Concrete numbers for their approach are not in public engineering posts; only referenced in passing in conference talks. Would require direct Spotify Engineering Blog search.

2. **Launchable post-acquisition data:** Launchable's specific accuracy/savings claims need re-verification from CloudBees documentation; original blog URLs have been redirected.

3. **Developer attention research (the 10-23 minute recovery claim):** The precise source is often cited without a canonical reference. Gloria Mark's "The Cost of Interrupted Work" (2008, SIGCHI) is the most commonly cited primary source but was not directly fetched in this session.

4. **Bash-specific TIA tooling:** No comprehensive survey of TIA-equivalent patterns for bash/shell test suites exists in the literature; the path-to-test-map pattern appears to be the dominant approach by necessity.

5. **AI agent test strategy best practices:** This is an emerging (2026) research area; Meta's JiTTesting paper is the most current primary source. Academic surveys of agentic test strategies are nascent.
