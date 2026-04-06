#!/usr/bin/env bash
# tests/contracts/test-setup-update-contracts.sh -- validate SETUP.md and UPDATE.md structural contracts.
# Run: bash tests/contracts/test-setup-update-contracts.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

SETUP="$REPO_ROOT/SETUP.md"
UPDATE="$REPO_ROOT/UPDATE.md"
MANIFESTS="$REPO_ROOT/template/setup/manifests.md"

echo "=== SETUP.md and UPDATE.md contract checks ==="
echo ""

# ──────────────────────────────────────────────────────────────
echo "1. SETUP.md contains all required sections"
# ──────────────────────────────────────────────────────────────

for section in \
  "## § 0 — Pre-flight" \
  "### § 0a —" \
  "### § 0b —" \
  "### § 0d —" \
  "#### § 0e —" \
  "## § 1 — Stack discovery" \
  "## § 2 — Populate" \
  "## § 2.4 —" \
  "## § 2.5 —" \
  "## § 2.8 —" \
  "## § 2.11a —" \
  "## § 2.12 —" \
  "## § 2.13 —" \
  "## § 3 —" \
  "## § 5 —"; do
  assert_file_contains "SETUP.md has section: $section" "$SETUP" "$section"
done
echo ""

# ──────────────────────────────────────────────────────────────
echo "2. UPDATE.md contains all required sections"
# ──────────────────────────────────────────────────────────────

for section in \
  "## Pre-flight Report" \
  "## Pre-write Backup" \
  "### U — Update all" \
  "### S — Skip" \
  "### C — Customise" \
  "## Post-update steps" \
    "## Factory restore" \
    "### F1 —" \
    "### F2 —" \
    "### F3 —" \
    "### F4 —" \
        "### F5 —" \
  "## Restore from backup" \
  "### R1 —" \
  "#### R2 —" \
  "#### R3 —" \
  "#### R4 —" \
  "#### R5 —" \
  "#### R6 —" \
  "## Applicability guardrails" \
  "## Force check"; do
  assert_file_contains "UPDATE.md has section: $section" "$UPDATE" "$section"
done
echo ""

# ──────────────────────────────────────────────────────────────
echo "3. SETUP.md ask_questions blocks have required fields"
# ──────────────────────────────────────────────────────────────

assert_python "SETUP.md ask_questions blocks are well-formed" '
text = (root / "SETUP.md").read_text(encoding="utf-8")
blocks = re.findall(r"```ask_questions\n(.*?)```", text, re.DOTALL)
if len(blocks) == 0:
    raise SystemExit("no ask_questions blocks found in SETUP.md")

for i, block in enumerate(blocks):
    if "header:" not in block:
        raise SystemExit(f"SETUP.md ask_questions block {i+1} missing header:")
    if "question:" not in block:
        raise SystemExit(f"SETUP.md ask_questions block {i+1} missing question:")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "4. UPDATE.md ask_questions blocks have required fields"
# ──────────────────────────────────────────────────────────────

assert_python "UPDATE.md ask_questions blocks are well-formed" '
text = (root / "UPDATE.md").read_text(encoding="utf-8")
blocks = re.findall(r"```ask_questions\n(.*?)```", text, re.DOTALL)
if len(blocks) == 0:
    raise SystemExit("no ask_questions blocks found in UPDATE.md")

for i, block in enumerate(blocks):
    if "header:" not in block:
        raise SystemExit(f"UPDATE.md ask_questions block {i+1} missing header:")
    if "question:" not in block:
        raise SystemExit(f"UPDATE.md ask_questions block {i+1} missing question:")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "5. ask_questions blocks with options have valid option structure"
# ──────────────────────────────────────────────────────────────

assert_python "ask_questions option blocks have label fields" '
for fname in ("SETUP.md", "UPDATE.md"):
    text = (root / fname).read_text(encoding="utf-8")
    blocks = re.findall(r"```ask_questions\n(.*?)```", text, re.DOTALL)
    for i, block in enumerate(blocks):
        if "options:" in block:
            labels = re.findall(r"- label:", block)
            if len(labels) == 0:
                raise SystemExit(f"{fname} block {i+1} has options: but no - label: entries")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "6. Minimum ask_questions block counts"
