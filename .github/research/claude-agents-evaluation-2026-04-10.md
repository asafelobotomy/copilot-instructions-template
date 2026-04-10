# Research: Claude-Format Agents — Evaluation for copilot-instructions-template

> Date: 2026-04-10 | Agent: Researcher | Status: complete

## Summary

Claude Code sub-agents (`.claude/agents/*.md`) and VS Code Copilot custom agents
(`.github/agents/*.agent.md`) are two distinct, non-interoperable systems with
overlapping intent but divergent formats and invocation models. The installed VS Code
Copilot extension now advertises direct Claude compatibility for `.claude/agents/`,
but it still handles `.claude/agents/*.md` and `.github/agents/*.agent.md` through
different discovery and parsing paths. That means the existing `.github/agents` roster
cannot be treated as a drop-in substitute for Claude-format agents. This repository made
an explicit, documented deferral decision on dual-format stubs at v3.2.0. That decision
remains valid: the format gap produces only degraded stubs, the maintenance burden is
significant, the `.claude/agents` path is currently a sandbox placeholder device in this
repo, and the previously documented `.github/agents` workaround is not strong enough to
recommend. **Recommendation: continue to defer.** Defer conditions are documented below.


## Sources

| URL | Relevance |
|-----|-----------|
| https://docs.anthropic.com/en/docs/claude-code/sub-agents | Claude Code sub-agents canonical docs (not reachable in sandbox; partially inferred from local OMC research and VS Code docs) |
| https://code.visualstudio.com/docs/copilot/customization/custom-agents | VS Code custom agent frontmatter schema |
| https://code.visualstudio.com/updates/v1_113 | v1.113: MCP in Copilot CLI and Claude agent sessions; nested subagents |
| https://code.visualstudio.com/updates/v1_114 | v1.114: Group policy to disable Claude agent `Claude3PIntegration = false` |
| `.github/research/copilot-audit-tool-design-2026-03-29.md` | Complete VS Code discovery path inventory as of March 2026 |
| `.github/research/sisyphus-ecosystem-synthesis-2026-04-05.md` | OMC (oh-my-claudecode) analysis: configuration precedence, `.claude/CLAUDE.md` pattern, project-scoped skills |
| `CHANGELOG.md` v3.2.0 | Explicit deferral decision recorded: "current decision to defer dual-format stubs, and workaround for cross-tool teams" |
| User memory note (debugging.md) | `.claude/agents` appears as `/dev/null` character-device placeholder in the VS Code Copilot sandbox |


## Findings

### 1. What Claude-format agents are and how they are stored/invoked today

Claude Code sub-agents are Markdown files stored under `.claude/agents/` (project scope)
or `~/.claude/agents/` (user scope). Configuration precedence favours project over user.

**Format** (Claude Code):

```yaml
---
name: <agent-name>
description: <what this agent does>
tools: [Read, Write, Bash, ...]   # allow-list; omit = inherits parent
model: claude-opus-4-5            # optional; inherits parent if absent
---
<system prompt in Markdown>
```

**Invocation model**: Claude Code's `Task` tool spins up an isolated sub-agent with its
own context, bounded tool set, and (optionally) its own model. The parent agent delegates
a task via `Task(agent="name", prompt="...")` and the sub-agent runs independently.
Results are returned to the parent when the sub-agent calls its own `task_complete` tool.

**VS Code context**: The installed Copilot extension changelog now states that VS Code
reads Claude configuration files directly, including `.claude/agents`, `.claude/skills`,
and `.claude/settings.json`. As of v1.113, MCP servers from `.vscode/mcp.json` are also
available inside Claude agent sessions. However, the extension bundle still treats Claude
agents and Copilot custom agents as different systems. The Copilot custom-agent discovery
map continues to include:
- `.github/agents/**/*.agent.md` — project-scoped Copilot agents
- `~/.copilot/agents/**/*.agent.md` — user-profile Copilot agents

The same installed extension separately offers `.claude/agents/` as the Claude-specific
project location. Directory configurability does not imply parser compatibility between
the two formats.

