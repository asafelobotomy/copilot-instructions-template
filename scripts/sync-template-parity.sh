#!/usr/bin/env bash
# sync-template-parity.sh — keep .github/ mirrors in sync with template/ sources.
#
# Usage:
#   bash scripts/sync-template-parity.sh --write   # copy template/ → .github/ for drifted files
#   bash scripts/sync-template-parity.sh --check   # fail if any mirror is out of sync
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
MODE="${1:---check}"

# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require_python_check_write "sync-template-parity.sh" "$MODE"

python3 - "$ROOT_DIR" "$MODE" <<'PY'
import filecmp
import shutil
import sys
import pathlib

root = pathlib.Path(sys.argv[1])
mode = sys.argv[2]

# mcp-management is .github/-only (no template mirror per Architecture invariant)
SKILL_EXCLUDE = {"mcp-management"}

drift = []
repaired = []

def is_drift(src, dst):
    """Return True if dst is missing or differs from src."""
    if not dst.exists():
        return True
    return not filecmp.cmp(src, dst, shallow=False)

# ── Hook scripts & config ────────────────────────────────────────────────────

hook_config = root / "template/hooks/copilot-hooks.json"
hook_repo = root / ".github/hooks/copilot-hooks.json"
if hook_config.exists():
    if is_drift(hook_config, hook_repo):
        drift.append(("template/hooks/copilot-hooks.json", ".github/hooks/copilot-hooks.json"))

for ext in ("*.sh", "*.ps1"):
    for src in sorted((root / "template/hooks/scripts").glob(ext)):
        dst = root / ".github/hooks/scripts" / src.name
        if is_drift(src, dst):
            drift.append((f"template/hooks/scripts/{src.name}", f".github/hooks/scripts/{src.name}"))

# ── Skills ────────────────────────────────────────────────────────────────────

for src_dir in sorted((root / "template/skills").iterdir()):
    if not src_dir.is_dir():
        continue
    if src_dir.name in SKILL_EXCLUDE:
        continue
    src = src_dir / "SKILL.md"
    dst = root / ".github/skills" / src_dir.name / "SKILL.md"
    if src.exists():
        if is_drift(src, dst):
            drift.append((f"template/skills/{src_dir.name}/SKILL.md",
                          f".github/skills/{src_dir.name}/SKILL.md"))

# ── Instructions & prompts ────────────────────────────────────────────────────
# Only check files where the template copy has NO placeholder tokens.
# Template files with {{}} tokens are consumer stubs — .github/ copies are
# intentionally resolved with project-specific values.

for kind in ("instructions", "prompts"):
    tpl_dir = root / "template" / kind
    dev_dir = root / ".github" / kind
    if not tpl_dir.exists() or not dev_dir.exists():
        continue
    for src in sorted(tpl_dir.iterdir()):
        if not src.is_file():
            continue
        src_text = src.read_text(encoding="utf-8")
        if "{{" in src_text:
            continue  # template stub with placeholders — skip
        dst = dev_dir / src.name
        if is_drift(src, dst):
            drift.append((f"template/{kind}/{src.name}", f".github/{kind}/{src.name}"))

# ── Act ───────────────────────────────────────────────────────────────────────

if not drift:
    print("✅ All template mirrors are in sync")
    sys.exit(0)

if mode == "--check":
    for src_rel, dst_rel in drift:
        print(f"❌ Drift: {dst_rel} differs from {src_rel}")
    print(f"\n{len(drift)} file(s) out of sync.")
    print("Run: bash scripts/sync-template-parity.sh --write")
    sys.exit(1)

# --write mode: copy template → .github
for src_rel, dst_rel in drift:
    src = root / src_rel
    dst = root / dst_rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    repaired.append(dst_rel)

for name in repaired:
    print(f"✅ Repaired {name}")
print(f"\n{len(repaired)} file(s) synced.")
PY
