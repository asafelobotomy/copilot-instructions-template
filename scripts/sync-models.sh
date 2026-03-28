#!/usr/bin/env bash
# sync-models.sh — keep .github/agents/*.agent.md model lists and llms.txt
#                  aligned with the single source of truth in MODELS.md.
#
# Usage:
#   bash scripts/sync-models.sh --write   # propagate MODELS.md → agent files + llms.txt
#   bash scripts/sync-models.sh --check   # fail if any file is out of sync
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
MODELS_FILE="$ROOT_DIR/MODELS.md"
MODE="${1:---check}"

# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require_check_write_mode "sync-models.sh" "$MODE"
require_command python3

if [[ ! -f "$MODELS_FILE" ]]; then
  echo "❌ MODELS.md not found at $MODELS_FILE"
  exit 1
fi

python3 - "$ROOT_DIR" "$MODELS_FILE" "$MODE" <<'PY'
import re
import sys
import pathlib

root      = pathlib.Path(sys.argv[1])
models_md = pathlib.Path(sys.argv[2])
mode      = sys.argv[3]

# Dynamic discovery: pick up any *.agent.md in .github/agents/
AGENTS = sorted(
    p.stem.replace(".agent", "")
    for p in (root / ".github" / "agents").glob("*.agent.md")
)


def parse_models(content: str) -> dict[str, list[str]]:
    """Return {agent_name: [model, ...]} from MODELS.md section headings."""
    result = {}
    current = None
    for line in content.splitlines():
        heading = re.match(r'^## (\S+)\s*$', line)
        if heading:
            current = heading.group(1)
            result[current] = []
            continue
        if current and re.match(r'^- ', line):
            result[current].append(line[2:].strip())
    return result


def parse_thinking_effort(content: str) -> dict[str, str]:
    """Return {agent_name: effort_level} from the Thinking Effort Guide table."""
    result = {}
    for line in content.splitlines():
        m = re.match(r'\|\s*(\w+)\s*\|\s*(Low|Medium|High)\s*\|', line)
        if m:
            result[m.group(1)] = m.group(2)
    return result


def get_agent_models(agent_file: pathlib.Path) -> list[str]:
    """Extract the model: list from an agent frontmatter."""
    content = agent_file.read_text()
    models = []
    in_model = False
    for line in content.splitlines():
        if re.match(r'^model:\s*$', line):
            in_model = True
            continue
        if in_model:
            m = re.match(r'^  - (.+)$', line)
            if m:
                models.append(m.group(1).strip())
            else:
                break
    return models


def set_agent_models(agent_file: pathlib.Path, models: list[str]) -> bool:
    """Replace the model: block in agent frontmatter. Returns True if changed."""
    content = agent_file.read_text()
    new_block = "model:\n" + "".join(f"  - {m}\n" for m in models)
    new_content = re.sub(r'(?m)^model:\n(  - .+\n)+', new_block, content)
    if new_content == content:
        return False
    agent_file.write_text(new_content)
    return True


def get_llms_primary(llms_file: pathlib.Path) -> dict[str, str]:
    """Parse the model strategy table in llms.txt → {agent_stem: primary_model}."""
    result = {}
    for line in llms_file.read_text().splitlines():
        m = re.match(r'\|\s*`([^`]+)`\s*\|\s*([^|]+?)\s*\|', line)
        if m:
            agent_file_name = m.group(1)
            model = m.group(2).strip()
            stem = agent_file_name.replace(".agent.md", "")
            result[stem] = model
    return result


def get_llms_effort(llms_file: pathlib.Path) -> dict[str, str]:
    """Parse the Thinking Effort column from llms.txt table."""
    result = {}
    for line in llms_file.read_text().splitlines():
        m = re.match(r'\|\s*`([^`]+)`\s*\|\s*[^|]+\|\s*(Low|Medium|High)\s*\|', line)
        if m:
            stem = m.group(1).replace(".agent.md", "")
            result[stem] = m.group(2)
    return result


def set_llms_primary(llms_file: pathlib.Path, agent: str, model: str) -> bool:
    """Update the primary model column for an agent row in llms.txt."""
    content = llms_file.read_text()
    pattern = rf'(\|\s*`{re.escape(agent)}\.agent\.md`\s*\|\s*)[^|]+(.*)'
    new_content = re.sub(pattern, rf'\g<1>{model} \2', content)
    # Normalize extra spaces introduced by the replacement
    new_content = re.sub(
        rf'(\|\s*`{re.escape(agent)}\.agent\.md`\s*\|\s*){re.escape(model)}\s+(\|)',
        rf'\1{model} \2',
        new_content,
    )
    if new_content == content:
        return False
    llms_file.write_text(new_content)
    return True


def set_llms_effort(llms_file: pathlib.Path, agent: str, effort: str) -> bool:
    """Update the Thinking Effort column for an agent row in llms.txt."""
    content = llms_file.read_text()
    pattern = rf'(\|\s*`{re.escape(agent)}\.agent\.md`\s*\|\s*[^|]+\|\s*)(Low|Medium|High)(\s*\|)'
    new_content = re.sub(pattern, rf'\g<1>{effort}\3', content)
    if new_content == content:
        return False
    llms_file.write_text(new_content)
    return True


# ── Main ─────────────────────────────────────────────────────────────────────

content = models_md.read_text()
registry = parse_models(content)
llms_file = root / "llms.txt"

missing = [a for a in AGENTS if a not in registry]
if missing:
    print(f"❌ MODELS.md is missing sections for: {', '.join(missing)}")
    sys.exit(1)

drift = False
changed = []

for agent in AGENTS:
    models = registry[agent]
    agent_file = root / ".github" / "agents" / f"{agent}.agent.md"

    if not agent_file.exists():
        print(f"❌ Agent file not found: {agent_file}")
        sys.exit(1)

    current = get_agent_models(agent_file)

    if current == models:
        continue

    if mode == "--check":
        print(f"❌ Drift: {agent}.agent.md model list differs from MODELS.md")
        print(f"   MODELS.md : {models}")
        print(f"   Agent file: {current}")
        drift = True
    else:
        set_agent_models(agent_file, models)
        changed.append(agent_file.name)

# Check/update llms.txt primary model column
llms_current = get_llms_primary(llms_file)
for agent in AGENTS:
    primary = registry[agent][0]
    if llms_current.get(agent) == primary:
        continue
    if mode == "--check":
        print(f"❌ Drift: llms.txt primary model for {agent} is "
              f"'{llms_current.get(agent)}' (expected '{primary}')")
        drift = True
    else:
        if set_llms_primary(llms_file, agent, primary):
            changed.append(f"llms.txt ({agent})")

# Check/update llms.txt thinking effort column
effort_registry = parse_thinking_effort(content)
if effort_registry:
    llms_effort = get_llms_effort(llms_file)
    for agent in AGENTS:
        expected = effort_registry.get(agent)
        if not expected:
            continue
        if llms_effort.get(agent) == expected:
            continue
        if mode == "--check":
            print(f"❌ Drift: llms.txt thinking effort for {agent} is "
                  f"'{llms_effort.get(agent)}' (expected '{expected}')")
            drift = True
        else:
            if set_llms_effort(llms_file, agent, expected):
                changed.append(f"llms.txt effort ({agent})")

if mode == "--check":
    if drift:
        print("Run 'bash scripts/sync-models.sh --write' to repair.")
        sys.exit(1)
    print("OK: agent model lists and llms.txt are in sync with MODELS.md")
else:
    if changed:
        for name in changed:
            print(f"✅ Updated {name}")
    else:
        print("✅ All files already in sync — no changes made")
PY
