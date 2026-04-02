#!/usr/bin/env bash
# tests/lib/powershell-hook-test-helpers.sh -- shared helpers for PowerShell hook test suites.

# shellcheck source=test-helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"

init_powershell_hook_test_context() {
  local script_path="$1"
  init_test_context "$script_path"
  SCRIPTS_DIR="$REPO_ROOT/template/hooks/scripts"
  # shellcheck disable=SC2034
  SESSION_START="$SCRIPTS_DIR/session-start.ps1"
  # shellcheck disable=SC2034
  POST_LINT="$SCRIPTS_DIR/post-edit-lint.ps1"
  # shellcheck disable=SC2034
  SAVE_CTX="$SCRIPTS_DIR/save-context.ps1"
  # shellcheck disable=SC2034
  PULSE="$SCRIPTS_DIR/pulse.ps1"
  PWSH=$(command -v pwsh || true)
}

ensure_pwsh_available() {
  if [[ -z "${PWSH:-}" ]]; then
    echo "pwsh is required for ${SUITE_NAME:-PowerShell hook tests}"
    exit 1
  fi
}

run_ps_script() {
  local script_path="$1" payload="$2"
  shift 2
  if [[ -n "${PWSH_COVERAGE_TRACE:-}" ]]; then
    if [[ $# -eq 0 ]]; then
      printf '%s' "$payload" | "$PWSH" -NoLogo -NoProfile -File "$REPO_ROOT/tests/coverage/invoke-powershell-with-coverage.ps1" -ScriptPath "$script_path" -TracePath "$PWSH_COVERAGE_TRACE" 2>/dev/null
      return
    fi
    printf '%s' "$payload" | "$PWSH" -NoLogo -NoProfile -File "$script_path" "$@" 2>/dev/null
    return
  fi

  printf '%s' "$payload" | "$PWSH" -NoLogo -NoProfile -File "$script_path" "$@" 2>/dev/null
}