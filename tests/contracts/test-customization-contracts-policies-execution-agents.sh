# shellcheck shell=bash
echo "11. Agent allow-lists stay minimal and workflow-aligned"
assert_python "agent allow-lists match documented delegation policy" '
def parse_tools_or_agents(frontmatter, field):
    match = re.search(rf"^{field}:\s*\[(.*)\]\s*$", frontmatter, re.M)
    if not match:
        raise SystemExit(f"missing {field}: line")
    return {
        item.strip().replace(chr(39), "").replace(chr(34), "")
        for item in match.group(1).split(",")
        if item.strip()
    }

expected = {
    "audit.agent.md": {"Code", "Setup", "Researcher", "Extensions", "Organise", "Planner", "Cleaner"},
    "cleaner.agent.md": {"Code", "Audit", "Organise", "Docs", "Commit"},
    "coding.agent.md": {"Review", "Audit", "Researcher", "Explore", "Commit", "Organise", "Planner", "Docs", "Debugger", "Cleaner"},
    "commit.agent.md": {"Code", "Review", "Audit", "Debugger", "Organise", "Cleaner"},
    "debugger.agent.md": {"Code", "Researcher", "Audit", "Planner"},
    "docs.agent.md": {"Code", "Researcher", "Review", "Explore"},
    "explore.agent.md": {"Researcher"},
    "extensions.agent.md": {"Code", "Audit", "Organise", "Researcher"},
    "fast.agent.md": {"Code", "Explore", "Commit"},
    "organise.agent.md": {"Code", "Explore", "Docs"},
    "planner.agent.md": {"Code", "Explore", "Researcher", "Debugger", "Docs"},
    "researcher.agent.md": {"Code", "Audit", "Explore", "Docs", "Planner"},
    "review.agent.md": {"Code", "Audit", "Organise", "Docs", "Debugger", "Cleaner"},
    "setup.agent.md": {"Audit", "Extensions", "Organise", "Researcher"},
}

for name, expected_agents in expected.items():
    path = root / "agents" / name
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise SystemExit("missing frontmatter in " + name)
    end = text.find("\n---\n", 4)
    if end == -1:
        raise SystemExit("unterminated frontmatter in " + name)
    fm = text[4:end]
    found_agents = parse_tools_or_agents(fm, "agents")
    if found_agents != expected_agents:
        raise SystemExit(f"{name} expected agents={sorted(expected_agents)} found={sorted(found_agents)}")

checks = {
    "audit.agent.md": [
        "Use `Cleaner` when the remediation path is mainly stale artefact removal,",
        "Use `Extensions` when a finding is specifically about VS Code extension",
    ],
    "cleaner.agent.md": [
        "Start with a dry-run inventory.",
        "Tracked deletions always need explicit user approval.",
        "Use `Audit` when the candidate cleanup touches security-sensitive files,",
        "Use `Organise` when cleanup turns into file moves, path updates, or",
    ],
    "coding.agent.md": [
        "Use `Planner` when the request is large, ambiguous, or needs a scoped execution plan before implementation.",
        "Use `Debugger` when the main task is to diagnose a failure, regression, or unclear root cause before editing.",
        "Use `Docs` when the work is primarily documentation, migration guidance, or user-facing technical explanation rather than product behavior.",
        "Use `Explore` for read-only codebase inventory across multiple files",
        "Use `Researcher` when a task depends on current external documentation",
        "Use `Cleaner` when the task is primarily repo hygiene",
    ],
    "commit.agent.md": [
        "Use `Code` when preflight or review finds implementation work",
        "Use `Audit` when the user requests a deeper security or health check",
        "Use `Organise` when branch cleanup or file restructuring is needed",
        "Use `Cleaner` when stale caches, generated artefacts, archive debris,",
    ],
    "debugger.agent.md": [
        "Focus on reproduction, symptom isolation, root cause, and the smallest credible fix path.",
        "Use `Researcher` when the failure depends on current external docs, release notes, or API behavior.",
        "Use `Code` only after the diagnosis is specific enough to implement without guessing.",
    ],
    "docs.agent.md": [
        "Prefer documentation files, guides, prompts, instructions, and user-facing examples over code changes.",
        "Use `Researcher` when the docs depend on current external references or upstream behavior.",
        "Do not silently change runtime behavior while doing docs-only work.",
    ],
    "fast.agent.md": [
        "If the question expands beyond a single file but stays read-only, use",
        "If the user is asking to stage, commit, push, tag, or release changes, use",
        "suggest switching to the Code agent using the",
    ],
    "organise.agent.md": [
        "Use `Code` when the task expands from structural cleanup into semantic",
    ],
    "planner.agent.md": [
        "Stay read-only. Do not modify files.",
        "Use `Explore` when the task needs a broader read-only inventory before the plan is credible.",
        "Use `Researcher` when the plan depends on current external docs or version-specific behavior.",
    ],
    "researcher.agent.md": [
        "Use `Explore` when you need a broader read-only inventory of local callers,",
    ],
    "review.agent.md": [
        "Prefer `Cleaner` over general `Code` when a finding is mainly stale artefact,",
        "Use `Debugger` when a finding cannot be substantiated without isolating the underlying root cause first.",
        "Use `Docs` when the review outcome is primarily missing documentation, migration guidance, or user-facing explanation.",
    ],
    "setup.agent.md": [
        "Use `Extensions` when setup or update work shifts into VS Code extension",
    ],
}
for name, needles in checks.items():
    text = (root / "agents" / name).read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            raise SystemExit(name + " missing workflow guidance: " + needle)
