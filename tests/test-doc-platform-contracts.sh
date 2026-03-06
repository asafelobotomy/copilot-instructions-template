#!/usr/bin/env bash
# tests/test-doc-platform-contracts.sh -- verify generated-context and platform documentation contracts.
# Run: bash tests/test-doc-platform-contracts.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"

echo "=== Documentation platform contract checks ==="
echo ""

echo "1. Canonical inventory index exists and stays coherent"
assert_python "DOC_INDEX exists and has required top-level keys" '
import json

path = root / ".copilot/workspace/DOC_INDEX.json"
if not path.exists():
    raise SystemExit("missing DOC_INDEX.json")
data = json.loads(path.read_text(encoding="utf-8"))
required = {"schemaVersion", "counts", "agents", "skills", "hookScripts", "guides"}
if not required.issubset(data.keys()):
    raise SystemExit(sorted(required - set(data.keys())))
'
assert_file_contains "README references DOC_INDEX" "$REPO_ROOT/README.md" 'DOC_INDEX\.json'
assert_file_contains "AGENTS file map references DOC_INDEX" "$REPO_ROOT/AGENTS.md" 'DOC_INDEX\.json'
assert_python "DOC_INDEX counts match skill reality" '
import json

data = json.loads((root / ".copilot/workspace/DOC_INDEX.json").read_text(encoding="utf-8"))
repo_count = len(list((root / ".github/skills").glob("*/SKILL.md")))
template_count = len(list((root / "template/skills").glob("*/SKILL.md")))
if data["counts"]["skillsRepo"] != repo_count or data["counts"]["skillsTemplate"] != template_count:
    raise SystemExit((data["counts"], repo_count, template_count))
'
if bash "$REPO_ROOT/scripts/sync-doc-index.sh" --check >/dev/null 2>&1; then
  pass_note "DOC_INDEX sync script check passes"
else
  fail_note "DOC_INDEX sync script check passes"
fi
echo ""

echo "2. LLM-facing summaries stay aligned"
assert_file_contains "llms review model says GPT-5.4" "$REPO_ROOT/llms.txt" 'GPT-5\.4'
assert_file_contains "llms links compact context pack" "$REPO_ROOT/llms.txt" 'llms-ctx\.txt'
assert_file_contains "llms links expanded context pack" "$REPO_ROOT/llms.txt" 'llms-ctx-full\.txt'
assert_python "compact and expanded llms context files exist" '
for rel in ("llms-ctx.txt", "llms-ctx-full.txt"):
    if not (root / rel).exists():
        raise SystemExit(rel)
'
if bash "$REPO_ROOT/scripts/sync-llms-context.sh" --check >/dev/null 2>&1; then
  pass_note "llms context sync script check passes"
else
  fail_note "llms context sync script check passes"
fi
echo ""

echo "3. Setup scaffolds the canonical metadata index"
assert_python "template workspace DOC_INDEX stub exists" '
if not (root / "template/workspace/DOC_INDEX.json").exists():
    raise SystemExit("template/workspace/DOC_INDEX.json")
'
assert_file_contains "SETUP workspace summary includes DOC_INDEX" "$REPO_ROOT/SETUP.md" 'DOC_INDEX\.json'
assert_file_contains "SETUP fetch table includes workspace DOC_INDEX source" "$REPO_ROOT/SETUP.md" 'template/workspace/DOC_INDEX\.json'
assert_file_contains "SETUP-GUIDE Step 3 includes DOC_INDEX" "$REPO_ROOT/docs/SETUP-GUIDE.md" 'DOC_INDEX\.json'
echo ""

echo "4. Preference interview docs reflect derived global autonomy"
assert_file_contains "README says 5-23 questions" "$REPO_ROOT/README.md" '5-23 questions'
assert_file_contains "README Full tier says 23" "$REPO_ROOT/README.md" '\| \*\*Full\*\* \| 23 \|'
assert_file_contains "SETUP-GUIDE Full tier says 23 questions" "$REPO_ROOT/docs/SETUP-GUIDE.md" '23 questions'
assert_file_not_contains "SETUP-GUIDE no E19 autonomy ceiling row" "$REPO_ROOT/docs/SETUP-GUIDE.md" 'E19 - Autonomy ceiling'
assert_file_contains "SETUP-GUIDE explains derived global autonomy" "$REPO_ROOT/docs/SETUP-GUIDE.md" 'Global autonomy row from S5'
assert_file_not_contains "SECURITY-GUIDE no stale E19 reference" "$REPO_ROOT/docs/SECURITY-GUIDE.md" 'E19'
echo ""

echo "5. Metrics schema and MCP settings match the current contract"
assert_file_contains "METRICS has extended header" "$REPO_ROOT/METRICS.md" 'AI Accept Rate'
assert_file_contains "INSTRUCTIONS-GUIDE mentions DORA and AI fields" "$REPO_ROOT/docs/INSTRUCTIONS-GUIDE.md" 'DORA and AI-operational fields'
assert_file_not_contains "settings no removed MCP memory server" "$REPO_ROOT/.vscode/settings.json" 'mcp\.json: memory'
assert_file_contains "settings allow GPT-5.4 for MCP sampling" "$REPO_ROOT/.vscode/settings.json" 'copilot/gpt-5\.4'
echo ""

echo "6. Canonical validation commands stay centralized"
assert_file_contains "instructions use run-all entrypoint" "$REPO_ROOT/.github/copilot-instructions.md" 'bash tests/run-all\.sh'
assert_file_contains "contributing uses run-all entrypoint" "$REPO_ROOT/CONTRIBUTING.md" 'bash tests/run-all\.sh'
assert_file_contains "workspace tools use run-all entrypoint" "$REPO_ROOT/.copilot/workspace/TOOLS.md" 'bash tests/run-all\.sh'
assert_file_not_contains "instructions no longer hardcode legacy inline chain" "$REPO_ROOT/.github/copilot-instructions.md" 'bash tests/test-hooks\.sh && bash tests/test-guard-destructive\.sh && bash tests/test-sync-version\.sh && bash tests/test-security-edge-cases\.sh'
echo ""

echo "7. Coverage reporting command stays discoverable"
assert_file_contains "llms.txt mentions coverage report" "$REPO_ROOT/llms.txt" 'bash scripts/report-script-coverage\.sh coverage'
assert_file_contains "compact llms context mentions coverage report" "$REPO_ROOT/llms-ctx.txt" 'bash scripts/report-script-coverage\.sh coverage'
assert_file_contains "expanded llms context mentions coverage report" "$REPO_ROOT/llms-ctx-full.txt" 'bash scripts/report-script-coverage\.sh coverage'
assert_file_contains "sync-llms generator mentions coverage report" "$REPO_ROOT/scripts/sync-llms-context.sh" 'bash scripts/report-script-coverage\.sh coverage'
echo ""

finish_tests