#!/usr/bin/env bash
# scripts/ci/validate-required-files.sh — assert all required repo files are present.
# Called from CI workflow. Exit 0 = all present, exit 1 = missing files.
set -euo pipefail

missing=0
for f in \
  ".github/copilot-instructions.md" \
  ".github/agents/setup.agent.md" \
  ".github/agents/coding.agent.md" \
  ".github/agents/organise.agent.md" \
  ".github/agents/review.agent.md" \
  ".github/agents/fast.agent.md" \
  ".github/agents/audit.agent.md" \
  ".github/agents/explore.agent.md" \
  ".github/agents/extensions.agent.md" \
  ".github/agents/researcher.agent.md" \
  ".github/agents/commit.agent.md" \
  "SETUP.md" "UPDATE.md" "MIGRATION.md" "MIGRATION.archive.md" "AGENTS.md" "VERSION.md" "CHANGELOG.md" \
  "scripts/release/plan-release.sh" \
  "scripts/release/stub-migration.sh" \
  "scripts/release/sync-version.sh" \
  "scripts/workspace/check-workspace-drift.sh" \
  "scripts/workspace/sync-workspace-index.sh" \
  "scripts/sync/sync-models.sh" \
  "scripts/sync/sync_models.py" \
  "scripts/sync/sync-template-parity.sh" \
  "scripts/validate/validate-agent-frontmatter.sh" \
  "scripts/lib.sh" \
  "MODELS.md" \
  "CLAUDE.md" \
  "llms.txt" \
  "starter-kits/REGISTRY.json" \
  ".copilot/workspace/workspace-index.json" \
  "template/copilot-instructions.md" \
  "template/instructions/tests.instructions.md" \
  "template/prompts/refactor.prompt.md" \
  "template/prompts/test-gen.prompt.md" \
  "template/prompts/commit-msg.prompt.md" \
  "template/prompts/context-map.prompt.md" \
  "template/prompts/explain.prompt.md" \
  "template/prompts/review-file.prompt.md" \
  "template/prompts/onboard-commit-style.prompt.md" \
  "template/instructions/api-routes.instructions.md" \
  "template/instructions/config.instructions.md" \
  "template/instructions/docs.instructions.md" \
  "template/copilot-setup-steps.yml" \
  "template/vscode/mcp.json" \
  "template/vscode/settings.json" \
  "template/hooks/copilot-hooks.json" \
  "template/hooks/scripts/lib-hooks.sh" \
  "template/hooks/scripts/scan-secrets.sh" \
  "template/hooks/scripts/session-start.sh" \
  "template/hooks/scripts/guard-destructive.sh" \
  "template/hooks/scripts/post-edit-lint.sh" \
  "template/hooks/scripts/save-context.sh" \
  "template/hooks/scripts/subagent-start.sh" \
  "template/hooks/scripts/subagent-stop.sh" \
  "template/hooks/scripts/mcp-npx.sh" \
  "template/hooks/scripts/mcp-uvx.sh" \
  "template/hooks/scripts/pulse.sh" \
  "template/hooks/scripts/heartbeat-policy.json" \
  "template/hooks/scripts/heartbeat_clock_summary.py" \
  "template/hooks/scripts/session-start.ps1" \
  "template/hooks/scripts/post-edit-lint.ps1" \
  "template/hooks/scripts/save-context.ps1" \
  "template/hooks/scripts/scan-secrets.ps1" \
  "template/hooks/scripts/guard-destructive.ps1" \
  "template/hooks/scripts/subagent-start.ps1" \
  "template/hooks/scripts/subagent-stop.ps1" \
  "template/hooks/scripts/pulse.ps1" \
  "template/CHANGELOG.md" \
  "template/CLAUDE.md" \
  "template/workspace/IDENTITY.md" "template/workspace/SOUL.md" \
  "template/workspace/USER.md" "template/workspace/TOOLS.md" \
  "template/workspace/MEMORY.md" "template/workspace/workspace-index.json" "template/workspace/BOOTSTRAP.md" \
  "template/workspace/HEARTBEAT.md" "template/workspace/RESEARCH.md" "template/workspace/commit-style.md" \
  "template/vscode/extensions.json"; do
  if [[ ! -f "$f" ]]; then
    echo "❌ Missing: $f"; missing=1
  fi
done
[[ $missing -eq 0 ]] || exit 1
echo "✅ All required files present"
