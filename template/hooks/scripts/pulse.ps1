# purpose:  Orchestrate heartbeat trigger state and retrospective gating.
# when:     Invoked by lifecycle hooks (SessionStart/PostToolUse/PreCompact/Stop/UserPromptSubmit).
# inputs:   JSON on stdin + -Trigger <session_start|soft_post_tool|compaction|stop|user_prompt|explicit>.
# outputs:  JSON hook response (`continue` or Stop `decision:block`).
# risk:     safe
# source:   original

[CmdletBinding()]
param(
    [string]$Trigger = ''
)

$ErrorActionPreference = 'SilentlyContinue'

if (-not $Trigger) {
    '{"continue": true}'
    exit 0
}

$inputJson = [Console]::In.ReadToEnd()
& (Join-Path $PSScriptRoot 'pulse_runtime.ps1') -Trigger $Trigger -InputJson $inputJson
