#!/usr/bin/env bash
# report-script-coverage.sh -- generate measurable bash and PowerShell script coverage.
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
OUTPUT_ARG="${1:-coverage}"

discover_bash_tests() {
    find "$ROOT_DIR/tests" -maxdepth 1 -type f -name 'test-*.sh' \
        | sed "s#^$ROOT_DIR/##" \
        | LC_ALL=C sort \
        | while IFS= read -r rel_path; do
                case "$rel_path" in
                    tests/test-*-powershell.sh|tests/test-report-script-coverage.sh|tests/test-inventory-files.sh|tests/test-markdown-contracts.sh|tests/test-release-contracts.sh|tests/test-customization-contracts.sh|tests/test-agent-skill-contracts.sh|tests/test-template-parity.sh)
                        continue
                        ;;
                esac
                printf '%s\n' "$rel_path"
            done
}

if [[ "$OUTPUT_ARG" == "--list-bash-tests" ]]; then
    discover_bash_tests
    exit 0
fi

if [[ "$OUTPUT_ARG" = /* ]]; then
    OUTPUT_DIR="$OUTPUT_ARG"
else
    OUTPUT_DIR="$ROOT_DIR/$OUTPUT_ARG"
fi

BASH_TRACE="$OUTPUT_DIR/bash-trace.log"
POWERSHELL_TRACE="$OUTPUT_DIR/powershell-trace.log"
SUMMARY_JSON="$OUTPUT_DIR/script-coverage-summary.json"
SUMMARY_MD="$OUTPUT_DIR/script-coverage-summary.md"

mkdir -p "$OUTPUT_DIR"
: > "$BASH_TRACE"
: > "$POWERSHELL_TRACE"

mapfile -t bash_tests < <(discover_bash_tests)

for test_script in "${bash_tests[@]}"; do
  echo "[bash coverage] $test_script"
  BASH_COVERAGE_TRACE="$BASH_TRACE" BASH_ENV="$ROOT_DIR/tests/coverage/bash-prelude.sh" bash "$ROOT_DIR/$test_script"
done

echo "[powershell coverage] tests/coverage/run-powershell-coverage.sh"
PWSH_COVERAGE_TRACE="$POWERSHELL_TRACE" bash "$ROOT_DIR/tests/coverage/run-powershell-coverage.sh"

python3 - "$ROOT_DIR" "$BASH_TRACE" "$POWERSHELL_TRACE" "$SUMMARY_JSON" "$SUMMARY_MD" <<'PY'
import json
import os
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1]).resolve()
bash_trace_path = pathlib.Path(sys.argv[2])
powershell_trace_path = pathlib.Path(sys.argv[3])
summary_json_path = pathlib.Path(sys.argv[4])
summary_md_path = pathlib.Path(sys.argv[5])

bash_threshold = float(os.environ.get('BASH_SCRIPT_COVERAGE_THRESHOLD', '0'))
powershell_threshold = float(os.environ.get('POWERSHELL_SCRIPT_COVERAGE_THRESHOLD', '0'))
overall_threshold = float(os.environ.get('OVERALL_SCRIPT_COVERAGE_THRESHOLD', '0'))

bash_targets = [
    'scripts/sync-version.sh',
    'scripts/sync-doc-index.sh',
    'scripts/sync-llms-context.sh',
    'template/hooks/scripts/session-start.sh',
    'template/hooks/scripts/guard-destructive.sh',
    'template/hooks/scripts/post-edit-lint.sh',
    'template/hooks/scripts/enforce-retrospective.sh',
    'template/hooks/scripts/save-context.sh',
]

powershell_targets = [
    'template/hooks/scripts/session-start.ps1',
    'template/hooks/scripts/guard-destructive.ps1',
    'template/hooks/scripts/post-edit-lint.ps1',
    'template/hooks/scripts/enforce-retrospective.ps1',
    'template/hooks/scripts/save-context.ps1',
]

trace_pattern = re.compile(r'^TRACE:(.*?):(\d+):')
block_comment_start = '<#'
block_comment_end = '#>'
heredoc_pattern = re.compile(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")


def normalize(path_str: str) -> str:
    return pathlib.Path(path_str).resolve().relative_to(root).as_posix()


def measurable_lines(path: pathlib.Path, language: str):
    lines = path.read_text(encoding='utf-8').splitlines()
    measured = set()
    in_block_comment = False
    heredoc_end = None
    powershell_data_block_end = None
    skip_tokens = {'{', '}', 'then', 'do', 'fi', 'done', 'esac', 'else', ';;'} if language == 'bash' else {'{', '}'}

    for index, line in enumerate(lines, start=1):
        stripped = line.strip()

        if language == 'bash' and heredoc_end is not None:
            if stripped == heredoc_end:
                heredoc_end = None
            continue

        if language == 'powershell' and powershell_data_block_end is not None:
            if stripped == powershell_data_block_end:
                powershell_data_block_end = None
            continue

        if not stripped:
            continue

        if language == 'powershell':
            if in_block_comment:
                if block_comment_end in stripped:
                    in_block_comment = False
                continue
            if stripped.startswith(block_comment_start):
                if block_comment_end not in stripped:
                    in_block_comment = True
                continue

            if '@(' in stripped:
                measured.add(index)
                powershell_data_block_end = ')'
                continue

            if '@{' in stripped:
                measured.add(index)
                powershell_data_block_end = '}'
                continue

        if stripped.startswith('#'):
            continue
        if stripped in skip_tokens:
            continue

        if language == 'bash':
            heredoc_match = heredoc_pattern.search(line)
            if heredoc_match:
                measured.add(index)
                heredoc_end = heredoc_match.group(2)
                continue

        measured.add(index)
    return measured


def parse_trace(trace_path: pathlib.Path, targets):
    executed = {target: set() for target in targets}
    if not trace_path.exists():
        return executed

    with trace_path.open(encoding='utf-8', errors='ignore') as handle:
        for raw_line in handle:
            match = trace_pattern.match(raw_line.strip())
            if not match:
                continue
            try:
                relative_path = normalize(match.group(1))
            except ValueError:
                continue
            if relative_path in executed:
                executed[relative_path].add(int(match.group(2)))
    return executed


def summarise(targets, language, trace_path, threshold):
    executed_by_file = parse_trace(trace_path, targets)
    files = []
    total_measured = 0
    total_covered = 0

    for relative_path in targets:
        absolute_path = root / relative_path
        measured = measurable_lines(absolute_path, language)
        covered = executed_by_file.get(relative_path, set()) & measured
        missed = sorted(measured - covered)
        measured_count = len(measured)
        covered_count = len(covered)
        percent = round((covered_count / measured_count * 100) if measured_count else 100.0, 2)
        total_measured += measured_count
        total_covered += covered_count
        files.append({
            'path': relative_path,
            'covered': covered_count,
            'measurable': measured_count,
            'percent': percent,
            'missedLines': missed[:25],
        })

    files.sort(key=lambda entry: entry['path'])
    percent = round((total_covered / total_measured * 100) if total_measured else 100.0, 2)
    return {
        'language': language,
        'threshold': threshold,
        'covered': total_covered,
        'measurable': total_measured,
        'percent': percent,
        'passed': percent >= threshold,
        'files': files,
    }


bash_summary = summarise(bash_targets, 'bash', bash_trace_path, bash_threshold)
powershell_summary = summarise(powershell_targets, 'powershell', powershell_trace_path, powershell_threshold)
overall_measurable = bash_summary['measurable'] + powershell_summary['measurable']
overall_covered = bash_summary['covered'] + powershell_summary['covered']
overall_percent = round((overall_covered / overall_measurable * 100) if overall_measurable else 100.0, 2)

summary = {
    'note': 'Coverage is measured from runtime trace data collected while executing the repository test suites. Mirror files under .github/hooks/scripts are excluded from the denominator because CI separately enforces parity with template copies.',
    'bash': bash_summary,
    'powershell': powershell_summary,
    'overall': {
        'threshold': overall_threshold,
        'covered': overall_covered,
        'measurable': overall_measurable,
        'percent': overall_percent,
        'passed': overall_percent >= overall_threshold,
    },
}

summary_json_path.write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')

md_lines = [
    '# Script Coverage Summary',
    '',
    summary['note'],
    '',
    '| Scope | Covered | Measurable | Coverage | Threshold | Status |',
    '|-------|---------|------------|----------|-----------|--------|',
]
for scope_name, scope in (('Bash', bash_summary), ('PowerShell', powershell_summary), ('Overall', summary['overall'])):
    status = 'PASS' if scope['passed'] else 'FAIL'
    md_lines.append(f"| {scope_name} | {scope['covered']} | {scope['measurable']} | {scope['percent']:.2f}% | {scope['threshold']:.2f}% | {status} |")

for section_name, scope in (('Bash', bash_summary), ('PowerShell', powershell_summary)):
    md_lines.extend(['', f'## {section_name} Files', '', '| File | Covered | Measurable | Coverage | Missed sample |', '|------|---------|------------|----------|---------------|'])
    for file_summary in scope['files']:
        missed_sample = ', '.join(str(line) for line in file_summary['missedLines'][:8]) or '—'
        md_lines.append(
            f"| `{file_summary['path']}` | {file_summary['covered']} | {file_summary['measurable']} | {file_summary['percent']:.2f}% | {missed_sample} |"
        )

summary_md_path.write_text('\n'.join(md_lines) + '\n', encoding='utf-8')

if not bash_summary['passed'] or not powershell_summary['passed'] or not summary['overall']['passed']:
    print(summary_md_path.read_text(encoding='utf-8'))
    sys.exit(1)

print(summary_md_path.read_text(encoding='utf-8'))
PY

echo "Coverage reports written to $OUTPUT_DIR"
