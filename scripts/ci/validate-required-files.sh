#!/usr/bin/env bash
# scripts/ci/validate-required-files.sh — assert all required repo files are present.
# Called from CI workflow. Exit 0 = all present, exit 1 = missing files.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
WORKSPACE_INDEX_PATH="$ROOT_DIR/.copilot/workspace/workspace-index.json"
if [[ ! -f "$WORKSPACE_INDEX_PATH" ]]; then
  WORKSPACE_INDEX_PATH="$ROOT_DIR/template/workspace/workspace-index.json"
fi

required_files=(
  ".github/copilot-instructions.md"
  "SETUP.md"
  "UPDATE.md"
  "MIGRATION.md"
  "MIGRATION.archive.md"
  "AGENTS.md"
  "VERSION.md"
  "CHANGELOG.md"
  "scripts/release/plan-release.sh"
  "scripts/release/stub-migration.sh"
  "scripts/release/sync-version.sh"
  "scripts/tests/run-all-captured.sh"
  "scripts/tests/suite-manifest.json"
  "scripts/tests/suite-manifest.py"
  "scripts/workspace/check-workspace-drift.sh"
  "scripts/workspace/sync-workspace-index.sh"
  "scripts/sync/sync-models.sh"
  "scripts/sync/sync_models.py"
  "scripts/sync/sync-template-parity.sh"
  "scripts/validate/validate-agent-frontmatter.sh"
  "scripts/lib.sh"
  "MODELS.md"
  "CLAUDE.md"
  "llms.txt"
  "starter-kits/REGISTRY.json"
  ".copilot/workspace/workspace-index.json"
  "template/copilot-instructions.md"
  "template/copilot-setup-steps.yml"
  "template/CHANGELOG.md"
  "template/CLAUDE.md"
  "template/setup/interview.md"
  "template/setup/manifests.md"
  "template/instructions/api-routes.instructions.md"
  "template/instructions/config.instructions.md"
  "template/instructions/docs.instructions.md"
  "template/instructions/tests.instructions.md"
  "template/prompts/refactor.prompt.md"
  "template/prompts/test-gen.prompt.md"
  "template/prompts/commit-msg.prompt.md"
  "template/prompts/context-map.prompt.md"
  "template/prompts/explain.prompt.md"
  "template/prompts/review-file.prompt.md"
  "template/prompts/onboard-commit-style.prompt.md"
  "template/vscode/mcp.json"
  "template/vscode/settings.json"
  "template/vscode/extensions.json"
  "template/hooks/copilot-hooks.json"
  "template/workspace/IDENTITY.md"
  "template/workspace/SOUL.md"
  "template/workspace/USER.md"
  "template/workspace/TOOLS.md"
  "template/workspace/MEMORY.md"
  "template/workspace/commit-style.md"
  "template/workspace/workspace-index.json"
  "template/workspace/BOOTSTRAP.md"
  "template/workspace/HEARTBEAT.md"
  "template/workspace/RESEARCH.md"
)

if [[ -f "$WORKSPACE_INDEX_PATH" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ Missing required command: python3"
    exit 1
  fi

  while IFS= read -r relative_path; do
    [[ -n "$relative_path" ]] || continue
    required_files+=("$relative_path")
  done < <(
    python3 - "$WORKSPACE_INDEX_PATH" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)

for name in payload.get("agents", []):
    print(f".github/agents/{name}")

for name in payload.get("skills", {}).get("repo", []):
    print(f".github/skills/{name}/SKILL.md")

for name in payload.get("skills", {}).get("template", []):
    print(f"template/skills/{name}/SKILL.md")

for names in payload.get("hookScripts", {}).values():
    for name in names:
        print(f"template/hooks/scripts/{name}")
PY
  )
fi

missing=0
for f in "${required_files[@]}"; do
  if [[ ! -f "$ROOT_DIR/$f" ]]; then
    echo "❌ Missing: $f"
    missing=1
  fi
done
[[ $missing -eq 0 ]] || exit 1
echo "✅ All required files present"
