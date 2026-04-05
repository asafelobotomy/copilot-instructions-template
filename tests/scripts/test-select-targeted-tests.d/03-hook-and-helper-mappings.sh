#!/usr/bin/env bash

echo "25. scan-secrets.ps1 maps to its dedicated PowerShell suite"
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

echo "26. subagent-start.sh maps to its dedicated shell suite"
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

echo "27. subagent-start.ps1 maps to its dedicated PowerShell suite"
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

echo "28. heartbeat_clock_summary.py maps to direct and integration suites"
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

echo "29. pulse_paths.py maps to direct and pulse integration suites"
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

echo "30. PowerShell test helpers broaden to every PowerShell hook suite"
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

echo "31. PowerShell coverage wrappers broaden to every PowerShell hook suite"
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

echo "32. pulse_state.py maps to direct and integration suites"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/hooks/scripts/pulse_state.py")
status=$?
assert_success "selector exits zero on pulse_state.py" "$status"
SELECTOR_OUTPUT="$output" assert_python "pulse_state.py includes direct and pulse coverage" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
selected = set(payload["selected_tests"])
required = {
    "tests/hooks/test-pulse-state.sh",
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

echo "33. lib-hooks.sh maps to direct and resilience suites"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" "template/hooks/scripts/lib-hooks.sh")
status=$?
assert_success "selector exits zero on lib-hooks.sh" "$status"
SELECTOR_OUTPUT="$output" assert_python "lib-hooks.sh includes direct and resilience coverage" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
selected = set(payload["selected_tests"])
required = {
    "tests/hooks/test-lib-hooks.sh",
    "tests/scripts/test-permission-resilience.sh",
    "tests/contracts/test-template-parity.sh",
}
missing = sorted(required - selected)
if missing:
    raise SystemExit(str(payload["selected_tests"]))
if payload["intermediate_phase_strategy"] != "targeted":
    raise SystemExit(payload["intermediate_phase_strategy"])
'
echo ""