#!/usr/bin/env bash
# tests/lib/copilot-audit-fixtures.sh — mutate_* fixture functions for test-copilot-audit.sh
# Sourced by the test file; requires copilot-audit-sandbox.sh to be loaded first.
# shellcheck source=copilot-audit-sandbox.sh

mutate_a1_missing_name() {
  write_sandbox_file "agents/bad.agent.md" <<'AGENT'
---
description: no name here
model:
  - Claude Sonnet 4.6
---
# Bad Agent
AGENT
}

mutate_a2_broken_handoff() {
  append_sandbox_file "agents/code.agent.md" <<'EXTRA'

handoffs:
  - label: Go to ghost
    agent: GhostAgent
    prompt: Hand off
    send: false
EXTRA
}

mutate_a3_unresolved_agent() {
  write_sandbox_file "agents/unresolved.agent.md" <<'AGENT'
---
name: Unresolved
description: Still has {{REPO_NAME}} token
model:
  - Claude Sonnet 4.6
---
AGENT
}

mutate_a4_missing_delegate() {
  write_sandbox_file "agents/code.agent.md" <<'AGENT'
---
name: Code
description: Coding agent
model:
  - Claude Sonnet 4.6
tools: [agent, codebase]
agents: ['Review', 'Audit', 'Researcher', 'Explore', 'Organise', 'Planner', 'Docs', 'Debugger']
---
# Code Agent
AGENT
}

mutate_i1_dev_placeholder() {
  append_sandbox_file ".github/copilot-instructions.md" <<'MD'
Oops {{PLACEHOLDER_TOKEN}} left in.
MD
}

mutate_i1_consumer_too_few_placeholders() {
  write_sandbox_file "template/copilot-instructions.md" <<'MD'
# Template
{{REPO_OWNER}}
MD
}

mutate_i1_backtick_placeholder() {
  append_sandbox_file ".github/copilot-instructions.md" <<'MD'
Contains `{{PLACEHOLDER}}` tokens — purely descriptive.
MD
}

mutate_i4_missing_delegation_policy() {
  write_sandbox_file ".github/copilot-instructions.md" <<'MD'
# Developer Instructions
> Role: AI developer.
MD
}

mutate_s1_wrong_skill_name() {
  write_sandbox_file "skills/my-skill/SKILL.md" <<'SKILL'
---
name: wrong-name
description: Name does not match directory
---
SKILL
}

mutate_m1_invalid_json() {
  write_sandbox_file ".vscode/mcp.json" <<'JSON'
not json
JSON
}

mutate_m2_npx_git() {
  write_sandbox_file ".vscode/mcp.json" <<'JSON'
{
  "servers": {
    "git": {
      "command": "npx",
      "args": ["mcp-server-git", "--repository", "."]
    }
  }
}
JSON
}

mutate_m2_jsonc_npx_git() {
  write_sandbox_file ".vscode/mcp.json" <<'JSON'
{
  // JSONC comments should still parse
  "servers": {
    "git": {
      "command": "npx",
      "args": ["mcp-server-git", "--repository", "."],
    }
  }
}
JSON
}

