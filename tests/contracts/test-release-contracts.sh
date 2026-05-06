#!/usr/bin/env bash
# tests/contracts/test-release-contracts.sh -- verify release metadata stays aligned.
# Run: bash tests/contracts/test-release-contracts.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -euo pipefail

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

echo "3. Current version is represented in CHANGELOG"
assert_python "current version appears in CHANGELOG" '
version = (root / "VERSION.md").read_text(encoding="utf-8").strip()
changelog = (root / "CHANGELOG.md").read_text(encoding="utf-8")
if f"## [{version}]" not in changelog:
    raise SystemExit("CHANGELOG missing current release heading")
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

echo ""

echo "8. CHANGELOG [Unreleased] block must precede the first versioned release"
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