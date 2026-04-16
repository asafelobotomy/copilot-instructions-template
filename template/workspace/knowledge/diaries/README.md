# Agent Diaries

Per-agent findings logs. Each file is named `{agent-name}.md` and capped at 30 lines.
Diaries are independent of the spatial environment — `spatial_status` includes them, but diaries exist and operate on their own.

- **Write**: Call `write_diary(agent_name, finding)` explicitly when you discover a durable insight. Handles dedup, timestamping, and the 30-line cap automatically.
- **Read**: Call `read_diaries(agent_name)` for a specific agent's entries, or `read_diaries()` for all agents. `spatial_status` also surfaces a recent summary.
- **Tool availability**: `write_diary` and `read_diaries` are provided by the heartbeat MCP server. The copilot-extension's `spatial_status` LM tool reads diaries. A dedicated `write_diary` extension LM tool is planned for a future extension release.
- **Hook**: SubagentStart injects a hint to call `read_diaries` or `spatial_status` — it does not inline diary content.
