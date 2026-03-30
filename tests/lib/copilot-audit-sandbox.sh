#!/usr/bin/env bash
# tests/lib/copilot-audit-sandbox.sh — shared sandbox setup for copilot_audit tests.
# Sourced by test-copilot-audit.sh. Provides setup_sandbox, teardown_sandbox,
# run_audit, and run_audit_md helpers.
#
# Requires: REPO_ROOT set by init_test_context; SCRIPT pointing to copilot_audit.py.

setup_sandbox() {
  SANDBOX=$(mktemp -d)
  # Minimal valid structure — all checks pass
  mkdir -p "$SANDBOX/.github/agents"
  mkdir -p "$SANDBOX/.github/instructions"
  mkdir -p "$SANDBOX/.github/prompts"
  mkdir -p "$SANDBOX/.github/skills/my-skill"
  mkdir -p "$SANDBOX/.github/hooks/scripts"
  mkdir -p "$SANDBOX/template/hooks/scripts"
  mkdir -p "$SANDBOX/template/instructions"
  mkdir -p "$SANDBOX/template/prompts"
  mkdir -p "$SANDBOX/template/skills/my-skill"
  mkdir -p "$SANDBOX/.vscode"
  mkdir -p "$SANDBOX/starter-kits/python"

  # Developer instructions — must have zero {{PLACEHOLDER}} tokens
  cat > "$SANDBOX/.github/copilot-instructions.md" <<'MD'
# Developer Instructions
> Role: AI developer.
MD

  # Consumer template — must have ≥ 3 {{PLACEHOLDER}} tokens
  cat > "$SANDBOX/template/copilot-instructions.md" <<'MD'
# Template
{{REPO_OWNER}} {{REPO_NAME}} {{LANGUAGE}}
MD

  # Valid agent
  cat > "$SANDBOX/.github/agents/code.agent.md" <<'AGENT'
---
name: Code
description: Coding agent
model:
  - Claude Sonnet 4.6
tools:
  - codebase
---
# Code Agent
AGENT

  # Valid skill (name matches dir)
  cat > "$SANDBOX/.github/skills/my-skill/SKILL.md" <<'SKILL'
---
name: my-skill
description: Does something useful in exactly one workflow
---
# My Skill
SKILL
  cat > "$SANDBOX/template/skills/my-skill/SKILL.md" <<'SKILL'
---
name: my-skill
description: Does something useful in exactly one workflow
---
# My Skill
SKILL

  # Valid .instructions.md
  cat > "$SANDBOX/.github/instructions/api.instructions.md" <<'INST'
---
applyTo: '**/api/**'
---
Use REST conventions.
INST

  # Valid .prompt.md
  cat > "$SANDBOX/.github/prompts/commit.prompt.md" <<'PROMPT'
---
description: Commit helper
agent: agent
---
Write a commit message.
PROMPT

  # Valid hook config
  cat > "$SANDBOX/template/hooks/copilot-hooks.json" <<'JSON'
{"hooks": []}
JSON

  # Valid hook script (template)
  cat > "$SANDBOX/template/hooks/scripts/session-start.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo '{}'
SH

  # Valid hook script (.github mirror)
  mkdir -p "$SANDBOX/.github/hooks"
  cp "$SANDBOX/template/hooks/copilot-hooks.json" "$SANDBOX/.github/hooks/copilot-hooks.json"
  cp "$SANDBOX/template/hooks/scripts/session-start.sh" "$SANDBOX/.github/hooks/scripts/session-start.sh"

  # Valid mcp.json
  cat > "$SANDBOX/.vscode/mcp.json" <<'JSON'
{
  "servers": {
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git"]
    }
  }
}
JSON

  # Minimal starter-kit metadata (one kit with plugin + registry entry)
  cat > "$SANDBOX/starter-kits/python/plugin.json" <<'JSON'
{
  "name": "python-starter-kit",
  "displayName": "Python Starter Kit",
  "description": "Sandbox starter kit",
  "version": "1.0.0"
}
JSON

  cat > "$SANDBOX/starter-kits/REGISTRY.json" <<'JSON'
{
  "schemaVersion": "1.0",
  "description": "Sandbox registry",
  "kits": [
    {
      "name": "python",
      "displayName": "Python Starter Kit",
      "description": "Sandbox starter kit",
      "files": ["plugin.json"]
    }
  ]
}
JSON
}

teardown_sandbox() {
  [[ -n "${SANDBOX:-}" ]] && rm -rf "$SANDBOX"
}

run_audit() {
  python3 "$SCRIPT" --root "$SANDBOX" --output json 2>&1
}

run_audit_md() {
  python3 "$SCRIPT" --root "$SANDBOX" --output md 2>&1
}
