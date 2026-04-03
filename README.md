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

## All trigger phrases

See [`AGENTS.md`](AGENTS.md) for the full list of commands (health check, retrospective, skills, MCP, hooks, and more).

## Keep delegation narrow

Agent delegation stays narrow by design. See [`AGENTS.md`](AGENTS.md) for the entrypoint rules and [`template/copilot-instructions.md`](template/copilot-instructions.md) for the consumer runtime policy. Keep each `agents:` allow-list limited to explicit workflow handoffs rather than speculative convenience delegates.

## Version

Current template version: **5.3.0** <!-- x-release-please-version --> — see [`CHANGELOG.md`](CHANGELOG.md) and [`MIGRATION.md`](MIGRATION.md).

## Release automation

After a commit lands on `main`, GitHub runs the full workflow set first. When CI passes, the release workflow evaluates only consumer-facing paths: `template/`, `.github/agents/`, `starter-kits/`, `SETUP.md`, and `UPDATE.md`.

Changes outside that surface are treated as developer-only and do not produce a release. Consumer-facing changes do produce a release: `feat` commits keep a minor bump, `fix` and `deps` keep a patch bump, and non-releasable commit headers fall back to a forced patch release so consumer updates are still tagged and published.
