# Research: Risk-Based Test Suite Escalation — Industry Patterns and Best Practices

> Date: 2026-04-12 | Agent: Researcher | Status: final

## Summary

Industry practice at Google, Meta, Microsoft, and Datadog converges on a layered model: fast targeted tests run per-change, with automatic escalation to broader or full suites when risk signals trip defined thresholds. Risk signals go well beyond file paths — mature systems use coverage tracing, historical failure correlation, dependency graph depth, change entropy, and commit-message escape hatches. The proposed escalation model (risk-classes on test-map rules + early full-suite emission) is architecturally sound and closely mirrors Datadog's Test Impact Analysis tracked-files/unskippable-tests pattern and Google's TAP broadening logic. Key additions recommended: confidence scoring in selector output, a "map-age staleness" guard, and a `should_skip_selection` pass-through for release/main branches.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://engineering.fb.com/2018/11/21/developer-tools/predictive-test-selection/ | Meta predictive test selection — ML baseline, 99.9% accuracy, 3x efficiency |
| https://arxiv.org/abs/1810.05286 | Meta arXiv paper — gradient-boosted model, flakiness handling, 95% individual failure catch rate |
| https://abseil.io/resources/swe-book/html/ch23.html | Google SWE Book Ch.23 — TAP, dependency graph, presubmit/post-submit, Takeout case study |
| https://devblogs.microsoft.com/devops/accelerated-continuous-testing-with-test-impact-analysis-part-1/ | Microsoft TIA — file-level instrumentation, >15 min threshold, IIS config |
| https://docs.datadoghq.com/tests/test_impact_analysis.md | Datadog Test Impact Analysis — coverage-based, tracked files, ITR:NoSkip, unskippable tests |
| https://docs.datadoghq.com/tests/test_impact_analysis/how_it_works/ | Datadog TIA internals — per-commit coverage diff, session-level savings reporting |
| https://docs.launchableinc.com/ | Launchable — SaaS ML predictive selection, confidence scoring, test health trends |
| https://engineering.fb.com/2026/02/11/developer-tools/the-death-of-traditional-testing-agentic-development-jit-testing-revival/ | Meta JiTTesting 2026 — LLM-generated on-the-fly tests for agentic workflows |
| https://testmon.org/ | pytest-testmon — coverage.py-based, --testmon-noselect for risk-ordered execution without deselection |
| https://arxiv.org/abs/2108.02464 | Academic survey: SBST/test prioritization literature 2010–2021 |

---

## Findings

### Q1. Established Industry Patterns for Risk-Based Test Selection

#### Google — Test Automation Platform (TAP)

TAP handles >50,000 code changes/day and >4 billion test cases/day. Key design choices:

- **Global dependency graph**: Forge/Blaze build tools maintain a near-real-time transitive dependency graph. Any changed file resolves instantly to the set of downstream tests.
- **Presubmit vs. post-submit split**: Each change runs a _presubmit_ suite (fast, targeted, engineer-visible) and a _post-submit_ suite (full, async). The presubmit passes with "95%+ likelihood" of the full suite passing.
- **Hermetic SUT policy**: Tests that run against real backends introduce flakiness and quota burn. Teams that switch to hermetic (fully isolated) presubmit cut runtime by up to 14x (Google Assistant case: 14x speedup, virtually zero flakiness).
- **Broadening signals**: Changes to widely-shared libraries automatically get a broader presubmit because the dependency graph shows fan-out. There is no manual annotation required — it emerges from the graph.
- **Post-submit culprit analysis**: When a post-submit test fails, TAP narrows the blame set to the specific change(s) that introduced the failure within a time window.

Source: https://abseil.io/resources/swe-book/html/ch23.html

#### Meta/Facebook — Predictive Test Selection

Meta deploys a gradient-boosted decision tree trained on historical change-outcome pairs.

- **Model inputs**: Abstracted representations of code changes (file paths, change size, affected modules, author/team metadata).
- **Model output**: Per-test probability of failure for the given change.
- **Production results** (in deployment since 2017, published 2018): catches >99.9% of faulty changes while running only 1/3 of transitively-impacted tests — doubling infrastructure efficiency versus the prior dependency-graph-only approach.
- **Flakiness handling**: Training data uses aggressive retry to distinguish true failures from flaky tests. Flaky tests are explicitly modelled as having non-deterministic outcomes.
- **Safety threshold**: The system is tuned to >95% individual test failure catch rate and >99.9% faulty-change detection rate. Below those thresholds, the model reverts to broader selection.

