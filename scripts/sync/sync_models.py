#!/usr/bin/env python3
"""Keep agent model lists and llms.txt aligned with MODELS.md."""
from __future__ import annotations

import pathlib
import re
import sys


def parse_models(content: str) -> dict[str, list[str]]:
    """Return {agent_name: [model, ...]} from MODELS.md section headings."""
    result: dict[str, list[str]] = {}
    current: str | None = None
    for line in content.splitlines():
        heading = re.match(r"^## (\S+)\s*$", line)
        if heading:
            current = heading.group(1)
            result[current] = []
            continue
        if current and re.match(r"^- ", line):
            result[current].append(line[2:].strip())
    return result


def parse_thinking_effort(content: str) -> dict[str, str]:
    """Return {agent_name: effort_level} from the Thinking Effort Guide table."""
    result: dict[str, str] = {}
    for line in content.splitlines():
        match = re.match(r"\|\s*(\w+)\s*\|\s*(Low|Medium|High)\s*\|", line)
        if match:
            result[match.group(1)] = match.group(2)
    return result


def discover_agents(root: pathlib.Path) -> list[str]:
    """Return dynamically discovered agent names from .github/agents/*.agent.md."""
    return sorted(
        path.stem.replace(".agent", "")
        for path in (root / ".github" / "agents").glob("*.agent.md")
    )


def get_agent_models(agent_file: pathlib.Path) -> list[str]:
    """Extract the model: list from an agent frontmatter."""
    content = agent_file.read_text(encoding="utf-8")
    models: list[str] = []
    in_model = False
    for line in content.splitlines():
        if re.match(r"^model:\s*$", line):
            in_model = True
            continue
        if in_model:
            match = re.match(r"^  - (.+)$", line)
            if match:
                models.append(match.group(1).strip())
            else:
                break
    return models


def set_agent_models(agent_file: pathlib.Path, models: list[str]) -> bool:
    """Replace the model: block in agent frontmatter. Returns True if changed."""
    content = agent_file.read_text(encoding="utf-8")
    new_block = "model:\n" + "".join(f"  - {model}\n" for model in models)
    new_content = re.sub(r"(?m)^model:\n(  - .+\n)+", new_block, content)
    if new_content == content:
        return False
    agent_file.write_text(new_content, encoding="utf-8")
    return True


def get_llms_primary(llms_file: pathlib.Path) -> dict[str, str]:
    """Parse the model strategy table in llms.txt -> {agent_stem: primary_model}."""
    result: dict[str, str] = {}
    for line in llms_file.read_text(encoding="utf-8").splitlines():
        match = re.match(r"\|\s*`([^`]+)`\s*\|\s*([^|]+?)\s*\|", line)
        if match:
            agent_file_name = match.group(1)
            model = match.group(2).strip()
            result[agent_file_name.replace(".agent.md", "")] = model
    return result


def get_llms_effort(llms_file: pathlib.Path) -> dict[str, str]:
    """Parse the Thinking Effort column from llms.txt."""
    result: dict[str, str] = {}
    for line in llms_file.read_text(encoding="utf-8").splitlines():
        match = re.match(r"\|\s*`([^`]+)`\s*\|\s*[^|]+\|\s*(Low|Medium|High)\s*\|", line)
        if match:
            result[match.group(1).replace(".agent.md", "")] = match.group(2)
    return result


def set_llms_primary(llms_file: pathlib.Path, agent: str, model: str) -> bool:
    """Update the primary model column for an agent row in llms.txt."""
    content = llms_file.read_text(encoding="utf-8")
    pattern = rf"(\|\s*`{re.escape(agent)}\.agent\.md`\s*\|\s*)[^|]+(.*)"
    new_content = re.sub(pattern, rf"\g<1>{model} \2", content)
    new_content = re.sub(
        rf"(\|\s*`{re.escape(agent)}\.agent\.md`\s*\|\s*){re.escape(model)}\s+(\|)",
        rf"\1{model} \2",
        new_content,
    )
    if new_content == content:
        return False
    llms_file.write_text(new_content, encoding="utf-8")
    return True


def set_llms_effort(llms_file: pathlib.Path, agent: str, effort: str) -> bool:
    """Update the Thinking Effort column for an agent row in llms.txt."""
    content = llms_file.read_text(encoding="utf-8")
    pattern = rf"(\|\s*`{re.escape(agent)}\.agent\.md`\s*\|\s*[^|]+\|\s*)(Low|Medium|High)(\s*\|)"
    new_content = re.sub(pattern, rf"\g<1>{effort}\3", content)
    if new_content == content:
        return False
    llms_file.write_text(new_content, encoding="utf-8")
    return True


def sync_models(root: pathlib.Path, models_md: pathlib.Path, mode: str) -> int:
    """Synchronize agent model lists and llms.txt with MODELS.md."""
    content = models_md.read_text(encoding="utf-8")
    registry = parse_models(content)
    llms_file = root / "llms.txt"
    agents = discover_agents(root)

    missing = [agent for agent in agents if agent not in registry]
    if missing:
        print(f"❌ MODELS.md is missing sections for: {', '.join(missing)}")
        return 1

    drift = False
    changed: list[str] = []

    for agent in agents:
        models = registry[agent]
        agent_file = root / ".github" / "agents" / f"{agent}.agent.md"

        if not agent_file.exists():
            print(f"❌ Agent file not found: {agent_file}")
            return 1

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

    llms_current = get_llms_primary(llms_file)
    for agent in agents:
        primary = registry[agent][0]
        if llms_current.get(agent) == primary:
            continue
        if mode == "--check":
            print(
                f"❌ Drift: llms.txt primary model for {agent} is "
                f"'{llms_current.get(agent)}' (expected '{primary}')"
            )
            drift = True
        else:
            if set_llms_primary(llms_file, agent, primary):
                changed.append(f"llms.txt ({agent})")

    effort_registry = parse_thinking_effort(content)
    if effort_registry:
        llms_effort = get_llms_effort(llms_file)
        for agent in agents:
            expected = effort_registry.get(agent)
            if not expected:
                continue
            if llms_effort.get(agent) == expected:
                continue
            if mode == "--check":
                print(
                    f"❌ Drift: llms.txt thinking effort for {agent} is "
                    f"'{llms_effort.get(agent)}' (expected '{expected}')"
                )
                drift = True
            else:
                if set_llms_effort(llms_file, agent, expected):
                    changed.append(f"llms.txt effort ({agent})")

    if mode == "--check":
        if drift:
            print("Run 'bash scripts/sync/sync-models.sh --write' to repair.")
            return 1
        print("OK: agent model lists and llms.txt are in sync with MODELS.md")
        return 0

    if changed:
        for name in changed:
            print(f"✅ Updated {name}")
    else:
        print("✅ All files already in sync — no changes made")
    return 0


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    if len(args) != 3:
        print("Usage: sync_models.py <root_dir> <models_file> <--check|--write>")
        return 2
    root = pathlib.Path(args[0])
    models_file = pathlib.Path(args[1])
    mode = args[2]
    return sync_models(root, models_file, mode)


if __name__ == "__main__":
    sys.exit(main())