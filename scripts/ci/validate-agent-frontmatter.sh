#!/usr/bin/env bash
# scripts/ci/validate-agent-frontmatter.sh — validate all agent files have required frontmatter.
#
# Usage: bash scripts/ci/validate-agent-frontmatter.sh
# Exit 0: all agents valid. Exit 1: one or more errors.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"
require_command python3

python3 - "$ROOT_DIR" <<'PY'
import re
import sys
import pathlib

root = pathlib.Path(sys.argv[1])
agents_dir = root / ".github" / "agents"

REQUIRED_FIELDS = ["name", "description", "model", "tools", "user-invocable"]

errors = []
count = 0

for agent_file in sorted(agents_dir.glob("*.agent.md")):
    count += 1
    text = agent_file.read_text(encoding="utf-8")

    if not text.startswith("---\n"):
        errors.append(f"{agent_file.name}: missing opening ---")
        continue

    end = text.find("\n---\n", 4)
    if end == -1:
        errors.append(f"{agent_file.name}: unterminated frontmatter")
        continue

    fm = text[4:end]

    for field in REQUIRED_FIELDS:
        if not re.search(rf'^{field}:', fm, re.M):
            errors.append(f"{agent_file.name}: missing required field '{field}'")

    tools_match = re.search(r'^tools:\s*\[(.*)\]\s*$', fm, re.M)
    tools = []
    if tools_match:
        tools = [item.strip().strip("'\"") for item in tools_match.group(1).split(",") if item.strip()]

    # model list must have at least one entry
    model_match = re.search(r'^model:\s*$', fm, re.M)
    if model_match:
        # Check the line immediately after model: for a list entry
        lines_after = fm[model_match.end():]
        if not lines_after.startswith("\n  - ") and not lines_after.startswith("  - "):
            errors.append(f"{agent_file.name}: model list is empty")

    user_invocable_match = re.search(r'^user-invocable:\s*(.*)\s*$', fm, re.M)
    if user_invocable_match:
        raw_value = user_invocable_match.group(1).strip()
        if raw_value not in {"true", "false"}:
            errors.append(
                f"{agent_file.name}: user-invocable must be true or false, found {raw_value!r}"
            )

    agents_match = re.search(r'^agents:\s*\[(.*)\]\s*$', fm, re.M)
    if agents_match:
        agents = [item.strip().strip("'\"") for item in agents_match.group(1).split(",") if item.strip()]
        if agents and "agent" not in tools:
            errors.append(f"{agent_file.name}: agents allow-list requires 'agent' in tools")

if count == 0:
    errors.append("no *.agent.md files found in .github/agents/")

if errors:
    for e in errors:
        print(f"❌ {e}")
    sys.exit(1)

print(f"✅ All {count} agent files have valid frontmatter")
PY
