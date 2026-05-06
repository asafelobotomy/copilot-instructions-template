#!/usr/bin/env bash
# tests/scripts/test-run-isolated-shell-stdin.sh -- tests for scripts/harness/run-isolated-shell-stdin.sh
# Run: bash tests/scripts/test-run-isolated-shell-stdin.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
trap cleanup_dirs EXIT

SCRIPT="$REPO_ROOT/scripts/harness/run-isolated-shell-stdin.sh"
PWSH=$(bash "$REPO_ROOT/scripts/harness/resolve-powershell.sh" || true)

echo "=== run-isolated-shell-stdin.sh ==="
echo ""

echo "1. Invalid usage without stdin is rejected"
output=$(bash "$SCRIPT" 2>&1) || true
assert_contains "usage is printed" "$output" "Usage: bash scripts/harness/run-isolated-shell-stdin.sh"
echo ""

echo "2. Strict bash here-doc form runs inside isolated shell"
output=$(bash "$SCRIPT" --shell bash --strict <<'EOF'
printf 'heredoc-ok\n'
EOF
)
command_rc=$?
assert_success "strict bash here-doc exits zero" "$command_rc"
assert_contains "strict bash here-doc prints output" "$output" "heredoc-ok"
echo ""

echo "3. sh here-doc form supports POSIX syntax"
output=$(bash "$SCRIPT" --shell sh <<'EOF'
printf '%s\n' 'stdin-sh-ok'
EOF
)
command_rc=$?
assert_success "sh here-doc exits zero" "$command_rc"
assert_contains "sh here-doc prints output" "$output" "stdin-sh-ok"
echo ""

echo "4. zsh here-doc form supports zsh-specific syntax"
if command -v zsh >/dev/null 2>&1; then
  output=$(bash "$SCRIPT" --shell zsh <<'EOF'
print -r -- "$ZSH_VERSION"
EOF
)
  command_rc=$?
  assert_success "zsh here-doc exits zero" "$command_rc"
  if [[ -n "$output" ]]; then
    pass_note "zsh here-doc exposes ZSH_VERSION"
  else
    fail_note "zsh here-doc exposes ZSH_VERSION" "     output was empty"
  fi
else
  pass_note "zsh here-doc coverage skipped when zsh is unavailable"
fi
echo ""

echo "5. PowerShell here-doc form supports pwsh snippets"
if [[ -n "$PWSH" ]]; then
  output=$(bash "$SCRIPT" --shell pwsh <<'EOF'
Write-Output 'stdin-pwsh-ok'
EOF
)
  command_rc=$?
  assert_success "pwsh here-doc exits zero" "$command_rc"
  assert_contains "pwsh here-doc prints output" "$output" "stdin-pwsh-ok"
else
  pass_note "pwsh here-doc coverage skipped when PowerShell is unavailable"
fi
echo ""

echo "6. --cwd changes the child working directory"
tmpdir=$(mktemp -d)
CLEANUP_DIRS+=("$tmpdir")
mkdir -p "$tmpdir/nested"
output=$(bash "$SCRIPT" --cwd "$tmpdir/nested" --shell bash <<'EOF'
pwd
EOF
)
command_rc=$?
assert_success "cwd here-doc exits zero" "$command_rc"
assert_contains "cwd here-doc prints requested directory" "$output" "$tmpdir/nested"
echo ""

finish_tests