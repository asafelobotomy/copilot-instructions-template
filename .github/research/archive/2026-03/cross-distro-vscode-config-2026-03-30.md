# Research: Cross-Distro VS Code + Copilot Configuration

> Date: 2026-03-30 | Agent: Researcher | Status: final

## Summary

A single Git repository shared across Bazzite/Fedora Atomic, Ubuntu, and Arch Linux faces a
fundamental tension: workspace config files (`.vscode/mcp.json`, `.vscode/settings.json`,
`.github/copilot-instructions.md`) are version-controlled and static, yet binary paths, package
managers, and Python locations differ per distro. This report maps every mechanism VS Code and
Copilot expose for per-machine or per-OS variation, evaluates their production readiness, and
ranks approaches for a template repository that gets installed into consumer projects.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://code.visualstudio.com/docs/copilot/reference/mcp-configuration> | MCP config reference: `${env:VAR}`, `envFile`, `${workspaceFolder}`, `${userHome}` variables |
| <https://code.visualstudio.com/docs/editor/variables-reference> | Full variable substitution reference; `settings.json` variable support is limited to specific keys |
| <https://code.visualstudio.com/docs/copilot/customization/hooks> | Hooks: `SessionStart` additionalContext injection; OS-specific `linux`/`osx`/`windows` command fields |
| <https://code.visualstudio.com/docs/debugtest/tasks#_operating-system-specific-properties> | `tasks.json` OS-specific `windows`/`linux`/`osx` top-level and per-task overrides |
| <https://code.visualstudio.com/docs/debugtest/debugging-configuration> | `launch.json` platform-specific literals: `windows`, `linux`, `osx` within configurations |
| <https://code.visualstudio.com/docs/configure/settings> | Settings scopes: user, workspace, language; no native per-OS override syntax in `settings.json` |
| <https://code.visualstudio.com/docs/configure/profiles> | Profiles: per-machine profile with own settings.json, extensions, and MCP servers |
| <https://code.visualstudio.com/docs/editor/settings-sync> | Settings Sync: machine-scoped settings excluded by default; `settingsSync.ignoredSettings` |
| <https://code.visualstudio.com/docs/terminal/profiles> | Terminal profiles: per-platform settings via `terminal.integrated.profiles.linux` etc. |
| <https://code.visualstudio.com/docs/reference/tasks-appendix> | `tasks.json` schema: top-level `linux`, `osx`, `windows` fields in `TaskConfiguration` |

---

## Findings

### Finding 1 — mcp.json supports variable substitution including `${env:VAR}`

**Status: production-ready**

The `.vscode/mcp.json` file accepts VS Code predefined variables in all string values.
Confirmed variables (from official MCP configuration reference):

- `${workspaceFolder}` — absolute path to workspace root
- `${userHome}` — user home directory
- `${env:VARIABLE_NAME}` — reads from the VS Code process environment at startup

Additionally, each server's `env` object and `envFile` field inject variables into the
spawned server process, not into the `command`/`args` values. The `envFile` field itself
accepts `${workspaceFolder}` in its path.

**Concrete pattern for cross-distro binary resolution:**

```json
{
  "servers": {
    "git": {
      "type": "stdio",
      "command": "${env:UVX_BIN}",
      "args": ["mcp-server-git", "--repository", "${workspaceFolder}"]
    }
  }
}
```

Each machine exports `UVX_BIN` in `~/.profile` or `/etc/environment`. The committed `mcp.json`
is identical on every distro.

**Limitation:** If the env var is unset, VS Code receives an empty string and the server
fails silently with no graceful fallback inside the JSON.

**Pros for template repos:** `mcp.json` stays fully committed and unchanged.
**Cons:** Requires a documented per-machine export step; no auto-detection.

---

### Finding 2 — `envFile` for per-machine MCP server-scoped variables

**Status: production-ready**

The `envFile` field loads a dotenv file into the spawned MCP server process environment.
This file can be gitignored and machine-local:

```json
{
  "servers": {
    "git": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "${workspaceFolder}"],
      "envFile": "${workspaceFolder}/.mcp.env"
    }
  }
}
```

Commit `.mcp.env.example` with documentation; add `.mcp.env` to `.gitignore`.

**Critical distinction:** `envFile` variables flow into the server process environment only.
They cannot be referenced as `${env:FROM_ENVFILE}` in the `command` field of the same server
entry — variable substitution in `command`/`args` happens at VS Code startup before the
process spawns. To vary the command itself, use Finding 1 or Finding 3.

**Best use:** API keys, tokens, and flags that vary per machine.

---

### Finding 3 — Shell wrapper script as MCP command (zero setup for consumers)

**Status: production-ready — highest ROI for a template repo**

Commit a shell script that probes the system and dispatches to the right binary:

```json
{
  "servers": {
    "git": {
      "type": "stdio",
      "command": "${workspaceFolder}/.github/scripts/mcp-git.sh",
      "args": ["--repository", "${workspaceFolder}"]
    }
  }
}
```

