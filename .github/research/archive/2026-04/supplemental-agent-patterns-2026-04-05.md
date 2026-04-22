# Research: Supplemental Agent Patterns — Verification, Handoff, Recovery, Lifecycle, Testing, Config

> Date: 2026-04-05 | Agent: Researcher | Status: complete
> Builds on: `.github/research/claw-code-2026-04-05.md`

## Summary

This supplemental pass gathered primary-source evidence for the seven improvement areas
identified from the `claw-code` analysis. Key result: six of the seven improvement
recommendations are STRENGTHENED by official VS Code and GitHub Copilot documentation
published in the April 2026 release cycle. The seventh (machine-readable sequential state
machine / LaneEvents) has no official VS Code equivalent — formal lane state transitions
are unsupported; the recommendation should be scoped down to a named event vocabulary
only. Two subsidiary ideas — WorkerBoot trust gate and a full mock parity server — should
be dropped in favour of cheaper official alternatives (VS Code permission levels and BATS
shell testing respectively).

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://code.visualstudio.com/docs/copilot/customization/hooks> | Official hooks spec: 8 lifecycle events, full I/O schema, exit codes, Stop loop prevention |
| <https://code.visualstudio.com/docs/copilot/customization/custom-agents> | Official agent frontmatter: handoffs, hooks, agents, model array, user-invocable |
| <https://code.visualstudio.com/docs/copilot/agents/subagents> | Subagent invocation, context isolation, synchronous/parallel execution, restrict-via-agents |
| <https://code.visualstudio.com/docs/copilot/agents/overview> | Agent types, permission levels, handoff workflow, /delegate command |
| <https://code.visualstudio.com/docs/copilot/agents/planning> | Plan agent 4-phase workflow, session memory save, chat.planAgent.defaultModel |
| <https://code.visualstudio.com/docs/copilot/agents/copilot-cli> | Copilot CLI isolation modes (worktree/workspace), /yolo, /compact, worktree auto-commit |
| <https://code.visualstudio.com/docs/copilot/agents/cloud-agents> | Cloud agent limits: no VS Code tools, only local unauthenticated MCP servers |
| <https://code.visualstudio.com/docs/copilot/concepts/agents> | Agent loop anatomy: Understand → Act → Validate; subagent context isolation |
| <https://code.visualstudio.com/docs/copilot/concepts/customization> | Customisation hierarchy: instructions → prompts → skills → agents → hooks → plugins |
| <https://code.visualstudio.com/docs/copilot/customization/overview> | Customisation overview; parent-repository discovery for monorepos |
| <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/manage-agents> | Cloud agent 5-step workflow: start, monitor, steer, open in IDE, review+merge |
| <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents> | Custom agent profile: name, description, tools, mcp-servers, repo/org/enterprise levels |
| <https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-custom-agents> | Custom agent profile format, scoping (repo / org / enterprise), usage surfaces |
| <https://modelcontextprotocol.io/specification/2025-03-26/basic/lifecycle> | MCP lifecycle: Initialization → Operation → Shutdown; 3 error scenarios |
| <https://modelcontextprotocol.io/specification/2025-03-26/basic/utilities/ping> | MCP ping liveness check; timeout → stale; multiple failures → connection reset |
| <https://modelcontextprotocol.io/specification/2025-03-26/basic/utilities/cancellation> | MCP cancellation notification; race conditions must be handled gracefully |
| <https://modelcontextprotocol.io/docs/concepts/transports> | MCP stdio transport security; Streamable HTTP; session ID; resumability |
| <https://agentskills.io/specification> | Agent Skills open spec v2026: frontmatter fields, progressive disclosure, validation |
| <https://12factor.net/config> | 12-factor III: env var preference; no named-env groups; strict config/code separation |
| <https://bats-core.readthedocs.io/en/stable/tutorial.html> | BATS (Bash Automated Testing System): run/assert_output; stdin/stdout testing of scripts |

---

## Findings by Focus Area

### Area 1 — Formal Test-Scope / Green-Contract Style Verification Tiers

**New evidence:**

VS Code's official agent loop concept (`/docs/copilot/concepts/agents`) explicitly names
three stages — **Understand, Act, Validate** — where Validate is defined as:
> "The agent runs tests, checks for compiler errors, and reviews its own changes. If
> something is wrong, it continues iterating."

