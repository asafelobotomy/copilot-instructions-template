# Research: Heartbeat Health File Utilization in AI Agent Workflows

> Date: 2026-03-30 | Agent: Researcher | Status: final

---

## Section A — Evidence Summary

### A1. VS Code Copilot Hooks — documented facts

**Source**: <https://code.visualstudio.com/docs/copilot/customization/hooks>

| Fact | Evidence |
|------|----------|
| Stop hook uses `hookSpecificOutput.decision: "block"` to prevent stopping and give the agent another turn | Docs Stop Output table: `"decision": "block"` → "Prevent the agent from stopping" |
| `continue: false` (top-level JSON) is a **separate, more drastic** action: stops the entire agent session immediately | Docs: "`continue: false` stops the entire agent session. Use `stopReason` to tell the user why. **This is more drastic** than blocking a single tool call." |
| When `decision: "block"` is used, the agent gets another turn. `stop_hook_active = true` on the next invocation — the script MUST check this to avoid infinite loops | Docs: "Always check the `stop_hook_active` field to prevent the agent from running indefinitely." |
| SessionStart hook receives `sessionId` in its input JSON | Docs SessionStart input schema — `hookEventName`, `timestamp`, `cwd`, `sessionId`, `transcript_path`, `source` |
| PreCompact hook output is `additionalContext`-only; it cannot write files via hook output | Docs PreCompact section: "PreCompact hook uses the common output format only" |
| Hook scripts CAN write files via shell commands | Hooks are arbitrary shell scripts; the post-edit-lint example uses `npx prettier --write` |
| Stop hook default timeout is 5 seconds (matches current config) | `copilot-hooks.json` confirms `"timeout": 5` for Stop |
| Agent plugins can bundle hooks; installed plugin hooks fire alongside workspace hooks | Docs: "Plugin hooks run alongside workspace-level and user-level hooks" |
| VS Code and Claude Code use the same hook format — both recognize `decision: "block"` in Stop hookSpecificOutput | Docs: "VS Code uses the same hook format as Claude Code and Copilot CLI" |

### A2. OpenClaw Heartbeat Pattern — documented facts

**Source**: <https://docs.openclaw.ai/gateway/heartbeat> and <https://docs.openclaw.ai/automation/cron-vs-heartbeat>

| Fact | Evidence |
|------|----------|
| OpenClaw heartbeat is **timed** (30m default), not event-driven. This repo adapted it to event-driven triggers | Docs: `every: "30m"` config; CHANGELOG: "event-triggered execution replacing timed intervals" |
| HEARTBEAT.md is a **prompt input**, not an output. Infrastructure never auto-writes it; the model can update it only when explicitly asked | Docs: "if you ask it to. HEARTBEAT.md is just a normal file in the agent workspace, so you can tell the agent something like: 'Update HEARTBEAT.md to add a daily calendar check.'" |
| `HEARTBEAT_OK` is a sentinel reply meaning "nothing needs attention". Replies ≤ 300 chars with `HEARTBEAT_OK` at start/end are silently dropped | Docs: "HEARTBEAT_OK appears at the start or end of the reply — the token is stripped and the reply is dropped if the remaining content is ≤ ackMaxChars (default: 300)" |
| `isolatedSession: true` reduces per-heartbeat token cost from ~100K tokens to ~2–5K | Docs: "Dramatically reduces per-heartbeat token cost. Combine with lightContext: true for maximum savings." |
| `lightContext: true` limits bootstrap files to only HEARTBEAT.md | Docs: "keeps only HEARTBEAT.md from workspace bootstrap files" |
| If HEARTBEAT.md is effectively empty (headers only), the run is skipped to save API calls | Docs: "if HEARTBEAT.md is effectively empty... OpenClaw skips the heartbeat run to save API calls" |
| Heartbeat is optimized for **batching multiple periodic checks** in one model turn; cron is for exact timing / isolation | Cron-vs-heartbeat docs: quick decision table shows heartbeat for "multiple periodic checks", cron for "exact timing required" |
| OpenClaw heartbeat runs in the **main session** by default; it does NOT create background task records | Docs: "Heartbeat is a scheduled main-session turn — it does not create background task records" |

### A3. Event-Driven Pattern theory — documented facts

**Source**: <https://martinfowler.com/articles/201701-event-driven.html>

