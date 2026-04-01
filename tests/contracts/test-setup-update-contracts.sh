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

finish_tests
