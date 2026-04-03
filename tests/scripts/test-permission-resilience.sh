#!/usr/bin/env bash
# tests/scripts/test-permission-resilience.sh -- permission and file-mode resilience tests
# Verifies hook scripts maintain correct permissions and behave correctly
# when permissions are degraded (e.g. after git checkout, archive extraction).
# Run: bash tests/scripts/test-permission-resilience.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

HOOKS_DIR="$REPO_ROOT/template/hooks/scripts"
PARITY_DIR="$REPO_ROOT/.github/hooks/scripts"

# Exhaustive list of shell hook scripts that must be executable.
HOOK_SCRIPTS=(
  guard-destructive.sh
  lib-hooks.sh
  mcp-npx.sh
  mcp-uvx.sh
  post-edit-lint.sh
  pulse.sh
  save-context.sh
  scan-secrets.sh
  session-start.sh
  subagent-start.sh
  subagent-stop.sh
)

echo "=== Permission resilience tests ==="
echo ""

# ── 1. Template hook scripts exist and are executable ─────────────────────────
echo "1. All template hook scripts exist and are executable"
for script in "${HOOK_SCRIPTS[@]}"; do
  path="$HOOKS_DIR/$script"
  if [[ -f "$path" ]]; then
    pass_note "template/$script exists"
  else
    fail_note "template/$script exists" "file not found: $path"
    continue
  fi
  if [[ -x "$path" ]]; then
    pass_note "template/$script is executable"
  else
    fail_note "template/$script is executable" "missing +x: $path"
  fi
done
echo ""

# ── 2. Parity hook scripts exist and are executable ───────────────────────────
echo "2. All .github parity hook scripts exist and are executable"
for script in "${HOOK_SCRIPTS[@]}"; do
  path="$PARITY_DIR/$script"
  if [[ -f "$path" ]]; then
    pass_note ".github/$script exists"
  else
    fail_note ".github/$script exists" "file not found: $path"
    continue
  fi
  if [[ -x "$path" ]]; then
    pass_note ".github/$script is executable"
  else
    fail_note ".github/$script is executable" "missing +x: $path"
  fi
done
echo ""

# ── 3. No hook script is world-writable ───────────────────────────────────────
# Over-permissive files (o+w / 777) are a security risk — any local user could
# inject code into a hook that runs with the developer's privileges.
echo "3. No template hook script is world-writable"
for script in "${HOOK_SCRIPTS[@]}"; do
  path="$HOOKS_DIR/$script"
  [[ -f "$path" ]] || continue
  perms=$(stat -c '%a' "$path" 2>/dev/null || stat -f '%Lp' "$path" 2>/dev/null)
  # Last digit: "other" permission bits. 2,3,6,7 mean write is set.
  other_bits="${perms: -1}"
  if [[ "$other_bits" =~ [2367] ]]; then
    fail_note "$script not world-writable" "permissions $perms — other has write"
  else
    pass_note "$script not world-writable (mode $perms)"
  fi
done
echo ""

# ── 4. All shell scripts have a valid shebang ────────────────────────────────
echo "4. All hook scripts have a bash shebang"
for script in "${HOOK_SCRIPTS[@]}"; do
  path="$HOOKS_DIR/$script"
  [[ -f "$path" ]] || continue
  first_line=$(head -1 "$path")
  if [[ "$first_line" == "#!/usr/bin/env bash" || "$first_line" == "#!/bin/bash" ]]; then
    pass_note "$script has bash shebang"
  else
    fail_note "$script has bash shebang" "     first line: $first_line"
  fi
done
echo ""

# ── 5. All hook scripts use strict mode ───────────────────────────────────────
# Every script must contain either 'set -euo pipefail' or 'set -uo pipefail'.
echo "5. All hook scripts use strict mode (set -euo pipefail or -uo pipefail)"
for script in "${HOOK_SCRIPTS[@]}"; do
  # lib-hooks.sh is a sourced library, not a standalone script — exempt.
  [[ "$script" == "lib-hooks.sh" ]] && continue
  path="$HOOKS_DIR/$script"
  [[ -f "$path" ]] || continue
  if grep -Eq 'set -[eu]*o pipefail' "$path"; then
    pass_note "$script strict mode"
  else
    fail_note "$script strict mode" "     missing set -euo pipefail / set -uo pipefail"
  fi
