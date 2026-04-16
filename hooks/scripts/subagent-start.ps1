#!/usr/bin/env pwsh
# purpose:  Inject subagent governance context when a subagent is spawned
# when:     SubagentStart hook — fires before a subagent begins work
# inputs:   JSON via stdin with subagent details (agent_type, agent_id)
# outputs:  JSON with additionalContext including governance hint
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

# Diary access is explicit — agents call spatial_status or read_diaries
$context = "Depth<=3. Protocols: PDCA, Tool, Skill. Agent: ${agentName}. Call spatial_status or read_diaries to access your diary."

$output = [ordered]@{
  hookSpecificOutput = [ordered]@{
    hookEventName = 'SubagentStart'
    additionalContext = $context
  }
}

$output | ConvertTo-Json -Compress
