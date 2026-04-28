#!/usr/bin/env bash
# tests/contracts/test-starter-kits.sh -- validate plugin manifests and starter-kit contracts.
# Run: bash tests/contracts/test-starter-kits.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

echo "=== Starter-kit contract checks ==="
echo ""

echo "1. REGISTRY.json is valid JSON with required schema"
assert_python "REGISTRY.json schema is valid" '
registry = json.loads((root / "starter-kits/REGISTRY.json").read_text(encoding="utf-8"))
if registry.get("schemaVersion") != "1.2":
    raise SystemExit("missing or wrong schemaVersion")
kits = registry.get("kits")
if not isinstance(kits, list) or len(kits) == 0:
    raise SystemExit("kits must be a non-empty list")
for kit in kits:
    for field in ("name", "displayName", "version", "description", "featured", "tags", "detect", "files"):
        if field not in kit:
            raise SystemExit("kit " + kit.get("name", "?") + " missing field: " + field)
    if not isinstance(kit["featured"], bool):
        raise SystemExit("kit " + kit["name"] + " has non-boolean featured field")
    if not isinstance(kit["tags"], list) or len(kit["tags"]) == 0:
        raise SystemExit("kit " + kit["name"] + " has empty tags list")
    if any(not isinstance(tag, str) or not tag for tag in kit["tags"]):
        raise SystemExit("kit " + kit["name"] + " has invalid tag entry")
    if len(set(kit["tags"])) != len(kit["tags"]):
        raise SystemExit("kit " + kit["name"] + " has duplicate tags")
    if not isinstance(kit["files"], list) or len(kit["files"]) == 0:
        raise SystemExit("kit " + kit["name"] + " has empty files list")
    if ".claude-plugin/plugin.json" not in kit["files"]:
        raise SystemExit("kit " + kit["name"] + " missing .claude-plugin/plugin.json in files list")
    detect = kit["detect"]
    has_signal = "files" in detect or "language" in detect or "dependencies" in detect
    if not has_signal:
        raise SystemExit("kit " + kit["name"] + " detect has no signals (files/language/dependencies)")
if not any(kit["featured"] for kit in kits):
    raise SystemExit("expected at least one featured starter kit")
'
echo ""

echo "2. Every kit directory listed in REGISTRY.json exists"
assert_python "kit directories exist" '
registry = json.loads((root / "starter-kits/REGISTRY.json").read_text(encoding="utf-8"))
for kit in registry["kits"]:
    kit_dir = root / "starter-kits" / kit["name"]
    if not kit_dir.is_dir():
        raise SystemExit("missing kit directory: starter-kits/" + kit["name"] + "/")
'
echo ""

echo "3. Every file listed in kit manifest exists on disk"
assert_python "kit files exist on disk" '
registry = json.loads((root / "starter-kits/REGISTRY.json").read_text(encoding="utf-8"))
for kit in registry["kits"]:
    kit_dir = root / "starter-kits" / kit["name"]
    for rel in kit["files"]:
        path = kit_dir / rel
        if not path.is_file():
            raise SystemExit("missing file: starter-kits/" + kit["name"] + "/" + rel)
'
echo ""

echo "4. Every on-disk starter-kit file is declared in REGISTRY.json"
assert_python "kit registries fully enumerate shipped files" '
registry = json.loads((root / "starter-kits/REGISTRY.json").read_text(encoding="utf-8"))
for kit in registry["kits"]:
    kit_dir = root / "starter-kits" / kit["name"]
    listed = set(kit["files"])
    actual = {
        path.relative_to(kit_dir).as_posix()
        for path in kit_dir.rglob("*")
        if path.is_file() and "__pycache__" not in path.parts
    }
    if listed != actual:
        raise SystemExit(
            "starter-kits/" + kit["name"] + " registry drift "
            + "registry-only=" + str(sorted(listed - actual)) + " "
            + "disk-only=" + str(sorted(actual - listed))
        )
'
echo ""

echo "5. Every .claude-plugin/plugin.json has required fields"
assert_python "plugin.json schema is valid" '
registry = json.loads((root / "starter-kits/REGISTRY.json").read_text(encoding="utf-8"))
for kit in registry["kits"]:
    pj_path = root / "starter-kits" / kit["name"] / ".claude-plugin" / "plugin.json"
    pj = json.loads(pj_path.read_text(encoding="utf-8"))
    for field in ("name", "description", "version"):
        if field not in pj:
            raise SystemExit(".claude-plugin/plugin.json in " + kit["name"] + " missing field: " + field)
    if "displayName" in pj:
        raise SystemExit(".claude-plugin/plugin.json in " + kit["name"] + " has unsupported displayName field")
    author = pj.get("author")
    if author is not None:
        if not isinstance(author, dict):
            raise SystemExit(".claude-plugin/plugin.json in " + kit["name"] + " has non-object author field")
        if not isinstance(author.get("name"), str) or not author["name"]:
            raise SystemExit(".claude-plugin/plugin.json in " + kit["name"] + " has invalid author.name field")
'
echo ""

