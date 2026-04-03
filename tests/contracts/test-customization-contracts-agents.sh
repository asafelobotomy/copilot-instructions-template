#!/usr/bin/env bash
# tests/contracts/test-customization-contracts-agents.sh -- agent and settings customization contract checks.
# Run: bash tests/contracts/test-customization-contracts-agents.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

echo "=== Customization agent contract checks ==="
echo ""

echo "1. Researcher and Explore agent files are well-formed"
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

echo "2. Audit agent defines D11-D13 upstream baseline checks"
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

assert_python "audit detects repo shape before health checks" '
text = (root / ".github/agents/audit.agent.md").read_text(encoding="utf-8")
required = [
    "## Repo shape detection",
    "Developer template repo",
    "Consumer repo",
    "default to the consumer-safe subset",
]
for needle in required:
    if needle not in text:
        raise SystemExit("audit.agent.md missing repo-shape guidance: " + needle)
'

assert_python "audit D4 and D14 mention delegation matrix enforcement" '
text = " ".join((root / ".github/agents/audit.agent.md").read_text(encoding="utf-8").split())
required = [
    "### D4 — Agent file validity and delegation policy",
    "specialist delegation allow-lists match the repo policy",
    "Consumer repos: skip repo-policy allow-list matching",
    "Covers: A1–A4 (agents)",
    "I1–I4 (instructions)",
    "--profile consumer",
    "intentionally skips repo-only A4, I4, K1, and K2",
]
for needle in required:
    if needle not in text:
        raise SystemExit("audit.agent.md missing delegation audit detail: " + needle)
'

assert_python "audit has fetch tool for upstream checks" '
text = (root / ".github/agents/audit.agent.md").read_text(encoding="utf-8")
end = text.find("\n---\n", 4)
fm = text[4:end]
if "fetch" not in fm:
    raise SystemExit("audit frontmatter must include fetch tool for upstream checks")
'
echo ""

echo "3. Organise stays hidden and coordinator agents can invoke it"
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
    "tools: [agent, editFiles, runCommands, codebase, search]",
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

echo "4. Agents with allow-lists include the agent tool"
assert_python "agents allow-list implies agent tool" '
def normalize_items(raw):
    return [item.strip().replace(chr(39), "").replace(chr(34), "") for item in raw.split(",") if item.strip()]

for path in sorted((root / ".github/agents").glob("*.agent.md")):
    text = path.read_text(encoding="utf-8")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit("unterminated frontmatter in " + path.name)
    fm = text[4:end]
    agents_match = re.search(r"^agents:\s*\[(.*)\]\s*$", fm, re.M)
    if not agents_match:
        continue
    agents = normalize_items(agents_match.group(1))
    if not agents:
        continue
    tools_match = re.search(r"^tools:\s*\[(.*)\]\s*$", fm, re.M)
    if not tools_match:
        raise SystemExit(path.name + " missing tools line")
    tools = normalize_items(tools_match.group(1))
    if "agent" not in tools:
        raise SystemExit(path.name + " declares agents: but omits agent tool")
'
echo ""

echo "5. Extensions agent grants the profile tools it references"
assert_python "extensions agent tools match profile workflow" '
def normalize_items(raw):
    return {item.strip().replace(chr(39), "").replace(chr(34), "") for item in raw.split(",") if item.strip()}

path = root / ".github/agents/extensions.agent.md"
text = path.read_text(encoding="utf-8")
end = text.find("\n---\n", 4)
if end == -1:
    raise SystemExit("unterminated frontmatter in extensions.agent.md")
fm = text[4:end]
tools_match = re.search(r"^tools:\s*\[(.*)\]\s*$", fm, re.M)
if not tools_match:
    raise SystemExit("extensions.agent.md missing tools line")
tools = normalize_items(tools_match.group(1))
required = {
    "get_active_profile",
    "list_profiles",
    "get_workspace_profile_association",
    "ensure_repo_profile",
    "get_installed_extensions",
    "install_extension",
    "uninstall_extension",
    "sync_extensions_with_recommendations",
}
missing = sorted(required - tools)
if missing:
    raise SystemExit("extensions.agent.md missing profile tools: " + ", ".join(missing))
'
echo ""

echo "6. Nested subagent invocation stays enabled in VS Code settings"
assert_python "repo and template settings keep nested subagents enabled" '
for rel in (".vscode/settings.json", "template/vscode/settings.json"):
    data = json.loads((root / rel).read_text(encoding="utf-8"))
    if data.get("chat.subagents.allowInvocationsFromSubagents") is not True:
        raise SystemExit(rel + " must set chat.subagents.allowInvocationsFromSubagents=true")
'
echo ""

finish_tests