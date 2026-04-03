#!/usr/bin/env bash
# sync-workspace-index.sh — keep repo and template workspace-index.json files aligned with repo state.
#
# Usage:
#   bash scripts/workspace/sync-workspace-index.sh --write   # rewrite repo and template workspace-index.json files from filesystem
#   bash scripts/workspace/sync-workspace-index.sh --check   # fail if either workspace-index.json copy is out of sync
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
WORKSPACE_INDEX_PATH="$ROOT_DIR/.copilot/workspace/workspace-index.json"
TEMPLATE_WORKSPACE_INDEX_PATH="$ROOT_DIR/template/workspace/workspace-index.json"
MODE="${1:---check}"

# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"
require_python_check_write "workspace/sync-workspace-index.sh" "$MODE"

python3 - "$ROOT_DIR" "$WORKSPACE_INDEX_PATH" "$TEMPLATE_WORKSPACE_INDEX_PATH" "$MODE" <<'PY'
import datetime
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
index_path = pathlib.Path(sys.argv[2])
template_index_path = pathlib.Path(sys.argv[3])
mode = sys.argv[4]

preferred_agents = [
    "setup.agent.md",
    "coding.agent.md",
    "organise.agent.md",
    "review.agent.md",
    "fast.agent.md",
    "audit.agent.md",
    "explore.agent.md",
    "extensions.agent.md",
    "researcher.agent.md",
    "commit.agent.md",
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
    "commit-preflight",
]

preferred_shell_hooks = [
    "lib-hooks.sh",
    "scan-secrets.sh",
    "session-start.sh",
    "guard-destructive.sh",
    "post-edit-lint.sh",
    "save-context.sh",
    "subagent-start.sh",
    "subagent-stop.sh",
    "mcp-npx.sh",
    "mcp-uvx.sh",
    "pulse.sh",
]

preferred_ps_hooks = [
    "scan-secrets.ps1",
    "session-start.ps1",
    "guard-destructive.ps1",
    "post-edit-lint.ps1",
    "save-context.ps1",
    "subagent-start.ps1",
    "subagent-stop.ps1",
    "pulse.ps1",
]

preferred_python_hooks = [
    "heartbeat_clock_summary.py",
    "mcp-heartbeat-server.py",
    "pulse_intent.py",
    "pulse_paths.py",
    "pulse_runtime.py",
    "pulse_state.py",
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
python_hooks_existing = [p.name for p in (root / "template/hooks/scripts").glob("*.py")]

agents = ordered(agents_existing, preferred_agents)
skills_repo = ordered(skills_repo_existing, preferred_skills)
skills_template = ordered(skills_template_existing, preferred_skills)
shell_hooks = ordered(shell_hooks_existing, preferred_shell_hooks)
ps_hooks = ordered(ps_hooks_existing, preferred_ps_hooks)
python_hooks = ordered(python_hooks_existing, preferred_python_hooks)

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
        "hookScriptsPython": len(python_hooks),
    },
    "agents": agents,
    "skills": {
        "repo": skills_repo,
        "template": skills_template,
    },
    "hookScripts": {
        "shell": shell_hooks,
        "powershell": ps_hooks,
        "python": python_hooks,
    },
    "notes": [
        "This index is the canonical metadata source for drift checks.",
        "Human-facing docs live on the docs branch.",
        "Consumer template: template/copilot-instructions.md (with {{PLACEHOLDER}} tokens).",
        "Developer instructions: .github/copilot-instructions.md (zero placeholder tokens, developer-only).",
    ],
}

if mode == "--write":
    for path in (index_path, template_index_path):
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", encoding="utf-8") as f:
            json.dump(generated, f, indent=2)
            f.write("\n")
        print(f"OK: wrote {path}")
    sys.exit(0)

for path in (index_path, template_index_path):
    if not path.exists():
        print(f"FAIL: missing {path}")
        print("Run: bash scripts/workspace/sync-workspace-index.sh --write")
        sys.exit(1)

for path in (index_path, template_index_path):
    with path.open(encoding="utf-8") as f:
        current = json.load(f)

    # Ignore 'updated' field in check mode to avoid daily drift noise.
    current_no_date = dict(current)
    current_no_date["updated"] = generated["updated"]

    if current_no_date != generated:
        print(f"FAIL: {path.relative_to(root).as_posix()} is out of sync")
        print("Run: bash scripts/workspace/sync-workspace-index.sh --write")
        sys.exit(1)

print("OK: workspace-index.json files are in sync")
PY