# ──────────────────────────────────────────────────────────────

assert_python "SETUP.md has >= 7 ask_questions blocks" '
text = (root / "SETUP.md").read_text(encoding="utf-8")
count = len(re.findall(r"```ask_questions", text))
if count < 7:
    raise SystemExit(f"SETUP.md has only {count} ask_questions blocks, expected >= 7")
'

assert_python "UPDATE.md has >= 6 ask_questions blocks" '
text = (root / "UPDATE.md").read_text(encoding="utf-8")
count = len(re.findall(r"```ask_questions", text))
if count < 6:
    raise SystemExit(f"UPDATE.md has only {count} ask_questions blocks, expected >= 6")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "7. Every ask_questions block has a Fallback note nearby"
# ──────────────────────────────────────────────────────────────

assert_python "ask_questions blocks have fallback notes" '
for fname in ("SETUP.md", "UPDATE.md"):
    text = (root / fname).read_text(encoding="utf-8")
    # Split on ask_questions fence markers
    parts = text.split("```ask_questions")
    # Skip the first part (before any block)
    for i, part in enumerate(parts[1:], start=1):
        # Find the closing fence, then check the next ~500 chars for fallback
        close = part.find("```")
        if close == -1:
            raise SystemExit(f"{fname} ask_questions block {i} has no closing fence")
        after_block = part[close:close+500]
        if "Fallback" not in after_block and "fallback" not in after_block and "unavailable" not in after_block:
            raise SystemExit(f"{fname} ask_questions block {i} missing fallback note within 500 chars after closing fence")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "8. Setup agent lists askQuestions in tools"
# ──────────────────────────────────────────────────────────────

# shellcheck disable=SC2043
for agent in setup; do
  assert_file_contains "$agent.agent.md has askQuestions tool" \
    "$REPO_ROOT/.github/agents/${agent}.agent.md" "askQuestions"
done
echo ""

# ──────────────────────────────────────────────────────────────
echo "9. Agent files mention ask_questions usage directive"
# ──────────────────────────────────────────────────────────────

# shellcheck disable=SC2043
for agent in setup; do
  assert_file_contains "$agent.agent.md has ask_questions usage directive" \
    "$REPO_ROOT/.github/agents/${agent}.agent.md" "ask_questions.*for.*ALL.*user-facing"
done
echo ""

# ──────────────────────────────────────────────────────────────
echo "10. SETUP.md fetch URLs are well-formed"
# ──────────────────────────────────────────────────────────────

assert_python "SETUP.md fetch URLs point to template repo" '
text = (root / "SETUP.md").read_text(encoding="utf-8")
urls = re.findall(r"https://raw\.githubusercontent\.com/asafelobotomy/copilot-instructions-template/[^\s`\"\)]+", text)
if len(urls) < 10:
    raise SystemExit(f"expected >= 10 fetch URLs in SETUP.md, found {len(urls)}")
for url in urls:
    if url.endswith((".md", ".json", ".yml", ".sh", ".ps1")):
        continue
    if url.endswith("/"):
        continue
    # URLs ending in file-like extensions are valid
    raise SystemExit(f"URL has unexpected ending: {url}")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "11. UPDATE.md fetch URLs are well-formed"
# ──────────────────────────────────────────────────────────────

assert_python "UPDATE.md fetch URLs point to template repo" '
text = (root / "UPDATE.md").read_text(encoding="utf-8")
urls = re.findall(r"https://raw\.githubusercontent\.com/asafelobotomy/copilot-instructions-template/[^\s`\"\)]+", text)
if len(urls) < 3:
    raise SystemExit(f"expected >= 3 fetch URLs in UPDATE.md, found {len(urls)}")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "12. SETUP.md references all conditional question IDs"
# ──────────────────────────────────────────────────────────────