| Fact | Evidence |
|------|----------|
| "Event-as-passive-aggressive-command" is an anti-pattern — when the source expects a reaction but styles the message as an event | Fowler: "the source system expects the recipient to carry out an action, and ought to use a command message to show that intention, but styles the message as an event instead" |
| Event-Carried State Transfer avoids query-dependency on source; recipient updates its own copy | Fowler: "Events carry details of the data that changed. A recipient can then update its own copy" |
| Event sourcing: snapshots derived from append-only event log. History table is an event log; Pulse is a derived working copy | Fowler: "We can look at the event log as either a list of changes, or as a list of states." |

### A4. copilot-profile-tools companion extension — inference only

**Finding**: The extension `asafelobotomy.copilot-profile-tools` is referenced in `.vscode/extensions.json` and documented in `.github/agents/extensions.agent.md` as contributing a `get_active_profile` Language Model Tool for profile detection. The VS Code Marketplace and GitHub Releases API both return 404 as of 2026-03-30, meaning **no publicly accessible documentation exists**.

**What is documented (internal repo only)**:
- Provides `get_active_profile` LM Tool
- Used for VS Code profile detection, not heartbeat orchestration
- No evidence in any file that it provides heartbeat or health-check capabilities

**Verdict**: This extension does NOT provide better heartbeat orchestration than shell hooks. Shell hooks remain the primary mechanism.

---

## Section B — Risks in Current Design (ranked)

### B1. CRITICAL — Stop hook output format is architecturally wrong

**Evidence**: VS Code documentation distinguishes:
- `{"continue": false}` → drastic: immediately terminates the agent session
- `{"hookSpecificOutput": {"hookEventName": "Stop", "decision": "block", "reason": "..."}}` → preferred: prevents stopping, gives agent another turn to comply

**Current code** (`enforce-retrospective.sh`) returns:
```json
{
  "continue": false,
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "reason": "The retrospective has not been run..."
  }
}
```

This terminates the session instantly. The agent **cannot run the retrospective** after this because the session is over.

The `stop_hook_active` guard in the same script implies the author intended `decision: "block"` semantics (agent gets another turn, is called again with `stop_hook_active: true`). The two approaches are mutually inconsistent.

**Consequence**: When the hook fires and blocks, the agent session ends abruptly without ever completing the retrospective. The fix is to use `decision: "block"`, not `continue: false`.

The existing tests (`test-hook-enforce-retrospective.sh`) reinforce this bug by asserting `'"continue": false'` as the correct blocked output.

### B2. HIGH — mtime-only check produces false positives for the gating condition

