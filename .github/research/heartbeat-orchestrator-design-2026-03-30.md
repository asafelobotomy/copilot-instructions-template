# Research: Heartbeat Orchestrator Design for VS Code Copilot Hook Architecture

> Date: 2026-03-30 | Agent: Researcher | Status: final

---

## Summary

The current heartbeat mechanism in this repository (`HEARTBEAT.md` + `.heartbeat-session` sentinel + `enforce-retrospective.sh` in the `Stop` hook) provides a functional baseline.  However, it conflates three distinct concerns — health checking, retrospective gating, and context injection — and distributes logic across hooks without a defined trigger matrix or suppression policy.  This report synthesises official VS Code Copilot hook semantics (current as of March 2026), event-driven checkpointing patterns from systems engineering, and a direct analysis of the existing implementation.  The main recommendation is **Option B**: a dedicated `pulse.sh` script invoked from specific lifecycle points, with a strict trigger matrix, file-write suppression rules, and a lightweight sidecar JSON state store.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://code.visualstudio.com/docs/copilot/customization/hooks | Primary: complete hook semantics, I/O contracts, timeout defaults, exit-code table |
| https://code.visualstudio.com/docs/copilot/concepts/customization | Hook vs instruction vs skill positioning |

---

## Section 1 — Official Hook Semantics (Documented Facts Only)

The following facts are sourced directly from the VS Code Copilot hooks documentation (last accessed 2026-03-30).

### 1.1  Supported hook events (VS Code, March 2026)

| Event | When | Can block? | Key input fields | Key output fields |
|-------|------|-----------|-----------------|------------------|
| `SessionStart` | First prompt of new session | No (context injection only) | `source`, `sessionId`, `timestamp` | `additionalContext` |
| `UserPromptSubmit` | Each user prompt | No (common output only) | `prompt`, `sessionId` | `continue`, `stopReason`, `systemMessage` |
| `PreToolUse` | Before any tool call | Yes (`permissionDecision: "deny"`) | `tool_name`, `tool_input`, `tool_use_id` | `permissionDecision`, `additionalContext`, `updatedInput` |
| `PostToolUse` | After tool completes | Yes (`decision: "block"`) | `tool_name`, `tool_input`, `tool_response` | `decision`, `reason`, `additionalContext` |
| `PreCompact` | Before context compaction | No (common output only) | `trigger` (`"auto"`) | `continue`, `stopReason`, `additionalContext` |
| `SubagentStart` | Subagent spawned | No | `agent_id`, `agent_type` | `additionalContext` |
| `SubagentStop` | Subagent completes | Yes (`decision: "block"`) | `agent_id`, `agent_type`, `stop_hook_active` | `decision`, `reason` |
| `Stop` | Agent session ends | Yes (`decision: "block"`) | `stop_hook_active` | `decision`, `reason` |

> **Important gap (2026-03-30)**: `UserPromptSubmit` is documented in the VS Code hooks reference but is **not** currently implemented in this repository's `copilot-hooks.json` or template.

### 1.2  Timeout and latency constraints

- **Default timeout**: 30 seconds per hook command.
- **Overridable per command** via the `"timeout"` property (integer, seconds).
- **Current repo values**: `SessionStart` = 10 s, `PreToolUse` = 5 s, `PostToolUse` = 30 s, `Stop` = 30 s/5 s, `PreCompact` = 10 s, `SubagentStart` = 5 s, `SubagentStop` = 5 s.
- **Implication for heartbeat writes**: Any file-write in a hook counts against its timeout.  On slow filesystems (network drives, containers), `python3` invocations to write JSON can take 200–500 ms.  Staying under 1 s total read/write per hook invocation is a safe target.

### 1.3  File-write safety by hook

| Event | Safe to write files? | Reasoning |
|-------|---------------------|-----------|
| `SessionStart` | **Yes** | Guaranteed once per session; nothing blocked by the write |
| `UserPromptSubmit` | **Yes** | Safe; fires before any tool use |
| `PreToolUse` | **Conditional** | Write only if you do not block; concurrent writes from rapid tool calls risk races |
| `PostToolUse` | **Yes** | Tool already completed; write is post-fact |
| `PreCompact` | **Yes** | Write state to survive compaction |
| `SubagentStart` | **Yes (with guard)** | High-frequency in deep recursion; must check depth |
| `SubagentStop` | **Yes (with guard)** | Same as SubagentStart |
| `Stop` | **Yes** | Always safe; session is ending |

