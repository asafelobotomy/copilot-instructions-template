#!/usr/bin/env bash
# tests/contracts/test-customization-contracts-policies.sh -- commit, inventory, and allow-list contract checks.
# Run: bash tests/contracts/test-customization-contracts-policies.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

echo "=== Customization policy contract checks ==="
echo ""

echo "1. Commit agent integrates preflight and install confirmation"
assert_python "commit agent has preflight workflow and askQuestions support" '
path = root / ".github/agents/commit.agent.md"
text = path.read_text(encoding="utf-8")
if not text.startswith("---\n"):
    raise SystemExit("missing frontmatter in commit.agent.md")
end = text.find("\n---\n", 4)
if end == -1:
    raise SystemExit("unterminated frontmatter in commit.agent.md")
fm = text[4:end]
tools_match = re.search(r"^tools:\s*\[(.*)\]\s*$", fm, re.M)
if not tools_match:
    raise SystemExit("commit.agent.md missing tools line")
tools = {
    item.strip().replace(chr(39), "").replace(chr(34), "")
    for item in tools_match.group(1).split(",")
    if item.strip()
}
if "askQuestions" not in tools:
    raise SystemExit("commit.agent.md missing askQuestions tool")
if "Audit" not in text:
    raise SystemExit("commit.agent.md missing Audit delegation path")
required = [
    "## Preflight workflow",
    "Activate the `commit-preflight` skill",
    "ask_questions` for ALL user-facing decisions",
    "Do NOT install dependencies silently",
    "Use `Audit` when the user requests a deeper security or health check before",
    "## Skill activation map",
]
for needle in required:
    if needle not in text:
        raise SystemExit("commit.agent.md missing expected preflight directive: " + needle)
'
echo ""

echo "2. Fast agent keeps exact-match search for quick lookups"
assert_python "fast agent includes search tool and research escalation" '
path = root / ".github/agents/fast.agent.md"
text = path.read_text(encoding="utf-8")
if not text.startswith("---\n"):
    raise SystemExit("missing frontmatter in fast.agent.md")
end = text.find("\n---\n", 4)
if end == -1:
    raise SystemExit("unterminated frontmatter in fast.agent.md")
fm = text[4:end]
tools_match = re.search(r"^tools:\s*\[(.*)\]\s*$", fm, re.M)
if not tools_match:
    raise SystemExit("fast.agent.md missing tools line")
tools = {
    item.strip().replace(chr(39), "").replace(chr(34), "")
    for item in tools_match.group(1).split(",")
    if item.strip()
}
if "search" not in tools:
    raise SystemExit("fast.agent.md missing search tool")
if "Researcher" not in text:
    raise SystemExit("fast.agent.md missing Researcher delegation path")
if "Use `search` for fast exact-match or regex lookups" not in text:
    raise SystemExit("fast.agent.md missing search guidance")
if "If the answer depends on current external documentation or version-specific" not in text:
    raise SystemExit("fast.agent.md missing Researcher escalation guidance")
'
echo ""

echo "3. Repo and consumer workspace indices stay aligned"
assert_python "workspace-index repo and template copies match" '
repo_path = root / ".copilot/workspace/workspace-index.json"
template_path = root / "template/workspace/workspace-index.json"
repo_data = json.load(repo_path.open(encoding="utf-8"))
template_data = json.load(template_path.open(encoding="utf-8"))
repo_data["updated"] = "IGNORED"
template_data["updated"] = "IGNORED"
if repo_data != template_data:
    raise SystemExit("repo and template workspace-index.json diverged")
if "commit-preflight" not in repo_data["skills"]["repo"]:
    raise SystemExit("workspace-index repo skills missing commit-preflight")
if "commit-preflight" not in template_data["skills"]["template"]:
    raise SystemExit("workspace-index template skills missing commit-preflight")
'
echo ""

