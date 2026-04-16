#!/usr/bin/env bash
# tests/scripts/test-copilot-audit.sh — unit tests for scripts/copilot_audit.py
# Run: bash tests/scripts/test-copilot-audit.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

SCRIPT="$REPO_ROOT/scripts/copilot_audit.py"

# shellcheck source=../lib/copilot-audit-sandbox.sh
source "$(dirname "$0")/../lib/copilot-audit-sandbox.sh"
trap 'teardown_sandbox' EXIT

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

# ── Tests ─────────────────────────────────────────────────────────────────────

echo "=== copilot_audit.py unit tests ==="
echo ""

# ── 1. Clean sandbox is HEALTHY ───────────────────────────────────────────────
echo "1. Clean sandbox exits 0 and reports HEALTHY"
run_audit_case json
assert_success "exits 0 on clean sandbox" "$CASE_STATUS"
assert_contains "status is HEALTHY" "$CASE_OUTPUT" '"status": "HEALTHY"'
assert_valid_json "output is valid JSON" "$CASE_OUTPUT"
echo ""

# ── 2. Markdown output format ─────────────────────────────────────────────────
echo "2. --output md produces Markdown report"
run_audit_case md
assert_contains "has h1 header"  "$CASE_OUTPUT" "# Copilot Audit Report"
assert_contains "has status line" "$CASE_OUTPUT" "**Status**: HEALTHY"
echo ""

# ── 3. A1 — agent missing name field ─────────────────────────────────────────
echo "3. A1: agent missing name field triggers HIGH"
run_audit_case json mutate_a1_missing_name
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "A1 HIGH reported" "$CASE_OUTPUT" '"severity": "HIGH"'
assert_contains "mentions name field" "$CASE_OUTPUT" 'name'
echo ""

# ── 4. A2 — broken handoff target ────────────────────────────────────────────
echo "4. A2: broken handoff target triggers CRITICAL"
run_audit_case json mutate_a2_broken_handoff
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "A2 CRITICAL" "$CASE_OUTPUT" 'GhostAgent'
echo ""

# ── 5. A3 — agent with placeholder token ─────────────────────────────────────
echo "5. A3: agent with {{PLACEHOLDER}} token triggers HIGH"
run_audit_case json mutate_a3_unresolved_agent
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "A3 finds placeholder" "$CASE_OUTPUT" 'placeholder token'
echo ""

# ── 6. A4 — missing required delegate ────────────────────────────────────────
echo "6. A4: missing required delegate triggers HIGH"
run_audit_case json mutate_a4_missing_delegate
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "A4 HIGH" "$CASE_OUTPUT" '"check_id": "A4"'
assert_contains "A4 missing delegate" "$CASE_OUTPUT" 'Missing required delegate(s): Cleaner, Commit'
echo ""

# ── 7. I1 — developer file has placeholder ───────────────────────────────────
echo "7. I1: developer instructions with {{PLACEHOLDER}} triggers CRITICAL"
run_audit_case json mutate_i1_dev_placeholder
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "I1 CRITICAL" "$CASE_OUTPUT" '"check_id": "I1"'
echo ""

# ── 8. I1 — consumer template too few placeholders ───────────────────────────
echo "8. I1: consumer template with < 3 placeholders triggers HIGH"
run_audit_case json mutate_i1_consumer_too_few_placeholders
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "I1 HIGH for consumer" "$CASE_OUTPUT" 'Consumer template'
echo ""

# ── 9. I1 — prose mentions of {{PLACEHOLDER}} in backticks are not flagged ───
echo "9. I1: backtick-wrapped {{PLACEHOLDER}} prose not flagged"
run_audit_case json mutate_i1_backtick_placeholder
assert_success "exits 0 — backtick placeholder not flagged" "$CASE_STATUS"
assert_contains "still HEALTHY" "$CASE_OUTPUT" '"status": "HEALTHY"'
echo ""

# ── 10. I4 — main-agent delegation policy missing ───────────────────────────
echo "10. I4: missing main-agent delegation policy triggers HIGH"
run_audit_case json mutate_i4_missing_delegation_policy
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "I4 HIGH" "$CASE_OUTPUT" '"check_id": "I4"'
assert_contains "I4 policy guidance" "$CASE_OUTPUT" 'Missing delegation policy guidance'
echo ""

# ── 11. S1 — skill name mismatch ─────────────────────────────────────────────
echo "11. S1: skill name not matching directory triggers HIGH"
run_audit_case json mutate_s1_wrong_skill_name
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "S1 mismatch" "$CASE_OUTPUT" 'does not match directory'
echo ""

