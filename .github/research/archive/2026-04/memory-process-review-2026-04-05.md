# Research: Memory Process Review — copilot-instructions-template

> Date: 2026-04-05 | Agent: Researcher | Status: complete

## Summary

The repo implements a five-layer memory model (MEMORY.md, SOUL.md, USER.md, HEARTBEAT.md
history, VS Code built-in `/memories/`) bridged by a `PreCompact` hook snapshot and a
`session_reflect` MCP tool triggered on significant sessions. The architecture is broadly
sound, but six concrete gaps reduce its reliability in practice. The highest-impact gap
is a structurally lossy PreCompact snapshot that may inject stale or arbitrarily truncated
context after compaction. Several gaps are quick wins; two require a consumer-visible
contract change.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://code.visualstudio.com/docs/copilot/agents/memory> | Official VS Code memory scopes, built-in memory tool vs Copilot Memory, Plan agent session memory |
| <https://github.blog/ai-and-ml/github-copilot/building-an-agentic-memory-system-for-github-copilot/> | GitHub's official memory design: citation-anchored facts, just-in-time verification, 28-day TTL |
| <https://code.visualstudio.com/docs/copilot/customization/hooks> | Hooks spec: 8 lifecycle events, PreCompact `trigger` field, Stop `stop_hook_active`, systemMessage vs additionalContext |
| <https://code.visualstudio.com/docs/copilot/agents/planning> | Plan agent saves plan to `/memories/session/plan.md`; `chat.planAgent.defaultModel` |
| <https://github.com/Yeachan-Heo/clawhip> | Clawhip MEMORY.md + memory-shard pattern: hot index + per-topic shard files |
| <https://github.com/Yeachan-Heo/oh-my-claudecode> | OMC: project-scoped skills with `source: extracted` provenance, `OMC_STATE_DIR` centralised state |
| Earlier in-repo research: `supplemental-agent-patterns-2026-04-05.md`, `sisyphus-ecosystem-synthesis-2026-04-05.md`, `github-copilot-hooks-agents-schema-2026-04-01.md` | Prior primary-source evidence for hook schema, escalation tiers, and historical gaps |

---

## Part 1 — Current Memory Model (as implemented)

### Layer inventory

| Layer | File(s) | Storage | Populated by | Consumed by |
|-------|---------|---------|--------------|-------------|
| **Project facts** | `template/workspace/knowledge/MEMORY.md` | Git-tracked, team-shared | Agent (manual append) | Heartbeat cross-ref; `save-context.sh` tail-20 |
| **Reasoning heuristics** | `template/workspace/identity/SOUL.md` | Git-tracked, team-shared | Agent across sessions | `save-context.sh` regex match; HEARTBEAT check |
| **User profile** | `template/workspace/knowledge/USER.md` | Git-tracked, team-shared | `session_reflect` MCP tool (significant sessions only) | SessionStart hook additionalContext (not currently injected) |
| **Health history** | `template/workspace/operations/HEARTBEAT.md` History table | Git-tracked | Agent follows Response Contract | `save-context.sh` `grep -m1 HEARTBEAT` |
| **Built-in user/repo/session** | `/memories/`, `/memories/repo/`, `/memories/session/` | Local, machine-only | VS Code memory tool (agent or user) | Auto-loaded (user scope first 200 lines); repo/session must be explicitly read |
| **PreCompact snapshot** | `template/hooks/scripts/save-context.sh` / `.ps1` | Ephemeral `additionalContext` | `PreCompact` hook fires, produces ≤2000 char blob | Next model turns after compaction |
| **Session state machine** | `.copilot/workspace/runtime/state.json`, `.heartbeat-events.jsonl` | Local, not git-tracked | `pulse_state.py` via `pulse.sh` hooks | `session_reflect` MCP tool; `heartbeat_clock_summary.py` |

### How memory survives compaction

`PreCompact` → `save-context.sh` fires → constructs a plain-text blob containing:
1. `grep -m1 'HEARTBEAT' HEARTBEAT.md` → first line matching "HEARTBEAT"
2. `heartbeat_clock_summary.py` → session timing metrics from state.json / .heartbeat-events.jsonl
3. `tail -20 MEMORY.md | head -c 500` → last 20 lines of MEMORY.md, truncated at 500 chars
4. `grep -A1 'heuristic|principle|rule|pattern' SOUL.md | head -c 300` → context lines around matched keywords
5. `git status --porcelain | head -10 | wc -l` → modified file count