echo "4. Main/default agent instructions require specialist-first delegation"
assert_python "top-level instruction files encode the delegation policy" '
required_by_file = {
    ".github/copilot-instructions.md": [
        "Main/default agent delegation:",
        "delegate instead of absorbing",
        "Preferred specialist map:",
        "`Explore` for read-only repo scans",
        "`Researcher` for current external docs",
        "`Review` for formal code review or architectural critique",
        "`Audit` for health, security, or residual-risk checks",
        "`Extensions` for VS Code extension, profile, or workspace recommendation",
        "`Commit` for staging, commits, pushes, tags, or releases",
        "`Setup` for template bootstrap, instruction update, backup restore, or factory restore",
        "`Organise` for file moves, path repair, or repository reshaping",
    ],
    "template/copilot-instructions.md": [
        "The parent/default agent follows this protocol too:",
        "delegate to the matching agent instead of absorbing",
        "Preferred specialist map:",
        "`Explore` for read-only repo scans",
        "`Researcher` for current external docs",
        "`Review` for formal code review or architectural critique",
        "`Audit` for health, security, or residual-risk checks",
        "`Extensions` for VS Code extension, profile, or workspace recommendation",
        "`Commit` for staging, commits, pushes, tags, or releases",
        "`Setup` for template bootstrap, instruction update, backup restore, or factory restore",
        "`Organise` for file moves, path repair, or repository reshaping",
    ],
    "AGENTS.md": [
        "The main/default agent follows the same specialist-first rule:",
        "delegate instead of handling the specialist workflow inline.",
    ],
}
for rel, needles in required_by_file.items():
    text = " ".join((root / rel).read_text(encoding="utf-8").split())
    for needle in needles:
        if " ".join(needle.split()) not in text:
            raise SystemExit(rel + " missing delegation guidance: " + needle)
'
echo ""

echo "5. Setup lifecycle entry surfaces point to canonical protocol sources"
assert_python "setup and agent entry files point to the canonical protocol docs" '
checks = {
    "AGENTS.md": [
        "## Canonical protocol sources",
        "[SETUP.md](SETUP.md)",
        "[UPDATE.md](UPDATE.md)",
        "https://github.com/asafelobotomy/copilot-instructions-template/blob/main/template/setup/manifests.md#protocol-sources",
    ],
    ".github/agents/setup.agent.md": [
        "## Canonical protocol sources",
        "[SETUP.md](SETUP.md)",
        "[UPDATE.md](UPDATE.md)",
        "https://github.com/asafelobotomy/copilot-instructions-template/blob/main/template/setup/manifests.md#protocol-sources",
        "[AGENTS.md](AGENTS.md)",
    ],
    "template/setup/manifests.md": [
        "## Protocol sources",
        "| Setup |",
        "| Update, backup restore, and factory restore |",
        "`SETUP.md`",
        "`UPDATE.md`",
    ],
}
for rel, needles in checks.items():
    text = (root / rel).read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            raise SystemExit(rel + " missing protocol source pointer: " + needle)

agents_text = (root / "AGENTS.md").read_text(encoding="utf-8")
if "## Remote Bootstrap Sequence" in agents_text:
    raise SystemExit("AGENTS.md still duplicates the remote bootstrap sequence")
if "## Remote Update Sequence" in agents_text:
    raise SystemExit("AGENTS.md still duplicates the remote update sequence")
for phrase in [
    "Setup from asafelobotomy/copilot-instructions-template",
    "Update your instructions",
    "Restore instructions from backup",
    "Factory restore instructions",
]:
    if agents_text.count(phrase) != 1:
        raise SystemExit("AGENTS.md duplicates trigger phrase: " + phrase)

setup_agent_text = (root / ".github/agents/setup.agent.md").read_text(encoding="utf-8")
if "### Pre-flight URLs" in setup_agent_text:
    raise SystemExit("setup.agent.md still duplicates the pre-flight URL list")
if "### Trigger phrases (update mode)" in setup_agent_text:
    raise SystemExit("setup.agent.md still duplicates the update trigger phrase list")
for rel in ("AGENTS.md", ".github/agents/setup.agent.md"):
    text = (root / rel).read_text(encoding="utf-8")
    if "[template/setup/manifests.md](template/setup/manifests.md#protocol-sources)" in text:
        raise SystemExit(rel + " still points consumers at a non-installed local manifests path")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "6. Task completion and testing policy distinguish targeted vs full-suite gates"
