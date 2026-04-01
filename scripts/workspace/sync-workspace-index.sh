#!/usr/bin/env bash
# sync-workspace-index.sh — keep .copilot/workspace/workspace-index.json aligned with repo state.
#
# Usage:
#   bash scripts/workspace/sync-workspace-index.sh --write   # rewrite workspace-index.json from filesystem
#   bash scripts/workspace/sync-workspace-index.sh --check   # fail if workspace-index.json is out of sync
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
WORKSPACE_INDEX_PATH="$ROOT_DIR/.copilot/workspace/workspace-index.json"
MODE="${1:---check}"

# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"
require_python_check_write "workspace/sync-workspace-index.sh" "$MODE"

python3 - "$ROOT_DIR" "$WORKSPACE_INDEX_PATH" "$MODE" <<'PY'
import datetime
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
index_path = pathlib.Path(sys.argv[2])
mode = sys.argv[3]

preferred_agents = [
    "setup.agent.md",
    "coding.agent.md",
    "review.agent.md",
    "fast.agent.md",
    "audit.agent.md",
    "researcher.agent.md",
    "explore.agent.md",
]

preferred_skills = [
    "skill-creator",
    "fix-ci-failure",
    "lean-pr-review",
    "conventional-commit",
    "create-adr",
    "mcp-builder",
    "webapp-testing",
    "agentic-workflows",
    "issue-triage",
    "tool-protocol",
    "skill-management",
    "mcp-management",
    "plugin-management",
    "extension-review",
    "test-coverage-review",
]

preferred_shell_hooks = [
    "lib-hooks.sh",
    "scan-secrets.sh",
    "session-start.sh",
    "guard-destructive.sh",
    "post-edit-lint.sh",
    "enforce-retrospective.sh",
    "save-context.sh",
    "subagent-start.sh",
    "subagent-stop.sh",
]

preferred_ps_hooks = [
    "scan-secrets.ps1",
    "session-start.ps1",
    "guard-destructive.ps1",
    "post-edit-lint.ps1",
    "enforce-retrospective.ps1",
    "save-context.ps1",
    "subagent-start.ps1",
    "subagent-stop.ps1",
]


def ordered(existing, preferred):
    existing_set = set(existing)
    ordered_items = [item for item in preferred if item in existing_set]
    extras = sorted([item for item in existing if item not in set(preferred)])
    return ordered_items + extras


agents_existing = [p.name for p in (root / ".github/agents").glob("*.agent.md")]
skills_repo_existing = [p.parent.name for p in (root / ".github/skills").glob("*/SKILL.md")]
skills_template_existing = [p.parent.name for p in (root / "template/skills").glob("*/SKILL.md")]
shell_hooks_existing = [p.name for p in (root / "template/hooks/scripts").glob("*.sh")]
ps_hooks_existing = [p.name for p in (root / "template/hooks/scripts").glob("*.ps1")]

agents = ordered(agents_existing, preferred_agents)
skills_repo = ordered(skills_repo_existing, preferred_skills)
skills_template = ordered(skills_template_existing, preferred_skills)
shell_hooks = ordered(shell_hooks_existing, preferred_shell_hooks)
ps_hooks = ordered(ps_hooks_existing, preferred_ps_hooks)

generated = {
    "$schema": "https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.copilot/schema/workspace-index.schema.json",
    "schemaVersion": "1.0",
    "updated": datetime.date.today().isoformat(),
    "purpose": "Canonical machine-readable inventory for repository metadata.",
    "counts": {
        "agents": len(agents),
        "skillsRepo": len(skills_repo),
        "skillsTemplate": len(skills_template),
        "hookScriptsShell": len(shell_hooks),
        "hookScriptsPowerShell": len(ps_hooks),
    },
    "agents": agents,
    "skills": {
        "repo": skills_repo,
        "template": skills_template,
    },
    "hookScripts": {
        "shell": shell_hooks,
        "powershell": ps_hooks,
    },
    "notes": [
        "This index is the canonical metadata source for drift checks.",
        "Human-facing docs live on the docs branch.",
        "Consumer template: template/copilot-instructions.md (with {{PLACEHOLDER}} tokens).",
        "Developer instructions: .github/copilot-instructions.md (zero placeholder tokens, developer-only).",
    ],
}

if mode == "--write":
    index_path.parent.mkdir(parents=True, exist_ok=True)
    with index_path.open("w", encoding="utf-8") as f:
        json.dump(generated, f, indent=2)
        f.write("\n")
    print(f"OK: wrote {index_path}")
    sys.exit(0)

if not index_path.exists():
    print(f"FAIL: missing {index_path}")
    print("Run: bash scripts/workspace/sync-workspace-index.sh --write")
    sys.exit(1)

with index_path.open(encoding="utf-8") as f:
    current = json.load(f)

# Ignore 'updated' field in check mode to avoid daily drift noise.
current_no_date = dict(current)
current_no_date["updated"] = generated["updated"]

if current_no_date != generated:
    print("FAIL: workspace-index.json is out of sync")
    print("Run: bash scripts/workspace/sync-workspace-index.sh --write")
    sys.exit(1)

print("OK: workspace-index.json is in sync")
PY
