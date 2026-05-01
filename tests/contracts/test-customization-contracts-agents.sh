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
    path = root / "agents" / (agent_name + ".agent.md")
    if not path.is_file():
        raise SystemExit("missing agent file: agents/" + agent_name + ".agent.md")
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

researcher_text = (root / "agents/researcher.agent.md").read_text(encoding="utf-8")
if "RESEARCH.md" not in researcher_text:
    raise SystemExit("researcher.agent.md body must reference RESEARCH.md")

researcher_end = researcher_text.find("\n---\n", 4)
if researcher_end == -1:
    raise SystemExit("unterminated frontmatter in researcher.agent.md")
researcher_fm = researcher_text[4:researcher_end]
for needle in ["fetch", "webSearch", "editFiles", "runCommands"]:
    if needle not in researcher_fm:
        raise SystemExit("researcher.agent.md missing required tool: " + needle)
for needle in [
    ".github/research/<topic>-<YYYY-MM-DD>.md",
    "**No code implementation** — produce findings; hand off to Code.",
    "**No test execution** — `runCommands` is limited to read-only exploration",
    "**No file deletion** — only append to `RESEARCH.md`; never remove rows.",
    "**No git operations** — do not commit or push.",
]:
    if needle not in researcher_text:
        raise SystemExit("researcher.agent.md missing research constraint: " + needle)

explore_text = (root / "agents/explore.agent.md").read_text(encoding="utf-8")
explore_end = explore_text.find("\n---\n", 4)
if explore_end == -1:
    raise SystemExit("unterminated frontmatter in explore.agent.md")
explore_fm = explore_text[4:explore_end]
if "editFiles" in explore_fm:
    raise SystemExit("explore.agent.md must stay read-only and omit editFiles")
if "runCommands" not in explore_fm:
    raise SystemExit("explore.agent.md must keep runCommands for read-only terminal inspection")
for needle in [
    "**Read-only strictly** — never use `editFiles`.",
    "read-only: `grep`, `find`, `cat`, `wc`, `ls`, `sed -n`.",
    "without making any modifications.",
]:
    if needle not in explore_text:
        raise SystemExit("explore.agent.md missing read-only guidance: " + needle)

planner_text = (root / "agents/planner.agent.md").read_text(encoding="utf-8")
planner_end = planner_text.find("\n---\n", 4)
if planner_end == -1:
    raise SystemExit("unterminated frontmatter in planner.agent.md")
planner_fm = planner_text[4:planner_end]
if "editFiles" in planner_fm:
    raise SystemExit("planner.agent.md must stay read-only and omit editFiles")
if "runCommands" not in planner_fm:
    raise SystemExit("planner.agent.md must keep runCommands for read-only inspection during planning")
for needle in [
    "Stay read-only. Do not modify files.",
    "Use `Explore` when the task needs a broader read-only inventory before the plan is credible.",
    "Use `Code` only after the plan is concrete enough to implement without widening scope.",
]:
    if needle not in planner_text:
        raise SystemExit("planner.agent.md missing planning constraint: " + needle)

review_text = (root / "agents/review.agent.md").read_text(encoding="utf-8")
review_end = review_text.find("\n---\n", 4)
if review_end == -1:
    raise SystemExit("unterminated frontmatter in review.agent.md")
review_fm = review_text[4:review_end]
if "editFiles" in review_fm:
    raise SystemExit("review.agent.md must stay read-only and omit editFiles")
if "runCommands" not in review_fm:
    raise SystemExit("review.agent.md must keep runCommands for read-only inspection during review")
for needle in [
    "This is a read-only role — do not modify files unless explicitly instructed.",
    "Prefer `Cleaner` over general `Code` when a finding is mainly stale artefact,",
    "Prefer `Organise` over general `Code` when a finding is primarily about",
]:
    if needle not in review_text:
        raise SystemExit("review.agent.md missing review constraint: " + needle)

docs_text = (root / "agents/docs.agent.md").read_text(encoding="utf-8")
docs_end = docs_text.find("\n---\n", 4)
if docs_end == -1:
    raise SystemExit("unterminated frontmatter in docs.agent.md")
docs_fm = docs_text[4:docs_end]
for needle in ["editFiles", "codebase", "search", "runCommands"]:
    if needle not in docs_fm:
        raise SystemExit("docs.agent.md missing required docs tool: " + needle)
for needle in [
    "Prefer documentation files, guides, prompts, instructions, and user-facing examples over code changes.",
    "Use `Code` when the requested documentation cannot be made truthful without implementation changes.",
    "Do not silently change runtime behavior while doing docs-only work.",
]:
    if needle not in docs_text:
        raise SystemExit("docs.agent.md missing docs constraint: " + needle)

