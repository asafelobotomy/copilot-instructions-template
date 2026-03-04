# Hooks Guide — Human Reference

> **Machine-readable version**: §8 (Heartbeat Protocol) in `.github/copilot-instructions.md`
> This document explains what agent hooks are, how they integrate with the template, and how to customise them.

---

## What are hooks?

**Agent hooks** are deterministic shell commands that VS Code executes at specific points during an agent session. Unlike instructions or custom prompts that *guide* agent behaviour, hooks *enforce* it — they run your code with guaranteed outcomes regardless of how the agent is prompted.

Hooks complement the template's existing systems:

| System | Type | Enforcement |
|--------|------|-------------|
| `copilot-instructions.md` | Soft guidance | Agent follows if it "remembers" |
| `HEARTBEAT.md` (retrospective) | Soft guidance | Agent runs when triggered |
| **Hooks** | **Hard enforcement** | **Runs deterministically every time** |

---

## How hooks work with this template

### Lifecycle events

VS Code fires hooks at eight lifecycle points. The template ships five starter hooks:

| Event | Template hook | What it does |
|-------|--------------|-------------|
| `SessionStart` | `session-start.sh` | Injects project context (name, version, branch, runtimes, heartbeat pulse) into every new session |
| `PreToolUse` | `guard-destructive.sh` | Blocks dangerous commands (`rm -rf /`, `DROP TABLE`) and flags caution patterns (`git push --force`) for user confirmation |
| `PostToolUse` | `post-edit-lint.sh` | Auto-formats edited files using the project's formatter (Prettier, Black, rustfmt, gofmt) |
| `Stop` | `enforce-retrospective.sh` | Prevents the agent from stopping if the retrospective has not been run |
| `PreCompact` | `save-context.sh` | Saves a workspace snapshot (heartbeat, memory, heuristics, git status) before conversation context is truncated |

