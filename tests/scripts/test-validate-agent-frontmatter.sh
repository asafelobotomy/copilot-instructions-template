#!/usr/bin/env bash
# tests/scripts/test-validate-agent-frontmatter.sh -- tests for scripts/ci/validate-agent-frontmatter.sh
# Run: bash tests/scripts/test-validate-agent-frontmatter.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
SCRIPT="$REPO_ROOT/scripts/ci/validate-agent-frontmatter.sh"
trap cleanup_dirs EXIT

make_agent() {
  local dir="$1" name="$2"
  local file="$dir/agents/${name}.agent.md"
  mkdir -p "$(dirname "$file")"
  cat > "$file" <<EOF
---
name: $name
description: test agent
model:
  - TestModel
tools:
  - codebase
user-invocable: true
---
# $name
EOF
}

echo "=== validate-agent-frontmatter.sh ==="
echo ""

echo "1. Valid agents pass"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
make_agent "$TMP" "test"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1)
status=$?
assert_success "valid agent exits zero" "$status"
assert_contains "reports valid" "$output" "validated successfully"
echo ""

echo "2. Missing name field is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/agents"
cat > "$TMP/agents/bad.agent.md" <<'EOF'
---
description: test
model:
  - TestModel
tools:
  - codebase
---
EOF
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1) || true
assert_contains "missing name reported" "$output" "missing required field 'name'"
echo ""

echo "3. Missing model field is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/agents"
cat > "$TMP/agents/bad.agent.md" <<'EOF'
---
name: bad
description: test
tools:
  - codebase
---
EOF
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1) || true
assert_contains "missing model reported" "$output" "missing required field 'model'"
echo ""

echo "4. Empty model list is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/agents"
cat > "$TMP/agents/bad.agent.md" <<'EOF'
---
name: bad
description: test
model:
tools:
  - codebase
---
EOF
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1) || true
assert_contains "empty model list reported" "$output" "model list is empty"
echo ""

echo "5. Missing user-invocable field is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/agents"
cat > "$TMP/agents/bad.agent.md" <<'EOF'
---
name: bad
description: test
model:
  - TestModel
tools:
  - codebase
---
EOF
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1) || true
assert_contains "missing user-invocable reported" "$output" "missing required field 'user-invocable'"
echo ""

echo "6. Invalid user-invocable value is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/agents"
cat > "$TMP/agents/bad.agent.md" <<'EOF'
---
name: bad
description: test
model:
  - TestModel
tools:
  - codebase
user-invocable: maybe
---
EOF
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1) || true
assert_contains "invalid user-invocable reported" "$output" "user-invocable must be true or false"
echo ""

echo "7. Missing opening --- is detected"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/agents"
echo "no frontmatter here" > "$TMP/agents/bad.agent.md"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1) || true
assert_contains "missing opening dashes" "$output" "missing opening ---"
echo ""

echo "8. No agent files at all is an error"
TMP=$(mktemp -d); CLEANUP_DIRS+=("$TMP")
mkdir -p "$TMP/agents"
output=$(ROOT_DIR="$TMP" bash "$SCRIPT" 2>&1) || true
assert_contains "no agents found" "$output" "no *.agent.md files found"
echo ""

echo "9. Real repo agents pass validation"
output=$(ROOT_DIR="$REPO_ROOT" bash "$SCRIPT" 2>&1)
status=$?
assert_success "real repo exits zero" "$status"
expected_count=$(find "$REPO_ROOT/agents" -name '*.agent.md' | wc -l | tr -d ' ')
assert_contains "real repo all valid" "$output" "$expected_count agent file(s) validated successfully"
echo ""

finish_tests
