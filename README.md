# Lean/Kaizen Copilot Instructions Template

A versioned, self-updating GitHub Copilot instruction template that keeps AI developer behaviour consistent across projects.

## Set up in your project

Tell Copilot:

> *"Setup from asafelobotomy/copilot-instructions-template"*

Copilot fetches [`SETUP.md`](SETUP.md) and bootstraps your project automatically. No manual file copying required.

## Update an existing installation

Tell Copilot:

> *"Update your instructions"*

Copilot fetches [`UPDATE.md`](UPDATE.md) and performs a version-aware three-way merge.

## Recover a broken installation

Tell Copilot:

> *"Factory restore instructions"*

Copilot bypasses the normal update pre-flight, backs up every template-managed surface, removes those files from the working tree, and reruns the latest setup flow from scratch.

## All trigger phrases

See [`AGENTS.md`](AGENTS.md) for the full list of direct consumer-facing commands (heartbeat, retrospective, tools, skills, MCP, hooks, and more).

## Keep delegation narrow

Agent delegation stays narrow by design. See [`AGENTS.md`](AGENTS.md) for the entrypoint rules and [`template/copilot-instructions.md`](template/copilot-instructions.md) for the consumer runtime policy. Keep each `agents:` allow-list limited to explicit workflow handoffs rather than speculative convenience delegates.

## Version

Current template version: **5.5.0** <!-- x-release-please-version --> — see [`CHANGELOG.md`](CHANGELOG.md) and [`MIGRATION.md`](MIGRATION.md).

## Release automation

Pushes to `main` run the full validation workflow first. A final CI release job runs only after the validation jobs succeed, so the same workflow both validates the commit and drives release-please.

The release job evaluates only consumer-facing paths: `template/`, `.github/agents/`, `starter-kits/`, `SETUP.md`, and `UPDATE.md`. Developer-only changes do not produce a release. Consumer-facing changes open or update a release PR; `feat` keeps a minor bump, `fix` and `deps` keep a patch bump, and non-releasable commit headers fall back to a forced patch release so consumer updates are still tagged and published.

Release-please is the only version writer. Do not bump `VERSION.md`, `.release-please-manifest.json`, or the `x-release-please-version` markers manually.

## Terminal-safe strict mode

In zsh workspaces, do not issue top-level `set -euo pipefail` or `setopt errexit nounset pipefail` directly into a persistent terminal session. Use the repo wrappers so strict mode stays isolated to a child Bash process.

For one-line snippets:

```bash
bash scripts/tests/run-strict-bash.sh --command 'tmpdir=$(mktemp -d) && printf "ok\n" > "$tmpdir/out" && cat "$tmpdir/out" && rm -rf "$tmpdir"'
```

For multi-line snippets:

```bash
bash scripts/tests/run-strict-bash-stdin.sh <<'EOF'
tmpdir=$(mktemp -d)
printf 'hello\n' > "$tmpdir/out.txt"
cat "$tmpdir/out.txt"
rm -rf "$tmpdir"
EOF
```

## Recommended GitHub settings

The current release workflow assumes a lightweight ruleset on `main`.

- Block branch deletion.
- Block non-fast-forward pushes.
- Enable auto-merge and squash merge.
- Enable the Actions setting that allows GitHub Actions to create and approve pull requests.
- Keep required pull-request approvals and required status checks off `main` unless you intentionally want release PRs to pause for manual merge or you switch release PR automation to a GitHub App or PAT-backed token.

Audit the live repository settings with an authenticated GitHub CLI session:

```bash
bash scripts/release/audit-release-settings.sh
```

If you want stricter governance on `main`, choose one of these paths:

1. Require pull-request approval and accept manual review and merge for release PRs.
2. Require pull-request checks and move release PR automation to a GitHub App or PAT-backed token that can trigger those checks.
