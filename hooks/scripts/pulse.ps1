#!/usr/bin/env pwsh
# purpose:  Thin proxy — delegates heartbeat/routing to Python canonical runtime.
# when:     Invoked by lifecycle hooks (SessionStart/PostToolUse/PreCompact/Stop/UserPromptSubmit).
# inputs:   JSON on stdin + -Trigger <name>.
# outputs:  JSON hook response from pulse_runtime.py.
# risk:     safe
# source:   original
# ESCALATION: none
# STOP LOOP: if stop_hook_active is true in the Stop payload, do not re-enter blocking Stop logic.

[CmdletBinding()]
param(
    [string]$Trigger = ''
)

Set-StrictMode -Version 1
$ErrorActionPreference = 'Stop'

$inputJson = [Console]::In.ReadToEnd()

# Resolve trigger: param > env > payload field
$effectiveTrigger = $Trigger
if (-not $effectiveTrigger) { $effectiveTrigger = $env:TRIGGER }
if (-not $effectiveTrigger) {
    try {
        $payload = $inputJson | ConvertFrom-Json -ErrorAction Stop
        if ($payload -and ($payload.PSObject.Properties.Name -contains 'trigger') -and $payload.trigger -is [string]) {
            $effectiveTrigger = $payload.trigger.Trim()
        }
    } catch {
        $effectiveTrigger = ''
    }
}

if (-not $effectiveTrigger) {
    '{"continue":true}'
    exit 0
}

# Resolve Python executable
$pythonCmd = Get-Command 'python3' -ErrorAction SilentlyContinue
if (-not $pythonCmd) { $pythonCmd = Get-Command 'python' -ErrorAction SilentlyContinue }
if (-not $pythonCmd) {
    '{"continue":true,"hookSpecificOutput":{"additionalContext":"Pulse hook: python3/python not found; skipping heartbeat runtime."}}'
    exit 0
}

$runtimeScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'pulse_runtime.py'
if (-not (Test-Path -LiteralPath $runtimeScript)) {
    '{"continue":true,"hookSpecificOutput":{"additionalContext":"Pulse hook: pulse_runtime.py not found; skipping heartbeat runtime."}}'
    exit 0
}

try {
    $output = $inputJson | & $pythonCmd.Source $runtimeScript $effectiveTrigger
    if ($LASTEXITCODE -ne 0) {
        '{"continue":true,"hookSpecificOutput":{"additionalContext":"Pulse hook: python runtime failed; continuing without heartbeat update."}}'
    } elseif ($null -eq $output -or [string]::IsNullOrWhiteSpace(($output -join "`n"))) {
        '{"continue":true}'
    } else {
        $rawOutput = $output -join "`n"
        try {
            $parsedOutput = $rawOutput | ConvertFrom-Json -Depth 100
            $parsedOutput | ConvertTo-Json -Compress -Depth 100
        } catch {
            $rawOutput
        }
    }
} catch {
    '{"continue":true,"hookSpecificOutput":{"additionalContext":"Pulse hook: python runtime invocation failed; continuing without heartbeat update."}}'
}
