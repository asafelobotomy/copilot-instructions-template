#!/usr/bin/env bash
# Validate consumer-surface parity between template/ and .github/.
#
# Skills are authored once and must stay byte-identical between
# template/skills/ and .github/skills/. Prompts and instructions
# legitimately differ between the two trees because the template tree may
# contain `{{PLACEHOLDER}}` tokens or section references that are resolved
# in the developer copy. Parity for those surfaces is enforced indirectly
# through the existing customization-contract suites.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

status=0

check_pair() {
  local left="$1"
  local right="$2"
  if [[ ! -d "$left" ]] || [[ ! -d "$right" ]]; then
    return 0
  fi
  local diff_output
  diff_output="$(diff -rq "$left" "$right" 2>/dev/null || true)"
  if [[ -n "$diff_output" ]]; then
    echo "PARITY DRIFT: $left vs $right"
    echo "$diff_output"
    status=1
  fi
}

check_pair "template/skills" ".github/skills"

if [[ $status -eq 0 ]]; then
  echo "Consumer-surface parity OK"
fi
exit $status
