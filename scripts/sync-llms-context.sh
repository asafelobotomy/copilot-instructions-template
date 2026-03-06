#!/usr/bin/env bash
# sync-llms-context.sh - keep llms context packs aligned with repo state.
#
# Usage:
#   bash scripts/sync-llms-context.sh --write   # rewrite llms-ctx*.txt
#   bash scripts/sync-llms-context.sh --check   # fail if generated files are out of sync
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
MODE="${1:---check}"
COMPACT_PATH="$ROOT_DIR/llms-ctx.txt"
FULL_PATH="$ROOT_DIR/llms-ctx-full.txt"
VERSION=$(tr -d '[:space:]' < "$ROOT_DIR/VERSION.md")

if [[ "$MODE" != "--check" && "$MODE" != "--write" ]]; then
  echo "Usage: bash scripts/sync-llms-context.sh [--check|--write]"
  exit 1
fi

readarray -t COUNTS < <(python3 - "$ROOT_DIR/.copilot/workspace/DOC_INDEX.json" <<'PY'
import json
import sys
with open(sys.argv[1], encoding='utf-8') as fh:
    data = json.load(fh)
print(data['counts']['agents'])
print(data['counts']['skillsRepo'])
print(data['counts']['guides'])
PY
)

AGENT_COUNT="${COUNTS[0]}"
SKILL_COUNT="${COUNTS[1]}"
GUIDE_COUNT="${COUNTS[2]}"

compact_content=$(cat <<EOF
# copilot-instructions-template LLM Context Pack

Version: $VERSION
Purpose: Compact AI-facing orientation for the template repo.

## Recommended models
- Setup and update: Claude Sonnet 4.6
- Coding and agentic implementation: GPT-5.3-Codex
- Deep review and complex reasoning: GPT-5.4
- Fast lookups: Claude Haiku 4.5

## Key entry points
- AGENTS.md: machine entry point with trigger phrases and remote sequences
- .github/copilot-instructions.md: always-loaded repo instructions
- llms.txt: concise public summary for LLMs
- llms-ctx-full.txt: expanded context pack with more navigation detail

## Core inventory
- Agents: $AGENT_COUNT model-pinned files in .github/agents/
- Skills: $SKILL_COUNT workflow skills in .github/skills/ and template/skills/
- Guides: $GUIDE_COUNT human-readable docs in docs/
- Canonical metadata: .copilot/workspace/DOC_INDEX.json
- Exhaustive catalogue: BIBLIOGRAPHY.md

## Highest-signal workflows
- Setup: read SETUP.md, then write populated .github/copilot-instructions.md and companion files into the user's project
- Update: read UPDATE.md and MIGRATION.md, then run the version-walk protocol
- Review: use review.agent.md for deep analysis; activate extension-review or test-coverage-review for heavier audits
- Health checks: use doctor.agent.md plus heartbeat files in .copilot/workspace/

## Validation commands
- Main checks: bash tests/test-hooks.sh && bash tests/test-guard-destructive.sh && bash tests/test-sync-version.sh && bash tests/test-security-edge-cases.sh
- Docs drift: bash tests/test-doc-consistency.sh
- Metadata sync: bash scripts/sync-doc-index.sh --check && bash scripts/sync-llms-context.sh --check
EOF
)

full_content=$(cat <<EOF
# copilot-instructions-template Expanded LLM Context Pack

Version: $VERSION
Purpose: Expanded AI-facing summary for agents and tools that need more than llms.txt but less than the full repo.

## Repository role
This repository is a GitHub Copilot customization template. It scaffolds model-pinned agents, instruction files, hook scripts, prompt files, workspace identity files, MCP config, and reusable skills into a user's project.

## Operating model
- The main instructions live in .github/copilot-instructions.md and follow a thirteen-section structure.
- Heavy workflows should move into on-demand skills instead of bloating the always-loaded prompt.
- AGENTS.md is the machine entry point for setup, update, restore, and trigger phrases.
- DOC_INDEX.json is the canonical machine-readable inventory; BIBLIOGRAPHY.md is the exhaustive human-readable catalogue.

## Recommended model assignments
- setup.agent.md: Claude Sonnet 4.6
- coding.agent.md: GPT-5.3-Codex
- review.agent.md: GPT-5.4
- fast.agent.md: Claude Haiku 4.5
- update.agent.md: Claude Sonnet 4.6
- doctor.agent.md: Claude Sonnet 4.6

## Repo surfaces worth reading first
- README.md: human overview and feature summary
- llms.txt: concise public summary
- AGENTS.md: machine trigger map and remote sequences
- SETUP.md: remote bootstrap protocol
- UPDATE.md: remote update and restore protocol
- MIGRATION.md: per-version change registry
- .github/copilot-instructions.md: core instruction file
- docs/AGENTS-GUIDE.md: human guide to models, triggers, and handoffs
- docs/SKILLS-GUIDE.md: human guide to skills and discovery

## Skill inventory
The repo ships $SKILL_COUNT skills. High-signal examples:
- skill-creator: author new skills
- lean-pr-review: structured Lean review workflow
- tool-protocol: search before building automation
- mcp-management: configure external tool access
- extension-review: audit VS Code extensions against the detected stack
- test-coverage-review: audit test coverage and recommend CI workflows
- webapp-testing: choose browser tools or Playwright

## Generated and canonical files
- .copilot/workspace/DOC_INDEX.json: source of truth for counts and guide/skill listings
- llms-ctx.txt and llms-ctx-full.txt: generated AI context packs kept in sync by scripts/sync-llms-context.sh
- VERSION.md: source of truth for current template version
- CHANGELOG.md and JOURNAL.md: historical change record

## Core triggers
- Setup from asafelobotomy/copilot-instructions-template
- Update your instructions
- Restore instructions from backup
- Review extensions
- Review my tests
- Check your heartbeat
- Run health check

## Validation commands
- bash tests/test-hooks.sh
- bash tests/test-guard-destructive.sh
- bash tests/test-sync-version.sh
- bash tests/test-security-edge-cases.sh
- bash tests/test-doc-consistency.sh
- bash scripts/sync-doc-index.sh --check
- bash scripts/sync-llms-context.sh --check
EOF
)

write_if_needed() {
  local path="$1"
  local content="$2"
  if [[ "$MODE" == "--write" ]]; then
    printf '%s\n' "$content" > "$path"
    echo "OK: wrote $path"
    return
  fi

  local tmp
  tmp=$(mktemp)
  printf '%s\n' "$content" > "$tmp"
  if ! cmp -s "$tmp" "$path"; then
    echo "FAIL: $(basename "$path") is out of sync"
    rm -f "$tmp"
    return 1
  fi
  rm -f "$tmp"
  echo "OK: $(basename "$path") is in sync"
}

write_if_needed "$COMPACT_PATH" "$compact_content"
write_if_needed "$FULL_PATH" "$full_content"