**Physical state of `.claude/agents` in this repo**: The path currently exists as a
character-device placeholder (`crw-rw-rw- 1 nobody nobody 1, 3`) created by the VS Code
sandbox runtime, not a real directory. It is structurally equivalent to `/dev/null`. Any
real sub-agent files would require removing or replacing this device node first.


### 2. Whether project-level `.claude/agents/` support appears stable and worth targeting

**Stability**: The feature is live and used by the Claude Code ecosystem. The OMC
(oh-my-claudecode) project ships 29 agents in this format; it is at v4.4.0+. The format
is simple enough to version-control without a heavyweight schema.

**Cross-consumer reach**: Among this template's consumer base, the `.claude/agents/`
path is only relevant to teams who run Claude Code CLI. Consumers who exclusively use VS
Code Copilot get zero benefit.

**Enterprise risk**: VS Code v1.114 introduced a group policy `Claude3PIntegration = false`
to disable the Claude extension entirely. Consumers in managed enterprise environments may
have this policy active, rendering all `.claude/agents/` files inert regardless of quality.

**Verdict**: The format itself is stable for Claude Code CLI users. Whether it is worth
targeting for *this template* depends on whether the template intends to serve Claude Code
CLI as a first-class consumer surface — which it does not currently do (single consumer
entry point is VS Code Copilot).


### 3. Practical benefits this repo would gain from adding real Claude-format agents

a. **Cross-tool reach**: Teams that run Claude Code CLI alongside VS Code Copilot could
   invoke the same specialist agent personalities (Researcher, Audit, Review, etc.) from
   within Claude Code sessions without manually rewriting the system prompts.

b. **Coherent agent identity**: The 13 agents defined in `.github/agents/` embody
   considerable design work (governance rules, tool allow-lists, delegation boundaries).
   A Claude-format mirror would carry that persona into a second runtime without requiring
   the consumer to rebuild it from scratch.

c. **`CLAUDE.md` extends to agents**: The template already ships `CLAUDE.md` for basic
   cross-tool compatibility. Adding `.claude/agents/` files would make the cross-tool story
   complete at the specialist-agent level, not just the global instruction level.

d. **Signal to consumers**: Publishing Claude-format agents alongside Copilot agents sends
   a clear message that the template is tool-agnostic, which may increase adoption by
   teams not committed to VS Code Copilot.


### 4. Practical costs and risks

#### 4a. Format incompatibility produces degraded stubs

The VS Code `.agent.md` format has features Claude Code sub-agents lack:

| Feature | VS Code `.agent.md` | Claude Code `.claude/agents/*.md` |
|---------|--------------------|---------------------------------|
| `handoffs:` (workflow steps) | ✓ | ✗ |
| `mcp-servers:` | ✓ | ✗ (MCP available via parent) |
| `agents:` allow-list | ✓ | ✗ |
| Agent-scoped `hooks:` | ✓ (Preview) | ✗ |
| Multi-model `model:` array | ✓ | Single model or inherit |
| `argument-hint:` | ✓ | ✗ |
| `user-invocable:` | ✓ | N/A (Tool-invoked) |

A Claude-format stub of (for example) the `Commit` agent would lose its `handoffs:` to
Review and Audit, its `mcp-servers:` list, and its governance allow-list. The stub would
be a weaker, unchecked version of the Copilot agent under the same name — a potential
source of inconsistency and user confusion.

#### 4b. Maintenance burden is significant

- **File count**: 13 agents × 2 formats = 26 agent files. The template currently enforces
  `.github/*` / `template/*` parity via CI. Adding `.claude/agents/` would require a third
  parity tier or a deliberate exception.
- **Schema divergence**: The two formats will continue to evolve on independent schedules
  (Anthropic and GitHub/Microsoft). Dual maintenance means tracking two changelog streams
  and applying compatible changes twice.
- **Validation gap**: The existing CI validates `.agent.md` frontmatter via
  `scripts/ci/validate-agent-frontmatter.sh`. There is no equivalent Claude sub-agent
  validator; one would need to be written and maintained.

#### 4c. Sandbox placeholder collision

