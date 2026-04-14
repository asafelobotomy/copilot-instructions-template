#!/usr/bin/env bash
# tests/contracts/test-release-contracts.sh -- verify release metadata stays aligned.
# Run: bash tests/contracts/test-release-contracts.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
trap cleanup_dirs EXIT

echo "=== Release metadata contract checks ==="
echo ""

echo "1. VERSION.md is valid semver"
assert_python "VERSION.md is valid semver" '
version = (root / "VERSION.md").read_text(encoding="utf-8").strip()
if not re.match(r"^\d+\.\d+\.\d+$", version):
    raise SystemExit("invalid semver: " + version)
'
echo ""

echo "2. Legacy release-please files are removed"
assert_python "no release-please artifacts remain" '
for name in ["release-please-config.json", ".release-please-manifest.json"]:
    if (root / name).exists():
        raise SystemExit(f"legacy file still present: {name}")
if (root / ".github/workflows/release-please.yml").exists():
    raise SystemExit("legacy release-please workflow should be removed")
'
echo ""

echo "3. Current version is represented in CHANGELOG and MIGRATION"
assert_python "current version appears in release docs" '
version = (root / "VERSION.md").read_text(encoding="utf-8").strip()
tag = f"v{version}"
changelog = (root / "CHANGELOG.md").read_text(encoding="utf-8")
migration = (root / "MIGRATION.md").read_text(encoding="utf-8")
if f"## [{version}]" not in changelog:
    raise SystemExit("CHANGELOG missing current release heading")
if f"## {tag}" not in migration:
    raise SystemExit("MIGRATION missing current version heading")
available_tags = re.search(r"\*\*Available tags\*\*: (.+)", migration)
if available_tags is None or tag not in available_tags.group(1):
    raise SystemExit("MIGRATION available tags missing current version")
'
echo ""

echo "4. Version markers remain in managed files"
assert_python "x-release markers remain discoverable" '
version = (root / "VERSION.md").read_text(encoding="utf-8").strip()
targets = [
    root / "template/copilot-instructions.md",
    root / "README.md",
    root / ".github/copilot-instructions.md",
]
for path in targets:
    text = path.read_text(encoding="utf-8")
    if path.suffix == ".md" and "x-release-please-version" not in text:
        raise SystemExit(f"missing marker in {path.relative_to(root)}")
    if version not in text:
        raise SystemExit(f"missing version {version} in {path.relative_to(root)}")
'
echo ""

echo "5. CI workflow integrates release automation after validation"
assert_python "CI owns the release orchestration" '
ci_text = (root / ".github/workflows/ci.yml").read_text(encoding="utf-8")
normalized = ci_text.replace(chr(39), "")
required = [
    "release:",
    "name: Release automation",
    "needs:",
    "- validate",
    "- markdownlint",
    "- actionlint",
    "- yamllint",
    "- shellcheck",
    "- script-tests",
    "github.event_name == push && github.ref == refs/heads/main",
    "Detect version bump",
    "gh release create",
]
for needle in required:
    if needle not in normalized:
        raise SystemExit("missing CI release orchestration detail: " + needle)
for forbidden in [
    "googleapis/release-please-action",
    "bash scripts/release/plan-release.sh",
    "release-please-config.json",
    ".release-please-manifest.json",
]:
    if forbidden in normalized:
        raise SystemExit("legacy release-please reference still present: " + forbidden)
'
echo ""

echo "6. Release job has no extra main-branch writers"
assert_python "release flow has no extra main-branch writers" '
ci_text = (root / ".github/workflows/ci.yml").read_text(encoding="utf-8")
for forbidden in [
    "Sync derived version references",
    "Auto-commit version sync",
    "chore: sync version references [skip ci]",
    "git pull --ff-only",
    "googleapis/release-please-action",
    "release-please-config.json",
    ".release-please-manifest.json",
]:
    if forbidden in ci_text:
        raise SystemExit("forbidden legacy flow still present: " + forbidden)
'
echo ""

echo "7. Maintainer docs describe the repository settings expected by release automation"
assert_python "release docs mention the GitHub settings audit" '
readme = (root / "README.md").read_text(encoding="utf-8")
required = [
    "## Recommended GitHub settings",
    "bash scripts/release/audit-release-settings.sh",
    "Enable squash merge.",
    "Version bumps are done locally.",
    "Minor: `feat:` for a consumer-facing addition.",
    "Use `feat` only for a real consumer-facing capability.",
]
for needle in required:
    if needle not in readme:
        raise SystemExit("README missing release-governance guidance: " + needle)
