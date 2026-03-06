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
assert_eq "repo skill file count" "$actual_repo_skills" "11"
assert_eq "template skill file count" "$actual_template_skills" "11"
assert_true "README says eleven starter skills" "grep -q 'Eleven starter skills' '$REPO_ROOT/README.md'"
assert_true "SETUP-GUIDE says eleven starter skills" "grep -q 'Eleven starter skills' '$REPO_ROOT/docs/SETUP-GUIDE.md'"
assert_true "SKILLS-GUIDE says eleven skills" "grep -q 'Eleven skills are scaffolded' '$REPO_ROOT/docs/SKILLS-GUIDE.md'"
echo ""

# 2) Known stale phrase should not return in core docs.
echo "2. Stale phrase prevention"
assert_absent "AGENTS.md no Playwright-only webapp-testing description" "$REPO_ROOT/AGENTS.md" "Playwright-based web app testing"
assert_true "AGENTS.md uses dual-path webapp-testing wording" "grep -q 'Browser-tools + Playwright web app testing' '$REPO_ROOT/AGENTS.md'"
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
for skill in tool-protocol skill-management mcp-management plugin-management; do
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

# 7) Setup flow scaffolds canonical index for consumer projects.
echo "7. Setup scaffolds DOC_INDEX"
assert_true "template workspace DOC_INDEX stub exists" "test -f '$REPO_ROOT/template/workspace/DOC_INDEX.json'"
assert_true "SETUP workspace summary includes DOC_INDEX" "grep -q 'DOC_INDEX.json' '$REPO_ROOT/SETUP.md'"
assert_true "SETUP fetch table includes workspace DOC_INDEX source" "grep -q 'template/workspace/DOC_INDEX.json' '$REPO_ROOT/SETUP.md'"
assert_true "SETUP-GUIDE Step 3 includes DOC_INDEX" "grep -q 'DOC_INDEX.json' '$REPO_ROOT/docs/SETUP-GUIDE.md'"
echo ""

echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
