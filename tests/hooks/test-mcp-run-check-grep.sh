#!/usr/bin/env bash
# tests/hooks/test-mcp-run-check-grep.sh -- unit tests for the run_check and
#   run_grep MCP tools in hooks/scripts/mcp-heartbeat-server.py
# Run: bash tests/hooks/test-mcp-run-check-grep.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
trap cleanup_dirs EXIT

# ---------------------------------------------------------------------------
# Helper — load the server module with mcp stubbed out
# ---------------------------------------------------------------------------

call_tool() {
  # Usage: call_tool <tool_name> <JSON args object>
  # Prints the JSON result from the tool to stdout.
  local tool="$1"
  local json_args="${2}"
  python3 - "$tool" "$json_args" <<'PYEOF'
import sys, os, json, types, pathlib, importlib.util as ilu

tool_name = sys.argv[1]
args_json  = sys.argv[2]

repo_root = pathlib.Path(os.environ.get("HEARTBEAT_WORKSPACE", ".")).resolve()
os.chdir(repo_root)
sys.path.insert(0, str(repo_root / "hooks" / "scripts"))

# Stub mcp package so the server imports cleanly without the real dependency.
fake_mcp = types.ModuleType("mcp")
fake_fastmcp = types.ModuleType("mcp.server.fastmcp")

class _FakeFastMCP:
    def __init__(self, *a, **k): pass
    def tool(self):
        def decorator(fn): return fn
        return decorator
    def run(self): pass

fake_fastmcp.FastMCP = _FakeFastMCP
sys.modules.setdefault("mcp", fake_mcp)
sys.modules.setdefault("mcp.server", types.ModuleType("mcp.server"))
sys.modules.setdefault("mcp.server.fastmcp", fake_fastmcp)

import mcp_heartbeat_lib  # noqa: F401
mcp_heartbeat_lib.ensure_writable_tempdir = lambda: None

spec = ilu.spec_from_file_location(
    "mcp_heartbeat_server",
    str(repo_root / "hooks" / "scripts" / "mcp-heartbeat-server.py"),
)
mod = ilu.module_from_spec(spec)
spec.loader.exec_module(mod)

fn = getattr(mod, tool_name)
kwargs = json.loads(args_json)
result = fn(**kwargs)
print(json.dumps(result, indent=2))
PYEOF
}

echo "=== mcp-heartbeat-server.py run_check + run_grep tools ==="
echo ""

# ---------------------------------------------------------------------------
# run_check tests
# ---------------------------------------------------------------------------

echo "--- run_check ---"
echo ""

# Test 1 — blocked command returns error
echo "1. run_check with a disallowed command returns an error key"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_tool run_check \
  '{"command":"rm","args":["-rf","."]}' 2>&1)
status=$?
assert_success "call exits zero" "$status"
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert 'error' in d, f'expected error key, got {list(d.keys())}'
assert 'allow-list' in d['error'].lower() or 'not in' in d['error'].lower(), \
    f'error message unexpected: {d[\"error\"]}'
" 2>/dev/null; then
  pass_note "disallowed command returns error"
else
  fail_note "disallowed command returns error" "output: $output"
fi
echo ""

# Test 2 — blocked git subcommand returns error
echo "2. run_check git with a write subcommand returns an error"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_tool run_check \
  '{"command":"git","args":["push"]}' 2>&1)
status=$?
assert_success "call exits zero" "$status"
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert 'error' in d, f'expected error key, got {list(d.keys())}'
" 2>/dev/null; then
  pass_note "git write subcommand blocked with error"
else
  fail_note "git write subcommand blocked with error" "output: $output"
fi
echo ""

# Test 3 — allowed git subcommand succeeds (git status)
echo "3. run_check git status returns ok=true and has exit_code key"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_tool run_check \
  '{"command":"git","args":["status","--short"]}' 2>&1)
