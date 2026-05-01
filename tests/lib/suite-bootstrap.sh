#!/usr/bin/env bash
# tests/lib/suite-bootstrap.sh — Source this file at the TOP of each test suite
# instead of manually calling source + init_test_context + trap.
#
# Usage (at the start of a test file, BEFORE any other setup):
#   source "$(dirname "$0")/../lib/suite-bootstrap.sh"
#
# After sourcing:
#   - test-helpers.sh is loaded
#   - init_test_context is called with the calling script's path
#   - cleanup_dirs trap is registered on EXIT
#   - REPO_ROOT and TESTS_ROOT are set

# Resolve the caller's script path (BASH_SOURCE[1] when this file is sourced)
set -uo pipefail
_bootstrap_caller="${BASH_SOURCE[1]:-$0}"

# shellcheck source=test-helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"

init_test_context "$_bootstrap_caller"
trap cleanup_dirs EXIT