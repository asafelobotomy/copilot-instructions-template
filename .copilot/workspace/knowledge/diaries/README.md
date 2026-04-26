# Agent Diaries

Per-agent findings logs. Each file is named `{agent-name}.md` and capped at 30 lines.

- **Write**: Call `asafelobotomy_write_diary(agent_name, finding)` explicitly when you discover a durable insight. Handles dedup, timestamping, and the 30-line cap automatically.
- **Read**: Call `asafelobotomy_read_diaries(agent_name)` for a specific agent's entries, or `asafelobotomy_read_diaries()` for all agents.
- **Tool availability**: `asafelobotomy_write_diary` and `asafelobotomy_read_diaries` are deferred extension LM tools — load via `tool_search` before first use. Diary files remain human-readable and git-tracked independently.
