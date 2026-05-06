#!/usr/bin/env bash
# tests/contracts/test-routing-manifest.sh -- routing manifest integrity and alignment checks
# Run: bash tests/contracts/test-routing-manifest.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -euo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"

MANIFEST="$REPO_ROOT/agents/routing-manifest.json"
AGENTS_DIR="$REPO_ROOT/agents"
AGENTS_MD="$REPO_ROOT/AGENTS.md"

echo "=== Routing manifest integrity and alignment checks ==="
echo ""

# ── 1. Manifest is valid JSON ─────────────────────────────────────────────────
echo "1. routing-manifest.json is valid JSON"
manifest_content=$(cat "$MANIFEST")
assert_valid_json "routing-manifest.json is valid JSON" "$manifest_content"
echo ""

# ── 2. Required top-level keys ────────────────────────────────────────────────
echo "2. routing-manifest.json has required top-level keys"
assert_python "manifest has version and agents keys" '
import json
m = json.loads((root / "agents/routing-manifest.json").read_text())
for key in ("version", "agents", "default_cooldown_seconds"):
    if key not in m:
        raise SystemExit(f"missing top-level key: {key}")
if not isinstance(m["agents"], list) or len(m["agents"]) == 0:
    raise SystemExit("agents must be a non-empty list")
'
echo ""

# ── 3. All agent files have a routing entry ───────────────────────────────────
echo "3. Every agents/*.agent.md file has a routing-manifest entry"
assert_python "every agent file maps to a routing manifest entry" '
import json
manifest_names = {a["name"].lower() for a in json.loads(
    (root / "agents/routing-manifest.json").read_text()
)["agents"]}
for path in sorted((root / "agents").glob("*.agent.md")):
    # Extract name from frontmatter
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        continue
    end = text.find("\n---\n", 4)
    if end == -1:
        continue
    fm = text[4:end]
    import re
    m = re.search(r"^name:\s*(.+)$", fm, re.MULTILINE)
    if not m:
        raise SystemExit(f"missing name: in {path.name}")
    agent_name = m.group(1).strip().lower()
    if agent_name not in manifest_names:
        raise SystemExit(f"agent {path.name} (name={agent_name!r}) not in routing-manifest.json")
'
echo ""

# ── 4. Each routing entry has required fields ─────────────────────────────────
echo "4. Each routing manifest entry has required fields"
assert_python "all manifest entries have required fields" '
import json
agents = json.loads((root / "agents/routing-manifest.json").read_text())["agents"]
required_fields = ["name", "summary", "route", "visibility", "prompt_patterns"]
for entry in agents:
    name = entry.get("name", "?")
    for field in required_fields:
        if field not in entry:
            raise SystemExit("agent " + repr(name) + " missing field: " + field)
    if entry["route"] not in ("active", "guarded", "disabled"):
        raise SystemExit("agent " + repr(name) + " has unknown route: " + repr(entry["route"]))
    if entry["visibility"] not in ("picker-visible", "internal", "hidden"):
        raise SystemExit("agent " + repr(name) + " has unknown visibility: " + repr(entry["visibility"]))
    if not isinstance(entry["prompt_patterns"], list) or len(entry["prompt_patterns"]) == 0:
        raise SystemExit("agent " + repr(name) + " has empty prompt_patterns")
'
echo ""

# ── 5. Prompt patterns are valid regex ────────────────────────────────────────
echo "5. All prompt_patterns compile as valid regex"
assert_python "all routing manifest prompt_patterns are valid regex" '
import json
import re as RE
agents = json.loads((root / "agents/routing-manifest.json").read_text())["agents"]
for entry in agents:
    name = entry.get("name", "?")
    for pattern in entry.get("prompt_patterns", []):
        try:
            RE.compile(pattern)
        except RE.error as e:
            raise SystemExit("agent " + repr(name) + " invalid regex " + repr(pattern) + ": " + str(e))
    for pattern in entry.get("suppress_patterns", []):
        try:
            RE.compile(pattern)
        except RE.error as e:
            raise SystemExit("agent " + repr(name) + " invalid suppress regex " + repr(pattern) + ": " + str(e))
'
echo ""

# ── 6. All picker-visible agents appear in AGENTS.md trigger table ────────────
echo "6. All picker-visible agents appear in AGENTS.md trigger table"
assert_python "picker-visible agents are documented in AGENTS.md" '
import json
agents = json.loads((root / "agents/routing-manifest.json").read_text())["agents"]
agents_md = (root / "AGENTS.md").read_text(encoding="utf-8").lower()
for entry in agents:
    if entry.get("visibility") == "picker-visible":
        name = entry["name"]
        # Check agent name OR first summary word appears in AGENTS.md
        # (Fast agent is documented as "Quick question / tiny edit", not by name)
        first_summary_word = entry.get("summary", "").split()[0].lower() if entry.get("summary") else ""
        if name.lower() not in agents_md and (not first_summary_word or first_summary_word not in agents_md):
            raise SystemExit("picker-visible agent " + repr(name) + " not documented in AGENTS.md")
'
echo ""

# ── 7. No duplicate agent names ───────────────────────────────────────────────
echo "7. routing-manifest.json has no duplicate agent names"
assert_python "no duplicate agent names in routing-manifest.json" '
import json
agents = json.loads((root / "agents/routing-manifest.json").read_text())["agents"]
names = [a["name"] for a in agents]
if len(names) != len(set(names)):
    from collections import Counter
    dupes = [n for n, c in Counter(names).items() if c > 1]
    raise SystemExit(f"duplicate agent names: {dupes}")
'
echo ""

# ── 8. Routing count matches agent file count ──────────────────────────────────
echo "8. routing-manifest.json entry count matches agents/*.agent.md count"
assert_python "manifest entry count matches agent file count" '
import json
agent_files = list((root / "agents").glob("*.agent.md"))
manifest_agents = json.loads((root / "agents/routing-manifest.json").read_text())["agents"]
if len(agent_files) != len(manifest_agents):
    raise SystemExit(
        f"agent file count ({len(agent_files)}) != manifest entry count ({len(manifest_agents)})"
    )
'
echo ""

# ── 9. Guarded routes require min_prompt_confidence ──────────────────────────
echo "9. Guarded routes have min_prompt_confidence and min_behavior_confidence"
assert_python "guarded routes declare confidence thresholds" '
import json
agents = json.loads((root / "agents/routing-manifest.json").read_text())["agents"]
for entry in agents:
    if entry["route"] == "guarded":
        name = entry.get("name", "?")
        for field in ("min_prompt_confidence", "min_behavior_confidence"):
            if field not in entry:
                raise SystemExit("guarded agent " + repr(name) + " missing " + repr(field))
'
echo ""

# ── 10. Cleaner routing covers hygiene vocabulary ─────────────────────────────
echo "10. Cleaner routing covers required hygiene vocabulary"
assert_python "Cleaner prompt_patterns include stale-artefact hygiene terms" '
import json
import re as RE
agents = json.loads((root / "agents/routing-manifest.json").read_text())["agents"]
cleaner = next((a for a in agents if a["name"] == "Cleaner"), None)
if cleaner is None:
    raise SystemExit("Cleaner agent not found in routing-manifest.json")
patterns_text = " ".join(cleaner["prompt_patterns"])
required_terms = ["stale", "artefact", "archive", "cache", "clean"]
for term in required_terms:
    if term not in patterns_text:
        raise SystemExit(f"Cleaner routing missing hygiene term: {term!r}")
'
echo ""

finish_tests