Source: https://engineering.fb.com/2018/11/21/developer-tools/predictive-test-selection/ | Paper: arXiv:1810.05286

#### Microsoft — Test Impact Analysis (TIA)

File-level instrumentation via the Visual Studio Test task v2.

- **Mechanism**: Instruments test execution to trace which source files each test reads. Builds a file→test dependency database.
- **Inclusion policy**: TIA always includes (a) tests impacted by changed files, (b) previously failing tests, (c) newly added tests that have no history.
- **Cost threshold**: TIA overhead (maintaining the DB) only pays off when full test runs take >15 minutes. Below that, overhead exceeds savings.
- **Periodic full-suite override**: Microsoft explicitly recommends running all tests at a configured cadence (e.g., nightly) regardless of TIA results. This prevents drift.
- **Language scope**: Requires managed .NET instrumentation; does not cover shell scripts, Python tests, or arbitrary test runners without additional tooling.

Source: https://devblogs.microsoft.com/devops/accelerated-continuous-testing-with-test-impact-analysis-part-1/

#### Datadog — Test Impact Analysis (formerly Intelligent Test Runner)

Coverage-tracing approach integrated with CI pipelines.

- **Mechanism**: Instruments test runs with per-line coverage tracing. Cross-references coverage data with git diff to find impacted tests.
- **Escape hatches** (critical pattern for risk-based escalation):
  1. **Tracked files**: Any file listed as a "tracked file" (Makefile, Dockerfile, requirements.txt, lock files) causes _all_ tests to run when changed. This is equivalent to a `critical-surface` risk class.
  2. **Unskippable tests**: Individual tests can be annotated as always-run. Equivalent to `must-run` flag in a test-map entry.
  3. **Commit-message override**: Adding `ITR:NoSkip` anywhere in a commit message disables test selection for that commit and runs all tests.
  4. **PR label override**: GitHub PR label `ITR:NoSkip` triggers full suite.
  5. **Branch exclusion**: Specific branches (e.g., `main`, `release/*`) can be excluded from test selection — they always run the full suite.
- **Known limitations acknowledged by Datadog**: Cannot automatically detect changes to data files in data-driven tests; cannot detect schema changes in external systems. Users must configure tracked files or unskippable tests for these cases.

Source: https://docs.datadoghq.com/tests/test_impact_analysis.md

#### Launchable (CloudBees)

Commercial SaaS ML-based predictive selection.

- **Input**: Per-run test results uploaded via CLI; change metadata (commit diff, author, branch).
- **Output**: Ordered/filtered test list with confidence score. Dashboard shows per-suite health trends, failure rate trends, unhealthy (flaky) test list.
- **Parallelization**: Uses historical duration data to create evenly-sized bins for parallel execution.
- **Observability**: All selection decisions are logged and visible in the Launchable dashboard. Shows selection size vs. full suite size, confidence level, and trend lines.

Source: https://docs.launchableinc.com/

---

### Q2. Risk Signals Beyond File Paths

The following signals are used in production systems beyond simple path matching:

#### Change entropy / code churn
- Microsoft Research (Nagappan & Ball, 2005–2007) found that code churn metrics (lines added, deleted, changed per file over a rolling window) are strong predictors of post-release defects — even stronger than code coverage alone.
- **Actionable pattern**: Files with high historical churn (many changes per week) should be `critical-surface` regardless of what direct tests map to them. A file changed 20 times in the past month is higher risk than a file changed once in a year, even if their path-based test mappings are identical.
- **Measurement**: `git log --diff-filter=M --name-only --since=30.days.ago -- <file> | wc -l` provides a simple churn proxy.

#### Historical failure correlation
- Meta's model is trained on historical change→test outcome pairs. Files whose changes historically co-occur with test failures are weighted higher for selection, regardless of dependency graph proximity.
- **Practical signal**: A test that has failed more than N times in the past M days is either flaky (needs repair) or a high-signal test (definitely include in every run).