assert_python "SETUP.md references S1-S5 and A6-A17 question IDs" '
text = (root / "SETUP.md").read_text(encoding="utf-8")
for qid in ["S1", "S2", "S3", "S4", "S5", "A6", "A7", "A8", "A9",
            "A10", "A11", "A12", "A13", "A14", "A15", "A16", "A17"]:
    if qid not in text:
        raise SystemExit(f"SETUP.md missing reference to question ID {qid}")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "13. UPDATE.md guardrails table contains all required items"
# ──────────────────────────────────────────────────────────────

for guardrail in \
  "Placeholder leakage" \
  "§10 collision" \
  "Migrated content" \
  "User-added content" \
  "User preference conflict" \
  "Metric threshold conflict"; do
  assert_file_contains "UPDATE.md guardrail: $guardrail" "$UPDATE" "$guardrail"
done
echo ""

# ──────────────────────────────────────────────────────────────
echo "14. UPDATE.md guardrail conflicts use ask_questions"
# ──────────────────────────────────────────────────────────────

assert_file_contains "user preference conflict uses ask_questions" \
  "$UPDATE" "User preference conflict.*ask_questions"

assert_file_contains "metric threshold conflict uses ask_questions" \
  "$UPDATE" "Metric threshold conflict.*ask_questions"
echo ""

# ──────────────────────────────────────────────────────────────
echo "15. Template copilot-instructions.md has >= 3 placeholder tokens"
# ──────────────────────────────────────────────────────────────

assert_python "template has >= 3 placeholder tokens" '
text = (root / "template/copilot-instructions.md").read_text(encoding="utf-8")
tokens = re.findall(r"\{\{[A-Z_]+\}\}", text)
unique = set(tokens)
if len(unique) < 3:
    raise SystemExit(f"template/copilot-instructions.md has only {len(unique)} unique placeholder tokens, expected >= 3")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "16. SETUP.md placeholder table matches template tokens"
# ──────────────────────────────────────────────────────────────

assert_python "SETUP.md placeholder table covers core template tokens" '
template_text = (root / "template/copilot-instructions.md").read_text(encoding="utf-8")
template_tokens = set(re.findall(r"\{\{([A-Z_]+)\}\}", template_text))

setup_text = (root / "SETUP.md").read_text(encoding="utf-8")
setup_tokens = set(re.findall(r"\{\{([A-Z_]+)\}\}", setup_text))

# Tokens that are derived from interview answers (not auto-detected in §1)
# and may not appear literally in SETUP.md
derived_tokens = {
    "DEP_BUDGET", "DEP_BUDGET_WARN",
    "LOC_WARN_THRESHOLD", "LOC_HIGH_THRESHOLD",
    "SUBAGENT_MAX_DEPTH", "TRUST_OVERRIDES",
    "PREFERRED_SERIALISATION", "SKILL_SEARCH_PREFERENCE",
    "FLOW_DESCRIPTION", "MCP_CUSTOM_SERVERS", "MCP_STACK_SERVERS",
    "INTEGRATION_TEST_ENV_VAR",
}

# Core tokens (§1 detection table) must appear in SETUP.md
core_tokens = template_tokens - derived_tokens
missing = core_tokens - setup_tokens
if missing:
    raise SystemExit(f"SETUP.md does not mention these core template tokens: {sorted(missing)}")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "17. Setup companion manifests include commit-style assets"
# ──────────────────────────────────────────────────────────────

assert_file_contains "manifests.md includes onboard commit style prompt" \
    "$MANIFESTS" "onboard-commit-style.prompt.md"

assert_file_contains "manifests.md includes commit-style workspace stub" \
    "$MANIFESTS" "template/workspace/commit-style.md"

assert_file_contains "manifests.md fetches python hook support files" \
    "$MANIFESTS" "hookScripts.python"

assert_file_contains "manifests.md discovers agent JSON support files" \
    "$MANIFESTS" "\\.github/agents/\\*\\.json"

