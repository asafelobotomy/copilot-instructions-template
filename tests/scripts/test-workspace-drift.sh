#!/usr/bin/env bash
# tests/scripts/test-workspace-drift.sh -- tests for scripts/workspace/check-workspace-drift.sh
# Run: bash tests/scripts/test-workspace-drift.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/workspace/check-workspace-drift.sh"
trap cleanup_dirs EXIT

echo "=== check-workspace-drift.sh ==="
echo ""

echo "1. Workspace with current sentinels exits 0 and reports OK"
TMPDIR_OK=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_OK")
mkdir -p "$TMPDIR_OK/operations"
cat > "$TMPDIR_OK/operations/HEARTBEAT.md" <<'EOF'
## Response Contract
<!-- template-section: heartbeat-response-contract v2 -->
- Always append a History row when the trigger is Session start or Explicit — regardless of check results.
- For all other triggers, append a History row only if a check raised an alert or retrospective output was persisted to identity files.
- If checks pass and nothing was persisted on a non-explicit trigger, keep Pulse as `HEARTBEAT_OK` and omit the History row.
EOF
output=$(bash "$SCRIPT" "$TMPDIR_OK" 2>/dev/null)
status=$?
assert_success "current sentinels exit 0" "$status"
assert_matches "current sentinels reports OK" "$output" "^OK"
echo ""

echo "2. Workspace with the sentinel but stale response lines exits 1 and reports DRIFT_CONTENT"
TMPDIR_CONTENT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_CONTENT")
mkdir -p "$TMPDIR_CONTENT/operations"
cat > "$TMPDIR_CONTENT/operations/HEARTBEAT.md" <<'EOF'
## Response Contract
<!-- template-section: heartbeat-response-contract v2 -->
- Always append a History row when the trigger is Session start or Explicit.
- Omit the History row whenever checks pass.
EOF
output=$(bash "$SCRIPT" "$TMPDIR_CONTENT" 2>/dev/null) && status=0 || status=$?
assert_failure "stale response lines exit 1" "$status"
assert_matches "stale response lines report DRIFT_CONTENT" "$output" "^DRIFT_CONTENT"
echo ""

echo "3. Workspace missing sentinel exits 1 and reports DRIFT"
TMPDIR_DRIFT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_DRIFT")
mkdir -p "$TMPDIR_DRIFT/operations"
cat > "$TMPDIR_DRIFT/operations/HEARTBEAT.md" <<'EOF'
## Response Contract
- Always append a History row if all checks pass.
- Omit row if session start passes without alerts.
EOF
output=$(bash "$SCRIPT" "$TMPDIR_DRIFT" 2>/dev/null) && status=0 || status=$?
assert_failure "drifted sentinel exits 1" "$status"
assert_matches "drifted sentinel reports DRIFT" "$output" "^DRIFT"
echo ""

echo "4. Workspace missing the file entirely exits 1 and reports MISSING_FILE"
TMPDIR_MISSING=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_MISSING")
output=$(bash "$SCRIPT" "$TMPDIR_MISSING" 2>/dev/null) && status=0 || status=$?
assert_failure "missing file exits 1" "$status"
assert_matches "missing file reports MISSING_FILE" "$output" "^MISSING_FILE"
echo ""

echo "5. Repo own workspace passes the check (integration test)"
output=$(bash "$SCRIPT" "$REPO_ROOT/.copilot/workspace" 2>/dev/null)
status=$?
assert_success "repo workspace is up to date" "$status"
echo ""

echo "6. Script is executable"
[[ -x "$SCRIPT" ]] && test_rc=0 || test_rc=1
assert_success "check-workspace-drift.sh is executable" "$test_rc"
echo ""

finish_tests
