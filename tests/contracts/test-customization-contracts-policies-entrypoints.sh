# shellcheck shell=bash
echo "1. Commit agent integrates preflight and install confirmation"
assert_python "commit agent has preflight workflow and askQuestions support" '
path = root / "agents/commit.agent.md"
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
    "askQuestions` for ALL user-facing decisions",
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
path = root / "agents/fast.agent.md"
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
if "Use `search` for fast exact-match or regex lookups" not in text:
    raise SystemExit("fast.agent.md missing search guidance")
'
echo ""

echo "3. Repo and consumer workspace indices stay aligned"
assert_python "workspace-index repo and template copies match" '
repo_path = root / ".copilot/workspace/operations/workspace-index.json"
template_path = root / "template/workspace/operations/workspace-index.json"
repo_data = json.load(repo_path.open(encoding="utf-8"))
template_data = json.load(template_path.open(encoding="utf-8"))
repo_data["updated"] = "IGNORED"
template_data["updated"] = "IGNORED"
if repo_data != template_data:
    raise SystemExit("repo and template workspace-index.json diverged")
if "commit-preflight" not in repo_data["skills"]["repo"]:
    raise SystemExit("workspace-index repo skills missing commit-preflight")
'
echo ""

echo "4. Main/default agent instructions require specialist-first delegation"
assert_python "top-level instruction files encode the delegation policy" '
required_by_file = {
    ".github/copilot-instructions.md": [
        "Main/default agent delegation:",
        "delegate instead of absorbing",
        "Do not keep specialist work inline because it seems small, quick, or manageable.",
        "Trust the selected specialist to complete the task unless you know it is outside the specialist scope, allow-list, or capabilities, or it reports a concrete blocker.",
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
        "Do not keep specialist work inline because it seems small, quick, or manageable.",
        "Trust the selected specialist to complete the task unless you know it is outside the specialist scope, allow-list, or capabilities, or the specialist reports a concrete blocker.",
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
        "Do not use task size, perceived simplicity, or personal preference as a reason to keep specialist work inline.",
        "Trust the selected specialist to complete the task unless you know it is outside the specialist scope, allow-list, or capabilities, or the specialist reports a concrete blocker.",
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
        "${CLAUDE_PLUGIN_ROOT}/agents/",
        "VS Code Agent Plugin",
        "Chat: Install Plugin",
    ],
    "agents/setup.agent.md": [
        "${CLAUDE_PLUGIN_ROOT}",
        "template/setup/manifests.md",
        "askQuestions",
    ],
    "template/setup/manifests.md": [
        "## Protocol sources",
        "| Setup |",
        "| Update, backup restore, and factory restore |",
        "`agents/setup.agent.md`",
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

setup_agent_text = (root / "agents/setup.agent.md").read_text(encoding="utf-8")
if "### Pre-flight URLs" in setup_agent_text:
    raise SystemExit("setup.agent.md still duplicates the pre-flight URL list")
if "### Trigger phrases (update mode)" in setup_agent_text:
    raise SystemExit("setup.agent.md still duplicates the update trigger phrase list")
for rel in ("AGENTS.md", "agents/setup.agent.md"):
    text = (root / rel).read_text(encoding="utf-8")
    if "[template/setup/manifests.md](template/setup/manifests.md#protocol-sources)" in text:
        raise SystemExit(rel + " still points consumers at a non-installed local manifests path")
'
echo ""

echo "5b. Setup guide stays aligned with plugin and manual bootstrap entry points"
assert_python "SETUP.md documents searchable setup routes and canonical triggers" '
checks = {
    "SETUP.md": [
        "# Setup Guide",
        "Install the copilot-instructions-template plugin",
        "Setup from asafelobotomy/copilot-instructions-template",
        "Set up this project",
        "Chat: Install Plugin",
        "Chat: Install Plugin From Source",
        "chat.pluginLocations",
        "@agentPlugins copilot-instructions-template",
        "Plugin-backed",
        "All-local",
        "See [AGENTS.md](AGENTS.md) for the full trigger table.",
    ],
    "README.md": [
        "### Setup routes",
        "Set up this project",
        "@agentPlugins copilot-instructions-template",
        "See [SETUP.md](SETUP.md) for the full plugin and manual setup flow",
        "If the plugin marketplace entry is unavailable, follow the manual Copilot bootstrap path in [SETUP.md](SETUP.md).",
    ],
}
for rel, needles in checks.items():
    text = (root / rel).read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            raise SystemExit(rel + " missing setup routing guidance: " + needle)
'
echo ""

echo "5c. Starter-kit ranking and hook catalog stay documented"
assert_python "setup agent and README document starter-kit ranking metadata and hooks" '
checks = {
    "agents/setup.agent.md": [
        "featured matches first (`featured: true`)",
        "Use `tags` and the kit description",
        "Starter kits",
    ],
    "README.md": [
        "## Hooks",
        "Featured default kits: `python` and `typescript`.",
        "[hooks/hooks.json](hooks/hooks.json)",
        "`SessionStart`",
        "`UserPromptSubmit`",
        "`PreToolUse`",
        "`PostToolUse`",
        "`Stop`",
        "`PreCompact`",
        "`SubagentStart`",
        "`SubagentStop`",
        "`session-start.sh`",
        "`scan-secrets.sh`",
        "`save-context.sh`",
        "`subagent-start.sh`",
        "`subagent-stop.sh`",
    ],
}
for rel, needles in checks.items():
    text = (root / rel).read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            raise SystemExit(rel + " missing hook or starter-kit documentation: " + needle)
'
echo ""