# ── 12. M1 — invalid JSON in mcp.json ────────────────────────────────────────
echo "12. M1: invalid JSON in mcp.json triggers CRITICAL"
run_audit_case json mutate_m1_invalid_json
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "M1 CRITICAL" "$CASE_OUTPUT" 'Invalid JSON'
echo ""

# ── 13. M2 — npx + mcp-server-git anti-pattern ───────────────────────────────
echo "13. M2: npx mcp-server-git triggers CRITICAL"
run_audit_case json mutate_m2_npx_git
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "M2 npx flagged" "$CASE_OUTPUT" 'npx'
echo ""

# ── 13b. M2 — JSONC mcp.json still parses ─────────────────────────────────
echo "13b. M2: JSONC mcp.json still triggers anti-pattern detection"
run_audit_case json mutate_m2_jsonc_npx_git
assert_failure "JSONC mcp config still exits non-zero" "$CASE_STATUS"
assert_contains "M2 JSONC npx flagged" "$CASE_OUTPUT" 'mcp-server-git'
echo ""

# ── 14. M3 — literal secret in mcp env ───────────────────────────────────────
echo "14. M3: literal secret value in mcp env triggers HIGH"
run_audit_case json mutate_m3_literal_secret
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "M3 secret flagged" "$CASE_OUTPUT" '"severity": "HIGH"'
echo ""

# ── 15. H1 — missing hooks config ────────────────────────────────────────────
echo "15. H1: missing copilot-hooks.json triggers HIGH"
run_audit_case json mutate_h1_missing_hooks
assert_failure "exits non-zero" "$CASE_STATUS"
assert_contains "H1 HIGH" "$CASE_OUTPUT" 'hooks config not found'
echo ""

# ── 16. SH1 — missing shebang ────────────────────────────────────────────────
echo "16. SH1: hook script without shebang triggers HIGH"
run_audit_case json mutate_sh1_missing_shebang
assert_contains "SH1 shebang missing" "$CASE_OUTPUT" 'shebang'
echo ""

# ── 17. SH3 — bash syntax error ──────────────────────────────────────────────
echo "17. SH3: bash syntax error in hook script triggers HIGH"
run_audit_case json mutate_sh3_broken_shell
# If bash is available, SH3 should flag it
if command -v bash >/dev/null 2>&1; then
  assert_contains "SH3 syntax error caught" "$CASE_OUTPUT" 'Syntax error'
else
  echo "  SKIP: bash not available"
fi
echo ""

# ── 18. Real repo passes audit ────────────────────────────────────────────────
echo "18. Real repo passes the audit (HEALTHY)"
out=$(python3 "$SCRIPT" --root "$REPO_ROOT" --output json 2>&1)
exit_code=$?
assert_success "real repo exits 0" "$exit_code"
assert_contains "real repo HEALTHY" "$out" '"status": "HEALTHY"'
echo ""

# ── 19. H2 — missing PowerShell hook script ──────────────────────────────────
echo "19. H2: missing PowerShell hook script triggers WARN"
run_audit_case json mutate_h2_missing_powershell_script
assert_success "exits 0 on WARN-only H2" "$CASE_STATUS"
assert_contains "H2 WARN-only is DEGRADED" "$CASE_OUTPUT" '"status": "DEGRADED"'
assert_contains "H2 reports missing PowerShell script" "$CASE_OUTPUT" 'missing-session-start.ps1'
echo ""

# ── 19b. PS1 — resolver degrades gracefully without bash ────────────────────
echo "19b. PS1: resolver does not crash audit when bash is unavailable"
setup_sandbox
mutate_ps1_resolver_without_bash
NO_BASH_PATH="$SANDBOX/no-bash-bin"
mkdir -p "$NO_BASH_PATH"
PYTHON_BIN=$(command -v python3)
if CASE_OUTPUT=$(PATH="$NO_BASH_PATH" "$PYTHON_BIN" "$SCRIPT" --root "$SANDBOX" --output json 2>&1); then
  CASE_STATUS=0
else
  CASE_STATUS=$?
fi
teardown_sandbox
assert_success "audit exits zero when resolver exists but bash is unavailable" "$CASE_STATUS"
assert_contains "audit remains healthy without bash" "$CASE_OUTPUT" '"status": "HEALTHY"'
echo ""