### 1.4  Stop hook re-entry semantics

When a `Stop` hook returns `decision: "block"`, the agent continues running and **all subsequent turns consume premium requests**.  The `stop_hook_active` boolean prevents infinite loops — hooks must respect it.  The current `enforce-retrospective.sh` already handles this correctly.

### 1.5  PreCompact output field discrepancy

The documentation specifies that `PreCompact` uses the **common output format only** (`continue`, `stopReason`, `systemMessage`).  However, the current `save-context.sh` script emits `hookSpecificOutput.additionalContext`.  Testing confirms the field is accepted by the runtime; it is simply not listed in the PreCompact-specific output table.  **Treat as implementation detail, not a guaranteed contract.**

---

## Section 2 — Architecture Patterns (Inferred + Industry Best Practices)

### 2.1  Trigger classification

In event-driven systems, health-check triggers fall into two categories:

**Hard triggers** — fire unconditionally, regardless of prior state or elapsed time:

- Session start (always initialise / read state)
- Explicit user request ("Check your heartbeat")
- Session end (always run retrospective gate)
- Pre-compaction (always snapshot relevant state)

**Soft triggers** — fire only when a qualifying condition is true:

- Large change (>N files modified in a single task)
- Refactor/migration flags
- Dependency manifest change
- CI resolution
- Task completion (only if work was done this session)

**Anti-pattern to avoid**: Firing a soft trigger on every `PostToolUse` without debouncing.  This causes _update spam_: N tool calls in a refactor trigger N heartbeat reads/writes, producing identical states.

### 2.2  Debounce / coalescing window pattern

In systems with high-frequency event sources (e.g. `PostToolUse` firing on every file edit), a **debounce file** suppresses redundant writes:

1. After writing the heartbeat, write a timestamp to a sidecar file (`state.json`).
2. On next trigger, compare `now - last_write` against a minimum interval (suggested: 300 s / 5 min for soft triggers).
3. If within interval, skip the write; emit read-only context injection if needed.

For VS Code agent hooks, the recommended window is **per-session**: soft heartbeat writes at most once per session unless a hard trigger fires.

### 2.3  Sidecar event log vs direct markdown rewrite

| Approach | Pros | Cons |
|----------|------|------|
| **Sidecar JSON** (`state.json`) | Machine-parseable; atomic w/ temp-rename; no Markdown parse errors | Extra file; requires sync with `HEARTBEAT.md` |
| **Direct markdown rewrite** | Human-readable; single source of truth | Non-atomic; diff noise; parse fragility |
| **Append-only log** | Zero risk of corruption; auditable | Grows unbounded; requires periodic trim |

**Recommended hybrid**: Sidecar JSON for machine state (session sentinel, last-write timestamp, pulse code); `HEARTBEAT.md` updated only on hard triggers.

### 2.4  State machine design

A minimal heartbeat state machine has four states:

```
                  ┌──────────────────────────────────────────┐
                  │                                          │
 SessionStart     ▼       Work done        Stop/retro       │
─────────────► [PENDING] ──────────────► [RUNNING] ──────► [COMPLETE]
                  │                                          │
                  │           Error / alert                  │
                  └──────────────────────────────────────────┘
                                  ▼
                              [STALE]  ← last_write > threshold without complete
```

- `PENDING` = session sentinel written, no heartbeat check yet
- `RUNNING` = current session is actively executing
- `COMPLETE` = retrospective run and sentinel marked complete
- `STALE` = previous session ended without `COMPLETE` (no sentinel file, or file older than threshold)

---

## Section 3 — Mechanism Comparison

### Option A — No separate pulse hook (status quo, distributed logic)

Logic spread across `session-start.sh` (initialise sentinel), `enforce-retrospective.sh` (gate Stop), and `save-context.sh` (snapshot PreCompact).  The agent reads `HEARTBEAT.md` via instructions.

| Dimension | Assessment |
|-----------|-----------|
| Complexity | **Low** — no new files; current state |
| Robustness | **Medium** — three separate scripts must stay in sync; logic scattered |
| Token cost | **Low** — only SessionStart injects heartbeat state |
| False positives | **Medium** — `enforce-retrospective.sh` fallback (mtime-based) can misfire |
| False negatives | **High** — no structured check that a heartbeat _read_ actually happened before Stop |
| Testability | **Medium** — each script tested individually, no integration test |