Events not yet configured: `UserPromptSubmit`, `SubagentStart`, `SubagentStop`. You can add hooks for these — see [Adding custom hooks](#adding-custom-hooks).

### File locations

During setup, hooks are copied to:

```text
.github/
└── hooks/
    ├── copilot-hooks.json       ← hook configuration (events → scripts)
    └── scripts/
        ├── session-start.sh     ← SessionStart
        ├── guard-destructive.sh ← PreToolUse
        ├── post-edit-lint.sh    ← PostToolUse
        ├── enforce-retrospective.sh ← Stop
        └── save-context.sh      ← PreCompact
```

VS Code discovers hooks by reading `.github/hooks/*.json`. The JSON maps lifecycle events to shell commands.

---

## Starter hooks in detail

### 1. Session Start — context injection

**File**: `scripts/session-start.sh`
**Event**: `SessionStart`
**Purpose**: Every new agent session starts with zero context about your project. This hook auto-injects:

- Project name and version (from `package.json`, `pyproject.toml`, or `Cargo.toml`)
- Current Git branch and commit hash
- Runtime versions (Node, Python)
- Current heartbeat pulse status

The agent receives this as `additionalContext` before processing your first prompt.

**Why it matters**: Without this, the agent has to read workspace files to orient itself — which consumes context window and may not happen at all in short sessions.

### 2. Destructive Command Guard

**File**: `scripts/guard-destructive.sh`
**Event**: `PreToolUse`
**Purpose**: Enforces §5 ("Secure by default") deterministically. Even if the agent is tricked via prompt injection, this hook blocks:

**Blocked** (hard deny):

- `rm -rf /`, `rm -rf ~`, `rm -rf .`
- `DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`
- `mkfs.*`, `dd if=… of=/dev/`
- Fork bombs, `chmod -R 777 /`
- Pipe-to-shell patterns (`curl … | sh`, `wget … | sh`)

**Caution** (user confirmation required):

- `rm -rf` (in any path), `rm -r`
- `DROP`, `DELETE FROM`
- `git push --force`, `git reset --hard`, `git clean -fd`
- `npm publish`, `cargo publish`, `pip install --`

Only terminal/command tools are inspected — file edits and other tools pass through.

### 3. Post-Edit Auto-Format

**File**: `scripts/post-edit-lint.sh`
**Event**: `PostToolUse`
**Purpose**: Automatically formats files after the agent edits them. Detects the file extension and runs the appropriate formatter:

| Extension | Formatter |
|-----------|-----------|
| `.js`, `.jsx`, `.ts`, `.tsx`, `.mjs`, `.cjs` | Prettier (if installed) |
| `.py` | Black or Ruff (if installed) |
| `.rs` | rustfmt |
| `.go` | gofmt |

If no formatter is available for the file type, the hook does nothing. It never installs formatters — only uses what's already in the project.

### 4. Retrospective Enforcer

**File**: `scripts/enforce-retrospective.sh`
**Event**: `Stop`
**Purpose**: The retrospective (§8, HEARTBEAT.md) is the agent's primary learning mechanism. Without enforcement, the agent may skip it when sessions end abruptly. This hook:

1. Checks if `stop_hook_active` is `true` (prevents infinite loops)
2. Scans the session transcript for retrospective keywords
3. Checks if `HEARTBEAT.md` was modified in the last 5 minutes
4. If no evidence of retrospective execution → blocks the stop and instructs the agent to run it

**Important**: When a Stop hook blocks, the agent continues running and additional turns consume premium requests. The `stop_hook_active` guard ensures this can only happen once per session.

### 5. Pre-Compaction Context Saver

**File**: `scripts/save-context.sh`
**Event**: `PreCompact`
**Purpose**: Long agent sessions eventually hit the context window limit. When VS Code compacts the conversation, earlier messages are truncated. This hook captures a snapshot of critical state *before* compaction occurs:

- Current heartbeat pulse
- Recent entries from MEMORY.md (last 20 lines)
- Key heuristics from SOUL.md
- Git working tree status

This snapshot is injected as `additionalContext` into the compacted conversation, ensuring the agent doesn't lose awareness of project state.

---

## Configuration format

The hook configuration file is JSON with a `hooks` object:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "./.github/hooks/scripts/guard-destructive.sh",
        "windows": "powershell -File .github\\hooks\\scripts\\guard-destructive.ps1",
        "timeout": 5
      }
    ]
  }
}
```

Each hook entry supports:

| Property | Type | Description |
|----------|------|-------------|
| `type` | string | Must be `"command"` |
| `command` | string | Default command (cross-platform) |
| `windows` | string | Windows-specific override |
| `linux` | string | Linux-specific override |
| `osx` | string | macOS-specific override |
| `timeout` | number | Timeout in seconds (default: 30) |

---

## Adding custom hooks

### Add a new hook to an existing event

Edit `.github/hooks/copilot-hooks.json` and append to the event's array:

```json
{
  "hooks": {
    "PostToolUse": [
      { "type": "command", "command": "./.github/hooks/scripts/post-edit-lint.sh" },
      { "type": "command", "command": "./.github/hooks/scripts/your-custom-hook.sh" }
    ]
  }
}
```

Hooks for the same event run sequentially. The most restrictive decision wins for `PreToolUse`.

### Add a hook for an unconfigured event

The template does not ship hooks for `UserPromptSubmit`, `SubagentStart`, or `SubagentStop`. To add one:

1. Create a script in `.github/hooks/scripts/`
2. Add the event to `copilot-hooks.json`
3. Make the script executable (`chmod +x`)

Example — log every user prompt:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "type": "command",
        "command": "./.github/hooks/scripts/log-prompt.sh",
        "timeout": 5
      }
    ]
  }
}
```

### Use the /hooks command

Type `/hooks` in the chat input to configure hooks through an interactive UI. This opens the hook file in the editor at the command field.

---

## Disabling hooks

To disable a specific hook, remove its entry from `copilot-hooks.json`. To disable all hooks, rename or delete the JSON file.

To temporarily disable a hook without editing JSON, make the script exit immediately:

```bash
#!/usr/bin/env bash
echo '{"continue": true}'
exit 0
```

---

## Interaction with other template systems

