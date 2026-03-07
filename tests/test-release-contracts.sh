#!/usr/bin/env bash
# tests/test-release-contracts.sh -- verify release metadata stays aligned.
# Run: bash tests/test-release-contracts.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
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
targets = [root / ".github/copilot-instructions.md"]
for path in targets:
    text = path.read_text(encoding="utf-8")
    if "x-release-please-version" not in text:
        raise SystemExit(f"missing marker in {path.relative_to(root)}")
    if version not in text:
        raise SystemExit(f"missing version {version} in {path.relative_to(root)}")
'
echo ""

finish_tests