#### Dependency graph depth / fan-out
- Google TAP's core signal: the deeper a changed file sits in the dependency graph and the wider its fan-out (how many modules depend on it), the broader the escalation.
- **Pattern**: Changes to a leaf module (few dependents) → targeted. Changes to a foundational library (many dependents) → automatic broadening.
- **For path-to-test maps**: This is represented by `broaden-aggressively` mappings. The escalation model should track when _multiple_ `broaden-aggressively` hits come from _different subsystems_ — that indicates cross-cutting concern.

#### Code ownership / reviewer signals
- Google's OWNERS file system means changes that touch files owned by many teams are higher risk. Cross-team changes are more likely to have integration failures.
- **Proxy**: Files listed in multiple CODEOWNERS sections, or in the root CODEOWNERS, trigger additional scrutiny.

#### Coverage delta (coverage decrease)
- A change that reduces test coverage by X% is higher risk than a refactor that keeps coverage stable.
- Codecov and Datadog both support coverage threshold alerts in CI.

#### Test age / last-run staleness
- Tests that have not been run in >N days deserve inclusion when they fall on the borderline of the change's impact. Stale tests may have accumulated silent coverage gaps.

#### Change transaction size (files changed, modules affected)
- The number of _distinct subsystems_ (top-level directories) touched by a change is a stronger signal than total files changed. Changing 50 files in one module is lower risk than changing 5 files each in 10 different modules.
- **This validates the proposed trigger #1** (multiple files/directories across different subsystems).

---

### Q3. Common Pitfalls in Test Selection

#### False economy of deferred failures
- The Google SWE Book documents the exponential cost growth of late detection: local fix is ~1x cost; post-commit block is ~10x; staging is ~100x; production incident is ~1000x.
- **Specific trap**: If your path-to-test map has gaps (new code paths with no test mapping), test selection will silently exclude relevant tests. "No tests match this path" should be treated as a risk signal, not a green light.
- **Mitigation**: Log unmapped paths as warnings with `unmapped_paths: [...]` in selector output. When unmapped paths exceed a threshold, escalate to full suite.

#### Configuration drift (stale test maps)
- All three major implementations (Google, Meta, Datadog) run full suites post-submit or periodically specifically to catch what targeted selection missed. The gap between selection and ground truth grows over time as code evolves.
- **Microsoft's explicit recommendation**: Even with TIA, run all tests at a configured periodicity.
- **Datadog's branch exclusion**: Release and main branches always run full suite — never rely on selection for ring-fenced branches.
- **For bash-based maps**: Every time a new test file is added to `tests/`, the `targeted-test-map.json` must be updated. An automated check (CI validation that all test files are mapped) prevents silent drift.

#### Coverage gaps from unmapped new code
- pytest-testmon explicitly notes: "Testmon selects too many tests when you change a method parameter name" — the entire module hierarchy is marked changed. This is a conservative (safe) failure mode.
- The opposite failure mode: a new file has _no_ tests mapped to it, so changes to it never trigger any tests. This is the silent danger.
- **Mitigation**: Reverse-coverage check: "which tests, if any, would catch a failure in this file?" If the answer is none, that file should auto-trigger `full-suite`.

#### Over-reliance on path heuristics without transitive analysis
- Path-to-test maps are a manually-maintained approximation of what instrumentation tools compute automatically. They will always lag the actual dependency graph.
- **Known gap**: If module A calls helper B, and you change B, your path-map must know that A's tests cover B. Without that transitive knowledge, B's change won't trigger A's tests.
- **Mitigation**: For the highest-risk boundaries (shared helpers, base classes), err toward `broaden-aggressively` or `critical-surface` rather than trying to enumerate all dependents manually.

#### Flakiness amplifying false deselection
- Datadog's documentation explicitly states that TIA filters flaky test noise by design: "By minimizing the number of tests run per commit, Test Impact Analysis reduces the frequency of flaky tests disrupting your pipelines."
- The converse risk: a flaky test that is intermittently selected may produce a false failure signal that causes the selector to incorrectly escalate for future unrelated changes (if historical failure rate drives selection logic).
- **Mitigation**: Separate "consistently failing" from "flaky" in the test map annotation. Flaky tests that are selected should use the retry mechanism, not count against the stability score.