done
echo ""

# ── 6. Guard-destructive works via bash invocation when +x stripped ───────────
# After git checkout or archive extraction the executable bit may be lost.
# Hooks invoked as `bash script.sh` must still produce valid JSON output.
echo "6. guard-destructive.sh works via 'bash' invocation without +x"
GUARD="$HOOKS_DIR/guard-destructive.sh"
TMPDIR_PERM=$(mktemp -d)
cleanup_perm() { rm -rf "$TMPDIR_PERM"; }
trap cleanup_perm EXIT

cp "$GUARD" "$TMPDIR_PERM/guard-destructive.sh"
cp "$HOOKS_DIR/lib-hooks.sh" "$TMPDIR_PERM/lib-hooks.sh"
chmod -x "$TMPDIR_PERM/guard-destructive.sh"

# Deny path
deny_out=$(printf '{"tool_name":"bash","tool_input":{"command":"rm -rf /"}}' \
  | bash "$TMPDIR_PERM/guard-destructive.sh" 2>/dev/null)
assert_valid_json "deny response is valid JSON (no +x)" "$deny_out"
assert_matches "deny path still triggers (no +x)" "$deny_out" '"permissionDecision": "deny"'

# Continue path
cont_out=$(printf '{"tool_name":"bash","tool_input":{"command":"ls -la"}}' \
  | bash "$TMPDIR_PERM/guard-destructive.sh" 2>/dev/null)
assert_valid_json "continue response is valid JSON (no +x)" "$cont_out"
assert_matches "continue path still works (no +x)" "$cont_out" '"continue": true'
echo ""

# ── 7. Utility scripts in scripts/ are executable ────────────────────────────
# The repo's own utility scripts must also be executable for CI and local use.
echo "7. Repo utility scripts are executable"
UTIL_SCRIPTS=(
  scripts/workspace/check-workspace-drift.sh
  scripts/release/plan-release.sh
  scripts/tests/run-all-captured.sh
  scripts/tests/select-targeted-tests.sh
  scripts/release/sync-version.sh
  scripts/workspace/sync-workspace-index.sh
  scripts/sync/sync-models.sh
  scripts/sync/sync-template-parity.sh
  scripts/validate/validate-agent-frontmatter.sh
  scripts/release/stub-migration.sh
  scripts/lib.sh
)
for rel_path in "${UTIL_SCRIPTS[@]}"; do
  path="$REPO_ROOT/$rel_path"
  if [[ ! -f "$path" ]]; then
    # Script may have been renamed; skip gracefully
    continue
  fi
  if [[ -x "$path" ]]; then
    pass_note "$rel_path is executable"
  else
    fail_note "$rel_path is executable" "missing +x: $path"
  fi
done
echo ""

# ── 8. Permission recovery — chmod +x restores hook function ─────────────────
echo "8. Permission recovery — restored +x makes script directly executable"
cp "$GUARD" "$TMPDIR_PERM/guard-recover.sh"
cp "$HOOKS_DIR/lib-hooks.sh" "$TMPDIR_PERM/lib-hooks.sh" 2>/dev/null || true
chmod -x "$TMPDIR_PERM/guard-recover.sh"
chmod +x "$TMPDIR_PERM/guard-recover.sh"
recover_out=$(printf '{"tool_name":"bash","tool_input":{"command":"rm -rf /"}}' \
  | "$TMPDIR_PERM/guard-recover.sh" 2>/dev/null)
assert_valid_json "recovered script produces valid JSON" "$recover_out"
assert_matches "recovered script denies dangerous command" "$recover_out" '"permissionDecision": "deny"'
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
finish_tests