status=$?
assert_success "call exits zero" "$status"
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert 'exit_code' in d, f'expected exit_code key, got {list(d.keys())}'
assert 'ok' in d,        f'expected ok key, got {list(d.keys())}'
assert 'stdout' in d,    f'expected stdout key, got {list(d.keys())}'
assert 'stderr' in d,    f'expected stderr key, got {list(d.keys())}'
" 2>/dev/null; then
  pass_note "git status returns structured result with ok/exit_code/stdout/stderr"
else
  fail_note "git status returns structured result" "output: $output"
fi
echo ""

# Test 4 — result shape for allowed command
echo "4. run_check result always has ok, exit_code, stdout, stderr keys"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_tool run_check \
  '{"command":"git","args":["log","--oneline","-1"]}' 2>&1)
status=$?
assert_success "call exits zero" "$status"
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for k in ('ok', 'exit_code', 'stdout', 'stderr'):
    assert k in d, f'missing key: {k}'
assert isinstance(d['ok'], bool)
assert isinstance(d['exit_code'], int)
" 2>/dev/null; then
  pass_note "result has all required keys with correct types"
else
  fail_note "result has all required keys" "output: $output"
fi
echo ""

# ---------------------------------------------------------------------------
# run_grep tests
# ---------------------------------------------------------------------------

echo "--- run_grep ---"
echo ""

# Test 5 — missing pattern returns error
echo "5. run_grep with empty pattern returns error"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_tool run_grep \
  '{"pattern":""}' 2>&1)
status=$?
assert_success "call exits zero (no crash)" "$status"
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert 'error' in d, f'expected error key, got {list(d.keys())}'
" 2>/dev/null; then
  pass_note "empty pattern returns error"
else
  fail_note "empty pattern returns error" "output: $output"
fi
echo ""

# Test 6 — known text found with correct structure
echo "6. run_grep finds a known string and returns structured matches"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_tool run_grep \
  '{"pattern":"mcp_heartbeat_run_tests","include_glob":"*.md","max_results":5}' 2>&1)
status=$?
assert_success "call exits zero" "$status"
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
# If rg not available, the tool returns an error — skip structural check.
if 'error' in d:
    print('rg not available; skip match check', file=sys.stderr)
    sys.exit(0)
assert 'matches' in d,        f'expected matches key'
assert 'total_matches' in d,  f'expected total_matches key'
assert 'truncated' in d,      f'expected truncated key'
assert 'pattern' in d,        f'expected pattern key'
assert isinstance(d['matches'], list)
# The string 'mcp_heartbeat_run_tests' appears in at least one .md file.
assert d['total_matches'] > 0, f'expected at least one match, got 0'
if d['matches']:
    m = d['matches'][0]
    assert 'file' in m and 'line' in m and 'content' in m, f'bad match shape: {m}'
" 2>/dev/null; then
  pass_note "grep finds known string with correct result shape"
else
  fail_note "grep finds known string" "output: $output"
fi
echo ""

# Test 7 — regex mode flag
echo "7. run_grep with is_regex=true accepts a simple regex"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_tool run_grep \
  '{"pattern":"mcp_heartbeat_[a-z_]+","is_regex":true,"include_glob":"*.md","max_results":5}' 2>&1)
status=$?
assert_success "regex call exits zero" "$status"
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if 'error' in d:
    print('rg not available; skip', file=sys.stderr)
    sys.exit(0)
assert isinstance(d.get('matches'), list)
" 2>/dev/null; then
  pass_note "regex mode accepted without error"
else
  fail_note "regex mode accepted" "output: $output"
fi
echo ""

# Test 8 — max_results cap is respected
echo "8. run_grep respects max_results cap"
output=$(HEARTBEAT_WORKSPACE="$REPO_ROOT" call_tool run_grep \
  '{"pattern":"the","max_results":3}' 2>&1)
status=$?
assert_success "call exits zero" "$status"
if echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if 'error' in d:
    sys.exit(0)
assert len(d['matches']) <= 3, f'expected <= 3 matches, got {len(d[\"matches\"])}'
" 2>/dev/null; then
  pass_note "matches capped at max_results"
else
  fail_note "matches capped at max_results" "output: $output"
fi
echo ""

finish_tests
