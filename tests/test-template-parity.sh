#!/usr/bin/env bash
# tests/test-template-parity.sh -- verify repo/template mirror files stay aligned.
# Run: bash tests/test-template-parity.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"

echo "=== Template parity checks ==="
echo ""

echo "1. Hook configuration and scripts stay in exact sync with template copies"
assert_python "hook mirrors remain exact" '
expected = {
    ".github/hooks/copilot-hooks.json": "template/hooks/copilot-hooks.json",
    ".github/hooks/scripts/enforce-retrospective.sh": "template/hooks/scripts/enforce-retrospective.sh",
    ".github/hooks/scripts/guard-destructive.sh": "template/hooks/scripts/guard-destructive.sh",
    ".github/hooks/scripts/post-edit-lint.sh": "template/hooks/scripts/post-edit-lint.sh",
    ".github/hooks/scripts/save-context.sh": "template/hooks/scripts/save-context.sh",
    ".github/hooks/scripts/session-start.sh": "template/hooks/scripts/session-start.sh",
    ".github/hooks/scripts/enforce-retrospective.ps1": "template/hooks/scripts/enforce-retrospective.ps1",
    ".github/hooks/scripts/guard-destructive.ps1": "template/hooks/scripts/guard-destructive.ps1",
    ".github/hooks/scripts/post-edit-lint.ps1": "template/hooks/scripts/post-edit-lint.ps1",
    ".github/hooks/scripts/save-context.ps1": "template/hooks/scripts/save-context.ps1",
    ".github/hooks/scripts/session-start.ps1": "template/hooks/scripts/session-start.ps1",
}
for repo_rel, template_rel in expected.items():
    repo_path = root / repo_rel
    template_path = root / template_rel
    if not repo_path.exists() or not template_path.exists():
        raise SystemExit(f"missing pair {repo_rel} {template_rel}")
    if not filecmp.cmp(repo_path, template_path, shallow=False):
        raise SystemExit(f"mismatch {repo_rel} {template_rel}")
'
echo ""

echo "2. Mirrorable skills stay in exact sync with their template copies"
assert_python "skill mirrors remain exact" '
expected = {
    ".github/skills/conventional-commit/SKILL.md": "template/skills/conventional-commit/SKILL.md",
    ".github/skills/extension-review/SKILL.md": "template/skills/extension-review/SKILL.md",
    ".github/skills/fix-ci-failure/SKILL.md": "template/skills/fix-ci-failure/SKILL.md",
    ".github/skills/issue-triage/SKILL.md": "template/skills/issue-triage/SKILL.md",
    ".github/skills/lean-pr-review/SKILL.md": "template/skills/lean-pr-review/SKILL.md",
    ".github/skills/mcp-builder/SKILL.md": "template/skills/mcp-builder/SKILL.md",
    ".github/skills/plugin-management/SKILL.md": "template/skills/plugin-management/SKILL.md",
    ".github/skills/skill-creator/SKILL.md": "template/skills/skill-creator/SKILL.md",
    ".github/skills/skill-management/SKILL.md": "template/skills/skill-management/SKILL.md",
    ".github/skills/test-coverage-review/SKILL.md": "template/skills/test-coverage-review/SKILL.md",
    ".github/skills/tool-protocol/SKILL.md": "template/skills/tool-protocol/SKILL.md",
    ".github/skills/webapp-testing/SKILL.md": "template/skills/webapp-testing/SKILL.md",
}
for repo_rel, template_rel in expected.items():
    repo_path = root / repo_rel
    template_path = root / template_rel
    if not repo_path.exists() or not template_path.exists():
        raise SystemExit(f"missing pair {repo_rel} {template_rel}")
    if not filecmp.cmp(repo_path, template_path, shallow=False):
        raise SystemExit(f"mismatch {repo_rel} {template_rel}")
'
echo ""

echo "3. Known divergent skills remain intentionally distinct from template copies"
assert_python "intentional skill divergences stay explicit" '
divergent = {
    ".github/skills/mcp-management/SKILL.md": "template/skills/mcp-management/SKILL.md",
}
for repo_rel, template_rel in divergent.items():
    repo_path = root / repo_rel
    template_path = root / template_rel
    if not repo_path.exists() or not template_path.exists():
        raise SystemExit(f"missing pair {repo_rel} {template_rel}")
    if filecmp.cmp(repo_path, template_path, shallow=False):
        raise SystemExit(f"expected divergence vanished for {repo_rel}")
'
echo ""

finish_tests
