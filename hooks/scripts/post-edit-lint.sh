#!/usr/bin/env bash
# purpose:  Auto-format files after agent edits them
# when:     PostToolUse hook — fires after a tool completes successfully
# inputs:   JSON via stdin with tool_name and tool_input
# outputs:  JSON with additionalContext if lint errors found
# risk:     safe
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\(.*\)"/\1/') || TOOL_NAME=""

# Only run after file-editing tools
if [[ "$TOOL_NAME" != *"edit"* && "$TOOL_NAME" != *"create"* && "$TOOL_NAME" != *"write"* && "$TOOL_NAME" != *"replace"* ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Extract file paths from tool input
FILES=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    ti = data.get('tool_input', {})
    # Try common field names for file paths
    for key in ('filePath', 'file', 'path', 'files', 'file_path'):
        val = ti.get(key, '')
        if isinstance(val, list):
            for v in val:
                print(v)
        elif val:
            print(val)
except Exception:
    pass
" 2>/dev/null || echo "")

if [[ -z "$FILES" ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Resolve workspace root for boundary checks
WORKSPACE_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
LINT_NOTES=""

while IFS= read -r filepath; do
  [[ -z "$filepath" ]] && continue
  [[ ! -f "$filepath" ]] && continue

  # Workspace boundary check — reject paths outside the repo root
  real_path=$(realpath "$filepath" 2>/dev/null) || continue
  case "$real_path" in
    "$WORKSPACE_ROOT"/*)  ;;
    *) continue ;;
  esac

  EXT="${filepath##*.}"
  _fmt_err=""
  case "$EXT" in
    js|jsx|ts|tsx|mjs|cjs)
      if command -v npx &>/dev/null && [[ -f node_modules/.bin/prettier ]]; then
        _fmt_err=$(npx prettier --write "$filepath" 2>&1) || LINT_NOTES+="[prettier:${filepath}] ${_fmt_err} "
      fi
      ;;
    py)
      if command -v black &>/dev/null; then
        _fmt_err=$(black --quiet "$filepath" 2>&1) || LINT_NOTES+="[black:${filepath}] ${_fmt_err} "
      elif command -v ruff &>/dev/null; then
        _fmt_err=$(ruff format "$filepath" 2>&1) || LINT_NOTES+="[ruff:${filepath}] ${_fmt_err} "
      fi
      ;;
    rs)
      if command -v rustfmt &>/dev/null; then
        _fmt_err=$(rustfmt "$filepath" 2>&1) || LINT_NOTES+="[rustfmt:${filepath}] ${_fmt_err} "
      fi
      ;;
    go)
      if command -v gofmt &>/dev/null; then
        _fmt_err=$(gofmt -w "$filepath" 2>&1) || LINT_NOTES+="[gofmt:${filepath}] ${_fmt_err} "
      fi
      ;;
  esac
done <<< "$FILES"

if [[ -n "$LINT_NOTES" ]]; then
  python3 -c "import sys,json; print(json.dumps({'continue':True,'additionalContext':sys.argv[1]}))" "$LINT_NOTES"
else
  echo '{"continue": true}'
fi
