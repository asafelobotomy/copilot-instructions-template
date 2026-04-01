#!/usr/bin/env bash
# tests/contracts/test-customization-contracts.sh -- verify prompt and instruction file contracts.
# Run: bash tests/contracts/test-customization-contracts.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

echo "=== Customization file contract checks ==="
echo ""

echo "1. Prompt files keep VS Code frontmatter and avoid deprecated keys"
assert_python "prompt frontmatter stays valid" '
expected = {
    "commit-msg.prompt.md",
    "context-map.prompt.md",
    "explain.prompt.md",
    "onboard-commit-style.prompt.md",
    "refactor.prompt.md",
    "review-file.prompt.md",
    "test-gen.prompt.md",
}
found = {path.name for path in (root / ".github/prompts").glob("*.prompt.md")}
if found != expected:
    raise SystemExit(f"expected={sorted(expected)} found={sorted(found)}")

for path in (root / ".github/prompts").glob("*.prompt.md"):
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit(f"missing frontmatter in {path.name}")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit(f"unterminated frontmatter in {path.name}")
    frontmatter = text[4:end]
    if "description:" not in frontmatter or "agent:" not in frontmatter:
        raise SystemExit(f"missing required prompt fields in {path.name}")
    if "mode:" in frontmatter:
        raise SystemExit(f"deprecated mode key in {path.name}")
    if "terminal" in frontmatter:
        raise SystemExit(f"deprecated terminal tool key in {path.name}")
'
echo ""

echo "2. Instruction files keep path scoping metadata"
assert_python "instruction frontmatter stays valid" '
expected = {
    "api-routes.instructions.md",
    "config.instructions.md",
    "docs.instructions.md",
    "tests.instructions.md",
}
found = {path.name for path in (root / ".github/instructions").glob("*.instructions.md")}
if found != expected:
    raise SystemExit(f"expected={sorted(expected)} found={sorted(found)}")

for path in (root / ".github/instructions").glob("*.instructions.md"):
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit(f"missing frontmatter in {path.name}")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit(f"unterminated frontmatter in {path.name}")
    frontmatter = text[4:end]
    if "applyTo:" not in frontmatter or "description:" not in frontmatter:
        raise SystemExit(f"missing required instruction fields in {path.name}")
'
echo ""

echo "3. Developer instruction and prompt stubs have no placeholder tokens"
assert_python "no {{ tokens in .github/instructions/ or .github/prompts/" '
for kind in ("instructions", "prompts"):
    d = root / ".github" / kind
    if not d.exists():
        continue
    for path in sorted(d.iterdir()):
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        if "{{" in text:
            raise SystemExit(f"unresolved {{{{}} token in .github/{kind}/{path.name}")
'
echo ""

echo "4. Developer copilot-instructions.md has no functional placeholder tokens"
assert_python "no functional {{ tokens in .github/copilot-instructions.md" '
text = (root / ".github/copilot-instructions.md").read_text(encoding="utf-8")
# Strip fenced code blocks and inline code spans (descriptive mentions are allowed there)
stripped = re.sub(r"```[\s\S]*?```", "", text)
stripped = re.sub(r"`[^`\n]+`", "", stripped)
m = re.search(r"\{\{[A-Z_]+\}\}", stripped)
if m:
    raise SystemExit("unresolved placeholder in .github/copilot-instructions.md: " + m.group())
'
echo ""

echo "5. Researcher and Explore agent files are well-formed"
assert_python "researcher and explore agents have required frontmatter and tools" '
for agent_name, required_tool in (("researcher", "fetch"), ("explore", "codebase")):
    path = root / ".github/agents" / (agent_name + ".agent.md")
    if not path.is_file():
        raise SystemExit("missing agent file: .github/agents/" + agent_name + ".agent.md")
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit("missing frontmatter in " + agent_name + ".agent.md")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit("unterminated frontmatter in " + agent_name + ".agent.md")
    fm = text[4:end]
    if "name:" not in fm:
        raise SystemExit("missing name: in " + agent_name + ".agent.md")
    if required_tool not in fm:
        raise SystemExit("missing tool " + required_tool + " in " + agent_name + ".agent.md")

