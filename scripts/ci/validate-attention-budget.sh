#!/usr/bin/env bash
# scripts/ci/validate-attention-budget.sh — enforce line-count budgets on the template.
# Called from CI workflow. Exit 0 = within budget, exit 1 = over budget.
set -euo pipefail

FILE="template/copilot-instructions.md"
TOTAL=$(wc -l < "$FILE")
MAX_TOTAL=800
MAX_SECTION=120
MAX_PROTOCOL=150
failed=0

echo "ℹ️  Total lines: $TOTAL (budget: $MAX_TOTAL)"
if [[ $TOTAL -gt $MAX_TOTAL ]]; then
  echo "❌ File exceeds $MAX_TOTAL-line budget ($TOTAL lines)"
  echo "   Extract detail into skills, path-instructions, or prompt files."
  failed=1
fi

# Per-section check (§2 ≤ 210, §1/§3–§9 ≤ 120, §11–§13 ≤ 150, §10 exempt)
prev_line=0
prev_section=""
while IFS=: read -r line_num text; do
  section_num=$(echo "$text" | grep -oP '§\K[0-9]+')
  if [[ -n "$prev_section" && $prev_line -gt 0 ]]; then
    len=$((line_num - prev_line))
    if [[ $prev_section -eq 10 ]]; then
      limit=999999  # §10 exempt
    elif [[ $prev_section -eq 2 ]]; then
      limit=210     # §2 Operating Modes gets extra room
    elif [[ $prev_section -ge 11 ]]; then
      limit=$MAX_PROTOCOL
    else
      limit=$MAX_SECTION
    fi
    if [[ $prev_section -ne 10 && $len -gt $limit ]]; then
      echo "❌ §$prev_section is $len lines (budget: $limit)"
      failed=1
    fi
  fi
  prev_line=$line_num
  prev_section=$section_num
done < <(grep -n '^## §[0-9]\+ —' "$FILE")

# Check last section
if [[ -n "$prev_section" && $prev_line -gt 0 ]]; then
  len=$((TOTAL - prev_line + 1))
  if [[ $prev_section -eq 10 ]]; then
    limit=999999
  elif [[ $prev_section -eq 2 ]]; then
    limit=210
  elif [[ $prev_section -ge 11 ]]; then
    limit=$MAX_PROTOCOL
  else
    limit=$MAX_SECTION
  fi
  if [[ $prev_section -ne 10 && $len -gt $limit ]]; then
    echo "❌ §$prev_section is $len lines (budget: $limit)"
    failed=1
  fi
fi

[[ $failed -eq 0 ]] || exit 1
echo "✅ Attention budget OK"
