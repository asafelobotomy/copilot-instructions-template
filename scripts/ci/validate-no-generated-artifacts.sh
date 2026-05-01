#!/usr/bin/env bash
# Fail when generated runtime artefacts are committed to the repository.

set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$ROOT_DIR"

bad_files="$({
  git ls-files | grep -E '(^|/)(__pycache__/|.*\.pyc$|.*\.pyo$)'
} || true)"

if [[ -n "$bad_files" ]]; then
  echo "Committed generated artefacts found:"
  echo "$bad_files"
  exit 1
fi

echo "No committed generated artefacts found"