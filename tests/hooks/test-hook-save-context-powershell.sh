#!/usr/bin/env bash
# tests/hooks/test-hook-save-context-powershell.sh -- unit tests for save-context.ps1
# Run: bash tests/hooks/test-hook-save-context-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/powershell-hook-test-helpers.sh
source "$(dirname "$0")/../lib/powershell-hook-test-helpers.sh"
init_powershell_hook_test_context "$0"
trap cleanup_dirs EXIT
ensure_pwsh_available

run_save_context_in_dir() {
  local dir="$1" payload="$2"
  (
    cd "$dir" || exit 1
    run_ps_script "$SAVE_CTX" "$payload"
  )
}

echo "=== save-context.ps1 (PowerShell) unit tests ==="
echo ""

echo "1. save-context.ps1 emits JSON and includes workspace summaries when present"
TMP_CTX=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CTX")
mkdir -p "$TMP_CTX/.copilot/workspace"
printf 'HEARTBEAT_OK\n' > "$TMP_CTX/.copilot/workspace/HEARTBEAT.md"
printf 'recent memory entry\n' > "$TMP_CTX/.copilot/workspace/MEMORY.md"
printf 'heuristic: verify before commit\n' > "$TMP_CTX/.copilot/workspace/SOUL.md"
output=$(run_save_context_in_dir "$TMP_CTX" '{}')
status=$?
assert_success "save-context exits zero" "$status"
assert_valid_json "save-context emits valid JSON" "$output"
assert_contains "save-context hookEventName present" "$output" "PreCompact"
assert_contains "save-context includes heartbeat" "$output" "HEARTBEAT_OK"
assert_contains "save-context includes memory summary" "$output" "recent memory entry"
assert_contains "save-context includes heuristics summary" "$output" "verify before commit"
echo ""

echo "2. save-context.ps1 includes clock summary when timing files exist"
TMP_CTX_CLOCK=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CTX_CLOCK")
mkdir -p "$TMP_CTX_CLOCK/.copilot/workspace"
printf 'HEARTBEAT_OK\n' > "$TMP_CTX_CLOCK/.copilot/workspace/HEARTBEAT.md"
cat > "$TMP_CTX_CLOCK/.copilot/workspace/state.json" <<'EOF'
{
  "session_id": "ps-clock",
  "session_state": "pending",
  "session_start_epoch": 1704067200
}
EOF
cat > "$TMP_CTX_CLOCK/.copilot/workspace/.heartbeat-events.jsonl" <<'EOF'
{"detail":"complete","duration_s":125,"trigger":"stop","ts":1704067325,"ts_utc":"2024-01-01T00:02:05Z"}
{"detail":"complete","duration_s":185,"trigger":"stop","ts":1704067485,"ts_utc":"2024-01-01T00:04:45Z"}
EOF
output=$(run_save_context_in_dir "$TMP_CTX_CLOCK" '{}')
assert_contains "save-context includes clock summary" "$output" "Clock:"
assert_contains "save-context includes active session id" "$output" "ps-clock"
assert_contains "save-context includes last completion UTC timestamp" "$output" "2024-01-01T00:04:45Z"
assert_contains "save-context includes median wording" "$output" "median of 2"
echo ""

finish_tests