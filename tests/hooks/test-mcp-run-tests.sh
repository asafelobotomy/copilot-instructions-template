#!/usr/bin/env bash
# tests/hooks/test-mcp-run-tests.sh -- unit tests for the run_tests MCP tool
#   in hooks/scripts/mcp-heartbeat-server.py
# Run: bash tests/hooks/test-mcp-run-tests.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
trap cleanup_dirs EXIT

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Call run_tests by importing the server module directly (avoids MCP transport
# overhead and does not require the mcp package to be installed at test time).
call_run_tests() {
  python3 - "$@" <<'PYEOF'
import sys, os, json, pathlib

repo_root = pathlib.Path(os.environ.get("HEARTBEAT_WORKSPACE", ".")).resolve()
os.chdir(repo_root)
sys.path.insert(0, str(repo_root / "hooks" / "scripts"))

# Minimal stub so the heartbeat lib resolves workspace paths to our fixture.
import importlib, types

# Parse CLI args: --files f1 f2 --mode m
args = sys.argv[1:]
files = []
mode = "targeted"
i = 0
while i < len(args):
    if args[i] == "--files":
        i += 1
        while i < len(args) and not args[i].startswith("--"):
            files.append(args[i])
            i += 1
    elif args[i] == "--mode":
        mode = args[i + 1]
        i += 2
    else:
        i += 1

# Import the function under test by loading the server module with mcp stubbed.
import unittest.mock as mock

# Stub out the mcp package so the server loads without the real dependency.
fake_mcp_mod = types.ModuleType("mcp")
fake_fastmcp_mod = types.ModuleType("mcp.server.fastmcp")
class _FakeFastMCP:
    def __init__(self, *a, **k): pass
    def tool(self):
        def decorator(fn): return fn
        return decorator
    def run(self): pass
fake_fastmcp_mod.FastMCP = _FakeFastMCP
sys.modules.setdefault("mcp", fake_mcp_mod)
sys.modules.setdefault("mcp.server", types.ModuleType("mcp.server"))
sys.modules.setdefault("mcp.server.fastmcp", fake_fastmcp_mod)

# Also stub ensure_writable_tempdir so we can import cleanly.
with mock.patch.dict(os.environ, {"HEARTBEAT_WORKSPACE": str(repo_root)}):
    import mcp_heartbeat_lib  # noqa: F401 — side-effects needed
    mcp_heartbeat_lib.ensure_writable_tempdir = lambda: None

    import importlib.util as ilu
    spec = ilu.spec_from_file_location(
        "mcp_heartbeat_server",
        str(repo_root / "hooks" / "scripts" / "mcp-heartbeat-server.py"),
    )
    mod = ilu.module_from_spec(spec)
    spec.loader.exec_module(mod)

result = mod.run_tests(files=files if files else None, mode=mode)
print(json.dumps(result, indent=2))
PYEOF
}

echo "=== mcp-heartbeat-server.py run_tests tool ==="
echo ""

# ---------------------------------------------------------------------------
# Test 1 — targeted run, single passing suite
# ---------------------------------------------------------------------------
echo "1. Targeted run of a single suite that passes"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_run_tests \
  --mode targeted \
  --files "tests/hooks/test-heartbeat-clock-summary.sh" 2>&1)
status=$?
assert_success "call exits zero" "$status"
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
s = d['summary']
assert s['total'] >= 1, 'total should be >= 1'
assert s['failed'] == 0, f'failed should be 0, got {s[\"failed\"]}'
assert s['all_passed'] is True, 'all_passed should be True'
" 2>/dev/null; then
  pass_note "summary shows all passed"
else
  fail_note "summary shows all passed" "     output: $output"
fi
echo ""

# ---------------------------------------------------------------------------
# Test 2 — targeted run, two suites, multi-suite summary
# ---------------------------------------------------------------------------
echo "2. Targeted run of two suites returns a multi-suite summary"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_run_tests \
  --mode targeted \
  --files "tests/hooks/test-heartbeat-clock-summary.sh" \
          "tests/hooks/test-lib-hooks.sh" 2>&1)
status=$?
assert_success "two-suite call exits zero" "$status"
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
s = d['summary']
assert s['total'] == 2, f'total should be 2, got {s[\"total\"]}'
assert s['failed'] == 0, f'failed should be 0, got {s[\"failed\"]}'
assert isinstance(d['details'], list) and len(d['details']) == 2
" 2>/dev/null; then
  pass_note "two-suite targeted run produces two-entry summary"
else
  fail_note "two-suite targeted run produces two-entry summary" "     output: $output"
fi
echo ""

# ---------------------------------------------------------------------------
# Test 3 — unknown suite path returns error entry, not hard failure
# ---------------------------------------------------------------------------
echo "3. Targeted run with an unknown suite path returns an error entry"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_run_tests \
  --mode targeted \
  --files "tests/does-not-exist.sh" 2>&1)
status=$?
assert_success "unknown suite exits zero (error in details, not crash)" "$status"
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
s = d['summary']
assert s['errors'] == 1, f'errors should be 1, got {s[\"errors\"]}'
assert s['total'] == 1, f'total should be 1, got {s[\"total\"]}'
" 2>/dev/null; then
  pass_note "unknown suite produces error entry in details"
else
  fail_note "unknown suite produces error entry in details" "     output: $output"
fi
echo ""

# ---------------------------------------------------------------------------
# Test 4 — result keys are present
# ---------------------------------------------------------------------------
echo "4. Result dict contains expected top-level keys"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_run_tests \
  --mode targeted \
  --files "tests/hooks/test-heartbeat-clock-summary.sh" 2>&1)
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for k in ('summary', 'failed_suites', 'skipped_suites', 'details'):
    assert k in d, f'missing key: {k}'
s = d['summary']
for sk in ('total', 'passed', 'failed', 'errors', 'skipped', 'all_passed'):
    assert sk in s, f'missing summary key: {sk}'
" 2>/dev/null; then
  pass_note "all expected result keys present"
else
  fail_note "all expected result keys present" "     output: $output"
fi
echo ""

# ---------------------------------------------------------------------------
# Test 5 — each detail entry has expected fields
# ---------------------------------------------------------------------------
echo "5. Detail entries contain status, elapsed_s, and output_tail"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_run_tests \
  --mode targeted \
  --files "tests/hooks/test-heartbeat-clock-summary.sh" 2>&1)
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for entry in d['details']:
    for f in ('suite', 'status', 'elapsed_s', 'output_tail'):
        assert f in entry, f'missing detail field: {f}'
    assert entry['status'] in ('passed', 'failed', 'error'), f'unexpected status: {entry[\"status\"]}'
" 2>/dev/null; then
  pass_note "detail entries have all required fields"
else
  fail_note "detail entries have all required fields" "     output: $output"
fi
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "Results: $PASS passed, $FAIL failed ($SUITE_NAME)"
[[ $FAIL -eq 0 ]]
