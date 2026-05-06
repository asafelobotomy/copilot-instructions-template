#!/usr/bin/env bash
# tests/scripts/test-suite-manifest.sh -- tests for scripts/harness/suite-manifest.py
# Run: bash tests/scripts/test-suite-manifest.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/harness/suite-manifest.py"
trap cleanup_dirs EXIT

make_success_fixture() {
  local root="$1"
  mkdir -p "$root/scripts/ci" "$root/scripts/harness" "$root/tests/scripts" "$root/tests/hooks"

  cat > "$root/scripts/ci/validate-test-output.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "validate-test-output OK"
EOF
  chmod +x "$root/scripts/ci/validate-test-output.sh"

  cat > "$root/tests/scripts/pass-suite.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "pass-suite"
EOF
  chmod +x "$root/tests/scripts/pass-suite.sh"

  cat > "$root/tests/hooks/skipped-suite.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "should-not-run"
EOF
  chmod +x "$root/tests/hooks/skipped-suite.sh"

  cat > "$root/scripts/harness/suite-manifest.json" <<'EOF'
{
  "schemaVersion": "1.0",
  "description": "fixture",
  "phases": [
    {
      "id": "scripts",
      "label": "Script Behavior"
    },
    {
      "id": "optional",
      "label": "Optional Phase",
      "optionalRequirement": {
        "command": "definitely-missing-tool",
        "label": "definitely-missing-tool",
        "probeArgs": []
      }
    }
  ],
  "suites": [
    {
      "id": "pass-suite",
      "path": "tests/scripts/pass-suite.sh",
      "phase": "scripts",
      "ciLabel": "Script behavior | pass-suite"
    },
    {
      "id": "skipped-suite",
      "path": "tests/hooks/skipped-suite.sh",
      "phase": "optional",
      "ciLabel": "Optional phase | skipped-suite"
    }
  ]
}
EOF
}

make_failure_fixture() {
  local root="$1"
  mkdir -p "$root/scripts/ci" "$root/scripts/harness" "$root/tests/scripts"

  cat > "$root/scripts/ci/validate-test-output.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "validate-test-output OK"
EOF
  chmod +x "$root/scripts/ci/validate-test-output.sh"

  cat > "$root/tests/scripts/failing-suite.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "about to fail"
exit 9
EOF
  chmod +x "$root/tests/scripts/failing-suite.sh"

  cat > "$root/scripts/harness/suite-manifest.json" <<'EOF'
{
  "schemaVersion": "1.0",
  "description": "fixture",
  "phases": [
    {
      "id": "scripts",
      "label": "Script Behavior"
    }
  ],
  "suites": [
    {
      "id": "failing-suite",
      "path": "tests/scripts/failing-suite.sh",
      "phase": "scripts",
      "ciLabel": "Script behavior | failing-suite"
    }
  ]
}
EOF
}

echo "=== suite-manifest.py ==="
echo ""

echo "1. Invalid usage is rejected"
output=$(python3 "$SCRIPT" 2>&1) || true
assert_contains "usage is printed" "$output" "usage:"
echo ""

echo "2. Real repo manifest validates"
output=$(python3 "$SCRIPT" validate --root "$REPO_ROOT" 2>&1)
status=$?
assert_success "real repo validate exits zero" "$status"
assert_contains "real repo validate reports suite count" "$output" "suite manifest is valid"
echo ""

echo "3. CI matrix output is valid and includes suite metadata"
output=$(python3 "$SCRIPT" ci-matrix --root "$REPO_ROOT")
status=$?
assert_success "ci-matrix exits zero" "$status"
assert_valid_json "ci-matrix output is valid JSON" "$output"
SELECTOR_OUTPUT="$output" assert_python "ci-matrix includes expected suite entries" '
payload = json.loads(os.environ["SELECTOR_OUTPUT"])
include = payload.get("include")
if not isinstance(include, list) or len(include) < 30:
    raise SystemExit(str(payload))
paths = {entry["path"]: entry for entry in include}
if "tests/scripts/test-select-targeted-tests.sh" not in paths:
    raise SystemExit("missing selector suite")
if "tests/hooks/test-hooks-powershell.sh" not in paths:
    raise SystemExit("missing PowerShell parity suite")