assert_file_contains "manifests.md documents agent support fallback inventory" \
    "$MANIFESTS" "agentSupportFiles"
echo ""

# ──────────────────────────────────────────────────────────────
echo "18. Hook companion inventories include JSON and Python support files"
# ──────────────────────────────────────────────────────────────

assert_file_contains "manifests.md fetches JSON hook support files" \
    "$MANIFESTS" "hookScripts.json"

assert_file_contains "manifests.md file manifest tracks hook JSON helpers" \
    "$MANIFESTS" "\\.github/hooks/scripts/\\*\\.json"

assert_file_contains "manifests.md file manifest tracks hook Python helpers" \
    "$MANIFESTS" "\\.github/hooks/scripts/\\*\\.py"

assert_file_contains "manifests.md file manifest tracks agent JSON support files" \
    "$MANIFESTS" "\\.github/agents/\\*\\.json"

assert_file_contains "UPDATE.md file manifest tracks hook JSON helpers" \
    "$UPDATE" "\\.github/hooks/scripts/\\*\\.json"

assert_file_contains "UPDATE.md file manifest tracks hook Python helpers" \
    "$UPDATE" "\\.github/hooks/scripts/\\*\\.py"

assert_file_contains "UPDATE.md file manifest tracks agent JSON support files" \
    "$UPDATE" "\\.github/agents/\\*\\.json"
echo ""

# ──────────────────────────────────────────────────────────────
echo "19. VS Code and starter-kit companion manifests are tracked"
# ──────────────────────────────────────────────────────────────

assert_file_contains "UPDATE.md maps template VS Code settings" \
    "$UPDATE" "template/vscode/settings\.json"

assert_file_contains "UPDATE.md maps agent JSON support files" \
    "$UPDATE" "\\.github/agents/\\*\\.json"

assert_file_contains "UPDATE.md keeps VS Code settings conditional" \
    "$UPDATE" "template/vscode/settings\.json.*only if the consumer already has this file from setup"

assert_file_contains "UPDATE.md maps template VS Code extensions" \
    "$UPDATE" "template/vscode/extensions\.json"

assert_file_contains "UPDATE.md keeps VS Code extensions conditional" \
    "$UPDATE" "template/vscode/extensions\.json.*only if the consumer already has this file from setup"

assert_file_contains "UPDATE.md maps template VS Code MCP config" \
    "$UPDATE" "template/vscode/mcp\.json"

assert_file_contains "manifests.md file manifest tracks starter-kit plugin manifests" \
    "$MANIFESTS" "\\.github/starter-kits/\\*/plugin\.json"

assert_file_contains "manifests.md file manifest tracks starter-kit skills" \
    "$MANIFESTS" "\\.github/starter-kits/\\*/skills/\\*/SKILL\.md"

assert_file_contains "manifests.md file manifest tracks starter-kit instructions" \
    "$MANIFESTS" "\\.github/starter-kits/\\*/instructions/\\*\.instructions\.md"

assert_file_contains "manifests.md file manifest tracks starter-kit prompts" \
    "$MANIFESTS" "\\.github/starter-kits/\\*/prompts/\\*\.prompt\.md"

assert_file_contains "manifests.md file manifest tracks VS Code settings" \
    "$MANIFESTS" "\\.vscode/settings\.json"

assert_file_contains "manifests.md file manifest tracks VS Code extensions" \
    "$MANIFESTS" "\\.vscode/extensions\.json"

assert_file_contains "manifests.md file manifest tracks VS Code MCP config" \
    "$MANIFESTS" "\\.vscode/mcp\.json"

assert_file_contains "manifests.md file manifest tracks CLAUDE.md" \
    "$MANIFESTS" "CLAUDE\.md"

assert_file_contains "UPDATE.md file manifest tracks starter-kit plugin manifests" \
    "$UPDATE" "\\.github/starter-kits/\\*/plugin\.json"

assert_file_contains "UPDATE.md file manifest tracks starter-kit skills" \
    "$UPDATE" "\\.github/starter-kits/\\*/skills/\\*/SKILL\.md"