The blob is returned as `hookSpecificOutput.additionalContext` (≤2000 chars total).

### How session retrospectives work

When `pulse.sh --trigger stop` fires at session end, `pulse_state.py` evaluates accumulated
signals (modified file count, elapsed minutes, compaction seen, explicit retro request) against
stored policy thresholds (`heartbeat-policy.json`). If the session is "significant", the Stop
hook injects a `systemMessage` instructing the model to call `session_reflect`. The MCP tool
(`mcp-heartbeat-server.py`) reads state and returns structured prompts for the model to process
silently, then persist findings to SOUL.md / MEMORY.md / USER.md.

---

## Part 2 — Weaknesses and Gaps (ordered by impact)

---

### G1 · HIGH — PreCompact snapshot is structurally lossy

**Problem:**
The `save-context.sh` blob is constructed by arbitrary line-end truncation of MEMORY.md and
keyword-grep extraction of SOUL.md. Specifically:

- `tail -20 MEMORY.md | head -c 500` takes the last 20 lines of a Markdown table, then
  hard-truncates mid-character at 500 bytes. If a table row spans lines or contains long
  content, the most recent entries are silently incomplete. There is no guarantee the last 20
  lines represent the most important entries.
- `grep -A1 'heuristic|principle|rule|pattern' SOUL.md | head -c 300` matches section headers
  (e.g. `"## Reasoning heuristics"`) rather than the actual heuristic content. The `-A1` flag
  returns only the line after the match. For SOUL.md's list-format content, this captures the
  first list item after each header, not the full list.
- The blob is flat plain text. After compaction the model has no way to tell which part came
  from MEMORY.md, which from SOUL.md, and which is the pulse line.

**Why it matters:**
Compaction is the highest-risk memory event. The few hundred characters injected here are the
only surviving context from the pre-compaction conversation. Injecting truncated or
misextracted content is worse than injecting nothing, because the model may act on fragment
facts.

**Primary source evidence:**
The GitHub Memory blog post identifies the core failure mode: "memories must include citations
to specific code locations that support each fact. When an agent encounters a stored memory, it
verifies the citations in real-time." The PreCompact blob has no citations and cannot be
verified. Official hooks docs confirm that `additionalContext` is the only channel available —
there is no way to recover more context post-compaction.

**Implementation shape:**
Restructure `save-context.sh` to emit labelled, fixed-row-count JSON fields rather than a
single concatenated string. Extract the most-recently-modified rows (by date column) from
MEMORY.md tables rather than the last 20 lines. Cap at 3 rows per table, one row per SOUL.md
value. Emit the full field names so the model can parse them after compaction.

**Risk/tradeoff:**
Medium. The 2000-char total budget constrains the fix. Structured output is more parseable but
requires the model to understand the field labels. No consumer contract change required — this
is an internal hook implementation change.

---

### Historical note — SubagentStop registration is already resolved