**Evidence**: `find .copilot/workspace/operations/HEARTBEAT.md -mmin -5` is satisfied by any process that touches the file — editor autosave, git operations, IDE index, workspace backup, or the `save-context.sh` PreCompact hook itself (which reads but does not write HEARTBEAT.md, but any tool that cat's the file and pipes it could still touch mtime on some filesystems via `atime`).

More critically: if a legitimate heartbeat happened 6 minutes ago (any session longer than 5 minutes will hit this), the check fails even though the retrospective ran correctly.

### B3. HIGH — Transcript keyword matching produces false positives

**Evidence**: The current check:
```bash
grep -qi 'retrospective\|HEARTBEAT\|Q[1-8].*SOUL\|Q[1-8].*MEMORY\|Q[1-8].*USER' "$TRANSCRIPT_PATH"
```
Matches any transcript line containing the word "retrospective" — including:
- "skip the retrospective this time"
- "the retrospective check failed"
- "the user asked about retrospective principles"
- This research document's content (if the agent reads it during a session)

Additionally, `HEARTBEAT` is present in the session-start hook's `additionalContext` output, meaning almost every normal session will contain "HEARTBEAT" in the transcript. This means the keyword check will pass trivially in most sessions and provides essentially no meaningful gating.

### B4. MEDIUM — HEARTBEAT.md History table will accumulate noise

**Evidence**: The event trigger list includes "Task completion — after completing any user-requested task." In a session with 5 tasks, 5 history rows would be written. OpenClaw addresses this with `HEARTBEAT_OK` suppression: only alert writes produce output. This repo has no equivalent silence-when-healthy mechanism.

**Consequence**: The History table fills with `HEARTBEAT_OK` entries within weeks, diminishing its diagnostic value. The "Keep last 5 entries" instruction is only a soft guard.

### B5. MEDIUM — 5-minute mtime window is structurally too short

**Evidence**: The `enforce-retrospective.sh` uses `-mmin -5`. A session involving complex research, implementation, or testing easily runs 10–30 minutes. If the heartbeat ran at session start (correctly), the mtime check will fail at session stop even for a well-behaved session.

**Consequence**: Well-behaved agents that ran the heartbeat at session start will be blocked from stopping in any session lasting >5 minutes.

### B6. MEDIUM — Hooks do not auto-write HEARTBEAT.md — compliance is instruction-only

**Evidence**: `session-start.sh` reads HEARTBEAT.md but does not write to it. `save-context.sh` reads HEARTBEAT.md but does not write to it. The agent is expected to follow the HEARTBEAT instruction and update the file voluntarily.

**Consequence**: If the agent skips the heartbeat trigger (the instruction says to fire on triggers but does not enforce it mechanically), the file goes stale with no detection mechanism except the Stop hook's mtime check — which, as noted above, is itself unreliable.

### B7. LOW — No session correlation in History

**Evidence**: The History table schema is `| Date | Trigger | Result | Actions taken |`. There is no session ID. Since `SessionStart` hook receives `sessionId`, this information is discarded.

**Consequence**: When debugging a failed retrospective, there is no way to match a History row to a specific transcript or session log.

### B8. LOW — Checks section uses Markdown checkboxes but provides no machine-readable state

**Evidence**: The checks are `- [ ] ...` items. Any edit to HEARTBEAT.md that contains `[x]` would satisfy a file-content-based detector, but no such detector exists. The `Pulse` line is a free-text string (`HEARTBEAT_OK` or `[!] HEARTBEAT_WARN`).

**Consequence**: No programmatic distinction between "checks ran and passed" vs "file was just touched."

---

## Section C — Recommended Design Changes

### Quick Wins (no structural changes, low risk)

**C-QW1. Fix Stop hook output format** (Critical fix)

Replace `"continue": false` with `"decision": "block"` in hookSpecificOutput. This aligns with documented VS Code Stop hook semantics and makes the `stop_hook_active` guard meaningful. Update tests to assert `decision: block` rather than `continue: false`.

**C-QW2. Add session ID to History entries**

The `SessionStart` hook receives `sessionId` in stdin. Pass it through as an environment variable or write it to a temp file. Append it as a column in the History table: `| Date | SessionID | Trigger | Result | Actions taken |`. This has zero consumer impact (history rows are append-only) and adds traceability.

**C-QW3. Widen or eliminate the mtime window; replace with session-boundary sentinel**

Either widen `-mmin -5` to `-mmin -120` (covers most work sessions), or replace the mtime check entirely. See C-D2 for the sentinel approach. As an immediate fix, `-mmin -120` reduces false negatives without requiring schema changes.

**C-QW4. Add silent-when-healthy guidance to HEARTBEAT.md**

Add a note to the History section: _Only append a row if Pulse is `[!] WARN` or the trigger was `explicit` or `session-start`. Skip writing for `HEARTBEAT_OK` task-completion triggers._ This imitates OpenClaw's `ackMaxChars` suppression in prose-instruction form.

**C-QW5. Tighten transcript keyword detection**

Replace the broad keyword check with a combination:
- Look for the specific pattern `Q[1-8]` + answer evidence (any of "SOUL.md", "MEMORY.md", "USER.md" on the same or following line), OR
- Check for HEARTBEAT.md modification since session start via a session-start-sentinel (see C-D2).
Remove `HEARTBEAT` as a keyword matcher since it appears in normal session context from the SessionStart hook output.

### Deeper Changes (structural, require schema migration)

**C-D1. Adopt OpenClaw's HEARTBEAT_OK suppression contract explicitly**

Add to both HEARTBEAT.md and copilot-instructions.md:
```
Response contract: If all checks pass and no issues found, reply HEARTBEAT_OK
and do NOT write a History entry. Only write History entries when: a check found
an issue (WARN or FAIL), the trigger was explicit, or the trigger was session-start.
```
This eliminates churn from the "task completion" trigger.

**C-D2. Session-boundary sentinel written by session-start.sh hook**

The session-start hook writes a lightweight sentinel file (not HEARTBEAT.md itself):
```
.copilot/workspace/.session-open
```
Contents: `<sessionId>:<timestamp>`. The Stop hook checks for this file's existence to determine whether a session is open. The retrospective instruction tells the agent to delete it (or instruct the Stop hook to delete it after successful retrospective detection). This avoids polling HEARTBEAT.md mtime entirely.

Benefits: deterministic, no mtime false positives, no write-on-read issues, small file.

**C-D3. Add a `## Status` block to HEARTBEAT.md with a state machine**

Append a machine-readable block to HEARTBEAT.md:
```markdown
## Status

```yaml
last_session:
  opened: "2026-03-30T10:00:00Z"
  session_id: "session-abc123"
  state: "open"           # open | closed
  retrospective: "pending" # pending | complete
```
```

- `session-start.sh` writes `state: open, retrospective: pending`
- Agent writes `state: closed, retrospective: complete` after running retrospective
- Stop hook parses `retrospective: pending` to decide whether to block

This is the most robust approach but requires HEARTBEAT.md schema migration for both this repo and consumers.

**C-D4. Lightweight write-file action in session-start.sh**

Instead of touching HEARTBEAT.md (which has downstream risk), write to a dedicated sidecar:
```
.copilot/workspace/runtime/.heartbeat-session
```
Format: `<sessionId>|<timestamp>|pending`. The Stop hook reads this file; the agent writes `<sessionId>|<timestamp>|complete` after retrospective. Shell-only parsing, no YAML required.

This has the same benefits as C-D2 but is more expressive, and is lower risk than modifying HEARTBEAT.md from hooks.

**C-D5. Plugin-level heartbeat hook bundle**

If `copilot-profile-tools` or a future plugin gains heartbeat capabilities, a plugin hook could bundle the session-sentinel logic and expose it across VS Code installations. This is currently unavailable (extension not in Marketplace) but is an architecture-level possibility via the VS Code agent plugins system (`chat.plugins.paths`).

---

## Section D — Concrete Implementation Sketch

### D1. Fix enforce-retrospective.sh output format

Change the "block" output from:
```bash
cat <<EOF
{
  "continue": false,
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "reason": "The retrospective has not been run this session..."
  }
}
EOF
```
To:
```bash
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "reason": "Retrospective not complete. Before stopping: run the Retrospective section of HEARTBEAT.md (§8 step 3) and persist insights. Then stop normally."
  }
}
EOF
```

### D2. Add session-sentinel write to session-start.sh

After the existing `PULSE=$(...)` block, before the final `cat <<EOF`, add:

```bash
# Write session-open sentinel for retrospective gate
SESSION_ID=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('sessionId', 'unknown'))
except Exception:
    print('unknown')
" 2>/dev/null || echo "unknown")
SENTINEL_DIR=".copilot/workspace"
if [[ -d "$SENTINEL_DIR" ]]; then
  TIMESTAMP_NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
  printf '%s|%s|pending\n' "$SESSION_ID" "$TIMESTAMP_NOW" \
    > "$SENTINEL_DIR/.heartbeat-session" 2>/dev/null || true
fi
```

### D3. Update enforce-retrospective.sh to use sentinel

Replace the mtime check with sentinel-file check:
```bash
# Check sentinel file for open retrospective
SENTINEL=".copilot/workspace/runtime/.heartbeat-session"
if [[ -f "$SENTINEL" ]]; then
  SENTINEL_STATE=$(cut -d'|' -f3 "$SENTINEL" 2>/dev/null | tr -d '[:space:]' || echo "unknown")
  if [[ "$SENTINEL_STATE" == "complete" ]]; then
    RETRO_RAN="true"
  fi
  # If sentinel exists but is not complete, RETRO_RAN stays "false"
else
  # No sentinel = no tracked session; fall back to mtime check
  if [[ -f .copilot/workspace/operations/HEARTBEAT.md ]]; then
    if find .copilot/workspace/operations/HEARTBEAT.md -mmin -120 2>/dev/null | grep -q .; then
      RETRO_RAN="true"
    fi
  fi
fi
```

### D4. Add retrospective-complete sentinel write to session heartbeat procedure

In HEARTBEAT.md's Retrospective section, add instruction before the final question:
```markdown
> After answering all questions above, write `complete` to the session state:
> ```bash
> sed -i 's/|pending$/|complete/' .copilot/workspace/runtime/.heartbeat-session 2>/dev/null || true
> ```
> This clears the Stop gate.
```

**Note**: This is agent-executed (the agent runs the command), not hook-executed. This is important — it makes the gate explicit and auditable.

### D5. HEARTBEAT.md History schema addition

Add `SessionID` column to the History table header:

```markdown
| Date | SessionID | Trigger | Result | Actions taken |
|------|-----------|---------|--------|---------------|
```

The session-start hook passes `sessionId` via additionalContext; the agent uses it when writing History rows.

### D6. Proposed HEARTBEAT.md section additions

Add after `## Retrospective` section:

```markdown
## Response Contract

- If all **Checks** pass and no new issues found → reply `HEARTBEAT_OK` and do **not** write a History row (silence-when-healthy).
- Write a History row when:
  - Trigger was **Explicit** or **Session start**
  - Any check raised `[!]`
  - Any retrospective question produced a concrete output
- After completing the Retrospective, mark the session sentinel complete:
  ```bash
  sed -i 's/|pending$/|complete/' .copilot/workspace/runtime/.heartbeat-session 2>/dev/null || true
  ```
```

---

## Section E — Validation Plan

### E1. Fix existing tests for enforce-retrospective.sh

`tests/test-hook-enforce-retrospective.sh` currently asserts `'"continue": false'` as the blocked output (B1 bug). After the C-QW1 fix:

- Test 2 ("No transcript blocks") → assert `'"decision": "block"'` instead of `'"continue": false'`
- Test 6 ("Transcript without retrospective keyword blocks") → same update
- Test 7 ("Stale HEARTBEAT.md blocks") → same update, but widen to 10min stale in test since window changes to 120min
- Add new test: **sentinel file `pending` → blocks** (new C-D3 path)
- Add new test: **sentinel file `complete` → passes** (new C-D3 path)
- Add new test: **no sentinel file + fresh HEARTBEAT.md (within 120min) → passes**

### E2. New tests for session-start sentinel

Add `tests/test-hook-session-start-sentinel.sh`:
- Test: running session-start.sh with a writable `.copilot/workspace/` creates `.heartbeat-session` with `pending` state
- Test: `pending` state is parseable (cut -d'|' -f3)
- Test: no crash when `.copilot/workspace/` does not exist

### E3. Regression: test silent-when-healthy

No automated test today for churn prevention. Add a prose-only assertion to the test for HEARTBEAT.md:
- Verify contract note text exists in HEARTBEAT.md ("silence-when-healthy")
- This is a static file content test, not a runtime test

### E4. Metrics to track effectiveness

| Metric | Measurement | Target |
|--------|-------------|--------|
| False stop-blocks per session | Count sessions where `decision: block` fired despite retrospective having run | < 1% of sessions |
| History table churn | Average rows added per session over 30 days | ≤ 1.5 rows/session |
| Session correlation coverage | % of History rows with a non-null SessionID | 100% after migration |
| Gating bypass rate | Sessions where Stop hook passed without sentinel or retrospective | 0% |

---

## Recommendations Summary

| Priority | Action | Effort | Risk |
|----------|--------|--------|------|
| Critical | Fix Stop hook output format to `decision: block` | Low (1 line change + test update) | Low |
| High | Widen mtime window from 5min to 120min | Low (1 character change) | Low |
| High | Remove `HEARTBEAT` as a transcript keyword trigger | Low | Low |
| Medium | Add session-sentinel write to session-start.sh | Medium (15 lines) | Low |
| Medium | Update enforce-retrospective to use sentinel | Medium (20 lines) | Low |
| Medium | Add Response Contract section to HEARTBEAT.md | Low | Low (consumers inherit next update) |
| Medium | Add SessionID column to History table | Low | Low |
| Low | Add retrospective-complete write instruction to HEARTBEAT.md | Low | Low |
| Low | Investigate copilot-profile-tools for heartbeat capabilities when published | None now | N/A |

---

## Gaps / Further Research Needed

1. **copilot-profile-tools extension**: Not publicly available. If published, re-evaluate whether it provides programmatic heartbeat trigger hooks or LM tools for state management.
2. **Transcript path format**: The `transcript_path` field from Stop hook input has not been tested in all agent configurations (local vs background agent). The keyword-search approach may be more fragile than documented.
3. **PreCompact hook depth**: Whether PreCompact fires in subagent sessions (not just the top-level session) is not explicitly documented. If it does, the save-context.sh could accumulate duplicate heartbeat entries.
4. **`session-start`'s `source` field**: Currently always `"new"` per docs. If this changes (e.g., `"restored"` for forked sessions), the sentinel write logic should suppress re-writing to avoid overwriting a legitimate `complete` state from a forked parent session.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://code.visualstudio.com/docs/copilot/customization/hooks> | Definitive VS Code hooks reference; Stop hook semantics; `decision: block` vs `continue: false` |
| <https://docs.openclaw.ai/gateway/heartbeat> | Original heartbeat mechanism this repo adapted from |
| <https://docs.openclaw.ai/automation/cron-vs-heartbeat> | Design rationale for heartbeat vs scheduled tasks |
| <https://code.visualstudio.com/docs/copilot/customization/agent-plugins> | Plugin hooks architecture; heartbeat orchestration via plugins |
| <https://code.visualstudio.com/updates/v1_110> | Agent Debug panel; context compaction; plugin system introduced |
| <https://martinfowler.com/articles/201701-event-driven.html> | Event-Notification vs Event-Carried-State-Transfer patterns |
