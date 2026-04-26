#!/usr/bin/env bash
# scripts/ci/validate-agent-frontmatter.sh — validate all agent files have required frontmatter.
#
# Usage: bash scripts/ci/validate-agent-frontmatter.sh
# Exit 0: all agents valid. Exit 1: one or more errors.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"
require_command python3

PY_VALIDATOR="$ROOT_DIR/scripts/ci/validate_agent_frontmatter.py"
if [[ ! -f "$PY_VALIDATOR" ]]; then
	PY_VALIDATOR="$(dirname "$0")/validate_agent_frontmatter.py"
fi

python3 "$PY_VALIDATOR" "$ROOT_DIR"