mutate_consumer_layout() {
  remove_sandbox_path "template"
  remove_sandbox_path "starter-kits"
  remove_sandbox_path ".vscode/mcp.json"

  write_sandbox_file ".github/copilot-instructions.md" <<'MD'
# Consumer Instructions
Sandbox Owner Sandbox Python
The parent/default agent follows this protocol too: if a request matches a named specialist workflow, delegate to the matching agent instead of absorbing the specialist workflow inline.
Do not keep specialist work inline because it seems small, quick, or manageable.
Trust the selected specialist to complete the task unless you know it is outside the specialist scope, allow-list, or capabilities, or the specialist reports a concrete blocker.
Preferred specialist map: `Explore` for read-only repo scans, `Researcher` for current external docs, `Review` for formal code review or architectural critique, `Audit` for health, security, or residual-risk checks, `Docs` for documentation and migration-note work, `Extensions` for VS Code extension, profile, or workspace recommendation work, `Commit` for staging, commits, pushes, tags, or releases, `Setup` for template bootstrap, instruction update, backup restore, or factory restore work, `Organise` for file moves, path repair, or repository reshaping, and `Cleaner` for stale artefact, archive, and cache cleanup.
MD

  mkdir -p "$SANDBOX/.github/workflows"
  mkdir -p "$SANDBOX/.copilot/workspace/identity"
  mkdir -p "$SANDBOX/.copilot/workspace/knowledge/diaries"
  mkdir -p "$SANDBOX/.copilot/workspace/operations"
  mkdir -p "$SANDBOX/.copilot/workspace/runtime"
  write_sandbox_file ".github/agents/code.agent.md" <<'AGENT'
---
name: Code
description: Consumer coding agent
---
# Code Agent
AGENT
  write_sandbox_file ".github/agents/routing-manifest.json" <<'JSON'
{
  "version": "1.0",
  "routes": []
}
JSON
  write_sandbox_file ".github/skills/my-skill/SKILL.md" <<'SKILL'
---
name: my-skill
description: Consumer skill
---
# My Skill
SKILL
  write_sandbox_file ".github/hooks/scripts/session-start.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
echo '{}'
SH
  write_sandbox_file ".github/workflows/copilot-setup-steps.yml" <<'YAML'
name: Copilot Setup Steps
YAML
  write_sandbox_file ".vscode/extensions.json" <<'JSON'
{
  "recommendations": []
}
JSON
  for file in identity/BOOTSTRAP.md identity/IDENTITY.md identity/SOUL.md \
             knowledge/MEMORY.md knowledge/RESEARCH.md knowledge/TOOLS.md knowledge/USER.md \
             operations/HEARTBEAT.md operations/commit-style.md; do
    write_sandbox_file ".copilot/workspace/$file" <<'MD'
placeholder
MD
  done
  cat > "$SANDBOX/.copilot/workspace/operations/workspace-index.json" <<'JSON'
{
  "schemaVersion": "1.0",
  "counts": {
    "agents": 1,
    "agentSupportFiles": 1,
    "skillsRepo": 1,
    "skillsTemplate": 1,
    "hookScriptsShell": 1,
    "hookScriptsPowerShell": 0,
    "hookScriptsPython": 0,
    "hookScriptsJson": 0
  },
  "agents": ["code.agent.md"],
  "agentSupportFiles": ["routing-manifest.json"],
  "skills": {
    "repo": ["my-skill"]
  },
  "prompts": ["commit.prompt.md"],
  "instructions": ["api.instructions.md"],
  "workspaceFiles": [
    "identity/BOOTSTRAP.md",
    "operations/HEARTBEAT.md",
    "identity/IDENTITY.md",
    "knowledge/MEMORY.md",
    "knowledge/RESEARCH.md",
    "identity/SOUL.md",
    "knowledge/TOOLS.md",
    "knowledge/USER.md",
    "operations/commit-style.md",
    "operations/workspace-index.json"
  ],
  "workflowFiles": ["copilot-setup-steps.yml"],
  "hookScripts": {
    "shell": ["session-start.sh"],
    "powershell": [],
    "python": [],
    "json": []
  }
}
JSON

  mkdir -p "$SANDBOX/.github/starter-kits/python/.claude-plugin" "$SANDBOX/.github/starter-kits/python/commands"
  cat > "$SANDBOX/.github/starter-kits/python/.claude-plugin/plugin.json" <<'JSON'
{
  "name": "python-starter-kit",
  "description": "Sandbox installed starter kit",
  "version": "1.0.0"
}
JSON
  cat > "$SANDBOX/.github/starter-kits/python/commands/python-debug.md" <<'PROMPT'
---
description: Python debug helper
agent: agent
---
Debug the Python issue.
PROMPT

  write_sandbox_file ".vscode/settings.json" <<'JSON'
{
  // Installed local plugin path
  "chat.pluginLocations": {
    ".github/starter-kits/python": true
  }
}
JSON

  write_sandbox_file ".github/copilot-version.md" <<'MD'
<!-- markdownlint-disable-file MD041 -->
5.4.0
Applied: 2026-04-04
Updated: 2026-04-04
<!-- section-fingerprints
§1=aaaaaaaaaaaa
-->
<!-- file-manifest
.github/agents/code.agent.md=bbbbbbbbbbbb
.github/agents/routing-manifest.json=bbbbbbbbbbbb
.github/hooks/copilot-hooks.json=bbbbbbbbbbbb
.github/hooks/scripts/session-start.sh=bbbbbbbbbbbb
.github/instructions/api.instructions.md=bbbbbbbbbbbb
.github/prompts/commit.prompt.md=bbbbbbbbbbbb
.github/skills/my-skill/SKILL.md=bbbbbbbbbbbb
.github/workflows/copilot-setup-steps.yml=bbbbbbbbbbbb
.vscode/settings.json=bbbbbbbbbbbb
.vscode/extensions.json=bbbbbbbbbbbb
.copilot/workspace/identity/BOOTSTRAP.md=bbbbbbbbbbbb
.copilot/workspace/operations/HEARTBEAT.md=bbbbbbbbbbbb
.copilot/workspace/identity/IDENTITY.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/MEMORY.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/RESEARCH.md=bbbbbbbbbbbb
.copilot/workspace/identity/SOUL.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/TOOLS.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/USER.md=bbbbbbbbbbbb
.copilot/workspace/operations/commit-style.md=bbbbbbbbbbbb
.copilot/workspace/operations/workspace-index.json=bbbbbbbbbbbb
.github/starter-kits/python/.claude-plugin/plugin.json=bbbbbbbbbbbb
.github/starter-kits/python/commands/python-debug.md=bbbbbbbbbbbb
-->
<!-- setup-answers
PROJECT_NAME=Sandbox
LANGUAGE=Python
RUNTIME=Python
PACKAGE_MANAGER=pip
TEST_COMMAND=bash tests/run-all.sh
TYPE_CHECK_COMMAND=echo "no type check configured"
THREE_CHECK_COMMAND=echo "no three-check configured"
TEST_FRAMEWORK=bash
SETUP_DATE=2026-04-04
-->
MD
}

