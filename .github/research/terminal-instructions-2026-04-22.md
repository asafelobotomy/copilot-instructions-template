# Research: Terminal Instructions — VS Code / GitHub Copilot Tooling Update

> Date: 2026-04-22 | Agent: Researcher | Status: final

## Summary

VS Code releases 1.115 (2026-04-08) and 1.116 (2026-04-15) introduced significant
changes to terminal agent tools that directly invalidate two bullets in the current
`terminal.instructions.md` and add two missing capability areas. The `send_to_terminal`
tool was added in 1.115 and extended to all visible terminals in 1.116. The LLM-based
prompt-for-input detection was removed in 1.116. Background terminal notifications
graduated from experimental to enabled-by-default in 1.116. Agent sandboxing (preview)
for macOS/Linux was formalised in the security docs with concrete OS-level enforcement
details. All five areas carry actionable wording changes for the instruction file.

## Sources

| URL | Relevance |
|-----|-----------|
| https://code.visualstudio.com/updates/v1_115 | Introduced `send_to_terminal` (background terminals), experimental `chat.tools.terminal.backgroundNotifications` |
| https://code.visualstudio.com/updates/v1_116 | `send_to_terminal`/`get_terminal_output` extended to foreground terminals; LLM input detection removed; background notifications default-on |
| https://code.visualstudio.com/docs/copilot/security | Security baseline, agent sandboxing, auto-approval rule limitations (aliases, quote concat, complex syntax) |
| https://code.visualstudio.com/docs/copilot/concepts/trust-and-safety | Agent sandboxing: OS enforcement (Seatbelt / bubblewrap+socat), file system default read-all / write-cwd-only, network isolation |
| https://code.visualstudio.com/docs/copilot/agents/agent-tools | Permission levels (Default/Bypass/Autopilot), tool approval flow, terminal approval caveats |

## Findings

### F1 — `get_terminal_output` / `send_to_terminal` now accept foreground terminal IDs (v1.116, BREAKING)

**Previous behaviour (pre-v1.115):** these tools only existed or only worked with
the opaque UUID returned by `run_in_terminal` in async mode.

**v1.115:** `send_to_terminal` introduced; `get_terminal_output` existed for background
terminals only.

**v1.116 (2026-04-15):** Both `send_to_terminal` and `get_terminal_output` now accept
a **numeric `terminalId`** (instanceId) to target any terminal visible in the terminal
panel, including user-created foreground terminals, running REPLs, or interactive
scripts. This is a separate parameter (`terminalId`, not `id`) from the opaque UUID.

**Current instruction (outdated):**
> "Use `get_terminal_output`, `send_to_terminal`, and `kill_terminal` only with the
> exact opaque terminal ID returned by `run_in_terminal` async mode."

> "Treat `get_terminal_output`, `send_to_terminal`, and `kill_terminal` as valid only
> when `run_in_terminal` returned a live terminal ID, typically from async mode..."

These bullets are now **factually incorrect**. The distinction that must be preserved
is `id` (opaque UUID from async `run_in_terminal`) versus `terminalId` (numeric
instanceId for any visible terminal). Never conflate them and never use a numeric
instanceId as the `id` parameter.

**Candidate rewrites:**

```
- `get_terminal_output` and `send_to_terminal` accept two distinct identifiers:
  use `id` (the opaque UUID returned by `run_in_terminal` async mode) for
  background sessions started by the agent, and `terminalId` (the numeric
  instanceId) to reach any terminal currently visible in the terminal panel
  (user-created, foreground, or REPL). Never pass one type of identifier
  where the other is required.

- `kill_terminal` accepts only the opaque UUID (`id`) from `run_in_terminal`
  async mode. It cannot target foreground or user-created terminals.

- Do not pass shell names, terminal labels, or `execution_subagent` results to
  any terminal tool. Only `id` (async UUID) and `terminalId` (numeric instanceId)
  are valid selectors.
```

---

### F2 — LLM-based prompt-for-input detection removed (v1.116)

**v1.116:** The per-output-chunk LLM call that classified whether a terminal was
waiting for input has been removed. The agent now sends input via `send_to_terminal`
and surfaces uncertainty to the user via the **question carousel** (which includes a
"Focus Terminal" button). The carousel auto-dismisses if the user starts typing
directly.

The current instructions do not mention interactive input handling via `send_to_terminal`
at all. This gap means instructions written before v1.115 are silent on the primary
mechanism for interactive input.

**Missing bullet:**

```
- For interactive terminal input (password prompts, wizard questions), send
  answers one at a time via `send_to_terminal`. After each send, call
  `get_terminal_output` to read the next prompt before sending the next answer.
  If uncertain whether the terminal is waiting, use the question carousel or
  focus the terminal directly rather than sending blind input.
```

The existing main instructions file already has a detailed interactive-input block;
verify it is consistent with this `send_to_terminal`-first pattern.

---

### F3 — Background terminal notifications enabled by default (v1.116)

**v1.115:** `chat.tools.terminal.backgroundNotifications` introduced as experimental.

