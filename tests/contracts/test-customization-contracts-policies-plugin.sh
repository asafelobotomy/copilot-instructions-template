# shellcheck shell=bash
echo "15. Plugin root-token guidance and root plugin hook surfaces stay format-aware"
assert_python "plugin guidance distinguishes formats and root plugin surfaces stay wired" '
import json

guidance_checks = {
    ".github/skills/plugin-management/SKILL.md": [
        "`${CLAUDE_PLUGIN_ROOT}` for Claude-format plugins",
        "`${PLUGIN_ROOT}` for OpenPlugin plugins",
        "Copilot-format plugins do not currently document a plugin-root token in VS Code",
    ],
    "template/skills/plugin-management/SKILL.md": [
        "`${CLAUDE_PLUGIN_ROOT}` for Claude-format plugins",
        "`${PLUGIN_ROOT}` for OpenPlugin plugins",
        "Copilot-format plugins do not currently document a plugin-root token in VS Code",
    ],
    ".github/skills/mcp-builder/SKILL.md": [
        "For Claude-format plugins, use `${CLAUDE_PLUGIN_ROOT}`",
        "For OpenPlugin plugins, replace it with `${PLUGIN_ROOT}`",
        "Copilot-format plugins do not currently document a plugin-root token in VS Code",
    ],
    "template/skills/mcp-builder/SKILL.md": [
        "For Claude-format plugins, use `${CLAUDE_PLUGIN_ROOT}`",
        "For OpenPlugin plugins, replace it with `${PLUGIN_ROOT}`",
        "Copilot-format plugins do not currently document a plugin-root token in VS Code",
    ],
    "README.md": [
        "the root Copilot-format manifest at [`plugin.json`](plugin.json)",
        "OpenPlugin under [`.plugin/plugin.json`](.plugin/plugin.json)",
        "Claude format under [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json)",
        "does not document an equivalent plugin-root token for Copilot-format plugin-owned hook and MCP executable paths",
    ],
}
for rel, needles in guidance_checks.items():
    text = (root / rel).read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            raise SystemExit(rel + " missing plugin-format guidance: " + needle)

plugin_specs = {
    ".plugin": {
        "manifest": "plugin.json",
        "hooks": "hooks.json",
        "mcp": ".mcp.json",
        "token": "${PLUGIN_ROOT}",
        "forbidden": ["${CLAUDE_PLUGIN_ROOT}", "${workspaceFolder}"],
    },
    ".claude-plugin": {
        "manifest": "plugin.json",
        "hooks": "hooks/hooks.json",
        "mcp": ".mcp.json",
        "token": "${CLAUDE_PLUGIN_ROOT}",
        "forbidden": ["${PLUGIN_ROOT}", "${workspaceFolder}"],
    },
}

workspace_hooks = json.loads((root / "template/hooks/copilot-hooks.json").read_text(encoding="utf-8"))["hooks"]
workspace_events = set(workspace_hooks.keys())

for plugin_root, spec in plugin_specs.items():
    manifest_path = root / plugin_root / spec["manifest"]
    hooks_path = root / plugin_root / spec["hooks"]
    mcp_path = root / plugin_root / spec["mcp"]

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    hooks = json.loads(hooks_path.read_text(encoding="utf-8"))
    mcp = json.loads(mcp_path.read_text(encoding="utf-8"))

    if manifest.get("name") != "copilot-instructions-template":
        raise SystemExit(str(manifest_path.relative_to(root)) + " has unexpected plugin name")
    if manifest.get("agents") != "../.github/agents":
        raise SystemExit(str(manifest_path.relative_to(root)) + " must point agents at ../.github/agents")
    if manifest.get("skills") != "../.github/skills":
        raise SystemExit(str(manifest_path.relative_to(root)) + " must point skills at ../.github/skills")
    if manifest.get("hooks") != spec["hooks"]:
        raise SystemExit(str(manifest_path.relative_to(root)) + " must point hooks at " + spec["hooks"])
    if manifest.get("mcpServers") != spec["mcp"]:
        raise SystemExit(str(manifest_path.relative_to(root)) + " must point mcpServers at " + spec["mcp"])

    hook_events = set(hooks.get("hooks", {}).keys())
    if hook_events != workspace_events:
        raise SystemExit(str(hooks_path.relative_to(root)) + " events diverged from template/hooks/copilot-hooks.json")

    hook_text = hooks_path.read_text(encoding="utf-8")
    if spec["token"] not in hook_text:
        raise SystemExit(str(hooks_path.relative_to(root)) + " missing expected token " + spec["token"])
    for forbidden in spec["forbidden"]:
        if forbidden in hook_text:
            raise SystemExit(str(hooks_path.relative_to(root)) + " contains wrong path token " + forbidden)
    expected_hook_suffix = "../hooks/scripts/"
    forbidden_hook_suffix = "../.github/hooks/scripts/"
    if expected_hook_suffix not in hook_text:
        raise SystemExit(str(hooks_path.relative_to(root)) + " must point hook commands at " + expected_hook_suffix)
    if forbidden_hook_suffix in hook_text:
        raise SystemExit(str(hooks_path.relative_to(root)) + " must not point hook commands at deleted " + forbidden_hook_suffix + " paths")

    mcp_text = mcp_path.read_text(encoding="utf-8")
    if spec["token"] not in mcp_text:
        raise SystemExit(str(mcp_path.relative_to(root)) + " missing expected token " + spec["token"])
    for forbidden in spec["forbidden"]:
        if forbidden in mcp_text:
            raise SystemExit(str(mcp_path.relative_to(root)) + " contains wrong path token " + forbidden)

    heartbeat = mcp.get("mcpServers", {}).get("heartbeat")
    if not heartbeat:
        raise SystemExit(str(mcp_path.relative_to(root)) + " missing heartbeat MCP server")
    args = heartbeat.get("args", [])
    if not any(spec["token"] in arg and "mcp-heartbeat-server.py" in arg for arg in args):
        raise SystemExit(str(mcp_path.relative_to(root)) + " must launch the heartbeat server from plugin-aware path")
'
echo ""

echo "16. Update mode documents MCP delta detection and install-metadata persistence"
assert_python "setup agent update mode covers MCP delta step and install-metadata refresh" '
setup_text = (root / "agents/setup.agent.md").read_text(encoding="utf-8")
required = [
    "MCP delta",
    "MCP_AVAILABLE",
    "new_servers",
    "install-metadata",
    "mcp-heartbeat-server.py",
]
for needle in required:
    if needle not in setup_text:
        raise SystemExit("agents/setup.agent.md update mode missing MCP delta guidance: " + needle)
'
echo ""

echo "17. Interview Tier S includes A18 plugin-authoring opt-in question"
assert_python "interview.md Tier S includes A18 question with S6 gate and plugin-authoring options" '
interview = (root / "template/setup/interview.md").read_text(encoding="utf-8")
required = [
    "A18",
    "Plugin authoring conventions",
    "S6 = All-local",
    "Yes (install when relevant)",
    "Ask when newly available on update",
]
for needle in required:
    if needle not in interview:
        raise SystemExit("template/setup/interview.md Tier S missing A18 requirement: " + needle)
manifests = (root / "template/setup/manifests.md").read_text(encoding="utf-8")
if "A18" not in manifests:
    raise SystemExit("template/setup/manifests.md stubs table missing A18 condition for plugin-components.instructions.md")
setup = (root / "agents/setup.agent.md").read_text(encoding="utf-8")
if "A18" not in setup:
    raise SystemExit("agents/setup.agent.md \u00a72.7 missing A18 gate for plugin-components.instructions.md")
'
echo ""

