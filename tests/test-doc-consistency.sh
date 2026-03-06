#!/usr/bin/env bash
# tests/test-doc-consistency.sh — documentation drift guardrails
# Run: bash tests/test-doc-consistency.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

PASS=0; FAIL=0
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)

assert_true() {
  local desc="$1" cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    ((FAIL++))
  fi
}

assert_eq() {
  local desc="$1" actual="$2" expected="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc (expected '$expected', got '$actual')"
    ((FAIL++))
  fi
}

assert_absent() {
  local desc="$1" file="$2" pattern="$3"
  if grep -q "$pattern" "$file"; then
    echo "  FAIL: $desc (found pattern '$pattern' in $file)"
    ((FAIL++))
  else
    echo "  PASS: $desc"
    ((PASS++))
  fi
}

echo "=== Documentation consistency checks ==="
echo ""

# 1) Skill inventory counts must match actual files.
echo "1. Skill inventory counts"
actual_repo_skills=$(find "$REPO_ROOT/.github/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
actual_template_skills=$(find "$REPO_ROOT/template/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
assert_eq "repo skill file count" "$actual_repo_skills" "13"
assert_eq "template skill file count" "$actual_template_skills" "13"
assert_true "README says thirteen starter skills" "grep -q 'Thirteen starter skills' '$REPO_ROOT/README.md'"
assert_true "SETUP-GUIDE says thirteen starter skills" "grep -q 'Thirteen starter skills' '$REPO_ROOT/docs/SETUP-GUIDE.md'"
assert_true "SKILLS-GUIDE says thirteen skills" "grep -q 'Thirteen skills are scaffolded' '$REPO_ROOT/docs/SKILLS-GUIDE.md'"
assert_true "AGENTS says thirteen starter skills" "grep -q '13 starter skills' '$REPO_ROOT/AGENTS.md'"
echo ""

# 2) Known stale phrase should not return in core docs.
echo "2. Stale phrase prevention"
assert_absent "AGENTS.md no Playwright-only webapp-testing description" "$REPO_ROOT/AGENTS.md" "Playwright-based web app testing"
assert_true "AGENTS.md advertises thirteen repo skills" "grep -q 'Thirteen repo skills' '$REPO_ROOT/AGENTS.md'"
echo ""

# 3) Memory server removal consistency in always-on lists.
echo "3. Always-on MCP consistency"
assert_absent "README no legacy always-on memory list" "$REPO_ROOT/README.md" "filesystem, memory, git"
assert_absent "SETUP-GUIDE no legacy always-on memory list" "$REPO_ROOT/docs/SETUP-GUIDE.md" "filesystem, memory, git"
assert_absent "INSTRUCTIONS-GUIDE no legacy always-on memory list" "$REPO_ROOT/docs/INSTRUCTIONS-GUIDE.md" "filesystem, memory, git"
assert_true "SETUP E22 option shows filesystem+git" "grep -q 'Always-on only (filesystem, git)' '$REPO_ROOT/SETUP.md'"
echo ""

# 4) Machine-critical headings in protocol docs must exist.
echo "4. Machine-critical heading guardrails"
assert_true "AGENTS has Remote Bootstrap Sequence" "grep -q '^## Remote Bootstrap Sequence' '$REPO_ROOT/AGENTS.md'"
assert_true "AGENTS has Remote Update Sequence" "grep -q '^## Remote Update Sequence' '$REPO_ROOT/AGENTS.md'"
assert_true "SETUP has section 2.6 skill scaffold" "grep -q '^## § 2.6 — Scaffold skill library' '$REPO_ROOT/SETUP.md'"
assert_true "UPDATE has Pre-flight Sequence" "grep -q '^## Pre-flight Sequence' '$REPO_ROOT/UPDATE.md'"
assert_true "copilot-instructions has Section 12" "grep -q '^## §12 — Skill Protocol' '$REPO_ROOT/.github/copilot-instructions.md'"
echo ""

# 5) Newly added skills should be discoverable in summary docs.
echo "5. Skill discoverability in summary docs"
for skill in tool-protocol skill-management mcp-management plugin-management extension-review test-coverage-review; do
  assert_true "llms lists $skill" "grep -q '$skill' '$REPO_ROOT/llms.txt'"
  assert_true "DOC_INDEX lists $skill" "python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); s=set(d[\"skills\"][\"repo\"]); sys.exit(0 if sys.argv[2] in s else 1)' '$REPO_ROOT/.copilot/workspace/DOC_INDEX.json' '$skill'"
done
echo ""

# 6) Canonical inventory index must exist and stay coherent.
echo "6. Canonical inventory index"
assert_true "DOC_INDEX exists" "test -f '$REPO_ROOT/.copilot/workspace/DOC_INDEX.json'"
assert_true "README references DOC_INDEX" "grep -q 'DOC_INDEX.json' '$REPO_ROOT/README.md'"
assert_true "AGENTS file map references DOC_INDEX" "grep -q 'DOC_INDEX.json' '$REPO_ROOT/AGENTS.md'"
assert_true "DOC_INDEX is valid JSON" "python3 -c 'import json,sys; json.load(open(sys.argv[1]))' '$REPO_ROOT/.copilot/workspace/DOC_INDEX.json'"
assert_true "DOC_INDEX has required top-level keys" "python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); req={\"schemaVersion\",\"counts\",\"agents\",\"skills\",\"hookScripts\",\"guides\"}; sys.exit(0 if req.issubset(d.keys()) else 1)' '$REPO_ROOT/.copilot/workspace/DOC_INDEX.json'"
assert_true "DOC_INDEX counts match skill reality" "python3 -c 'import json,sys,pathlib; d=json.load(open(sys.argv[1])); root=pathlib.Path(sys.argv[2]); repo=len(list((root/\".github/skills\").glob(\"*/SKILL.md\"))); tpl=len(list((root/\"template/skills\").glob(\"*/SKILL.md\"))); sys.exit(0 if d[\"counts\"][\"skillsRepo\"]==repo and d[\"counts\"][\"skillsTemplate\"]==tpl else 1)' '$REPO_ROOT/.copilot/workspace/DOC_INDEX.json' '$REPO_ROOT'"
assert_true "DOC_INDEX sync script check passes" "bash '$REPO_ROOT/scripts/sync-doc-index.sh' --check"
echo ""

# 7) LLM-facing summary files must stay aligned.
echo "7. LLM context consistency"
assert_true "llms review model says GPT-5.4" "grep -Fq 'review.agent.md' '$REPO_ROOT/llms.txt' && grep -Fq 'GPT-5.4' '$REPO_ROOT/llms.txt'"
assert_true "llms links compact context pack" "grep -q 'llms-ctx.txt' '$REPO_ROOT/llms.txt'"
assert_true "llms links expanded context pack" "grep -q 'llms-ctx-full.txt' '$REPO_ROOT/llms.txt'"
assert_true "compact llms context exists" "test -f '$REPO_ROOT/llms-ctx.txt'"
assert_true "expanded llms context exists" "test -f '$REPO_ROOT/llms-ctx-full.txt'"
assert_true "llms context sync script check passes" "bash '$REPO_ROOT/scripts/sync-llms-context.sh' --check"
echo ""

# 8) Setup flow scaffolds canonical index for consumer projects.
echo "8. Setup scaffolds DOC_INDEX"
assert_true "template workspace DOC_INDEX stub exists" "test -f '$REPO_ROOT/template/workspace/DOC_INDEX.json'"
assert_true "SETUP workspace summary includes DOC_INDEX" "grep -q 'DOC_INDEX.json' '$REPO_ROOT/SETUP.md'"
assert_true "SETUP fetch table includes workspace DOC_INDEX source" "grep -q 'template/workspace/DOC_INDEX.json' '$REPO_ROOT/SETUP.md'"
assert_true "SETUP-GUIDE Step 3 includes DOC_INDEX" "grep -q 'DOC_INDEX.json' '$REPO_ROOT/docs/SETUP-GUIDE.md'"
echo ""

# 9) Preference interview docs must reflect derived global autonomy.
echo "9. Preference interview consistency"
assert_true "README says 5-23 questions" "grep -q '5-23 questions' '$REPO_ROOT/README.md'"
assert_true "README Full tier says 23" "grep -Fq '| **Full** | 23 |' '$REPO_ROOT/README.md'"
assert_true "SETUP-GUIDE Full tier says 23 questions" "grep -q '23 questions' '$REPO_ROOT/docs/SETUP-GUIDE.md'"
assert_absent "SETUP-GUIDE no E19 autonomy ceiling row" "$REPO_ROOT/docs/SETUP-GUIDE.md" 'E19 — Autonomy ceiling'
assert_true "SETUP-GUIDE explains derived global autonomy" "grep -q 'Global autonomy row from S5' '$REPO_ROOT/docs/SETUP-GUIDE.md'"
assert_absent "SECURITY-GUIDE no stale E19 reference" "$REPO_ROOT/docs/SECURITY-GUIDE.md" 'E19'
echo ""

# 10) Metrics and MCP settings should match the current template contract.
echo "10. Metrics and MCP settings consistency"
assert_true "METRICS has extended header" "grep -q 'AI Accept Rate' '$REPO_ROOT/METRICS.md'"
assert_true "INSTRUCTIONS-GUIDE mentions DORA and AI fields" "grep -q 'DORA and AI-operational fields' '$REPO_ROOT/docs/INSTRUCTIONS-GUIDE.md'"
assert_absent "settings no removed MCP memory server" "$REPO_ROOT/.vscode/settings.json" 'mcp.json: memory'
assert_true "settings allow GPT-5.4 for MCP sampling" "grep -q 'copilot/gpt-5.4' '$REPO_ROOT/.vscode/settings.json'"
echo ""

echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