| Template system | Hook interaction |
|-----------------|-----------------|
| **Heartbeat Protocol (§8)** | `SessionStart` injects heartbeat pulse. `Stop` enforces retrospective. `PreCompact` saves heartbeat state. |
| **Security (§5)** | `PreToolUse` provides deterministic enforcement of §5's "Secure by default" principle. |
| **Waste Elimination (§6)** | `PostToolUse` auto-formats to prevent W9 (manual repetition of formatting). |
| **Workspace identity files** | `PreCompact` preserves MEMORY.md, SOUL.md state across context compaction. |
| **Subagent Protocol (§9)** | `SubagentStart`/`SubagentStop` hooks (not yet configured) can enforce context passing and result validation. |
| **Graduated Trust (§10)** | The `PreToolUse` guard reinforces Guarded-tier protections for config files and secrets. |

---

## Troubleshooting

### View hook diagnostics

Right-click in the Chat view → **Diagnostics** to see loaded hooks and validation errors.

### View hook output

Open the **Output** panel → select **GitHub Copilot Chat Hooks** from the channel dropdown.

### Dependencies

The five starter hook scripts require **Python 3** to be installed and available on `$PATH`.
Python 3 is used for JSON parsing — if it is missing, `guard-destructive.sh` will silently
pass all commands through (including dangerous ones) and other hooks will produce no output.

Verify Python 3 is available:

```bash
python3 --version
```

On macOS, install via `brew install python`. On Windows (WSL), `sudo apt install python3`.
On minimal CI images, add `python3` to your environment setup.

### Common issues

| Problem | Fix |
|---------|-----|
| Hook not executing | Verify `.github/hooks/copilot-hooks.json` exists and has `.json` extension |
| Permission denied | Run `chmod +x .github/hooks/scripts/*.sh` |
| Timeout errors | Increase `timeout` in the JSON config (default: 30s) |
| JSON parse errors | Ensure scripts output valid JSON to stdout |
| Stop hook loops | Always check `stop_hook_active` before blocking |
| `guard-destructive.sh` not blocking dangerous commands | Python 3 may be missing — see [Dependencies](#dependencies) above |

---

## Security considerations

- Hook scripts run with the same permissions as VS Code. Review scripts before enabling, especially from shared repositories.
- Use the `chat.tools.edits.autoApprove` setting to prevent the agent from editing hook scripts without manual approval.
- Never hardcode secrets in hook scripts — use environment variables.
- The `guard-destructive.sh` script is a safety net, not a replacement for proper access controls.

---

## Customisation examples

### Require approval for database tools

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "./.github/hooks/scripts/guard-destructive.sh"
      },
      {
        "type": "command",
        "command": "bash -c 'INPUT=$(cat); TOOL=$(echo \"$INPUT\" | grep -o '\"tool_name\"[^\"]*\"[^\"]*\"' | head -1); if echo \"$TOOL\" | grep -qi \"database\\|sql\\|prisma\"; then echo \"{\\\"hookSpecificOutput\\\":{\\\"hookEventName\\\":\\\"PreToolUse\\\",\\\"permissionDecision\\\":\\\"ask\\\",\\\"permissionDecisionReason\\\":\\\"Database tool detected — requires confirmation\\\"}}\"; else echo \"{\\\"continue\\\": true}\"; fi'",
        "timeout": 5
      }
    ]
  }
}
```

### Inject API keys at session start

```json
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "./.github/hooks/scripts/session-start.sh"
      },
      {
        "type": "command",
        "command": "bash -c 'echo \"{\\\"hookSpecificOutput\\\":{\\\"hookEventName\\\":\\\"SessionStart\\\",\\\"additionalContext\\\":\\\"API_BASE_URL=${API_BASE_URL:-http://localhost:3000}\\\"}}\"'",
        "env": { "API_BASE_URL": "${env:API_BASE_URL}" },
        "timeout": 5
      }
    ]
  }
}
```

---

## Further reading

- [VS Code hooks documentation](https://code.visualstudio.com/docs/copilot/customization/hooks)
- [Hook lifecycle events reference](https://code.visualstudio.com/docs/copilot/customization/hooks#_hook-lifecycle-events)
- [§8 Heartbeat Protocol](INSTRUCTIONS-GUIDE.md) in the Instructions Guide
