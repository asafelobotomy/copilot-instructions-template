echo "6. Task completion and testing policy distinguish targeted vs full-suite gates"
assert_python "instruction files define phase testing vs final completion semantics" '
required_by_file = {
    ".github/copilot-instructions.md": [
        "use deterministic targeted suites during intermediate phases; run `bash tests/run-all.sh` only when the selector or blast radius indicates a full-suite gate is warranted for broad or high-risk work",
        "During intermediate phases or multi-part tasks, run the narrowest deterministic targeted suites",
        "Run `bash tests/run-all.sh` only when the selector emits `run_full_suite_at_completion: true` or `should_run_full_suite_early: true`",
        "### Test Scope Policy",
        "**Task complete** means the full user-visible task is finished end-to-end",
        "During intermediate phases, prefer deterministic path-based targeted suites",
        "If multiple sub-parts are still in progress, do not treat a passing targeted subset as permission to declare the whole task complete",
        "Broaden early when changes touch shared helpers, broad policy surfaces, parity mirrors, or any area without a reliable targeted test mapping",
        "Keep intermediate verification under roughly 10 seconds when the targeted mapping allows",
        "Re-run the full suite during active work only if a targeted failure required a fix",
        "Never run the full suite repeatedly between intermediate steps just to be safe",
        "Final gate: before marking the full task complete, run the full suite only when the selector emits `run_full_suite_at_completion: true` or `should_run_full_suite_early: true`",
        "**Risk-based early escalation**: when the selector emits `should_run_full_suite_early: true`, run the full suite immediately",
    ],
    "template/copilot-instructions.md": [
        "use deterministic targeted suites during intermediate phases when available; run `{{TEST_COMMAND}}` only when the selector or blast radius indicates a full-suite gate is warranted for broad or high-risk work",
        "Three-check ritual before marking a full task complete end-to-end",
        "Must pass before the full task is done",
        "During intermediate phases or multi-part tasks, run the narrowest deterministic targeted suites",
        "Run `{{TEST_COMMAND}}` only when the selector emits `run_full_suite_at_completion: true` or `should_run_full_suite_early: true`",
        "### Test Scope Policy",
        "**Task complete** means the full user-visible task is finished end-to-end",
        "During intermediate phases, prefer deterministic path-based targeted suites",
        "If the repo documents a targeted-test selector or phase-test command, use it to choose deterministic phase checks from changed paths",
        "If multiple sub-parts are still in progress, do not treat a passing targeted subset as permission to declare the whole task complete",
        "Broaden early when changes touch shared helpers, broad policy surfaces, parity mirrors, or any area without a reliable targeted test mapping",
        "Keep intermediate verification under roughly 10 seconds when the targeted mapping allows",
        "Re-run the full suite during active work only if a targeted failure required a fix",
        "Never run the full suite repeatedly between intermediate steps just to be safe",
        "Final gate: before marking the full task complete, run the full suite only when the selector emits `run_full_suite_at_completion: true` or `should_run_full_suite_early: true`",
        "**Risk-based early escalation**: when the selector emits `should_run_full_suite_early: true`, run the full suite immediately",
    ],
}
for rel, needles in required_by_file.items():
    text = " ".join((root / rel).read_text(encoding="utf-8").split()).lower()
    for needle in needles:
        if " ".join(needle.split()).lower() not in text:
            raise SystemExit(rel + " missing testing policy guidance: " + needle)
'
echo ""

echo "7. Developer instructions expose the targeted test selector command"
assert_python "developer instructions mention the targeted test selector" '
text = " ".join((root / ".github/copilot-instructions.md").read_text(encoding="utf-8").split())
required = [
    "Select targeted tests",
    "bash scripts/harness/select-targeted-tests.sh <paths...>",
    "Use `bash scripts/harness/select-targeted-tests.sh <paths...>` to choose deterministic phase checks from changed paths",
]
for needle in required:
    if " ".join(needle.split()) not in text:
        raise SystemExit(".github/copilot-instructions.md missing selector guidance: " + needle)
'
echo ""

echo "8. Instruction files encode terminal discipline for truncation and zsh shells"
assert_python "instruction files include terminal discipline guidance" '
# Terminal discipline is extracted to instruction files (terminal.instructions.md).
# Main files must reference the instruction file; instruction files carry the detail.
for main_file in (".github/copilot-instructions.md", "template/copilot-instructions.md"):
    text = (root / main_file).read_text(encoding="utf-8")
    if "terminal.instructions.md" not in text:
        raise SystemExit(main_file + " must reference terminal.instructions.md")