'
echo ""

echo "11. Hidden specialist agents are not advertised in the public trigger table"
assert_python "AGENTS.md keeps delegation-first specialists out of direct trigger docs" '
text = (root / "AGENTS.md").read_text(encoding="utf-8")
normalized = " ".join(text.split())
required = [
    "direct consumer-facing trigger phrases",
    "Audit, Researcher, Extensions, and Organise",
    "hidden from direct invocation",
]
for needle in required:
    if " ".join(needle.split()) not in normalized:
        raise SystemExit("AGENTS.md missing hidden-agent note: " + needle)
for forbidden in [
    "| Health check |",
    "| Extensions (review/install/profile) |",
    "| Research (find/report/track) |",
    "| Security audit |",
]:
    if forbidden in text:
        raise SystemExit("AGENTS.md still advertises hidden specialist trigger row: " + forbidden)
'

assert_python "AGENTS.md keeps the Fast public trigger row" '
text = (root / "AGENTS.md").read_text(encoding="utf-8")
required = [
    "| Quick question / tiny edit |",
    "*\"Quick question\"*",
    "*\"What does this regex match?\"*",
    "*\"Fix the typo in ...\"*",
    "*\"Single-file edit\"*",
    "wc -l of ...?",
]
for needle in required:
    if needle not in text:
        raise SystemExit("AGENTS.md missing Fast public trigger phrase: " + needle)
'
echo ""

echo "12. Lightweight AI entry surfaces point to canonical sources"
assert_python "CLAUDE.md stays lean and llms.txt stays machine-readable" '
claude_text = (root / "CLAUDE.md").read_text(encoding="utf-8")
for needle in [
    ".github/copilot-instructions.md",
    "bash tests/run-all.sh",
    "## Canonical instructions",
    "targeted tests during iterative work",
    "once as the final full-suite gate",
]:
    if needle not in claude_text:
        raise SystemExit("CLAUDE.md missing canonical source pointer: " + needle)
for forbidden in ["## Rules", "## Coding conventions"]:
    if forbidden in claude_text:
        raise SystemExit("CLAUDE.md still duplicates policy section: " + forbidden)

llms_text = (root / "llms.txt").read_text(encoding="utf-8")
for needle in [
    "[.github/copilot-instructions.md](.github/copilot-instructions.md)",
    "[AGENTS.md](AGENTS.md)",
    "[MODELS.md](MODELS.md)",
    "[SETUP.md](SETUP.md)",
    "[starter-kits/REGISTRY.json](starter-kits/REGISTRY.json)",
    "[.copilot/workspace/operations/workspace-index.json](.copilot/workspace/operations/workspace-index.json)",
    "## Model strategy",
    "## Agents",
    "## Skills",
    "## Starter kits",
    "## Hook and runtime surfaces",
]:
    if needle not in llms_text:
        raise SystemExit("llms.txt missing canonical navigation link: " + needle)
