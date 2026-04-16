---
name: security-audit
description: Security audit checks (S1–S10) — OWASP Top 10, secret detection, injection patterns, supply chain, shell hardening, deserialization, CVE scan
compatibility: ">=2.0"
---

# Security Audit Checks

> Skill metadata: version "1.0"; license MIT; tags [security, owasp, audit, secrets, vulnerabilities, cve]; compatibility ">=2.0"; recommended tools [codebase, runCommands, fetch, webSearch].

On-demand security checks for the Audit agent. References OWASP Top 10:2025, CWE/SANS Top 25:2024, and OWASP ASVS 5.0.

Scan the entire codebase. Prioritise: source code → config files → CI workflows → infrastructure → documentation.

---

### S1 — Secret Detection

Scan all files for leaked secrets.

**Critical** (flag immediately): AWS keys (`AKIA...`), GitHub PATs (`ghp_`, `github_pat_`, `gho_/ghs_/ghu_/ghr_`), Google Cloud keys (`AIza...`), Stripe live keys (`sk_live_`), SendGrid keys (`SG.`), NPM tokens (`npm_`), Slack tokens (`xox[baprs]-`), PEM private key blocks.

**Medium** (review context): generic password/secret assignments with hardcoded values, connection strings with credentials, embedded JWTs (not test fixtures), base64 secrets after keyword context.

**Exclude**: `*.example`, `*.sample`, `*.template`, test fixtures, strings with `YOUR_`, `REPLACE_ME`, `CHANGEME`, `example`, `placeholder`, `dummy`, `fake`, `test_key`.

Flag: `[CRITICAL]` high-confidence. `[HIGH]` medium-confidence.

### S2 — Injection Patterns

Scan for: SQL injection (string concat in `execute()`/`query()`/`raw()`), OS command injection (`subprocess` with `shell=True`, `os.system()`, `child_process.exec()` with user input), XSS (`.innerHTML`, `dangerouslySetInnerHTML`, `eval()`, unescaped template output), path traversal (file ops with request params, `../`), SSRF (HTTP clients with user-supplied URLs).

Flag: `[CRITICAL]` with clear user input path. `[HIGH]` without confirmed input path.

### S3 — Cryptographic Weaknesses

Scan for: MD5/SHA1 for password hashing, ECB mode, hardcoded IVs/nonces, non-crypto PRNG for security (`Math.random()`, `random.random()`), disabled TLS verification (`verify=False`), weak TLS protocols (TLSv1.0/1.1, SSLv2/v3), `Cipher.getInstance("AES")` in Java (defaults to ECB).

Flag: `[CRITICAL]` disabled TLS verification or weak password hashing. `[HIGH]` ECB mode, weak PRNG, hardcoded crypto material.

### S4 — Supply Chain Security

**Lock files**: Verify presence of `package-lock.json`/`pnpm-lock.yaml`/`yarn.lock`, `Pipfile.lock`/`poetry.lock`/pinned `requirements.txt`, `go.sum`, `Cargo.lock`, `Gemfile.lock`.

**Dependency pinning**: Flag unpinned versions (`^`, `~`, `*`, `>=`), bare package names, `git+` deps, `:latest` Docker tags.

**GitHub Actions**: Flag actions not pinned to full SHA, third-party actions, `pull_request_target` with code checkout, script injection via `${{ github.event.*.title }}` in `run:`, `permissions: write-all`, secrets echoed to logs.

**Dependabot/Renovate**: Flag absence of `.github/dependabot.yml` or `renovate.json`.

Flag: `[CRITICAL]` Actions script injection, `pull_request_target` with checkout. `[HIGH]` unpinned Actions, missing lock files, missing Dependabot. `[WARN]` unpinned ranges, missing SBOM.

### S5 — Configuration Security

Scan for: debug mode in production (`DEBUG = True`, `NODE_ENV=development`), default credentials, CORS wildcard with credentials, missing security headers (CSP with `unsafe-inline`/`unsafe-eval`, missing `X-Frame-Options`/HSTS), wildcard `script-src *`.

