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

run_optional_phase() {
  local label="$1"
  local requirement_label="$2"
  local requirement_cmd="$3"
  shift 3

  echo ""
  echo "## $label"
  if ! command -v "$requirement_cmd" >/dev/null 2>&1; then
    echo "Skipping $label: missing $requirement_label"
    return
  fi
  # Functional probe: the binary must actually execute without crashing.
  if ! "$requirement_cmd" -NoProfile -NonInteractive -Command 'exit 0' >/dev/null 2>&1; then
    echo "Skipping $label: $requirement_label is installed but non-functional (runtime error)"
    return
  fi

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
  "tests/test-guard-destructive.sh" \
  "tests/test-release-contracts.sh"

run_optional_phase "Hook Behavior (PowerShell parity)" "pwsh" "pwsh" \
  "tests/test-hooks-powershell.sh" \
  "tests/test-guard-destructive-powershell.sh"

run_phase "Script Behavior" \
  "tests/test-sync-version.sh" \
  "tests/test-sync-doc-index.sh" \
  "tests/test-sync-models.sh" \
  "tests/test-security-edge-cases.sh"

run_phase "Documentation And Contracts" \
  "tests/test-customization-contracts.sh" \
  "tests/test-template-parity.sh"

echo "All test suites passed."
