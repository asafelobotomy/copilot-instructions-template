#!/usr/bin/env bash
# tests/scripts/test-mcp-servers.sh -- validation tests for owned MCP Python servers
# Run: bash tests/scripts/test-mcp-servers.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

MCP_DIR="$REPO_ROOT/hooks/scripts"

SERVERS=(
  mcp-fetch-server.py
  mcp-docs-server.py
  mcp-duckduckgo-server.py
  mcp-sequential-thinking-server.py
  mcp-git-server.py
  mcp-heartbeat-server.py
)

echo "=== Owned MCP server validation tests ==="
echo ""

# ── 1. Every server file exists ────────────────────────────────────────────────
echo "1. All owned MCP server files exist"
for srv in "${SERVERS[@]}"; do
  assert_file_exists "$srv exists" "$MCP_DIR/$srv"
done
echo ""

# ── 2. Python syntax validity ─────────────────────────────────────────────────
echo "2. All servers pass Python syntax check (py_compile)"
for srv in "${SERVERS[@]}"; do
  if python3 -m py_compile "$MCP_DIR/$srv" 2>/dev/null; then
    pass_note "$srv syntax OK"
  else
    fail_note "$srv syntax OK" "     python3 -m py_compile failed for $srv"
  fi
done
echo ""

# ── 3. Parity — each server has three identical copies ────────────────────────
echo "3. Three-copy parity (hooks/, .github/hooks/, template/hooks/)"
for srv in "${SERVERS[@]}"; do
  root_copy="$REPO_ROOT/hooks/scripts/$srv"
  dev_copy="$REPO_ROOT/.github/hooks/scripts/$srv"
  tpl_copy="$REPO_ROOT/template/hooks/scripts/$srv"
  if [[ ! -f "$dev_copy" ]]; then
    fail_note "$srv parity .github/hooks/ copy exists" "     missing: $dev_copy"
  elif [[ ! -f "$tpl_copy" ]]; then
    fail_note "$srv parity template/hooks/ copy exists" "     missing: $tpl_copy"
  elif diff -q "$root_copy" "$dev_copy" > /dev/null 2>&1 && diff -q "$root_copy" "$tpl_copy" > /dev/null 2>&1; then
    pass_note "$srv three-copy parity OK"
  else
    fail_note "$srv three-copy parity OK" "     parity copies differ from $root_copy"
  fi
done
echo ""

# ── 4. All servers have a __main__ block for direct invocation ────────────────
echo "4. All servers have an if __name__ == '__main__' block"
for srv in "${SERVERS[@]}"; do
  if grep -q "__name__.*__main__" "$MCP_DIR/$srv"; then
    pass_note "$srv has __main__ block"
  else
    fail_note "$srv has __main__ block" "     missing: if __name__ == '__main__'"
  fi
done
echo ""

# ── 5. SSRF guards present in servers that make outbound HTTP calls ───────────
echo "5. SSRF guard (_validate_fetch_url) present in HTTP-capable servers"
SSRF_SERVERS=(mcp-fetch-server.py mcp-duckduckgo-server.py mcp-docs-server.py)
for srv in "${SSRF_SERVERS[@]}"; do
  if grep -q "_validate_fetch_url\|_ALLOWED_HOSTS\|allowlist" "$MCP_DIR/$srv"; then
    pass_note "$srv has SSRF guard"
  else
    fail_note "$srv has SSRF guard" "     missing: _validate_fetch_url or allowlist"
  fi
done
echo ""

# ── 6. mcp-fetch-server.py: blocks loopback and private ranges ────────────────
echo "6. mcp-fetch-server.py blocks loopback, private, and link-local ranges"
FETCH="$MCP_DIR/mcp-fetch-server.py"
assert_file_contains "uses ipaddress module for range checks" "$FETCH" "ipaddress"
assert_file_contains "checks is_loopback" "$FETCH" "is_loopback"
assert_file_contains "checks is_private" "$FETCH" "is_private"
assert_file_contains "checks is_link_local" "$FETCH" "is_link_local"
assert_file_contains "blocks localhost hostname explicitly" "$FETCH" "localhost"
echo ""

# ── 7. mcp-docs-server.py: strict hostname allowlist ─────────────────────────
echo "7. mcp-docs-server.py has strict DevDocs hostname allowlist"
DOCS="$MCP_DIR/mcp-docs-server.py"
assert_file_contains "devdocs.io in allowlist" "$DOCS" "devdocs.io"
assert_file_contains "documents.devdocs.io in allowlist" "$DOCS" "documents.devdocs.io"
# Must not allow arbitrary hosts
if grep -q "_ALLOWED_HOSTS\|allowlist\|_validate_fetch_url" "$DOCS"; then
  pass_note "mcp-docs-server.py has host restriction"
else
  fail_note "mcp-docs-server.py has host restriction" "     no allowlist or _validate_fetch_url found"
