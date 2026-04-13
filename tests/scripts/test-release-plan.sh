#!/usr/bin/env bash
# tests/scripts/test-release-plan.sh -- verify release planning only for release-driving changes.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

trap cleanup_dirs EXIT

make_release_sandbox() {
  local dir
  dir=$(mktemp -d)
  CLEANUP_DIRS+=("$dir")

  mkdir -p "$dir/scripts/release" "$dir/scripts/workspace" "$dir/template" "$dir/.github/agents" "$dir/starter-kits/python"
  cp "$REPO_ROOT/scripts/release/plan-release.sh" "$dir/scripts/release/plan-release.sh"
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

  mkdir -p "$dir/starter-kits/python/.claude-plugin"
  cat > "$dir/starter-kits/python/.claude-plugin/plugin.json" <<'EOF_PLUGIN'
{}
EOF_PLUGIN

  cat > "$dir/AGENTS.md" <<'EOF_AGENTS'
Agent entrypoint
EOF_AGENTS

  cat > "$dir/scripts/workspace/check-workspace-drift.sh" <<'EOF_DRIFT'
#!/usr/bin/env bash
echo drift
EOF_DRIFT

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
    bash scripts/release/plan-release.sh "$@"
  )
}

echo "=== Release planner behavior ==="
echo ""

echo "1. README-only changes do not trigger a release"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf 'docs\n' >> README.md
  git add README.md
  git commit -q -m "docs: clarify maintainer notes"
)
output=$(run_plan "$sandbox")
assert_contains "readme-only change skips release" "$output" "should_release=false"
assert_contains "readme-only change keeps bump none" "$output" "version_bump=none"
assert_contains "readme-only change explains skip" "$output" "reason=no release-driving changes since last tag"
echo ""

echo "2. Template docs-only changes still force a patch release"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf 'clarified\n' >> template/copilot-instructions.md
  git add template/copilot-instructions.md
  git commit -q -m "docs: clarify consumer template wording"
)
output=$(run_plan "$sandbox")
assert_contains "template docs change triggers release" "$output" "should_release=true"
assert_contains "template docs change bumps patch" "$output" "version_bump=patch"
assert_contains "template docs change forces release-as" "$output" "force_release_as=true"
assert_contains "template docs change computes next patch" "$output" "next_version=1.2.4"
echo ""

echo "3. Agent entrypoint changes trigger a patch release"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf 'new trigger\n' >> AGENTS.md
  git add AGENTS.md
  git commit -q -m "docs: expand direct trigger wording"
)
output=$(run_plan "$sandbox")
assert_contains "agent entrypoint change triggers release" "$output" "should_release=true"
assert_contains "agent entrypoint change bumps patch" "$output" "version_bump=patch"
assert_contains "agent entrypoint change forces release-as" "$output" "force_release_as=true"
assert_contains "agent entrypoint change computes next patch" "$output" "next_version=1.2.4"
echo ""

echo "4. Release-driving feat commits keep native minor bumping"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf '{"name":"python-v2"}\n' > starter-kits/python/.claude-plugin/plugin.json
  git add starter-kits/python/.claude-plugin/plugin.json
  git commit -q -m "feat: expand python starter kit"
)
output=$(run_plan "$sandbox")
assert_contains "release-driving feat triggers release" "$output" "should_release=true"
assert_contains "release-driving feat bumps minor" "$output" "version_bump=minor"
assert_contains "release-driving feat does not force release-as" "$output" "force_release_as=false"
assert_contains "release-driving feat computes next minor" "$output" "next_version=1.3.0"
echo ""

echo "5. Non-conventional release-driving commits still infer a patch release"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf 'extra note\n' >> UPDATE.md
  git add UPDATE.md
  git commit -q -m "[WIP] polish update flow" -m "* fix: clarify release wording"
)
output=$(run_plan "$sandbox")
assert_contains "wip release-driving commit triggers release" "$output" "should_release=true"
assert_contains "wip release-driving commit infers patch" "$output" "version_bump=patch"
assert_contains "wip release-driving commit forces release-as" "$output" "force_release_as=true"
echo ""

