#!/usr/bin/env bash
# scripts/ci/validate-template-sync.sh — check .github/ copies match template/ copies.
# Called from CI workflow. Exit 0 = in sync, exit 1 = drift detected.
set -euo pipefail

drift=0
# Skills: .github/skills/* must match template/skills/*
for dir in .github/skills/*/; do
  skill=$(basename "$dir")
  if [[ "$skill" == "mcp-management" ]]; then
    continue
  fi
  template_skill="template/skills/$skill/SKILL.md"
  if [[ -f "$template_skill" ]]; then
    if ! diff -q "$dir/SKILL.md" "$template_skill" > /dev/null 2>&1; then
      echo "❌ Drift: $dir/SKILL.md ≠ $template_skill"; drift=1
    fi
  fi
done
# Hooks: .github/hooks/scripts/* must match template/hooks/scripts/*
for f in .github/hooks/scripts/*.sh; do
  tf="template/hooks/scripts/$(basename "$f")"
  if [[ -f "$tf" ]] && ! diff -q "$f" "$tf" > /dev/null 2>&1; then
    echo "❌ Drift: $f ≠ $tf"; drift=1
  fi
done
for f in .github/hooks/scripts/*.ps1; do
  tf="template/hooks/scripts/$(basename "$f")"
  if [[ -f "$tf" ]] && ! diff -q "$f" "$tf" > /dev/null 2>&1; then
    echo "❌ Drift: $f ≠ $tf"; drift=1
  fi
done
if ! diff -q .github/hooks/copilot-hooks.json template/hooks/copilot-hooks.json > /dev/null 2>&1; then
  echo "❌ Drift: copilot-hooks.json"; drift=1
fi
[[ $drift -eq 0 ]] || { echo "Sync the drifted files and commit."; exit 1; }
echo "✅ All template copies in sync"
