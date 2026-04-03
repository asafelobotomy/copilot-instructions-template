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
        "`Setup` for template bootstrap, instruction update, or backup restore",
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
        "`Setup` for template bootstrap, instruction update, or backup restore",
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

echo "5. Task completion and testing policy distinguish targeted vs full-suite gates"
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

echo "6. Developer instructions expose the targeted test selector command"
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

echo "7. Instruction files encode terminal discipline for truncation and zsh shells"
assert_python "instruction files include terminal discipline guidance" '
required_by_file = {
    ".github/copilot-instructions.md": [
        "Run all tests (captured)",
        "bash scripts/tests/run-all-captured.sh",
        "For high-volume commands, capture the full output to a log file and print only a bounded tail",
        "Prefer repo bash scripts over ad hoc zsh control flow",
        "Never run `set -euo pipefail` or `setopt errexit nounset pipefail` as a standalone terminal command",
        "scripts/tests/run-strict-bash.sh",
        "scripts/tests/run-strict-bash-stdin.sh",
        "--command",
        "EOF",
        "avoid reserved variable names such as `status`",
        "stop retrying equivalent one-liners and switch to a repo script or simpler direct invocation",
    ],
    "template/copilot-instructions.md": [
        "For high-volume commands, capture the full output to a log file and print only a bounded tail instead of streaming everything",
        "If the repo documents a terminal-safe wrapper for a noisy command, prefer it",
        "Prefer repo scripts or bash wrappers over ad hoc shell control flow",
        "Never run `set -euo pipefail` or `setopt errexit nounset pipefail` as a standalone terminal command",
        "prefer a repo wrapper if one exists",
        "prefer a dedicated stdin or here-doc wrapper when the repo provides one",
        "run the snippet through a child Bash process with strict mode enabled",
        "avoid reserved variable names such as `status`",
        "stop retrying equivalent one-liners and switch to a repo script or simpler direct invocation",
    ],
}
for rel, needles in required_by_file.items():
    text = " ".join((root / rel).read_text(encoding="utf-8").split())
    for needle in needles:
        if " ".join(needle.split()) not in text:
            raise SystemExit(rel + " missing terminal discipline guidance: " + needle)
template_text = (root / "template/copilot-instructions.md").read_text(encoding="utf-8")
if "scripts/tests/run-strict-bash.sh" in template_text:
    raise SystemExit("template/copilot-instructions.md must not reference repo-only strict wrapper paths")
if "scripts/tests/run-strict-bash-stdin.sh" in template_text:
    raise SystemExit("template/copilot-instructions.md must not reference repo-only stdin wrapper paths")
search_roots = [
    root / ".github/agents",
    root / ".github/prompts",
    root / ".github/instructions",
    root / "template/prompts",
    root / "template/instructions",
]
for search_root in search_roots:
    for path in search_root.rglob("*.md"):
        text = path.read_text(encoding="utf-8")
        if "setopt errexit nounset pipefail" in text:
            raise SystemExit(str(path.relative_to(root)) + " must not suggest top-level zsh strict-mode mutation")
'
echo ""

echo "8. Agent and prompt surfaces avoid top-level zsh strict-mode mutation guidance"
assert_python "prompt and agent surfaces avoid raw zsh strict-mode mutation" '
search_roots = [
    root / ".github/agents",
    root / ".github/prompts",
    root / ".github/instructions",
    root / "template/prompts",
    root / "template/instructions",
]
for search_root in search_roots:
    for path in search_root.rglob("*.md"):
        text = path.read_text(encoding="utf-8")
        if "setopt errexit nounset pipefail" in text:
            raise SystemExit(str(path.relative_to(root)) + " must not suggest top-level zsh strict-mode mutation")
'
echo ""

echo "9. Agent allow-lists stay minimal and workflow-aligned"
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
    "coding.agent.md": {"Review", "Audit", "Researcher", "Explore", "Extensions", "Commit", "Setup", "Organise"},
    "commit.agent.md": {"Code", "Review", "Audit"},
    "explore.agent.md": {"Researcher"},
    "extensions.agent.md": {"Code", "Audit", "Organise"},
    "fast.agent.md": {"Code", "Review", "Audit", "Explore", "Researcher", "Extensions", "Commit", "Setup", "Organise"},
    "organise.agent.md": {"Code", "Explore"},
    "researcher.agent.md": {"Code", "Audit", "Explore"},
    "review.agent.md": {"Code", "Audit", "Organise"},
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
        "Use `Explore` for read-only codebase inventory across multiple files",
        "Use `Researcher` when a task depends on current external documentation",
        "Use `Extensions` when the work shifts into VS Code extension recommendations",
        "Use `Setup` when the task turns into template bootstrap, instruction update,",
    ],
    "commit.agent.md": [
        "Use `Code` when preflight or review finds implementation work",
        "Use `Audit` when the user requests a deeper security or health check",
    ],
    "fast.agent.md": [
        "If the user is asking for a formal code review or architectural critique, use",
        "If the user is asking for a health check, security audit, or vulnerability",
        "If the question expands beyond a single file but stays read-only, use",
        "If the answer depends on current external documentation or version-specific",
        "If the user is asking to stage, commit, push, tag, or release changes, use",
        "If the task is really VS Code extension, profile, or workspace recommendation",
        "If the task is really template setup, instruction update, or backup restore",
        "If the task is primarily moving files, fixing broken paths, or reorganising",
    ],
    "organise.agent.md": [
        "Use `Code` when the task expands from structural cleanup into semantic",
    ],
    "researcher.agent.md": [
        "Use `Explore` when you need a broader read-only inventory of local callers,",
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

finish_tests