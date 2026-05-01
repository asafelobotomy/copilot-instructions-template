#!/usr/bin/env bash
# scripts/ci/validate-shared-skill-sync.sh -- ensure shared root skills stay synced.
# Root skills/ is the canonical shared subset. Consumer-only extras may exist in
# .github/skills/ and template/skills/, but any skill that also exists at the
# root must match exactly across all three surfaces.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
FAIL=0
COUNT=0

for root_skill in "$REPO_ROOT"/skills/*; do
  [[ -d "$root_skill" ]] || continue

  skill_name=$(basename "$root_skill")
  root_file="$root_skill/SKILL.md"

  for target_root in "$REPO_ROOT/.github/skills" "$REPO_ROOT/template/skills"; do
    target_file="$target_root/$skill_name/SKILL.md"
    COUNT=$((COUNT + 1))

    if [[ ! -f "$target_file" ]]; then
      echo "SHARED SKILL DRIFT: missing ${target_file#$REPO_ROOT/} for shared root skill skills/$skill_name/SKILL.md"
      FAIL=$((FAIL + 1))
      continue
    fi

    if ! cmp -s "$root_file" "$target_file"; then
      echo "SHARED SKILL DRIFT: skills/$skill_name/SKILL.md != ${target_file#$REPO_ROOT/}"
      FAIL=$((FAIL + 1))
    fi
  done
done

if [[ $FAIL -gt 0 ]]; then
  echo "validate-shared-skill-sync: $FAIL shared-skill comparison(s) failed"
  exit 1
fi

echo "Shared skill sync OK ($COUNT comparisons)"