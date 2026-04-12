# Plan: Plugin Packaging and Answers-File Generator — Next Steps

> Date: 2026-04-12 | Agent: Docs | Status: active
> Builds on: [copilot-bootstrap-distribution-2026-04-12.md](copilot-bootstrap-distribution-2026-04-12.md)

## Summary

Two deliverables move this repo from a purely script-bootstrapped distribution
model to one that supports both native plugin install and pre-answered automated
setup. Neither changes the existing `SETUP.md` or `UPDATE.md` flow. Both are
additive.

**Deliverable 1 — Root plugin packaging**: add `plugin.json` and `.mcp.json` at
the repo root so `asafelobotomy/copilot-instructions-template` can be installed
directly via Copilot's "Install Plugin From Source" path. Wire in the existing
`.github/skills/`, `.github/agents/`, and `.github/hooks/` assets.

**Deliverable 2 — Answers file plus generator**: define a
`.github/copilot-answers.json` schema that consumers can pre-populate to skip
the interactive interview in `SETUP.md` §0d. Add a generator script that
produces a starter file from the interview question set. Integrate the read
path into `SETUP.md` and `UPDATE.md`.

## Task Matrix

| ID | Task | Priority | Status | Owning files | Verification |
|----|------|----------|--------|--------------|--------------|
| P1 | Draft root `plugin.json` with name, display name, description, and version | High | Not started | `plugin.json` | CI parity check and manual plugin install |
| P2 | Draft root `.mcp.json` with plugin-scoped servers that are safe to trust at plugin-install time | High | Not started | `.mcp.json` | Manual plugin MCP smoke test |
| P3 | Add plugin recommendation settings for consumers | High | Not started | `.vscode/settings.json`, `template/vscode/settings.json` | `validate-template-sync.sh` and manual workspace prompt |
| P4 | Wire plugin recommendation settings into setup manifests | High | Not started | `template/setup/manifests.md` | `tests/contracts/test-setup-update-contracts.sh` |
| P5 | Track root plugin surfaces in workspace inventory | Medium | Not started | `workspace-index.json`, `scripts/workspace/sync-workspace-index.sh` | `bash scripts/workspace/sync-workspace-index.sh --check` |
| P6 | Add CI guard so root `plugin.json` version matches `VERSION.md` | Medium | Not started | `scripts/release/verify-version-references.sh` or new CI helper | Full suite |
| P7 | Document the install-from-source plugin path for maintainers and consumers | Low | Not started | `README.md` | Docs review |
| A1 | Define `copilot-answers.json` schema keyed to `interview.md` question IDs | High | Not started | `template/setup/answers-schema.json`, `template/setup/interview.md` | Schema validation and round-trip test |
| A2 | Generate a starter answers file with defaults | High | Not started | `scripts/setup/generate-answers-stub.sh` | New targeted script test |
| A3 | Read answers file in `SETUP.md` and skip already-covered interactive questions | High | Not started | `SETUP.md`, `.github/agents/setup.agent.md` | Setup/update contracts and manual dry run |
| A4 | Read answers file during factory restore and update flows where it helps | Medium | Not started | `UPDATE.md`, `.github/agents/setup.agent.md` | Setup/update contracts |
| A5 | Add answers file to the managed file-manifest set | Medium | Not started | `template/setup/manifests.md` | Setup/update contracts |
| A6 | Keep `<!-- setup-answers -->` output sourced from resolved answers rather than chat-only state | Low | Not started | `.github/agents/setup.agent.md`, `template/setup/manifests.md` | Version file contract coverage |
| A7 | Add answers schema to parity and validation checks | Low | Not started | `scripts/ci/validate-template-sync.sh` and related contracts | Full suite |
| M1 | Add migration entry for root plugin files | Medium | Not started | `MIGRATION.md` | Release reference verification |
| M2 | Add migration entry for optional answers file support | Medium | Not started | `MIGRATION.md` | Release reference verification |

## Build The Root Plugin

### Phase 1-A — Add Core Plugin Artefacts

Goal: produce a minimal installable plugin.

Steps:

1. Read the current plugin manifest shape from `starter-kits/*/plugin.json`.
2. Draft `plugin.json` at the repo root with:
   - `name`: `copilot-instructions-template`
   - `displayName`: `Lean/Kaizen Copilot Instructions Template`
   - `description`: one-line summary aligned with `README.md`
   - `version`: sourced from `VERSION.md`
3. Point the plugin at live repo assets under `.github/` rather than `template/`.
4. Draft root `.mcp.json` with the smallest safe server set. Start with
   heartbeat only unless filesystem access in plugin scope is proven clean.
5. Confirm the plugin trust model stays explicit. Only include servers whose
   code lives in the repo.

Acceptance: `Chat: Install Plugin From Source` loads agents and skills without
schema or path errors.

### Phase 1-B — Add Distribution Hooks

Goal: make the plugin easy to adopt in consumer workspaces.

