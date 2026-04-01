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
    ".github/hooks/scripts/lib-hooks.sh": "template/hooks/scripts/lib-hooks.sh",
    ".github/hooks/scripts/guard-destructive.sh": "template/hooks/scripts/guard-destructive.sh",
    ".github/hooks/scripts/post-edit-lint.sh": "template/hooks/scripts/post-edit-lint.sh",
    ".github/hooks/scripts/pulse.sh": "template/hooks/scripts/pulse.sh",
    ".github/hooks/scripts/save-context.sh": "template/hooks/scripts/save-context.sh",
    ".github/hooks/scripts/scan-secrets.sh": "template/hooks/scripts/scan-secrets.sh",
    ".github/hooks/scripts/session-start.sh": "template/hooks/scripts/session-start.sh",
    ".github/hooks/scripts/subagent-start.sh": "template/hooks/scripts/subagent-start.sh",
    ".github/hooks/scripts/subagent-stop.sh": "template/hooks/scripts/subagent-stop.sh",
    ".github/hooks/scripts/guard-destructive.ps1": "template/hooks/scripts/guard-destructive.ps1",
    ".github/hooks/scripts/post-edit-lint.ps1": "template/hooks/scripts/post-edit-lint.ps1",
    ".github/hooks/scripts/pulse.ps1": "template/hooks/scripts/pulse.ps1",
    ".github/hooks/scripts/save-context.ps1": "template/hooks/scripts/save-context.ps1",
    ".github/hooks/scripts/scan-secrets.ps1": "template/hooks/scripts/scan-secrets.ps1",
    ".github/hooks/scripts/session-start.ps1": "template/hooks/scripts/session-start.ps1",
    ".github/hooks/scripts/subagent-start.ps1": "template/hooks/scripts/subagent-start.ps1",
    ".github/hooks/scripts/subagent-stop.ps1": "template/hooks/scripts/subagent-stop.ps1",
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
    ".github/skills/create-adr/SKILL.md": "template/skills/create-adr/SKILL.md",
    ".github/skills/agentic-workflows/SKILL.md": "template/skills/agentic-workflows/SKILL.md",
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

echo "3. mcp-management skill exists only in .github/skills/ (no template mirror)"
assert_python "mcp-management has no template mirror" '
mcp_template = root / "template/skills/mcp-management"
mcp_github = root / ".github/skills/mcp-management/SKILL.md"
if mcp_template.exists():
    raise SystemExit("template/skills/mcp-management/ should not exist")
if not mcp_github.exists():
    raise SystemExit(".github/skills/mcp-management/SKILL.md is missing")
'
echo ""

echo "4. Verbatim instruction and prompt stubs stay in exact sync"
assert_python "verbatim instruction and prompt mirrors remain exact" '
exact = {
    ".github/instructions/api-routes.instructions.md": "template/instructions/api-routes.instructions.md",
    ".github/instructions/config.instructions.md": "template/instructions/config.instructions.md",
    ".github/instructions/docs.instructions.md": "template/instructions/docs.instructions.md",
    ".github/prompts/commit-msg.prompt.md": "template/prompts/commit-msg.prompt.md",
    ".github/prompts/context-map.prompt.md": "template/prompts/context-map.prompt.md",
    ".github/prompts/explain.prompt.md": "template/prompts/explain.prompt.md",
    ".github/prompts/review-file.prompt.md": "template/prompts/review-file.prompt.md",
}
for repo_rel, template_rel in exact.items():
    repo_path = root / repo_rel
    template_path = root / template_rel
    if not repo_path.exists() or not template_path.exists():
        raise SystemExit(f"missing pair {repo_rel} {template_rel}")
    if not filecmp.cmp(repo_path, template_path, shallow=False):
        raise SystemExit(f"mismatch {repo_rel} {template_rel}")
'
echo ""

echo "5. Every developer instruction and prompt has a template counterpart"
assert_python "instruction and prompt template stubs exist" '
for kind, folder in [("instructions", "*.instructions.md"), ("prompts", "*.prompt.md")]:
    dev_dir = root / ".github" / kind
    tpl_dir = root / "template" / kind
    if not dev_dir.exists():
        continue
    for dev_file in sorted(dev_dir.glob(folder)):
        tpl_file = tpl_dir / dev_file.name
        if not tpl_file.exists():
            raise SystemExit(f"template/{kind}/{dev_file.name} missing (developer copy exists)")
'
echo ""

finish_tests
