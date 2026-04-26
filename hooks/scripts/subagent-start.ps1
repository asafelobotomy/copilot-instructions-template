#!/usr/bin/env pwsh
# purpose:  Add governance context when a subagent starts
# when:     SubagentStart
# inputs:   JSON via stdin with subagent details (agent_type, agent_id)
# outputs:  JSON with additionalContext
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

# Spatial status is via the extension tool
$context = "Depth<=3. PDCA, Tool, Skill. Agent: ${agentName}. Use asafelobotomy_spatial_status for context."

$output = [ordered]@{
  hookSpecificOutput = [ordered]@{
    hookEventName = 'SubagentStart'
    additionalContext = $context
  }
}

$output | ConvertTo-Json -Compress
