#!/usr/bin/env bash
# tests/test-customization-contracts.sh -- verify prompt and instruction file contracts.
# Run: bash tests/test-customization-contracts.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"

echo "=== Customization file contract checks ==="
echo ""

echo "1. Prompt files keep VS Code frontmatter and avoid deprecated keys"
assert_python "prompt frontmatter stays valid" '
expected = {
    "commit-msg.prompt.md",
    "explain.prompt.md",
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
finish_tests