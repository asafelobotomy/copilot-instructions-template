#!/usr/bin/env bash
# tests/coverage/bash-prelude.sh -- enable bash xtrace coverage when requested.

if [[ -n "${BASH_COVERAGE_TRACE:-}" ]]; then
  exec 9>>"$BASH_COVERAGE_TRACE"
  export BASH_XTRACEFD=9
  export PS4='TRACE:${BASH_SOURCE}:${LINENO}:'
  set -x
fi
