# purpose:  Remind the agent to run the retrospective before stopping
# when:     Stop hook — fires when the agent session ends
# inputs:   JSON via stdin with stop_hook_active flag
# outputs:  JSON that can block stopping if retrospective was not run
# risk:     safe

$ErrorActionPreference = 'SilentlyContinue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pulsePath = Join-Path $scriptDir 'pulse.ps1'

if (Test-Path $pulsePath) {
    & $pulsePath -Trigger stop
    exit 0
}

'{"continue": true}'
