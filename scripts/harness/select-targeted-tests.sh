#!/usr/bin/env bash
# purpose:  Map changed repository paths to deterministic targeted test suites for intermediate-phase verification.
# when:     Use during task phases to choose targeted suites from changed paths; not a replacement for the final full-suite gate.
# inputs:   One or more repo-relative or absolute file or directory paths under the current repository root.
# outputs:  JSON describing normalized paths, selected test suites, intermediate-phase strategy, the inner-loop time budget, matched rules, and the final full-suite gate.
# risk:     safe
# source:   original
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
MAP_FILE="$ROOT_DIR/scripts/harness/targeted-test-map.json"
SUITE_MANIFEST_PATH="$ROOT_DIR/scripts/harness/suite-manifest.json"

if [[ $# -lt 1 ]]; then
  echo "Usage: bash scripts/harness/select-targeted-tests.sh <path> [<path>...]" >&2
  exit 1
fi

exec python3 "$(dirname "$0")/select_targeted_tests.py" "$ROOT_DIR" "$MAP_FILE" "$SUITE_MANIFEST_PATH" "$@"