The Plan agent (`/docs/copilot/agents/planning`) uses a 4-phase workflow (Discovery,
Alignment, Design, Refinement) and does not make code changes until the plan is approved.
This is a formal verification gate before any write operations. The Copilot CLI
worktree-isolation mode auto-commits at the end of each turn, creating an implicit
`MergeReady` checkpoint aligned with a branch boundary.

The cloud/CLI agent docs state the explicit prerequisite: tasks must have
**"well-defined scope and all necessary context"** to be handed off to background or cloud
agents. This is the informal verbal equivalent of a GreenContract gate.

**Assessment:** STRENGTHENS the recommendation. Official tooling has the same structural
idea but uses no machine-checkable typed representation. The absence of a typed
enum/contract is the gap our GreenContract formalisation would fill.

**Concrete implication for this repo:** Rename the implied levels to align with official
VS Code language:

| claw-code name | Proposed alias | VS Code analogue |
|---|---|---|
| `TargetedTests` | `PathTargeted` | Run targeted tests during Validate stage |
| `Package` | `AffectedSuite` | Broaden when shared helpers are touched |
| `Workspace` | `FullSuite` | Full `bash tests/run-all.sh` pass |
| `MergeReady` | `MergeGate` | Cloud agent PR creation prerequisite |

Embed these tier names in a short table in the PDCA section of
`template/copilot-instructions.md` (replaces the current prose-only description).
This makes the tier machine-checkable by the `copilot_audit.py` check suite.

---

### Area 2 — Structured Task Brief / Task-Packet Patterns for Agent Handoffs

**New evidence:**

VS Code now has an official `handoffs` frontmatter field in `.agent.md` files
(`/docs/copilot/customization/custom-agents`):

```yaml
handoffs:
  - label: Start Implementation
    agent: implementation
    prompt: Now implement the plan outlined above.
    send: false
    model: GPT-5.2 (copilot)
```

Fields map directly to TaskPacket concepts:

| TaskPacket field | VS Code handoff equivalent |
|---|---|
| `objective` | `prompt` |
| `scope` | Agent definition body |
| `acceptance_tests` | absent — gap |
| `commit_policy` | absent — gap |
| `escalation_policy` | absent — gap |
| `reporting_contract` | absent — gap |

The Plan agent saves its plan to `/memories/session/plan.md` — this is a known, stable
location for the task brief that persists through the session and is accessible by
handoff recipients.

The GitHub Copilot cloud agent use a structured 5-step workflow:
select repo + agent, monitor status, steer with steering prompts, open in IDE, review PR.
Every step except "monitor" can be addressed via a prepared task brief.

**Assessment:** STRENGTHENS the recommendation. Official tooling uses a structured
handoff schema already — but it lacks the `acceptance_tests`, `escalation_policy`, and
`reporting_contract` fields. Those are the value-add of our TaskPacket proposal.

**Concrete implication for this repo:**
1. Add a `TaskBrief` section to the Commit agent prompt template (`.github/agents/Commit.agent.md`)
   with explicit `acceptance_tests:`, `escalation_policy:`, and `reporting_contract:` fields.
2. When any agent writes to `/memories/session/plan.md`, include these fields.
3. The `handoffs` field in `.agent.md` is the delivery mechanism — do not add a parallel
   custom mechanism; extend what VS Code already provides.

---

### Area 3 — Recovery Recipes / Escalation Policy Patterns

**New evidence:**

VS Code hooks provide three distinct escalation mechanisms with different scope:

| Mechanism | Scope | claw-code analogue |
|---|---|---|
| `permissionDecision: "ask"` in PreToolUse | Single tool call | `AlertHuman` |
| `decision: "block"` in PostToolUse | Single tool result | `LogAndContinue` with block |
| `continue: false` + `stopReason` | Entire session | `Abort` |
| `stop_hook_active` check in Stop hook | Session loop guard | Anti-infinite-loop guard |

The `stop_hook_active` flag is an official pattern for loop prevention:
> "Always check the `stop_hook_active` field to prevent the agent from running
> indefinitely."

This is the production implementation of our copilot-instructions.md "3-strike rule". The
analogy: if a Stop hook fires and `stop_hook_active: true`, the hook MUST NOT block again
(that would loop). This maps to: after N retries of a recovery recipe, escalate rather
than retry.

MCP spec defines recovery for connection-level failures:
- **Ping timeout** → "MAY consider stale, terminate, attempt reconnection"
- **Multiple failed pings** → "MAY trigger connection reset"
- **`notifications/cancelled`** → explicit in-flight cancellation

These are the `McpHandshakeFailure` and `McpStartup` recovery cases from the
RecoveryRecipes pattern.

