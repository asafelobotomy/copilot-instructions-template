#!/usr/bin/env bash
# scripts/ci/validate-cross-references.sh — detect stale section ranges and dead llms.txt links.
# Called from CI workflow. Exit 0 = consistent, exit 1 = stale references found.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
TEMPLATE_FILE="$ROOT_DIR/template/copilot-instructions.md"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "❌ Missing: template/copilot-instructions.md"
  exit 1
fi

cd "$ROOT_DIR"

failed=0

# Derive expected section count from copilot-instructions.md
SECTION_MAX=$(grep -oP '§\K[0-9]+' "$TEMPLATE_FILE" | sort -n | tail -1)
echo "ℹ️  Highest section: §$SECTION_MAX"

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

[[ $failed -eq 0 ]] || exit 1
echo "✅ Cross-references consistent (§1–§$SECTION_MAX)"

# Validate llms.txt file link targets exist
LLMS_FILE="$ROOT_DIR/llms.txt"
if [[ -f "$LLMS_FILE" ]]; then
  echo ""
  echo "ℹ️  Checking llms.txt link targets…"
  _link_re='\[([^]]+)\]\(([^)]+)\)'
  while IFS= read -r line; do
    # Extract markdown link target: [text](path) — capture the path
    if [[ "$line" =~ $_link_re ]]; then
      target="${BASH_REMATCH[2]}"
      # Skip URLs (http/https) and fragment-only links
      [[ "$target" =~ ^https?:// ]] && continue
      [[ "$target" =~ ^# ]] && continue
      if [[ ! -e "$ROOT_DIR/$target" ]]; then
        echo "❌ llms.txt: dead link target '$target'"
        failed=1
      fi
    fi
  done < "$LLMS_FILE"
  [[ $failed -eq 0 ]] && echo "✅ llms.txt link targets all exist"
fi

[[ $failed -eq 0 ]] || exit 1