echo "6. release-style commit still plans a release (CI handles release-commit finalization)"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  # Release-commit handling now lives in the CI release job, not in this script.
  printf 'Template copy v1.2.4\n' > template/copilot-instructions.md
  git add template/copilot-instructions.md
  git commit -q -m "chore(main): release 1.2.4"
)
output=$(run_plan "$sandbox")
assert_contains "release-style commit triggers release planning" "$output" "should_release=true"
assert_contains "release-style commit falls back to patch" "$output" "version_bump=patch"
assert_contains "release-style commit forces release-as" "$output" "force_release_as=true"
echo ""

echo "7. Breaking-change bang (feat!:) in release-driving commit body infers major via fallback"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf 'note\n' >> UPDATE.md
  git add UPDATE.md
  # Non-conventional header so native-bump stays none; bang in body exercises fallback_bump
  git commit -q -m "[WIP] big change" -m "* feat!: remove legacy bootstrap path"
)
output=$(run_plan "$sandbox")
assert_contains "feat-bang commit triggers release" "$output" "should_release=true"
assert_contains "feat-bang commit infers major" "$output" "version_bump=major"
assert_contains "feat-bang commit forces release-as" "$output" "force_release_as=true"
echo ""

echo "8. Drift-check helper changes are release-driving"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf 'echo updated drift\n' >> scripts/workspace/check-workspace-drift.sh
  git add scripts/workspace/check-workspace-drift.sh
  git commit -q -m "fix: adjust workspace drift helper"
)
output=$(run_plan "$sandbox")
assert_contains "drift helper change triggers release" "$output" "should_release=true"
assert_contains "drift helper change bumps patch" "$output" "version_bump=patch"
assert_contains "drift helper change does not force release-as" "$output" "force_release_as=false"
echo ""

echo "9. Conventional docs changes on release-driving files stay patch releases"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf 'clarify\n' >> UPDATE.md
  git add UPDATE.md
  git commit -q -m "docs: clarify update migration guidance"
)
output=$(run_plan "$sandbox")
assert_contains "release-driving docs change triggers release" "$output" "should_release=true"
assert_contains "release-driving docs change bumps patch" "$output" "version_bump=patch"
assert_contains "release-driving docs change forces release-as" "$output" "force_release_as=true"
assert_contains "release-driving docs change uses fallback reason" "$output" "reason=release-driving commits imply a semver bump through fallback rules"
echo ""

echo "10. Breaking non-releasable conventional headers still force a major release"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf 'breaking\n' >> UPDATE.md
  git add UPDATE.md
  git commit -q -m "refactor!: remove legacy update flow"
)
output=$(run_plan "$sandbox")
assert_contains "breaking non-releasable commit triggers release" "$output" "should_release=true"
assert_contains "breaking non-releasable commit bumps major" "$output" "version_bump=major"
assert_contains "breaking non-releasable commit forces release-as" "$output" "force_release_as=true"
assert_contains "breaking non-releasable commit computes next major" "$output" "next_version=2.0.0"
echo ""

echo "11. Breaking releasable conventional headers keep native major bumping"
sandbox=$(make_release_sandbox)
(
  cd "$sandbox" || exit 1
  printf 'breaking\n' >> UPDATE.md
  git add UPDATE.md
  git commit -q -m "fix!: remove legacy update flow"
)
output=$(run_plan "$sandbox")
assert_contains "breaking releasable commit triggers release" "$output" "should_release=true"
assert_contains "breaking releasable commit bumps major" "$output" "version_bump=major"
assert_contains "breaking releasable commit keeps native release" "$output" "force_release_as=false"
assert_contains "breaking releasable commit computes next major" "$output" "next_version=2.0.0"
echo ""

finish_tests