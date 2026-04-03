#!/usr/bin/env bash
# scripts/release/stub-migration.sh — auto-insert a stub MIGRATION.md entry for a new release.
#
# Usage: bash scripts/release/stub-migration.sh <tag>
#   e.g. bash scripts/release/stub-migration.sh v4.1.0
#
# Idempotent: exits 0 immediately if the tag heading already exists.
# Inserts the stub directly before the first ## v* version heading, and
# appends the tag to the "Available tags" line.
#
# Called from the CI release job before merging a release PR.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -n "${ROOT_DIR:-}" ]]; then
  ROOT_DIR="$ROOT_DIR"
elif [[ -f "$PWD/MIGRATION.md" ]]; then
  ROOT_DIR="$PWD"
elif git_root=$(git rev-parse --show-toplevel 2>/dev/null) && [[ -f "$git_root/MIGRATION.md" ]]; then
  ROOT_DIR="$git_root"
else
  ROOT_DIR="$PWD"
fi

# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"
require_command python3

TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  echo "Usage: $0 <tag>  (e.g. v4.1.0)" >&2
  exit 1
fi

MIGRATION="$ROOT_DIR/MIGRATION.md"
if [[ ! -f "$MIGRATION" ]]; then
  echo "❌ $MIGRATION not found" >&2
  exit 1
fi

# Idempotency check
if grep -q "^## ${TAG}$" "$MIGRATION"; then
  echo "✅ $MIGRATION already has ${TAG} entry — nothing to do"
  exit 0
fi

python3 - "$TAG" "$MIGRATION" <<'PYEOF'
import sys, re

tag = sys.argv[1]
path = sys.argv[2]
content = open(path, encoding="utf-8").read()

# 1. Append tag to Available tags line
if tag not in content:
    content = re.sub(
        r"(\*\*Available tags\*\*:.+)",
        lambda m: m.group(1) + ", " + tag,
        content,
    )

# 2. Build stub block
stub = (
    f"## {tag}\n"
    "\n"
    "| Breaking | Sections changed | Sections added | Includes |\n"
    "|----------|-----------------|----------------|----------|\n"
    "| TBD | — | — | — |\n"
    "\n"
    "**What changed**: *(stub — fill in before the next release or immediately after)*\n"
    "\n"
    "**New placeholders**: none\n"
    "\n"
    "**Companion files added**: none\n"
    "\n"
    "**Companion files updated**: none\n"
    "\n"
    "**Manual actions**: None\n"
    "\n"
    "---\n"
    "\n"
)

# 3. Insert before the first existing ## v* heading
content = re.sub(r"(---\n\n)(## v)", stub + r"\2", content, count=1)

open(path, "w", encoding="utf-8").write(content)
print(f"✅ Inserted stub entry for {tag} into {path}")
PYEOF
