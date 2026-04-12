#!/usr/bin/env bash

echo "1. Invalid usage is rejected"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" 2>&1) || true
assert_contains "usage is printed" "$output" "Usage: bash scripts/harness/select-targeted-tests.sh"
echo ""

echo "2. Selector manifests are valid JSON and root manifest lists valid shards"
output=$(cat "$MAP_FILE")
assert_valid_json "targeted test map root is valid JSON" "$output"
SELECTOR_OUTPUT="$output" MAP_FILE_PATH="$MAP_FILE" assert_python "selector root manifest lists valid shard files" '
map_file = pathlib.Path(os.environ["MAP_FILE_PATH"])
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
rule_files = payload.get("ruleFiles")
if not isinstance(rule_files, list) or len(rule_files) != 4:
    raise SystemExit(str(rule_files))
for rel in rule_files:
    shard = root / rel
    if not shard.is_file():
        raise SystemExit(str(shard))
    json.loads(shard.read_text(encoding="utf-8"))
'
output=$(cat "$SUITE_MANIFEST_FILE")
assert_valid_json "suite manifest is valid JSON" "$output"
echo ""

echo "3. Exact script mapping returns targeted suites"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/release/verify-version-references.sh")
status=$?
assert_success "selector exits zero on exact mapping" "$status"
assert_valid_json "selector output is valid JSON" "$output"
SELECTOR_OUTPUT="$output" assert_python "verify-version-references maps to its targeted suites" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
expected = {
    "tests/scripts/test-verify-version-references.sh",
    "tests/scripts/test-security-edge-cases.sh",
}
if set(payload["selected_tests"]) != expected:
    raise SystemExit(str(payload["selected_tests"]))
if payload["normalized_paths"] != ["scripts/release/verify-version-references.sh"]:
    raise SystemExit(str(payload["normalized_paths"]))
if payload["intermediate_phase_budget_seconds"] != 10:
    raise SystemExit(str(payload["intermediate_phase_budget_seconds"]))
if payload["run_full_suite_at_completion"] is not True:
    raise SystemExit("final full-suite gate missing")
if payload["terminal_safe_final_gate"] != "bash scripts/harness/run-all-captured.sh":
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
    "tests/scripts/test-verify-version-references.sh",
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
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/release/verify-version-references.sh" "scripts/lib.sh")
status=$?
assert_success "selector exits zero on combined inputs" "$status"
SELECTOR_OUTPUT="$output" assert_python "combined inputs deduplicate tests and keep the broader strategy" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
tests = payload["selected_tests"]
if len(tests) != len(set(tests)):
    raise SystemExit("duplicate tests present")
if payload["intermediate_phase_strategy"] != "broaden-aggressively":
    raise SystemExit(payload["intermediate_phase_strategy"])
if "tests/scripts/test-verify-version-references.sh" not in tests:
    raise SystemExit("missing verify-version-references suite")
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

echo "12. Escalation fields are present with no escalation on safe targeted path"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/release/verify-version-references.sh")
SELECTOR_OUTPUT="$output" assert_python "escalation fields present and false for safe path" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["should_run_full_suite_early"] is not False:
    raise SystemExit(f"should_run_full_suite_early={payload['should_run_full_suite_early']}")
if payload["early_full_suite_reasons"]:
    raise SystemExit(str(payload["early_full_suite_reasons"]))
if not isinstance(payload["confidence_score"], (int, float)):
    raise SystemExit(f"confidence_score type: {type(payload['confidence_score'])}")
if payload["confidence_score"] != 1.0:
    raise SystemExit(f"confidence_score={payload['confidence_score']}")
if not isinstance(payload["risk_classes_matched"], list):
    raise SystemExit(f"risk_classes_matched type: {type(payload['risk_classes_matched'])}")
if not isinstance(payload["domains_touched"], list):
    raise SystemExit(f"domains_touched type: {type(payload['domains_touched'])}")
if not isinstance(payload["decision_log"], list):
    raise SystemExit(f"decision_log type: {type(payload['decision_log'])}")
if len(payload["decision_log"]) < 4:
    raise SystemExit(f"expected >= 4 decision_log entries, got {len(payload['decision_log'])}")
'
echo ""

echo "13. Critical-surface risk class triggers early full suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" ".github/copilot-instructions.md")
SELECTOR_OUTPUT="$output" assert_python "critical-surface triggers should_run_full_suite_early" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["should_run_full_suite_early"] is not True:
    raise SystemExit(f"should_run_full_suite_early={payload['should_run_full_suite_early']}")
if "critical-surface" not in payload["risk_classes_matched"]:
    raise SystemExit(str(payload["risk_classes_matched"]))
reasons = " ".join(payload["early_full_suite_reasons"])
if "critical-surface" not in reasons.lower() and "Critical-surface" not in reasons:
    raise SystemExit(str(payload["early_full_suite_reasons"]))
rules_matched = [r for r in payload["matched_rules"] if r.get("riskClass") == "critical-surface"]
if not rules_matched:
    raise SystemExit("no matched_rules have riskClass=critical-surface")
'
echo ""

echo "14. Security-sensitive risk class triggers early full suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/hooks/scripts/scan-secrets.sh")
SELECTOR_OUTPUT="$output" assert_python "security-sensitive triggers should_run_full_suite_early" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["should_run_full_suite_early"] is not True:
    raise SystemExit(f"should_run_full_suite_early={payload['should_run_full_suite_early']}")
if "security-sensitive" not in payload["risk_classes_matched"]:
    raise SystemExit(str(payload["risk_classes_matched"]))
'
echo ""

echo "15. Cross-cutting risk class is collected in risk_classes_matched"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/lib.sh")
SELECTOR_OUTPUT="$output" assert_python "cross-cutting risk class collected" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if "cross-cutting" not in payload["risk_classes_matched"]:
    raise SystemExit(str(payload["risk_classes_matched"]))
'
echo ""

echo "16. Decision log records all five escalation rules"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/release/verify-version-references.sh")
SELECTOR_OUTPUT="$output" assert_python "decision log has all five rule entries" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
rules = [entry["rule"] for entry in payload["decision_log"]]
expected = {"tracked-file-pattern", "critical-surface", "security-sensitive", "multi-domain-broaden", "confidence-floor"}
missing = expected - set(rules)
if missing:
    raise SystemExit(f"missing decision log rules: {sorted(missing)}")
'
echo ""

echo "17. Confidence score drops below 1.0 when unmapped paths exist"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/release/verify-version-references.sh" ".gitignore")
SELECTOR_OUTPUT="$output" assert_python "confidence score reflects unmapped paths" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["confidence_score"] >= 1.0:
    raise SystemExit(f"expected < 1.0, got {payload['confidence_score']}")
if payload["confidence_score"] != 0.5:
    raise SystemExit(f"expected 0.5 (1/2), got {payload['confidence_score']}")
'
echo ""

echo "18. Domains touched reflects top-level directories"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/lib.sh" "template/copilot-instructions.md")
SELECTOR_OUTPUT="$output" assert_python "domains_touched includes both top-level dirs" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
domains = set(payload["domains_touched"])
if "scripts" not in domains or "template" not in domains:
    raise SystemExit(str(payload["domains_touched"]))
'
echo ""