**Assessment:** STRONGLY STRENGTHENS the recommendation. The escalation tiers exist in
official tooling with named, typed values. The gap is that our hook scripts do not yet
document which escalation tier they implement, and copilot-instructions.md does not name
the scenarios.

**Concrete implication for this repo:**
1. Annotate each `.github/hooks/*.json` script with a comment naming the escalation tier:
   `# ESCALATION: ask | block | abort | none`
2. Add a 5-scenario table to copilot-instructions.md PDCA section:

   | Scenario | Max auto-retries | Hook mechanism | Escalation |
   |---|---|---|---|
   | Trigger phrase matched wrong agent | 1 | UserPromptSubmit `systemMessage` | `ask` |
   | Test suite red | 1 (re-run once) | Stop `decision: block` | abort after 2 |
   | MCP handshake failure | 2 | PreToolUse `permissionDecision: deny` | `abort` |
   | Stale local branch | 0 | PreToolUse `additionalContext` | `ask` |
   | Destructive operation blocked by policy | 0 | PreToolUse `permissionDecision: deny` | hard block |

3. The `stop_hook_active` guard belongs in the comment block at the top of every Stop
   hook script in this repo.

---

### Area 4 — Machine-Readable Lifecycle / Lane-Event Style Status Vocabularies

**New evidence:**

VS Code provides 8 named hook event types that form an official vocabulary:

```
SessionStart → UserPromptSubmit → PreToolUse / PostToolUse (×N) → PreCompact?
→ SubagentStart / SubagentStop (×N) → Stop
```

These are **invocation points**, not sequential state transitions. There is no ordering
guarantee between PreToolUse and SubagentStart — both can interleave. The VS Code
architecture does not publish a typed state machine for agent sessions.

Hook output fields `continue: bool`, `stopReason`, `decision: "block"`,
`permissionDecision: "allow"|"deny"|"ask"` are a machine-readable typed vocabulary
subset.

MCP lifecycle provides a 3-state machine (Initialization → Operation → Shutdown) at the
protocol level — useful for MCP error handling, not for agent workflow status.

Cloud agent sessions display a "status" in the GitHub Agents tab (visible in the UI),
but this status vocabulary is not published as a machine-readable enum in official
documentation as of April 2026.

**Assessment:** WEAKENS the full-LaneEvents recommendation. The official vocabulary is:
8 hook event names + 4 permission decision values + 2 continue values. There is no
sequential state machine. The `lane.started → lane.ready → lane.green/red → ...` chain
is not implementable with available tooling without custom instrumentation.

**Scope-down implication for this repo:**
Use the 8 VS Code hook event names as the canonical vocabulary for status logging in hook
scripts. Do NOT implement a full sequential state machine. The concrete change is to
standardise the `systemMessage` prefix format in hook JSON output logs:

```json
{
  "systemMessage": "[SessionStart] Project: copilot-instructions-template v5.5.0 | branch: main"
}
```

This gives downstream tools (CI, HEARTBEAT.md parsing) a searchable vocabulary without
any custom state machine complexity.

---

### Area 5 — Deterministic Mock Harness Patterns for CLI Agents, Hooks, JSON stdin/stdout

**New evidence:**

The VS Code hooks specification publishes the exact I/O contract for hook scripts:

**Universal input fields (all 8 events):**
```json
{
  "timestamp": "2026-04-05T10:30:00.000Z",
  "cwd": "/path/to/workspace",
  "sessionId": "session-identifier",
  "hookEventName": "PreToolUse",
  "transcript_path": "/path/to/transcript.json"
}
```

**Event-specific additions (e.g. PreToolUse):**
```json
{
  "tool_name": "editFiles",
  "tool_input": { "files": ["src/main.ts"] },
  "tool_use_id": "tool-123"
}
```

**Universal output structure:**
```json
{
  "continue": true,
  "stopReason": "optional reason",
  "systemMessage": "optional warning",
  "hookSpecificOutput": { "hookEventName": "...", "permissionDecision": "deny" }
}
```

**Exit code semantics are fully specified:**
- `0`: parse stdout as JSON
- `2`: blocking error; show stderr to model
- all other codes: non-blocking warning; continue

BATS (`bats-core.readthedocs.io`) provides a bash testing framework with:
- `@test "name" { ... }` blocks
- `setup()` for per-test initialisation
- `run command` to capture exit code + stdout + stderr
- `assert_output 'expected value'` from `bats-assert` library
- No external dependencies beyond git submodules