fi
echo ""

# ── 8. mcp-sequential-thinking-server.py: no network calls ───────────────────
echo "8. mcp-sequential-thinking-server.py has no outbound network imports"
SEQ="$MCP_DIR/mcp-sequential-thinking-server.py"
if grep -Eq "^import (urllib|requests|httpx|aiohttp)" "$SEQ"; then
  fail_note "mcp-sequential-thinking-server.py has no outbound network imports" \
    "     found network import"
else
  pass_note "mcp-sequential-thinking-server.py has no outbound network imports"
fi
echo ""

# ── 9. mcp-git-server.py: GIT_MCP_REPOSITORY isolation ──────────────────────
echo "9. mcp-git-server.py uses GIT_MCP_REPOSITORY env for repo isolation"
GIT="$MCP_DIR/mcp-git-server.py"
assert_file_contains "GIT_MCP_REPOSITORY env var used" "$GIT" "GIT_MCP_REPOSITORY"
echo ""

# ── 10. Parameter clamping: max_results / max_length boundaries ───────────────
echo "10. HTTP-capable servers clamp output parameters"
for srv in mcp-fetch-server.py mcp-duckduckgo-server.py mcp-docs-server.py; do
  if grep -Eq "max\(|min\(|clamp|100_000|100000" "$MCP_DIR/$srv"; then
    pass_note "$srv clamps parameters"
  else
    fail_note "$srv clamps parameters" "     no clamping found"
  fi
done
echo ""

# ── 11. Prompt-injection warning footer ───────────────────────────────────────
echo "11. HTTP-capable servers append prompt-injection warning to content"
for srv in mcp-fetch-server.py mcp-duckduckgo-server.py; do
  if grep -qi "injection\|untrusted\|warning\|AI-generated" "$MCP_DIR/$srv"; then
    pass_note "$srv has injection warning footer"
  else
    fail_note "$srv has injection warning footer" \
      "     no injection/untrusted warning found"
  fi
done
echo ""

# ── 12. All servers use stdio transport only (no HTTP server mode) ────────────
echo "12. All servers use stdio transport (mcp.run via __main__)"
for srv in "${SERVERS[@]}"; do
  if grep -q "mcp.run\|transport.*stdio\|stdio.*transport" "$MCP_DIR/$srv"; then
    pass_note "$srv uses stdio transport"
  else
    fail_note "$srv uses stdio transport" "     no mcp.run or stdio transport found"
  fi
done
echo ""

# ── 13. mcp.json files use exact pinned versions for owned-server deps ────────
echo "13. mcp.json files use exact (==) pinned versions for --with deps"
MCP_CONFIGS=(
  "$REPO_ROOT/.vscode/mcp.json"
  "$REPO_ROOT/template/vscode/mcp.json"
  "$REPO_ROOT/template/vscode/mcp-unsandboxed.json"
)
for cfg in "${MCP_CONFIGS[@]}"; do
  rel="${cfg#$REPO_ROOT/}"
  if grep -Eq '"[a-z][a-z0-9_-]*(>=|<=|~=|<|>)[0-9]' "$cfg"; then
    fail_note "$rel has no ranged deps" \
      "     found ranged specifier (>=, <=, ~=, <, >) — pin to exact version with =="
  else
    pass_note "$rel uses only exact pinned versions"
  fi
done
echo ""

# ── 14. mcp-unsandboxed.json is valid JSON ────────────────────────────────────
echo "14. template/vscode/mcp-unsandboxed.json is valid JSON with required keys"
UNSANDBOXED="$REPO_ROOT/template/vscode/mcp-unsandboxed.json"
assert_file_exists "mcp-unsandboxed.json exists" "$UNSANDBOXED"
content=$(cat "$UNSANDBOXED")
assert_valid_json "mcp-unsandboxed.json is valid JSON" "$content"
assert_python "mcp-unsandboxed.json has servers key" '
import json, pathlib
cfg = json.loads((root / "template/vscode/mcp-unsandboxed.json").read_text())
if "servers" not in cfg:
    raise SystemExit("missing top-level 'servers' key")
required = {"filesystem", "git", "github"}
missing = required - cfg["servers"].keys()
if missing:
    raise SystemExit(f"mcp-unsandboxed.json missing servers: {missing}")
'
echo ""

# ── 15. mcp-unsandboxed.json uses owned git server (not upstream mcp-server-git) ──
echo "15. mcp-unsandboxed.json git server uses owned mcp-git-server.py"
assert_file_contains "mcp-unsandboxed git uses owned server" \
  "$UNSANDBOXED" "mcp-git-server.py"
assert_file_not_contains "mcp-unsandboxed git does not use upstream mcp-server-git as package" \
  "$UNSANDBOXED" '"mcp-server-git"'
echo ""

finish_tests