#### Silently skipping test categories (tool limitations)
- Datadog acknowledges it cannot track: data file changes in data-driven tests, external service schema changes, environment configuration changes.
- **Pattern**: Introduce `tracked-file-patterns` as a first-class concept in the selector: files matching these patterns (e.g., `*.json`, `config/*`, `Makefile`) always trigger full suite. This maps directly to Datadog's "tracked files" mechanism.

---

### Q4. Threshold and Failsafe Mechanisms

The following threshold/failsafe patterns are observed across industry implementations:

#### Time-based periodic override
- **Microsoft TIA**: Recommends running all tests "at a configured periodicity" regardless of TIA status.
- **Practical form**: `if (days_since_last_full_suite > N) → run_full_suite_early = true`.
- **Typical N**: 1–7 days depending on team velocity. A team merging 20 PRs/day might use N=1; a team merging 1 PR/week might use N=30.

#### Branch-based unconditional full suite
- **Datadog**: Branches can be excluded from test selection entirely. `main`, `release/*` always run all tests.
- **Google TAP**: Post-submit to trunk always runs the full asynchronous suite regardless of presubmit results.
- **Pattern**: Any change targeting a protected branch (`main`, `release/*`, `hotfix/*`) → `should_run_full_suite_early = true` with reason `protected-branch-target`.

#### Percentage-of-codebase-changed trigger
- No single published threshold exists, but the pattern is: when the ratio of changed files to total codebase files exceeds X%, targeted selection provides little marginal benefit.
- **Practical threshold**: If >10% of watched files are changed in a single commit, the selection overhead may exceed the savings. Full suite at that point is often faster end-to-end.
- **For a 47-suite bash framework**: Count distinct top-level directories touched. If >50% of subsystems are touched, there is no targeted benefit.

#### Cross-domain broadening threshold
- **Pattern from proposed design**: Two or more `broaden-aggressively` matches from different top-level domains → `should_run_full_suite_early = true`.
- **Rationale**: Each `broaden-aggressively` match already means "we don't have confidence in targeted selection for this domain." Two such matches from unrelated subsystems means neither targeted nor domain-scoped selection is safe.
- **This is architecturally sound** and closely mirrors Google's TAP fan-out logic: when the dependency footprint crosses subsystem boundaries, broadening is the safe choice.

#### Confidence scoring with fallback threshold
- **Launchable**: Emits a confidence score for each selection decision. Low confidence → include more tests or escalate.
- **Meta's paper**: Production deployment required >95% individual failure catch rate as a floor. If the model's expected recall drops below 95%, it falls back to full dependency-graph selection (the prior, more conservative system).
- **For static path-to-test maps**: Confidence is expressed as coverage completeness — what percentage of the changed files have at least one test mapped. `confidence = mapped_files / total_changed_files`. Below 70–80%, escalate.

#### Commit-message escape hatch (opt-in full suite)
- **Datadog**: `ITR:NoSkip` in commit message → full suite.
- **Pattern**: `[full-suite]`, `!test-all`, or similar token in commit message → `should_run_full_suite_early = true` with reason `author-requested`.
- This is especially important for: large refactors that the author knows are cross-cutting; security patches; dependency upgrades.

#### New file without test mapping (reverse coverage gap signal)
- Files added in a change that have _no_ test entry in the coverage map represent unknown risk.
- **Pattern**: `unmapped_new_files.count > 0` → emit warning + consider escalation.
- If the unmapped file is under a `critical-surface` path, escalate.

---

### Q5. Observability Metadata the Selector Should Emit

Based on Launchable's dashboard model, Datadog's test session metadata, and Google TAP's blame system, mature test selectors emit the following fields:

#### Selection decision fields
```json
{
  "strategy": "targeted | broaden-aggressively | full-suite",
  "should_run_full_suite_early": false,
  "early_full_suite_reasons": [],
  "confidence_score": 0.87,
  "confidence_basis": "mapped_files_ratio"
}
```

#### Coverage and mapping quality
```json
{
  "changed_files_total": 12,
  "changed_files_mapped": 10,
  "changed_files_unmapped": ["scripts/new-helper.sh"],
  "coverage_estimated_pct": 83.3,
  "test_map_age_days": 4,
  "test_map_staleness_warning": false
}
```

