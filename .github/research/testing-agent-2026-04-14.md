# Research: Testing Agent

> Date: 2026-04-14 | Agent: Researcher | Status: final

## Summary

Do not add a `Testing` agent to the base catalog yet. The current repo already
covers the main testing workflows through `Code`, `Debugger`, `Review`, the
`test-coverage-review` skill, the `webapp-testing` skill, and the `/test-gen`
prompt. A dedicated Testing agent becomes justified only if the repo grows a
repeatable test-generation workflow that is distinct enough from general code
implementation to avoid routing ambiguity.

## Sources

| URL | Relevance |
|-----|-----------|
| <https://code.visualstudio.com/docs/copilot/customization/custom-agents> | Current custom-agent contract and routing surface for any future Testing agent |
| <https://code.visualstudio.com/docs/copilot/reference/copilot-vscode-features#_chat-tools> | Current built-in tool surface relevant to test generation and execution |
| <https://www.anthropic.com/research/building-effective-agents> | Useful boundary guidance for when a specialist workflow deserves its own agent |

## Repo signals

- The repo already has a `test-coverage-review` skill for read-only coverage and CI-gap analysis.
- The repo already has a `webapp-testing` skill for browser and Playwright testing setup.
- `Code` already owns test-writing requests as part of normal implementation work.
- `Debugger` already owns unclear failing-test diagnosis and root-cause isolation.
- The earlier catalog review placed browser-testing specialists in starter kits or optional layers rather than the base catalog.

## Recommendation

Keep `Testing` out of the base catalog for now.

- Best fit today: optional starter-kit agent or future installable specialist
- Base-catalog status: not recommended yet
- Visibility if added later: internal specialist first, not picker-visible

## Why not now

The current trigger surface is still too ambiguous.

- "Write tests for X" naturally routes to `Code`
- "Why is this test failing?" naturally routes to `Debugger`
- "Review my tests" naturally routes to `Review`
- "Check coverage" already maps to the `test-coverage-review` skill

Adding a Testing agent now would duplicate those entry points without a crisp
enough routing boundary.

## Future role boundary

If the repo adds Testing later, the role should be narrow and execution-focused.

### Good at

- scaffolding a new test framework in a repo
- generating missing tests for named modules or files
- filling coverage gaps after a coverage audit
- refactoring test-only helpers and suite layout
- wiring CI test workflows and coverage gates

### Not good at

- fixing source-code bugs revealed by tests
- diagnosing unclear test failures at root-cause level
- security review of test infrastructure
- documentation-only test strategy work
- commit, push, or release operations

## Proposed future contract

If added later, start with this shape:

```yaml
tools: [agent, editFiles, runCommands, codebase, search, askQuestions]
mcp-servers: [filesystem, git, context7, playwright, heartbeat]
user-invocable: false
model:
  - GPT-5.3-Codex
  - Claude Sonnet 4.6
  - GPT-5.2-Codex
```

Delegates should include `Code`, `Debugger`, `Review`, `Commit`, and `Researcher`.

## Future trigger phrases

If the agent is added later, the cleanest user phrases are:

- "Add tests to ..."
- "Write tests for ..."
- "Set up tests"
- "Fill my coverage gaps"
- "Scaffold a test suite"

These still need suppress-pattern protection so they do not steal work that
belongs to `Code` or `Debugger`.

## Minimal future file set

If a `Testing` agent is added later, the smallest coherent change set is:

- `.github/agents/testing.agent.md`
- `.github/agents/routing-manifest.json`
- `.github/copilot-instructions.md`
- `AGENTS.md`
- `MODELS.md`
- `scripts/copilot_audit/checks_agents.py`
- `tests/contracts/test-customization-contracts-agents.sh`
- `tests/contracts/test-customization-contracts-policies.sh`
- regenerated `llms.txt`
- regenerated `.copilot/workspace/operations/workspace-index.json`

## Decision

Treat `Testing` as a tracked future candidate rather than a base-catalog agent.
Revisit it when the repo adds a distinctive test-generation workflow, starter-kit
testing bundles, or JiT-style test automation that can no longer live cleanly
inside `Code` plus existing skills.