for forbidden in ["## Route queries quickly", "## Canonical machine sources"]:
    if forbidden in llms_text:
        raise SystemExit("llms.txt still duplicates navigation section: " + forbidden)

for agent_path in sorted((root / "agents").glob("*.agent.md")):
    rel = agent_path.relative_to(root).as_posix()
    marker = f"[{rel}]({rel})"
    if marker not in llms_text:
        raise SystemExit("llms.txt missing agent catalog entry: " + rel)

for skill_path in sorted((root / "skills").glob("*/SKILL.md")):
    rel = skill_path.relative_to(root).as_posix()
    marker = f"[{rel}]({rel})"
    if marker not in llms_text:
        raise SystemExit("llms.txt missing skill catalog entry: " + rel)

for starter_kit_path in sorted((root / "starter-kits").glob("*/.claude-plugin/plugin.json")):
    rel = starter_kit_path.relative_to(root).as_posix()
    marker = f"[{rel}]({rel})"
    if marker not in llms_text:
        raise SystemExit("llms.txt missing starter-kit catalog entry: " + rel)

for rel in [
    "hooks/hooks.json",
    "template/hooks/copilot-hooks.json",
    "template/vscode/settings.json",
    "template/vscode/mcp.json",
    "CLAUDE.md",
]:
    marker = f"[{rel}]({rel})"
    if marker not in llms_text:
        raise SystemExit("llms.txt missing hook or runtime catalog entry: " + rel)

models_text = (root / "MODELS.md").read_text(encoding="utf-8")
for needle in [
    "llms.txt` includes a machine-readable repo catalog",
    "sync-models.sh` propagates only the",
    "primary-model and thinking-effort summary table within `llms.txt`",
]:
    if needle not in models_text:
        raise SystemExit("MODELS.md missing llms.txt catalog note: " + needle)
'
echo ""

echo "13. Consumer template CLAUDE surface stays lean and placeholder-safe"
assert_python "template/CLAUDE.md mirrors the canonical-source pattern with placeholders" '
template_claude_text = (root / "template/CLAUDE.md").read_text(encoding="utf-8")
for needle in [
    "## Canonical instructions",
    ".github/copilot-instructions.md",
    "{{TEST_COMMAND}}",
    "{{PROJECT_NAME}}",
    "{{LANGUAGE}}",
    "targeted tests during iterative work",
    "once as the final full-suite gate",
]:
    if needle not in template_claude_text:
        raise SystemExit("template/CLAUDE.md missing expected content: " + needle)
for forbidden in ["## Rules", "## Coding conventions"]:
    if forbidden in template_claude_text:
        raise SystemExit("template/CLAUDE.md still duplicates deprecated section: " + forbidden)
'
echo ""

echo "14. Test instructions, prompts, agents, and validation docs align with targeted-first execution"
assert_python "targeted-first policy is enforced across test-facing surfaces" '
checks = {
    ".github/instructions/tests.instructions.md": [
        "select-targeted-tests.sh <paths...>",
        "Run `bash tests/run-all.sh` once only when the full task is complete",
        "targeted failure required broader re-verification",
    ],
    "template/instructions/tests.instructions.md": [
        "targeted-test selector or phase-test command",
        "Run `{{TEST_COMMAND}}` once only when the full task is complete",
        "targeted failure required broader re-verification",
    ],
    ".github/prompts/test-gen.prompt.md": [
        "select-targeted-tests.sh <paths...>",
        "Run `bash tests/run-all.sh` once only if the generated tests finish the full task",
        "targeted failure required broader re-verification",
    ],
    "template/prompts/test-gen.prompt.md": [
        "targeted-test selector or phase-test command",
        "Run `{{TEST_COMMAND}}` once only if the generated tests finish the full task",
        "targeted failure required broader re-verification",
    ],
    "agents/organise.agent.md": [
        "Run the repo test suite once before task completion",
        "targeted failure required a fix and broader re-verification is warranted",
    ],
    "README.md": [
        "During iterative work, prefer `bash scripts/harness/select-targeted-tests.sh <paths...>`",
        "single end-of-task full-suite gate",
        "targeted failure forces broader re-verification",
    ],
}
for rel, needles in checks.items():
    text = (root / rel).read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            raise SystemExit(rel + " missing targeted-first policy guidance: " + needle)
'
echo ""