Together these give a complete, low-ceremony path to a deterministic hook test harness:

```bash
@test "PreToolUse hook blocks dangerous commands" {
  input='{"hookEventName":"PreToolUse","tool_name":"runCommand",
          "tool_input":{"command":"drop-all-tables"}}'
  run bash .github/hooks/scripts/security-check.sh <<< "$input"
  assert_output --partial '"permissionDecision":"deny"'
}
```

No mock Anthropic server is needed. No Rust binary. No live REST call.

**Assessment:** STRONGLY STRENGTHENS the mock harness recommendation. The official spec
provides a stable, versioned I/O contract. BATS provides the bash testing harness. The
required test harness is substantially simpler than claw-code's `mock-anthropic-service`
— it does not need to simulate an LLM, only invoke hook scripts with synthetic JSON.

**Concrete implication for this repo:**
1. Add `tests/hooks/` directory with a BATS test file per hook script.
2. Add `tests/bats/` as a git submodule, or install bats via package manager in CI.
3. Test scenarios should cover: allow, deny, ask, block, abort, and systemMessage injection.
4. Add `tests/hooks/` to `targeted-test-map.json` for the hook scripts paths.
5. Add to `suite-manifest.json` as a new suite named `hooks`.

---

### Area 6 — Config Hierarchy / Config Precedence Documentation Patterns

**New evidence:**

**12-factor app III** (`12factor.net/config`) contributes three principles absent from
the current `config.instructions.md`:
1. **Credentials belong in env vars**, not config files (risk: accidental commit)
2. **No named-environment grouping** (`dev`/`staging`/`prod` groups) — use granular
   orthogonal env vars instead
3. Named groups "do not scale cleanly" — the anti-pattern justification we were missing

**VS Code hook file locations** provide an official 4-level override model:
1. User (`~/.copilot/hooks`, `~/.claude/settings.json`)
2. Claude-format workspace (`.claude/settings.json`)
3. Claude-format local (`.claude/settings.local.json`)
4. Workspace (`.github/hooks/*.json`)

Rule: "Workspace hooks take precedence over user hooks for the same event type."
`chat.hookFilesLocations` allows disabling individual paths by setting them to `false`.

**Parent-repository discovery** (`chat.useCustomizationsInParentRepositories`) adds a
monorepo dimension: a parent repo's hooks can be discovered from a subfolder workspace.
This creates an implicit 5th level (parent-level hooks before workspace hooks).

**Assessment:** STRENGTHENS the config.instructions.md improvement recommendation.
The new evidence provides concrete content to add: 12-factor III principles +
VS Code's own hook precedence model as an explicit example.

**Concrete implication for this repo:**
Add a **§ Config Resolution Order** subsection to `template/instructions/config.instructions.md`:

```
Resolution order (later overrides earlier):
1. Hard-coded defaults in script
2. User-level config (~/.copilot/hooks, ~/.claude/settings.json)
3. Repository workspace config (.github/hooks/*.json)
4. Local override (.claude/settings.local.json) — gitignored, never committed
5. Environment variables — for secrets and deploy-time values only

Rules:
- Credentials MUST come from env vars, never from committed config files.
- Do not group config into named environments (dev/staging/prod).
  Use per-value env vars instead — groups do not scale (12-factor III).
- Local overrides (layer 4) are invisible to CI and must be documented in SETUP.md.
```

---

### Area 7 — Official GitHub Copilot / VS Code Documentation Constraints

**New evidence and constraints:**

**Hard limits affecting our recommendations:**

| Constraint | Source | Implication |
|---|---|---|
| Background (CLI) agents: "can currently only access local MCP servers that don't require authentication" | `/docs/copilot/agents/copilot-cli` | MCP recovery recipes must assume local-only MCP in Copilot CLI context |
| Cloud agents: "can't directly access VS Code built-in tools and run-time context (like failed tests)" | `/docs/copilot/agents/cloud-agents` | Cloud agents cannot read test output natively; must be passed via TaskPacket or plan |
| Agent-scoped hooks: requires `chat.useCustomAgentHooks: true` | hooks docs | `.agent.md` hook definitions are opt-in; instructions must note this setting |
| `agents` property (restrict subagent access): experimental | custom-agents docs | Cannot rely on it for stable agent governance; use `disable-model-invocation` instead |
| Stop hook `stop_hook_active` check: required | hooks docs | Every Stop hook MUST check this field to prevent infinite loops |

**Features that support our recommendations:**

