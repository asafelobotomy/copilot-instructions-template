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

echo "5. release-please.yml workflow_run name matches CI workflow name"
assert_python "workflow_run trigger name matches CI name" '
import re
ci_text = (root / ".github/workflows/ci.yml").read_text(encoding="utf-8")
rp_text = (root / ".github/workflows/release-please.yml").read_text(encoding="utf-8")
ci_name_m = re.search(r"^name:\s*(.+)", ci_text, re.MULTILINE)
rp_name_m = re.search(r"workflows:\s*\[\"(.+?)\"\]", rp_text)
if not ci_name_m:
    raise SystemExit("could not find name: in ci.yml")
if not rp_name_m:
    raise SystemExit("could not find workflows: trigger in release-please.yml")
ci_name = ci_name_m.group(1).strip()
rp_name = rp_name_m.group(1).strip()
if ci_name != rp_name:
    raise SystemExit("MISMATCH ci=" + repr(ci_name) + " rp=" + repr(rp_name))
'
echo ""

echo "6. release workflow is gated by the release planner"
assert_python "release workflow uses plan-release gate" '
rp_text = (root / ".github/workflows/release-please.yml").read_text(encoding="utf-8")
if "bash scripts/plan-release.sh --write-config" not in rp_text:
    raise SystemExit("release planner step missing")
if "steps.plan.outputs.should_release ==" not in rp_text:
    raise SystemExit("release action missing planner gate")
if "config-file: ${{ steps.plan.outputs.config_file }}" not in rp_text:
    raise SystemExit("release action not using planner config")
'
echo ""

finish_tests