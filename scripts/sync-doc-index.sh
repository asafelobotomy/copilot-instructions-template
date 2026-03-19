#!/usr/bin/env bash
# sync-doc-index.sh — keep .copilot/workspace/DOC_INDEX.json aligned with repo state.
#
# Usage:
#   bash scripts/sync-doc-index.sh --write   # rewrite DOC_INDEX.json from filesystem
#   bash scripts/sync-doc-index.sh --check   # fail if DOC_INDEX.json is out of sync
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
DOC_INDEX_PATH="$ROOT_DIR/.copilot/workspace/DOC_INDEX.json"
MODE="${1:---check}"

# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"
require_check_write_mode "sync-doc-index.sh" "$MODE"

python3 - "$ROOT_DIR" "$DOC_INDEX_PATH" "$MODE" <<'PY'
import datetime
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
doc_index_path = pathlib.Path(sys.argv[2])
mode = sys.argv[3]

preferred_agents = [
    "setup.agent.md",
    "coding.agent.md",
    "review.agent.md",
    "fast.agent.md",
    "update.agent.md",
    "doctor.agent.md",
]

preferred_skills = [
    "skill-creator",
    "fix-ci-failure",
    "lean-pr-review",
    "conventional-commit",
    "mcp-builder",
    "webapp-testing",
    "issue-triage",
    "tool-protocol",
    "skill-management",
    "mcp-management",
    "plugin-management",
    "extension-review",
    "test-coverage-review",
]

preferred_shell_hooks = [
    "session-start.sh",
    "guard-destructive.sh",
    "post-edit-lint.sh",
    "enforce-retrospective.sh",
    "save-context.sh",
]

preferred_ps_hooks = [
    "session-start.ps1",
    "guard-destructive.ps1",
    "post-edit-lint.ps1",
    "enforce-retrospective.ps1",
    "save-context.ps1",
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
    doc_index_path.parent.mkdir(parents=True, exist_ok=True)
    with doc_index_path.open("w", encoding="utf-8") as f:
        json.dump(generated, f, indent=2)
        f.write("\n")
    print(f"OK: wrote {doc_index_path}")
    sys.exit(0)

if not doc_index_path.exists():
    print(f"FAIL: missing {doc_index_path}")
    print("Run: bash scripts/sync-doc-index.sh --write")
    sys.exit(1)

with doc_index_path.open(encoding="utf-8") as f:
    current = json.load(f)

# Ignore 'updated' field in check mode to avoid daily drift noise.
current_no_date = dict(current)
current_no_date["updated"] = generated["updated"]

if current_no_date != generated:
    print("FAIL: DOC_INDEX.json is out of sync")
    print("Run: bash scripts/sync-doc-index.sh --write")
    sys.exit(1)

print("OK: DOC_INDEX.json is in sync")
PY