#### Risk classification breakdown
```json
{
  "risk_classes_matched": ["security-sensitive", "cross-cutting"],
  "domains_touched": ["scripts/hooks", "template/instructions", ".github/agents"],
  "broaden_aggressively_domains": ["template/instructions"],
  "critical_surface_paths": [".github/copilot-instructions.md"],
  "unchanged_full_suite_trigger": null
}
```

#### Selection result
```json
{
  "suites_selected": ["test-hooks.sh", "test-agents.sh", "test-instructions.sh"],
  "suites_excluded": ["test-sync-models.sh", "test-workspace-index.sh"],
  "selection_mode": "targeted",
  "estimated_duration_s": 28,
  "full_suite_estimated_duration_s": 180
}
```

#### Audit trail
```json
{
  "selector_version": "2.1.0",
  "selector_invocation_id": "abc123",
  "changed_paths_input": ["template/instructions/docs.md", ".github/agents/fast.agent.md"],
  "escalation_decision_log": [
    {"rule": "security-sensitive-path", "path": ".github/hooks", "matched": false},
    {"rule": "multi-domain-broaden", "domains_broadening": 1, "threshold": 2, "matched": false}
  ],
  "timestamp": "2026-04-12T10:30:00Z"
}
```

The `escalation_decision_log` is especially valuable for debugging false non-escalations: when a production failure later identifies that a test should have run, the audit trail shows exactly which rule did not trigger and why.

---

### Q6. Novel and Emerging Approaches (2024–2026)

#### Meta JiTTesting — Just-in-Time Test Generation (February 2026)

Meta's most current public research directly addresses the agentic development problem.

- **Problem statement**: "Agentic development dramatically increases the pace of code change, straining test development burden and scaling the cost of false positives and test maintenance to breaking point."
- **Approach**: Instead of selecting from an existing test suite, JiTTesting _generates_ tests on-the-fly for each code change using LLMs:
  1. Code change lands → system infers developer intent from the diff
  2. Mutation testing generates deliberate faults (mutants) in the changed code
  3. LLM generates test cases specifically designed to catch those mutants
  4. LLM + rule-based assessors filter out false positives before surfacing to developer
- **Key insight**: Tests are tailored to the specific change, eliminating general test maintenance overhead. No test code review, no test library to maintain.
- **Relevance to escalation model**: JiTTesting is complementary, not a replacement. The escalation model determines _which existing tests to run_; JiTTesting fills the gap for _newly changed code with no existing coverage_.

Source: https://engineering.fb.com/2026/02/11/developer-tools/the-death-of-traditional-testing-agentic-development-jit-testing-revival/

#### Graph Neural Networks for Test Impact Analysis

Academic research (2023–2025) applies GNN models to code change impact analysis:

- Where Meta's model uses gradient-boosted trees on file-level features, GNN approaches model the full dependency graph as a graph and run graph convolution to propagate change impact through the graph.
- Advantage: can learn non-obvious transitive dependencies that static dependency graphs miss (e.g., dynamic dispatch, reflection).
- Current state: experimental/academic; not yet in production at major companies.
- **Relevance**: For a bash-based suite, GNN is impractical. But the GNN's core insight (transitive impact through the dependency graph) is what the `broaden-aggressively` classification already approximates manually.

#### LLM-Assisted Test Prioritization

Emerging pattern: use LLMs to read a diff and predict which test suites are likely relevant, augmenting or replacing static path maps.

- An LLM can understand semantic changes (e.g., renaming `validate_input` to `check_input` in a shared lib) and predict test relevance based on code semantics rather than file paths.
- Early experiments (GitHub Copilot Autofix, Semgrep, various startups) integrate into CI pipelines.
- **Tradeoff**: LLM calls add 5–30 seconds to the path-to-test resolution step; for short suites this overhead may exceed savings.
- **Practical near-term use**: LLM annotation of test-map entries — an LLM reviews new code and suggests which test suites to add to the map. Human reviews and commits the annotation.

#### Mutation Testing Integration with Test Selection

The pattern from JiTTesting generalizes: mutation test scores for individual files provide a per-file "how well does the existing suite cover this?" signal.

- Files with high mutation score (most mutants killed) → existing tests reliably cover them → targeted selection is safe.
- Files with low mutation score (many mutants escape) → existing tests don't cover them well → escalate.
- **Tools**: Stryker (JavaScript), PIT (Java), mutmut (Python). No mature bash mutation testing tool exists.
- **Actionable for this repo**: Track test quality per script function manually; files/functions with no test coverage → treat as `critical-surface` for selection escalation.

