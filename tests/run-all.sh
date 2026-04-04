#!/usr/bin/env bash
# tests/run-all.sh -- canonical local test entrypoint for the template repo.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to run tests/run-all.sh" >&2
  exit 1
fi

exec python3 "$ROOT_DIR/scripts/tests/suite-manifest.py" run-local --root "$ROOT_DIR"
