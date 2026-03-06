# Security Guide

> How the template hardens your CI pipeline and controls agent trust levels.

---

## SHA-pinned GitHub Actions

All GitHub Actions in the template's workflows are pinned to specific commit SHAs rather than version tags. This protects against supply-chain attacks where a compromised action tag is repointed to malicious code.

### What it looks like

```yaml
# Pinned (secure)
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

# Tag-only (vulnerable to tag repointing)
- uses: actions/checkout@v4
```

### Why it matters

Version tags (`v4`, `v2`, etc.) are mutable Git references. A compromised action maintainer — or an attacker with write access — can repoint a tag to arbitrary code. SHA pins are immutable: the action code cannot change without changing the hash.

### Keeping SHAs current

Dependabot is configured in `.github/dependabot.yml` to automatically propose PRs when pinned actions have new releases. Review these PRs, verify the changelog, and merge to stay current without sacrificing security.

---

## Harden Runner

Every CI job includes `step-security/harden-runner` as its first step, configured with `egress-policy: audit`. This:

- Monitors all outbound network connections during the job
- Logs DNS queries and HTTP/HTTPS requests
- Detects unexpected network activity (e.g., data exfiltration attempts)
- Provides a foundation for upgrading to `egress-policy: block` once baseline traffic is established

### Upgrading to block mode

After running in audit mode for several weeks:

1. Review the StepSecurity dashboard for your repository
2. Identify the expected egress endpoints (npm registry, GitHub API, etc.)
3. Create an `allowed-endpoints` list
4. Switch from `egress-policy: audit` to `egress-policy: block`

---

## OpenSSF Scorecard

The `scorecard.yml` workflow runs the [OpenSSF Scorecard](https://securityscorecards.dev/) analysis weekly and on pushes to main. It:

- Evaluates the repository against 18+ security checks (branch protection, dependency updates, dangerous workflows, etc.)
- Uploads results as SARIF to GitHub's code scanning dashboard
- Publishes results to the OpenSSF Scorecard API

### Viewing results

- **GitHub UI**: Security tab → Code scanning alerts → Filter by "OSSF Scorecard"
- **Badge**: Add a Scorecard badge to your README once results are published
- **API**: Query `api.securityscorecards.dev` for your repository's score

---

## Graduated Trust Model

The template includes a trust model in §10 that controls how much verification Copilot applies based on which files are being changed.

### Three trust tiers

| Trust tier | Default paths | What happens |
|-----------|--------------|-------------|
| **High** | Tests, docs, markdown files | Copilot acts freely and summarises after the fact |
| **Standard** | Source code (`src/`, `lib/`, `app/`) | Copilot describes the plan and waits for approval |
| **Guarded** | Config files, CI, Docker, `.env` | Copilot stops, explains in detail, and waits for explicit "go ahead" |

### Customising trust levels

During setup, interview question **E21** lets you choose:

- **Use defaults** — the three-tier system above
- **Trust everything** — all paths get High trust (for users who review via git diff)
- **Review everything** — all paths get Standard trust (maximum caution)
- **Custom tiers** — define your own path-to-trust mappings

Custom overrides are written to the `{{TRUST_OVERRIDES}}` placeholder in §10 and take precedence over defaults.

### Custom tier format

When option **D — Custom tiers** is selected during setup (E21), the text you type is written verbatim to `{{TRUST_OVERRIDES}}` in §10. The expected format is a short Markdown table followed by any prose notes:

```markdown
| Path pattern | Trust tier | Behaviour |
|---|---|---|
| `.github/workflows/**` | Guarded | Pause and explain before any edit |
| `src/auth/**` | Guarded | Pause and explain before any edit |
| `src/**` | Standard | Describe plan and wait for approval |
| `docs/**` | High | Auto-approve; summarise after |
| `**/*.test.*` | High | Auto-approve test files |
```

Rules:

- **Path patterns** use standard glob syntax (`**` matches any path segment, `*` matches within a segment).
- **Trust tiers**: `High`, `Standard`, or `Guarded` only.
- More specific patterns take precedence over broader ones.
- Paths not matched by any pattern fall back to the default tier for their category (source → Standard, config → Guarded, docs/tests → High).

### How it interacts with other settings

The trust model works alongside — not in place of — other autonomy controls:

- **S5 (Autonomy level)** — sets the general behaviour (ask first / act then summarise / ask only for risky)
- **Global autonomy** — derived from S5 and stored as a separate preference row that caps all autonomy settings
- **Graduated Trust** — path-specific refinement within the S5/global-autonomy envelope

The most restrictive setting always wins. If S5 is set to "Ask first," the derived Global autonomy row stays low and the trust model becomes correspondingly conservative.

---

## Skill security metadata

Starting in v1.4.0, the skill spec (§12) recommends documenting two additional pieces of skill metadata. Keep them in the body-level `> Skill metadata:` note near the top of the file so the skill stays compatible with VS Code's stricter frontmatter validator.

### `compatibility`

```markdown
> Skill metadata: version "1.0"; license MIT; tags [security, review]; compatibility ">=1.4"; recommended tools [codebase, editFiles, runCommands].
```

Semver range indicating which template versions this skill was designed for. Agents warn if the current template version falls outside the range. This prevents running outdated skills that may reference removed sections or changed conventions.

### `recommended tools`

```markdown
> Skill metadata: version "1.0"; license MIT; tags [security, review]; compatibility ">=1.4"; recommended tools [codebase, editFiles, runCommands].
```

Array of tool identifiers the skill is expected to use. When executing a skill, agents should still restrict tool access to the smallest safe set. This implements the principle of least privilege: a review skill that only needs read access should not have write or command-execution access.

### Tool identifiers

Common tool identifiers used in skills:

| Tool | Description |
|------|------------|
| `codebase` | Read-only access to search and read files |
| `editFiles` | Create, modify, or delete files |
| `runCommands` | Execute shell and workspace commands |
| `githubRepo` | Access GitHub API (issues, PRs, releases) |
| `fetch` | Make HTTP requests to external URLs |

---

## Dependabot configuration

The template includes `.github/dependabot.yml` configured for the `github-actions` ecosystem:

- **Weekly schedule** — checks every Monday for action updates
- **Grouped PRs** — minor and patch updates are batched into a single PR
- **Conventional commits** — PR titles use `ci:` prefix for automatic changelog categorisation
- **PR limit** — maximum 5 open Dependabot PRs at a time

This ensures SHA-pinned actions stay current without manual tracking.

---

## Security checklist

When reviewing PRs that touch security-sensitive areas:

- [ ] All `uses:` references are SHA-pinned with version comment
- [ ] `harden-runner` is the first step in every job
- [ ] No secrets are hardcoded (use `${{ secrets.* }}` or environment variables)
- [ ] No `pull_request_target` with checkout of PR code (script injection risk)
- [ ] Permissions follow the principle of least privilege
- [ ] New skills document compatibility and recommended tools in the `Skill metadata` note
- [ ] Trust tier assignments match the sensitivity of the changed paths
