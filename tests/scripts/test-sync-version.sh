#!/usr/bin/env bash
# tests/scripts/test-sync-version.sh — unit tests for scripts/release/sync-version.sh
# Run: bash tests/scripts/test-sync-version.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
trap 'teardown_sandbox' EXIT

# Path to the script under test (relative to repo root)
SCRIPT="$REPO_ROOT/scripts/release/sync-version.sh"

# ── Helpers ───────────────────────────────────────────────────────────────────

setup_sandbox() {
  local ver="${1:-1.2.3}"
  local managed_ver="${2:-$ver}"
  SANDBOX=$(mktemp -d)
  # Minimal tree matching the paths the script targets
  mkdir -p "$SANDBOX/template" "$SANDBOX/.github"
  echo "$ver" > "$SANDBOX/VERSION.md"
  cat > "$SANDBOX/template/copilot-instructions.md" <<'INST'
# Copilot Instructions Template

> **Template version**: __VERSION__ <!-- x-release-please-version --> | **Applied**: 2025-01-01
> Living document.
INST
  sed -i "s/__VERSION__/$managed_ver/" "$SANDBOX/template/copilot-instructions.md"

  printf '{"." : "%s"}\n' "$managed_ver" > "$SANDBOX/.release-please-manifest.json"

  printf 'Current template version: **%s** <!-- x-release-please-version --> — see CHANGELOG.md.\n' "$managed_ver" \
    > "$SANDBOX/README.md"

  cat > "$SANDBOX/.github/copilot-instructions.md" <<'DVINST'
# Developer Instructions — copilot-instructions-template

> Role: AI developer for this repository. Template version: __VERSION__ <!-- x-release-please-version --> | Updated: 2025-01-01
DVINST
  sed -i "s/__VERSION__/$managed_ver/" "$SANDBOX/.github/copilot-instructions.md"
}

teardown_sandbox() {
  [[ -n "${SANDBOX:-}" ]] && rm -rf "$SANDBOX"
}

run_script() {
  ROOT_DIR="$SANDBOX" bash "$SCRIPT" 2>&1
}

# ── Tests ──────────────────────────────────────────────────────────────────────

echo "=== sync-version.sh unit tests ==="
echo ""

# ── 1. Happy path — matching files verify cleanly ─────────────────────────────
echo "1. Matching release-managed files verify cleanly"
setup_sandbox "1.2.3" "1.2.3"
output=$(run_script)
status=$?
assert_success "exits 0" "$status"
assert_contains "success message mentions VERSION.md" "$output" "Release-managed version references match VERSION.md (1.2.3)"
teardown_sandbox
echo ""

# ── 2. Drift is detected instead of rewritten ──────────────────────────────────
echo "2. Drift is reported instead of being rewritten"
setup_sandbox "1.2.3" "0.0.0"
output=$(run_script 2>&1)
status=$?
assert_failure "drift exits non-zero" "$status"
assert_contains "template drift is reported" "$output" "template/copilot-instructions.md"
assert_contains "manifest drift is reported" "$output" "version drift in .release-please-manifest.json"
teardown_sandbox
echo ""

# ── 3. Marker requirements are enforced ────────────────────────────────────────
echo "3. Missing release markers are reported"
setup_sandbox "2.0.0" "2.0.0"
printf 'Current template version: **2.0.0** — see CHANGELOG.md.\n' > "$SANDBOX/README.md"
output=$(run_script 2>&1)
status=$?
assert_failure "missing marker exits non-zero" "$status"
assert_contains "missing marker is reported" "$output" "missing x-release-please-version marker in README.md"
teardown_sandbox
echo ""

# ── 4. Read-only verification is stable ───────────────────────────────────────
echo "4. Verification is read-only across repeated runs"
setup_sandbox "3.1.0" "3.1.0"
sha1_inst=$(sha256sum "$SANDBOX/template/copilot-instructions.md")
sha1_manifest=$(sha256sum "$SANDBOX/.release-please-manifest.json")
sha1_readme=$(sha256sum "$SANDBOX/README.md")
sha1_dev=$(sha256sum "$SANDBOX/.github/copilot-instructions.md")
run_script >/dev/null
run_script >/dev/null
sha2_inst=$(sha256sum "$SANDBOX/template/copilot-instructions.md")
sha2_manifest=$(sha256sum "$SANDBOX/.release-please-manifest.json")
sha2_readme=$(sha256sum "$SANDBOX/README.md")
sha2_dev=$(sha256sum "$SANDBOX/.github/copilot-instructions.md")
if [[ "$sha1_inst" == "$sha2_inst" && "$sha1_manifest" == "$sha2_manifest" && "$sha1_readme" == "$sha2_readme" && "$sha1_dev" == "$sha2_dev" ]]; then
  pass_note "verification leaves files unchanged"
else
  fail_note "verification leaves files unchanged"
fi
teardown_sandbox
echo ""

# ── 5. Multi-digit version (10.21.300) ────────────────────────────────────────
echo "5. Multi-digit version (10.21.300) verifies cleanly"
setup_sandbox "10.21.300" "10.21.300"
output=$(run_script)
status=$?
assert_success "multi-digit version exits zero" "$status"
assert_contains "multi-digit version is echoed" "$output" "10.21.300"
teardown_sandbox
echo ""

# ── 6. Missing VERSION.md → non-zero exit ─────────────────────────────────────
echo "6. Missing VERSION.md exits non-zero"
SANDBOX=$(mktemp -d)
mkdir -p "$SANDBOX/.github"
ROOT_DIR="$SANDBOX" bash "$SCRIPT" 2>/dev/null
assert_failure "missing VERSION.md → exit non-zero" $?
teardown_sandbox
echo ""

# ── 7. Invalid semver (alpha string) → non-zero exit ─────────────────────────
echo "7. Invalid semver 'not-a-version' exits non-zero"
setup_sandbox "1.2.3" "1.2.3"
echo "not-a-version" > "$SANDBOX/VERSION.md"
run_script 2>/dev/null
assert_failure "invalid semver → exit non-zero" $?
teardown_sandbox
echo ""

# ── 8. VERSION.md with leading/trailing whitespace → handled ──────────────────
echo "8. VERSION.md with surrounding whitespace"
setup_sandbox "4.5.6" "4.5.6"
printf "  4.5.6  \n" > "$SANDBOX/VERSION.md"
output=$(run_script)
status=$?
assert_success "surrounding whitespace is tolerated" "$status"
assert_contains "whitespace-normalized version is echoed" "$output" "4.5.6"
teardown_sandbox
echo ""

# ── 9. Manifest drift is reported directly ────────────────────────────────────
echo "9. Manifest drift is reported directly"
setup_sandbox "7.8.9" "7.8.9"
printf '{"." : "7.8.8"}\n' > "$SANDBOX/.release-please-manifest.json"
output=$(run_script 2>&1)
status=$?
assert_failure "manifest drift exits non-zero" "$status"
assert_contains "manifest drift points at manifest file" "$output" ".release-please-manifest.json"
teardown_sandbox
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
finish_tests
