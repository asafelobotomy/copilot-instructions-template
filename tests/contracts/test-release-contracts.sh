#!/usr/bin/env bash
# tests/contracts/test-release-contracts.sh -- verify release metadata stays aligned.
# Run: bash tests/contracts/test-release-contracts.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

echo "=== Release metadata contract checks ==="
echo ""

echo "1. VERSION.md and release-please manifest agree"
assert_python "version matches manifest" '
version = (root / "VERSION.md").read_text(encoding="utf-8").strip()
manifest = json.loads((root / ".release-please-manifest.json").read_text(encoding="utf-8"))
actual = manifest.get(".")
if actual != version:
    raise SystemExit("manifest=" + str(actual) + " version=" + version)
'
echo ""

echo "2. Release config points at the canonical version and changelog files"
assert_python "release-please config stays aligned" '
config = json.loads((root / "release-please-config.json").read_text(encoding="utf-8"))
pkg = config["packages"]["."]
if pkg.get("version-file") != "VERSION.md":
    raise SystemExit(pkg.get("version-file"))
if pkg.get("changelog-path") != "CHANGELOG.md":
    raise SystemExit(pkg.get("changelog-path"))
if ".release-please-manifest.json" in pkg.get("extra-files", []):
    raise SystemExit("manifest must not be listed in extra-files")
for rel in pkg.get("extra-files", []):
    if not (root / rel).exists():
        raise SystemExit(rel)
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

echo "4. Version markers remain in release-managed files"
assert_python "x-release markers remain discoverable" '
version = (root / "VERSION.md").read_text(encoding="utf-8").strip()
config = json.loads((root / "release-please-config.json").read_text(encoding="utf-8"))
targets = [root / rel for rel in config["packages"]["."].get("extra-files", [])]
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
    "bash scripts/release/plan-release.sh",
    "googleapis/release-please-action",
]
for needle in required:
    if needle not in normalized:
        raise SystemExit("missing CI release orchestration detail: " + needle)
'
echo ""

echo "6. Release job removes CI writeback and prepares MIGRATION on the release PR"
assert_python "single-authority release flow has no extra main-branch writers" '
ci_text = (root / ".github/workflows/ci.yml").read_text(encoding="utf-8")
normalized = ci_text.replace(chr(39), "")
for forbidden in [
    "Sync derived version references",
    "Auto-commit version sync",
    "chore: sync version references [skip ci]",
    "git pull --ff-only",
    "stub MIGRATION.md entry for $NEXT_TAG [skip ci]",
]:
    if forbidden in ci_text:
        raise SystemExit("forbidden legacy flow still present: " + forbidden)
required = [
    "Detect release commit",
    "is_release_commit=true",
    "steps.release_commit.outputs.is_release_commit == true",
    "bash scripts/release/stub-migration.sh \"$NEXT_TAG\"",
    "gh pr view \"$pr_number\"",
    "git push origin HEAD:\"$pr_branch\"",
    "gh pr merge \"$pr_number\"",
    "mergeStateStatus",
    "Release PR merge attempt $attempt/6 failed",
    "Release PR was not immediately mergeable after retries",
    "skip-github-release: true",
    "skip-github-pull-request: true",
    "Refresh merged main for publish pass",
    "steps.refresh_release_main.outputs.merged == true",
]
for needle in required:
    if needle not in normalized:
        raise SystemExit("missing release finalization detail: " + needle)
if "[skip ci]" in ci_text and "stub MIGRATION.md entry for $NEXT_TAG" in ci_text:
    raise SystemExit("release PR stub commit must not contain [skip ci] because squash merges copy it into main release commits")
if (root / ".github/workflows/release-please.yml").exists():
    raise SystemExit("legacy release-please workflow should be removed")
'
echo ""

echo "7. Maintainer docs describe the repository settings expected by release automation"
assert_python "release docs mention the GitHub settings audit" '
readme = (root / "README.md").read_text(encoding="utf-8")
required = [
    "## Recommended GitHub settings",
    "bash scripts/release/audit-release-settings.sh",
    "Enable auto-merge and squash merge.",
    "GitHub Actions to create and approve pull requests.",
    "Only release-driving changes produce a release.",
    "Major: any commit marked as a breaking change",
    "Minor: `feat:` for a consumer-facing addition.",
    "Patch: `fix:`, `deps:`",
    "Use `feat` only for a real consumer-facing capability.",
    "scripts/workspace/check-workspace-drift.sh",
]
for needle in required:
    if needle not in readme:
        raise SystemExit("README missing release-governance guidance: " + needle)
for forbidden in [
    "Any successful push to `main` is releaseable.",
]:
    if forbidden in readme:
        raise SystemExit("README still documents retired broad-release rule: " + forbidden)
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

finish_tests