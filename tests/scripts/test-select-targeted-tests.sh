#!/usr/bin/env bash
# tests/scripts/test-select-targeted-tests.sh -- unit tests for scripts/tests/select-targeted-tests.sh
# Run: bash tests/scripts/test-select-targeted-tests.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/tests/select-targeted-tests.sh"
MAP_FILE="$REPO_ROOT/scripts/tests/targeted-test-map.json"

echo "=== select-targeted-tests.sh ==="
echo ""

echo "1. Invalid usage is rejected"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" 2>&1) || true
assert_contains "usage is printed" "$output" "Usage: bash scripts/tests/select-targeted-tests.sh"
echo ""

echo "2. Manifest is valid JSON"
output=$(cat "$MAP_FILE")
assert_valid_json "targeted test map is valid JSON" "$output"
echo ""

echo "3. Exact script mapping returns targeted suites"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/release/sync-version.sh")
status=$?
assert_success "selector exits zero on exact mapping" "$status"
assert_valid_json "selector output is valid JSON" "$output"
SELECTOR_OUTPUT="$output" assert_python "sync-version maps to its targeted suites" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
expected = {
    "tests/scripts/test-sync-version.sh",
    "tests/scripts/test-security-edge-cases.sh",
}
if set(payload["selected_tests"]) != expected:
    raise SystemExit(str(payload["selected_tests"]))
if payload["normalized_paths"] != ["scripts/release/sync-version.sh"]:
    raise SystemExit(str(payload["normalized_paths"]))
if payload["run_full_suite_at_completion"] is not True:
    raise SystemExit("final full-suite gate missing")
'
echo ""

echo "4. Agent file mapping returns customization and audit suites"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" ".github/agents/fast.agent.md")
status=$?
assert_success "selector exits zero on agent mapping" "$status"
SELECTOR_OUTPUT="$output" assert_python "agent files map to customization-related suites" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
expected = {
    "tests/contracts/test-customization-contracts.sh",
    "tests/scripts/test-copilot-audit.sh",
    "tests/scripts/test-sync-models.sh",
    "tests/scripts/test-validate-agent-frontmatter.sh",
}
selected = set(payload["selected_tests"])
missing = sorted(expected - selected)
if missing:
    raise SystemExit(", ".join(missing))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "5. Shared helper escalation is marked as broaden-aggressively"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/lib.sh")
status=$?
assert_success "selector exits zero on shared helper mapping" "$status"
SELECTOR_OUTPUT="$output" assert_python "shared helper broadens the phase strategy" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["intermediate_phase_strategy"] != "broaden-aggressively":
    raise SystemExit(payload["intermediate_phase_strategy"])
required = {
    "tests/scripts/test-release-plan.sh",
    "tests/scripts/test-sync-version.sh",
    "tests/scripts/test-stub-migration.sh",
    "tests/scripts/test-sync-workspace-index.sh",
    "tests/scripts/test-sync-models.sh",
    "tests/scripts/test-validate-agent-frontmatter.sh",
    "tests/scripts/test-sync-template-parity.sh",
    "tests/scripts/test-permission-resilience.sh",
}
missing = sorted(required - set(payload["selected_tests"]))
if missing:
    raise SystemExit(", ".join(missing))
if not payload["broadening_reasons"]:
    raise SystemExit("missing broadening reasons")
'
echo ""

echo "6. Audit sandbox helper stays targeted"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "tests/lib/copilot-audit-sandbox.sh")
status=$?
assert_success "selector exits zero on audit sandbox helper" "$status"
SELECTOR_OUTPUT="$output" assert_python "audit sandbox helper maps only to the audit suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
if payload["selected_tests"] != ["tests/scripts/test-copilot-audit.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["unmapped_paths"]:
    raise SystemExit(str(payload["unmapped_paths"]))
'
echo ""

echo "7. Unmapped paths force the full-suite strategy"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" ".gitignore")
status=$?
assert_success "selector exits zero on unmapped path" "$status"
SELECTOR_OUTPUT="$output" assert_python "unmapped paths require the full-suite strategy" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["intermediate_phase_strategy"] != "full-suite":
    raise SystemExit(payload["intermediate_phase_strategy"])
if payload["unmapped_paths"] != [".gitignore"]:
    raise SystemExit(str(payload["unmapped_paths"]))
if payload["selected_tests"]:
    raise SystemExit(str(payload["selected_tests"]))
'
echo ""

echo "8. Multiple paths de-duplicate suites and promote the widest strategy"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/release/sync-version.sh" "scripts/lib.sh")
status=$?
assert_success "selector exits zero on combined inputs" "$status"
SELECTOR_OUTPUT="$output" assert_python "combined inputs deduplicate tests and keep the broader strategy" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
tests = payload["selected_tests"]
if len(tests) != len(set(tests)):
    raise SystemExit("duplicate tests present")
if payload["intermediate_phase_strategy"] != "broaden-aggressively":
    raise SystemExit(payload["intermediate_phase_strategy"])
if "tests/scripts/test-sync-version.sh" not in tests:
    raise SystemExit("missing sync-version suite")
'
echo ""

echo "9. Absolute paths are normalized to repo-relative paths"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "$REPO_ROOT/SETUP.md")
status=$?
assert_success "selector accepts absolute paths" "$status"
SELECTOR_OUTPUT="$output" assert_python "absolute paths normalize correctly" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["normalized_paths"] != ["SETUP.md"]:
    raise SystemExit(str(payload["normalized_paths"]))
if "tests/contracts/test-setup-update-contracts.sh" not in payload["selected_tests"]:
    raise SystemExit(str(payload["selected_tests"]))
'
echo ""

echo "10. Heartbeat MCP server maps to its dedicated hook suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/hooks/scripts/mcp-heartbeat-server.py")
status=$?
assert_success "selector exits zero on heartbeat MCP server" "$status"
SELECTOR_OUTPUT="$output" assert_python "heartbeat MCP server maps to its dedicated suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
selected = set(payload["selected_tests"])
required = {
    "tests/hooks/test-mcp-heartbeat-server.sh",
    "tests/contracts/test-template-parity.sh",
}
missing = sorted(required - selected)
if missing:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "11. Setup manifests map to the setup/update contract suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/setup/manifests.md")
status=$?
assert_success "selector exits zero on setup manifests" "$status"
SELECTOR_OUTPUT="$output" assert_python "setup manifests map to the setup/update contract suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/contracts/test-setup-update-contracts.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "12. Selector assets map back to the selector suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/tests/targeted-test-map.json")
status=$?
assert_success "selector exits zero on selector assets" "$status"
SELECTOR_OUTPUT="$output" assert_python "selector assets map to the selector suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/scripts/test-select-targeted-tests.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
'
echo ""


finish_tests