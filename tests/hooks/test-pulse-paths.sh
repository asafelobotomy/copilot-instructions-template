#!/usr/bin/env bash
# tests/hooks/test-pulse-paths.sh -- unit tests for pulse_paths.py
# Run: bash tests/hooks/test-pulse-paths.sh
# Exit 0: all tests passed. Exit 1: one or more failures.
set -uo pipefail

# shellcheck source=../lib/test-helpers.sh
source "$(dirname "$0")/../lib/test-helpers.sh"
init_test_context "$0"
MODULE_PATH="$REPO_ROOT/hooks/scripts/pulse_paths.py"

load_module_code='import importlib.util
spec = importlib.util.spec_from_file_location("pulse_paths", os.environ["MODULE_PATH"])
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)
'

echo "=== pulse_paths.py ==="
echo ""

echo "1. normalize_path canonicalizes dotted and absolute paths"
MODULE_PATH="$MODULE_PATH" assert_python "normalize_path canonicalizes dotted and absolute paths" "$load_module_code
absolute = str(root / 'README.md')
assert module.normalize_path('./hooks/scripts/pulse.sh') == 'hooks/scripts/pulse.sh'
assert module.normalize_path(absolute) == 'README.md'
assert module.normalize_path('') == ''
"
echo ""

echo "2. extract_tool_paths collects supported path fields and de-duplicates"
MODULE_PATH="$MODULE_PATH" assert_python "extract_tool_paths collects and de-duplicates supported path fields" "$load_module_code
payload = {
    'tool_input': {
        'filePath': './README.md',
        'files': [
            'hooks/scripts/pulse.sh',
            {'path': str(root / 'SETUP.md')},
            {'filePath': 'hooks/scripts/pulse.sh'},
        ],
    }
}
assert module.extract_tool_paths(payload) == ['README.md', 'hooks/scripts/pulse.sh', 'SETUP.md']
"
echo ""

echo "3. classify_path_family recognizes the main repository surface types"
MODULE_PATH="$MODULE_PATH" assert_python "classify_path_family recognizes the main repository surface types" "$load_module_code
expected = {
    '.copilot/workspace/knowledge/MEMORY.md': 'memory',
    'hooks/scripts/pulse.sh': 'hook',
    'agents/code.agent.md': 'agent',
    'tests/hooks/test-hook-pulse.sh': 'tests',
    'scripts/release/verify-version-references.sh': 'ci_release',
    'release-please-config.json': 'manifest',
    '.vscode/settings.json': 'config',
    'README.md': 'docs',
    'scripts/copilot_audit.py': 'runtime',
}
for path_text, family in expected.items():
    actual = module.classify_path_family(path_text)
    assert actual == family, f'{path_text}: {actual} != {family}'
"
echo ""

echo "4. path_requires_parity identifies mirrored customization surfaces"
MODULE_PATH="$MODULE_PATH" assert_python "path_requires_parity identifies mirrored customization surfaces" "$load_module_code
assert module.path_requires_parity('hooks/scripts/pulse.sh')
assert module.path_requires_parity('.github/prompts/context-map.prompt.md')
assert module.path_requires_parity('template/workspace/operations/workspace-index.json')
assert not module.path_requires_parity('scripts/release/verify-version-references.sh')
"
echo ""

echo "5. update_touched_files preserves order, de-duplicates paths, and tracks families"
MODULE_PATH="$MODULE_PATH" assert_python "update_touched_files preserves order, de-duplicates paths, and tracks families" "$load_module_code
state = {
    'touched_files_sample': ['scripts/copilot_audit.py'],
    'changed_path_families': ['runtime'],
    'unique_touched_file_count': 1,
}
updated = module.update_touched_files(
    state,
    ['scripts/copilot_audit.py', 'hooks/scripts/pulse.sh', '.copilot/workspace/knowledge/MEMORY.md'],
)
assert updated['touched_files_sample'] == [
    'scripts/copilot_audit.py',
    'hooks/scripts/pulse.sh',
    '.copilot/workspace/knowledge/MEMORY.md',
]
assert updated['unique_touched_file_count'] == 3
assert updated['changed_path_families'] == ['runtime', 'hook', 'memory']
"
echo ""

finish_tests