Steps:

1. Add `enabledPlugins` and `extraKnownMarketplaces` to
   `.vscode/settings.json` and `template/vscode/settings.json`.
2. Mirror the same settings block into `template/setup/manifests.md` so setup
   writes it for consumers.
3. Extend workspace inventory so root plugin surfaces are tracked alongside
   agents, skills, hooks, and starter kits.

Acceptance: template parity passes and workspace-index sync reports no drift.

### Phase 1-C — Guard Versioning And Migration

Goal: stop silent drift between root plugin metadata and release versioning.

Steps:

1. Add a CI check that asserts root `plugin.json` version matches `VERSION.md`.
2. Add a migration entry that marks root plugin files as additive and
   consumer-optional.
3. Keep release ownership with release-please. Do not create a second version
   source of truth.

Acceptance: release verification and the full suite pass on the first versioned
plugin commit.

## Add The Answers File And Generator

### Phase 2-A — Define The Schema

Goal: formalize what an answers file may contain.

Steps:

1. Read `template/setup/interview.md` and map each question ID to a machine key.
2. Create `template/setup/answers-schema.json` using a stable JSON Schema draft.
3. Keep all properties optional so partial answers files remain valid.
4. Record defaults in schema descriptions so skipped keys have clear semantics.

Acceptance: a generated stub validates cleanly against the schema.

### Phase 2-B — Generate A Default Stub

Goal: let a consumer create a pre-filled answers file in one command.

Steps:

1. Write `scripts/setup/generate-answers-stub.sh`.
2. Read question IDs and defaults from the schema or the interview source.
3. Write `.github/copilot-answers.json` with every supported key present.
4. Support `--dry-run` so the script can print to stdout without side effects.
5. Add a focused test that validates JSON shape, key coverage, and dry-run
   behavior.

Acceptance: the script produces valid JSON and the new targeted test passes.

### Phase 2-C — Read Answers During Setup And Update

Goal: skip manual interview steps when the answers file already covers them.

Steps:

1. Add a pre-read step to `SETUP.md` before the interactive interview batch.
2. If `.github/copilot-answers.json` exists and validates, treat present keys as
   answered and only ask about missing fields.
3. Mirror the same read path in `UPDATE.md` where recovery or restore flows
   benefit from preserved setup answers.
4. Keep `<!-- setup-answers -->` in `.github/copilot-version.md` as the durable
   rendered output for update logic.
5. Add the answers file to the managed file-manifest set so drift is visible.

Acceptance: a setup dry run with a pre-populated answers file skips covered
questions and preserves the current update semantics.

### Phase 2-D — Close The Loop In CI And Migration

Goal: make the new answers-file surface durable and release-safe.

Steps:

1. Add schema and generator paths to parity and validation checks.
2. Add migration notes that explain the answers file is optional and additive.
3. Keep old consumers working unchanged when no answers file exists.

Acceptance: full suite passes and migration notes are complete.

## Roll Out In This Order

```text
Phase 1-A
  -> Phase 1-B
    -> Phase 1-C

Phase 2-A
  -> Phase 2-B
    -> Phase 2-C
      -> Phase 2-D
```

The two streams can run in parallel. Phase 1-C and Phase 2-D are the release
gates for their respective streams.

## Decide These Open Questions First

| ID | Question | Why it matters |
|----|----------|----------------|
| OQ1 | Should root `plugin.json` version mirror `VERSION.md` directly through release-please? | Prevents a second version source of truth. |
| OQ2 | Which MCP servers belong in plugin scope, if any beyond heartbeat? | Plugin trust is broader than consumer MCP prompts. |
| OQ3 | Should `.github/copilot-answers.json` be committed by default or treated as local-only? | Affects setup language and consumer expectations. |
| OQ4 | Should the generator script ship to consumers or stay developer-only? | Changes whether the answers workflow is reusable after setup. |
| OQ5 | Should root plugin support be marked preview until the schema stabilizes? | Reduces churn risk from upstream plugin API changes. |
| OQ6 | Should installing the plugin ever shorten `SETUP.md`, or should plugin install and bootstrap stay fully independent? | Affects complexity and user mental model. |

## Use These Verification Steps

During implementation, keep verification scoped to the touched surfaces first:

1. `bash scripts/harness/select-targeted-tests.sh <paths...>`
2. Run the selected targeted suites for the changed files.
3. Run `bash tests/run-all.sh` once before marking the full task complete.

## Cross References

- [copilot-bootstrap-distribution-2026-04-12.md](copilot-bootstrap-distribution-2026-04-12.md)
- [SETUP.md](../../SETUP.md)
- [UPDATE.md](../../UPDATE.md)
- [template/setup/interview.md](../../template/setup/interview.md)
- [template/setup/manifests.md](../../template/setup/manifests.md)
- [starter-kits/REGISTRY.json](../../starter-kits/REGISTRY.json)