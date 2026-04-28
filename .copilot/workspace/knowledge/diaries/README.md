# Agent Diaries

Per-agent findings logs. Each file is named `{agent-name}.md` and capped at 30 lines.

- **Write**: Call `mcp_heartbeat_write_diary(agent_name, finding)` explicitly when you discover a durable insight. Handles dedup, timestamping, and the 30-line cap automatically.
- **Read**: Call `mcp_heartbeat_read_diaries(agent_name)` for a specific agent's entries, or `mcp_heartbeat_read_diaries()` for all agents.
- **Tool availability**: `mcp_heartbeat_write_diary` and `mcp_heartbeat_read_diaries` are deferred MCP tools. If they are already loaded, call them directly. Otherwise try `tool_search` once. If that is unavailable, edit the diary files directly instead. Diary files remain human-readable and git-tracked independently.
