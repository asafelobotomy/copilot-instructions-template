# Research: Candidate Dependency Evaluation

> Date: 2026-04-09 | Agent: Researcher | Status: final

## Summary

This report evaluates 12 candidate tools and libraries for potential adoption in the
`copilot-instructions-template` repository (Markdown/Shell, Python stdlib + FastMCP, 6-dep budget,
currently at ~0 declared runtime deps). Each candidate is assessed for maintenance health,
install weight, fit to specific use cases in this repo, and security posture.
Five candidates reach ADOPT/TRIAL tier; seven are SKIP.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://pypi.org/project/tiktoken/ | tiktoken versions and description |
| https://pypi.org/project/ruff/ | ruff versions and description |
| https://pypi.org/project/watchdog/ | watchdog versions and description |
| https://pypi.org/project/rapidfuzz/ | rapidfuzz versions and description |
| https://pypi.org/project/jsonschema/ | jsonschema description |
| https://pypi.org/project/check-jsonschema/ | check-jsonschema CLI and pre-commit hook |
| https://pypi.org/project/pre-commit/ | pre-commit latest version (4.5.1) |
| https://github.com/openai/tiktoken/releases | tiktoken release history: 0.12.0 (Oct 2025) |
| https://github.com/astral-sh/ruff/releases | ruff latest: 0.15.9 (Apr 2026) |
| https://github.com/gorakhargosh/watchdog/releases | watchdog latest: 6.0.0 (Nov 2024) |
| https://github.com/rapidfuzz/RapidFuzz/releases | rapidfuzz latest: 3.14.5 (Apr 2026) |
| https://github.com/jqlang/jq/releases | jq 1.8.1 (Jul 2025, CVE-2025-49014 fix) |
| https://github.com/koalaman/shellcheck/releases | shellcheck v0.11.0 (Aug 2025) |
| https://github.com/crate-ci/typos/releases | typos-cli v1.45.0 (Apr 2026) |
| https://github.com/crate-ci/typos/blob/master/docs/comparison.md | typos vs codespell feature matrix |
| https://github.com/sharkdp/fd/releases | fd v10.4.2 (Mar 2026) |
| https://github.com/microsoft/LLMLingua | LLMLingua: last code activity ~Jul 2024, v0.2.2 |
| https://github.com/open-compress/claw-compactor | Claw Compactor v7.0: 14-stage pipeline, Apr 2026 |
| https://github.com/DelvyG/promptmin | promptminify: tiktoken-validated rules, Apr 2026 |
| https://github.com/topics/prompt-compression?l=python&o=desc&s=updated | Prompt compression landscape 2026 |
| https://github.com/codespell-project/codespell/releases | codespell v2.4.2 (Mar 2026) |

---

## Findings

### A. tiktoken (OpenAI tokenizer)

- **Version**: 0.12.0 — released Oct 2025. Active: yes (maintained by OpenAI).
- **Install size**: ~7 MB wheel (Rust-compiled BPE core + Python bindings). On first use, downloads
  a ~1.7 MB vocabulary blob from `openaipublic.blob.core.windows.net` and caches it in
  `~/.tiktoken/` (or `$TIKTOKEN_CACHE_DIR`).
- **Offline?**: No. First run requires CDN access. CI pipelines that have no internet access will
  fail unless the cache is pre-seeded. Seeding is possible (`TIKTOKEN_CACHE_DIR` env var) but adds
  CI setup complexity.
- **What it enables**: Replacing the line-count proxy in `validate-attention-budget.sh` with exact
  BPE token counts for `cl100k_base` (GPT-4/GPT-3.5) or `o200k_base` (GPT-4o). The current script
  uses `wc -l` with fixed budgets (800 lines total, 120 per section) — reasonable heuristics, but a
  1-line bullet and a 1-line blank count identically.
- **Direct deps**: `regex`, `requests` (+5 transitive: `certifi`, `charset-normalizer`, `idna`,
  `urllib3`, and `requests` itself).
- **Security**: No known CVEs. The CDN download is integrity-checked via included `.tiktoken`
  reference hashes. Network dependency in CI is the main risk surface.
- **Verdict context**: The improvement from heuristic → exact is real but marginal; the budget is
  already section-granular. The CDN dependency is a concrete friction point for a CI-first repo.

### B. jq (system JSON processor)

