#!/usr/bin/env bash
# tests/test-release-plan.sh -- verify consumer-path release planning behavior.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"

trap cleanup_dirs EXIT

make_release_sandbox() {
  local dir
  dir=$(mktemp -d)
  CLEANUP_DIRS+=("$dir")

  mkdir -p "$dir/scripts" "$dir/template" "$dir/.github/agents" "$dir/starter-kits/python"
  cp "$REPO_ROOT/scripts/plan-release.sh" "$dir/scripts/plan-release.sh"
  cp "$REPO_ROOT/scripts/lib.sh" "$dir/scripts/lib.sh"

  cat > "$dir/VERSION.md" <<'EOF_VERSION'
1.2.3
EOF_VERSION

  cat > "$dir/release-please-config.json" <<'EOF_CONFIG'
{
  "release-type": "simple",
  "packages": {
    ".": {
      "version-file": "VERSION.md",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        "template/copilot-instructions.md"
      ]
    }
  }
}
EOF_CONFIG

  cat > "$dir/CHANGELOG.md" <<'EOF_CHANGELOG'
## [1.2.3]
EOF_CHANGELOG

  cat > "$dir/README.md" <<'EOF_README'
Developer-only readme
EOF_README

  cat > "$dir/SETUP.md" <<'EOF_SETUP'
Setup
EOF_SETUP

  cat > "$dir/UPDATE.md" <<'EOF_UPDATE'
Update
EOF_UPDATE

  cat > "$dir/template/copilot-instructions.md" <<'EOF_TEMPLATE'
Template copy
EOF_TEMPLATE

  cat > "$dir/.github/agents/setup.agent.md" <<'EOF_AGENT'
model: gpt-5.4
EOF_AGENT

  cat > "$dir/starter-kits/python/plugin.json" <<'EOF_PLUGIN'
{}
EOF_PLUGIN

  (
    cd "$dir" || exit 1
    git init -q
    git config user.email "test@test.com"
    git config user.name "test"
    git add .
    git commit -q -m "chore: bootstrap"
    git tag v1.2.3
  )

  echo "$dir"
}

run_plan() {
  local dir="$1"
  shift
  (
    cd "$dir" || exit 1
    bash scripts/plan-release.sh "$@"
  )
}

echo "=== Release planner behavior ==="
echo ""

echo "1. Dev-only changes do not trigger a release"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf 'docs\n' >> README.md
  git add README.md
  git commit -q -m "docs: clarify maintainer notes"
)
output=$(run_plan "$sandbox")
assert_contains "dev-only change skips release" "$output" "should_release=false"
assert_contains "dev-only change keeps bump none" "$output" "version_bump=none"
echo ""

echo "2. Consumer docs-only changes force a patch release"
sandbox=$(make_release_sandbox)
runtime_config="$sandbox/runtime-config.json"
(
  cd "$sandbox" || exit 1
  printf 'clarified\n' >> template/copilot-instructions.md
  git add template/copilot-instructions.md
  git commit -q -m "docs: clarify consumer template wording"
)
output=$(run_plan "$sandbox" --write-config "$runtime_config")
assert_contains "consumer docs change triggers release" "$output" "should_release=true"
assert_contains "consumer docs change bumps patch" "$output" "version_bump=patch"
assert_contains "consumer docs change forces release-as" "$output" "force_release_as=true"
assert_contains "consumer docs change computes next patch" "$output" "next_version=1.2.4"
assert_python_in_root "runtime config injects release-as" "$sandbox" '
config = json.loads((root / "runtime-config.json").read_text(encoding="utf-8"))
assert config["packages"]["."]["release-as"] == "1.2.4"
'
echo ""

echo "3. Consumer feat commits keep native minor bumping"
sandbox=$(make_release_sandbox)
runtime_config="$sandbox/runtime-config.json"
(
  cd "$sandbox" || exit 1
  printf '{"name":"python"}\n' > starter-kits/python/plugin.json
  git add starter-kits/python/plugin.json
  git commit -q -m "feat: expand python starter kit"
)
output=$(run_plan "$sandbox" --write-config "$runtime_config")
assert_contains "consumer feat triggers release" "$output" "should_release=true"
assert_contains "consumer feat bumps minor" "$output" "version_bump=minor"
assert_contains "consumer feat does not force release-as" "$output" "force_release_as=false"
assert_contains "consumer feat computes next minor" "$output" "next_version=1.3.0"
assert_python_in_root "runtime config stays clean for native release" "$sandbox" '
config = json.loads((root / "runtime-config.json").read_text(encoding="utf-8"))
assert "release-as" not in config["packages"]["."]
'
echo ""

echo "4. Non-conventional consumer commits still infer a patch release"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf 'extra note\n' >> SETUP.md
  git add SETUP.md
  git commit -q -m "[WIP] polish setup flow" -m "* fix: clarify bootstrap wording"
)
output=$(run_plan "$sandbox")
assert_contains "wip consumer commit still triggers release" "$output" "should_release=true"
assert_contains "wip consumer commit infers patch" "$output" "version_bump=patch"
assert_contains "wip consumer commit forces release-as" "$output" "force_release_as=true"
echo ""

finish_tests