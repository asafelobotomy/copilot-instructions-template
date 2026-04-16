# Lean/Kaizen Copilot Instructions Template

A versioned, self-updating GitHub Copilot instruction template that keeps AI developer behaviour consistent across projects.

## Repository map

## Set up in your project

1. Install the plugin: open VS Code → `Chat: Install Plugin` → search **copilot-instructions-template**.
2. Tell Copilot:

> *"Set up this project"*

The Setup agent runs a personalisation wizard using the locally-installed plugin. No manual file copying or URL fetching required.

## Update an existing installation

Tell Copilot:

> *"Update your instructions"*

The Setup agent compares your installed version against the plugin version and applies a selective update.

## Recover a broken installation

Tell Copilot:

> *"Factory restore instructions"*

The Setup agent backs up every template-managed surface, removes those files from the working tree, and reruns the full setup from scratch.

## All trigger phrases

See [`AGENTS.md`](AGENTS.md) for the full list of direct consumer-facing commands (heartbeat, retrospective, tools, skills, MCP, hooks, and more).

## Keep delegation narrow

Agent delegation stays narrow by design. See [`AGENTS.md`](AGENTS.md) for the entrypoint rules and [`template/copilot-instructions.md`](template/copilot-instructions.md) for the consumer runtime policy. Keep each `agents:` allow-list limited to explicit workflow handoffs rather than speculative convenience delegates.

## Version

Current template version: **0.6.1** <!-- x-release-please-version --> — see [`CHANGELOG.md`](CHANGELOG.md).

## Release automation

Pushes to `main` run the full validation workflow first. A final CI release job runs only after the validation jobs succeed.

Version bumps are done locally. Bump `VERSION.md` and all `<!-- x-release-please-version -->` markers together, then verify with `bash scripts/release/verify-version-references.sh`. When the push lands on `main` and the version in `VERSION.md` does not yet have a corresponding git tag, CI creates a GitHub release automatically.

SemVer policy:

- Major: breaking changes to consumer-facing surfaces.
- Minor: `feat:` for a consumer-facing addition.
- Patch: fixes, maintenance, wording updates, and refactors.

Use `feat` only for a real consumer-facing capability. Use patch-level headers for corrections, maintenance, wording updates, and refactors. This keeps the minor digit meaningful instead of incrementing it for every change.

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
- Enable squash merge.

Audit the live repository settings with an authenticated GitHub CLI session:

```bash
bash scripts/release/audit-release-settings.sh
```
