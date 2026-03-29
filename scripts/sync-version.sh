#!/usr/bin/env bash
# sync-version.sh — CI safety net for version constants.
#
# Single source of truth: VERSION.md
# Primary sync: release-please extra-files (x-release-please-version markers)
# This script: fallback validation — CI runs it and checks for a dirty tree.
#              If release-please updated all markers correctly, this is a no-op.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
VERSION_FILE="$ROOT_DIR/VERSION.md"

# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require_command python3

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "❌ Missing VERSION.md"
  exit 1
fi

VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ VERSION.md must contain semver x.y.z (found: '$VERSION')"
  exit 1
fi

python3 - "$ROOT_DIR" "$VERSION" <<'PY'
import re
import sys
import pathlib

root = pathlib.Path(sys.argv[1])
version = sys.argv[2]

def sub(path, pattern, repl):
    t = path.read_text()
    nt = re.sub(pattern, repl, t, flags=re.S)
    if nt != t:
        path.write_text(nt)

sub(root / "template/copilot-instructions.md",
    r'(> \*\*Template version\*\*: )\d+\.\d+\.\d+( [^|]*\| \*\*Applied\*\*:)',
    rf'\g<1>{version}\g<2>')
sub(root / "README.md",
    r'(\*\*)\d+\.\d+\.\d+(\*\* <!-- x-release-please-version -->)',
    rf'\g<1>{version}\g<2>')
sub(root / ".release-please-manifest.json",
    r'("\."\s*:\s*")\d+\.\d+\.\d+(")',
    rf'\g<1>{version}\g<2>')
sub(root / ".github/copilot-instructions.md",
    r'(Template version: )\d+\.\d+\.\d+',
    rf'\g<1>{version}')
PY

echo "✅ Synced version references from VERSION.md ($VERSION)"