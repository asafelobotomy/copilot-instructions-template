#!/usr/bin/env bash
# tests/scripts/test-audit-release-settings.sh -- verify release governance audit behavior.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

trap cleanup_dirs EXIT

SCRIPT="$REPO_ROOT/scripts/release/audit-release-settings.sh"

make_fixture_dir() {
  local dir
  dir=$(mktemp -d)
  CLEANUP_DIRS+=("$dir")

  cat > "$dir/repo.json" <<'EOF_REPO'
{
  "allow_auto_merge": true,
  "allow_squash_merge": true
}
EOF_REPO

  cat > "$dir/workflow.json" <<'EOF_WORKFLOW'
{
  "can_approve_pull_request_reviews": true,
  "default_workflow_permissions": "read"
}
EOF_WORKFLOW

  cat > "$dir/rules.json" <<'EOF_RULES'
[
  {"type": "deletion"},
  {"type": "non_fast_forward"}
]
EOF_RULES

  echo "$dir"
}

run_script() {
  local fixture_dir="$1"
  shift
  RELEASE_SETTINGS_FIXTURE_DIR="$fixture_dir" bash "$SCRIPT" "$@" 2>&1
}

echo "=== Release governance audit behavior ==="
echo ""

echo "1. Lightweight ruleset profile passes cleanly"
fixture_dir=$(make_fixture_dir)
output=$(run_script "$fixture_dir" --repo asafelobotomy/copilot-instructions-template)
status=$?
assert_success "lightweight profile exits zero" "$status"
assert_contains "lightweight profile is marked compatible" "$output" "Result: compatible"
assert_contains "lightweight profile notes default read permissions" "$output" "Default workflow permissions are read-only"
echo ""

echo "2. Missing auto-merge fails the audit"
fixture_dir=$(make_fixture_dir)
cat > "$fixture_dir/repo.json" <<'EOF_REPO'
{
  "allow_auto_merge": false,
  "allow_squash_merge": true
}
EOF_REPO
output=$(run_script "$fixture_dir" --repo asafelobotomy/copilot-instructions-template) && status=0 || status=$?
assert_failure "missing auto-merge exits non-zero" "$status"
assert_contains "missing auto-merge is reported" "$output" "Repository auto-merge is disabled"
assert_contains "failure result is reported" "$output" "Result: incompatible with the current lightweight release workflow"
echo ""

echo "3. Required status checks produce caveats instead of a hard failure"
fixture_dir=$(make_fixture_dir)
cat > "$fixture_dir/rules.json" <<'EOF_RULES'
[
  {"type": "deletion"},
  {"type": "non_fast_forward"},
  {"type": "required_status_checks"}
]
EOF_RULES
output=$(run_script "$fixture_dir" --repo asafelobotomy/copilot-instructions-template)
status=$?
assert_success "required status checks still exit zero" "$status"
assert_contains "required status checks warning is reported" "$output" "Release PRs created with GITHUB_TOKEN will not trigger new workflows"
assert_contains "caveat result is reported" "$output" "Result: compatible with caveats"
echo ""

echo "4. Disabled GitHub Actions PR approval permission fails the audit"
fixture_dir=$(make_fixture_dir)
cat > "$fixture_dir/workflow.json" <<'EOF_WORKFLOW'
{
  "can_approve_pull_request_reviews": false,
  "default_workflow_permissions": "read"
}
EOF_WORKFLOW
output=$(run_script "$fixture_dir" --repo asafelobotomy/copilot-instructions-template) && status=0 || status=$?
assert_failure "missing workflow approval permission exits non-zero" "$status"
assert_contains "workflow permission error is reported" "$output" "GitHub Actions may not create and approve pull requests"
echo ""

finish_tests