#### Confidence Score as First-Class CI Citizen (Launchable, 2024–2025)

Launchable models confidence score as the primary observable. This reframes the question from "which tests to run?" to "how confident are we that the selected tests are sufficient?"

- **Low confidence scenarios**: new tests added but not yet in the ML model; large refactors with no clear coverage precedent; first-time contributors with no test history.
- **High confidence scenarios**: small isolated changes to well-tested modules with dense historical coverage data.
- **Output format**: CI badge showing "Selection: 847 of 2,100 tests (confidence: 94%)". Developers see the confidence and can override (`ITR:NoSkip`) when they disagree.
- **Relevance**: The proposed selector should emit `confidence_score` as a first-class field so consumers can apply their own thresholds.

---

## Recommendations for the Proposed Escalation Model

Based on the research above, the following additions or modifications should be considered:

1. **Add `confidence_score` to selector output.** Use `mapped_files / total_changed_files` as a static proxy. Emit `confidence_basis: "map-coverage-ratio"`. When confidence < 0.75, treat as `escalation_advisory`. When confidence < 0.50 (over half of changed files are unmapped), escalate to full suite.

2. **Add `tracked-file-patterns` to the test map config** (mirrors Datadog's tracked files pattern). Files matching these patterns always trigger full suite regardless of other risk classifications. Good candidates: `Makefile`, `*.lock`, `requirements*.txt`, `*.config.*`, CI workflow files (`.github/workflows/*.yml`).

3. **Add branch-based unconditional escalation** (mirrors Datadog's branch exclusion). Inject an environment-based check: if `$GITHUB_REF` matches `refs/heads/main` or `refs/heads/release/*`, emit `should_run_full_suite_early=true` with reason `protected-branch`. This does not belong in the path map — it belongs as a first-pass check in the selector script.

4. **Track `test_map_age_days` and emit staleness warnings.** Keep a `.timestamp` file in `tests/` updated whenever the test map changes. The selector emits `test_map_age_days` and sets `test_map_staleness_warning=true` when age > 7 days without a full-suite run validating it.

5. **Add `unmapped_paths` to selector output.** Changed paths that have no entry in `targeted-test-map.json` should surface as a warning, not be silently ignored. If any unmapped path is under a `critical-surface` prefix, escalate.

6. **Add `decision_log` array for audit trail.** Each escalation rule that was evaluated should emit one entry with: `{rule, matched, value, threshold}`. This makes debugging post-incident false non-escalations tractable.

7. **For the multi-domain broadening trigger**, use top-level directory as the domain unit, not individual files. A change spanning `template/`, `scripts/`, and `.github/` covers three distinct domains — that is the right broadening signal. Two files in `scripts/` and `scripts/` is still one domain.

8. **Consider the `author-requested` escape hatch** (`[full-suite]` in commit message → `should_run_full_suite_early=true`). This is low-cost to implement and high-value for large refactors or security patches where the author knows the scope.

---

## Gaps / Further Research Needed

1. **Threshold calibration from empirical data**: The confidence threshold (0.75, 0.50) and the domain-count threshold (≥2) are directionally correct but need calibration against this repo's actual test selection history. After 30 days of using the selector, analyze false non-escalations to tune thresholds.

2. **Bash-specific code churn metrics**: No published study examines churn-based risk for bash/shell scripts specifically. The general Nagappan/Ball results apply but their magnitude models are for managed-code projects. Treat as directionally valid rather than numerically precise.

3. **JiTTesting applicability to bash tests**: Meta's JiTTesting applies to Python/Java/C++ codebases with LLM support. Generating bash test cases via LLM for shell script changes is theoretically possible but no production deployment or academic evaluation exists as of April 2026.

4. **ML model for this repo**: Launchable-style predictive selection requires historical training data. This repo does not currently log per-test outcomes over time. If test history were logged (CI pass/fail per test per commit), a simple logistic regression on change-feature→test-outcome pairs could be trained after ~3 months of data.

5. **GNN for this codebase**: Not applicable at current scale (47 suites, bash scripts). Revisit if the test suite grows to >500 suites or moves to a language with rich dependency graph data.
