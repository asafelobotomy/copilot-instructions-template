#!/usr/bin/env bash
# scripts/ci/validate-template-sync.sh — CI wrapper around the canonical template parity check.
# Called from CI workflow. Exit 0 = in sync, exit 1 = drift detected.
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROOT_DIR="${ROOT_DIR:-$SCRIPT_ROOT}"

ROOT_DIR="$ROOT_DIR" exec bash "$SCRIPT_ROOT/scripts/sync/sync-template-parity.sh" --check