mutate_consumer_layout_without_vscode_surfaces() {
  mutate_consumer_layout
  remove_sandbox_path ".vscode/settings.json"
  remove_sandbox_path ".vscode/extensions.json"
  write_sandbox_file ".github/copilot-version.md" <<'MD'
<!-- markdownlint-disable-file MD041 -->
5.4.0
Applied: 2026-04-04
Updated: 2026-04-04
<!-- section-fingerprints
§1=aaaaaaaaaaaa
-->
<!-- file-manifest
.github/agents/code.agent.md=bbbbbbbbbbbb
.github/agents/routing-manifest.json=bbbbbbbbbbbb
.github/hooks/copilot-hooks.json=bbbbbbbbbbbb
.github/hooks/scripts/session-start.sh=bbbbbbbbbbbb
.github/instructions/api.instructions.md=bbbbbbbbbbbb
.github/prompts/commit.prompt.md=bbbbbbbbbbbb
.github/skills/my-skill/SKILL.md=bbbbbbbbbbbb
.github/workflows/copilot-setup-steps.yml=bbbbbbbbbbbb
.copilot/workspace/identity/BOOTSTRAP.md=bbbbbbbbbbbb
.copilot/workspace/operations/HEARTBEAT.md=bbbbbbbbbbbb
.copilot/workspace/identity/IDENTITY.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/MEMORY.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/RESEARCH.md=bbbbbbbbbbbb
.copilot/workspace/identity/SOUL.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/TOOLS.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/USER.md=bbbbbbbbbbbb
.copilot/workspace/operations/commit-style.md=bbbbbbbbbbbb
.copilot/workspace/operations/workspace-index.json=bbbbbbbbbbbb
.github/starter-kits/python/.claude-plugin/plugin.json=bbbbbbbbbbbb
.github/starter-kits/python/commands/python-debug.md=bbbbbbbbbbbb
-->
<!-- setup-answers
PROJECT_NAME=Sandbox
LANGUAGE=Python
RUNTIME=Python
PACKAGE_MANAGER=pip
TEST_COMMAND=bash tests/run-all.sh
TYPE_CHECK_COMMAND=echo "no type check configured"
THREE_CHECK_COMMAND=echo "no three-check configured"
TEST_FRAMEWORK=bash
SETUP_DATE=2026-04-04
-->
MD
}

