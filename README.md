# Lean/Kaizen Copilot Instructions Template

A versioned, self-updating GitHub Copilot instruction template that keeps AI developer behaviour consistent across projects.

## Repository map

- [`AGENTS.md`](AGENTS.md): machine entry point and trigger phrases.
- [`SETUP.md`](SETUP.md): first-time setup protocol for consumer projects.
- [`UPDATE.md`](UPDATE.md): update, backup restore, and factory restore protocol.
- [`MODELS.md`](MODELS.md): source of truth for agent model assignments.
- [`MIGRATION.md`](MIGRATION.md): active migration registry for `v3.4.0+`.
- [`MIGRATION.archive.md`](MIGRATION.archive.md): legacy migration registry for versions earlier than `v3.4.0`.
- [`template/copilot-instructions.md`](template/copilot-instructions.md): consumer instruction template delivered by setup.
- [`.github/research/README.md`](.github/research/README.md): research-note layout and archive rules.

Archive naming stays explicit by design. The migration archive remains a single
top-level file because the update flow fetches it directly, while research notes
archive by month under `.github/research/archive/`.

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

Current template version: **5.13.0** <!-- x-release-please-version --> — see [`CHANGELOG.md`](CHANGELOG.md) and [`MIGRATION.md`](MIGRATION.md).

For older installed versions, use [`MIGRATION.archive.md`](MIGRATION.archive.md)
alongside [`MIGRATION.md`](MIGRATION.md).

## Release automation

Pushes to `main` run the full validation workflow first. A final CI release job runs only after the validation jobs succeed, so the same workflow both validates the commit and drives release-please.

Only release-driving changes produce a release. The allowlist is: `template/`, `.github/agents/`, `starter-kits/`, `SETUP.md`, `UPDATE.md`, `AGENTS.md`, and `scripts/workspace/check-workspace-drift.sh`. Workflow changes, docs-only maintainer changes, tests, and other internal maintenance do not release by themselves.

Within the release-driving set, the SemVer policy is explicit:

- Major: any commit marked as a breaking change with `!` or a `BREAKING CHANGE:` footer. Releasable headers such as `fix!:` stay native; non-releasable headers such as `refactor!:` still publish through the forced fallback path.
- Minor: `feat:` for a consumer-facing addition.
- Patch: `fix:`, `deps:`, and release-driving `docs:`, `refactor:`, `perf:`, `build:`, `ci:`, `test:`, or `chore:` changes.
- No release: changes outside the release-driving allowlist.

Use `feat` only for a real consumer-facing capability. Use patch-level headers for corrections, maintenance, wording updates, and refactors. This keeps the minor digit meaningful instead of incrementing it for every release-driving change.

Release-please is the only version writer. Do not bump `VERSION.md`, `.release-please-manifest.json`, or the `x-release-please-version` markers manually.

## Validation entrypoints

- During iterative work, prefer `bash scripts/harness/select-targeted-tests.sh <paths...>` and keep the selected checks narrow. Reserve `bash tests/run-all.sh` for a single end-of-task full-suite gate unless a targeted failure forces broader re-verification.
- Full suite: `bash tests/run-all.sh`
- Captured full suite: `bash scripts/harness/run-all-captured.sh`
- Targeted test selection: `bash scripts/harness/select-targeted-tests.sh <paths...>`
- Workspace index drift: `bash scripts/workspace/sync-workspace-index.sh --check`
- Model registry drift: `bash scripts/sync/sync-models.sh --check`

## Terminal-safe shell protocol

Use this decision order whenever an agent needs the terminal:

1. If an existing repo script already does the job, run that script directly.
2. If the task is a single existing command with no shell control flow, tempfile plumbing, redirection, retries, or shell-specific syntax, direct execution is fine.
3. For any ad hoc snippet beyond that, use an isolated child shell wrapper instead of relying on the persistent terminal's current shell or option state.

For the async terminal tool family, use the exact terminal ID returned by `run_in_terminal` async mode with `get_terminal_output`, `send_to_terminal`, and `kill_terminal`.

Treat those tools as valid only when `run_in_terminal` returned a live terminal ID, usually from async mode or from a sync command that outlived its timeout.

Do not pass terminal labels, shell names, normal editor terminals, or `execution_subagent` results to those tools. Use `terminal_last_command` and `terminal_selection` only for the currently active editor terminal. If you only need command output, prefer `execution_subagent` or a synchronous terminal run over creating a background terminal just to poll it.

Reuse async terminals only for genuinely interactive or persistent sessions, and call `kill_terminal` when the session is no longer needed. Do not add `sleep` loops or blind polling around background terminals. For standard build or run workflows, prefer repo scripts or `create_and_run_task` instead of a persistent interactive shell.

In zsh workspaces, do not issue top-level `set -euo pipefail` or `setopt errexit nounset pipefail` directly into a persistent terminal session. Use the repo wrappers so strict mode stays isolated to a child shell.

For one-line or multi-step snippets:

```bash
bash scripts/harness/run-isolated-shell.sh --shell bash --strict --command 'tmpdir=$(mktemp -d) && printf "ok\n" > "$tmpdir/out" && cat "$tmpdir/out" && rm -rf "$tmpdir"'
```

For zsh-specific syntax:

```bash
bash scripts/harness/run-isolated-shell.sh --shell zsh --command 'print -r -- "$ZSH_VERSION"'
```

For PowerShell syntax:

```bash
bash scripts/harness/run-isolated-shell.sh --shell pwsh --strict --command '$value = "pwsh-ok"; Write-Output $value'
```

For multi-line snippets:

```bash
bash scripts/harness/run-isolated-shell-stdin.sh --shell bash --strict <<'EOF'
tmpdir=$(mktemp -d)
printf 'hello\n' > "$tmpdir/out.txt"
cat "$tmpdir/out.txt"
rm -rf "$tmpdir"
EOF
```

For Bash-specific strict mode, keep `--shell bash --strict` on the generic wrappers.

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
