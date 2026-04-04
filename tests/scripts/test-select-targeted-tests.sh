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
SUITE_MANIFEST_FILE="$REPO_ROOT/scripts/tests/suite-manifest.json"

echo "=== select-targeted-tests.sh ==="
echo ""

echo "1. Invalid usage is rejected"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" 2>&1) || true
assert_contains "usage is printed" "$output" "Usage: bash scripts/tests/select-targeted-tests.sh"
echo ""

echo "2. Manifest is valid JSON"
output=$(cat "$MAP_FILE")
assert_valid_json "targeted test map is valid JSON" "$output"
output=$(cat "$SUITE_MANIFEST_FILE")
assert_valid_json "suite manifest is valid JSON" "$output"
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
if payload["terminal_safe_final_gate"] != "bash scripts/tests/run-all-captured.sh":
    raise SystemExit(payload["terminal_safe_final_gate"])
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

echo "13. Suite manifest assets map to the suite-manifest suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/tests/suite-manifest.py" "scripts/tests/suite-manifest.json")
status=$?
assert_success "selector exits zero on suite-manifest assets" "$status"
SELECTOR_OUTPUT="$output" assert_python "suite manifest assets map to the suite-manifest suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
expected = {
    "tests/scripts/test-suite-manifest.sh",
    "tests/scripts/test-select-targeted-tests.sh",
    "tests/scripts/test-run-all-captured.sh",
}
if set(payload["selected_tests"]) != expected:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "broaden-aggressively":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "14. validate-template-sync maps to its dedicated suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/ci/validate-template-sync.sh")
status=$?
assert_success "selector exits zero on validate-template-sync" "$status"
SELECTOR_OUTPUT="$output" assert_python "validate-template-sync maps to its dedicated suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/scripts/test-validate-template-sync.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "15. run-all-captured maps to its dedicated suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/tests/run-all-captured.sh")
status=$?
assert_success "selector exits zero on run-all-captured" "$status"
SELECTOR_OUTPUT="$output" assert_python "run-all-captured maps to its dedicated suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/scripts/test-run-all-captured.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "16. run-strict-bash-stdin maps to its dedicated suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/tests/run-strict-bash-stdin.sh")
status=$?
assert_success "selector exits zero on run-strict-bash-stdin" "$status"
SELECTOR_OUTPUT="$output" assert_python "run-strict-bash-stdin maps to its dedicated suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/scripts/test-run-strict-bash-stdin.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "17. validate-required-files maps to its dedicated suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/ci/validate-required-files.sh")
status=$?
assert_success "selector exits zero on validate-required-files" "$status"
SELECTOR_OUTPUT="$output" assert_python "validate-required-files maps to its dedicated suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/scripts/test-validate-required-files.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "18. validate-cross-references maps to its dedicated suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/ci/validate-cross-references.sh")
status=$?
assert_success "selector exits zero on validate-cross-references" "$status"
SELECTOR_OUTPUT="$output" assert_python "validate-cross-references maps to its dedicated suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/scripts/test-validate-cross-references.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "19. validate-attention-budget maps to its dedicated suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/ci/validate-attention-budget.sh")
status=$?
assert_success "selector exits zero on validate-attention-budget" "$status"
SELECTOR_OUTPUT="$output" assert_python "validate-attention-budget maps to its dedicated suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/scripts/test-validate-attention-budget.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "20. CLAUDE.md maps to the customization contract suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "CLAUDE.md")
status=$?
assert_success "selector exits zero on CLAUDE.md" "$status"
SELECTOR_OUTPUT="$output" assert_python "CLAUDE.md maps to the customization contract suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/contracts/test-customization-contracts.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "21. template/CLAUDE.md maps to the customization contract suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/CLAUDE.md")
status=$?
assert_success "selector exits zero on template/CLAUDE.md" "$status"
SELECTOR_OUTPUT="$output" assert_python "template/CLAUDE.md maps to the customization contract suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/contracts/test-customization-contracts.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "22. Customization contract sub-suites map to the aggregate contract suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "tests/contracts/test-customization-contracts-policies.sh")
status=$?
assert_success "selector exits zero on customization contract sub-suites" "$status"
SELECTOR_OUTPUT="$output" assert_python "customization contract sub-suites map to the aggregate suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/contracts/test-customization-contracts.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "23. scan-secrets.ps1 maps to its dedicated PowerShell suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/hooks/scripts/scan-secrets.ps1")
status=$?
assert_success "selector exits zero on scan-secrets.ps1" "$status"
SELECTOR_OUTPUT="$output" assert_python "scan-secrets.ps1 includes direct PowerShell coverage and parity" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
selected = set(payload["selected_tests"])
required = {
    "tests/hooks/test-hook-scan-secrets-powershell.sh",
    "tests/contracts/test-template-parity.sh",
}
missing = sorted(required - selected)
if missing:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "24. subagent-start.sh maps to its dedicated shell suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/hooks/scripts/subagent-start.sh")
status=$?
assert_success "selector exits zero on subagent-start.sh" "$status"
SELECTOR_OUTPUT="$output" assert_python "subagent-start.sh includes direct shell coverage and parity" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
selected = set(payload["selected_tests"])
required = {
    "tests/hooks/test-hook-subagent-start.sh",
    "tests/contracts/test-template-parity.sh",
    "tests/scripts/test-permission-resilience.sh",
}
missing = sorted(required - selected)
if missing:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "25. subagent-start.ps1 maps to its dedicated PowerShell suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/hooks/scripts/subagent-start.ps1")
status=$?
assert_success "selector exits zero on subagent-start.ps1" "$status"
SELECTOR_OUTPUT="$output" assert_python "subagent-start.ps1 includes direct PowerShell coverage and parity" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
selected = set(payload["selected_tests"])
required = {
    "tests/hooks/test-hook-subagent-start-powershell.sh",
    "tests/contracts/test-template-parity.sh",
    "tests/hooks/test-hooks-powershell.sh",
}
missing = sorted(required - selected)
if missing:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "26. heartbeat_clock_summary.py maps to direct and integration suites"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/hooks/scripts/heartbeat_clock_summary.py")
status=$?
assert_success "selector exits zero on heartbeat_clock_summary.py" "$status"
SELECTOR_OUTPUT="$output" assert_python "heartbeat_clock_summary.py includes direct and integration coverage" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
selected = set(payload["selected_tests"])
required = {
    "tests/hooks/test-heartbeat-clock-summary.sh",
    "tests/hooks/test-hook-save-context.sh",
    "tests/contracts/test-template-parity.sh",
}
missing = sorted(required - selected)
if missing:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "27. pulse_paths.py maps to direct and pulse integration suites"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/hooks/scripts/pulse_paths.py")
status=$?
assert_success "selector exits zero on pulse_paths.py" "$status"
SELECTOR_OUTPUT="$output" assert_python "pulse_paths.py includes direct and pulse coverage" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
selected = set(payload["selected_tests"])
required = {
    "tests/hooks/test-pulse-paths.sh",
    "tests/hooks/test-hook-pulse.sh",
    "tests/contracts/test-template-parity.sh",
}
missing = sorted(required - selected)
if missing:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "28. PowerShell test helpers broaden to every PowerShell hook suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "tests/lib/powershell-hook-test-helpers.sh")
status=$?
assert_success "selector exits zero on PowerShell test helpers" "$status"
SELECTOR_OUTPUT="$output" assert_python "PowerShell test helpers include every PowerShell hook suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
selected = set(payload["selected_tests"])
required = {
    "tests/hooks/test-hooks-powershell.sh",
    "tests/hooks/test-guard-destructive-powershell.sh",
    "tests/hooks/test-hook-scan-secrets-powershell.sh",
    "tests/hooks/test-hook-subagent-start-powershell.sh",
    "tests/hooks/test-hook-subagent-stop-powershell.sh",
}
missing = sorted(required - selected)
if missing:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "broaden-aggressively":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "29. PowerShell coverage wrappers broaden to every PowerShell hook suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "tests/coverage/run-powershell-coverage.sh")
status=$?
assert_success "selector exits zero on PowerShell coverage wrappers" "$status"
SELECTOR_OUTPUT="$output" assert_python "PowerShell coverage wrappers include every PowerShell hook suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
selected = set(payload["selected_tests"])
required = {
    "tests/hooks/test-hooks-powershell.sh",
    "tests/hooks/test-guard-destructive-powershell.sh",
    "tests/hooks/test-hook-scan-secrets-powershell.sh",
    "tests/hooks/test-hook-subagent-start-powershell.sh",
    "tests/hooks/test-hook-subagent-stop-powershell.sh",
}
missing = sorted(required - selected)
if missing:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "broaden-aggressively":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""


finish_tests