mutate_consumer_legacy_workspace_index_without_optional_files() {
  mutate_consumer_layout_without_vscode_surfaces
  write_sandbox_file ".copilot/workspace/operations/workspace-index.json" <<'JSON'
{
  "schemaVersion": "0.9",
  "counts": {
    "agents": 1,
    "agentSupportFiles": 1,
    "skillsRepo": 1,
    "skillsTemplate": 1,
    "hookScriptsShell": 1,
    "hookScriptsPowerShell": 0,
    "hookScriptsPython": 0,
    "hookScriptsJson": 0
  },
  "agents": ["code.agent.md"],
  "agentSupportFiles": ["routing-manifest.json"],
  "skills": {
    "repo": ["my-skill"]
  },
  "workspaceFiles": [
    "identity/BOOTSTRAP.md",
    "operations/HEARTBEAT.md",
    "identity/IDENTITY.md",
    "knowledge/MEMORY.md",
    "knowledge/RESEARCH.md",
    "identity/SOUL.md",
    "knowledge/TOOLS.md",
    "knowledge/USER.md",
    "operations/commit-style.md",
    "operations/workspace-index.json"
  ],
  "workflowFiles": ["copilot-setup-steps.yml"],
  "hookScripts": {
    "shell": ["session-start.sh"],
    "powershell": [],
    "python": [],
    "json": []
  }
}
JSON
}

mutate_consumer_missing_delegation_policy() {
  mutate_consumer_layout
  write_sandbox_file ".github/copilot-instructions.md" <<'MD'
# Consumer Instructions
> Role: AI developer.
MD
}

mutate_consumer_missing_starter_kit_assets() {
  mutate_consumer_layout
  remove_sandbox_path ".github/starter-kits/python/commands"
  remove_sandbox_path ".github/starter-kits/python/skills"
  remove_sandbox_path ".github/starter-kits/python/.claude-plugin"
}

mutate_consumer_version_file_missing_blocks() {
  mutate_consumer_layout
  write_sandbox_file ".github/copilot-version.md" <<'MD'
<!-- markdownlint-disable-file MD041 -->
5.4.0
Applied: 2026-04-04
Updated: 2026-04-04
<!-- section-fingerprints
§1=aaaaaaaaaaaa
-->
MD
}

mutate_consumer_missing_workflow_inventory_surface() {
  mutate_consumer_layout
  remove_sandbox_path ".github/workflows/copilot-setup-steps.yml"
}

mutate_consumer_version_file_manifest_missing_surface() {
  mutate_consumer_layout
  write_sandbox_file ".github/copilot-version.md" <<'MD'
<!-- markdownlint-disable-file MD041 -->
5.4.0
Applied: 2026-04-04
Updated: 2026-04-04
<!-- section-fingerprints
§1=aaaaaaaaaaaa
-->
<!-- file-manifest
agents/code.agent.md=bbbbbbbbbbbb
hooks/copilot-hooks.json=bbbbbbbbbbbb
-->
<!-- setup-answers
PROJECT_NAME=Sandbox
LANGUAGE=Python
RUNTIME=Python
PACKAGE_MANAGER=pip
TEST_COMMAND=bash tests/run-all.sh
TYPE_CHECK_COMMAND=echo "no type check configured"
THREE_CHECK_COMMAND=echo "no three-check configured"
TEST_FRAMEWORK=bash
SETUP_DATE=2026-04-04
-->
MD
}

mutate_consumer_setup_answers_missing_core_key() {
  mutate_consumer_layout
  write_sandbox_file ".github/copilot-version.md" <<'MD'
<!-- markdownlint-disable-file MD041 -->
5.4.0
Applied: 2026-04-04
Updated: 2026-04-04
<!-- section-fingerprints
§1=aaaaaaaaaaaa
-->
<!-- file-manifest
agents/code.agent.md=bbbbbbbbbbbb
agents/routing-manifest.json=bbbbbbbbbbbb
hooks/copilot-hooks.json=bbbbbbbbbbbb
hooks/scripts/session-start.sh=bbbbbbbbbbbb
.github/instructions/api.instructions.md=bbbbbbbbbbbb
.github/prompts/commit.prompt.md=bbbbbbbbbbbb
skills/my-skill/SKILL.md=bbbbbbbbbbbb
.github/workflows/copilot-setup-steps.yml=bbbbbbbbbbbb
.vscode/settings.json=bbbbbbbbbbbb
.vscode/extensions.json=bbbbbbbbbbbb
.copilot/workspace/identity/BOOTSTRAP.md=bbbbbbbbbbbb
.copilot/workspace/operations/HEARTBEAT.md=bbbbbbbbbbbb
.copilot/workspace/identity/IDENTITY.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/MEMORY.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/RESEARCH.md=bbbbbbbbbbbb
.copilot/workspace/identity/SOUL.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/TOOLS.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/USER.md=bbbbbbbbbbbb
.copilot/workspace/operations/commit-style.md=bbbbbbbbbbbb
.copilot/workspace/operations/workspace-index.json=bbbbbbbbbbbb
.github/starter-kits/python/.claude-plugin/plugin.json=bbbbbbbbbbbb
.github/starter-kits/python/commands/python-debug.md=bbbbbbbbbbbb
-->
<!-- setup-answers
PROJECT_NAME=Sandbox
LANGUAGE=Python
RUNTIME=Python
PACKAGE_MANAGER=pip
TYPE_CHECK_COMMAND=echo "no type check configured"
THREE_CHECK_COMMAND=echo "no three-check configured"
TEST_FRAMEWORK=bash
SETUP_DATE=2026-04-04
-->
MD
}

