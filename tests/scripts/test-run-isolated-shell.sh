#!/usr/bin/env bash
# tests/scripts/test-run-isolated-shell.sh -- tests for scripts/harness/run-isolated-shell.sh
# Run: bash tests/scripts/test-run-isolated-shell.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
trap cleanup_dirs EXIT

SCRIPT="$REPO_ROOT/scripts/harness/run-isolated-shell.sh"
PWSH=$(bash "$REPO_ROOT/scripts/harness/resolve-powershell.sh" || true)

echo "=== run-isolated-shell.sh ==="
echo ""

echo "1. Invalid usage is rejected"
output=$(bash "$SCRIPT" 2>&1) || true
assert_contains "usage is printed" "$output" "Usage: bash scripts/harness/run-isolated-shell.sh"
echo ""

echo "2. Bash command form runs inside isolated child shell"
output=$(bash "$SCRIPT" --command 'printf "bash-ok\\n"')
command_rc=$?
assert_success "bash command form exits zero" "$command_rc"
assert_contains "bash command form prints output" "$output" "bash-ok"
echo ""

echo "3. Bash strict mode stops on failure and preserves child exit code"
output=$(bash "$SCRIPT" --shell bash --strict --command $'printf "before\\n"\nfalse\nprintf "after\\n"' 2>&1) && command_rc=0 || command_rc=$?
assert_failure "strict bash exits non-zero" "$command_rc"
if [[ "$command_rc" -eq 1 ]]; then
  pass_note "strict bash preserves child exit code"
else
  fail_note "strict bash preserves child exit code" "     expected exit 1, got: $command_rc"
fi
assert_contains "strict bash prints output before failure" "$output" "before"
if grep -Fq -- "after" <<< "$output"; then
  fail_note "strict bash prevents later commands" "     unexpected output after failure: after"
else
  pass_note "strict bash prevents later commands"
fi
echo ""

echo "4. --cwd changes the child working directory"
tmpdir=$(mktemp -d)
CLEANUP_DIRS+=("$tmpdir")
mkdir -p "$tmpdir/nested"
output=$(bash "$SCRIPT" --cwd "$tmpdir/nested" --command 'pwd')
command_rc=$?
assert_success "cwd form exits zero" "$command_rc"
assert_contains "cwd form prints requested directory" "$output" "$tmpdir/nested"
echo ""

echo "5. Unsupported shells fail clearly"
output=$(bash "$SCRIPT" --shell fish --command 'echo nope' 2>&1) && command_rc=0 || command_rc=$?
assert_failure "unsupported shell exits non-zero" "$command_rc"
assert_contains "unsupported shell is reported" "$output" "Unsupported shell: fish"
echo ""

echo "6. sh shell mode runs POSIX snippets"
output=$(bash "$SCRIPT" --shell sh --command 'printf "%s\n" "sh-ok"')
command_rc=$?
assert_success "sh shell exits zero" "$command_rc"
assert_contains "sh shell prints output" "$output" "sh-ok"
echo ""

echo "7. Strict sh mode stops on undefined variables"
output=$(bash "$SCRIPT" --shell sh --strict --command $'printf "before\\n"\n: "$missing"\nprintf "after\\n"' 2>&1) && command_rc=0 || command_rc=$?
assert_failure "strict sh exits non-zero" "$command_rc"
assert_contains "strict sh prints output before failure" "$output" "before"
if grep -Fq -- "after" <<< "$output"; then
  fail_note "strict sh prevents later commands" "     unexpected output after failure: after"
else
  pass_note "strict sh prevents later commands"
fi
echo ""

echo "8. zsh shell mode supports zsh-specific variables"
if command -v zsh >/dev/null 2>&1; then
  output=$(bash "$SCRIPT" --shell zsh --command 'print -r -- "$ZSH_VERSION"')
  command_rc=$?
  assert_success "zsh shell exits zero" "$command_rc"
  if [[ -n "$output" ]]; then
    pass_note "zsh shell exposes ZSH_VERSION"
  else
    fail_note "zsh shell exposes ZSH_VERSION" "     output was empty"
  fi
else
  pass_note "zsh shell coverage skipped when zsh is unavailable"
fi
echo ""

echo "9. PowerShell shell mode supports pwsh snippets"
if [[ -n "$PWSH" ]]; then
  output=$(bash "$SCRIPT" --shell pwsh --command 'Write-Output "pwsh-ok"')
  command_rc=$?
  assert_success "pwsh shell exits zero" "$command_rc"
  assert_contains "pwsh shell prints output" "$output" "pwsh-ok"
else
  pass_note "pwsh shell coverage skipped when PowerShell is unavailable"
fi
echo ""

echo "10. PowerShell strict mode stops on undefined variables"
if [[ -n "$PWSH" ]]; then
  output=$(bash "$SCRIPT" --shell pwsh --strict --command $'Write-Output "before"\n$missing\nWrite-Output "after"' 2>&1) && command_rc=0 || command_rc=$?
  assert_failure "strict pwsh exits non-zero" "$command_rc"
  assert_contains "strict pwsh prints output before failure" "$output" "before"
  if grep -Fq -- "after" <<< "$output"; then
    fail_note "strict pwsh prevents later commands" "     unexpected output after failure: after"
  else
    pass_note "strict pwsh prevents later commands"
  fi
else
  pass_note "strict pwsh coverage skipped when PowerShell is unavailable"
fi
echo ""

finish_tests