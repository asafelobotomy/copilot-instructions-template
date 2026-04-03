#!/usr/bin/env bash
# sync-version.sh — verify release-managed version references stay aligned.
#
# Legacy name retained for compatibility.
# Single source of truth: VERSION.md
# Single writer: release-please (version-file, manifest-file, extra-files)
# This script is read-only and fails if the managed files drift from VERSION.md.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
VERSION_FILE="$ROOT_DIR/VERSION.md"

# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"
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
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
version = sys.argv[2]
errors = []


def require_text_match(path: pathlib.Path, pattern: str, description: str, require_marker: bool = False) -> None:
    if not path.exists():
        errors.append(f"missing file: {path.relative_to(root)}")
        return
    text = path.read_text(encoding="utf-8")
    if require_marker and "x-release-please-version" not in text:
        errors.append(f"missing x-release-please-version marker in {path.relative_to(root)}")
    match = re.search(pattern, text, re.S)
    if match is None:
        errors.append(f"could not locate {description} in {path.relative_to(root)}")
        return
    actual = match.group(1)
    if actual != version:
        errors.append(
            f"version drift in {path.relative_to(root)}: expected {version}, found {actual}"
        )


require_text_match(
    root / "template/copilot-instructions.md",
    r"> \*\*Template version\*\*: (\d+\.\d+\.\d+)(?: [^|]*\| \*\*Applied\*\*:)",
    "template version marker",
    require_marker=True,
)
require_text_match(
    root / "README.md",
    r"\*\*(\d+\.\d+\.\d+)\*\* <!-- x-release-please-version -->",
    "README version marker",
    require_marker=True,
)
require_text_match(
    root / ".github/copilot-instructions.md",
    r"Template version: (\d+\.\d+\.\d+)",
    "developer instruction version marker",
    require_marker=True,
)

manifest_path = root / ".release-please-manifest.json"
if not manifest_path.exists():
    errors.append("missing file: .release-please-manifest.json")
else:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    actual = manifest.get(".")
    if actual != version:
        errors.append(
            f"version drift in .release-please-manifest.json: expected {version}, found {actual}"
        )

if errors:
    for err in errors:
        print(f"❌ {err}")
    print("Run release-please or repair the managed files before releasing again.")
    raise SystemExit(1)

print(f"✅ Release-managed version references match VERSION.md ({version})")
PY