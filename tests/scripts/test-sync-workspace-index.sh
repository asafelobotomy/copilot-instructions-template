#!/usr/bin/env bash
# tests/scripts/test-sync-workspace-index.sh -- direct tests for scripts/workspace/sync-workspace-index.sh
# Run: bash tests/scripts/test-sync-workspace-index.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/workspace/sync-workspace-index.sh"
trap cleanup_dirs EXIT

make_fixture() {
  local root="$1"
  mkdir -p \
    "$root/.copilot/workspace/identity" \
    "$root/.copilot/workspace/knowledge/diaries" \
    "$root/.copilot/workspace/operations" \
    "$root/.copilot/workspace/runtime" \
    "$root/.github/agents" \
    "$root/.github/skills/skill-creator" \
    "$root/.github/skills/extension-review" \
    "$root/.github/skills/zzz-extra" \
    "$root/template/instructions" \
    "$root/template/prompts" \
    "$root/template/skills/skill-creator" \
    "$root/template/skills/test-coverage-review" \
    "$root/template/skills/aaa-extra" \
    "$root/template/workspace/identity" \
    "$root/template/workspace/knowledge/diaries" \
    "$root/template/workspace/operations" \
    "$root/template/hooks/scripts"

  : > "$root/.github/agents/setup.agent.md"
  : > "$root/.github/agents/review.agent.md"
  : > "$root/.github/agents/z-last.agent.md"
  : > "$root/.github/agents/routing-manifest.json"

  printf 'name: skill-creator\ndescription: test\n' > "$root/.github/skills/skill-creator/SKILL.md"
  printf 'name: extension-review\ndescription: test\n' > "$root/.github/skills/extension-review/SKILL.md"
  printf 'name: zzz-extra\ndescription: test\n' > "$root/.github/skills/zzz-extra/SKILL.md"

  printf 'name: skill-creator\ndescription: test\n' > "$root/template/skills/skill-creator/SKILL.md"
  printf 'name: test-coverage-review\ndescription: test\n' > "$root/template/skills/test-coverage-review/SKILL.md"
  printf 'name: aaa-extra\ndescription: test\n' > "$root/template/skills/aaa-extra/SKILL.md"

  : > "$root/template/instructions/api-routes.instructions.md"
  : > "$root/template/instructions/tests.instructions.md"
  : > "$root/template/prompts/commit-msg.prompt.md"
  : > "$root/template/prompts/review-file.prompt.md"
  : > "$root/template/workspace/identity/BOOTSTRAP.md"
  : > "$root/template/workspace/knowledge/TOOLS.md"
  : > "$root/template/workspace/knowledge/diaries/README.md"
  : > "$root/template/copilot-setup-steps.yml"

  : > "$root/template/hooks/scripts/session-start.sh"
  : > "$root/template/hooks/scripts/guard-destructive.sh"
  : > "$root/template/hooks/scripts/save-context.sh"
  : > "$root/template/hooks/scripts/session-start.ps1"
  : > "$root/template/hooks/scripts/guard-destructive.ps1"
  : > "$root/template/hooks/scripts/save-context.ps1"
  : > "$root/template/hooks/scripts/heartbeat-policy.json"
  : > "$root/template/hooks/scripts/heartbeat_clock_summary.py"
  : > "$root/template/hooks/scripts/mcp-heartbeat-server.py"
  : > "$root/template/hooks/scripts/pulse_runtime.py"

  cat > "$root/template/workspace/operations/workspace-index.json" <<'EOF'
{
  "$schema": "https://example.test/workspace-index.schema.json",
  "schemaVersion": "1.0",
  "updated": "2026-04-03",
  "purpose": "fixture",
  "counts": {
    "agents": 2,
    "agentSupportFiles": 1,
    "skillsRepo": 2,
    "skillsTemplate": 2,
    "hookScriptsShell": 3,
    "hookScriptsPowerShell": 3,
    "hookScriptsPython": 2,
    "hookScriptsJson": 1
  },
  "agents": [
    "setup.agent.md",
    "review.agent.md"
  ],
  "agentSupportFiles": [
    "routing-manifest.json"
  ],
  "skills": {
    "repo": [
      "skill-creator",
      "extension-review"
    ],
    "template": [
      "skill-creator",
      "test-coverage-review"
    ]
  },
  "prompts": [
    "commit-msg.prompt.md",
    "review-file.prompt.md"
  ],
  "instructions": [
    "api-routes.instructions.md",
    "tests.instructions.md"
  ],
  "workspaceFiles": [
    "identity/BOOTSTRAP.md",
    "knowledge/TOOLS.md",
    "operations/workspace-index.json"
  ],
  "workflowFiles": [
    "copilot-setup-steps.yml"
  ],
  "hookScripts": {
    "shell": [
      "session-start.sh",
      "guard-destructive.sh",
      "save-context.sh"
    ],
    "powershell": [
      "session-start.ps1",
      "guard-destructive.ps1",
      "save-context.ps1"
    ],
    "python": [
      "heartbeat_clock_summary.py",
      "mcp-heartbeat-server.py"
    ],
    "json": [
      "heartbeat-policy.json"
    ]
  },
  "notes": [
    "fixture baseline"
  ]
}
EOF
}

echo "=== sync-workspace-index.sh direct tests ==="
echo ""

echo "1. Invalid mode is rejected"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" --wat 2>&1)
status=$?
assert_failure "invalid mode exits non-zero" "$status"
assert_contains "invalid mode prints usage" "$output" "Usage: bash scripts/workspace/sync-workspace-index.sh"
echo ""