Flag: `[HIGH]` debug mode, CORS wildcard with credentials. `[WARN]` missing headers, default credentials in templates.

### S6 — Shell Script Security

**Safety**: Every `.sh`/`.bash` script must have `set -euo pipefail` in first 15 lines.

**Dangerous patterns**: Unquoted variables in `rm`/`chmod`/`chown`/`mv`/`cp`, `eval` with variable content, fetch-and-execute piping, static `/tmp/filename` (use `mktemp`), `source` with variable paths, backtick substitution (prefer `$()`), `chmod 777`/`chmod a+w`, `sudo` with variable commands.

If `shellcheck` is available, run `shellcheck -f json <script>` and map SC codes to severity.

Flag: `[CRITICAL]` `eval` with external data, fetch-and-execute. `[HIGH]` missing `set -euo pipefail`, unquoted destructive commands. `[WARN]` static temp files, backtick substitution.

### S7 — GitHub Repository Security

**File presence**: `SECURITY.md` (`[HIGH]` if absent), `.github/CODEOWNERS` (`[HIGH]`), `.github/dependabot.yml` (`[WARN]`), CodeQL workflow (`[WARN]`).

**`.gitignore` coverage**: Verify patterns for `.env`, `*.pem`, `*.key`, private key files, `*.credentials`, `secrets.yml`, `.aws/credentials`.

**Actions hardening**: Check for `permissions:` block, flag `runs-on: self-hosted` and `workflow_run` triggers.

If GitHub API is available: check branch protection, open secret scanning alerts, open Dependabot alerts (high/critical), webhook configs without secrets.

### S8 — Insecure Deserialization

Flag unsafe patterns: Python `pickle.loads()`/`yaml.load()` without SafeLoader, PHP `unserialize()` with user input, Java `ObjectInputStream.readObject()` without type filtering, Ruby `Marshal.load()`, .NET `BinaryFormatter`/`LosFormatter`, Node.js `node-serialize`/`cryo` with user input.

Flag: `[CRITICAL]` deserialization of user-controlled data. `[HIGH]` without safe loader/type filter.

### S9 — Dependency CVE Scan

Parse lock files and query OSV.dev API (`POST https://api.osv.dev/v1/query`) for each direct dependency. Use `webSearch` to look up specific CVE details when needed. Limit ≤ 50 queries per audit.

Flag: `[CRITICAL]` CVSS ≥ 9.0 or in CISA KEV. `[HIGH]` CVSS ≥ 7.0. `[WARN]` CVSS ≥ 4.0.
Skip if no lock files or Fetch tool unavailable.

### S10 — Information Exposure

Scan for: stack traces in error handlers, verbose error configs, sensitive data in log statements, log injection, source maps in production, version/technology disclosure headers, comments with credentials or internal URLs.

Flag: `[HIGH]` stack traces exposed, sensitive data in logs. `[WARN]` source maps, technology disclosure.

---

## Security execution tiers

Run checks in order; each tier adds capability:

**Tier 1 — Zero-dependency** (always run): S1–S8, S10 using file reads and `grep` patterns only.

**Tier 2 — API-augmented** (if Fetch available): S9 via OSV.dev API. S7 via GitHub API for branch protection and alerts.

**Tier 3 — Tool-assisted** (if installed): `shellcheck` for deeper S6, `semgrep --config=auto --json` for broader S2, `gitleaks detect --no-git --report-format json` for S1 depth.

Note which tier was executed in the report.

---

## Security report format

```text
# Security Audit Report
**Date:** <timestamp>  **Tier:** <1|2|3>  **Scope:** <files scanned>

## Findings
### [CRITICAL] S1-001: AWS Access Key in config.env (line 42)
- Pattern: AWS_ACCESS_KEY | OWASP: A02:2025 | CWE: CWE-798
- Remediation: Move to env var or secrets manager. Rotate immediately.

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 0 |
| WARN     | 0 |

**Status:** SECURE (0 CRITICAL/HIGH) | AT-RISK (HIGH present) | CRITICAL (CRITICAL present)
```