assert_file_contains "UPDATE.md file manifest tracks starter-kit instructions" \
    "$UPDATE" "\\.github/starter-kits/\\*/instructions/\\*\.instructions\.md"

assert_file_contains "UPDATE.md file manifest tracks starter-kit prompts" \
    "$UPDATE" "\\.github/starter-kits/\\*/prompts/\\*\.prompt\.md"

assert_file_contains "UPDATE.md file manifest tracks VS Code settings" \
    "$UPDATE" "\\.vscode/settings\.json"

assert_file_contains "UPDATE.md file manifest tracks VS Code extensions" \
    "$UPDATE" "\\.vscode/extensions\.json"

assert_file_contains "UPDATE.md file manifest tracks VS Code MCP config" \
    "$UPDATE" "\\.vscode/mcp\.json"

assert_file_contains "UPDATE.md file manifest tracks CLAUDE.md" \
    "$UPDATE" "CLAUDE\.md"
echo ""

# ──────────────────────────────────────────────────────────────
echo "20. MCP sources keep the heartbeat server in parity"
# ──────────────────────────────────────────────────────────────

assert_python "template and manifest MCP configs stay semantically aligned" '
import copy
import re

def extract_block(markdown: str, heading: str) -> dict[str, object]:
    marker = markdown.find(heading)
    if marker == -1:
        raise SystemExit("missing heading in manifests.md: " + heading)
    fenced = re.search(r"```json\n(.*?)\n```", markdown[marker:], re.S)
    if fenced is None:
        raise SystemExit("missing JSON fence after heading: " + heading)
    return json.loads(fenced.group(1))

manifests_text = (root / "template/setup/manifests.md").read_text(encoding="utf-8")
sandboxed = extract_block(manifests_text, "### Sandboxed config")
unsandboxed = extract_block(manifests_text, "### Unsandboxed config")
template_mcp = json.loads((root / "template/vscode/mcp.json").read_text(encoding="utf-8"))

if sandboxed != template_mcp:
    raise SystemExit("Sandboxed manifests MCP config drifted from template/vscode/mcp.json")

expected_unsandboxed = copy.deepcopy(template_mcp)
expected_unsandboxed.pop("sandbox", None)
filesystem = expected_unsandboxed.get("servers", {}).get("filesystem", {})
if isinstance(filesystem, dict):
    filesystem.pop("sandboxEnabled", None)
    filesystem.pop("sandbox", None)

if unsandboxed != expected_unsandboxed:
    raise SystemExit("Unsandboxed manifests MCP config drifted from the template baseline")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "21. Workspace-index fallback is available before agent and skill discovery"
# ──────────────────────────────────────────────────────────────

assert_python "SETUP.md prefetches workspace-index before §2.5" '
text = (root / "SETUP.md").read_text(encoding="utf-8")
workspace_index_url = "https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/workspace/workspace-index.json"
prefetch_pos = text.find(workspace_index_url)
agents_pos = text.find("## § 2.5 — Write model-pinned agent files")
skills_pos = text.find("## § 2.6 — Scaffold skill library")
if prefetch_pos == -1:
    raise SystemExit("workspace-index prefetch URL missing from SETUP.md")
if agents_pos == -1 or skills_pos == -1:
    raise SystemExit("agent or skill section missing from SETUP.md")
if not (prefetch_pos < agents_pos < skills_pos):
    raise SystemExit(f"prefetch_pos={prefetch_pos} agents_pos={agents_pos} skills_pos={skills_pos}")
'

assert_file_contains "manifests.md documents SETUP §2 prefetch for agent fallback" \
    "$MANIFESTS" "prefetched by SETUP\.md §2"

assert_file_not_contains "manifests.md no longer defers agent fallback to §3" \
    "$MANIFESTS" "fetched in § ?3"
echo ""

# ──────────────────────────────────────────────────────────────
echo "22. Tier counts in SETUP.md match the interview inventory"
# ──────────────────────────────────────────────────────────────

