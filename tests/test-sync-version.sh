#!/usr/bin/env bash
# tests/test-sync-version.sh — unit tests for scripts/sync-version.sh
# Run: bash tests/test-sync-version.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"
trap 'teardown_sandbox' EXIT

# Path to the script under test (relative to repo root)
SCRIPT="$REPO_ROOT/scripts/sync-version.sh"

# ── Helpers ────────────────────────────────────────────────────────────────────

setup_sandbox() {
  local ver="${1:-1.2.3}"
  SANDBOX=$(mktemp -d)
  # Minimal tree matching the paths the script targets
  mkdir -p "$SANDBOX/template" "$SANDBOX/.github"
  echo "$ver" > "$SANDBOX/VERSION.md"
  cat > "$SANDBOX/template/copilot-instructions.md" <<'INST'
# Copilot Instructions Template

> **Template version**: 0.0.0 <!-- x-release-please-version --> | **Applied**: 2025-01-01
> Living document.
INST

  printf '{"." : "0.0.0"}\n' > "$SANDBOX/.release-please-manifest.json"

  printf 'Current template version: **0.0.0** <!-- x-release-please-version --> — see CHANGELOG.md.\n' \
    > "$SANDBOX/README.md"

  cat > "$SANDBOX/.github/copilot-instructions.md" <<'DVINST'
# Developer Instructions — copilot-instructions-template

> Role: AI developer for this repository. Template version: 0.0.0 <!-- x-release-please-version --> | Updated: 2025-01-01
DVINST
}

teardown_sandbox() {
  [[ -n "${SANDBOX:-}" ]] && rm -rf "$SANDBOX"
}

assert_fail() {
  local desc="$1" actual_exit="$2"
  if [[ "$actual_exit" -ne 0 ]]; then
    pass_note "$desc"
  else
    fail_note "$desc" "     expected non-zero exit, got 0"
  fi
}

run_script() {
  # Run the script with ROOT_DIR pointing to our sandbox
  ROOT_DIR="$SANDBOX" bash "$SCRIPT" 2>&1
  return $?
}

# ── Tests ──────────────────────────────────────────────────────────────────────

echo "=== sync-version.sh unit tests ==="
echo ""

# ── 1. Happy path — updates both files ─────────────────────────────────────────
echo "1. Happy path — updates version 0.0.0 → 1.2.3"
setup_sandbox "1.2.3"
run_script
exit_code=$?
assert_success "exits 0" "$exit_code"
assert_file_contains "copilot-instructions updated" "$SANDBOX/template/copilot-instructions.md" "Template version\*\*: 1.2.3"
assert_file_not_contains "old version gone"         "$SANDBOX/template/copilot-instructions.md" "Template version\*\*: 0.0.0"
assert_file_contains "dev-instructions updated"     "$SANDBOX/.github/copilot-instructions.md"  "Template version: 1.2.3"
assert_file_not_contains "dev-instructions old ver" "$SANDBOX/.github/copilot-instructions.md"  "Template version: 0.0.0"
assert_file_contains "readme updated"              "$SANDBOX/README.md"                         "\*\*1.2.3\*\*"
assert_file_not_contains "readme old version gone" "$SANDBOX/README.md"                         "\*\*0.0.0\*\*"
assert_file_contains "manifest updated"             "$SANDBOX/.release-please-manifest.json"   '"1.2.3"'
assert_file_not_contains "old manifest gone"        "$SANDBOX/.release-please-manifest.json"   '"0.0.0"'
teardown_sandbox
echo ""

# ── 2. Inline x-release-please-version marker is preserved ────────────────────
echo "2. Inline marker preserved after substitution"
setup_sandbox "2.0.0"
run_script >/dev/null
assert_file_contains "marker still in instructions" "$SANDBOX/template/copilot-instructions.md" "x-release-please-version"
assert_file_contains "marker still in dev-instructions" "$SANDBOX/.github/copilot-instructions.md" "x-release-please-version"
teardown_sandbox
echo ""

# ── 3. Idempotency — running twice leaves tree clean ──────────────────────────
echo "3. Idempotency — second run is a no-op"
setup_sandbox "3.1.0"
run_script >/dev/null
sha1_inst=$(sha256sum "$SANDBOX/template/copilot-instructions.md")
sha1_manifest=$(sha256sum "$SANDBOX/.release-please-manifest.json")
sha1_readme=$(sha256sum "$SANDBOX/README.md")
run_script >/dev/null
sha2_inst=$(sha256sum "$SANDBOX/template/copilot-instructions.md")
sha2_manifest=$(sha256sum "$SANDBOX/.release-please-manifest.json")
sha2_readme=$(sha256sum "$SANDBOX/README.md")
if [[ "$sha1_inst" == "$sha2_inst" ]]; then
  pass_note "copilot-instructions idempotent"
else
  fail_note "copilot-instructions changed on second run"
fi
if [[ "$sha1_manifest" == "$sha2_manifest" ]]; then
  pass_note "manifest idempotent"
else
  fail_note "manifest changed on second run"
fi
if [[ "$sha1_readme" == "$sha2_readme" ]]; then
  pass_note "readme idempotent"
else
  fail_note "readme changed on second run"
fi
teardown_sandbox
echo ""

# ── 4. Multi-digit version (10.21.300) ────────────────────────────────────────
echo "4. Multi-digit version (10.21.300)"
setup_sandbox "10.21.300"
run_script >/dev/null
assert_file_contains "manifest has multi-digit version" "$SANDBOX/.release-please-manifest.json" '"10.21.300"'
teardown_sandbox
echo ""

# ── 5. Missing VERSION.md → non-zero exit ─────────────────────────────────────
echo "5. Missing VERSION.md exits non-zero"
SANDBOX=$(mktemp -d)
mkdir -p "$SANDBOX/.github"
# Intentionally do NOT create VERSION.md
ROOT_DIR="$SANDBOX" bash "$SCRIPT" 2>/dev/null
assert_fail "missing VERSION.md → exit non-zero" $?
teardown_sandbox
echo ""

# ── 6. Invalid semver (alpha string) → non-zero exit ─────────────────────────
echo "6. Invalid semver 'not-a-version' exits non-zero"
setup_sandbox
echo "not-a-version" > "$SANDBOX/VERSION.md"
run_script 2>/dev/null
assert_fail "invalid semver → exit non-zero" $?
teardown_sandbox
echo ""

# ── 7. Invalid semver (missing patch) → non-zero exit ────────────────────────
echo "7. Incomplete semver '1.2' exits non-zero"
setup_sandbox
echo "1.2" > "$SANDBOX/VERSION.md"
run_script 2>/dev/null
assert_fail "incomplete semver → exit non-zero" $?
teardown_sandbox
echo ""

# ── 8. VERSION.md with leading/trailing whitespace → handled ──────────────────
echo "8. VERSION.md with surrounding whitespace"
setup_sandbox
printf "  4.5.6  \n" > "$SANDBOX/VERSION.md"
run_script >/dev/null
assert_file_contains "strips whitespace — manifest updated" "$SANDBOX/.release-please-manifest.json" '"4.5.6"'
teardown_sandbox
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
finish_tests
