# Research: GitHub Copilot VS Code — Hooks, Instructions, Agents Schema (April 2026)

> Date: 2026-04-01 | Agent: Researcher | Status: final

## Summary

Six precise questions about VS Code Copilot customisation internals were researched against
live official documentation and the April 2026 release notes (v1.110–v1.114). Key findings:
hooks now support 8 lifecycle events with `sessionId` and `transcript_path` in all common
payloads; `Stop` supports `hookSpecificOutput.decision:"block"`; `systemMessage` is a
user-facing warning, not a system-message injection; context injection uses
`hookSpecificOutput.additionalContext`; `applyTo` is a comma-separated string (not array);
SKILL.md has no stack-filtering metadata; the latest stable is VS Code **1.114** (released
today, 2026-04-01); and several breaking/deprecated changes affect template maintainers.

## Sources

| URL | Relevance |
|-----|-----------|
| <https://code.visualstudio.com/docs/copilot/customization/hooks> | Primary: full hooks schema, all events, input/output format |
| <https://code.visualstudio.com/docs/copilot/customization/custom-instructions> | Primary: `applyTo` syntax, instruction file format |
| <https://code.visualstudio.com/docs/copilot/customization/custom-agents> | Primary: agent frontmatter schema, all fields |
| <https://code.visualstudio.com/docs/copilot/customization/agent-skills> | Primary: SKILL.md frontmatter fields in VS Code |
| <https://agentskills.io/specification> | Primary: open standard SKILL.md spec, `metadata` field |
| <https://code.visualstudio.com/updates/v1_111> | Breaking changes: agent-scoped hooks Preview, `infer` deprecated |
| <https://code.visualstudio.com/updates/v1_112> | New: monorepo parent-repo discovery |
| <https://code.visualstudio.com/updates/v1_113> | Breaking: thinking effort settings deprecated |
| <https://code.visualstudio.com/updates/v1_114> | Latest stable v1.114, released 2026-04-01 |

---

## Q1 — Lifecycle hook events and payload fields

**Source**: <https://code.visualstudio.com/docs/copilot/customization/hooks>

### Supported hook events (8 total)

| Event | When it fires |
|-------|---------------|
| `SessionStart` | User submits the first prompt of a new session |
| `UserPromptSubmit` | User submits any prompt |
| `PreToolUse` | Before agent invokes any tool |
| `PostToolUse` | After tool completes successfully |
| `PreCompact` | Before conversation context is compacted |
| `SubagentStart` | Subagent is spawned |
| `SubagentStop` | Subagent completes |
| `Stop` | Agent session ends |

> **Template gap**: this repo's `copilot-hooks.json` defines 7 events. `SubagentStop` is missing.

### Common input payload (all hooks)

```json
{
  "timestamp": "2026-02-09T10:30:00.000Z",
  "cwd": "/path/to/workspace",
  "sessionId": "session-identifier",
  "hookEventName": "PreToolUse",
  "transcript_path": "/path/to/transcript.json"
}
```

- **`sessionId`**: YES — injected into every hook event's payload.
- **`transcript_path`**: YES — injected into **every** hook event's common payload, not
  just `Stop`. (The Stop hook does not receive any additional unique input fields beyond
  `stop_hook_active`.)

### Stop event: does it support `hookSpecificOutput.decision: "block"`?