- **Version**: 1.8.1 — released Jul 2025 (security release over 1.8.0).
- **Security note**: 1.8.1 fixes CVE-2025-49014 (heap use-after-free in `f_strftime`) and
  CVE-2024-53427 from 1.8.0. Any environment pinned to 1.7.x or pre-1.7 is exposed.
- **Install size**: ~1 MB static binary.
- **Usage in this repo**: Two occurrences: (1) `lib.sh` documents `require_command python3 jq` as
  a usage example only — `jq` is not called in that file; (2) `audit-release-settings.sh` calls
  `gh repo view --json nameWithOwner --jq .nameWithOwner`, which delegates the jq filter to the
  `gh` CLI's bundled jq interpreter. No other script calls jq directly.
- **Python alternative**: All JSON manipulation in `scripts/copilot_audit/` uses `json` (stdlib).
  The `workspace-index.json` reads/writes use `json.load` / `json.dumps`.
- **Verdict context**: jq is already assumed to be present in most Linux CI environments and on
  developer machines. It is never a hard failure path (only the `gh --jq` call matters). Declaring
  it as a formal dependency provides documentation value but does not close any gap.

### C. shellcheck (shell linter)

- **Version**: v0.11.0 — released Aug 2025. Active: yes.
- **Install size**: ~10 MB static binary (Haskell-compiled, no runtime needed).
- **CI status**: Already active via `uses: ludeeus/action-shellcheck@master` in the GitHub Actions
  workflow. Covers all `*.sh` files in the repo.
- **Local gap**: Developers running `bash tests/run-all.sh` do not get shellcheck feedback unless
  the Action has already run.
- **What adding locally would enable**: Catch shellcheck issues before push instead of at CI time.
  However, the `commit-preflight` skill already suggests running local checks. Adding shellcheck
  to a bare `pre-commit` hook would require contributors to install pre-commit.
- **Verdict context**: CI already covers this fully. The marginal benefit of a local hook does not
  justify the setup overhead, especially given that pre-commit is a SKIP (see I below).

### D. ruff (Python linter + formatter)

- **Version**: 0.15.9 — released Apr 2026. Active: extremely (weekly releases).
- **Install size**: ~7 MB wheel (Rust binary with Python thin wrapper). Zero Python runtime deps.
- **What it enables**: Linting and formatting `scripts/copilot_audit/` (~15 files, ~1200 LOC).
  Currently no Python linter runs on this code. ruff replaces black + flake8 + isort in a single
  command with no configuration file required for basic use. The `commit-preflight` skill explicitly
  references ruff as the preferred Python linter.
- **Category**: dev-only (not needed at runtime; only needed in CI and local dev).
- **vs black + flake8**: ruff is 10-100x faster, maintains parity with both, and is already the
  community standard for new Python projects in 2026. The two-tool combination is legacy.
- **Security**: No known CVEs; Rust codebase; MIT licensed; maintained by Astral.
- **Verdict context**: The copilot_audit Python code has no linter today. ruff as a dev dep (CI
  only) costs zero runtime budget and provides a quality gate that is currently absent.

### E. watchdog (Python file watcher)

- **Version**: 6.0.0 — released Nov 2024. Active: yes.
- **Install size**: ~300 KB. Deps: `pathtools` only (1 transitive).
- **What it enables**: Live reload of workspace files in the FastMCP server — detecting when
  instructions files change and invalidating the server's in-memory cache automatically.
- **Assessment**: The current MCP server in this repo is a static loader; it re-reads files only
  when the tool is called. watchdog would add real-time propagation of edits. However:
  - Template repos are edited infrequently relative to application code.
  - The MCP server is not a long-running daemon in the CI pipeline; it is invoked on demand.
  - Adding a background thread with inotify/kqueue semantics adds platform-specific failure modes
    (FAT32, WSL v1, network mounts fail silently).
- **Verdict context**: This is over-engineering for a template repo. A consumer project with an
  active MCP server might benefit, but this repo does not.

### F. rapidfuzz (fuzzy string matching)

- **Version**: 3.14.5 — released Apr 2026. Active: yes (monthly releases).
- **Install size**: ~8-10 MB (Cython-compiled C++ core, pre-built wheels per platform).
- **Transitive deps**: 0 at runtime (`numpy` is optional).
- **What it enables**: Replacing the current diary dedup check (set-intersection of words,
  80% overlap threshold) with true edit-distance or partial-ratio matching.
- **Assessment**: The diary dedup problem is a grep-before-write check on a small (~100 entry) file.
  `difflib.SequenceMatcher` from stdlib achieves comparable accuracy for this scale with zero cost.
  rapidfuzz's advantage (sub-millisecond matching over millions of strings) is irrelevant here.
