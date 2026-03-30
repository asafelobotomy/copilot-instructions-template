#!/usr/bin/env bash
# scripts/ci/validate-cross-references.sh — detect stale section/question ranges.
# Called from CI workflow. Exit 0 = consistent, exit 1 = stale references found.
set -euo pipefail

failed=0

# Derive expected section count from copilot-instructions.md
SECTION_MAX=$(grep -oP '§\K[0-9]+' template/copilot-instructions.md | sort -n | tail -1)
echo "ℹ️  Highest section: §$SECTION_MAX"

# Derive expected question count from SETUP.md (highest E-number)
Q_MAX=$(grep -oP '^#+.*\bE\K[0-9]+' SETUP.md | sort -n | tail -1)
echo "ℹ️  Highest Expert question: E$Q_MAX"

# Check for stale "all sections" ranges (last 2 totals only).
# Intentional subsets like §1–§7 or §1–§9 are policy references,
# not claims about the total section count — skip those.
for n in $((SECTION_MAX - 2)) $((SECTION_MAX - 1)); do
  [[ $n -ge 1 ]] || continue
  hits=$(grep -rn "§1[–-]§$n\b" --include='*.md' --include='*.yml' . \
    | grep -v 'CHANGELOG.md' | grep -v 'node_modules' || true)
  if [[ -n "$hits" ]]; then
    echo "❌ Stale section range §1–§$n (expected §1–§$SECTION_MAX):"
    echo "$hits"
    failed=1
  fi
done

# Check for stale "N numbered sections" prose
number_words=("zero" "one" "two" "three" "four" "five" "six" "seven"
  "eight" "nine" "ten" "eleven" "twelve" "thirteen" "fourteen" "fifteen")
for n in $((SECTION_MAX - 2)) $((SECTION_MAX - 1)); do
  [[ $n -ge 1 ]] || continue
  word="${number_words[$n]}"
  [[ -n "$word" ]] || continue
  hits=$(grep -rni "${word}.*numbered.*section" --include='*.md' . \
    | grep -v 'CHANGELOG.md' | grep -v 'node_modules' || true)
  if [[ -n "$hits" ]]; then
    echo "❌ Stale prose '$word ... numbered ... section' (expected '${number_words[$SECTION_MAX]}'):"
    echo "$hits"
    failed=1
  fi
done

# Check for stale Expert question ranges (last 2 totals)
for n in $((Q_MAX - 2)) $((Q_MAX - 1)); do
  [[ $n -ge 16 ]] || continue
  hits=$(grep -rn "E16[–-]E$n\b" --include='*.md' . \
    | grep -v 'CHANGELOG.md' | grep -v 'node_modules' || true)
  if [[ -n "$hits" ]]; then
    echo "❌ Stale question range E16–E$n (expected E16–E$Q_MAX):"
    echo "$hits"
    failed=1
  fi
done

[[ $failed -eq 0 ]] || exit 1
echo "✅ Cross-references consistent (§1–§$SECTION_MAX, E16–E$Q_MAX)"