assert_python "instruction files define phase testing vs final completion semantics" '
required_by_file = {
    ".github/copilot-instructions.md": [
        "use deterministic targeted suites during intermediate phases; run `bash tests/run-all.sh` before marking a full task done end-to-end",
        "During intermediate phases or multi-part tasks, run the narrowest deterministic targeted suites",
        "Run `bash tests/run-all.sh` only before marking the full user task complete end-to-end",
        "### Test Scope Policy",
        "**Task complete** means the full user-visible task is finished end-to-end",
        "During intermediate phases, prefer deterministic path-based targeted suites",
        "If multiple sub-parts are still in progress, do not treat a passing targeted subset as permission to declare the whole task complete",
        "Broaden early when changes touch shared helpers, broad policy surfaces, parity mirrors, or any area without a reliable targeted test mapping",
        "Final gate: before marking the full task complete, run the full suite with `bash tests/run-all.sh`",
    ],
    "template/copilot-instructions.md": [
        "use deterministic targeted suites during intermediate phases when available; run `{{TEST_COMMAND}}` before marking a full task done end-to-end",
        "Three-check ritual before marking a full task complete end-to-end",
        "Must pass before the full task is done",
        "During intermediate phases or multi-part tasks, run the narrowest deterministic targeted suites",
        "Run `{{TEST_COMMAND}}` only before marking the full user task complete end-to-end",
        "### Test Scope Policy",
        "**Task complete** means the full user-visible task is finished end-to-end",
        "During intermediate phases, prefer deterministic path-based targeted suites",
        "If the repo documents a targeted-test selector or phase-test command, use it to choose deterministic phase checks from changed paths",
        "If multiple sub-parts are still in progress, do not treat a passing targeted subset as permission to declare the whole task complete",
        "Broaden early when changes touch shared helpers, broad policy surfaces, parity mirrors, or any area without a reliable targeted test mapping",
        "Final gate: before marking the full task complete, run the full suite with `{{TEST_COMMAND}}`",
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
    "bash scripts/tests/select-targeted-tests.sh <paths...>",
    "Use `bash scripts/tests/select-targeted-tests.sh <paths...>` to choose deterministic phase checks from changed paths",
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
    "avoid reserved variable names such as `status`",
    "Do not rely on profile files, aliases, or exported shell options",
    "stop retrying equivalent one-liners and switch to a repo script or simpler direct invocation",
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
    "avoid reserved variable names such as `status`",
    "Do not rely on profile files, aliases, or exported shell options",
    "stop retrying equivalent one-liners and switch to a repo script or simpler direct invocation",
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
if "bash scripts/tests/run-all-captured.sh" not in dev_text:
    raise SystemExit(".github/copilot-instructions.md still needs run-all-captured.sh in Key Commands")

# Deleted strict wrapper paths must not appear
for rel in (".github/copilot-instructions.md", "template/copilot-instructions.md"):
    txt = (root / rel).read_text(encoding="utf-8")
    for deleted in ("scripts/tests/run-strict-bash.sh", "scripts/tests/run-strict-bash-stdin.sh"):
        if deleted in txt:
            raise SystemExit(rel + " must not reference deleted strict wrapper: " + deleted)

# Agent/prompt/instruction files must not suggest zsh strict-mode mutation
# (terminal instruction files are excluded — they warn AGAINST it)
search_roots = [
    root / ".github/agents",
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
    root / ".github/agents",
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
    "- **Sandbox stdio servers**: set `\"sandboxEnabled\": true` in `mcp.json` for locally-running stdio servers to restrict filesystem and network access (macOS/Linux). Sandboxed servers auto-approve tool calls.": 1,
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

echo "11. Agent allow-lists stay minimal and workflow-aligned"
assert_python "agent allow-lists match documented delegation policy" '
def parse_tools_or_agents(frontmatter, field):
    match = re.search(rf"^{field}:\s*\[(.*)\]\s*$", frontmatter, re.M)
    if not match:
        raise SystemExit(f"missing {field}: line")
    return {
        item.strip().replace(chr(39), "").replace(chr(34), "")
        for item in match.group(1).split(",")
        if item.strip()
    }

expected = {
    "audit.agent.md": {"Code", "Setup", "Researcher", "Extensions", "Organise"},
    "coding.agent.md": {"Review", "Audit", "Researcher", "Explore", "Extensions", "Commit", "Setup", "Organise", "Planner", "Docs", "Debugger"},
    "commit.agent.md": {"Code", "Review", "Audit"},
    "debugger.agent.md": {"Code", "Researcher", "Audit"},
    "docs.agent.md": {"Code", "Researcher", "Review"},
    "explore.agent.md": {"Researcher"},
    "extensions.agent.md": {"Code", "Audit", "Organise"},
    "fast.agent.md": {"Code", "Review", "Audit", "Explore", "Researcher", "Extensions", "Commit", "Setup", "Organise", "Planner", "Docs", "Debugger"},
    "organise.agent.md": {"Code", "Explore"},
    "planner.agent.md": {"Code", "Explore", "Researcher"},
    "researcher.agent.md": {"Code", "Audit", "Explore"},
    "review.agent.md": {"Code", "Audit", "Organise", "Docs", "Debugger"},
    "setup.agent.md": {"Audit", "Extensions", "Organise"},
}

for name, expected_agents in expected.items():
    path = root / ".github/agents" / name
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit("missing frontmatter in " + name)
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit("unterminated frontmatter in " + name)
    fm = text[4:end]
    found_agents = parse_tools_or_agents(fm, "agents")
    if found_agents != expected_agents:
        raise SystemExit(f"{name} expected agents={sorted(expected_agents)} found={sorted(found_agents)}")

checks = {
    "audit.agent.md": ["Use `Extensions` when a finding is specifically about VS Code extension"],
    "coding.agent.md": [
        "Use `Planner` when the request is large, ambiguous, or needs a scoped execution plan before implementation.",
        "Use `Debugger` when the main task is to diagnose a failure, regression, or unclear root cause before editing.",
        "Use `Docs` when the work is primarily documentation, migration guidance, or user-facing technical explanation rather than product behavior.",
        "Use `Explore` for read-only codebase inventory across multiple files",
        "Use `Researcher` when a task depends on current external documentation",
        "Use `Extensions` when the work shifts into VS Code extension recommendations",
        "Use `Setup` when the task turns into template bootstrap, instruction update,",
    ],
    "commit.agent.md": [
        "Use `Code` when preflight or review finds implementation work",
        "Use `Audit` when the user requests a deeper security or health check",
    ],
    "debugger.agent.md": [
        "Focus on reproduction, symptom isolation, root cause, and the smallest credible fix path.",
        "Use `Researcher` when the failure depends on current external docs, release notes, or API behavior.",
        "Use `Code` only after the diagnosis is specific enough to implement without guessing.",
    ],
    "docs.agent.md": [
        "Prefer documentation files, guides, prompts, instructions, and user-facing examples over code changes.",
        "Use `Researcher` when the docs depend on current external references or upstream behavior.",
        "Do not silently change runtime behavior while doing docs-only work.",
    ],
    "fast.agent.md": [
        "If the user is asking for a formal code review or architectural critique, use",
        "If the user is mainly asking for task decomposition, phased planning, or scope control, use `Planner`.",
        "If the user is primarily debugging a failure or regression, use `Debugger`.",
        "If the task is really documentation generation, migration notes, or guide writing, use `Docs`.",
        "If the user is asking for a health check, security audit, or vulnerability",
        "If the question expands beyond a single file but stays read-only, use",
        "If the answer depends on current external documentation or version-specific",
        "If the user is asking to stage, commit, push, tag, or release changes, use",
        "If the task is really VS Code extension, profile, or workspace recommendation",
        "If the task is really template setup, instruction update, backup restore, or factory restore",
        "If the task is primarily moving files, fixing broken paths, or reorganising",
    ],
    "organise.agent.md": [
        "Use `Code` when the task expands from structural cleanup into semantic",
    ],
    "planner.agent.md": [
        "Stay read-only. Do not modify files.",
        "Use `Explore` when the task needs a broader read-only inventory before the plan is credible.",
        "Use `Researcher` when the plan depends on current external docs or version-specific behavior.",
    ],
    "researcher.agent.md": [
        "Use `Explore` when you need a broader read-only inventory of local callers,",
    ],
    "review.agent.md": [
        "Use `Debugger` when a finding cannot be substantiated without isolating the underlying root cause first.",
        "Use `Docs` when the review outcome is primarily missing documentation, migration guidance, or user-facing explanation.",
    ],
    "setup.agent.md": [
        "Use `Extensions` when setup or update work shifts into VS Code extension",
    ],
}
for name, needles in checks.items():
    text = (root / ".github/agents" / name).read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            raise SystemExit(name + " missing workflow guidance: " + needle)
'
echo ""

echo "11. Hidden specialist agents are not advertised in the public trigger table"
assert_python "AGENTS.md keeps delegation-first specialists out of direct trigger docs" '
text = (root / "AGENTS.md").read_text(encoding="utf-8")
normalized = " ".join(text.split())
required = [
    "direct consumer-facing trigger phrases",
    "Audit, Researcher, Extensions, and Organise",
    "hidden from direct invocation",
]
for needle in required:
    if " ".join(needle.split()) not in normalized:
        raise SystemExit("AGENTS.md missing hidden-agent note: " + needle)
for forbidden in [
    "| Health check |",
    "| Extensions (review/install/profile) |",
    "| Research (find/report/track) |",
    "| Security audit |",
]:
    if forbidden in text:
        raise SystemExit("AGENTS.md still advertises hidden specialist trigger row: " + forbidden)
'
echo ""

echo "12. Lightweight AI entry surfaces point to canonical sources"
assert_python "CLAUDE.md and llms.txt stay lean and point to the canonical sources" '
claude_text = (root / "CLAUDE.md").read_text(encoding="utf-8")
for needle in [
    ".github/copilot-instructions.md",
    "bash tests/run-all.sh",
    "## Canonical instructions",
]:
    if needle not in claude_text:
        raise SystemExit("CLAUDE.md missing canonical source pointer: " + needle)
for forbidden in ["## Rules", "## Coding conventions"]:
    if forbidden in claude_text:
        raise SystemExit("CLAUDE.md still duplicates policy section: " + forbidden)

llms_text = (root / "llms.txt").read_text(encoding="utf-8")
for needle in [
    "[.github/copilot-instructions.md](.github/copilot-instructions.md)",
    "[AGENTS.md](AGENTS.md)",
    "[MODELS.md](MODELS.md)",
    "## Model strategy",
]:
    if needle not in llms_text:
        raise SystemExit("llms.txt missing canonical navigation link: " + needle)
for forbidden in ["## Route queries quickly", "## Canonical machine sources"]:
    if forbidden in llms_text:
        raise SystemExit("llms.txt still duplicates navigation section: " + forbidden)

models_text = (root / "MODELS.md").read_text(encoding="utf-8")
if "llms.txt` mirrors only the primary-model and thinking-effort summary" not in models_text:
    raise SystemExit("MODELS.md missing llms.txt mirror note")
'
echo ""

echo "13. Consumer template CLAUDE surface stays lean and placeholder-safe"
assert_python "template/CLAUDE.md mirrors the canonical-source pattern with placeholders" '
template_claude_text = (root / "template/CLAUDE.md").read_text(encoding="utf-8")
for needle in [
    "## Canonical instructions",
    ".github/copilot-instructions.md",
    "{{TEST_COMMAND}}",
    "{{PROJECT_NAME}}",
    "{{LANGUAGE}}",
]:
    if needle not in template_claude_text:
        raise SystemExit("template/CLAUDE.md missing expected content: " + needle)
for forbidden in ["## Rules", "## Coding conventions"]:
    if forbidden in template_claude_text:
        raise SystemExit("template/CLAUDE.md still duplicates deprecated section: " + forbidden)
'
echo ""

finish_tests