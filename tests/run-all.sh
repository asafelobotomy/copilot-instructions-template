#!/usr/bin/env bash
# tests/run-all.sh -- canonical local test entrypoint for the template repo.
set -uo pipefail

FAILED_SUITES=0
FAILED_LIST=()
TOTAL_SUITES=0

# ── Pre-flight: structural lint checks ────────────────────────────────────────
echo "## Pre-flight"
if bash scripts/ci/validate-test-output.sh; then
  echo "  pre-flight: validate-test-output OK"
else
  echo "  pre-flight: validate-test-output FAILED"
  FAILED_SUITES=1
  FAILED_LIST+=("scripts/ci/validate-test-output.sh")
fi
echo ""

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
  "tests/hooks/test-hook-session-start.sh" \
  "tests/hooks/test-hook-pulse.sh" \
  "tests/hooks/test-hook-post-edit-lint.sh" \
  "tests/hooks/test-hook-save-context.sh" \
  "tests/hooks/test-guard-destructive.sh" \
  "tests/hooks/test-hook-scan-secrets.sh"

run_optional_phase "Hook Behavior (PowerShell parity)" "pwsh" "pwsh" \
  "tests/hooks/test-hooks-powershell.sh" \
  "tests/hooks/test-guard-destructive-powershell.sh"

run_phase "Script Behavior" \
  "tests/scripts/test-release-plan.sh" \
  "tests/scripts/test-sync-version.sh" \
  "tests/scripts/test-stub-migration.sh" \
  "tests/scripts/test-sync-workspace-index.sh" \
  "tests/scripts/test-sync-models.sh" \
  "tests/scripts/test-validate-agent-frontmatter.sh" \
  "tests/scripts/test-sync-template-parity.sh" \
  "tests/scripts/test-security-edge-cases.sh" \
  "tests/scripts/test-copilot-audit.sh" \
  "tests/scripts/test-mcp-launchers.sh" \
  "tests/scripts/test-workspace-drift.sh" \
  "tests/scripts/test-permission-resilience.sh"

run_phase "Documentation And Contracts" \
  "tests/contracts/test-release-contracts.sh" \
  "tests/contracts/test-customization-contracts.sh" \
  "tests/contracts/test-template-parity.sh" \
  "tests/contracts/test-starter-kits.sh" \
  "tests/contracts/test-setup-update-contracts.sh"

echo ""
if [[ $FAILED_SUITES -gt 0 ]]; then
  echo "## FAILED ($FAILED_SUITES of $TOTAL_SUITES suites)"
  for f in "${FAILED_LIST[@]}"; do
    echo "  - $f"
  done
  exit 1
fi

echo "All $TOTAL_SUITES test suites passed."
