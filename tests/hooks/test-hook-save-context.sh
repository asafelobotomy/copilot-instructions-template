#!/usr/bin/env bash
# tests/hooks/test-hook-save-context.sh -- unit tests for template/hooks/scripts/save-context.sh
# Run: bash tests/hooks/test-hook-save-context.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/template/hooks/scripts/save-context.sh"
trap cleanup_dirs EXIT

echo "=== save-context.sh ==="
echo ""

echo "1. Output is valid JSON and includes the compaction trigger when provided"
output=$(echo '{"trigger":"auto"}' | bash "$SCRIPT" 2>/dev/null)
assert_success "exits 0" $?
assert_valid_json "valid JSON output" "$output"
assert_matches "trigger label appears in context" "$output" "Trigger: auto"
echo ""

echo "2. Output contains hookEventName=PreCompact"
assert_matches "hookEventName present" "$output" "PreCompact"
echo ""

echo "3. HEARTBEAT.md content appears in additionalContext when present"
TMPDIR_CTX=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_CTX")
mkdir -p "$TMPDIR_CTX/.copilot/workspace"
printf 'HEARTBEAT_OK - all checks pass\n' > "$TMPDIR_CTX/.copilot/workspace/HEARTBEAT.md"
output=$(cd "$TMPDIR_CTX" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "heartbeat pulse in context" "$output" "HEARTBEAT"
echo ""

echo "4. No workspace files does not crash"
TMPDIR_EMPTY=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_EMPTY")
(
  cd "$TMPDIR_EMPTY" || exit
  echo '{}' | bash "$SCRIPT" 2>/dev/null
)
assert_success "no workspace files" $?
echo ""

echo "5. MEMORY.md table entries appear in additionalContext"
TMPDIR_MEM=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_MEM")
mkdir -p "$TMPDIR_MEM/.copilot/workspace"
printf 'HEARTBEAT: ok\n' > "$TMPDIR_MEM/.copilot/workspace/HEARTBEAT.md"
cat > "$TMPDIR_MEM/.copilot/workspace/MEMORY.md" <<'EOF'
# Memory Strategy

## Known Gotchas

| Gotcha | Affected files | Workaround | Severity |
|--------|---------------|------------|----------|
| Large commit batches hide failures | tests/ | Prefer smaller batches and rerun targeted suites | medium |
EOF
output=$(cd "$TMPDIR_MEM" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "MEMORY section label in context" "$output" "Known Gotchas"
assert_matches "MEMORY row content in context" "$output" "Prefer smaller batches"
assert_valid_json "valid JSON with MEMORY.md" "$output"
echo ""

echo "6. SOUL.md heuristics appear in additionalContext"
TMPDIR_SOUL=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_SOUL")
mkdir -p "$TMPDIR_SOUL/.copilot/workspace"
printf 'HEARTBEAT: ok\n' > "$TMPDIR_SOUL/.copilot/workspace/HEARTBEAT.md"
cat > "$TMPDIR_SOUL/.copilot/workspace/SOUL.md" <<'EOF'
# Values & Reasoning Patterns

- Keep changes reversible.

## Reasoning heuristics

- When uncertain, read the source.
- Prefer the smaller batch.
EOF
output=$(cd "$TMPDIR_SOUL" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "SOUL heuristics in context" "$output" "When uncertain, read the source"
assert_valid_json "valid JSON with SOUL.md" "$output"
echo ""

echo "7. Workspace summaries include additionalContext key"
TMPDIR_KEYS=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_KEYS")
mkdir -p "$TMPDIR_KEYS/.copilot/workspace"
printf 'HEARTBEAT: running\n' > "$TMPDIR_KEYS/.copilot/workspace/HEARTBEAT.md"
output=$(cd "$TMPDIR_KEYS" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "additionalContext key present" "$output" "additionalContext"
assert_matches "PreCompact hookEventName present" "$output" "PreCompact"

echo ""

echo "8. Clock summary appears when heartbeat timing files exist"
TMPDIR_CLOCK=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_CLOCK")
mkdir -p "$TMPDIR_CLOCK/.copilot/workspace"
printf 'HEARTBEAT: running\n' > "$TMPDIR_CLOCK/.copilot/workspace/HEARTBEAT.md"
cat > "$TMPDIR_CLOCK/.copilot/workspace/state.json" <<'EOF'
{
  "session_id": "sess-clock",
  "session_state": "pending",
  "session_start_epoch": 1704067200
}
EOF
cat > "$TMPDIR_CLOCK/.copilot/workspace/.heartbeat-events.jsonl" <<'EOF'
{"detail":"complete","duration_s":125,"trigger":"stop","ts":1704067325,"ts_utc":"2024-01-01T00:02:05Z"}
{"detail":"complete","duration_s":185,"trigger":"stop","ts":1704067485,"ts_utc":"2024-01-01T00:04:45Z"}
EOF
output=$(cd "$TMPDIR_CLOCK" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "clock summary key appears in context" "$output" "Clock:"
assert_matches "clock summary includes active session id" "$output" "sess-clock"
assert_matches "clock summary includes last completion UTC timestamp" "$output" "2024-01-01T00:04:45Z"
assert_matches "clock summary includes median wording" "$output" "median of 2"
echo ""

echo "9. Priority scoring surfaces highest-priority row from MEMORY.md"
TMPDIR_PRI=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_PRI")
mkdir -p "$TMPDIR_PRI/.copilot/workspace"
printf 'HEARTBEAT: ok\n' > "$TMPDIR_PRI/.copilot/workspace/HEARTBEAT.md"
cat > "$TMPDIR_PRI/.copilot/workspace/MEMORY.md" <<'EOF'
# Memory

## Metrics Freshness

| Metric | Last reviewed | Priority | Notes |
|--------|--------------|----------|-------|
| Low priority metric | 2026-01-01 | P3 | should not appear |
| Critical baseline | 2026-03-19 | P1 | this row wins |
| Medium metric | 2026-02-01 | P2 | also should not appear |
EOF
output=$(cd "$TMPDIR_PRI" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "P1 row appears in context" "$output" "Critical baseline"
if echo "$output" | grep -q "Low priority metric"; then
  fail_note "P3 row should be excluded by priority scoring"
else
  pass_note "P3 row excluded by priority"
fi
assert_valid_json "valid JSON with priority scoring" "$output"
echo ""

echo "10. Impact column scoring surfaces critical rows"
TMPDIR_IMP=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_IMP")
mkdir -p "$TMPDIR_IMP/.copilot/workspace"
printf 'HEARTBEAT: ok\n' > "$TMPDIR_IMP/.copilot/workspace/HEARTBEAT.md"
cat > "$TMPDIR_IMP/.copilot/workspace/MEMORY.md" <<'EOF'
# Memory

## Known Gotchas

| Gotcha | Impact | Notes |
|--------|--------|-------|
| Minor quirk | informational | low priority |
| Critical bug workaround | critical | this row wins |
EOF
output=$(cd "$TMPDIR_IMP" && echo '{}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "critical Impact row appears" "$output" "Critical bug workaround"
if echo "$output" | grep -q "Minor quirk"; then
  fail_note "informational row should be excluded by Impact scoring"
else
  pass_note "informational row excluded by Impact"
fi
assert_valid_json "valid JSON with Impact scoring" "$output"

finish_tests
