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

finish_tests

finish_tests