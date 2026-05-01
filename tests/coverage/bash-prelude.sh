#!/usr/bin/env bash
# tests/coverage/bash-prelude.sh -- enable bash xtrace coverage when requested.

set -euo pipefail
if [[ -n "${BASH_COVERAGE_TRACE:-}" ]]; then
  exec 9>>"$BASH_COVERAGE_TRACE"
  BASH_XTRACEFD=9
  export PS4='TRACE:${BASH_SOURCE:-$0}:${LINENO}:'
  set -x
fi