**v1.116 (2026-04-15):** The setting is **enabled by default** in Stable. The agent
now receives automatic notifications when a background terminal command finishes, times
out, or requires input — without polling.

**Impact on current instructions:**

The current bullet "Do not add `sleep` loops or blind polling around background
terminals..." is **confirmed correct** and the rationale is now stronger: since
notifications fire automatically, polling is doubly unnecessary. The bullet can be
strengthened with this context.

**Candidate addition/strengthening:**

```
- Background terminal notifications are enabled by default
  (`chat.tools.terminal.backgroundNotifications`). The agent is automatically
  notified when a background command completes or needs input; do not poll
  `get_terminal_output` on a timer or in a sleep loop. Inspect output only
  when the notification or workflow logic gives a concrete reason to do so.
```

---

### F4 — Agent sandboxing (preview, macOS / Linux) — currently missing

**Security docs (current):** VS Code preview feature `chat.tools.terminal.sandbox.enabled`
enables OS-level isolation for terminal commands on macOS (Apple Seatbelt) and
Linux/WSL2 (bubblewrap + socat). Key properties:

- File system defaults: **read access everywhere; write access limited to cwd and
  subdirectories.** Additional paths can be configured.
- Network access: **all outbound blocked by default.** Domain allowlists via
  `chat.agent.allowedNetworkDomains`.
- All child processes inherit the same restrictions (npm, pip, build scripts).
- When sandboxing is enabled, VS Code **auto-approves terminal commands** because
  they already run in a controlled environment.
- Linux prerequisite: `sudo apt-get install bubblewrap socat` (Debian/Ubuntu) or
  `sudo dnf install bubblewrap socat` (Fedora). WSL1 not supported.

**Current instruction gap:** no mention of sandboxing.

**Candidate addition:**

```
- When `chat.tools.terminal.sandbox.enabled` is active (macOS / Linux / WSL2),
  agent-executed terminal commands run with write access restricted to the
  current working directory and no outbound network access by default. Commands
  that need write access outside the workspace or network access will prompt
  to run outside the sandbox; do not suppress this prompt.

- Linux sandboxing requires `bubblewrap` and `socat`. WSL1 is not supported;
  use WSL2 or a dev container instead.
```

---

### F5 — Terminal auto-approval rule limitations (security docs) — currently missing

**Security docs (current):** Auto-approval rules for terminal commands use
best-effort command parsing with **known limitations**:

> "Quote concatenation or shell aliases might bypass the rules and slip through
> undetected."

This is particularly relevant for guidance about relying on `command -v` probing or
assuming terminal auto-approval correctly gates complex shell constructs.

The current instruction on probing (`command -v <tool> before invoking`) is correct
but lacks the caveat that auto-approval rules are not a complete security boundary.

**Candidate addition:**

```
- Terminal command auto-approval rules use best-effort parsing. They do not
  reliably detect shell aliases, quote concatenation, or complex compound
  syntax. Do not treat auto-approval as a security guarantee for complex
  invocations; prefer agent sandboxing or a dev container for stronger
  isolation.
```

---

### F6 — `terminal_last_command` / `terminal_selection` scope — CONFIRMED unchanged

**Current instruction:** "Use `terminal_last_command` and `terminal_selection` only
for the currently active editor terminal. They do not read or control `run_in_terminal`
async sessions."

This remains accurate. Neither of these tools has been extended in recent releases.
No change needed.

---

### F7 — Preference for sync over async — CONFIRMED

**Current instruction:** "If you only need command output rather than a persistent
background session, prefer a synchronous terminal run or `execution_subagent` over
polling a background terminal."

The official docs and architecture confirm: Background sessions cost more (extra
notifications, additional tool calls). Synchronous runs remain the preferred pattern
for non-interactive commands. Confirmed correct; no change needed.

---

### F8 — GitHub CLI auth check — CONFIRMED

**Current instruction:** "Before declaring GitHub CLI auth missing or broken, run
`gh auth status` explicitly."

Not directly addressed in the new docs, but confirmed consistent with the general
principle of explicit probing before declaring tool absence. Confirmed correct.

---

## Recommendations

Priority order for `terminal.instructions.md` edits:

| Priority | Finding | Action |
|----------|---------|--------|
| P0 | F1 — `id` vs `terminalId` parameter distinction | Rewrite 2 outdated bullets |
| P0 | F2 — `send_to_terminal` interactive input pattern | Add missing bullet |
| P1 | F3 — Background notification default-on | Strengthen existing polling bullet |
| P1 | F5 — Auto-approval rule parsing limitations | Add security caveat |
| P2 | F4 — Agent sandboxing behaviour | Add 2 new bullets |

## Gaps / Further research needed

- `kill_terminal` parameter contract for foreground vs background terminals — the
  release notes did not clarify whether `kill_terminal` was also extended to
  foreground terminals in v1.116. The current assumption (async UUID only) should
  be verified against the tool schema before updating that bullet.
- v1.117 release notes (if already published) — check for further terminal tool
  changes before acting on these recommendations.