# ── 20. VS1 — invalid customization locations in settings.json ──────────────
echo "20. VS1: invalid customization paths in settings.json trigger WARN"
run_audit_case json mutate_vs1_invalid_settings_paths
assert_success "VS1 WARN-only still exits 0" "$CASE_STATUS"
assert_contains "VS1 WARN-only is DEGRADED" "$CASE_OUTPUT" '"status": "DEGRADED"'
assert_contains "VS1 reports missing plugin path" "$CASE_OUTPUT" 'chat.pluginLocations entry not found'
assert_contains "VS1 reports missing instructions path" "$CASE_OUTPUT" 'chat.instructionsFilesLocations entry not found'
echo ""

# ── 21. K1 — invalid starter-kit plugin JSON ────────────────────────────────
echo "21. K1: invalid starter-kit plugin JSON triggers CRITICAL"
run_audit_case json mutate_k1_invalid_plugin_json
assert_failure "exits non-zero on bad plugin" "$CASE_STATUS"
assert_contains "K1 invalid plugin JSON" "$CASE_OUTPUT" '"check_id": "K1"'
echo ""

# ── 22. K2 — REGISTRY references missing starter-kit files ─────────────────
echo "22. K2: REGISTRY references missing starter-kit files triggers HIGH"
run_audit_case json mutate_k2_missing_registry_file
assert_failure "exits non-zero on missing starter-kit file" "$CASE_STATUS"
assert_contains "K2 missing file" "$CASE_OUTPUT" 'skills/python-testing/SKILL.md'
echo ""

# ── 23. Consumer profile — consumer-shaped repo passes ─────────────────────
echo "23. consumer profile: consumer-shaped repo remains HEALTHY"
run_audit_case json mutate_consumer_layout consumer
assert_success "consumer profile exits 0 on consumer-shaped repo" "$CASE_STATUS"
assert_contains "consumer profile HEALTHY" "$CASE_OUTPUT" '"status": "HEALTHY"'
echo ""

# ── 23b. Consumer profile — VS Code opt-out remains HEALTHY ─────────────────
echo "23b. consumer profile: VS Code opt-out remains HEALTHY"
run_audit_case json mutate_consumer_layout_without_vscode_surfaces consumer
assert_success "consumer profile allows missing opted-out VS Code files" "$CASE_STATUS"
assert_contains "consumer profile stays HEALTHY without VS Code files" "$CASE_OUTPUT" '"status": "HEALTHY"'
echo ""

# ── 23c. Consumer profile — legacy workspace-index is no longer supported ───
echo "23c. consumer profile: legacy workspace-index fails when required inventories are missing"
run_audit_case json mutate_consumer_legacy_workspace_index_without_optional_files consumer
assert_failure "consumer profile rejects legacy workspace-index without optional inventories" "$CASE_STATUS"
assert_contains "consumer profile reports C1 for legacy workspace-index" "$CASE_OUTPUT" '"check_id": "C1"'
assert_contains "consumer profile flags missing prompts inventory" "$CASE_OUTPUT" 'workspace-index missing required inventory list: prompts'
echo ""

# ── 24. Consumer profile — A4 repo policy skipped ──────────────────────────
echo "24. consumer profile: A4 repo delegation policy is skipped"
run_audit_case json mutate_a4_missing_delegate consumer
assert_success "consumer profile skips A4" "$CASE_STATUS"
assert_contains "consumer profile stays HEALTHY for A4-only mutation" "$CASE_OUTPUT" '"status": "HEALTHY"'
echo ""

# ── 25. Consumer profile — I4 repo policy is enforced ──────────────────────
echo "25. consumer profile: I4 repo delegation wording is enforced"
run_audit_case json mutate_consumer_missing_delegation_policy consumer
assert_failure "consumer profile fails when delegation policy is missing" "$CASE_STATUS"
assert_contains "consumer profile reports I4" "$CASE_OUTPUT" '"check_id": "I4"'
echo ""

# ── 26. Consumer profile — installed starter-kit content is validated ──────
echo "26. consumer profile: installed starter-kit content is validated"
run_audit_case json mutate_consumer_missing_starter_kit_assets consumer
assert_failure "consumer profile fails on empty installed starter kit" "$CASE_STATUS"
assert_contains "consumer profile reports K2" "$CASE_OUTPUT" '"check_id": "K2"'
echo ""

# ── 27. Consumer profile — generic checks still run ────────────────────────
echo "27. consumer profile: generic MCP checks still trigger failures"
run_audit_case json mutate_m1_invalid_json consumer
assert_failure "consumer profile still exits non-zero on invalid MCP JSON" "$CASE_STATUS"
assert_contains "consumer profile still reports M1" "$CASE_OUTPUT" '"check_id": "M1"'
echo ""