```bash
#!/usr/bin/env bash
# .github/scripts/mcp-git.sh
set -euo pipefail

for candidate in "$HOME/.local/bin/uvx" "/usr/local/bin/uvx" "/usr/bin/uvx" \
    "$(command -v uvx 2>/dev/null || true)"; do
  [[ -x "$candidate" ]] && exec "$candidate" mcp-server-git "$@"
done

# Bazzite/immutable distro fallback
command -v flatpak &>/dev/null && \
  exec flatpak run --command=uvx io.github.flatpak.uv mcp-server-git "$@" 2>/dev/null || true

echo "ERROR: uvx not found. Install uv: https://docs.astral.sh/uv/getting-started/installation/" >&2
exit 1
```

**Pros:** Zero per-machine setup after clone; handles all three distro families; provides
clear error message with fix URL; testable locally.
**Cons:** Must be marked `chmod +x` in git; becomes a maintenance surface for new distros.

---

### Finding 4 — Hooks have first-class `linux`/`osx`/`windows` command fields

**Status: production-ready — but limited to Windows vs Linux vs macOS axis**

VS Code hook command objects support explicit per-OS command overrides at the schema level:

```json
{
  "hooks": {
    "PostToolUse": [{
      "type": "command",
      "command": "./scripts/format.sh",
      "linux": "./scripts/format-linux.sh",
      "osx": "./scripts/format-mac.sh",
      "windows": "powershell -File scripts\\format.ps1"
    }]
  }
}
```

**Critical limitation for cross-distro Linux:** Bazzite, Ubuntu, and Arch all map to `linux`.
There is one `linux` field for all three; distro detection must happen inside the script
itself via `/etc/os-release` parsing.

---

### Finding 5 — SessionStart hook injects live OS context into Copilot

**Status: production-ready**

The `SessionStart` hook fires once per chat session and returns `additionalContext` that
VS Code prepends to the Copilot conversation. This is the only mechanism to make
`copilot-instructions.md` OS-aware at runtime.

**Additive extension to the existing `session-start.sh`:**

```bash
OS_ID=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "unknown")
case "$OS_ID" in
  ubuntu|debian)  PKG_MGR="apt" ;;
  arch|manjaro)   PKG_MGR="pacman" ;;
  fedora)         PKG_MGR="dnf" ;;
  *)
    grep -qi "atomic\|bazzite\|silverblue" /etc/os-release 2>/dev/null \
      && PKG_MGR="rpm-ostree" || PKG_MGR="unknown"
    ;;
esac
UVX_PATH=$(command -v uvx 2>/dev/null || echo "not found")
NPX_PATH=$(command -v npx 2>/dev/null || echo "not found")
```

Emit as `hookSpecificOutput.additionalContext`. Every Copilot turn in that session will
use correct package manager syntax and binary paths in its suggestions.

**What this enables:** Answers to "install X" use `pacman` on Arch, `apt` on Ubuntu,
`rpm-ostree` on Bazzite; scripts it writes use the correct `uvx` path.
**What it does NOT do:** Cannot retroactively change `mcp.json` or `settings.json` at runtime.

---

### Finding 6 — `settings.json` has NO per-OS override syntax

**Status: confirmed capability gap**

Unlike `tasks.json` and `launch.json`, VS Code's workspace `settings.json` has no `linux`,
`osx`, or `windows` block mechanism. There is no language-filter equivalent for OS.

OS-differentiated options that DO work in `settings.json`:
- `terminal.integrated.profiles.linux` / `.osx` / `.windows` — per-platform terminal shell
- `terminal.integrated.defaultProfile.linux` etc.

Variable substitution (`${env:VAR}`) in `settings.json` is supported only in a small set of
terminal-related keys (`terminal.integrated.env.linux.PATH`, `cwd`, `shell`, `shellArgs`),
not in arbitrary settings values.

**Best workaround:** Workspace `.vscode/settings.json` contains only shared settings.
Machine-specific settings (Python interpreter path, tool paths) live in user
`~/.config/Code/User/settings.json`. Document required user settings in `SETUP.md` per distro.

---

### Finding 7 — VS Code Profiles provide machine-specific config isolation

**Status: production-ready but requires manual per-machine setup**

A VS Code Profile stores its own `settings.json`, extensions, MCP servers, snippets.
Profiles can be associated with a specific workspace folder — when the folder is opened,
that profile activates automatically.

Profile path: `~/.config/Code/User/profiles/<profile-id>/`

**Limitation for template repos:** Profile creation and workspace association cannot be
scripted or committed. It is a one-time manual VS Code UI action per machine. Not viable
as a primary zero-config delivery mechanism.

---

### Finding 8 — `tasks.json` and `launch.json` have per-OS override blocks

**Status: production-ready — Windows/Linux/macOS axis only**

`tasks.json` top-level schema (from `tasks-appendix`):
```json
{
  "version": "2.0.0",
  "linux":   { "options": { "env": { "KEY": "value" } } },
  "windows": { "command": "nmake" },
  "tasks": []
}
```