debugger_text = (root / "agents/debugger.agent.md").read_text(encoding="utf-8")
debugger_end = debugger_text.find("\n---\n", 4)
if debugger_end == -1:
    raise SystemExit("unterminated frontmatter in debugger.agent.md")
debugger_fm = debugger_text[4:debugger_end]
if "editFiles" in debugger_fm:
    raise SystemExit("debugger.agent.md must stay diagnosis-first and omit editFiles")
if "runCommands" not in debugger_fm:
    raise SystemExit("debugger.agent.md must keep runCommands for reproduction and inspection")
for needle in [
    "Your role: diagnose problems before implementation starts.",
    "Use `Code` only after the diagnosis is specific enough to implement without guessing.",
    "Do not mix diagnosis with broad refactoring.",
]:
    if needle not in debugger_text:
        raise SystemExit("debugger.agent.md missing debugger constraint: " + needle)

fast_text = (root / "agents/fast.agent.md").read_text(encoding="utf-8")
fast_end = fast_text.find("\n---\n", 4)
if fast_end == -1:
    raise SystemExit("unterminated frontmatter in fast.agent.md")
fast_fm = fast_text[4:fast_end]
for needle in ["editFiles", "runCommands", "search", "codebase"]:
    if needle not in fast_fm:
        raise SystemExit("fast.agent.md missing required fast-path tool: " + needle)
for needle in [
    "If the question expands beyond a single file but stays read-only, use",
    "If the user is asking to stage, commit, push, tag, or release changes, use",
    "Do not run the full PDCA cycle for simple edits — just make the change and",
]:
    if needle not in fast_text:
        raise SystemExit("fast.agent.md missing fast-path constraint: " + needle)

setup_text = (root / "agents/setup.agent.md").read_text(encoding="utf-8")
setup_end = setup_text.find("\n---\n", 4)
if setup_end == -1:
    raise SystemExit("unterminated frontmatter in setup.agent.md")
setup_fm = setup_text[4:setup_end]
for needle in ["editFiles", "fetch", "askQuestions", "runCommands", "search"]:
    if needle not in setup_fm:
        raise SystemExit("setup.agent.md missing required setup tool: " + needle)
if "disable-model-invocation: true" not in setup_fm:
    raise SystemExit("setup.agent.md must keep disable-model-invocation: true")
for needle in [
    "All template content and companion data files are",
    "available locally; no network fetch is required.",
    "Use `askQuestions` for **ALL** user-facing decisions.",
    "If the output contains",
    "Do not modify files in `asafelobotomy/copilot-instructions-template` — all",
]:
    if needle not in setup_text:
        raise SystemExit("setup.agent.md missing setup constraint: " + needle)
'
echo ""

echo "2. Audit agent defines D11-D13 upstream baseline checks (via audit-procedures skill)"
assert_python "audit has D11 upstream version check" '
# D11-D14 definitions live in the audit-procedures skill (loaded on demand)
agent_text = (root / "agents/audit.agent.md").read_text(encoding="utf-8")
if "audit-procedures" not in agent_text:
    raise SystemExit("audit.agent.md must reference the audit-procedures skill for D1-D14 definitions")
text = (root / "skills/audit-procedures/SKILL.md").read_text(encoding="utf-8")
if "### D11" not in text:
    raise SystemExit("audit-procedures skill missing D11 check definition")
if "VERSION.md" not in text:
    raise SystemExit("D11 must reference VERSION.md for upstream comparison")
if "raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/VERSION.md" not in text:
    raise SystemExit("D11 must contain the upstream VERSION.md fetch URL")
'

assert_python "audit has D12 fingerprint integrity check" '
text = (root / "skills/audit-procedures/SKILL.md").read_text(encoding="utf-8")
if "### D12" not in text:
    raise SystemExit("audit-procedures skill missing D12 check definition")
if "section-fingerprints" not in text:
    raise SystemExit("D12 must reference section-fingerprints block")
if "sha256sum" not in text:
    raise SystemExit("D12 must use sha256sum for fingerprint computation")
'

assert_python "audit has D13 companion file completeness check" '
text = (root / "skills/audit-procedures/SKILL.md").read_text(encoding="utf-8")
if "### D13" not in text:
    raise SystemExit("audit-procedures skill missing D13 check definition")
if "workspace-index.json" not in text:
    raise SystemExit("D13 must reference workspace-index.json as canonical inventory")
if "raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.copilot/workspace/operations/workspace-index.json" not in text:
    raise SystemExit("D13 must contain the upstream workspace-index.json fetch URL")
for needle in [
    "prompts",
    "instructions",
    "core `.copilot/workspace/` files",
    "`.github/starter-kits/*/`",
    "`.vscode/settings.json`",
]:
    if needle not in text:
        raise SystemExit("D13 must cover companion surface: " + needle)
'

