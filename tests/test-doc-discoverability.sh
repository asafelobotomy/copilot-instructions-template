#!/usr/bin/env bash
# tests/test-doc-discoverability.sh -- verify documentation discoverability contracts.
# Run: bash tests/test-doc-discoverability.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"

echo "=== Documentation discoverability checks ==="
echo ""

echo "1. Skill inventory counts and summary docs stay aligned"
assert_python "repo skill file count is 13" '
actual = len(list((root / ".github/skills").glob("*/SKILL.md")))
if actual != 13:
    raise SystemExit(actual)
'
assert_python "template skill file count is 13" '
actual = len(list((root / "template/skills").glob("*/SKILL.md")))
if actual != 13:
    raise SystemExit(actual)
'
assert_file_contains "README says thirteen starter skills" "$REPO_ROOT/README.md" 'Thirteen starter skills'
assert_file_contains "SETUP-GUIDE says thirteen starter skills" "$REPO_ROOT/docs/SETUP-GUIDE.md" 'Thirteen starter skills'
assert_file_contains "SKILLS-GUIDE says thirteen skills" "$REPO_ROOT/docs/SKILLS-GUIDE.md" 'Thirteen skills are scaffolded'
assert_file_contains "AGENTS says thirteen starter skills" "$REPO_ROOT/AGENTS.md" '13 starter skills'
echo ""

echo "2. Stale phrases stay out of the machine entry point"
assert_file_not_contains "AGENTS.md no Playwright-only webapp-testing description" "$REPO_ROOT/AGENTS.md" 'Playwright-based web app testing'
assert_file_contains "AGENTS.md advertises thirteen repo skills" "$REPO_ROOT/AGENTS.md" 'Thirteen repo skills'
echo ""

echo "3. Always-on MCP docs reflect filesystem plus git"
assert_file_not_contains "README no legacy always-on memory list" "$REPO_ROOT/README.md" 'filesystem, memory, git'
assert_file_not_contains "SETUP-GUIDE no legacy always-on memory list" "$REPO_ROOT/docs/SETUP-GUIDE.md" 'filesystem, memory, git'
assert_file_not_contains "INSTRUCTIONS-GUIDE no legacy always-on memory list" "$REPO_ROOT/docs/INSTRUCTIONS-GUIDE.md" 'filesystem, memory, git'
assert_file_contains "SETUP E22 option shows filesystem+git" "$REPO_ROOT/SETUP.md" 'Always-on only \(filesystem, git\)'
echo ""

echo "4. Machine-critical headings remain present"
assert_file_contains "AGENTS has Remote Bootstrap Sequence" "$REPO_ROOT/AGENTS.md" '^## Remote Bootstrap Sequence'
assert_file_contains "AGENTS has Remote Update Sequence" "$REPO_ROOT/AGENTS.md" '^## Remote Update Sequence'
assert_file_contains "SETUP has section 2.6 skill scaffold" "$REPO_ROOT/SETUP.md" '^## § 2\.6 .+ Scaffold skill library'
assert_file_contains "UPDATE has Pre-flight Sequence" "$REPO_ROOT/UPDATE.md" '^## Pre-flight Sequence'
assert_file_contains "copilot-instructions has Section 12" "$REPO_ROOT/.github/copilot-instructions.md" '^## §12 .+ Skill Protocol'
echo ""

echo "5. Summary surfaces keep high-signal skill discoverability"
for skill in tool-protocol skill-management mcp-management plugin-management extension-review test-coverage-review; do
  assert_file_contains "llms lists $skill" "$REPO_ROOT/llms.txt" "$skill"
    assert_file_contains "DOC_INDEX lists $skill" "$REPO_ROOT/.copilot/workspace/DOC_INDEX.json" "\"$skill\""
done
echo ""

finish_tests