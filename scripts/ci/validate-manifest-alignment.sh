#!/usr/bin/env bash
# scripts/ci/validate-manifest-alignment.sh — verify routing-manifest.json agent names
# match the 'name:' field in their corresponding *.agent.md frontmatter.
# Exit 0: aligned. Exit 1: mismatches found.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"
require_command python3

python3 - "$ROOT_DIR" <<'PY'
import json, re, sys, pathlib

root = pathlib.Path(sys.argv[1])
manifest_path = root / "agents" / "routing-manifest.json"

try:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
except Exception as e:
    print(f"❌ Could not read routing-manifest.json: {e}")
    sys.exit(1)

errors = []
manifest_names = {a["name"] for a in manifest.get("agents", [])}

# Check every manifest name has a corresponding agent file with matching name field
for agent_name in sorted(manifest_names):
    # Find candidate files
    candidates = list((root / "agents").glob("*.agent.md"))
    found = False
    for candidate in candidates:
        text = candidate.read_text(encoding="utf-8")
        m = re.search(r'^name:\s*(.+)$', text[:500], re.M)
        if m and m.group(1).strip() == agent_name:
            found = True
            break
    if not found:
        errors.append(f"routing-manifest.json lists '{agent_name}' but no *.agent.md has name: {agent_name}")

# Check every agent file name field is listed in the manifest
for agent_file in sorted((root / "agents").glob("*.agent.md")):
    text = agent_file.read_text(encoding="utf-8")
    m = re.search(r'^name:\s*(.+)$', text[:500], re.M)
    if not m:
        continue
    agent_name = m.group(1).strip()
    if agent_name not in manifest_names:
        errors.append(f"{agent_file.name} has name: {agent_name} but it is not listed in routing-manifest.json")

if errors:
    for e in errors:
        print(f"❌ {e}")
    sys.exit(1)

count = len(manifest_names)
print(f"✅ {count} agent(s) aligned between routing-manifest.json and frontmatter")
PY