- **Security**: MIT licensed, no known CVEs.
- **Verdict context**: stdlib `difflib` fully covers the need. A compiled C++ extension for this
  use case is disproportionate.

### G. jsonschema / pydantic (JSON validation)

- **jsonschema version**: v4.x — actively maintained by python-jsonschema org.
- **check-jsonschema**: CLI wrapper around jsonschema; also a pre-commit hook; actively maintained.
- **jsonschema install size**: ~1 MB; transitive deps: `attrs`, `jsonschema-specifications`,
  `referencing`, `rpds-py` (~4-5 deps, all small).
- **pydantic version**: v2.x (Rust core via pydantic-core).
- **pydantic install size**: ~15 MB (pydantic + pydantic-core Rust wheels).
- **What they enable**: Formal schema validation for `workspace-index.json`, `suite-manifest.json`,
  `plugin.json`, and `REGISTRY.json`. Currently validated only by ad-hoc Python checks in
  `copilot_audit`. Missing fields produce cryptic KeyError traces rather than structured errors.
- **Assessment**:
  - `jsonschema` (via `check-jsonschema` CLI) is the right choice: (a) works as a
    `pre-commit` hook or a direct `python -m jsonschema` call, (b) accepts JSON Schema Draft 2020-12,
    (c) doesn't require defining Python models. The `check-jsonschema` CLI can validate
    GitHub Actions workflow YAML, too.
  - `pydantic` is significantly heavier and designed for typed Python models, not raw JSON
    file validation. Overkill here unless the audit module were to be reimplemented with typed models.

### H. typos-cli (source code spell checker)

- **Version**: v1.45.0 — released Apr 2026. Active: very (monthly dictionary updates + fixes).
- **Install size**: ~6 MB Rust binary (no Python, no runtime deps).
- **What it enables**: Automated typo detection across all `.md`, `.sh`, `.json`, `.py` files.
  Dictionary updates ship monthly. Recognises CamelCase, snake_case, URLs, email, base64, hex, UUID,
  and SHA hashes — does not flag them as typos. Respects `.gitignore`. Exit code for CI use.
- **vs codespell**: codespell v2.4.2 (Mar 2026, GPL v2) has no gitignore support, no CamelCase
  handling, no per-language dictionaries. typos is MIT, has per-lang dicts, far lower false-positive
  rate, and is now the dominant choice in GitHub Actions integrations.
- **GitHub Action**: `crate-ci/typos@HEAD` — available today, no additional setup.
- **Security**: MIT; Rust; no network access at runtime.
- **Verdict context**: This repo is documentation-heavy Markdown + Shell. Typos in instruction
  files reduce agent prompt quality. typos-cli is a zero-dep CI add that closes a gap not covered
  by markdownlint, shellcheck, or yamllint.

### I. pre-commit (git hook framework)

- **Version**: 4.5.1 — released Dec 2025. Active: yes.
- **Install size**: ~500 KB wheel; transitive deps include `cfgv`, `identify`, `nodeenv`,
  `platformdirs`, `virtualenv` (~15+ transitive).
- **What it enables**: Wiring shellcheck, markdownlint, yamllint, typos, ruff as git pre-commit
  hooks to give immediate local feedback before push.
- **Conflict with copilot-hooks.json**: The repo already has its own hook system
  (`template/hooks/copilot-hooks.json`, GitHub Action `Stop` hook) for agent workflows. pre-commit
  manages git-level `hooks/pre-commit` in `.git/hooks/`. These two systems are orthogonal and do
  not technically conflict, but presenting contributors with two hook systems (one for git, one for
  Copilot agents) adds cognitive overhead and setup friction.
- **Setup cost**: Requires `pre-commit install` per clone. If not run, git commits silently skip
  all checks. CI already runs all the same checks.
- **Verdict context**: The marginal local feedback loop does not justify the contributor setup
  burden, especially while CI gates cover the same checks. Revisit if the contributor base grows
  beyond a single maintainer.

### J. fd-find (modern find replacement)

- **Version**: v10.4.2 — released Mar 2026. Active: yes.
- **Install size**: ~5 MB static binary.
- **Usage in this repo**: No script calls `fd` directly. All file traversal uses `find`, `grep -r`,
  or Python `os.walk` / `pathlib.glob`. The `targeted-test-map.json` uses path patterns, not shell
  tools. `sync-workspace-index.sh` uses `find ... -type f`.
