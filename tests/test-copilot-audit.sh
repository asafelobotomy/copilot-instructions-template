#!/usr/bin/env bash
# tests/test-copilot-audit.sh — unit tests for scripts/copilot_audit.py
# Run: bash tests/test-copilot-audit.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=tests/lib/test-helpers.sh
source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"

SCRIPT="$REPO_ROOT/scripts/copilot_audit.py"

# ── Sandbox helpers ───────────────────────────────────────────────────────────

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
mode: agent
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

# ── Tests ─────────────────────────────────────────────────────────────────────

echo "=== copilot_audit.py unit tests ==="
echo ""

# ── 1. Clean sandbox is HEALTHY ───────────────────────────────────────────────
echo "1. Clean sandbox exits 0 and reports HEALTHY"
setup_sandbox
out=$(run_audit)
exit_code=$?
assert_success "exits 0 on clean sandbox" "$exit_code"
assert_contains "status is HEALTHY" "$out" '"status": "HEALTHY"'
assert_valid_json "output is valid JSON" "$out"
teardown_sandbox
echo ""

# ── 2. Markdown output format ─────────────────────────────────────────────────
echo "2. --output md produces Markdown report"
setup_sandbox
out=$(run_audit_md)
assert_contains "has h1 header"  "$out" "# Copilot Audit Report"
assert_contains "has status line" "$out" "**Status**: HEALTHY"
teardown_sandbox
echo ""

# ── 3. A1 — agent missing name field ─────────────────────────────────────────
echo "3. A1: agent missing name field triggers HIGH"
setup_sandbox
cat > "$SANDBOX/.github/agents/bad.agent.md" <<'AGENT'
---
description: no name here
model:
  - Claude Sonnet 4.6
---
# Bad Agent
AGENT
out=$(run_audit)
exit_code=$?
assert_failure "exits non-zero" "$exit_code"
assert_contains "A1 HIGH reported" "$out" '"severity": "HIGH"'
assert_contains "mentions name field" "$out" 'name'
teardown_sandbox
echo ""

# ── 4. A2 — broken handoff target ────────────────────────────────────────────
echo "4. A2: broken handoff target triggers CRITICAL"
setup_sandbox
cat >> "$SANDBOX/.github/agents/code.agent.md" <<'EXTRA'

handoffs:
  - label: Go to ghost
    agent: GhostAgent
    prompt: Hand off
    send: false
EXTRA
out=$(run_audit)
exit_code=$?
assert_failure "exits non-zero" "$exit_code"
assert_contains "A2 CRITICAL" "$out" 'GhostAgent'
teardown_sandbox
echo ""

# ── 5. A3 — agent with placeholder token ─────────────────────────────────────
echo "5. A3: agent with {{PLACEHOLDER}} token triggers HIGH"
setup_sandbox
cat > "$SANDBOX/.github/agents/unresolved.agent.md" <<'AGENT'
---
name: Unresolved
description: Still has {{REPO_NAME}} token
model:
  - Claude Sonnet 4.6
---
AGENT
out=$(run_audit)
exit_code=$?
assert_failure "exits non-zero" "$exit_code"
assert_contains "A3 finds placeholder" "$out" 'placeholder token'
teardown_sandbox
echo ""

# ── 6. I1 — developer file has placeholder ───────────────────────────────────
echo "6. I1: developer instructions with {{PLACEHOLDER}} triggers CRITICAL"
setup_sandbox
echo "Oops {{PLACEHOLDER_TOKEN}} left in." >> "$SANDBOX/.github/copilot-instructions.md"
out=$(run_audit)
exit_code=$?
assert_failure "exits non-zero" "$exit_code"
assert_contains "I1 CRITICAL" "$out" '"check_id": "I1"'
teardown_sandbox
echo ""

# ── 7. I1 — consumer template too few placeholders ───────────────────────────
echo "7. I1: consumer template with < 3 placeholders triggers HIGH"
setup_sandbox
printf '# Template\n{{REPO_OWNER}}\n' > "$SANDBOX/template/copilot-instructions.md"
out=$(run_audit)
exit_code=$?
assert_failure "exits non-zero" "$exit_code"
assert_contains "I1 HIGH for consumer" "$out" 'Consumer template'
teardown_sandbox
echo ""

