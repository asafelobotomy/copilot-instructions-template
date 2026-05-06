#!/usr/bin/env python3
"""Validate all agent files have required frontmatter fields."""
import re
import sys
import pathlib

root = pathlib.Path(sys.argv[1])
agents_dir = root / "agents"

REQUIRED_FIELDS = ["name", "description", "model", "tools", "user-invocable"]

# Canonical MCP server IDs — must match .vscode/mcp.json server keys
KNOWN_MCP_SERVERS = {
    "filesystem", "git", "github", "fetch", "heartbeat",
    "docs", "sequential-thinking", "duckduckgo",
}

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

    model_match = re.search(r'^model:\s*$', fm, re.M)
    if model_match:
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

    mcp_match = re.search(r'^mcp-servers:\s*\[(.*)\]\s*$', fm, re.M)
    if mcp_match:
        mcp_servers = [item.strip().strip("'\"") for item in mcp_match.group(1).split(",") if item.strip()]
        unknown = [s for s in mcp_servers if s not in KNOWN_MCP_SERVERS]
        if unknown:
            errors.append(f"{agent_file.name}: unknown mcp-servers: {unknown!r} — update KNOWN_MCP_SERVERS if intentional")

if count == 0:
    errors.append("no *.agent.md files found in agents/")

if errors:
    for e in errors:
        print(f"❌ {e}")
    sys.exit(1)

print(f"✅ {count} agent file(s) validated successfully")