- **What it enables**: Nothing material. `fd` is faster than `find` and has better UX, but the
  existing scripts' file traversal is not a bottleneck for a ~50-file repo.
- **Verdict context**: No gap to fill. GNU `find` is present everywhere and sufficient.

### K. Prompt / instruction compression tools

#### LLMLingua (Microsoft, 2024)

- **Version**: v0.2.2 — last commit: July 2024. Effectively **unmaintained** as of April 2026.  
  Last news from the project page: September 2024 (KV cache offloading work). No 2025 or 2026
  releases.
- **Install size**: 50+ MB (requires `torch` + `transformers`).
- **Verdict**: Dead for this use case. Heavy ML stack, stale codebase, and it operates by dropping
  tokens by perplexity score — which destroys code identifiers and JSON keys. Not appropriate for
  agent instruction files where every structural term is load-bearing.

#### Claw Compactor (open-compress, 2026)

- **Version**: v7.0 — last update Apr 2026. Active: yes.
- **Dependencies**: `tree-sitter` (required for AST-aware code compression) plus language grammar
  packs, totalling ~5-7 MB of additional binary data.
- **What it enables**: 14-stage pipeline — RLE, semantic dedup (simhash), JSON sampling, log
  folding, AST compression, NLP abbreviation — with reversible decompression via hash-addressed
  store. Zero LLM inference cost. Benchmarks show 15-82% reduction depending on content type.
- **Assessment**: Impressive architecture and active development, but instruction files are a poor
  target. Instruction files are intentionally structured, with human-readable prose, numbered
  sections, and table formatting that agents depend on. "Compressing" them by removing whitespace,
  abbreviating natural language, or sampling JSON keys would break agent behaviour in
  non-deterministic ways. The tool is designed for compressing **context passed to an LLM** (logs,
  code, search results) — not for authoring compressed instruction files meant to be read and
  maintained by humans.
- **No purpose-built tool exists (2026)**: The `prompt-compression` GitHub topic has 17 repos as
  of April 2026. None are specifically designed for deterministic compression of AI instruction
  files. The closest, `promptminify`, validates token savings with tiktoken but operates on
  natural language prompts (Spanish/English), not structured Markdown with tables and code fences.

#### Recommendation
For this repo's current need (keeping `template/copilot-instructions.md` within its 800-line
budget), the right approach remains the existing `validate-attention-budget.sh` line-count gate
plus manual authoring discipline. No external compression tool materially helps.

### L. difflib / unified-diff tools

- **difflib** is Python **stdlib** — `difflib.unified_diff()` produces standard unified diffs at
  zero installation cost.
- **Current parity checker** (`sync-template-parity.sh`): uses `diff -u` (GNU diff, always
  present) or `filecmp.cmp` in Python. Both are already available.
- **Assessment**: No external dep is needed. `difflib.unified_diff` is the correct primitive for
  generating human-readable parity diffs in Python scripts.

---

## Summary Table

> **Categories**: `runtime` = needed at process runtime | `dev` = local dev tooling | `ci` = CI-only | `system` = OS-level binary, not declared as a package dep

| Name | Category | Install size | Transitive deps | Last release | Verdict |
|------|----------|-------------|-----------------|-------------|---------|
| **typos-cli** | ci | ~6 MB (binary) | 0 | v1.45.0 — Apr 2026 | **ADOPT** |
| **ruff** | dev/ci | ~7 MB (binary) | 0 | v0.15.9 — Apr 2026 | **ADOPT** |
| **tiktoken** | ci | ~7 MB wheel + ~1.7 MB CDN | ~6 (+ CDN dep) | 0.12.0 — Oct 2025 | **TRIAL** |
| **jsonschema** (check-jsonschema) | ci | ~1 MB | 4-5 | 4.x — 2025 | **TRIAL** |
| **jq** | system | ~1 MB binary | 0 | 1.8.1 — Jul 2025 | **SKIP** |
| **shellcheck** | system/ci | ~10 MB binary | 0 | v0.11.0 — Aug 2025 | **SKIP** |
| **watchdog** | runtime | ~300 KB | 1 (pathtools) | 6.0.0 — Nov 2024 | **SKIP** |
| **rapidfuzz** | runtime | ~9 MB | 0 (numpy optional) | 3.14.5 — Apr 2026 | **SKIP** |
| **pydantic** | runtime | ~15 MB | 3 (Rust core) | v2.x — 2026 | **SKIP** |
| **pre-commit** | dev | ~500 KB | ~15 | 4.5.1 — Dec 2025 | **SKIP** |
| **fd-find** | system | ~5 MB binary | 0 | v10.4.2 — Mar 2026 | **SKIP** |
| **LLMLingua** | runtime | 50+ MB | ~100 (torch) | v0.2.2 — Apr 2024 | **SKIP** |
| **Claw Compactor** | runtime | ~7 MB + grammars | tree-sitter | v7.0 — Apr 2026 | **SKIP** |
| **difflib** | stdlib | 0 | 0 | stdlib | **SKIP** |

