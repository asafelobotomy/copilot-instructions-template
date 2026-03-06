#!/usr/bin/env bash
# tests/run-all.sh -- canonical local test entrypoint for the template repo.
set -euo pipefail

run_phase() {
  local label="$1"
  shift
  echo ""
  echo "## $label"
  for test_script in "$@"; do
    echo "==> $test_script"
    bash "$test_script"
  done
}

run_phase "Hook Behavior" \
  "tests/test-hook-session-start.sh" \
  "tests/test-hook-post-edit-lint.sh" \
  "tests/test-hook-enforce-retrospective.sh" \
  "tests/test-hook-save-context.sh" \
  "tests/test-hooks-powershell.sh" \
  "tests/test-guard-destructive.sh" \
  "tests/test-guard-destructive-powershell.sh"

run_phase "Script Behavior" \
  "tests/test-sync-version.sh" \
  "tests/test-sync-doc-index.sh" \
  "tests/test-security-edge-cases.sh"

run_phase "Documentation And Contracts" \
  "tests/test-release-contracts.sh" \
  "tests/test-customization-contracts.sh" \
  "tests/test-template-parity.sh"

echo "All test suites passed."