**YES.** The documented Stop output schema is:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "reason": "Run the test suite before finishing"
  }
}
```

`decision: "block"` prevents the agent from stopping. `reason` is required when blocking.
When blocked, the agent continues running — this consumes premium requests. Always check
`stop_hook_active` (in the Stop input payload) to prevent infinite loops.

### Common output fields (all hooks)

```json
{
  "continue": false,
  "stopReason": "Security policy violation",
  "systemMessage": "Unit tests failed"
}
```

| Field | Meaning |
|-------|---------|
| `continue` | `false` stops the entire agent session (most drastic) |
| `stopReason` | Reason shown to the user when `continue: false` |
| `systemMessage` | **Warning message displayed to the user in chat** — NOT a system message injected to the model |

### Per-event hookSpecificOutput fields

| Event | hookSpecificOutput fields |
|-------|--------------------------|
| `PreToolUse` | `permissionDecision` (allow/deny/ask), `permissionDecisionReason`, `updatedInput`, `additionalContext` |
| `PostToolUse` | `additionalContext` (plus top-level `decision: "block"`, `reason`) |
| `SessionStart` | `additionalContext` (string — injected into agent's conversation) |
| `Stop` | `decision: "block"`, `reason` |
| `SubagentStart` | `additionalContext` |
| `SubagentStop` | top-level `decision: "block"`, `reason` (no hookSpecificOutput wrapper needed) |
| `UserPromptSubmit` | None (common output only) |
| `PreCompact` | None (common output only) |

---

## Q2 — `.instructions.md` applyTo patterns

**Source**: <https://code.visualstudio.com/docs/copilot/customization/custom-instructions>

### Syntax

`applyTo` is a **single YAML string**, not an array. Comma-separated glob patterns are
supported within that string:

```yaml
---
applyTo: "**/*.ts,**/*.tsx"
---
```

The documentation also shows single-glob usage:

```yaml
applyTo: '**/*.py'
```

and a wildcard for all files:

```yaml
applyTo: "**"
```

**Not an array** — `applyTo: ["**/*.ts", "**/*.tsx"]` is not shown in any documentation
example, and no array syntax is mentioned.

### What happens when the pattern matches zero files?

The documentation states: "If not specified [or no files match the pattern implied by
agenttic context], the instructions are not applied automatically, but you can still add
them manually to a chat request."

The agent determines which instruction files apply based on two criteria:
1. The `applyTo` glob pattern matching files currently being worked on
2. Semantic matching of the `description` field to the current task

If no files in the workspace match the `applyTo` pattern **and** no task semantically
matches the `description`, the instruction does **not** load automatically. It is not
session-wide always-on — it is conditionally activated. You can still attach it manually.

---

## Q3 — Agent frontmatter schema (current, as of v1.113–v1.114)

**Source**: <https://code.visualstudio.com/docs/copilot/customization/custom-agents>

### All supported fields

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | Agent description, shown as placeholder text |
| `name` | string | Agent name (defaults to file name) |
| `argument-hint` | string | Hint text in chat input |
| `tools` | list | Tool/tool-set names available to this agent |
| `agents` | list | Agent names allowed as subagents (`*` = all, `[]` = none) |
| `model` | string or array | AI model name(s) in priority order |
| `user-invocable` | boolean | Whether agent appears in dropdown (default: `true`) |
| `disable-model-invocation` | boolean | Prevent other agents invoking this as subagent (default: `false`) |
| `infer` | — | **DEPRECATED** — use `user-invocable` + `disable-model-invocation` |
| `target` | string | `vscode` or `github-copilot` |
| `mcp-servers` | list | MCP server config for GitHub Copilot cloud agents only |
| `handoffs` | list | Suggested next-step actions; each has `label`, `agent`, `prompt`, `send`, `model` |
| `hooks` | object | Agent-scoped hooks (Preview) — same format as hook JSON config files |

### New in recent releases

- **`hooks` in frontmatter** (v1.111, Preview): attach hooks scoped to this agent. Requires
  `chat.useCustomAgentHooks: true`.
- **`handoffs.model`** uses qualified format: `"Claude Sonnet 4.5 (copilot)"` or
  `"GPT-5 (copilot)"`.
- **Nested subagents** (v1.113): `agents` list can now include subagents that themselves
  invoke subagents, when `chat.subagents.allowInvocationsFromSubagents` is enabled.

### Deprecated

- **`infer`**: previously `infer: false` hid from picker and blocked subagent invocation.
  Now replaced by `user-invocable: false` (hides picker, allows subagent) and
  `disable-model-invocation: true` (blocks subagent, keeps in picker).

---

## Q4 — `systemMessage` vs `additionalContext` in hook output

**Source**: <https://code.visualstudio.com/docs/copilot/customization/hooks>

### Critical distinction

| Field | Location | Effect |
|-------|----------|--------|
| `systemMessage` | Top-level common output | **Displays a warning to the user** in the chat UI — does NOT inject into agent context |
| `additionalContext` | Inside `hookSpecificOutput` | **Injects text into the agent's conversation** — actual context injection |

`systemMessage: "Unit tests failed"` is a user-facing notification. The model does not
receive it as a system message.

### Correct SessionStart output for context injection

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Project: my-app v2.1.0 | Branch: main | Node: v20.11.0"
  }
}
```

`additionalContext` is the **only** supported mechanism for injecting text into the agent's
conversation from a `SessionStart` hook. `systemMessage` in the top-level output will
display a warning in the UI but will not be seen by the model.

### Summary by event

| Event | Injection field | Warning display field |
|-------|----------------|----------------------|
| `SessionStart` | `hookSpecificOutput.additionalContext` | top-level `systemMessage` |
| `PreToolUse` | `hookSpecificOutput.additionalContext` | top-level `systemMessage` |
| `PostToolUse` | `hookSpecificOutput.additionalContext` | top-level `systemMessage` |
| `SubagentStart` | `hookSpecificOutput.additionalContext` | top-level `systemMessage` |
| `UserPromptSubmit` | none (common output only) | top-level `systemMessage` |
| `Stop` | none (hooks cannot inject on stop) | top-level `systemMessage` |

---

## Q5 — Skill `stacks` or metadata filtering

**Sources**: <https://code.visualstudio.com/docs/copilot/customization/agent-skills>,
<https://agentskills.io/specification>

### VS Code Copilot SKILL.md supported fields

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | Lowercase, hyphens, max 64 chars |
| `description` | Yes | Max 1024 chars; drives when VS Code loads the skill |
| `argument-hint` | No | Hint text for slash command |
| `user-invocable` | No | Show in `/` menu (default: true) |
| `disable-model-invocation` | No | Prevent auto-loading by agent (default: false) |

**There is no `stacks`, `tags`, `stack`, or language/framework filtering field supported
in VS Code's SKILL.md implementation.**

