#!/usr/bin/env bash
# tests/lib/copilot-audit-sandbox.sh — shared sandbox setup for copilot_audit tests.
# Sourced by test-copilot-audit.sh. Provides setup_sandbox, teardown_sandbox,
# run_audit, and run_audit_md helpers.
#
# Requires: REPO_ROOT set by init_test_context; SCRIPT pointing to copilot_audit.py.

setup_sandbox() {
  SANDBOX=$(mktemp -d)
  # Minimal valid structure — all checks pass
  mkdir -p "$SANDBOX/agents"
  mkdir -p "$SANDBOX/.github/instructions"
  mkdir -p "$SANDBOX/.github/prompts"
  mkdir -p "$SANDBOX/.github/hooks"
  mkdir -p "$SANDBOX/skills/my-skill"
  mkdir -p "$SANDBOX/hooks/scripts"
  mkdir -p "$SANDBOX/template/instructions"
  mkdir -p "$SANDBOX/template/prompts"
  mkdir -p "$SANDBOX/.vscode"
  mkdir -p "$SANDBOX/starter-kits/python"

  # plugin manifest — needed for repo_shape developer detection
  cat > "$SANDBOX/plugin.json" <<'JSON'
{"name": "copilot-instructions-template", "description": "sandbox", "version": "0.0.1"}
JSON

  # Developer instructions — must have zero {{PLACEHOLDER}} tokens
  cat > "$SANDBOX/.github/copilot-instructions.md" <<'MD'
# Developer Instructions
> Role: AI developer.
Main/default agent delegation: when the request matches a named specialist workflow,
delegate instead of absorbing the workflow inline.
Do not keep specialist work inline because it seems small, quick, or manageable.
Trust the selected specialist to complete the task unless you know it is outside the specialist scope, allow-list, or capabilities, or it reports a concrete blocker.
Preferred specialist map: `Explore` for read-only repo scans, `Researcher` for current external docs, `Review` for formal code review or architectural critique, `Audit` for health, security, or residual-risk checks, `Docs` for documentation and migration-note work, `Extensions` for VS Code extension, profile, or workspace recommendation work, `Commit` for staging, commits, pushes, tags, or releases, `Setup` for template bootstrap, instruction update, backup restore, or factory restore work, `Organise` for file moves, path repair, or repository reshaping, and `Cleaner` for stale artefact, archive, and cache cleanup.
MD

  # Consumer template — must have ≥ 3 {{PLACEHOLDER}} tokens
  cat > "$SANDBOX/template/copilot-instructions.md" <<'MD'
# Template
{{REPO_OWNER}} {{REPO_NAME}} {{LANGUAGE}}
The parent/default agent follows this protocol too: if a request matches a named specialist workflow, delegate to the matching agent instead of absorbing the specialist workflow inline.
Do not keep specialist work inline because it seems small, quick, or manageable.
Trust the selected specialist to complete the task unless you know it is outside the specialist scope, allow-list, or capabilities, or the specialist reports a concrete blocker.
Preferred specialist map: `Explore` for read-only repo scans, `Researcher` for current external docs, `Review` for formal code review or architectural critique, `Audit` for health, security, or residual-risk checks, `Docs` for documentation and migration-note work, `Extensions` for VS Code extension, profile, or workspace recommendation work, `Commit` for staging, commits, pushes, tags, or releases, `Setup` for template bootstrap, instruction update, backup restore, or factory restore work, `Organise` for file moves, path repair, or repository reshaping, and `Cleaner` for stale artefact, archive, and cache cleanup.
MD

  # Valid agent
  cat > "$SANDBOX/agents/code.agent.md" <<'AGENT'
---
name: Code
description: Coding agent
model:
  - Claude Sonnet 4.6
tools: [agent, codebase]
agents: ['Review', 'Audit', 'Researcher', 'Explore', 'Commit', 'Organise', 'Planner', 'Docs', 'Debugger', 'Cleaner']
---
# Code Agent
AGENT

  # Valid skill (name matches dir)
  cat > "$SANDBOX/skills/my-skill/SKILL.md" <<'SKILL'
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

  # Valid hook configs
  cat > "$SANDBOX/hooks/hooks.json" <<'JSON'
{"hooks": []}
JSON
  cat > "$SANDBOX/.github/hooks/copilot-hooks.json" <<'JSON'
{"hooks": []}
JSON

  # Valid hook script
  cat > "$SANDBOX/hooks/scripts/session-start.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo '{}'
SH

  # Valid mcp.json — includes heartbeat to satisfy M5 (all-local default)
  cat > "$SANDBOX/.vscode/mcp.json" <<'JSON'
{
  "servers": {
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git"]
    },
    "heartbeat": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-heartbeat"]
    }
  }
}
JSON

  # Minimal starter-kit metadata (one kit with plugin + registry entry)
  mkdir -p "$SANDBOX/starter-kits/python/.claude-plugin"
  cat > "$SANDBOX/starter-kits/python/.claude-plugin/plugin.json" <<'JSON'
{
  "name": "python-starter-kit",
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
      "files": [".claude-plugin/plugin.json"]
    }
  ]
}
JSON
}

teardown_sandbox() {
  [[ -n "${SANDBOX:-}" ]] && rm -rf "$SANDBOX"
}

write_sandbox_file() {
  local rel_path="$1"
  local target="$SANDBOX/$rel_path"
  mkdir -p "$(dirname "$target")"
  cat > "$target"
}

append_sandbox_file() {
  local rel_path="$1"
  local target="$SANDBOX/$rel_path"
  mkdir -p "$(dirname "$target")"
  cat >> "$target"
}

remove_sandbox_path() {
  local rel_path="$1"
  rm -rf "${SANDBOX:?}/$rel_path"
}

run_audit() {
  local profile="${1:-developer}"
  python3 "$SCRIPT" --root "$SANDBOX" --profile "$profile" --output json 2>&1
}

run_audit_md() {
  local profile="${1:-developer}"
  python3 "$SCRIPT" --root "$SANDBOX" --profile "$profile" --output md 2>&1
}

run_audit_case() {
  local format="${1:-json}" mutator="${2:-}" profile="${3:-developer}"
  # shellcheck disable=SC2034
  CASE_OUTPUT=""
  # shellcheck disable=SC2034
  CASE_STATUS=0
  setup_sandbox
  if [[ -n "$mutator" ]]; then
    "$mutator"
  fi
  if [[ "$format" == "md" ]]; then
    # shellcheck disable=SC2034
    CASE_OUTPUT=$(run_audit_md "$profile")
  else
    # shellcheck disable=SC2034
    CASE_OUTPUT=$(run_audit "$profile")
  fi
  # shellcheck disable=SC2034
  CASE_STATUS=$?
  teardown_sandbox
}
