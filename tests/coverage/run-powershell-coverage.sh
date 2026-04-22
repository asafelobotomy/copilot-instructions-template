#!/usr/bin/env bash
# tests/coverage/run-powershell-coverage.sh -- deterministic PowerShell coverage driver.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
PWSH_BIN=$(bash "$REPO_ROOT/scripts/harness/resolve-powershell.sh" || true)
TRACE_PATH="${PWSH_COVERAGE_TRACE:-}"
WRAPPER="$REPO_ROOT/tests/coverage/invoke-powershell-with-coverage.ps1"

if [[ -z "$PWSH_BIN" ]]; then
  echo "PowerShell is required for PowerShell coverage collection" >&2
  exit 1
fi

if [[ -z "$TRACE_PATH" ]]; then
  echo "PWSH_COVERAGE_TRACE must be set" >&2
  exit 1
fi

run_hook() {
  local script_path="$1" payload="$2"
  "$PWSH_BIN" -NoLogo -NoProfile -File "$WRAPPER" -ScriptPath "$script_path" -TracePath "$TRACE_PATH" -Payload "$payload" >/dev/null
}

TEMPLATE_HOOKS="$REPO_ROOT/hooks/scripts"

run_hook "$TEMPLATE_HOOKS/session-start.ps1" '{}'

TMP_NPM=$(mktemp -d)
printf '{"name":"coverage-project","version":"1.2.3"}\n' > "$TMP_NPM/package.json"
(
  cd "$TMP_NPM"
  run_hook "$TEMPLATE_HOOKS/session-start.ps1" '{}'
)
rm -rf "$TMP_NPM"

run_hook "$TEMPLATE_HOOKS/post-edit-lint.ps1" '{"tool_name":"read_file","tool_input":{}}'
run_hook "$TEMPLATE_HOOKS/post-edit-lint.ps1" 'not-json'
TMP_EDIT=$(mktemp)
run_hook "$TEMPLATE_HOOKS/post-edit-lint.ps1" "{\"tool_name\":\"edit_file\",\"tool_input\":{\"filePath\":\"$TMP_EDIT\"}}"
rm -f "$TMP_EDIT"

run_hook "$TEMPLATE_HOOKS/guard-destructive.ps1" '{"tool_name":"read_file","tool_input":{"filePath":"/tmp/x"}}'
run_hook "$TEMPLATE_HOOKS/guard-destructive.ps1" '{"tool_name":"bash","tool_input":{"command":"rm -rf /"}}'
run_hook "$TEMPLATE_HOOKS/guard-destructive.ps1" '{"tool_name":"command","tool_input":{"command":"git push origin --force"}}'
run_hook "$TEMPLATE_HOOKS/guard-destructive.ps1" '{"tool_name":"bash","tool_input":{"command":"git status"}}'

TMP_RETRO=$(mktemp -d)
(
  cd "$TMP_RETRO"
  run_hook "$TEMPLATE_HOOKS/enforce-retrospective.ps1" '{"stop_hook_active": false}'
)
rm -rf "$TMP_RETRO"

TMP_HB=$(mktemp -d)
mkdir -p "$TMP_HB/.copilot/workspace/identity" "$TMP_HB/.copilot/workspace/knowledge/diaries" "$TMP_HB/.copilot/workspace/operations" "$TMP_HB/.copilot/workspace/runtime"
touch "$TMP_HB/.copilot/workspace/operations/HEARTBEAT.md"
(
  cd "$TMP_HB"
  run_hook "$TEMPLATE_HOOKS/enforce-retrospective.ps1" '{"stop_hook_active": false}'
)
rm -rf "$TMP_HB"

TMP_CTX=$(mktemp -d)
mkdir -p "$TMP_CTX/.copilot/workspace/identity" "$TMP_CTX/.copilot/workspace/knowledge/diaries" "$TMP_CTX/.copilot/workspace/operations" "$TMP_CTX/.copilot/workspace/runtime"
printf 'HEARTBEAT_OK\n' > "$TMP_CTX/.copilot/workspace/operations/HEARTBEAT.md"
printf 'recent memory entry\n' > "$TMP_CTX/.copilot/workspace/knowledge/MEMORY.md"
printf 'heuristic: verify before commit\n' > "$TMP_CTX/.copilot/workspace/identity/SOUL.md"
(
  cd "$TMP_CTX"
  run_hook "$TEMPLATE_HOOKS/save-context.ps1" '{}'
)
rm -rf "$TMP_CTX"