`launch.json` per-configuration:
```json
{
  "configurations": [{
    "type": "node", "name": "Start",
    "program": "${workspaceFolder}/app.js",
    "linux":   { "env": { "TOOL_PATH": "/usr/local/bin" } },
    "windows": { "env": { "TOOL_PATH": "C:\\tools" } }
  }]
}
```

Does not affect `mcp.json` or `settings.json`. All three Linux distros share
the `linux` field.

---

### Finding 9 — Copilot instruction files have no runtime OS detection

**Status: confirmed gap — by design**

`copilot-instructions.md`, `.github/agents/*.agent.md`, `.instructions.md` are static
Markdown. No template variables, environment interpolation, or conditional blocks are
processed. File content is sent to the model verbatim.

Three workarounds:
1. **SessionStart hook** `additionalContext` injection (Finding 5) — recommended.
2. **Instructions that prompt the model to ask** — e.g., "when suggesting install commands,
   confirm the OS if not already stated in context."
3. **Separate instruction files per distro** — impractical for a shared template.

---

### Finding 10 — MCP `chat.mcp.discovery.enabled` for config reuse from other tools

**Status: experimental (VS Code v1.110, Feb 2026)**

VS Code can auto-discover MCP configs from applications such as Claude Desktop. If another
tool already has the correct distro-specific binary paths configured, VS Code inherits them.
The `chat.mcp.discovery.enabled` setting controls which sources to discover from.

**Limitation:** Source application list is undocumented beyond Claude Desktop. Subject to
change while experimental. Not a reliable primary strategy.

---

## Approach Comparison Matrix

| Approach | Cross-distro Linux? | Zero per-machine setup? | Committed to repo? | Status |
|----------|--------------------|-----------------------|--------------------|--------|
| `${env:VAR}` in `mcp.json` | Yes (with convention) | No (set env vars) | JSON only | Production |
| `envFile` + gitignored `.mcp.env` | Yes (per-machine file) | No (copy + fill) | template only | Production |
| Shell wrapper script as MCP command | Yes (probe at runtime) | Yes | full script | Production |
| Hooks `linux`/`osx`/`windows` fields | No (all Linux same) | Yes | yes | Production |
| `SessionStart` OS context injection | Yes (AI context) | Yes | additive script | Production |
| VS Code Profiles | Yes (full isolation) | No (manual UI) | no | Production |
| `tasks.json`/`launch.json` per-OS | No (Windows/Linux/macOS) | Yes | yes | Production |
| `settings.json` per-OS syntax | N/A — does not exist | N/A | N/A | Gap |
| MCP auto-discovery | Partial | Yes (if other tool set up) | no | Experimental |

---

## Recommendations

### Rank 1 — Shell wrapper scripts for MCP binary resolution

Commit `.github/scripts/mcp-<name>.sh` per server requiring a local binary. The wrapper
probes `PATH` in order of common locations, then falls back to `flatpak run` for immutable
distros, then exits with a helpful error message. No per-machine setup required.

Point `mcp.json` at `"command": "${workspaceFolder}/.github/scripts/mcp-<name>.sh"`.
Ensure executable bit: `git update-index --chmod=+x .github/scripts/mcp-*.sh`.

### Rank 2 — `${env:VAR}` convention documented in SETUP.md

Provide a one-liner for each supported distro in `SETUP.md`. Advanced users can override
the wrapper by setting `UVX_BIN` / `NPX_BIN`. The wrapper reads these first, uses its own
probe order as fallback:

```bash
# In wrapper script top:
UVX=${UVX_BIN:-}
[[ -n "$UVX" && -x "$UVX" ]] && exec "$UVX" "$@"
# ...then probe order fallback
```

### Rank 3 — SessionStart hook OS injection

Extend the existing `session-start.sh` with OS/toolchain detection (~20 lines). Every
Copilot session automatically receives accurate OS context without touching static instruction
files. Additive, non-breaking change.

### Rank 4 — envFile for API tokens and secrets

Commit `.mcp.env.example` with documentation. Add `.mcp.env` to `.gitignore`. Installation
step: `cp .mcp.env.example .mcp.env && $EDITOR .mcp.env`. Handles keys that cannot be probed.

### Not recommended as primary — VS Code Profiles

Document as an optional power-user enhancement. Not suitable as the default delivery
mechanism because it cannot be scripted or committed.

---

## Gaps / Further Research Needed

1. **Bazzite Flatpak Node.js invocation path** — the exact `flatpak run` command for `npx`
   on Bazzite requires empirical testing on a live Bazzite install.

2. **`settings.json` per-OS feature request** — search `microsoft/vscode` issues for
   `label:feature-request "platform-specific settings"` to find current status and vote count.

3. **MCP sandbox + wrapper script permissions** — when `sandboxEnabled: true`, verify that
   `sandbox.filesystem` must grant read access to `.github/scripts/` for the wrapper to run.

4. **`chat.mcp.discovery.enabled` full source list** — which application configs VS Code can
   discover beyond Claude Desktop is not fully documented as of 2026-03-30.