The `.claude/agents` path in this repo is currently a character-device file (confirmed by
`ls -la`). Creating real sub-agent files would require replacing the device node, which
may reappear after sandbox restarts. The user memory documents this pattern: these
placeholders "will reappear after deletion." Working around this requires `.git/info/exclude`
entries and careful handling during setup and CI — additional complexity.

#### 4d. No invocation benefit for Copilot users

Because VS Code Copilot does not read `.claude/agents/`, all 13 files would be invisible
to the template's primary consumer surface. The benefit is exclusively for Claude Code CLI
users, a currently unsupported consumer category.

#### 4e. Documentation and consumer onboarding cost

Consumers who see both `.github/agents/*.agent.md` and `.claude/agents/*.md` need to
understand which file is active in which context. This requires clear documentation that
does not currently exist in `SETUP.md` or `README.md`. Absent that documentation, the dual
presence creates confusion rather than clarity.


### 5. Existing repo decision and cross-tool workaround

CHANGELOG v3.2.0 records the decision explicitly (line 520):

> Claude agent format compatibility section added to `docs/AGENTS-GUIDE.md` — documents
> format differences (`.agent.md` vs `.claude/agents/*.md`), **current decision to defer
> dual-format stubs**, and workaround for cross-tool teams.

The earlier workaround for cross-tool teams (from the now-retired `docs/AGENTS-GUIDE.md`)
was: configure `chat.agentFilesLocations` in `.vscode/settings.json` to point Claude Code
sessions at the `.github/agents/` directory directly, rather than maintaining a separate
`.claude/agents/` mirror.

That workaround should now be treated as **unverified and too strong for official
documentation**. The installed Copilot extension advertises both `chat.agentFilesLocations`
and direct `.claude/agents` compatibility, but the bundled code inspects `.github/agents`
and `.claude/agents` through separate discovery paths. This is strong evidence that
`chat.agentFilesLocations` adds more directories for Copilot-style custom agents, not that
it translates `.agent.md` files into Claude-format subagents. Until an end-to-end test
proves otherwise, this repo should not recommend the setting as a supported bridge.


## Recommendation

**Defer — the v3.2.0 deferral decision remains valid.**

The evidence for deferral is stronger now than when it was first made:

1. The installed extension now claims direct `.claude/agents` support, but `.claude/agents`
  and `.github/agents` still follow separate code paths. Format isolation remains real.
2. The feature gap between the two formats has widened (VS Code added `handoffs:`,
   agent-scoped hooks, and MCP server integration in agent frontmatter since v3.2.0).
3. The `.claude/agents` sandbox placeholder issue adds a concrete implementation obstacle.
4. The enterprise group policy risk (`Claude3PIntegration = false`) caps the cross-tool
   audience further.
5. No current consumer onboarding path targets Claude Code CLI as a first-class surface.

**Conditions to revisit this decision:**

- VS Code officially adds `.claude/agents/` to its Copilot agent discovery paths — at that
  point the files would serve both runtimes simultaneously.
- A future template version explicitly targets Claude Code CLI as a co-equal consumer. This
  would require a new `SETUP.md` section, consumer entry points, and a validation tier.
- Anthropic adds `handoffs:` or equivalent workflow composition to Claude Code sub-agents,
  narrowing the feature gap enough to produce non-degraded stubs.

**If a consumer asks for cross-tool agent support today**, do not recommend a directory
alias as an official solution. Instead, explain the tradeoff directly: either maintain real
`.claude/agents` files intentionally, or run an experimental local prototype before relying
on `.github/agents` as a bridge.


## Gaps / Further research needed

- The Anthropic docs site was unreachable from the sandbox during this research. The Claude
  Code sub-agent frontmatter schema above is inferred from OMC research and VS Code integration
  notes; it should be verified against `https://docs.anthropic.com/en/docs/claude-code/sub-agents`
  when network access is available.
- VS Code v1.113 notes "MCP servers available in Copilot CLI and Claude agent sessions" — the exact
  mechanism (whether `.vscode/mcp.json` is auto-read by the Claude extension) warrants a dedicated
  fetch to confirm whether this creates any new interoperability surface.
