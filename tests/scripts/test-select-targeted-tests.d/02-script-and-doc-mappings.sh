# shellcheck shell=bash
set -euo pipefail

echo "12. Selector root manifest and shard files map back to the selector suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/harness/targeted-test-map.json" "scripts/harness/targeted-test-map.d/00-selector-core.json")
status=$?
assert_success "selector exits zero on selector assets" "$status"
SELECTOR_OUTPUT="$output" assert_python "selector assets map to the selector suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/scripts/test-select-targeted-tests.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if sorted(payload["normalized_paths"]) != sorted([
    "scripts/harness/targeted-test-map.json",
    "scripts/harness/targeted-test-map.d/00-selector-core.json",
]):
    raise SystemExit(str(payload["normalized_paths"]))
'
echo ""

echo "13. Selector test shard files map back to the aggregate selector suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "tests/scripts/test-select-targeted-tests.d/01-core.sh")
status=$?
assert_success "selector exits zero on selector test shard" "$status"
SELECTOR_OUTPUT="$output" assert_python "selector test shards map to the aggregate suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/scripts/test-select-targeted-tests.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
'
echo ""

echo "14. Suite manifest assets map to the suite-manifest suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/harness/suite-manifest.py" "scripts/harness/suite-manifest.json")
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

echo "16. run-all-captured maps to its dedicated suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/harness/run-all-captured.sh")
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

echo "17. run-isolated-shell maps to its dedicated suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/harness/run-isolated-shell.sh")
status=$?
assert_success "selector exits zero on run-isolated-shell" "$status"
SELECTOR_OUTPUT="$output" assert_python "run-isolated-shell maps to its dedicated suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/scripts/test-run-isolated-shell.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "18. run-isolated-shell-stdin maps to its dedicated suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "scripts/harness/run-isolated-shell-stdin.sh")
status=$?
assert_success "selector exits zero on run-isolated-shell-stdin" "$status"
SELECTOR_OUTPUT="$output" assert_python "run-isolated-shell-stdin maps to its dedicated suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/scripts/test-run-isolated-shell-stdin.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "19. validate-required-files maps to its dedicated suite"
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

echo "20. validate-cross-references maps to its dedicated suite"
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

echo "21. validate-attention-budget maps to its dedicated suite"
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

echo "22. CLAUDE.md maps to the customization policy contract suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "CLAUDE.md")
status=$?
assert_success "selector exits zero on CLAUDE.md" "$status"
SELECTOR_OUTPUT="$output" assert_python "CLAUDE.md maps to the customization policy contract suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/contracts/test-customization-contracts-policies.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "23. template/CLAUDE.md maps to the customization policy contract suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/CLAUDE.md")
status=$?
assert_success "selector exits zero on template/CLAUDE.md" "$status"
SELECTOR_OUTPUT="$output" assert_python "template/CLAUDE.md maps to the customization policy contract suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/contracts/test-customization-contracts-policies.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "24. Customization contract sub-suites self-map now that they are manifest-addressable"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "tests/contracts/test-customization-contracts-policies.sh")
status=$?
assert_success "selector exits zero on customization contract sub-suites" "$status"
SELECTOR_OUTPUT="$output" assert_python "customization contract sub-suites self-map" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if payload["selected_tests"] != ["tests/contracts/test-customization-contracts-policies.sh"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'

echo "25. README.md maps to the release and customization policy contract suites"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "README.md")
status=$?
assert_success "selector exits zero on README.md" "$status"
SELECTOR_OUTPUT="$output" assert_python "README.md maps to the release and customization policy contract suites" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if set(payload["selected_tests"]) != {
    "tests/contracts/test-release-contracts.sh",
    "tests/contracts/test-customization-contracts-policies.sh",
}:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""

echo "26. template/workspace/ stub files — skip (setup-update contracts deleted)"
# Placeholder for future workspace stubs test
echo ""

echo "37. .copilot/workspace/operations/HEARTBEAT.md maps to drift check suite"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" ".copilot/workspace/operations/HEARTBEAT.md")
status=$?
assert_success "selector exits zero on developer HEARTBEAT.md" "$status"
SELECTOR_OUTPUT="$output" assert_python "developer HEARTBEAT.md maps to workspace drift suite" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
if "tests/scripts/test-workspace-drift.sh" not in payload["selected_tests"]:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
if payload.get("unmapped_paths"):
    _um = payload["unmapped_paths"]
    raise SystemExit(f"unexpected unmapped: {_um}")
'
echo ""

echo "38. mirror-domain collapsing reduces domain count for parity-mirror changes"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "hooks/scripts/pulse_state.py" "hooks/scripts/pulse_state.py")
status=$?
assert_success "selector exits zero on parity mirror pair" "$status"
SELECTOR_OUTPUT="$output" assert_python "parity mirror pair collapses to a single domain" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
domains = payload["domains_touched"]
if len(domains) != 1:
    raise SystemExit(f"expected 1 collapsed domain, got {len(domains)}: {domains}")
if domains[0] != "hooks-mirror":
    raise SystemExit(f"expected hooks-mirror domain, got: {domains[0]}")
'
echo ""