Earlier hook-schema research recorded a missing `SubagentStop` registration. That is no longer
an active gap on current `main`: [template/hooks/copilot-hooks.json](template/hooks/copilot-hooks.json#L83)
already registers `SubagentStop`, and the shell/PowerShell handlers exist alongside it.

Keep the earlier research note as historical context only. Do not treat `SubagentStop`
registration as a current improvement target.

---

### G3 · HIGH — MEMORY.md and `/memories/repo/` overlap with no coexistence enforcement

**Problem:**
The template's coexistence contract declares: "MEMORY.md wins for project-specific facts;
built-in user memory wins for personal preferences." But:

1. `/memories/repo/` is workspace-scoped and persistent — the same effective scope as
   MEMORY.md. An agent writing to `/memories/repo/` and also updating MEMORY.md creates
   two independent fact stores that can diverge silently.
2. No hook or heartbeat check detects or reconciles drift between the two stores.
3. The official VS Code memory tool populates `/memories/repo/` automatically — consumers
   who have the memory tool enabled will accumulate facts there even if they intend to use
   only MEMORY.md.
4. User memory (`/memories/`) is loaded into context for the first 200 lines automatically.
   MEMORY.md is never auto-loaded — it must be read explicitly or surfaced via save-context.
   This gives the built-in system a structural context-window advantage over MEMORY.md.

**Why it matters:**
A consumer following this template in good faith may have facts in three places: MEMORY.md
(manual, git-tracked), `/memories/repo/` (auto-populated by VS Code), and the user scope
`/memories/` (personal, 200 lines auto-loaded). Without a stated reconciliation protocol,
the model cherry-picks from whichever it encounters first. MEMORY.md, being git-tracked,
has the most value for teams — but it has the worst discovery guarantees.

**Primary source evidence:**
VS Code memory docs (2026-04-01) describe the memory tool and Copilot Memory as complementary
but provide no coexistence protocol with file-based memory stores. The docs explicitly state
that user memory first 200 lines are auto-loaded; repo and session memory must be requested.
The GitHub memory blog confirms that only GitHub-hosted Copilot Memory has verification
against citations — local file memory has no validation layer.

**Implementation shape:**
Add a heartbeat check: "Are there facts in `/memories/repo/` that are not yet in MEMORY.md?
If so, propose moving them." Add a note to the coexistence table in MEMORY.md clarifying that
`/memories/repo/` is auto-populated and is the faster-growing store. Document that MEMORY.md
is the canonical team-shared source; `/memories/repo/` should be treated as an inbox requiring
periodic promotion or discard.

**Risk/tradeoff:**
Low (documentation and heartbeat check only). The check itself is research-grade — the agent
cannot definitively tell which store is authoritative. Consumer contract change: soft — a new
heartbeat check, additive.

---

### G4 · MEDIUM-HIGH — USER.md has no reliable activation path for most sessions

**Problem:**
USER.md is populated only as output of `session_reflect`, which only fires for "significant"
sessions (one strong signal: ≥8 modified files or ≥30 minutes; or two supporting signals).
For typical sessions — a twenty-minute coding task, a question-answer session — `session_reflect`
never runs and USER.md never updates.

Additionally, USER.md content is never injected into context by any hook. `session-start.sh`
injects project name, branch, OS, and runtime versions — but not USER.md content. The model
only encounters USER.md if it explicitly reads the workspace directory or if session_reflect
fires and prompts it to read/update the file.

The fields listed (communication style, domain expertise, working pace) are not
project-scoped — they are global preferences already tracked more reliably by the built-in
`/memories/` user scope (which IS auto-loaded). This makes USER.md a project-scoped
duplication of global preferences that the model already has, but without the auto-loading
advantage.

**Why it matters:**
USER.md was designed to personalise agent behaviour within a specific project. If it is never
populated and never injected, it provides no behavioural differentiation from the template
defaults.

**Primary source evidence:**
VS Code planning docs note the Plan agent saves plans to `/memories/session/plan.md` — a
known stable path. The same approach could be applied to USER.md: the SessionStart hook could
read USER.md and inject its content (bounded at 300 chars) as `additionalContext`, ensuring it
reaches the model in every session regardless of size.

**Implementation shape (consumer contract change):**
Add USER.md content injection to `session-start.sh`. Gate the injection on whether at least
one field is populated (i.e., not all `*(to be discovered)*`). Cap at 300 chars. This would
make USER.md actually useful without requiring significant sessions.

**Risk/tradeoff:**
Low-medium. Adds ~300 chars to each session's injected context. Consumer contract change:
YES — changes what the SessionStart hook injects.

---

### G5 · MEDIUM — SOUL.md entries have no timestamps or provenance, no staleness protocol

**Problem:**
SOUL.md entries are free-form values statements and heuristics with no creation date, no
source attribution, and no removal criteria. A heuristic added in January that was later
superseded by a better pattern coexists silently with the newer one. There is no audit
mechanism.

The `save-context.sh` extracts SOUL.md content via `grep -A1 'heuristic|principle|rule|pattern'
SOUL.md | head -c 300` — matching section headings, not values. The current SOUL.md template
has a `## Reasoning heuristics` section. The grep matches the heading and returns the first
item beneath it, not the full list.

**Why it matters:**
SOUL.md is positioned as the "reasoning DNA" of the agent for this project. Unverifiable,
undated heuristics accumulate over time and either bloat the file or silently conflict with
each other. The Sisyphus ecosystem (clawhip, OMC) uses `source: extracted` provenance and
keyword triggers to scope heuristics — this repo has neither.

**Primary source evidence:**
OMC's `auto-learner` feature extracts reusable patterns from sessions with `source: extracted`
provenance, allowing later validation that the pattern was actually observed rather than ad hoc
invented. MEMORY.md's own maintenance protocol says "rules must be falsifiable — remove any
entry that no longer improves agent output" — but SOUL.md has no equivalent requirement and no
enforcement mechanism.

**Implementation shape:**
Add a simple schema to SOUL.md: each entry in a values or heuristics section should have a
date suffix comment (e.g., `— added 2026-04-05`) and a provenance note (`observed` / `explicit`).
Add a heartbeat check: "Has any SOUL.md entry not been reviewed in the last 90 days?" This
is soft and does not require breaking existing content.

**Risk/tradeoff:**
Low. Additive schema requirement. No consumer contract change.

---

### G6 · MEDIUM — MEMORY.md maintenance rules are aspirational; no enforcement exists

**Problem:**
MEMORY.md specifies:
> "Review and prune this file quarterly (or when it exceeds 100 rows total)."
> "Remove entries that are now captured in the instructions file."
> "Rules in this file must be falsifiable."

None of these rules are enforced by any check:
- No heartbeat check measures MEMORY.md row count.
- `copilot_audit.py` does not include a MEMORY.md health check.
- No CI script validates table structure or row count.
- There is no deduplication audit between MEMORY.md entries and the consumer instructions file.

**Why it matters:**
In practice, MEMORY.md will grow monotonically unless there is an automated reminder or
gate. Once it exceeds 100 rows it crosses into "attention degradation" territory — the rule
noted in the template's copilot-instructions.md about LLMs losing focus on middle-of-context
content applies to MEMORY.md itself when it is read without filtering.

**Primary source evidence:**
The `copilot_audit.py` suite already validates agent frontmatter, hook schemas, skill files,
and version references. Extending it to check MEMORY.md row count is consistent with the
existing audit philosophy. There is no official VS Code guidance specifically on file-based
memory limits, but the built-in memory tool's auto-load of 200 lines from user memory
implicitly sets a practical attention budget upper bound.

**Implementation shape:**
Add a `checks_memory.py` module to `scripts/copilot_audit/` that reports a warning when any
MEMORY.md table exceeds 20 rows or the file exceeds 100 non-blank lines. Add a HEARTBEAT.md
check item: "Is MEMORY.md below 100 total rows?" This can be a standard checks-file entry,
no consumer contract change.

**Risk/tradeoff:**
Low. Purely additive audit check. A copilot_audit change would require the supplemental CI
manifest to be updated. Consumer heartbeat check is additive.

---

### G7 · LOWER — PreCompact hook ignores the `trigger` field and has no task-state awareness

**Problem:**
The official `PreCompact` input payload includes `{ "trigger": "auto" }`. `save-context.sh`
reads stdin but discards it entirely. Two consequences:

1. The snapshot cannot adapt to the compaction reason. Auto-compaction (context too long)
   and manual compaction (`/compact` in Copilot CLI) have different optimal responses.
2. The snapshot does not include any current-task context — what the agent was doing when
   compaction happened. `session-start.sh` already injects branch, commit, OS, project
   version. After compaction, the model re-receives this through its own reinjection — but
   has no information about the _task in progress_.

**Why it matters:**
The most critical recovery information after compaction is "what was I doing?" The current
snapshot captures global project state but not local task state. A model resuming after
compaction knows the project name and git branch but not the half-completed refactor it was
executing.

**Primary source evidence:**
The Plan agent (VS Code 2026-04-01 docs) writes its plan to `/memories/session/plan.md`. This
is a stable location the model or a hook can read to recover task state. The PreCompact hook
could read `/memories/session/plan.md` if it exists and include the first 200 chars of the
current plan in `additionalContext`. This is a low-cost, high-value addition.

**Implementation shape:**
In `save-context.sh`:
1. Parse the `trigger` field from stdin and label the snapshot: `"PreCompact (trigger: auto)"`.
2. If `/memories/session/plan.md` or `.copilot/workspace/runtime/state.json`'s `intent_phase` field
   indicates active work, include a 150-char snippet.
No consumer contract change required.

**Risk/tradeoff:**
Low. Internal hook change only.

---

## Part 3 — Improvement Plan

### Quick Wins (no consumer contract change, low risk)

| # | Change | Primary file(s) | Impact |
|---|--------|----------------|--------|
| QW1 | Parse and label `trigger` field in `save-context.sh` | `template/hooks/scripts/save-context.sh`, `.ps1` | Makes PostCompact context self-labelled |
| QW2 | Replace `tail -20 | head -c 500` with date-sorted top-N row extraction | `template/hooks/scripts/save-context.sh`, `.ps1` | Prevents mid-row truncation and prioritises recent facts |
| QW3 | Fix SOUL.md extraction from `grep -A1` (captures headers) to read actual list values | `template/hooks/scripts/save-context.sh`, `.ps1` | Ensures SOUL.md heuristics actually reach the model post-compaction |
| QW4 | Add MEMORY.md row-count check to `HEARTBEAT.md` template | `template/workspace/operations/HEARTBEAT.md` | Enforces the 100-row maintenance rule |
| QW5 | Read `/memories/session/plan.md` in `save-context.sh` if it exists | `template/hooks/scripts/save-context.sh`, `.ps1` | Restores task-in-progress context post-compaction |

### Structural Changes (may require consumer-visible contract updates)

| # | Change | Primary file(s) | Consumer impact |
|---|--------|----------------|----------------|
| SC1 | Inject USER.md content (bounded 300 chars) in `session-start.sh` when fields are populated | `template/hooks/scripts/session-start.sh`, `.ps1` | YES — changes what is injected at session start |
| SC2 | Add MEMORY.md coexistence protocol: heartbeat check for `/memories/repo/` inbox | `template/workspace/operations/HEARTBEAT.md`, `template/workspace/knowledge/MEMORY.md` | SOFT — adds a new heartbeat check, additive |
| SC3 | Add `Source` column to all MEMORY.md table templates; document citation format | `template/workspace/knowledge/MEMORY.md` | YES — changes MEMORY.md table schema; existing consumer rows need migration note |
| SC4 | Add `SOUL.md` entry provenance suffix requirement (`— added YYYY-MM-DD`) and heartbeat staleness check | `template/workspace/identity/SOUL.md`, `template/workspace/operations/HEARTBEAT.md` | SOFT — additive schema requirement |
| SC5 | Add `checks_memory.py` to `copilot_audit` suite (row count, blank line count, table structure) | `scripts/copilot_audit/checks_memory.py` | NO — audit-only, consumer templates are not executed by audit |

---

## Part 4 — Consumer Contract Changes Summary

| Change | Contract change description | Migration note needed? |
|--------|----------------------------|----------------------|
| SC1 (USER.md injection) | SessionStart additionalContext will include USER.md content for populated profiles | No — additive injection; consumers who have not populated USER.md see no change |
| SC3 (MEMORY.md Source column) | MEMORY.md table schema gains a `Source` column | Yes — MIGRATION.md entry needed; existing consumer rows without Source remain valid but lose verification benefit |

---

## Part 5 — Gaps Not to Fix

The following ideas from the Sisyphus ecosystem research were considered but should NOT be
implemented in this repo:

- **Full sequential state machine (LaneEvents)**: VS Code provides 8 hook event names as
  invocation points, not a typed state machine. No official equivalent exists. Over-engineering
  risk. (Documented in `supplemental-agent-patterns-2026-04-05.md` §Area 4.)
- **Memory sharding** (`.copilot/workspace/memory/` subdirectory): Adds directory complexity
  for a benefit only realised at >20 MEMORY.md table rows. Revisit when any consumer
  MEMORY.md approaches 100 rows.
- **Copilot Memory (GitHub-hosted)**: Opt-in feature, 28-day TTL, requires enterprise policy
  change. Outside scope of this template.
- **Citation verification via real-time code reads**: The GitHub Memory blog describes this
  for GitHub-hosted memories. Implementing it for MEMORY.md would require the model to read
  every cited file on each heartbeat — prohibitive context cost for a local template.

---

## Appendix — File Map

| Repo path | Role in memory model |
|-----------|---------------------|
| `template/workspace/knowledge/MEMORY.md` | Hot index, team-shared project facts |
| `template/workspace/identity/SOUL.md` | Reasoning heuristics and values |
| `template/workspace/knowledge/USER.md` | Project-scoped user profile |
| `template/workspace/operations/HEARTBEAT.md` | Health check + session history append-log |
| `template/hooks/scripts/save-context.sh` | PreCompact snapshot constructor |
| `template/hooks/scripts/save-context.ps1` | PreCompact snapshot constructor (Windows) |
| `template/hooks/scripts/mcp-heartbeat-server.py` | `session_reflect` MCP tool implementation |
| `template/hooks/scripts/pulse_state.py` | Session signal tracker (significance decision) |
| `template/hooks/scripts/heartbeat_clock_summary.py` | Session timing metrics for PreCompact |
| `template/hooks/copilot-hooks.json` | Hook registrations (missing SubagentStop) |
| `tests/hooks/test-hook-save-context.sh` | Save-context unit tests (8 tests) |