### Agent Skills open standard (agentskills.io)

The open standard adds these optional fields:

| Field | Notes |
|-------|-------|
| `license` | License name |
| `compatibility` | Max 500 chars — environment requirements, intended product |
| `metadata` | Arbitrary key-value map |
| `allowed-tools` | Space-delimited pre-approved tools (Experimental) |

The `compatibility` field can describe intended product or environment (e.g.,
`"Requires: Node.js 20+"`), and `metadata` allows arbitrary keys. However:

- **VS Code does not document support for `compatibility`, `metadata`, or `allowed-tools`**
  in its SKILL.md loading logic.
- No VS Code documentation describes using any frontmatter field for stack-based filtering.

### Conclusion

**Stack-based filtering is purely an agent-implemented concern.** VS Code selects which
skills to load based solely on:
1. The `description` field (semantic relevance to current task)
2. Manual invocation via `/skill-name` slash command

There is no supported frontmatter syntax that causes VS Code to filter skills by detected
project stack. The `compatibility` and `metadata` spec fields exist in the open standard
but VS Code does not use them for automatic filtering.

---

## Q6 — Latest VS Code Copilot version and breaking changes

### Latest stable release: VS Code **1.114** (2026-04-01)

Previous recent stable releases:

| Version | Date | Key relevance |
|---------|------|---------------|
| v1.110 | 2026-03-04 | Agent plugins, agentic browser tools, Agent Debug Panel, Edit Mode deprecated |
| v1.111 | 2026-03-09 | Autopilot/agent permissions; **agent-scoped hooks Preview** (`hooks` in .agent.md); SubagentStop event added |
| v1.112 | 2026-03-18 | /troubleshoot skill; sandbox MCP servers; monorepo parent-repo discovery |
| v1.113 | 2026-03-25 | Chat Customizations editor; thinking effort in model picker; nested subagents; **thinking effort settings deprecated** |
| v1.114 | 2026-04-01 | /troubleshoot for previous sessions; #codebase now pure semantic search only |

VS Code moved to **weekly Stable releases** starting v1.111.

### Breaking / deprecated changes relevant to template maintainers

1. **`infer` agent field deprecated** (v1.111): Replace `infer: false` with
   `user-invocable: false` and/or `disable-model-invocation: true`.
   Both fields now exist in `.github/agents/*.agent.md` files.

2. **Edit Mode deprecated** (v1.110): Will be fully removed at v1.125. Users can
   temporarily re-enable via `chat.editMode.hidden`. Template references to Edit Mode
   should be flagged for removal.

3. **Thinking effort settings deprecated** (v1.113):
   - `github.copilot.chat.anthropic.thinking.effort`
   - `github.copilot.chat.responsesApiReasoningEffort`
   Both replaced by UI-level thinking effort selector in the model picker. Remove from any
   template settings stubs.

4. **Agent-scoped hooks in `.agent.md` frontmatter** (v1.111, Preview): New `hooks` field
   is preview-gated behind `chat.useCustomAgentHooks: true`. Not stable; do not document
   as stable API.

5. **SubagentStop hook event** (v1.111): Documented as one of the 8 supported events.
   The template's `copilot-hooks.json` does not yet register a `SubagentStop` handler.

6. **#codebase behaviour change** (v1.114): Now purely semantic search. Previously could
   fall back to fuzzy text search. Any instructions telling agents to rely on #codebase for
   exact-match text search should be updated.

7. **Monorepo parent-repo discovery** (v1.112): New setting
   `chat.useCustomizationsInParentRepositories`. Template `SETUP.md` guidance may want to
   mention this for monorepo consumers.

8. **Nested subagents** (v1.113): `chat.subagents.allowInvocationsFromSubagents` now
   enables subagents to invoke other subagents. Template sub-agent depth guidance (max 3)
   remains valid but should note this setting exists.

---

## Recommendations

1. **Add `SubagentStop` handler to `copilot-hooks.json`** — it is a documented event but
   missing from the template.
2. **Remove `infer` from any `.agent.md` files** — deprecated; use `user-invocable` +
   `disable-model-invocation`.
3. **Audit template instructions for thinking-effort settings** — both deprecated settings
   should be removed.
4. **Clarify `systemMessage` vs `additionalContext`** in hook script comments — the
   template's `session-start.sh` should confirm it uses `hookSpecificOutput.additionalContext`
   not top-level `systemMessage` for context injection.
5. **Document `compatibility` as description guidance** for SKILL.md authors — although
   VS Code doesn't use it for filtering, it is available in frontmatter without breaking
   the spec.

## Gaps / Further research needed

- Confirm whether comma-separated `applyTo` values (e.g., `"**/*.ts,**/*.tsx"`) are
  processed as separate globs or as a single pattern. The documentation shows this form
  but does not explicitly call out comma as a separator.
- Confirm VS Code's handling of `metadata` and `compatibility` SKILL.md fields — whether
  they are silently ignored or cause a validation error.
- Confirm whether `transcript_path` in common hook input is a stable API or Preview.
