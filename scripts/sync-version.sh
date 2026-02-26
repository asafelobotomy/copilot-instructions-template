#!/usr/bin/env bash
# sync-version.sh — CI safety net for version constants.
#
# Single source of truth: VERSION.md
# Primary sync: release-please extra-files (x-release-please-version markers)
# This script: fallback validation — CI runs it and checks for a dirty tree.
#              If release-please updated all markers correctly, this is a no-op.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
VERSION_FILE="$ROOT_DIR/VERSION.md"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "❌ Missing VERSION.md"
  exit 1
fi

VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ VERSION.md must contain semver x.y.z (found: '$VERSION')"
  exit 1
fi

perl -0777 -i -pe 's#(> \*\*Template version\*\*: )[0-9]+\.[0-9]+\.[0-9]+( [^|]*\| \*\*Applied\*\*:)#${1}'"$VERSION"'${2}#g' "$ROOT_DIR/.github/copilot-instructions.md"
perl -0777 -i -pe 's#(\[!\[Version\]\(https://img\.shields\.io/badge/version-)[^)]+(\)\]\(VERSION\.md\))#${1}'"$VERSION"'-blue${2}#g' "$ROOT_DIR/README.md"
perl -0777 -i -pe 's#("\."\s*:\s*")[0-9]+\.[0-9]+\.[0-9]+(")#${1}'"$VERSION"'${2}#g' "$ROOT_DIR/.release-please-manifest.json"

echo "✅ Synced version references from VERSION.md ($VERSION)"