| Feature | Source | Supports |
|---|---|---|
| `handoffs` frontmatter with `label`, `agent`, `prompt`, `send`, `model` | custom-agents | TaskPacket structured dispatch |
| `model: ['GPT-5.2', 'Claude Opus 4.5']` array — tries in order | custom-agents | Resilience via built-in model fallback |
| `user-invocable: false` | custom-agents | Internal-only agents (subagent-only, not in picker) |
| Plan agent saves to `/memories/session/plan.md` | planning docs | Stable location for TaskPacket-style artefact |
| Stop hook `decision: "block"` with reason | hooks docs | Official Abort escalation mechanism |
| Permission levels: Default/Bypass/Autopilot | agents overview | Official 3-tier EscalationPolicy |

**VS Code permission tiers ARE the EscalationPolicy enum:**

| EscalationPolicy (claw-code) | VS Code equivalent |
|---|---|
| `AlertHuman` | Default Approvals + `permissionDecision: "ask"` |
| `LogAndContinue` | Bypass Approvals (auto-approve, no confirmation) |
| `Abort` | Stop hook `decision: "block"` + `continue: false` |
| (new) Autopilot | Auto-approves AND auto-responds; most permissive |

The VS Code model adds a 4th tier (Autopilot) between LogAndContinue and Abort.
Our escalation policy documentation should use VS Code's own tier names.

---

## Ideas from Original Plan to Downgrade or Drop

| Original recommendation | Decision | Reason |
|---|---|---|
| **Full LaneEvent state machine in heartbeat** | Scope down to named event vocabulary only | VS Code has no sequential state machine; 8 hook event names suffice |
| **WorkerBoot trust gate implementation** | Drop | VS Code permission levels cover this; custom trust gate adds complexity with no benefit |
| **Full mock-anthropic-service in Rust** | Replace with BATS | VS Code hook I/O spec is stable; BATS is lower overhead; no LLM mock needed |
| **Discord-style trigger phrases** | Keep (confirmed valid) | Copilot cloud agent's own UX validates single-sentence task dispatch |
| **`STALE_BRANCH_THRESHOLD` configurable** | Deprioritise | Not in our template's scope |
| **PolicyEngine composable conditions** | Keep as concept | Official `agents` restriction property is weaker but similar |

---

## Ranked Recommendation List for This Repo

### Now (high confidence, low risk, clear scope)

1. **Hook mock test harness (BATS)** — Add `tests/hooks/` with BATS tests for each hook
   script. Stable official I/O contract exists. Fills the known test coverage gap for
   `template/hooks/scripts/`. Estimated: 1 session, targeted test suite addition.

2. **config.instructions.md: add § Config Resolution Order** — Add 5-layer override table
   and 12-factor III credentials-in-env-vars rule. Small, high-value, no risk.
   Estimated: < 30 lines.

3. **copilot-instructions.md: rename test tiers to match VS Code language** — Replace
   prose with a 4-row named table: PathTargeted / AffectedSuite / FullSuite / MergeGate.
   Estimated: < 20 lines change.

4. **Annotate hook scripts with escalation tier** — Add `# ESCALATION: ask|block|abort|none`
   comments to each hook script. Machine-parseable. Estimated: 1 line per hook.

### Later (validated, useful, requires more design work)

5. **TaskPacket / TaskBrief structured template in Commit agent** — Add
   `acceptance_tests:`, `escalation_policy:`, `reporting_contract:` fields to the Commit
   prompt. Requires reviewing the existing Commit agent format first.

6. **RecoveryRecipes 5-scenario table in PDCA section** — Add named failure scenarios
   with prescribed steps to copilot-instructions.md. Requires alignment with existing
   anti-loop rules to avoid duplication.

7. **Stop hook `stop_hook_active` guard comment** — Document the loop-prevention guard
   in every Stop hook script in template.

8. **Named event vocabulary in hook JSON output** — Standardise `systemMessage` prefix
   format with `[HookEventName]` for searchable log entries.

### Avoid (not supported by official tooling, or cost exceeds benefit)

9. **LaneEvent full sequential state machine** — VS Code hooks are invocation points,
   not state transitions. Implementing a separate state machine adds significant overhead
   with no official tooling support.

10. **WorkerBoot trust gate** — VS Code permission levels cover this. A custom trust
    gate would shadow the official feature and confuse users.

11. **Separate mock Anthropic service** — BATS + hook I/O spec is sufficient for hook
    testing. A Rust binary mock server is out of scope for a Markdown/Shell repo.