**Verdict**: Viable for minimal setups.  Does not scale as trigger complexity grows.

### Option B — Separate `pulse.sh` script invoked from lifecycle hooks

A dedicated `pulse.sh` encapsulates all heartbeat read/write logic.  Lifecycle hooks call it with positional arguments: `pulse.sh --trigger SESSION_START`, `pulse.sh --trigger STOP`, etc.  It maintains a `state.json` sidecar and rewrites `HEARTBEAT.md` only on hard triggers.

| Dimension | Assessment |
|-----------|-----------|
| Complexity | **Medium** — one new script plus state JSON schema |
| Robustness | **High** — single entry point; state transitions are explicit |
| Token cost | **Low** — same injection points as Option A |
| False positives | **Low** — suppression rules in one place |
| False negatives | **Low** — state machine tracks whether a read occurred pre-Stop |
| Testability | **High** — `pulse.sh` can be tested with synthetic inputs and state fixtures |

**Verdict**: Recommended.  Low overhead relative to robustness gain.

### Option C — Plugin/tool-based orchestrator

An MCP tool or agent plugin acting as a heartbeat manager, callable from instruction context.

| Dimension | Assessment |
|-----------|-----------|
| Complexity | **High** — requires MCP server, separate process, TypeScript/Python runtime |
| Robustness | **Medium** — MCP transport failures can silently drop heartbeat |
| Token cost | **High** — every tool call requires an LLM decision step |
| False positives | **Low** — well-designed tool can deduplicate |
| False negatives | **Medium** — depends on agent calling the tool |
| Testability | **High** — MCP inspector + unit tests |

**Verdict**: Over-engineered for this use case.  Reserve for when heartbeat logic needs external integrations (e.g. posting to a dashboard, alerting on Slack).

---

## Section 4 — Claude Code / OpenClaw Heartbeat Concepts

> **Source**: Analysis of Claude Code hook configuration format compatibility noted in VS Code documentation (2026-03-25).  "OpenClaw" is not a named public product; this section analyses the general pattern used by Claude Code-style hook configurations and what VS Code documents about their compatibility.

### 4.1  Claude Code hook architecture — portable patterns

The VS Code Copilot documentation explicitly states compatibility with Claude Code's `.claude/settings.json` hook format.  Key Claude Code patterns relevant to heartbeat design:

- **Matcher syntax**: Claude Code hooks support tool-name matchers (e.g. `"Edit|Write"`).  VS Code currently **ignores** matchers — all hooks run on every event.  **Do not rely on matchers for suppression; use script-level guards instead.**
- **JSON stdin/stdout protocol**: Identical to VS Code.  Scripts from Claude Code environments port directly with tool-name normalisation (snake_case → camelCase).
- **`stop_hook_active` loop prevention**: Claude Code uses the same boolean.  This pattern is directly portable.
- **Context injection via `additionalContext`**: Both runtimes honour this field from applicable hooks.

### 4.2  Concepts that cannot be safely ported

- **Bash-only hooks with match expressions**: Claude Code evaluates matchers server-side; VS Code ignores them client-side.  A hook designed to fire only on `Edit` tool will fire on every tool in VS Code.  Porting such hooks without script-level guards causes performance degradation.
- **Background daemon processes from hooks**: Claude Code may allow long-running hook daemons in some configurations.  VS Code enforces per-hook timeouts (default 30 s).  Daemon-style processes must be replaced with fast, stateless scripts.
- **Tool-name references**: Claude Code uses `Write` and `Edit`; VS Code uses `create_file`, `replace_string_in_file`, `editFiles`.  Any heartbeat logic filtering on tool names must normalise these.

---

## Section 5 — Failure Modes and Mitigations

### 5.1  File-lock / race conditions

**Risk**: Two `PostToolUse` hooks fire within milliseconds (rapid multi-file edits).  Both attempt to write `state.json` simultaneously.

**Mitigation**: Use `python3`'s `os.replace()` with an atomic write pattern (write to `.state.json.tmp`, rename to `state.json`).  This is the only cross-platform atomic write available in bash+python3:

```bash
python3 - << 'PY'
import json, os, pathlib, time
p = pathlib.Path('.copilot/workspace/state.json')
tmp = p.with_suffix('.tmp')
data = json.loads(p.read_text()) if p.exists() else {}
data['last_soft_write'] = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
tmp.write_text(json.dumps(data, indent=2))
os.replace(tmp, p)  # atomic on POSIX and Windows NTFS
PY
```

