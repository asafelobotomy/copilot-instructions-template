#!/usr/bin/env bash
# tests/contracts/test-customization-contracts-surfaces.sh -- prompt, instruction, and skill contract checks.
# Run: bash tests/contracts/test-customization-contracts-surfaces.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

echo "=== Customization surface contract checks ==="
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

for rel in (".github/prompts/context-map.prompt.md", "template/prompts/context-map.prompt.md"):
    text = (root / rel).read_text(encoding="utf-8")
    end = text.find("\n---\n", 4)
    frontmatter = text[4:end]
    if "tools: [codebase]" not in frontmatter:
        raise SystemExit(f"context-map prompt must stay read-only in {rel}")
'
echo ""

echo "2. Instruction files keep path scoping metadata"
assert_python "instruction frontmatter stays valid" '
expected = {
    "api-routes.instructions.md",
    "config.instructions.md",
    "docs.instructions.md",
    "plugin-components.instructions.md",
    "terminal.instructions.md",
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
stripped = re.sub(r"```[\s\S]*?```", "", text)
stripped = re.sub(r"`[^`\n]+`", "", stripped)
m = re.search(r"\{\{[A-Z_]+\}\}", stripped)
if m:
    raise SystemExit("unresolved placeholder in .github/copilot-instructions.md: " + m.group())
'
echo ""

echo "4b. Agent files have no functional placeholder tokens outside code spans"
assert_python "no functional {{ tokens in agents/*.agent.md prose" '
for path in sorted((root / "agents").glob("*.agent.md")):
    text = path.read_text(encoding="utf-8")
    stripped = re.sub(r"```[\s\S]*?```", "", text)
    stripped = re.sub(r"`[^`\n]+`", "", stripped)
    m = re.search(r"\{\{[A-Z_]+\}\}", stripped)
    if m:
        raise SystemExit(f"unresolved placeholder {m.group()} in agents/{path.name}")
'
echo ""

echo "5. Skill files have no unresolved placeholder tokens"
# shellcheck disable=SC2016
assert_python "no unresolved {{PLACEHOLDER}} tokens in repo or template skills" '
for path in sorted((root / "skills").rglob("SKILL.md")):
    text = path.read_text(encoding="utf-8")
    match = re.search(r"(?<!\$)\{\{[A-Z_]+\}\}", text)
    if match:
        raise SystemExit(
            f"unresolved placeholder {match.group()} in {path.relative_to(root).as_posix()}"
        )
'
echo ""

echo "6. Repo and template skills avoid unsupported stacks frontmatter"
assert_python "repo and template skills do not declare stacks frontmatter" '
for path in sorted((root / "skills").rglob("SKILL.md")):
    text = path.read_text(encoding="utf-8")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit("unterminated frontmatter in " + path.relative_to(root).as_posix())
    frontmatter = text[4:end]
    if re.search(r"^stacks:\s*", frontmatter, re.M):
        raise SystemExit("unsupported stacks frontmatter in " + path.relative_to(root).as_posix())
'
echo ""

echo "7. Key skills avoid stale hardcoded tool identifiers"
# shellcheck disable=SC2016
assert_python "tool and extension skills avoid stale tool-name guidance" '
checks = {
    "skills/tool-protocol/SKILL.md": ["list_code_usages"],
    "skills/extension-review/SKILL.md": ["`get_active_profile` Language Model Tool"],
}
for rel, forbidden in checks.items():
    text = (root / rel).read_text(encoding="utf-8")
    for needle in forbidden:
        if needle in text:
            raise SystemExit(rel + " contains stale tool guidance: " + needle)
'
echo ""

echo "8. Lean PR review skill points to current section numbers"
assert_python "lean-pr-review skill tracks current review/baseline sections" '
required = [
    ("skills/lean-pr-review/SKILL.md", "§5 Review Mode", "§2 baselines"),
]
for rel, review_ref, baseline_ref in required:
    text = (root / rel).read_text(encoding="utf-8")
    if review_ref not in text:
        raise SystemExit(rel + " missing current review section reference")
    if baseline_ref not in text:
        raise SystemExit(rel + " missing current baselines section reference")
    for stale in ("§2 Review Mode", "§3 baselines"):
        if stale in text:
            raise SystemExit(rel + " still contains stale section reference: " + stale)
'
echo ""

finish_tests