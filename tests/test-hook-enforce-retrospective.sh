#!/usr/bin/env bash
# tests/test-hook-enforce-retrospective.sh -- unit tests for template/hooks/scripts/enforce-retrospective.sh
# Run: bash tests/test-hook-enforce-retrospective.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/template/hooks/scripts/enforce-retrospective.sh"
trap cleanup_dirs EXIT

echo "=== enforce-retrospective.sh ==="
echo ""

echo "1. stop_hook_active=true passes through immediately"
output=$(printf '{"stop_hook_active": true}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "stop_hook_active=true continues" "$output" '"continue": true'
assert_valid_json "valid JSON on active hook" "$output"
echo ""

echo "2. No transcript blocks the stop"
TMPDIR_NO_TX=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_NO_TX")
output=$(cd "$TMPDIR_NO_TX" && printf '{"stop_hook_active": false}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "no transcript blocks" "$output" '"decision": "block"'
assert_valid_json "valid JSON on block" "$output"
echo ""

echo "3. Transcript with retrospective keyword passes through"
TMPDIR_RETRO=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_RETRO")
TRANSCRIPT="$TMPDIR_RETRO/transcript.txt"
printf 'The agent ran the retrospective successfully.\n' > "$TRANSCRIPT"
output=$(printf '{"stop_hook_active": false, "transcript_path": "%s"}' "$TRANSCRIPT" | bash "$SCRIPT" 2>/dev/null)
assert_matches "retrospective keyword continues" "$output" '"continue": true'
echo ""

echo "4. Fresh HEARTBEAT.md passes through"
TMPDIR_HB=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_HB")
mkdir -p "$TMPDIR_HB/.copilot/workspace"
touch "$TMPDIR_HB/.copilot/workspace/HEARTBEAT.md"
output=$(cd "$TMPDIR_HB" && printf '{"stop_hook_active": false}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "fresh heartbeat continues" "$output" '"continue": true'
echo ""

echo "5. Malformed JSON input does not crash"
echo 'not-json' | bash "$SCRIPT" 2>/dev/null
assert_success "malformed JSON" $?
echo ""

echo "6. Transcript without retrospective keyword still blocks"
TMPDIR_NO_RETRO=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_NO_RETRO")
TRANSCRIPT_NORETRO="$TMPDIR_NO_RETRO/transcript.txt"
printf 'The agent coded features and committed changes.\n' > "$TRANSCRIPT_NORETRO"
output=$(cd "$TMPDIR_NO_RETRO" && printf '{"stop_hook_active": false, "transcript_path": "%s"}' "$TRANSCRIPT_NORETRO" | bash "$SCRIPT" 2>/dev/null)
assert_matches "missing retrospective keyword blocks" "$output" '"decision": "block"'
assert_valid_json "valid JSON when blocking" "$output"
echo ""

echo "7. Stale HEARTBEAT.md blocks"
TMPDIR_STALE=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_STALE")
mkdir -p "$TMPDIR_STALE/.copilot/workspace"
STALE_HB="$TMPDIR_STALE/.copilot/workspace/HEARTBEAT.md"
touch "$STALE_HB"
touch -d "130 minutes ago" "$STALE_HB" 2>/dev/null \
  || python3 -c "import os,time; os.utime('$STALE_HB', (time.time()-7800, time.time()-7800))" 2>/dev/null \
  || true
output=$(cd "$TMPDIR_STALE" && printf '{"stop_hook_active": false}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "stale heartbeat blocks" "$output" '"decision": "block"'

echo ""

echo "8. Sentinel pending blocks and sentinel complete passes"
TMPDIR_SENT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_SENT")
mkdir -p "$TMPDIR_SENT/.copilot/workspace"
printf 'abc|2026-03-30T00:00:00Z|pending\n' > "$TMPDIR_SENT/.copilot/workspace/.heartbeat-session"
output=$(cd "$TMPDIR_SENT" && printf '{"stop_hook_active": false}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "pending sentinel blocks" "$output" '"decision": "block"'
printf 'abc|2026-03-30T00:00:00Z|complete\n' > "$TMPDIR_SENT/.copilot/workspace/.heartbeat-session"
output=$(cd "$TMPDIR_SENT" && printf '{"stop_hook_active": false}' | bash "$SCRIPT" 2>/dev/null)
assert_matches "complete sentinel continues" "$output" '"continue": true'

finish_tests