mutate_m3_literal_secret() {
  write_sandbox_file ".vscode/mcp.json" <<'JSON'
{
  "servers": {
    "myapi": {
      "command": "uvx",
      "args": ["some-mcp-server"],
      "env": {
        "MYAPP_API_TOKEN": "sk-abc123real-secret-value-here"
      }
    }
  }
}
JSON
}

mutate_h1_missing_hooks() {
  remove_sandbox_path "hooks/hooks.json"
  remove_sandbox_path ".github/hooks/copilot-hooks.json"
}

mutate_sh1_missing_shebang() {
  write_sandbox_file "hooks/scripts/noshebang.sh" <<'SH'
set -euo pipefail
echo '{}'
SH
}

mutate_sh3_broken_shell() {
  write_sandbox_file "hooks/scripts/broken.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ true; then
  echo bad
fi
SH
}

mutate_h2_missing_powershell_script() {
  write_sandbox_file ".github/hooks/copilot-hooks.json" <<'JSON'
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "./hooks/scripts/session-start.sh",
        "windows": "powershell -File .github\\hooks\\scripts\\missing-session-start.ps1",
        "timeout": 10
      }
    ]
  }
}
JSON
}

mutate_ps1_resolver_without_bash() {
  write_sandbox_file "scripts/harness/resolve-powershell.sh" <<'SH'
#!/usr/bin/env bash
exit 1
SH
}

mutate_vs1_invalid_settings_paths() {
  write_sandbox_file ".vscode/settings.json" <<'JSON'
{
  // Local plugin registrations
  "chat.pluginLocations": {
    ".github/starter-kits/missing": true
  },
  "chat.instructionsFilesLocations": {
    ".github/missing-instructions": true
  },
  "chat.promptFilesLocations": {
    ".github/missing-prompts": true
  },
  "chat.agentFilesLocations": {
    ".github/missing-agents": true
  },
  "chat.skillsLocations": {
    ".github/missing-skills": true
  },
  "chat.hookFilesLocations": {
    ".github/missing-hooks": true
  }
}
JSON
}

mutate_k1_invalid_plugin_json() {
  mkdir -p "$SANDBOX/starter-kits/python/.claude-plugin"
  write_sandbox_file "starter-kits/python/.claude-plugin/plugin.json" <<'JSON'
not json
JSON
}

mutate_k2_missing_registry_file() {
  write_sandbox_file "starter-kits/REGISTRY.json" <<'JSON'
{
  "schemaVersion": "1.0",
  "description": "Sandbox registry with missing files",
  "kits": [
    {
      "name": "python",
      "displayName": "Python Starter Kit",
      "description": "Sandbox kit",
      "files": [".claude-plugin/plugin.json", "skills/python-testing/SKILL.md"]
    }
  ]
}
JSON
}

mutate_m5_plugin_backed_with_workspace_heartbeat() {
  # HEARTBEAT_MCP=plugin but workspace mcp.json still has a heartbeat server → M5 HIGH
  write_sandbox_file ".github/copilot-version.md" <<'MD'
<!-- markdownlint-disable-file MD041 -->
5.0.0
Applied: 2026-01-01
<!-- ownership-mode
OWNERSHIP_MODE=plugin-backed
AGENTS=plugin
SKILLS=plugin
HOOKS=plugin
HEARTBEAT_MCP=plugin
-->
MD
  # Sandbox mcp.json already has a heartbeat entry (added during setup_sandbox)
}