### 5.2  Update spam / churn

**Risk**: `PostToolUse` fires on every file edit.  A refactor touching 40 files triggers 40 heartbeat write attempts.

**Mitigation**: Soft triggers in `pulse.sh` check `state.json["last_soft_write"]`.  If the elapsed time since last write is < `MIN_INTERVAL_SOFT` (recommended: 300 s), emit no-op `{"continue": true}`.  Hard triggers bypass the interval check.

### 5.3  Stale state

**Risk**: Agent crashes or VS Code closes mid-session without running the `Stop` hook.  Next session finds `.heartbeat-session` in `pending` state.

**Mitigation**: `SessionStart` checks the previous sentinel.  If `session_state == "pending"` and `session_start` is older than `STALE_THRESHOLD` (recommended: 4 hours), log a warning in `HEARTBEAT.md` History and reinitialise with `stale_recovery: true`.

### 5.4  Cross-platform parity (bash vs PowerShell)

**Risk**: `pulse.sh` logic diverges from `pulse.ps1`, causing inconsistent heartbeat state across operating systems.

**Mitigation policy**:

- All state logic in `pulse.sh` (bash) must have a functional equivalent in `pulse.ps1`.
- `state.json` is the canonical source of truth; both scripts read/write the same schema.
- PowerShell uses `[System.IO.File]::Move($tmp, $dest, $true)` for atomic rename.
- Test matrix must include both scripts in CI.

### 5.5  Branch pollution

**Risk**: Frequent `state.json` and `HEARTBEAT.md` writes appear in `git status`, polluting diffs and commits.

**Mitigation**:

- Add `.copilot/workspace/state.json` and `.copilot/workspace/.heartbeat-session` to `.gitignore`.
- `HEARTBEAT.md` History rows are written only on hard triggers (low frequency by design).

### 5.6  Missing or corrupt state.json

**Risk**: `state.json` contains malformed JSON (e.g. partially written before a crash).

**Mitigation**: All reads use `try/except` and fall back to a fresh state object.  A corrupt file is logged to stderr (surfaced via hook warning mechanism) and overwritten with defaults.  Script always exits 0 so no hook fires a blocking error for a state management issue.

---

## Section 6 — Recommended Algorithm

### 6.1  Trigger matrix

| Trigger | Hook | Type | Reads state.json? | Writes state.json? | Writes HEARTBEAT.md? |
|---------|------|------|------------------|--------------------|---------------------|
| Session start | `SessionStart` | Hard | Yes (recover stale) | Yes (init sentinel) | Only if STALE_RECOVERY |
| User explicit | `UserPromptSubmit` (keyword match) | Hard | Yes | Yes | Yes (full check) |
| Pre-compaction | `PreCompact` | Hard | Yes (read pulse) | No | No |
| Task completion / Stop | `Stop` (first invocation) | Hard | Yes | Yes (mark complete) | Yes (if checks alert) |
| >5 files changed | `PostToolUse` | Soft | Yes (mtime guard) | Yes if guard passes | No |
| Refactor task tag | `PostToolUse` | Soft | Yes (mtime guard) | Yes if guard passes | No |
| Manifest changed | `PostToolUse` (file pattern guard) | Soft | Yes (mtime guard) | Yes if guard passes | No |
| Subagent spawn | `SubagentStart` | None | No | No | No |
| Subagent end | `SubagentStop` | None | No | No | No |

> **Rationale for no-write on SubagentStart/Stop**: Subagents are transient; writing state on every subagent event adds noise with no diagnostic value.  The parent session's `Stop` hook captures the aggregate result.

### 6.2  Read/write policy

**Read-only occasions** (never write, only inject context):

- `PreCompact` — read `state.json` and emit pulse as `additionalContext`
- Any soft trigger within `MIN_INTERVAL_SOFT` window (debounce active)
- `SubagentStart`/`SubagentStop` at any depth

**Write occasions** (update `state.json` and optionally `HEARTBEAT.md`):

- `SessionStart` — always write sentinel (init/recovery)
- `Stop` (first hit) — mark sentinel complete; write History row if checks alert
- Hard explicit trigger — full check; write History row unconditionally

### 6.3  Suppression rules

A `state.json` write is suppressed when **all** of the following hold:

