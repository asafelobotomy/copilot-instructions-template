#!/usr/bin/env bash
# tests/run-all.sh -- canonical local test entrypoint for the template repo.
set -uo pipefail

FAILED_SUITES=0
FAILED_LIST=()
TOTAL_SUITES=0

run_phase() {
  local label="$1"
  shift
  echo ""
  echo "## $label"
  for test_script in "$@"; do
    ((TOTAL_SUITES++))
    echo "==> $test_script"
    local start=$SECONDS
    if bash "$test_script"; then
      echo "  ($((SECONDS - start))s)"
    else
      echo "  ($((SECONDS - start))s) FAILED"
      ((FAILED_SUITES++))
      FAILED_LIST+=("$test_script")
    fi
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
    ((TOTAL_SUITES++))
    echo "==> $test_script"
    local start=$SECONDS
    if bash "$test_script"; then
      echo "  ($((SECONDS - start))s)"
    else
      echo "  ($((SECONDS - start))s) FAILED"
      ((FAILED_SUITES++))
      FAILED_LIST+=("$test_script")
    fi
  done
}

run_phase "Hook Behavior" \
  "tests/test-hook-session-start.sh" \
  "tests/test-hook-pulse.sh" \
  "tests/test-hook-post-edit-lint.sh" \
  "tests/test-hook-enforce-retrospective.sh" \
  "tests/test-hook-save-context.sh" \
  "tests/test-guard-destructive.sh" \
  "tests/test-hook-scan-secrets.sh" \
  "tests/test-release-contracts.sh"

run_optional_phase "Hook Behavior (PowerShell parity)" "pwsh" "pwsh" \
  "tests/test-hooks-powershell.sh" \
  "tests/test-guard-destructive-powershell.sh"

run_phase "Script Behavior" \
  "tests/test-release-plan.sh" \
  "tests/test-sync-version.sh" \
  "tests/test-stub-migration.sh" \
  "tests/test-sync-workspace-index.sh" \
  "tests/test-sync-models.sh" \
  "tests/test-validate-agent-frontmatter.sh" \
  "tests/test-sync-template-parity.sh" \
  "tests/test-security-edge-cases.sh" \
  "tests/test-copilot-audit.sh" \
  "tests/test-mcp-launchers.sh" \
  "tests/test-permission-resilience.sh"

run_phase "Documentation And Contracts" \
  "tests/test-customization-contracts.sh" \
  "tests/test-template-parity.sh" \
  "tests/test-starter-kits.sh" \
  "tests/test-setup-update-contracts.sh"

echo ""
if [[ $FAILED_SUITES -gt 0 ]]; then
  echo "## FAILED ($FAILED_SUITES of $TOTAL_SUITES suites)"
  for f in "${FAILED_LIST[@]}"; do
    echo "  - $f"
  done
  exit 1
fi

echo "All $TOTAL_SUITES test suites passed."
