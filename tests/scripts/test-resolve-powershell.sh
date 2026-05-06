#!/usr/bin/env bash
# tests/scripts/test-resolve-powershell.sh -- deterministic tests for scripts/harness/resolve-powershell.sh
# Run: bash tests/scripts/test-resolve-powershell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
trap cleanup_dirs EXIT

SCRIPT="$REPO_ROOT/scripts/harness/resolve-powershell.sh"
BASH_BIN=$(command -v bash)

make_fake_powershell() {
  local dir="$1" name="$2" probe_rc="${3:-0}" probe_trace="${4:-}"
  local probe_trace_q=""
  if [[ -n "$probe_trace" ]]; then
    printf -v probe_trace_q '%q' "$probe_trace"
  fi
  cat > "$dir/$name" <<EOF
#!$BASH_BIN
PROBE_TRACE=$probe_trace_q
if [[ "\$1" == "-NoLogo" && "\$2" == "-NoProfile" && "\$3" == "-Command" && "\$4" == "exit 0" ]]; then
  if [[ -n "\$PROBE_TRACE" ]]; then
    printf 'probe\n' >> "\$PROBE_TRACE"
  fi
  exit $probe_rc
fi
exit 97
EOF
  chmod +x "$dir/$name"
}

run_resolver() {
  local path_override="$1"
  local env_pwsh="$2"
  local env_powershell="$3"
  shift 3
  PATH="$path_override" PWSH_BIN="$env_pwsh" POWERSHELL_BIN="$env_powershell" PWSH_RESOLUTION_DISABLE_CACHE=1 "$BASH_BIN" "$SCRIPT" "$@"
}

echo "=== resolve-powershell.sh ==="
echo ""

echo "1. Check mode fails when no PowerShell candidate exists"
EMPTY_BIN=$(mktemp -d)
CLEANUP_DIRS+=("$EMPTY_BIN")
if run_resolver "$EMPTY_BIN" "" "" --check >/dev/null 2>&1; then
  status=0
else
  status=$?
fi
assert_failure "--check exits non-zero without candidates" "$status"
echo ""

echo "2. pwsh is preferred when it is present and functional"
PWSH_FIRST=$(mktemp -d)
CLEANUP_DIRS+=("$PWSH_FIRST")
make_fake_powershell "$PWSH_FIRST" "pwsh" 0
make_fake_powershell "$PWSH_FIRST" "powershell" 0
output=$(run_resolver "$PWSH_FIRST" "" "")
status=$?
assert_success "resolver exits zero for working pwsh" "$status"
assert_matches "resolver returns pwsh path" "$output" '/pwsh$'
echo ""

echo "3. powershell is used when pwsh is absent"
POWERSHELL_ONLY=$(mktemp -d)
CLEANUP_DIRS+=("$POWERSHELL_ONLY")
make_fake_powershell "$POWERSHELL_ONLY" "powershell" 0
output=$(run_resolver "$POWERSHELL_ONLY" "" "")
status=$?
assert_success "resolver exits zero for working powershell" "$status"
assert_matches "resolver returns powershell path" "$output" '/powershell$'
echo ""

echo "4. Broken pwsh is skipped in favor of working powershell"
BROKEN_FIRST=$(mktemp -d)
CLEANUP_DIRS+=("$BROKEN_FIRST")
make_fake_powershell "$BROKEN_FIRST" "pwsh" 1
make_fake_powershell "$BROKEN_FIRST" "powershell" 0
output=$(run_resolver "$BROKEN_FIRST" "" "")
status=$?
assert_success "resolver skips broken pwsh" "$status"
assert_matches "fallback resolves to powershell" "$output" '/powershell$'
echo ""

echo "5. PWSH_BIN absolute-path override wins when valid"
OVERRIDE_BIN=$(mktemp -d)
CLEANUP_DIRS+=("$OVERRIDE_BIN")
make_fake_powershell "$OVERRIDE_BIN" "custom-pwsh" 0
output=$(run_resolver "$EMPTY_BIN" "$OVERRIDE_BIN/custom-pwsh" "")
status=$?
assert_success "absolute override exits zero" "$status"
assert_contains "absolute override path is returned" "$output" "$OVERRIDE_BIN/custom-pwsh"
echo ""

echo "6. POWERSHELL_BIN command-name override resolves via PATH"
NAMED_OVERRIDE=$(mktemp -d)
CLEANUP_DIRS+=("$NAMED_OVERRIDE")
make_fake_powershell "$NAMED_OVERRIDE" "my-powershell" 0
output=$(run_resolver "$NAMED_OVERRIDE" "" "my-powershell")
status=$?
assert_success "named override exits zero" "$status"
assert_matches "named override path is returned" "$output" '/my-powershell$'
echo ""

echo "7. Failed probes are cached to avoid repeated retries"
CACHE_DIR=$(mktemp -d)
CLEANUP_DIRS+=("$CACHE_DIR")
BROKEN_ONLY="$CACHE_DIR/broken-only"
mkdir -p "$BROKEN_ONLY"
PROBE_LOG="$CACHE_DIR/probe.log"
CACHE_FILE="$CACHE_DIR/resolve.cache"
make_fake_powershell "$BROKEN_ONLY" "pwsh" 1 "$PROBE_LOG"

if PATH="$BROKEN_ONLY" PWSH_BIN="" POWERSHELL_BIN="" PWSH_RESOLUTION_CACHE_FILE="$CACHE_FILE" "$BASH_BIN" "$SCRIPT" --check >/dev/null 2>&1; then
  status=0
else
  status=$?
fi
assert_failure "first cached check exits non-zero" "$status"

if PATH="$BROKEN_ONLY" PWSH_BIN="" POWERSHELL_BIN="" PWSH_RESOLUTION_CACHE_FILE="$CACHE_FILE" "$BASH_BIN" "$SCRIPT" --check >/dev/null 2>&1; then
  status=0
else
  status=$?
fi
assert_failure "second cached check exits non-zero" "$status"

probe_count=0
if [[ -f "$PROBE_LOG" ]]; then
  probe_count=$(wc -l < "$PROBE_LOG")
fi
if [[ "$probe_count" == "1" ]]; then
  pass_note "broken pwsh is probed only once per cache window"
else
  fail_note "broken pwsh is probed only once per cache window" "     expected 1 probe, saw: $probe_count"
fi
echo ""

finish_tests