1. Trigger type is `soft`
2. `state.json["last_soft_write"]` exists and `now - last_soft_write < 300` seconds
3. Pulse has not changed since last write (`state.json["pulse"] == current_pulse`)

A `HEARTBEAT.md` History row is suppressed when:

1. All checks pass (no `[!]` prefix would be added to Pulse)
2. Trigger is neither `explicit` nor `session_start`
3. No retrospective output was persisted to SOUL.md / MEMORY.md / USER.md this session

### 6.4  Sidecar state.json schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12",
  "type": "object",
  "properties": {
    "schema_version":  { "type": "integer", "const": 1 },
    "session_id":      { "type": "string" },
    "session_state":   { "type": "string", "enum": ["pending", "running", "complete", "stale"] },
    "session_start":   { "type": "string", "format": "date-time" },
    "last_hard_write": { "type": "string", "format": "date-time" },
    "last_soft_write": { "type": "string", "format": "date-time" },
    "pulse":           { "type": "string" },
    "pending_checks":  { "type": "array", "items": { "type": "string" } },
    "stale_recovery":  { "type": "boolean" }
  },
  "required": ["schema_version", "session_id", "session_state", "pulse"]
}
```

**Default (empty/corrupt fallback)**:

```json
{
  "schema_version": 1,
  "session_id": "unknown",
  "session_state": "pending",
  "session_start": "1970-01-01T00:00:00Z",
  "last_hard_write": "1970-01-01T00:00:00Z",
  "last_soft_write": "1970-01-01T00:00:00Z",
  "pulse": "HEARTBEAT_UNKNOWN",
  "pending_checks": [],
  "stale_recovery": false
}
```

### 6.5  Fallback behaviour when state missing or corrupt

```
1. Read state.json
   → if missing:       use default object
   → if malformed:     log warning to stderr; use default object
2. If session_state == "pending" AND session_start older than 4 hours:
   → set session_state = "stale"; set stale_recovery = true
3. Proceed with trigger logic using (recovered) state
4. Atomically write corrected state.json at end of script
```

---

## Section 7 — Implementation-Ready Specification

### 7.1  `pulse.sh` entry-point pseudo-code

```bash
#!/usr/bin/env bash
# pulse.sh — heartbeat pulse orchestrator
# Usage: pulse.sh --trigger <TRIGGER> [--files <N>]
# stdin:  JSON hook payload
# stdout: JSON hook response
set -euo pipefail

TRIGGER=""
FILE_COUNT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --trigger) TRIGGER="$2"; shift 2 ;;
    --files)   FILE_COUNT="$2"; shift 2 ;;
    *)         shift ;;
  esac
done

STATE_FILE=".copilot/workspace/state.json"
HB_FILE=".copilot/workspace/HEARTBEAT.md"
MIN_INTERVAL_SOFT=300  # seconds

# --- load_state: read state.json; return default on missing/corrupt ---
load_state() { ... }  # python3 json.load with try/except → default

# --- is_stale: check session_state==pending and age > 4h ---
is_stale() { ... }

# --- is_suppressed: check soft debounce window ---
is_suppressed() { ... }

# --- write_state: atomic temp-file rename ---
write_state() { ... }

# --- run_checks: evaluate HEARTBEAT.md check list ---
run_checks() { ... }  # returns PULSE_OK or PULSE_WARN:<reason>

# --- append_history_row: append to HEARTBEAT.md History table ---
append_history_row() { ... }

# --- inject_context: emit additionalContext JSON ---
inject_context() { ... }

# --- Main dispatch ---
load_state

case "$TRIGGER" in
  session_start)
    if is_stale; then
      append_history_row "STALE_RECOVERY"
      STATE["stale_recovery"]=true
      STATE["session_state"]="pending"
    else
      STATE["session_state"]="pending"
    fi
    STATE["session_id"]="$SESSION_ID"
    STATE["session_start"]="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    write_state
    inject_context
    ;;

  stop)
    [[ "$STOP_HOOK_ACTIVE" == "true" ]] && { echo '{"continue":true}'; exit 0; }
    PULSE=$(run_checks)
    STATE["session_state"]="complete"
    STATE["last_hard_write"]="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    write_state
    if [[ "$PULSE" == PULSE_WARN* ]]; then
      append_history_row "$PULSE"
    fi
    echo '{"continue":true}'
    ;;

  compaction)
    PULSE="${STATE[pulse]:-HEARTBEAT_UNKNOWN}"
    emit_precompact_context "Heartbeat: $PULSE | State: ${STATE[session_state]}"
    ;;

  soft_post_tool)
    is_suppressed && { echo '{"continue":true}'; exit 0; }
    PULSE=$(run_soft_checks)
    STATE["last_soft_write"]="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    STATE["pulse"]="$PULSE"
    write_state
    [[ "$PULSE" == PULSE_WARN* ]] && inject_context "Soft alert: $PULSE"
    echo '{"continue":true}'
    ;;

  explicit)
    PULSE=$(run_checks)
    STATE["last_hard_write"]="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    STATE["pulse"]="$PULSE"
    write_state
    append_history_row "$PULSE"
    inject_context "Heartbeat explicit check: $PULSE"
    ;;
