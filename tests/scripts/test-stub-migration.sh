#!/usr/bin/env bash
# tests/scripts/test-stub-migration.sh -- unit tests for scripts/release/stub-migration.sh
# Run: bash tests/scripts/test-stub-migration.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
trap 'teardown_sandbox' EXIT

SCRIPT="$REPO_ROOT/scripts/release/stub-migration.sh"

setup_sandbox() {
  SANDBOX=$(mktemp -d)
  cat > "$SANDBOX/MIGRATION.md" <<'EOF'
# Migration Registry

**Available tags**: v1.0.0, v1.1.0

---

## v1.1.0

| Breaking | Sections changed | Sections added | Includes |
|----------|------------------|----------------|----------|
| No | §2, §10 | none | hooks |
EOF
}

teardown_sandbox() {
  [[ -n "${SANDBOX:-}" ]] && rm -rf "$SANDBOX"
}

run_script() {
  local tag="$1"
  (
    cd "$SANDBOX" || exit 1
    bash "$SCRIPT" "$tag"
  )
}

echo "=== stub-migration.sh unit tests ==="
echo ""

echo "1. Missing tag argument exits non-zero"
setup_sandbox
(
  cd "$SANDBOX" || exit 1
  bash "$SCRIPT" >/dev/null 2>&1
)
assert_failure "missing tag exits non-zero" $?
teardown_sandbox
echo ""

echo "2. Missing MIGRATION.md exits non-zero"
SANDBOX=$(mktemp -d)
(
  cd "$SANDBOX" || exit 1
  bash "$SCRIPT" "v2.0.0" >/dev/null 2>&1
)
assert_failure "missing MIGRATION.md exits non-zero" $?
teardown_sandbox
echo ""

echo "3. Inserts new tag block and updates Available tags"
setup_sandbox
run_script "v2.0.0" >/dev/null
assert_file_contains "available tags include new tag" "$SANDBOX/MIGRATION.md" "\*\*Available tags\*\*: .*v2\.0\.0"
assert_file_contains "new heading inserted" "$SANDBOX/MIGRATION.md" "^## v2\.0\.0$"
assert_file_contains "stub table row present" "$SANDBOX/MIGRATION.md" "\| TBD \| — \| — \| — \|"
assert_python_in_root "new tag inserted before first existing release heading" "$SANDBOX" '
text = (root / "MIGRATION.md").read_text(encoding="utf-8")
if text.index("## v2.0.0") > text.index("## v1.1.0"):
    raise SystemExit("new tag was not inserted before first existing release heading")
'
teardown_sandbox
echo ""

echo "4. Idempotent for existing tag"
setup_sandbox
run_script "v2.0.0" >/dev/null
before=$(sha256sum "$SANDBOX/MIGRATION.md")
run_script "v2.0.0" >/dev/null
after=$(sha256sum "$SANDBOX/MIGRATION.md")
if [[ "$before" == "$after" ]]; then
  pass_note "second run does not change file"
else
  fail_note "second run changed file"
fi
assert_python_in_root "tag appears only once" "$SANDBOX" '
import re
text = (root / "MIGRATION.md").read_text(encoding="utf-8")
if len(re.findall(r"^## v2\.0\.0$", text, re.MULTILINE)) != 1:
    raise SystemExit("expected exactly one heading for v2.0.0")
'
teardown_sandbox
echo ""

finish_tests