echo "2. Missing workspace-index.json in check mode fails with repair hint"
TMP_MISSING=$(mktemp -d); CLEANUP_DIRS+=("$TMP_MISSING")
make_fixture "$TMP_MISSING"
output=$(ROOT_DIR="$TMP_MISSING" bash "$SCRIPT" --check 2>&1)
status=$?
assert_failure "missing workspace-index exits non-zero" "$status"
assert_contains "missing workspace-index is reported" "$output" "FAIL: missing"
assert_contains "repair hint is printed" "$output" "Run: bash scripts/workspace/sync-workspace-index.sh --write"
echo ""

echo "3. Write mode creates a valid canonical index"
TMP_WRITE=$(mktemp -d); CLEANUP_DIRS+=("$TMP_WRITE")
make_fixture "$TMP_WRITE"
output=$(ROOT_DIR="$TMP_WRITE" bash "$SCRIPT" --write 2>&1)
status=$?
assert_success "write mode exits zero" "$status"
assert_contains "write mode reports repo target" "$output" ".copilot/workspace/operations/workspace-index.json"
assert_contains "write mode reports template target" "$output" "template/workspace/operations/workspace-index.json"
assert_python_in_root "workspace-index.json is valid JSON" "$TMP_WRITE" "
path = root / '.copilot/workspace/operations/workspace-index.json'
json.load(path.open())
"
assert_python_in_root "template workspace-index.json is valid JSON" "$TMP_WRITE" "
path = root / 'template/workspace/operations/workspace-index.json'
json.load(path.open())
"
assert_python_in_root "counts match fixture contents" "$TMP_WRITE" "
for rel in ('.copilot/workspace/operations/workspace-index.json', 'template/workspace/operations/workspace-index.json'):
  data = json.load((root / rel).open())
  assert data['counts']['agents'] == 3
  assert data['counts']['agentSupportFiles'] == 1
  assert data['counts']['skillsRepo'] == 3
  assert data['counts']['skillsTemplate'] == 3
  assert data['counts']['hookScriptsShell'] == 3
  assert data['counts']['hookScriptsPowerShell'] == 3
  assert data['counts']['hookScriptsPython'] == 3
  assert data['counts']['hookScriptsJson'] == 1
"
assert_python_in_root "baseline order is preserved and extras sort after it" "$TMP_WRITE" "
for rel in ('.copilot/workspace/operations/workspace-index.json', 'template/workspace/operations/workspace-index.json'):
  data = json.load((root / rel).open())
  assert data['agents'] == ['setup.agent.md', 'review.agent.md', 'z-last.agent.md']
  assert data['agentSupportFiles'] == ['routing-manifest.json']
  assert data['skills']['repo'] == ['skill-creator', 'extension-review', 'zzz-extra']
  assert data['skills']['template'] == ['skill-creator', 'test-coverage-review', 'aaa-extra']
  assert data['prompts'] == ['commit-msg.prompt.md', 'review-file.prompt.md']
  assert data['instructions'] == ['api-routes.instructions.md', 'tests.instructions.md']
  assert data['workspaceFiles'] == ['identity/BOOTSTRAP.md', 'knowledge/TOOLS.md', 'operations/workspace-index.json', 'knowledge/diaries/README.md']
  assert data['workflowFiles'] == ['copilot-setup-steps.yml']
  assert data['hookScripts']['shell'] == ['session-start.sh', 'guard-destructive.sh', 'save-context.sh']
  assert data['hookScripts']['powershell'] == ['session-start.ps1', 'guard-destructive.ps1', 'save-context.ps1']
  assert data['hookScripts']['python'] == ['heartbeat_clock_summary.py', 'mcp-heartbeat-server.py', 'pulse_runtime.py']
  assert data['hookScripts']['json'] == ['heartbeat-policy.json']
"
assert_python_in_root "repo and template indices match exactly" "$TMP_WRITE" "
repo_data = json.load((root / '.copilot/workspace/operations/workspace-index.json').open())
template_data = json.load((root / 'template/workspace/operations/workspace-index.json').open())
assert repo_data == template_data
"
echo ""

echo "4. Check mode passes when file is in sync"
output=$(ROOT_DIR="$TMP_WRITE" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "check mode passes on synced file" "$status"
assert_contains "check mode success message" "$output" "OK: workspace-index.json files are in sync"
echo ""

echo "5. Drift is detected after manual modification"
python3 - "$TMP_WRITE/.copilot/workspace/operations/workspace-index.json" <<'PY'
import json
import sys
path = sys.argv[1]
with open(path, encoding='utf-8') as fh:
    data = json.load(fh)
data['skills']['repo'].append('rogue-skill')
with open(path, 'w', encoding='utf-8') as fh:
    json.dump(data, fh, indent=2)
    fh.write('\n')
PY
output=$(ROOT_DIR="$TMP_WRITE" bash "$SCRIPT" --check 2>&1)
status=$?
assert_failure "check mode fails on drift" "$status"
assert_contains "drift message is printed" "$output" ".copilot/workspace/operations/workspace-index.json is out of sync"
assert_contains "drift includes repair hint" "$output" "Run: bash scripts/workspace/sync-workspace-index.sh --write"
echo ""

echo "6. Write mode repairs the drifted file"
output=$(ROOT_DIR="$TMP_WRITE" bash "$SCRIPT" --write 2>&1)
status=$?
assert_success "write repairs drift" "$status"
output=$(ROOT_DIR="$TMP_WRITE" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "check passes after repair" "$status"
echo ""

echo "7. Real repo and template indices stay aligned"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "real repo indices are in sync" "$status"
assert_contains "real repo reports both indices are in sync" "$output" "OK: workspace-index.json files are in sync"
echo ""

finish_tests