assert_python "setup tier descriptions match current question totals" '
setup_text = (root / "SETUP.md").read_text(encoding="utf-8")
interview_text = (root / "template/setup/interview.md").read_text(encoding="utf-8")

question_ids = set(re.findall(r"\*\*([SAE]\d+)\s+—", interview_text))

quick_ids = {qid for qid in question_ids if qid.startswith("S")}
standard_ids = quick_ids | {qid for qid in question_ids if qid.startswith("A")}
full_ids = standard_ids | {qid for qid in question_ids if qid.startswith("E")}

expected_descriptions = {
    "Q — Quick": f"{len(quick_ids)} questions (S1-S5), ~3 min",
    "S — Standard": f"{len(standard_ids)} questions (S1-S5 + A6-A17), ~6 min",
    "F — Full": f"{len(full_ids)} questions (S1-S5 + A6-A17 + E16-E18, E20-E24), ~10 min",
}

for label, description in expected_descriptions.items():
    if label not in setup_text:
        raise SystemExit(f"missing tier label in SETUP.md: {label}")
    if description not in setup_text:
        raise SystemExit(f"missing or stale tier description in SETUP.md: {description}")
'
echo ""

# ──────────────────────────────────────────────────────────────
echo "23. Factory restore is a full backup-purge-reinstall flow"
# ──────────────────────────────────────────────────────────────

assert_file_contains "Factory restore backs up VS Code MCP config" \
    "$UPDATE" "\\.vscode/mcp\.json"

assert_file_contains "Factory restore backs up VS Code settings" \
    "$UPDATE" "\\.vscode/settings\.json"

assert_file_contains "Factory restore backs up VS Code extensions" \
    "$UPDATE" "\\.vscode/extensions\.json"

assert_file_contains "Factory restore backs up CHANGELOG.md" \
    "$UPDATE" "CHANGELOG\.md"

assert_file_contains "Factory restore writes BACKUP-MANIFEST.md" \
    "$UPDATE" "BACKUP-MANIFEST\.md"

assert_file_contains "Factory restore removes managed surfaces before reinstall" \
    "$UPDATE" "remove every existing managed surface"

assert_file_contains "Factory restore ignores current repo instructions" \
    "$UPDATE" "Explicitly disregard current repo instructions"

assert_file_contains "SETUP recovery mode forbids reading old managed files" \
    "$SETUP" "Do not read, merge, preserve, or rely on current .*copilot-instructions\\.md"
echo ""

# ──────────────────────────────────────────────────────────────
echo "24. Restore from backup supports factory-restore snapshots"
# ──────────────────────────────────────────────────────────────

assert_file_contains "Restore flow scans pre-factory-restore backups" \
    "$UPDATE" "pre-factory-restore-\\*"

assert_file_contains "Restore flow uses backup manifests to restore managed surfaces" \
    "$UPDATE" "Restore the managed surfaces recorded in .*BACKUP-MANIFEST\\.md"
echo ""

# ──────────────────────────────────────────────────────────────
echo "25. UPDATE.md defines a supported in-place update floor"
# ──────────────────────────────────────────────────────────────

assert_file_contains "UPDATE.md requires v3.4.0 or newer for in-place updates" \
    "$UPDATE" 'tagged installed version `v3\.4\.0` or newer'

assert_file_contains "UPDATE.md requires section-fingerprints for supported updates" \
    "$UPDATE" "section-fingerprints"

assert_file_contains "UPDATE.md requires file-manifest for supported updates" \
    "$UPDATE" "file-manifest"

assert_file_contains "UPDATE.md directs unsupported installs to Factory restore" \
    "$UPDATE" "direct the user to \*\*Factory restore\*\*"

assert_file_not_contains "UPDATE.md no longer fetches MIGRATION.archive for supported updates" \
    "$UPDATE" "MIGRATION\.archive\.md"

assert_file_not_contains "UPDATE.md no longer documents the legacy heuristic merge path" \
    "$UPDATE" "Legacy fallback"
echo ""

finish_tests