if "tests/hooks/test-heartbeat-clock-summary.sh" not in paths:
  raise SystemExit("missing heartbeat clock summary suite")
if "tests/hooks/test-hook-subagent-start-powershell.sh" not in paths:
  raise SystemExit("missing subagent-start PowerShell suite")
if "tests/hooks/test-pulse-state.sh" not in paths:
  raise SystemExit("missing pulse_state helper suite")
if "tests/hooks/test-lib-hooks.sh" not in paths:
  raise SystemExit("missing lib-hooks helper suite")
'
echo ""

echo "4. run-suite executes a required suite"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_success_fixture "$TMP"
output=$(python3 "$SCRIPT" run-suite --root "$TMP" "tests/scripts/pass-suite.sh" 2>&1)
status=$?
assert_success "run-suite exits zero for required suite" "$status"
assert_contains "run-suite prints required suite output" "$output" "pass-suite"
echo ""

echo "5. run-suite skips optional missing requirements"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_success_fixture "$TMP"
output=$(python3 "$SCRIPT" run-suite --root "$TMP" "tests/hooks/skipped-suite.sh" 2>&1)
status=$?
assert_success "run-suite exits zero for skipped optional suite" "$status"
assert_contains "run-suite reports the optional skip" "$output" "Skipping Optional Phase: missing definitely-missing-tool"
echo ""

echo "6. Local run executes required suites and skips optional missing requirements"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_success_fixture "$TMP"
output=$(python3 "$SCRIPT" run-local --root "$TMP" 2>&1)
status=$?
assert_success "fixture local run exits zero" "$status"
assert_contains "required suite output is shown" "$output" "pass-suite"
assert_contains "optional phase skip is reported" "$output" "Skipping Optional Phase: missing definitely-missing-tool"
assert_contains "fixture local run summary is correct" "$output" "All 1 test suites passed."
echo ""

echo "7. Local run preserves failures and reports the failed suite"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_failure_fixture "$TMP"
if output=$(python3 "$SCRIPT" run-local --root "$TMP" 2>&1); then
  status=0
else
  status=$?
fi
assert_failure "failing fixture exits non-zero" "$status"
assert_contains "failing fixture output is shown" "$output" "about to fail"
assert_contains "failure summary is printed" "$output" "## FAILED (1 of 1 suites)"
assert_contains "failed suite path is listed" "$output" "tests/scripts/failing-suite.sh"
echo ""

echo "8. SIGINT during run-local prints partial summary and exits 130"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_success_fixture "$TMP"
# Replace the pass-suite with one that sends SIGINT to the parent Python process
cat > "$TMP/tests/scripts/pass-suite.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "pass-suite"
EOF
chmod +x "$TMP/tests/scripts/pass-suite.sh"
# Append an interrupter suite that fires SIGINT at the manifest runner's PID
cat >> "$TMP/scripts/harness/suite-manifest.json" <<'EOF_UNUSED'
EOF_UNUSED
# Build a fixture that has one passing suite then one that SIGINTs the runner
cat > "$TMP/scripts/harness/suite-manifest.json" <<'EOF'
{
  "schemaVersion": "1.0",
  "description": "interrupt-fixture",
  "phases": [{ "id": "scripts", "label": "Script Behavior" }],
  "suites": [
    { "id": "pass-suite", "path": "tests/scripts/pass-suite.sh", "phase": "scripts", "ciLabel": "pass" },
    { "id": "interrupt-suite", "path": "tests/scripts/interrupt-suite.sh", "phase": "scripts", "ciLabel": "interrupt" }
  ]
}
EOF
cat > "$TMP/tests/scripts/interrupt-suite.sh" <<'EOF'
#!/usr/bin/env bash
# Send SIGINT to the parent process group so the Python harness catches it.
kill -INT "$(ps -o ppid= -p $$)" 2>/dev/null || true
sleep 2
EOF
chmod +x "$TMP/tests/scripts/interrupt-suite.sh"
interrupt_output=$(python3 "$SCRIPT" run-local --root "$TMP" 2>&1) || interrupt_rc=$?
interrupt_rc=${interrupt_rc:-0}
assert_contains "interrupted run prints partial summary" "$interrupt_output" "INTERRUPTED"
assert_contains "interrupted run shows completed count" "$interrupt_output" "completed 1 suites"
echo ""

finish_tests