esac
```

### 7.2  Recommended hook wiring

```json
{
  "hooks": {
    "SessionStart": [
      { "type": "command", "command": "./.github/hooks/scripts/session-start.sh",
        "windows": "powershell -File .github\\hooks\\scripts\\session-start.ps1", "timeout": 10 },
      { "type": "command", "command": "./.github/hooks/scripts/pulse.sh --trigger session_start",
        "windows": "powershell -File .github\\hooks\\scripts\\pulse.ps1 -Trigger session_start", "timeout": 5 }
    ],
    "PostToolUse": [
      { "type": "command", "command": "./.github/hooks/scripts/post-edit-lint.sh", "timeout": 30 },
      { "type": "command", "command": "./.github/hooks/scripts/pulse.sh --trigger soft_post_tool",
        "windows": "powershell -File .github\\hooks\\scripts\\pulse.ps1 -Trigger soft_post_tool", "timeout": 5 }
    ],
    "PreCompact": [
      { "type": "command", "command": "./.github/hooks/scripts/save-context.sh", "timeout": 10 },
      { "type": "command", "command": "./.github/hooks/scripts/pulse.sh --trigger compaction",
        "windows": "powershell -File .github\\hooks\\scripts\\pulse.ps1 -Trigger compaction", "timeout": 5 }
    ],
    "Stop": [
      { "type": "command", "command": "./.github/hooks/scripts/scan-secrets.sh", "timeout": 30 },
      { "type": "command", "command": "./.github/hooks/scripts/enforce-retrospective.sh", "timeout": 5 }
    ]
  }
}
```

> `Stop` hook: in Phase 3, `enforce-retrospective.sh` may be subsumed into `pulse.sh --trigger stop` once sentinel state is unified.  Until then, both coexist.

### 7.3  Acceptance criteria

| # | Criterion |
|---|-----------|
| AC-1 | `pulse.sh --trigger session_start` writes `state.json` with `session_state: "pending"` within 2 s |
| AC-2 | Two `soft_post_tool` calls within 300 s produce exactly one `state.json` write (debounce) |
| AC-3 | `pulse.sh --trigger stop` sets `session_state: "complete"` |
| AC-4 | A corrupt `state.json` is replaced with defaults; script exits 0 |
| AC-5 | A `pending` `state.json` older than 4 hours triggers `stale_recovery: true` on next `session_start` |
| AC-6 | `HEARTBEAT.md` History row appended only when `checks_alerted OR trigger==explicit` |
| AC-7 | `pulse.ps1` passes the same test assertions as `pulse.sh` |
| AC-8 | `state.json` and `.heartbeat-session` are listed in `.gitignore` |
| AC-9 | `pulse.sh` completes within 1 s on standard Linux filesystem |
| AC-10 | All pre-existing session-start and enforce-retrospective tests pass after migration |

---

## Section 8 — Testing Blueprint

### 8.1  Unit tests per trigger path (`tests/test-hook-pulse.sh`)

```bash
test_session_start_writes_sentinel()        # AC-1
test_session_start_detects_stale_sentinel() # AC-5
test_session_start_no_stale_within_threshold()
test_soft_trigger_suppressed_within_interval() # AC-2
test_soft_trigger_fires_when_interval_exceeded()
test_stop_trigger_marks_complete()          # AC-3
test_compaction_trigger_read_only()
test_explicit_trigger_writes_history_row()  # AC-6
test_corrupt_state_json_fallback()          # AC-4
test_missing_state_json_creates_defaults()
```

### 8.2  Regression tests for false positives/negatives

```bash
test_fp_no_duplicate_history_rows_on_silent_session()
test_fp_no_write_when_pulse_unchanged()
test_fn_stop_blocks_when_sentinel_pending()
test_fn_stop_passes_when_sentinel_complete()
test_fn_stale_recovery_warns_in_context()
```

### 8.3  Performance budget check

```bash
time_budget_check() {
  START_NS=$(date +%s%N)
  echo '{"sessionId":"perf-test"}' \
    | bash .github/hooks/scripts/pulse.sh --trigger session_start >/dev/null
  ELAPSED_MS=$(( ($(date +%s%N) - START_NS) / 1000000 ))
  [[ $ELAPSED_MS -lt 1000 ]] \
    || { echo "FAIL: pulse.sh exceeded 1000ms (got ${ELAPSED_MS}ms)"; return 1; }
}
```

Add to `tests/run-all.sh` after Phase 2.

---

## Section 9 — Migration Strategy (Phased Rollout)

### Phase 1 — Sidecar state.json (non-breaking, ~1 day)

1. `session-start.sh` writes `state.json` (schema v1) in addition to `.heartbeat-session`.
2. `enforce-retrospective.sh` reads `state.json["session_state"]` as a secondary check (`.heartbeat-session` remains primary).
3. Add `.copilot/workspace/state.json` to `.gitignore`.
4. Write `tests/test-hook-pulse.sh` with `test_session_start_writes_sentinel` and `test_corrupt_state_json_fallback`.

**Rollback**: Remove `state.json` writes from both scripts.  No behaviour change externally.

### Phase 2 — `pulse.sh` scaffold with soft trigger (~2 days)

1. Write `pulse.sh` and `pulse.ps1` with `soft_post_tool` trigger only.
2. Add as second entry under `PostToolUse` in `copilot-hooks.json` (5 s timeout).
3. Mirror to `template/hooks/scripts/`.
4. Expand tests: debounce assertions, file-count guard.

**Rollback**: Remove `pulse.sh` entry from `PostToolUse`.

### Phase 3 — Sentinel migration to `pulse.sh` (~2 days)

1. Add `session_start`, `stop`, `compaction`, `explicit` trigger handlers to `pulse.sh`.
2. Remove sentinel-write Python block from `session-start.sh` (now in `pulse.sh`).
3. `enforce-retrospective.sh` delegates sentinel check to `pulse.sh --query sentinel_state` (or merges entirely).
4. Expand tests for all AC-1 through AC-10.

**Rollback**: Re-add sentinel-write to `session-start.sh`; restore `enforce-retrospective.sh` to standalone mode.

### Phase 4 — `UserPromptSubmit` explicit trigger (optional, ~1 day)

1. Add `UserPromptSubmit` to `copilot-hooks.json`.
2. `pulse.sh --trigger user_prompt` reads `prompt` from stdin JSON.
3. If prompt matches keyword list (`heartbeat`, `check your heartbeat`, `run health check`): run full checks, write History row.
4. Otherwise: `{"continue": true}` immediately.

**Rollback**: Remove `UserPromptSubmit` entry.

---

## Gaps / Further Research Needed

1. **`UserPromptSubmit` prompt field access**: The `prompt` value is in stdin JSON as `"prompt"` key (not a shell env var).  Verify parsing semantics with a live hook test before Phase 4 implementation.

2. **Agent-scoped hooks in `.agent.md` frontmatter**: Custom agents (Security, Researcher) could define their own scoped heartbeat hooks with domain-specific checks.  This offers more precision but adds per-agent maintenance overhead.

3. **`stop_hook_active` forwarding in merged `pulse.sh`**: When `enforce-retrospective.sh` blocks Stop and the agent re-invokes, subsequent Stop hooks receive `stop_hook_active: true`.  If Phase 3 merges `enforce-retrospective.sh`, this flag must be propagated correctly.  The current script already handles it — migration must preserve the guard.

4. **Latency profiling on Windows (`pulse.ps1`)**: `[System.IO.File]::Move()` with overwrite has not been benchmarked on NTFS under load.  Profile before Phase 3 completion on Windows.

5. **Token cost of `additionalContext` injection**: Injected context consumes prompt budget every turn.  A 200-token cap on injected pulse strings is a reasonable default; actual measurement is needed.

6. **`PreCompact` `additionalContext` contract**: The VS Code docs list PreCompact as using "common output format only" but the current runtime accepts `hookSpecificOutput.additionalContext`.  This is an undocumented field and could break in a future VS Code release.  Track this against the official spec.
