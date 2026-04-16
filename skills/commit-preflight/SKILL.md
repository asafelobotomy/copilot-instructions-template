---
name: commit-preflight
description: Inspect active GitHub Actions workflows before commit or push, run matching local checks for staged or unpushed files, ask which missing tools to install via askQuestions, and fix in-scope issues so the Commit agent can proceed.
compatibility: ">=1.4"
---

# Commit Preflight

> Skill metadata: version "1.0"; license MIT; tags [commit, preflight, ci, workflow, git]; compatibility ">=1.4"; recommended tools [codebase, runCommands, editFiles, askQuestions].

Inspect active workflows before commit/push and clear locally reproducible failures before the Commit agent proceeds.

## When to use

- User asks to commit/push and the repo has GitHub Actions workflows or local CI scripts

## When not to use

- No local checks to run, gate depends on secrets/hosted services, or user explicitly skips verification

## Steps

1. Determine candidate file set.
   - Commit: `git diff --cached --name-only` (if empty and staging approved, use proposed list).
   - Push: diff against `origin/<branch>`. Stop if empty.

2. Discover active workflow gates.
   - Read `.github/workflows/*.yml`. Prioritise `push` triggers for current branch; include `pull_request` workflows running the same checks.
   - Honor `branches`, `branches-ignore`, `paths`, `paths-ignore` (both must match when combined).
   - Treat `workflow_run` as downstream unless it exposes a documented local command.

3. Build local execution plan (cheapest → most expensive).
   - Prefer explicit `run:` commands and repo scripts. Use curated equivalents for wrapper actions.

   | Workflow shape | Local preflight command |
   |----------------|-------------------------|
   | `run: bash tests/run-all.sh` | Run the exact command |
   | `run: bash scripts/... --check` | Run the exact command |
   | `uses: DavidAnson/markdownlint-cli2-action` | `npx markdownlint-cli2 ...` with the workflow globs |
   | `uses: raven-actions/actionlint` | `actionlint` |
   | `uses: ludeeus/action-shellcheck` | `shellcheck` with the workflow severity |
   | `run: pip install yamllint` + `yamllint ...` | Probe or install `yamllint`, then run the exact lint command |

4. Probe dependencies.
   - `command -v` each required tool. Reuse workflow install steps when available.
   - Never install silently. Use `askQuestions` for missing tools only.

   ```yaml
   header: "Preflight Dependencies"
   question: "Some preflight checks need tools that are not installed. Which tools, if any, would you like me to install before I continue?"
   multiSelect: true
   allowFreeformInput: false
   options:
     - label: "Install yamllint"
       description: "Needed for YAML lint; the workflow already uses pip install yamllint --quiet"
       recommended: true
     - label: "Install actionlint"
       description: "Needed for workflow lint"
     - label: "Install none"
       description: "Skip the missing-tool checks and decide after the risk summary"
   ```

   > Fallback: If `askQuestions` is unavailable, present the same choices as a
   > numbered list in chat.

5. Install only approved tools. Use workflow install commands first; re-probe after install. Mark failed installs as unavailable.

6. Run checks: read-only first, file-scoped before full-suite. Capture command, exit status, affected files.

7. Repair in-scope failures only. If fix requires out-of-scope files, ask before widening. Rerun affected checks after each repair.

8. Decide proceed/block. All pass → concise summary. Skipped checks → `askQuestions` for residual risk. Any required check failing → block with exact blocker.

9. Summary: executed checks, skipped checks (with reason), auto-fixed files, proceed/block verdict.

## Verify

- Workflow-backed checks discovered from `.github/workflows/`
- Dependencies probed before install; installs approved via `askQuestions`
- Auto-fixes stayed in scope or were re-approved
- Commit agent received clear pass, block, or residual-risk outcome
