#!/usr/bin/env pwsh
# purpose:  Signal subagent completion; diary writes are explicit agent actions via write_diary
# when:     SubagentStop hook — fires after a subagent finishes
# inputs:   JSON via stdin with subagent details (agent_type, agent_id, stop_hook_active)
# outputs:  JSON with additionalContext summarising outcome
# risk:     safe
# ESCALATION: none

$ErrorActionPreference = 'Stop'

$input_json = [Console]::In.ReadToEnd()
$agentName = 'unknown'
try {
  $payload = $input_json | ConvertFrom-Json -ErrorAction Stop
  if ($null -ne $payload.agent_type -and [string]::IsNullOrWhiteSpace([string]$payload.agent_type) -eq $false) {
    $agentName = [string]$payload.agent_type
  }
}
catch {
  $payload = $null
}

$context = "${agentName} done. Review before continuing."

$output = [ordered]@{
  hookSpecificOutput = [ordered]@{
    hookEventName = 'SubagentStop'
    additionalContext = $context
  }
}

$output | ConvertTo-Json -Compress
