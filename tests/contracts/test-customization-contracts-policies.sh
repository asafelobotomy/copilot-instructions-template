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

echo "4. Agent allow-lists stay minimal and workflow-aligned"
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
    "coding.agent.md": {"Review", "Audit", "Researcher", "Explore", "Extensions", "Commit", "Organise"},
    "commit.agent.md": {"Code", "Review", "Audit"},
    "explore.agent.md": {"Researcher"},
    "extensions.agent.md": {"Code", "Audit", "Organise"},
    "fast.agent.md": {"Code", "Explore", "Researcher"},
    "organise.agent.md": {"Explore"},
    "researcher.agent.md": {"Code", "Audit"},
    "review.agent.md": {"Code", "Audit", "Organise"},
    "setup.agent.md": {"Audit", "Organise"},
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
    ],
    "commit.agent.md": [
        "Use `Code` when preflight or review finds implementation work",
        "Use `Audit` when the user requests a deeper security or health check",
    ],
    "fast.agent.md": [
        "If the question expands beyond a single file but stays read-only, use",
        "If the answer depends on current external documentation or version-specific",
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