assert_python "audit report format covers D1-D14" '
text = (root / "agents/audit.agent.md").read_text(encoding="utf-8")
if "D1\u2013D14" not in text and "D1-D14" not in text:
    raise SystemExit("report format section must reference D1-D14 range")
'

assert_python "audit detects repo shape before health checks" '
text = (root / "agents/audit.agent.md").read_text(encoding="utf-8")
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
text = " ".join((root / "skills/audit-procedures/SKILL.md").read_text(encoding="utf-8").split())
required = [
    "### D4 — Agent file validity and delegation policy",
    "specialist delegation allow-lists match the repo policy",
    "Consumer repos: skip repo-policy allow-list matching",
    "Covers: A1–A4 (agents)",
    "C1 (consumer companion completeness)",
    "I1–I4 (instructions)",
    "V1 (version metadata)",
    "--profile consumer",
    "K1–K2 (starter kits)",
    "It intentionally skips repo-only A4.",
]
for needle in required:
    if needle not in text:
        raise SystemExit("audit-procedures skill missing delegation audit detail: " + needle)
'

assert_python "audit D6 and D9 cover version metadata and pluginLocations" '
text = (root / "skills/audit-procedures/SKILL.md").read_text(encoding="utf-8")
for needle in [
    "file-manifest",
    "setup-answers",
    "chat.pluginLocations",
]:
    if needle not in text:
        raise SystemExit("audit-procedures skill missing health-check detail: " + needle)
'

assert_python "verbatim-delivered agents use workspace-neutral identity wording" '
expected = {
    "coding.agent.md": "You are the Coding agent for the current project.",
    "cleaner.agent.md": "You are the Cleaner agent for the current project.",
    "review.agent.md": "You are the Review agent for the current project.",
    "fast.agent.md": "You are the Fast agent for the current project.",
    "extensions.agent.md": "You are the Extensions agent for the current project.",
    "setup.agent.md": "You are the Setup agent for the current project.",
    "audit.agent.md": "You are the Audit agent for the current project.",
    "planner.agent.md": "You are the Planner agent for the current project.",
    "docs.agent.md": "You are the Docs agent for the current project.",
    "debugger.agent.md": "You are the Debugger agent for the current project.",
}
for filename, needle in expected.items():
    text = (root / "agents" / filename).read_text(encoding="utf-8")
    if needle not in text:
        raise SystemExit(filename + " missing workspace-neutral identity wording")
    if "for copilot-instructions-template." in text:
        raise SystemExit(filename + " still leaks template-repo identity into delivered agent text")
'

assert_python "audit has fetch tool for upstream checks" '
text = (root / "agents/audit.agent.md").read_text(encoding="utf-8")
end = text.find("\n---\n", 4)
fm = text[4:end]
if "fetch" not in fm:
    raise SystemExit("audit frontmatter must include fetch tool for upstream checks")
'
echo ""

echo "3. Specialist delegation agents stay hidden and coordinators can invoke them"
assert_python "specialist agents stay hidden when they are delegation-first" '
expected_hidden = {
    "audit.agent.md": ["name: Audit", "user-invocable: false"],
    "researcher.agent.md": ["name: Researcher", "user-invocable: false"],
    "extensions.agent.md": ["name: Extensions", "user-invocable: false"],
    "organise.agent.md": ["name: Organise", "user-invocable: false"],
    "planner.agent.md": ["name: Planner", "user-invocable: false"],
    "debugger.agent.md": ["name: Debugger", "user-invocable: false"],
}

for filename, needles in expected_hidden.items():
    path = root / "agents" / filename
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit("missing frontmatter in " + filename)
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit("unterminated frontmatter in " + filename)
    fm = text[4:end]
    for needle in needles:
        if needle not in fm:
            raise SystemExit(filename + " missing: " + needle)

