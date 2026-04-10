#!/usr/bin/env bash
# tests/hooks/test-mcp-spatial-status.sh -- unit tests for spatial_status tool
# Run: bash tests/hooks/test-mcp-spatial-status.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/template/hooks/scripts/mcp-heartbeat-server.py"
CLOCK_SCRIPT="$REPO_ROOT/template/hooks/scripts/heartbeat_clock_summary.py"
trap cleanup_dirs EXIT

run_spatial() {
  local root_dir="$1"
  TEST_SCRIPT="$SCRIPT" TEST_ROOT="$root_dir" PYTHONPATH="$(dirname "$CLOCK_SCRIPT")" python3 - <<'PY'
import importlib.util
import json
import os
import sys
import types


class FakeMCP:
    def __init__(self, name):
        self.name = name

    def tool(self):
        def decorator(fn):
            return fn
        return decorator

    def run(self):
        return None


mcp_mod = types.ModuleType("mcp")
server_mod = types.ModuleType("mcp.server")
fastmcp_mod = types.ModuleType("mcp.server.fastmcp")
fastmcp_mod.FastMCP = FakeMCP
sys.modules["mcp"] = mcp_mod
sys.modules["mcp.server"] = server_mod
sys.modules["mcp.server.fastmcp"] = fastmcp_mod

os.chdir(os.environ["TEST_ROOT"])
spec = importlib.util.spec_from_file_location("heartbeat_mcp", os.environ["TEST_SCRIPT"])
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)
print(json.dumps(module.spatial_status()))
PY
}

echo "=== spatial_status tool ==="
echo ""

echo "1. Empty workspace returns valid structure"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
output=$(run_spatial "$TMP")
status=$?
assert_success "empty workspace exits zero" "$status"
assert_valid_json "empty workspace is valid JSON" "$output"
SPATIAL_OUTPUT="$output" assert_python "empty workspace has required keys" '
payload = json.loads(os.environ["SPATIAL_OUTPUT"])
assert "vocabulary" in payload
assert "diaries" in payload
assert "clock" in payload
assert isinstance(payload["vocabulary"], list)
assert isinstance(payload["diaries"], dict)
assert len(payload["diaries"]) == 0
'
echo ""

echo "2. Diary entries are returned"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/.copilot/workspace/knowledge/diaries"
cat > "$TMP/.copilot/workspace/knowledge/diaries/review.md" <<'MD'
# Review Diary

- 2026-01-01T00:00:00Z Found unused import
- 2026-01-02T00:00:00Z Fixed auth handler
MD
output=$(run_spatial "$TMP")
status=$?
assert_success "diary workspace exits zero" "$status"
SPATIAL_OUTPUT="$output" assert_python "diary entries parsed correctly" '
payload = json.loads(os.environ["SPATIAL_OUTPUT"])
assert "review" in payload["diaries"]
entries = payload["diaries"]["review"]
assert len(entries) == 2
assert "unused import" in entries[0]
assert "auth handler" in entries[1]
'
echo ""

echo "3. Vocabulary table is extracted from ledger"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/.copilot/workspace/identity" "$TMP/.copilot/workspace/knowledge/diaries" "$TMP/.copilot/workspace/operations" "$TMP/.copilot/workspace/runtime"
cat > "$TMP/.copilot/workspace/operations/ledger.md" <<'MD'
# Spatial Ledger

| Term | Meaning |
|------|---------|
| Village | The workspace |
| Building | Agent home |
MD
output=$(run_spatial "$TMP")
status=$?
assert_success "ledger workspace exits zero" "$status"
SPATIAL_OUTPUT="$output" assert_python "vocabulary extracted from ledger" '
payload = json.loads(os.environ["SPATIAL_OUTPUT"])
vocab = payload["vocabulary"]
assert len(vocab) == 2
assert any("Village" in v for v in vocab)
assert any("Building" in v for v in vocab)
'
echo ""

echo "4. README.md in diaries is ignored"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/.copilot/workspace/knowledge/diaries"
cat > "$TMP/.copilot/workspace/knowledge/diaries/README.md" <<'MD'
# Diaries

- This is documentation, not a diary
MD
output=$(run_spatial "$TMP")
status=$?
assert_success "readme-skip exits zero" "$status"
SPATIAL_OUTPUT="$output" assert_python "README.md is excluded from diaries" '
payload = json.loads(os.environ["SPATIAL_OUTPUT"])
assert len(payload["diaries"]) == 0
'
echo ""

echo "5. Multiple agent diaries are returned"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/.copilot/workspace/knowledge/diaries"
printf '# Code Diary\n\n- entry1\n- entry2\n' > "$TMP/.copilot/workspace/knowledge/diaries/code.md"
printf '# Audit Diary\n\n- finding1\n' > "$TMP/.copilot/workspace/knowledge/diaries/audit.md"
output=$(run_spatial "$TMP")
status=$?
assert_success "multi-diary exits zero" "$status"
SPATIAL_OUTPUT="$output" assert_python "multiple diaries returned" '
payload = json.loads(os.environ["SPATIAL_OUTPUT"])
assert "code" in payload["diaries"]
assert "audit" in payload["diaries"]
assert len(payload["diaries"]["code"]) == 2
assert len(payload["diaries"]["audit"]) == 1
'
echo ""

finish_tests