mutate_m5_all_local_missing_workspace_heartbeat() {
  # HEARTBEAT_MCP=local but workspace mcp.json lacks heartbeat → M5 HIGH
  write_sandbox_file ".github/copilot-version.md" <<'MD'
<!-- markdownlint-disable-file MD041 -->
5.0.0
Applied: 2026-01-01
<!-- ownership-mode
OWNERSHIP_MODE=all-local
AGENTS=local
SKILLS=local
HOOKS=local
HEARTBEAT_MCP=local
-->
MD
  # Overwrite mcp.json without a heartbeat entry
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
}

mutate_m5_plugin_backed_missing_plugin_mcp() {
  # HEARTBEAT_MCP=plugin and workspace mcp.json has no heartbeat (correct) but
  # .mcp.json is absent → M5 HIGH (missing plugin-side declaration)
  write_sandbox_file ".github/copilot-version.md" <<'MD'
<!-- markdownlint-disable-file MD041 -->
5.0.0
Applied: 2026-01-01
<!-- ownership-mode
OWNERSHIP_MODE=plugin-backed
AGENTS=plugin
SKILLS=plugin
HOOKS=plugin
HEARTBEAT_MCP=plugin
-->
MD
  # Workspace mcp.json has no heartbeat (correct for plugin-backed)
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
  # Remove the plugin .mcp.json so M5 has nothing to validate against
  rm -f "$SANDBOX/.mcp.json"
}

mutate_v1_invalid_ownership_mode() {
  mutate_consumer_layout
  # Overwrite with a version file that has an invalid OWNERSHIP_MODE
  write_sandbox_file ".github/copilot-version.md" <<'MD'
<!-- markdownlint-disable-file MD041 -->
5.4.0
Applied: 2026-04-04
Updated: 2026-04-04
<!-- section-fingerprints
§1=aaaaaaaaaaaa
-->
<!-- file-manifest
.github/agents/code.agent.md=bbbbbbbbbbbb
.github/agents/routing-manifest.json=bbbbbbbbbbbb
.github/hooks/copilot-hooks.json=bbbbbbbbbbbb
.github/hooks/scripts/session-start.sh=bbbbbbbbbbbb
.github/instructions/api.instructions.md=bbbbbbbbbbbb
.github/prompts/commit.prompt.md=bbbbbbbbbbbb
.github/skills/my-skill/SKILL.md=bbbbbbbbbbbb
.github/workflows/copilot-setup-steps.yml=bbbbbbbbbbbb
.vscode/settings.json=bbbbbbbbbbbb
.vscode/extensions.json=bbbbbbbbbbbb
.copilot/workspace/identity/BOOTSTRAP.md=bbbbbbbbbbbb
.copilot/workspace/operations/HEARTBEAT.md=bbbbbbbbbbbb
.copilot/workspace/identity/IDENTITY.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/MEMORY.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/RESEARCH.md=bbbbbbbbbbbb
.copilot/workspace/identity/SOUL.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/TOOLS.md=bbbbbbbbbbbb
.copilot/workspace/knowledge/USER.md=bbbbbbbbbbbb
.copilot/workspace/operations/commit-style.md=bbbbbbbbbbbb
.copilot/workspace/operations/workspace-index.json=bbbbbbbbbbbb
.github/starter-kits/python/.claude-plugin/plugin.json=bbbbbbbbbbbb
.github/starter-kits/python/commands/python-debug.md=bbbbbbbbbbbb
-->
<!-- setup-answers
PROJECT_NAME=Sandbox
LANGUAGE=Python
RUNTIME=Python
PACKAGE_MANAGER=pip
TEST_COMMAND=bash tests/run-all.sh
TYPE_CHECK_COMMAND=echo "no type check configured"
THREE_CHECK_COMMAND=echo "no three-check configured"
TEST_FRAMEWORK=bash
SETUP_DATE=2026-04-04
-->
<!-- ownership-mode
OWNERSHIP_MODE=invalid-value
HEARTBEAT_MCP=local
-->
MD
}