# The instruction files carry the detailed terminal guidance
required_dev = [
    "For high-volume commands, capture the full output to a log file and print only a bounded tail",
    "Prefer repo scripts or bash wrappers over ad hoc shell control flow",
    "single existing command with no shell control flow",
    "generic isolated-shell wrapper",
    "stdin or here-doc isolated-shell wrapper",
    "Never run `set -euo pipefail` or `setopt errexit nounset pipefail` as a standalone terminal command",
    "prefer a repo wrapper if one exists",
    "prefer a dedicated stdin or here-doc wrapper when the repo provides one",
    "run the snippet through a child Bash process with strict mode enabled",
    "`get_terminal_output` and `send_to_terminal` accept two distinct selectors",
    "`kill_terminal` accepts only the opaque UUID returned by `run_in_terminal` async mode",
    "Do not pass shell names, terminal labels, or `execution_subagent` results",
    "Use `terminal_last_command` and `terminal_selection` only for the currently active editor terminal",
    "For interactive terminal input, send one answer at a time with `send_to_terminal`",
    "prefer a synchronous terminal run or `execution_subagent` over polling a background terminal",
    "call `kill_terminal` when that session is no longer needed",
    "Background terminal notifications are enabled by default",
    "prefer repo scripts or `create_and_run_task`",
    "avoid reserved variable names such as `status`",
    "Do not rely on profile files, aliases, or exported shell options",
    "stop retrying equivalent one-liners and switch to a repo script or simpler direct invocation",
    "Terminal command auto-approval rules use best-effort parsing",
    "When `chat.tools.terminal.sandbox.enabled` is active on macOS, Linux, or WSL2",
    "Linux terminal sandboxing requires `bubblewrap` and `socat`",
    "Before declaring GitHub CLI auth missing or broken, run `gh auth status` explicitly",
]
required_tpl = [
    "For high-volume commands, capture the full output to a log file and print only a bounded tail instead of streaming everything",
    "Prefer repo scripts or bash wrappers over ad hoc shell control flow",
    "single existing command with no shell control flow",
    "generic isolated-shell wrapper",
    "stdin or here-doc isolated-shell wrapper",
    "Never run `set -euo pipefail` or `setopt errexit nounset pipefail` as a standalone terminal command",
    "prefer a repo wrapper if one exists",
    "prefer a dedicated stdin or here-doc wrapper when the repo provides one",
    "run the snippet through a child Bash process with strict mode enabled",
    "`get_terminal_output` and `send_to_terminal` accept two distinct selectors",
    "`kill_terminal` accepts only the opaque UUID returned by `run_in_terminal` async mode",
    "Do not pass shell names, terminal labels, or `execution_subagent` results",
    "Use `terminal_last_command` and `terminal_selection` only for the currently active editor terminal",
    "For interactive terminal input, send one answer at a time with `send_to_terminal`",
    "prefer a synchronous terminal run or `execution_subagent` over polling a background terminal",
    "call `kill_terminal` when that session is no longer needed",
    "Background terminal notifications are enabled by default",
    "prefer repo scripts or `create_and_run_task`",
    "avoid reserved variable names such as `status`",
    "Do not rely on profile files, aliases, or exported shell options",
    "stop retrying equivalent one-liners and switch to a repo script or simpler direct invocation",
    "Terminal command auto-approval rules use best-effort parsing",
    "When `chat.tools.terminal.sandbox.enabled` is active on macOS, Linux, or WSL2",
    "Linux terminal sandboxing requires `bubblewrap` and `socat`",
    "Before declaring GitHub CLI auth missing or broken, run `gh auth status` explicitly",
]

for path_rel, needles in [
    (".github/instructions/terminal.instructions.md", required_dev),
    ("template/instructions/terminal.instructions.md", required_tpl),
]:
    text = " ".join((root / path_rel).read_text(encoding="utf-8").split())
    for needle in needles:
        if " ".join(needle.split()) not in text:
            raise SystemExit(path_rel + " missing terminal discipline guidance: " + needle)

# Dev instructions still references run-all-captured
dev_text = (root / ".github/copilot-instructions.md").read_text(encoding="utf-8")
if "Run all tests (captured)" not in dev_text:
    raise SystemExit(".github/copilot-instructions.md still needs Run all tests (captured) in Key Commands")
if "bash scripts/harness/run-all-captured.sh" not in dev_text:
    raise SystemExit(".github/copilot-instructions.md still needs run-all-captured.sh in Key Commands")

readme_text = " ".join((root / "README.md").read_text(encoding="utf-8").split())
for needle in [
    "For terminal-session tools, use the right selector: `id` is the opaque UUID returned by `run_in_terminal` async mode, while `terminalId` is the numeric instanceId for a terminal already visible in the terminal panel.",
    "`get_terminal_output` and `send_to_terminal` can use either selector in the correct parameter; `kill_terminal` only accepts the async `id` UUID.",
    "Use `terminal_last_command` and `terminal_selection` only for the currently active editor terminal.",
    "prefer `execution_subagent` or a synchronous terminal run over creating a background terminal just to poll it.",
    "call `kill_terminal` when the session is no longer needed.",
    "Background terminal notifications are enabled by default, so do not add `sleep` loops or blind polling around background terminals.",
    "prefer repo scripts or `create_and_run_task` instead of a persistent interactive shell.",
    "For interactive terminal prompts, send one answer at a time with `send_to_terminal`",
]:
    if " ".join(needle.split()) not in readme_text:
        raise SystemExit("README.md missing async terminal guidance: " + needle)