organise_text = (root / "agents/organise.agent.md").read_text(encoding="utf-8")
end = organise_text.find("\n---\n", 4)
fm = organise_text[4:end]
required = [
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

assert_python "Docs and Cleaner stay publicly invocable" '
expected_public = {
    "docs.agent.md": ["name: Docs", "user-invocable: true"],
    "cleaner.agent.md": ["name: Cleaner", "user-invocable: true"],
}

for filename, needles in expected_public.items():
    path = root / "agents" / filename
    text = path.read_text(encoding="utf-8")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit("unterminated frontmatter in " + filename)
    fm = text[4:end]
    for needle in needles:
        if needle not in fm:
            raise SystemExit(filename + " missing: " + needle)
'

assert_python "coordinator allow-lists include Organise" '
for agent_name in ("coding", "setup", "audit", "review", "extensions"):
    text = (root / "agents" / f"{agent_name}.agent.md").read_text(encoding="utf-8")
    if "Organise" not in text:
        raise SystemExit(f"{agent_name}.agent.md missing Organise allow-list entry")
'

assert_python "cleanup-capable coordinators include Cleaner" '
for agent_name in ("coding", "audit", "review", "commit"):
    text = (root / "agents" / f"{agent_name}.agent.md").read_text(encoding="utf-8")
    if "Cleaner" not in text:
        raise SystemExit(f"{agent_name}.agent.md missing Cleaner allow-list entry")
'
echo ""

echo "4. Agents with allow-lists include the agent tool"
assert_python "agents allow-list implies agent tool" '
def normalize_items(raw):
    return [item.strip().replace(chr(39), "").replace(chr(34), "") for item in raw.split(",") if item.strip()]

for path in sorted((root / "agents").glob("*.agent.md")):
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

path = root / "agents/extensions.agent.md"
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

echo "7. Routing manifest covers all agents with Stage 4 active scope"
assert_python "routing manifest includes all agents and only Stage 4 routes are active" '
manifest_path = root / "agents/routing-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
entries = manifest.get("agents")
if not isinstance(entries, list) or not entries:
    raise SystemExit("routing-manifest.json must include a non-empty agents array")

names_from_manifest = {entry.get("name") for entry in entries if isinstance(entry, dict)}
names_from_files = set()
for path in sorted((root / "agents").glob("*.agent.md")):
    text = path.read_text(encoding="utf-8")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit("unterminated frontmatter in " + path.name)
    fm = text[4:end]
    match = re.search(r"^name:\s*(.+)$", fm, re.M)
    if not match:
        raise SystemExit("missing name field in " + path.name)
    names_from_files.add(match.group(1).strip())

if names_from_manifest != names_from_files:
    missing = sorted(names_from_files - names_from_manifest)
    extra = sorted(names_from_manifest - names_from_files)
    raise SystemExit(f"routing manifest mismatch: missing={missing} extra={extra}")

active = {
    entry.get("name")
    for entry in entries
    if isinstance(entry, dict) and entry.get("route") in {"active", "guarded"}
}
expected_active = {
    "Audit",
    "Cleaner",
    "Commit",
    "Code",
    "Debugger",
    "Docs",
    "Explore",
    "Extensions",
    "Fast",
    "Organise",
    "Planner",
    "Researcher",
    "Review",
    "Setup",
}
if active != expected_active:
    raise SystemExit(f"unexpected Stage 4 active routes: {sorted(active)}")

public_visible = {
    entry.get("name")
    for entry in entries
    if isinstance(entry, dict) and entry.get("visibility") == "picker-visible"
}
for required in {"Docs", "Cleaner"}:
    if required not in public_visible:
        raise SystemExit(f"routing manifest must expose {required} in the picker")
'

assert_python "Cleaner routing covers documented hygiene vocabulary" '
manifest = json.loads((root / "agents/routing-manifest.json").read_text(encoding="utf-8"))
cleaner = next(
    (entry for entry in manifest.get("agents", []) if isinstance(entry, dict) and entry.get("name") == "Cleaner"),
    None,
)
if cleaner is None:
    raise SystemExit("routing manifest missing Cleaner entry")

patterns = cleaner.get("prompt_patterns") or []
joined = " ".join(patterns)
required = [
    r"\bstale (?:artefacts?|artifacts?)\b",
    r"\bdead files?\b",
    r"\barchive (?:clutter|debris)\b",
    r"\bcache clutter\b",
]
for needle in required:
    if needle not in joined:
        raise SystemExit("Cleaner prompt_patterns missing documented hygiene route: " + needle)
'
echo ""

echo "8. Agent model lists exclude GPT-5 mini because deferred tools reject it"
assert_python "agent model lists do not advertise GPT-5 mini" '
for path in sorted((root / "agents").glob("*.agent.md")):
    text = path.read_text(encoding="utf-8")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit("unterminated frontmatter in " + path.name)
    fm = text[4:end]
    if re.search(r"^\s*-\s*GPT-5 mini\s*$", fm, re.M):
        raise SystemExit(path.name + " must not include GPT-5 mini; tool_search is unsupported on that model")
'
echo ""

echo "9. Repo MCP sampling excludes GPT-5 mini"
assert_python "workspace settings do not sample MCP tools on GPT-5 mini" '
data = json.loads((root / ".vscode/settings.json").read_text(encoding="utf-8"))
sampling = data.get("chat.mcp.serverSampling") or {}
for key, value in sampling.items():
    if not isinstance(value, dict):
        raise SystemExit("chat.mcp.serverSampling entry must be an object: " + str(key))
    allowed = value.get("allowedModels") or []
    if "copilot/gpt-5-mini" in allowed:
        raise SystemExit(str(key) + " must not allow copilot/gpt-5-mini")
'
echo ""

finish_tests