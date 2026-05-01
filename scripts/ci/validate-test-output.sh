#!/usr/bin/env bash
# scripts/ci/validate-test-output.sh -- verify all test scripts emit mandatory result output.
# Every standalone tests/**/test-*.sh entrypoint must call finish_tests or
# contain an explicit Results: echo. Sourced shard files may share the naming
# convention but rely on a wrapper suite for result reporting.
# Exit 0: all compliant. Exit 1: one or more scripts missing result reporting.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
FAIL=0
COUNT=0

while IFS= read -r f; do
  if [[ "$(head -n 1 "$f")" != '#!/usr/bin/env bash' ]]; then
    continue
  fi
  name=$(basename "$f")
  COUNT=$((COUNT + 1))
  if ! grep -qE 'finish_tests|echo.*Results' "$f"; then
    echo "FAIL: $name — missing finish_tests or 'Results:' output"
    FAIL=$((FAIL + 1))
  fi
done < <(find "$REPO_ROOT/tests" -mindepth 2 -maxdepth 2 -type f -name 'test-*.sh' | sort)

if [[ $FAIL -gt 0 ]]; then
  echo "validate-test-output: $FAIL script(s) lack mandatory result reporting"
  exit 1
fi

echo "OK: all $COUNT test scripts have mandatory result reporting"