# ── 28. Consumer profile — version metadata completeness enforced ───────────
echo "28. consumer profile: version metadata completeness is enforced"
run_audit_case json mutate_consumer_version_file_missing_blocks consumer
assert_failure "consumer profile fails on incomplete version metadata" "$CASE_STATUS"
assert_contains "consumer profile reports V1" "$CASE_OUTPUT" '"check_id": "V1"'
assert_contains "consumer profile flags setup-answers" "$CASE_OUTPUT" 'setup-answers block'
echo ""

# ── 29. Consumer profile — workspace inventory completeness enforced ────────
echo "29. consumer profile: workspace inventory completeness is enforced"
run_audit_case json mutate_consumer_missing_workflow_inventory_surface consumer
assert_failure "consumer profile fails on missing workflow surface" "$CASE_STATUS"
assert_contains "consumer profile reports C1" "$CASE_OUTPUT" '"check_id": "C1"'
assert_contains "consumer profile flags missing workflow" "$CASE_OUTPUT" 'copilot-setup-steps.yml'
echo ""

# ── 30. Consumer profile — file-manifest tracks managed surfaces ────────────
echo "30. consumer profile: file-manifest tracks managed surfaces"
run_audit_case json mutate_consumer_version_file_manifest_missing_surface consumer
assert_failure "consumer profile fails on incomplete file-manifest" "$CASE_STATUS"
assert_contains "consumer profile flags missing managed surface" "$CASE_OUTPUT" 'file-manifest missing managed surface'
assert_contains "consumer profile flags extensions surface" "$CASE_OUTPUT" '.vscode/extensions.json'
echo ""

# ── 31. Consumer profile — setup-answers track core setup decisions ─────────
echo "31. consumer profile: setup-answers track core setup decisions"
run_audit_case json mutate_consumer_setup_answers_missing_core_key consumer
assert_failure "consumer profile fails on missing core setup answer" "$CASE_STATUS"
assert_contains "consumer profile flags missing TEST_COMMAND" "$CASE_OUTPUT" 'setup-answers missing required key: TEST_COMMAND'
echo ""

# ── 32. M5 — plugin-backed: heartbeat in workspace mcp.json is duplicate ─────
echo "32. M5: plugin-backed ownership with workspace heartbeat triggers HIGH"
run_audit_case json mutate_m5_plugin_backed_with_workspace_heartbeat
assert_failure "exits non-zero when heartbeat duplicated in workspace mcp.json" "$CASE_STATUS"
assert_contains "M5 flags duplicate heartbeat" "$CASE_OUTPUT" '"check_id": "M5"'
assert_contains "M5 severity is HIGH" "$CASE_OUTPUT" '"severity": "HIGH"'
echo ""

# ── 33. M5 — all-local: heartbeat absent from workspace mcp.json ─────────────
echo "33. M5: all-local ownership with missing workspace heartbeat triggers HIGH"
run_audit_case json mutate_m5_all_local_missing_workspace_heartbeat
assert_failure "exits non-zero when heartbeat missing from workspace mcp.json" "$CASE_STATUS"
assert_contains "M5 flags missing heartbeat" "$CASE_OUTPUT" '"check_id": "M5"'
assert_contains "M5 severity is HIGH" "$CASE_OUTPUT" '"severity": "HIGH"'
echo ""

# ── 34. V1 — invalid OWNERSHIP_MODE value ─────────────────────────────────────
echo "34. V1: invalid OWNERSHIP_MODE value triggers HIGH"
run_audit_case json mutate_v1_invalid_ownership_mode consumer
assert_failure "exits non-zero on invalid OWNERSHIP_MODE" "$CASE_STATUS"
assert_contains "V1 flags invalid OWNERSHIP_MODE" "$CASE_OUTPUT" '"check_id": "V1"'
assert_contains "V1 reports OWNERSHIP_MODE error" "$CASE_OUTPUT" "OWNERSHIP_MODE must be 'plugin-backed' or 'all-local'"
echo ""

# ── 35. M5 — plugin-backed: .mcp.json absent or missing heartbeat ─────────────
echo "35. M5: plugin-backed ownership with missing .mcp.json heartbeat triggers HIGH"
run_audit_case json mutate_m5_plugin_backed_missing_plugin_mcp
assert_failure "exits non-zero when .mcp.json lacks heartbeat in plugin mode" "$CASE_STATUS"
assert_contains "M5 flags missing plugin-side heartbeat" "$CASE_OUTPUT" '"check_id": "M5"'
assert_contains "M5 severity is HIGH for missing .mcp.json" "$CASE_OUTPUT" '"severity": "HIGH"'

# ── Summary ───────────────────────────────────────────────────────────────────
finish_tests
