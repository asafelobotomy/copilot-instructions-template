---
name: Terminal Discipline
applyTo: "**/*.sh,**/*.bash,**/*.zsh,**/*.ps1"
description: "Terminal session safety — shell isolation, strict-mode wrappers, variable naming, and output management"
---

# Terminal Discipline

- For high-volume commands, capture the full output to a log file and print only a bounded tail instead of streaming everything.
- If the repo documents a terminal-safe wrapper for a noisy command, prefer it over the raw command when using terminal tools.
- Prefer repo scripts or bash wrappers over ad hoc shell control flow when a command needs exit-status plumbing, redirection, or retries.
- A single existing command with no shell control flow, tempfile plumbing, redirection, or shell-specific syntax may run directly in the terminal.
- If the repo provides a generic isolated-shell wrapper, use it for ad hoc one-liners or multi-step snippets instead of relying on the persistent terminal's current shell state.
- If the repo provides a stdin or here-doc isolated-shell wrapper, use it for multi-line snippets and shell-specific syntax.
- Never run `set -euo pipefail` or `setopt errexit nounset pipefail` as a standalone terminal command in the persistent zsh session. Shell integration hooks can inherit that global state and terminate the session on the next prompt cycle.
- For ad hoc strict-mode one-liners, prefer a repo wrapper if one exists. Otherwise run the snippet through a child Bash process with strict mode enabled instead of mutating the parent zsh session.
- For multi-line strict-mode snippets, prefer a dedicated stdin or here-doc wrapper when the repo provides one. Otherwise run the snippet through a child Bash process with strict mode enabled instead of mutating the parent zsh session.
- Use shell-specific child wrappers for zsh, `sh`, or PowerShell syntax instead of assuming the persistent terminal is already in the right shell.
- `get_terminal_output` and `send_to_terminal` accept two distinct selectors: use `id` for the opaque UUID returned by `run_in_terminal` async mode, and use `terminalId` for a numeric foreground terminal instance that is already visible in the terminal panel. Never pass one selector type where the other is required.
- `kill_terminal` accepts only the opaque UUID returned by `run_in_terminal` async mode. It cannot target foreground or user-created terminals by numeric `terminalId`.
- Do not pass shell names, terminal labels, or `execution_subagent` results to terminal-session tools. Only async UUIDs and foreground numeric `terminalId` values are valid selectors.
- Use `terminal_last_command` and `terminal_selection` only for the currently active editor terminal. They do not read or control `run_in_terminal` async sessions.
- For interactive terminal input, send one answer at a time with `send_to_terminal`, then read the next prompt with `get_terminal_output` before sending more input. If it is unclear whether the terminal is waiting for input, focus the terminal or use the question flow rather than sending blind input.
- If you only need command output rather than a persistent background session, prefer a synchronous terminal run or `execution_subagent` over polling a background terminal.
- Reuse async terminals only for genuinely interactive or persistent sessions, and call `kill_terminal` when that session is no longer needed.
- Background terminal notifications are enabled by default. Do not add `sleep` loops or blind polling around background terminals; inspect output only when a notification or workflow event gives a concrete reason to do so.
- For standard build or run workflows, prefer repo scripts or `create_and_run_task`. Reserve async terminal sessions for cases that truly need a persistent interactive shell.
- In zsh workspaces, avoid reserved variable names such as `status`; use `rc`, `exit_code`, or `command_rc` instead.
- Do not rely on profile files, aliases, or exported shell options for ad hoc snippets. Child wrappers should start from a clean shell state.
- If a failure is caused by shell semantics rather than the underlying command, stop retrying equivalent one-liners and switch to a repo script or simpler direct invocation.
- Terminal command auto-approval rules use best-effort parsing and have known gaps around aliases, quote concatenation, and complex shell syntax. Do not treat auto-approval as a security guarantee for complex invocations.
- When `chat.tools.terminal.sandbox.enabled` is active on macOS, Linux, or WSL2, terminal commands run with write access limited to the current working directory and outbound network blocked by default. Child processes inherit the same restrictions; commands that need broader access should prompt to run outside the sandbox.
- Linux terminal sandboxing requires `bubblewrap` and `socat`. WSL1 is not supported; use WSL2 or a dev container instead.
- Before declaring GitHub CLI auth missing or broken, run `gh auth status` explicitly. A failed `gh issue`, `gh pr`, or `gh release` command is not enough evidence by itself.
- If `get_terminal_output` returns a "command not found" error, the call used an invalid terminal ID (an integer panel ID or a subagent result instead of an async UUID). Discard the result, do not retry with the same ID, and re-run the command using `execution_subagent` or synchronous `run_in_terminal`.
- The VS Code sandbox injects a restricted PATH. Tools present in the user's interactive shell (e.g. `python`, `actionlint`, `shellcheck`) may be absent. Probe with `command -v <tool>` before invoking, or use `execution_subagent` which handles sandbox PATH transparently.