# ── 8. I1 — prose mentions of {{PLACEHOLDER}} in backticks are not flagged ───
echo "8. I1: backtick-wrapped {{PLACEHOLDER}} prose not flagged"
setup_sandbox
# Append a prose mention inside backticks — must not be counted as a real token
cat >> "$SANDBOX/.github/copilot-instructions.md" <<'MD'
Contains \`{{PLACEHOLDER}}\` tokens — purely descriptive.
MD
out=$(run_audit)
exit_code=$?
assert_success "exits 0 — backtick placeholder not flagged" "$exit_code"
assert_contains "still HEALTHY" "$out" '"status": "HEALTHY"'
teardown_sandbox
echo ""

# ── 9. S1 — skill name mismatch ──────────────────────────────────────────────
echo "9. S1: skill name not matching directory triggers HIGH"
setup_sandbox
cat > "$SANDBOX/.github/skills/my-skill/SKILL.md" <<'SKILL'
---
name: wrong-name
description: Name does not match directory
---
SKILL
out=$(run_audit)
exit_code=$?
assert_failure "exits non-zero" "$exit_code"
assert_contains "S1 mismatch" "$out" 'does not match directory'
teardown_sandbox
echo ""

# ── 10. M1 — invalid JSON in mcp.json ────────────────────────────────────────
echo "10. M1: invalid JSON in mcp.json triggers CRITICAL"
setup_sandbox
printf 'not json\n' > "$SANDBOX/.vscode/mcp.json"
out=$(run_audit)
exit_code=$?
assert_failure "exits non-zero" "$exit_code"
assert_contains "M1 CRITICAL" "$out" 'Invalid JSON'
teardown_sandbox
echo ""

# ── 11. M2 — npx + mcp-server-git anti-pattern ───────────────────────────────
echo "11. M2: npx mcp-server-git triggers CRITICAL"
setup_sandbox
cat > "$SANDBOX/.vscode/mcp.json" <<'JSON'
{
  "servers": {
    "git": {
      "command": "npx",
      "args": ["mcp-server-git", "--repository", "."]
    }
  }
}
JSON
out=$(run_audit)
exit_code=$?
assert_failure "exits non-zero" "$exit_code"
assert_contains "M2 npx flagged" "$out" 'npx'
teardown_sandbox
echo ""

# ── 12. M3 — literal secret in mcp env ───────────────────────────────────────
echo "12. M3: literal secret value in mcp env triggers HIGH"
setup_sandbox
cat > "$SANDBOX/.vscode/mcp.json" <<'JSON'
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
out=$(run_audit)
exit_code=$?
assert_failure "exits non-zero" "$exit_code"
assert_contains "M3 secret flagged" "$out" '"severity": "HIGH"'
teardown_sandbox
echo ""

# ── 13. H1 — missing hooks config ────────────────────────────────────────────
echo "13. H1: missing copilot-hooks.json triggers HIGH"
setup_sandbox
rm "$SANDBOX/template/hooks/copilot-hooks.json"
rm "$SANDBOX/.github/hooks/copilot-hooks.json"
out=$(run_audit)
exit_code=$?
assert_failure "exits non-zero" "$exit_code"
assert_contains "H1 HIGH" "$out" 'hooks config not found'
teardown_sandbox
echo ""

# ── 14. SH1 — missing shebang ────────────────────────────────────────────────
echo "14. SH1: hook script without shebang triggers HIGH"
setup_sandbox
cat > "$SANDBOX/template/hooks/scripts/noshebang.sh" <<'SH'
set -euo pipefail
echo '{}'
SH
out=$(run_audit)
assert_contains "SH1 shebang missing" "$out" 'shebang'
teardown_sandbox
echo ""

# ── 15. SH3 — bash syntax error ──────────────────────────────────────────────
echo "15. SH3: bash syntax error in hook script triggers HIGH"
setup_sandbox
cat > "$SANDBOX/template/hooks/scripts/broken.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ true; then
  echo bad
fi
SH
out=$(run_audit)
# If bash is available, SH3 should flag it
if command -v bash >/dev/null 2>&1; then
  assert_contains "SH3 syntax error caught" "$out" 'Syntax error'
else
  echo "  SKIP: bash not available"
fi
teardown_sandbox
echo ""

# ── 16. Real repo passes audit ────────────────────────────────────────────────
echo "16. Real repo passes the audit (HEALTHY)"
out=$(python3 "$SCRIPT" --root "$REPO_ROOT" --output json 2>&1)
exit_code=$?
assert_success "real repo exits 0" "$exit_code"
assert_contains "real repo HEALTHY" "$out" '"status": "HEALTHY"'
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