for forbidden in [
    "Any successful push to `main` is releaseable.",
    "Release-please is the only version writer.",
]:
    if forbidden in readme:
        raise SystemExit("README still documents retired release rule: " + forbidden)
'
echo ""

echo "8. All v5 migration entries are not left as release stubs"
assert_python "v5 migration entries are populated" '
import re

text = (root / "MIGRATION.md").read_text(encoding="utf-8")
tags_match = re.search(r"\*\*Available tags\*\*: (.+)", text)
if tags_match is None:
    raise SystemExit("MIGRATION.md missing Available tags line")

def parse_version(tag: str):
    return tuple(int(part) for part in tag.lstrip("v").split("."))

tags = [tag.strip() for tag in tags_match.group(1).split(",") if tag.strip()]
current_major = parse_version(tags[-1])[0]
recent = sorted(
    [tag for tag in tags if parse_version(tag)[0] == current_major],
    key=parse_version,
)

for tag in recent:
    start = text.find(f"## {tag}\n")
    if start == -1:
        raise SystemExit("missing migration heading for current-major tag " + tag)
    next_match = re.search(r"^## v", text[start + 1:], re.M)
    end = len(text) if next_match is None else start + 1 + next_match.start()
    block = text[start:end]
    if "| TBD |" in block or "*(stub" in block:
        raise SystemExit("current-major migration entry still stubbed: " + tag)
'
echo ""

echo "9. Unreleased workspace migration moves all diary files"
assert_python "unreleased workspace migration covers existing diary files" '
text = (root / "MIGRATION.md").read_text(encoding="utf-8")
start = text.find("## Unreleased — workspace and scripts reorganization\n")
if start == -1:
    raise SystemExit("missing unreleased workspace reorganization entry")
next_match = re.search(r"^## v", text[start + 1:], re.M)
end = len(text) if next_match is None else start + 1 + next_match.start()
block = text[start:end]
required = [
        "for path in diaries/*; do",
        "git mv \"$path\" knowledge/diaries/ 2>/dev/null || mv \"$path\" knowledge/diaries/",
]
for needle in required:
        if needle not in block:
                raise SystemExit("unreleased workspace migration missing diary move detail: " + needle)
if "git mv diaries/README.md knowledge/diaries/" in block:
        raise SystemExit("unreleased workspace migration still only moves diaries/README.md")
'

sandbox=$(make_git_sandbox)
CLEANUP_DIRS+=("$sandbox")
mkdir -p "$sandbox/.copilot/workspace/diaries" "$sandbox/.copilot/workspace/knowledge/diaries"
printf 'tracked\n' > "$sandbox/.copilot/workspace/diaries/README.md"
(cd "$sandbox" && git add .copilot/workspace/diaries/README.md && git commit -q -m "add tracked diary")
printf 'untracked\n' > "$sandbox/.copilot/workspace/diaries/explore.md"

(
    cd "$sandbox/.copilot/workspace" || exit 1
    if [ -d diaries ]; then
        for path in diaries/*; do
            [ -e "$path" ] || continue
            git mv "$path" knowledge/diaries/ 2>/dev/null || mv "$path" knowledge/diaries/
        done
        rmdir diaries 2>/dev/null || true
    fi
)

assert_file_exists "tracked diary moved into knowledge/diaries" \
    "$sandbox/.copilot/workspace/knowledge/diaries/README.md"

assert_file_exists "untracked diary moved into knowledge/diaries" \
    "$sandbox/.copilot/workspace/knowledge/diaries/explore.md"

if [[ ! -d "$sandbox/.copilot/workspace/diaries" ]]; then
    pass_note "legacy diaries directory removed after migration"
else
    fail_note "legacy diaries directory removed after migration" \
        "     directory still exists: $sandbox/.copilot/workspace/diaries"
fi

echo ""

echo "10. CHANGELOG [Unreleased] block must precede the first versioned release"
assert_python "Unreleased block if present must precede the first versioned release" '
import re
text = (root / "CHANGELOG.md").read_text(encoding="utf-8")
unreleased_pos = -1
first_version_pos = -1
for m in re.finditer(r"^## \[", text, re.M):
    heading = text[m.start():text.find("\n", m.start())]
    if "Unreleased" in heading:
        if unreleased_pos == -1:
            unreleased_pos = m.start()
    elif re.search(r"## \[\d", heading):
        if first_version_pos == -1:
            first_version_pos = m.start()
if unreleased_pos != -1 and first_version_pos != -1:
    if unreleased_pos > first_version_pos:
        raise SystemExit("CHANGELOG [Unreleased] block appears after a versioned release — stale leftover?")
'
echo ""

finish_tests