# Deleted strict wrapper paths must not appear
for rel in (".github/copilot-instructions.md", "template/copilot-instructions.md"):
    txt = (root / rel).read_text(encoding="utf-8")
    for deleted in ("scripts/harness/run-strict-bash.sh", "scripts/harness/run-strict-bash-stdin.sh"):
        if deleted in txt:
            raise SystemExit(rel + " must not reference deleted strict wrapper: " + deleted)

# Agent/prompt/instruction files must not suggest zsh strict-mode mutation
# (terminal instruction files are excluded — they warn AGAINST it)
search_roots = [
    root / "agents",
    root / ".github/prompts",
    root / "template/prompts",
]
for search_root in search_roots:
    for path in search_root.rglob("*.md"):
        text = path.read_text(encoding="utf-8")
        if "setopt errexit nounset pipefail" in text:
            raise SystemExit(str(path.relative_to(root)) + " must not suggest top-level zsh strict-mode mutation")
# Non-terminal instruction files also checked
for instr_root in (root / ".github/instructions", root / "template/instructions"):
    for path in instr_root.rglob("*.md"):
        if path.name == "terminal.instructions.md":
            continue  # this file warns AGAINST it
        text = path.read_text(encoding="utf-8")
        if "setopt errexit nounset pipefail" in text:
            raise SystemExit(str(path.relative_to(root)) + " must not suggest top-level zsh strict-mode mutation")
'
echo ""

echo "9. Agent and prompt surfaces avoid top-level zsh strict-mode mutation guidance"
assert_python "prompt and agent surfaces avoid raw zsh strict-mode mutation" '
search_roots = [
    root / "agents",
    root / ".github/prompts",
    root / "template/prompts",
]
for search_root in search_roots:
    for path in search_root.rglob("*.md"):
        text = path.read_text(encoding="utf-8")
        if "setopt errexit nounset pipefail" in text:
            raise SystemExit(str(path.relative_to(root)) + " must not suggest top-level zsh strict-mode mutation")
# Instruction files checked separately — terminal.instructions.md warns AGAINST it
for instr_root in (root / ".github/instructions", root / "template/instructions"):
    for path in instr_root.rglob("*.md"):
        if path.name == "terminal.instructions.md":
            continue
        text = path.read_text(encoding="utf-8")
        if "setopt errexit nounset pipefail" in text:
            raise SystemExit(str(path.relative_to(root)) + " must not suggest top-level zsh strict-mode mutation")
'
echo ""

echo "10. Consumer template has no duplicated hook or MCP guidance"
assert_python "template instructions avoid duplicated or malformed protocol text" '
text = (root / "template/copilot-instructions.md").read_text(encoding="utf-8")
if "rejected.ation" in text:
    raise SystemExit("template/copilot-instructions.md contains malformed MCP troubleshooting text")

counts = {
    "Agent-scoped hooks: individual agents can define a `hooks:` section in their `.agent.md` YAML frontmatter.": 1,
    "- **Sandbox stdio servers**: set `\"sandboxEnabled\": true` in `mcp.json` for locally-running `npx`-based stdio servers (macOS/Linux). Do not sandbox `uvx`-based servers — the VS Code sandbox proxy intercepts PyPI network access during the launcher phase and triggers repeated domain-approval prompts. The M4 audit check enforces this by exempting `command == \"uvx\"` servers automatically. Sandboxed servers auto-approve tool calls.": 1,
    "- The MCP `memory` server has been removed — VS Code\x27s built-in memory tool (`/memories/`) provides superior persistent storage with three scopes (user, session, repository)": 1,
    "- Never hardcode secrets — use `${input:}` or `${env:}` variable syntax": 1,
    "- **Monorepo discovery**: enable `chat.useCustomizationsInParentRepositories` to auto-discover instructions, prompts, agents, skills, and hooks from a parent Git repository root when opening a subfolder. Requires the parent folder to be trusted.": 1,
    "- **Troubleshooting**: if customizations fail to load, select the ellipsis (…) menu in the Chat view → *Show Agent Debug Logs* to diagnose which files were discovered and which were rejected.": 1,
}

for snippet, expected in counts.items():
    actual = text.count(snippet)
    if actual != expected:
        raise SystemExit(f"template/copilot-instructions.md expected {expected} occurrence(s) of {snippet!r}, found {actual}")
'
echo ""

