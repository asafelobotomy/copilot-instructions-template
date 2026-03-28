#!/usr/bin/env bash
# tests/test-sync-models.sh -- contract tests for scripts/sync-models.sh
# Run: bash tests/test-sync-models.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/sync-models.sh"

# ─── Fixture helpers ──────────────────────────────────────────────────────────

make_models_md() {
  local dir="$1"
  cat > "$dir/MODELS.md" <<'MODELS'
# Model Registry

## coding
- ModelA
- ModelB

## doctor
- ModelC

## fast
- ModelD
- ModelE

## review
- ModelF

## setup
- ModelG
- ModelH

## update
- ModelI
MODELS
}

make_agent() {
  local dir="$1" agent="$2"
  shift 2
  local models=("$@")
  local file="$dir/.github/agents/${agent}.agent.md"
  mkdir -p "$(dirname "$file")"
  {
    echo "---"
    echo "name: ${agent}"
    echo "description: test agent"
    echo "model:"
    for m in "${models[@]}"; do
      echo "  - $m"
    done
    echo "tools: [codebase]"
    echo "---"
  } > "$file"
}

make_llms_txt() {
  local dir="$1"
  cat > "$dir/llms.txt" <<'LLMS'
# test llms

## Model strategy

| Surface | Recommended model | Role |
|---------|-------------------|------|
| `setup.agent.md` | ModelG | setup |
| `coding.agent.md` | ModelA | coding |
| `review.agent.md` | ModelF | review |
| `fast.agent.md` | ModelD | fast |
| `update.agent.md` | ModelI | update |
| `doctor.agent.md` | ModelC | doctor |
LLMS
}

make_fixture() {
  local root="$1"
  mkdir -p "$root"
  make_models_md "$root"
  make_agent "$root" coding ModelA ModelB
  make_agent "$root" doctor ModelC
  make_agent "$root" fast ModelD ModelE
  make_agent "$root" review ModelF
  make_agent "$root" setup ModelG ModelH
  make_agent "$root" update ModelI
  make_llms_txt "$root"
}

# ─── Tests ───────────────────────────────────────────────────────────────────

echo "=== sync-models.sh contract tests ==="
echo ""

# 1. Invalid mode
echo "1. Invalid mode is rejected"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" --wat 2>&1) || true
assert_contains "invalid mode prints usage" "$output" "Usage: bash scripts/sync-models.sh"
echo ""

# 2. Missing MODELS.md exits non-zero
echo "2. Missing MODELS.md in check mode fails"
TMP=$(mktemp -d)
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "missing MODELS.md reports error" "$output" "MODELS.md not found"
rm -rf "$TMP"
echo ""

# 3. In-sync fixture passes --check
echo "3. In-sync fixture passes --check"
TMP=$(mktemp -d)
make_fixture "$TMP"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "check mode exits zero on in-sync fixture" "$status"
assert_contains "check mode prints OK" "$output" "OK:"
rm -rf "$TMP"
echo ""

# 4. Drift in agent file is detected
echo "4. Model drift in agent file is detected"
TMP=$(mktemp -d)
make_fixture "$TMP"
# Tamper: give coding a wrong primary model
make_agent "$TMP" coding WrongModel ModelB
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "drift detected in agent file" "$output" "coding.agent.md"
assert_contains "repair hint is printed" "$output" "sync-models.sh --write"
rm -rf "$TMP"
echo ""

# 5. --write repairs a drifted agent file
echo "5. --write repairs drifted agent file"
TMP=$(mktemp -d)
make_fixture "$TMP"
make_agent "$TMP" coding WrongModel
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --write 2>&1)
status=$?
assert_success "--write exits zero" "$status"
assert_contains "--write reports updated file" "$output" "coding.agent.md"
# Verify the file now starts with ModelA
assert_file_contains "agent file now has correct primary model" \
  "$TMP/.github/agents/coding.agent.md" "  - ModelA"
# Verify --check passes after write
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "check passes after write" "$status"
rm -rf "$TMP"
echo ""

# 6. Drift in llms.txt is detected
echo "6. Drift in llms.txt is detected"
TMP=$(mktemp -d)
make_fixture "$TMP"
# Tamper: wrong primary in llms.txt for doctor
sed -i 's/| `doctor\.agent\.md` | ModelC /| `doctor.agent.md` | WrongModel /' \
  "$TMP/llms.txt"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "llms.txt drift detected" "$output" "llms.txt"
rm -rf "$TMP"
echo ""

# 7. Idempotency — second --write is a no-op
echo "7. Idempotency — second --write is a no-op"
TMP=$(mktemp -d)
make_fixture "$TMP"
ROOT_DIR="$TMP" bash "$SCRIPT" --write > /dev/null
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --write 2>&1)
assert_contains "second write is a no-op" "$output" "already in sync"
rm -rf "$TMP"
echo ""

# 8. MODELS.md missing a section exits non-zero
echo "8. MODELS.md missing an agent section exits non-zero"
TMP=$(mktemp -d)
make_fixture "$TMP"
# Remove the 'fast' section from MODELS.md
python3 -c "
import re, pathlib
p = pathlib.Path('$TMP/MODELS.md')
text = p.read_text()
text = re.sub(r'## fast\n.*?(?=## |\Z)', '', text, flags=re.DOTALL)
p.write_text(text)
"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "missing section reported" "$output" "fast"
rm -rf "$TMP"
echo ""

# 9. Real repo is in sync (regression guard)
echo "9. Real repo agent files and llms.txt are in sync with MODELS.md"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" --check 2>&1)
status=$?
assert_success "real repo check exits zero" "$status"
assert_contains "real repo check prints OK" "$output" "OK:"
echo ""

# 10. Dynamically discovered agent without MODELS.md section is reported
echo "10. Extra agent file without MODELS.md section is caught"
TMP=$(mktemp -d)
make_fixture "$TMP"
make_agent "$TMP" extra ModelX
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" --check 2>&1) || true
assert_contains "missing section for extra agent" "$output" "extra"
rm -rf "$TMP"
echo ""

finish_tests