echo "4b. Root plugin.json uses explicit component paths and supported metadata"
assert_python "root plugin manifest is valid" '
pj = json.loads((root / "plugin.json").read_text(encoding="utf-8"))
for field in ("name", "description", "version"):
    if not isinstance(pj.get(field), str) or not pj[field]:
        raise SystemExit("root plugin.json missing or invalid field: " + field)
author = pj.get("author")
if author is not None:
    if not isinstance(author, dict):
        raise SystemExit("root plugin.json has non-object author field")
    if not isinstance(author.get("name"), str) or not author["name"]:
        raise SystemExit("root plugin.json has invalid author.name field")
# VS Code Copilot plugin format has no plugin-root token for hook/MCP executable paths.
# "hooks" and "mcpServers" must NOT be present — they cause broken path resolution
# (${CLAUDE_PLUGIN_ROOT} expands to empty string, yielding /hooks/scripts/... errors).
for field, expected in (("agents", "agents"), ("skills", "skills")):
    if pj.get(field) != expected:
        raise SystemExit("root plugin.json has unexpected " + field + " path")
for forbidden_field in ("hooks", "mcpServers"):
    if forbidden_field in pj:
        raise SystemExit("root plugin.json must not contain " + forbidden_field + " (no plugin-root token in VS Code Copilot format)")
'
echo ""

echo "4c. Plugin .mcp.json is empty (heartbeat MCP server removed)"
assert_python "plugin mcp.json is empty object" '
mcp = json.loads((root / ".mcp.json").read_text(encoding="utf-8"))
if mcp != {}:
    raise SystemExit(".mcp.json should be empty object, got: " + json.dumps(mcp))
'
echo ""

echo "6. SKILL.md files in kits have valid YAML frontmatter"
assert_python "kit SKILL.md frontmatter is valid" '
registry = json.loads((root / "starter-kits/REGISTRY.json").read_text(encoding="utf-8"))
for kit in registry["kits"]:
    kit_dir = root / "starter-kits" / kit["name"]
    for skill_md in kit_dir.rglob("SKILL.md"):
        text = skill_md.read_text(encoding="utf-8")
        if not text.startswith("---\n"):
            raise SystemExit("missing frontmatter in " + str(skill_md.relative_to(root)))
        end = text.find("\n---\n", 4)
        if end == -1:
            raise SystemExit("unterminated frontmatter in " + str(skill_md.relative_to(root)))
        fm = text[4:end]
        if "name:" not in fm or "description:" not in fm:
            raise SystemExit("missing name/description in " + str(skill_md.relative_to(root)))
'
echo ""

echo "7. Kit command files have valid frontmatter"
assert_python "kit command frontmatter is valid" '
registry = json.loads((root / "starter-kits/REGISTRY.json").read_text(encoding="utf-8"))
for kit in registry["kits"]:
    kit_dir = root / "starter-kits" / kit["name"]
    cmd_dir = kit_dir / "commands"
    if not cmd_dir.exists():
        continue
    for path in cmd_dir.glob("*.md"):
        text = path.read_text(encoding="utf-8")
        if not text.startswith("---\n"):
            raise SystemExit("missing frontmatter in " + str(path.relative_to(root)))
        end = text.find("\n---\n", 4)
        if end == -1:
            raise SystemExit("unterminated frontmatter in " + str(path.relative_to(root)))
        fm = text[4:end]
        if "description:" not in fm:
            raise SystemExit("missing description in " + str(path.relative_to(root)))
'
echo ""

echo "8. Plugin manifests are in .claude-plugin/ directory"
assert_python "plugin.json location is correct" '
registry = json.loads((root / "starter-kits/REGISTRY.json").read_text(encoding="utf-8"))
for kit in registry["kits"]:
    kit_dir = root / "starter-kits" / kit["name"]
    # Must be in .claude-plugin/ not root
    if (kit_dir / "plugin.json").exists():
        raise SystemExit("plugin.json in root of " + kit["name"] + " — should be in .claude-plugin/")
    if not (kit_dir / ".claude-plugin" / "plugin.json").exists():
        raise SystemExit("missing .claude-plugin/plugin.json in " + kit["name"])
'
echo ""

echo "9. No placeholder tokens in any starter-kit file"
assert_python "no {{ tokens in starter-kits/" '
for path in (root / "starter-kits").rglob("*"):
    if not path.is_file():
        continue
    if path.suffix == ".json":
        continue
    text = path.read_text(encoding="utf-8")
    # Match {{PLACEHOLDER}} patterns but not Go template syntax like {{.Field}}
    if re.search(r"\{\{[A-Z_]+\}\}", text):
        raise SystemExit("unresolved placeholder token in " + str(path.relative_to(root)))
'
echo ""

echo "10. Kit names are lowercase alphanumeric with hyphens only"
assert_python "kit names follow naming convention" '
registry = json.loads((root / "starter-kits/REGISTRY.json").read_text(encoding="utf-8"))
for kit in registry["kits"]:
    name = kit["name"]
    if not re.match(r"^[a-z][a-z0-9-]*$", name):
        raise SystemExit("invalid kit name: " + name + " (must be lowercase alphanumeric with hyphens)")
'
echo ""

finish_tests
