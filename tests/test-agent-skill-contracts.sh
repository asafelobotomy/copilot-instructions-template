#!/usr/bin/env bash
# tests/test-agent-skill-contracts.sh -- verify agent and skill metadata contracts.
# Run: bash tests/test-agent-skill-contracts.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"

echo "=== Agent and skill contract checks ==="
echo ""

echo "1. Agent files keep the expected inventory and frontmatter shape"
assert_python "agent metadata stays valid" '
expected = {
    "coding.agent.md": "Code",
    "doctor.agent.md": "Doctor",
    "fast.agent.md": "Fast",
    "review.agent.md": "Review",
    "setup.agent.md": "Setup",
    "update.agent.md": "Update",
}
found = {path.name: path for path in (root / ".github/agents").glob("*.agent.md")}
if set(found) != set(expected):
    raise SystemExit(f"expected={sorted(expected)} found={sorted(found)}")

for file_name, agent_name in expected.items():
    text = found[file_name].read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit(f"missing frontmatter in {file_name}")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit(f"unterminated frontmatter in {file_name}")
    frontmatter = text[4:end]
    body = text[end + 5 :]
    required_markers = [
        f"name: {agent_name}",
        "description:",
        "argument-hint:",
        "model:",
        "tools:",
    ]
    for marker in required_markers:
        if marker not in frontmatter:
            raise SystemExit(f"{file_name}: missing {marker}")
    if "agent for copilot-instructions-template." not in body:
        raise SystemExit(f"{file_name}: missing role declaration")
    should_disable = file_name in {"setup.agent.md", "update.agent.md"}
    has_disable = "disable-model-invocation: true" in frontmatter
    if should_disable and not has_disable:
        raise SystemExit(f"{file_name}: missing disable-model-invocation")
    if not should_disable and has_disable:
        raise SystemExit(f"{file_name}: unexpected disable-model-invocation")
'
echo ""

echo "2. Skill files keep the expected inventory and minimal metadata"
assert_python "skill metadata stays valid" '
expected = {
    "conventional-commit",
    "extension-review",
    "fix-ci-failure",
    "issue-triage",
    "lean-pr-review",
    "mcp-builder",
    "mcp-management",
    "plugin-management",
    "skill-creator",
    "skill-management",
    "test-coverage-review",
    "tool-protocol",
    "webapp-testing",
}
found = {path.parent.name: path for path in (root / ".github/skills").glob("*/SKILL.md")}
if set(found) != expected:
    raise SystemExit(f"expected={sorted(expected)} found={sorted(found)}")

for skill_name, path in found.items():
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit(f"missing frontmatter in {path.relative_to(root)}")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit(f"unterminated frontmatter in {path.relative_to(root)}")
    frontmatter = text[4:end]
    body = text[end + 5 :]
    if f"name: {skill_name}" not in frontmatter:
        raise SystemExit(f"{path.relative_to(root)}: missing name")
    if "description:" not in frontmatter:
        raise SystemExit(f"{path.relative_to(root)}: missing description")
    if "# " not in body:
        raise SystemExit(f"{path.relative_to(root)}: missing top-level heading")
    if "Skill metadata:" not in body:
        raise SystemExit(f"{path.relative_to(root)}: missing skill metadata note")
'
echo ""

echo "3. Human docs still advertise agents and skills as first-class surfaces"
assert_python "guide docs keep agent and skill coverage" '
checks = {
    "README.md": [".github/agents/", ".github/skills/"],
    "AGENTS.md": [".github/agents/", ".github/skills/"],
    "docs/AGENTS-GUIDE.md": [".github/agents/*.agent.md", "agent: Code"],
    "docs/SKILLS-GUIDE.md": ["SKILL.md", "Skill Protocol"],
}
for rel_path, markers in checks.items():
    text = (root / rel_path).read_text(encoding="utf-8")
    for marker in markers:
        if marker not in text:
            raise SystemExit(f"{rel_path}: missing {marker}")
'
echo ""

finish_tests