---

## Recommendations

### ADOPT

**typos-cli** — Add as a GitHub Actions step (`crate-ci/typos@HEAD`) in the existing CI workflow
alongside markdownlint and yamllint. No Python budget consumed. Monthly dictionary updates auto-
catch new common typos. The comparison with codespell is decisive: typos has better false-positive
handling for code symbols and is MIT licensed. Estimated setup: 5-line addition to `ci.yml`.

**ruff** — Add as a dev/CI dep for `scripts/copilot_audit/`. Zero runtime budget; dev toolchain
only. Configure via `pyproject.toml` (creates a minimal one) or `ruff.toml`. Replaces the absent
linter/formatter. Directly referenced in the `commit-preflight` skill, so alignment is already
implied. Estimated setup: `pip install ruff` + one `ruff check .` step in CI.

### TRIAL

**tiktoken** — Trial only if the token-exact attention budget becomes a concrete requirement (for
example, if the template starts targeting models where line count diverges significantly from token
count). The CDN bootstrap dependency is the main friction point; mitigate by pre-seeding the cache
in the CI runner or using `TIKTOKEN_CACHE_DIR` pointing to a committed reference encoding.
Do not adopt unless the line-count heuristic proves insufficient in practice.

**jsonschema (check-jsonschema)** — Trial as a CI check for `workspace-index.json` and
`suite-manifest.json`. Write minimal JSON Schema Draft 2020-12 schemas for these two files (both
have stable shapes already documented). Use `check-jsonschema` CLI rather than importing jsonschema
into Python — this keeps it outside the runtime dep budget. Budget impact: 1 of 6 slots if
declared as a runtime dep, or 0 if used as a standalone CLI invocation.

### SKIP

- **jq**: Python stdlib `json` handles all actual needs; the only `--jq` call in the codebase
  delegates to `gh`'s bundled interpreter; declaring it adds documentation noise with no real gap.
- **shellcheck**: Already in CI; no gap; pre-commit setup overhead unjustified for single maintainer.
- **watchdog**: Over-engineering; the MCP server is invoked on demand, not long-running; platform-
  specific failure modes (WSL, FAT32) add more risk than value.
- **rapidfuzz**: stdlib `difflib.SequenceMatcher` is sufficient for the diary dedup volume; the
  compiled C++ extension weight is disproportionate.
- **pydantic**: Too heavy; check-jsonschema covers the structural validation need at a fraction of
  the cost.
- **pre-commit**: Contributor setup friction, dual hook system confusion, CI already gates the same
  checks.
- **fd-find**: No scripts call it; `find` is present everywhere and adequate for a 50-file repo.
- **LLMLingua**: Unmaintained since mid-2024; torch/transformers dependency is prohibitive.
- **Claw Compactor**: Designed for context compression, not instruction file authoring; would harm
  agent-readability of instruction files; tree-sitter dep adds complexity.
- **difflib**: Already stdlib; no action needed.

---

## Gaps / Further research needed

1. **tiktoken CDN seeding in GitHub Actions**: If tiktoken is later trialed, research the exact
   workflow steps for pre-seeding the `~/.tiktoken/` cache in a `ubuntu-latest` runner (whether
   the encoding blobs can be committed to the repo or fetched via a separate cache job).
2. **check-jsonschema schema authoring**: Writing minimal JSON schemas for the four JSON config
   files in this repo is a one-time task. Research whether `npx quicktype` or `python -m
   genson` can auto-generate a schema draft from existing instances to accelerate this.
3. **Deterministic instruction compression (2026)**: No purpose-built tool exists. The closest
   candidate (`promptminify`) validates savings with tiktoken but is not designed for structured
   Markdown with tables. Monitor this space; a utility for deterministic reduction of agent
   instruction files (collapsing table whitespace, deduplicating equivalent rules) would be
   directly useful here.
