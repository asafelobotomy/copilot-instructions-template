#!/usr/bin/env bash
# tests/hooks/test-heartbeat-clock-summary.sh -- unit tests for heartbeat_clock_summary.py
# Run: bash tests/hooks/test-heartbeat-clock-summary.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/template/hooks/scripts/heartbeat_clock_summary.py"
trap cleanup_dirs EXIT

run_summary() {
  local workspace="$1"
  python3 "$SCRIPT" "$workspace" 2>/dev/null
}

echo "=== heartbeat_clock_summary.py ==="
echo ""

echo "1. Missing workspace files return an empty summary"
TMP_EMPTY=$(mktemp -d); CLEANUP_DIRS+=("$TMP_EMPTY")
output=$(run_summary "$TMP_EMPTY")
status=$?
assert_success "empty workspace exits zero" "$status"
if [[ -z "$output" ]]; then
  pass_note "empty workspace emits no summary"
else
  fail_note "empty workspace emits no summary" "     output: $output"
fi
echo ""

echo "2. Active sessions and completed events produce a stable summary"
TMP_CLOCK=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CLOCK")
mkdir -p "$TMP_CLOCK/runtime"
cat > "$TMP_CLOCK/runtime/state.json" <<'EOF'
{
  "session_id": "sess-clock",
  "session_state": "pending",
  "session_start_epoch": 1704067200
}
EOF
cat > "$TMP_CLOCK/runtime/.heartbeat-events.jsonl" <<'EOF'
{"detail":"complete","duration_s":125,"trigger":"stop","ts":1704067325,"ts_utc":"2024-01-01T00:02:05Z"}
{"detail":"complete","duration_s":185,"trigger":"stop","ts":1704067485,"ts_utc":"2024-01-01T00:04:45Z"}
EOF
output=$(run_summary "$TMP_CLOCK")
status=$?
assert_success "clock summary exits zero" "$status"
assert_contains "active session is reported" "$output" 'session sess-clock active for'
assert_contains "session start timestamp is reported" "$output" 'since 2024-01-01T00:00:00Z UTC'
assert_contains "even-count median is reported" "$output" 'typical session 2m 35s (median of 2)'
assert_contains "last completed session timestamp is reported" "$output" 'last completed session ended 2024-01-01T00:04:45Z after 3m 5s'
echo ""

echo "3. Corrupt state and malformed event lines are ignored safely"
TMP_CORRUPT=$(mktemp -d); CLEANUP_DIRS+=("$TMP_CORRUPT")
mkdir -p "$TMP_CORRUPT/runtime"
printf '{broken-json\n' > "$TMP_CORRUPT/runtime/state.json"
cat > "$TMP_CORRUPT/runtime/.heartbeat-events.jsonl" <<'EOF'
not-json
{"detail":"complete","duration_s":45,"trigger":"stop","ts":1704067400,"ts_utc":"2024-01-01T00:03:20Z"}
EOF
output=$(run_summary "$TMP_CORRUPT")
status=$?
assert_success "corrupt workspace exits zero" "$status"
assert_contains "valid event lines still contribute to the summary" "$output" 'typical session 45s (median of 1)'
echo ""

echo "4. Long summaries are capped to the configured maximum length"
TMP_LONG=$(mktemp -d); CLEANUP_DIRS+=("$TMP_LONG")
mkdir -p "$TMP_LONG/runtime"
LONG_ID=$(python3 - <<'PY'
print('session-' + 'x' * 600)
PY
)
cat > "$TMP_LONG/runtime/state.json" <<EOF
{
  "session_id": "$LONG_ID",
  "session_state": "pending",
  "session_start_epoch": 1704067200
}
EOF
output=$(run_summary "$TMP_LONG")
status=$?
assert_success "long-summary workspace exits zero" "$status"
if [[ ${#output} -le 400 ]]; then
  pass_note "summary length is capped at 400 characters"
else
  fail_note "summary length is capped at 400 characters" "     length: ${#output}"
fi
echo ""

finish_tests