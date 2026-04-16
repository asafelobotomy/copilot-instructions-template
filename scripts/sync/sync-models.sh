#!/usr/bin/env bash
# sync-models.sh — keep agents/*.agent.md model lists and llms.txt
#                  aligned with the single source of truth in MODELS.md.
#
# Usage:
#   bash scripts/sync/sync-models.sh --write   # propagate MODELS.md → agent files + llms.txt
#   bash scripts/sync/sync-models.sh --check   # fail if any file is out of sync
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
MODELS_FILE="$ROOT_DIR/MODELS.md"
MODE="${1:---check}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=../lib.sh
source "$(dirname "$0")/../lib.sh"
require_python_check_write "sync/sync-models.sh" "$MODE"

if [[ ! -f "$MODELS_FILE" ]]; then
  echo "❌ MODELS.md not found at $MODELS_FILE"
  exit 1
fi

python3 "$SCRIPT_DIR/sync_models.py" "$ROOT_DIR" "$MODELS_FILE" "$MODE"