researcher_text = (root / ".github/agents/researcher.agent.md").read_text(encoding="utf-8")
if "RESEARCH.md" not in researcher_text:
    raise SystemExit("researcher.agent.md body must reference RESEARCH.md")
'
echo ""

echo "6. Audit agent defines D11-D13 upstream baseline checks"
assert_python "audit has D11 upstream version check" '
text = (root / ".github/agents/audit.agent.md").read_text(encoding="utf-8")
if "### D11" not in text:
    raise SystemExit("audit.agent.md missing D11 check definition")
if "VERSION.md" not in text:
    raise SystemExit("D11 must reference VERSION.md for upstream comparison")
if "raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/VERSION.md" not in text:
    raise SystemExit("D11 must contain the upstream VERSION.md fetch URL")
'

assert_python "audit has D12 fingerprint integrity check" '
text = (root / ".github/agents/audit.agent.md").read_text(encoding="utf-8")
if "### D12" not in text:
    raise SystemExit("audit.agent.md missing D12 check definition")
if "section-fingerprints" not in text:
    raise SystemExit("D12 must reference section-fingerprints block")
if "sha256sum" not in text:
    raise SystemExit("D12 must use sha256sum for fingerprint computation")
'

assert_python "audit has D13 companion file completeness check" '
text = (root / ".github/agents/audit.agent.md").read_text(encoding="utf-8")
if "### D13" not in text:
    raise SystemExit("audit.agent.md missing D13 check definition")
if "workspace-index.json" not in text:
    raise SystemExit("D13 must reference workspace-index.json as canonical inventory")
if "raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.copilot/workspace/workspace-index.json" not in text:
    raise SystemExit("D13 must contain the upstream workspace-index.json fetch URL")
'

assert_python "audit report format covers D1-D14" '
text = (root / ".github/agents/audit.agent.md").read_text(encoding="utf-8")
if "D1\u2013D14" not in text and "D1-D14" not in text:
    raise SystemExit("report format section must reference D1-D14 range")
'

assert_python "audit has fetch tool for upstream checks" '
text = (root / ".github/agents/audit.agent.md").read_text(encoding="utf-8")
# Check frontmatter tools list
end = text.find("\n---\n", 4)
fm = text[4:end]
if "fetch" not in fm:
    raise SystemExit("audit frontmatter must include fetch tool for upstream checks")
'
echo ""

echo "7. Organise stays hidden and coordinator agents can invoke it"
assert_python "organise agent stays subagent-only with nested delegation" '
path = root / ".github/agents/organise.agent.md"
text = path.read_text(encoding="utf-8")
if not text.startswith("---\n"):
    raise SystemExit("missing frontmatter in organise.agent.md")
end = text.find("\n---\n", 4)
if end == -1:
    raise SystemExit("unterminated frontmatter in organise.agent.md")
fm = text[4:end]
required = [
    "name: Organise",
    "user-invocable: false",
    "disable-model-invocation: false",
    "tools: [editFiles, runCommands, codebase, search]",
]
for needle in required:
    if needle not in fm:
        raise SystemExit("organise.agent.md missing: " + needle)
agents_line = next((line for line in fm.splitlines() if line.startswith("agents:")), None)
if agents_line is None:
    raise SystemExit("organise.agent.md missing agents: frontmatter line")
if "Explore" not in agents_line:
    raise SystemExit("organise.agent.md must allow Explore for nested read-only inventory work")
'

assert_python "coordinator allow-lists include Organise" '
for agent_name in ("coding", "setup", "audit", "review", "extensions"):
    text = (root / ".github/agents" / f"{agent_name}.agent.md").read_text(encoding="utf-8")
    if "Organise" not in text:
        raise SystemExit(f"{agent_name}.agent.md missing Organise allow-list entry")
'
echo ""

echo "8. Nested subagent invocation stays enabled in VS Code settings"
assert_python "repo and template settings keep nested subagents enabled" '
for rel in (".vscode/settings.json", "template/vscode/settings.json"):
    data = json.loads((root / rel).read_text(encoding="utf-8"))
    if data.get("chat.subagents.allowInvocationsFromSubagents") is not True:
        raise SystemExit(rel + " must set chat.subagents.allowInvocationsFromSubagents=true")
'
echo ""
finish_tests