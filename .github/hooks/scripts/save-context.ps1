# purpose:  Save critical workspace context before conversation compaction
# when:     PreCompact hook — fires when context is about to be truncated
# inputs:   JSON via stdin with trigger field
# outputs:  JSON with additionalContext summarising saved state
# risk:     safe

$ErrorActionPreference = 'SilentlyContinue'
$summary = ''

function Get-PythonCommand {
    foreach ($candidate in @('python3', 'python', 'py')) {
        if (Get-Command $candidate -ErrorAction SilentlyContinue) {
            return $candidate
        }
    }
    return $null
}

function Get-ClockSummary {
    $statePath = '.copilot/workspace/state.json'
    $eventsPath = '.copilot/workspace/.heartbeat-events.jsonl'
    if (-not (Test-Path $statePath) -and -not (Test-Path $eventsPath)) {
        return ''
    }

    $pythonCommand = Get-PythonCommand
    if ($null -eq $pythonCommand) {
        return ''
    }

    $helperPath = Join-Path $PSScriptRoot 'heartbeat_clock_summary.py'
    if (-not (Test-Path $helperPath)) {
        return ''
    }

    if ($pythonCommand -eq 'py') {
        $output = & py -3 $helperPath 2>$null
        if (-not $output) {
            $output = & py $helperPath 2>$null
        }
    } else {
        $output = & $pythonCommand $helperPath 2>$null
    }

    return ($output | Out-String).Trim()
}

# Heartbeat pulse
if (Test-Path '.copilot/workspace/HEARTBEAT.md') {
    $pulse = (Select-String -Path '.copilot/workspace/HEARTBEAT.md' -Pattern 'HEARTBEAT' |
              Select-Object -First 1).Line
    if ($pulse) { $summary += "Heartbeat: $pulse. " }
}

$clockSummary = Get-ClockSummary
if ($clockSummary) {
    $summary += "Clock: $clockSummary. "
}

# Recent MEMORY.md entries
if (Test-Path '.copilot/workspace/MEMORY.md') {
    $recentMemory = (Get-Content '.copilot/workspace/MEMORY.md' -Tail 20 -ErrorAction SilentlyContinue) -join "`n"
    if ($recentMemory.Length -gt 500) { $recentMemory = $recentMemory.Substring(0,500) }
    if ($recentMemory) { $summary += "Recent memory: $recentMemory. " }
}

# SOUL.md heuristics
if (Test-Path '.copilot/workspace/SOUL.md') {
    $heuristics = (Select-String -Path '.copilot/workspace/SOUL.md' -Pattern 'heuristic|principle|rule|pattern' |
                   Select-Object -First 5 | ForEach-Object { $_.Line }) -join ' '
    if ($heuristics.Length -gt 300) { $heuristics = $heuristics.Substring(0,300) }
    if ($heuristics) { $summary += "Key heuristics: $heuristics. " }
}

# Git status snapshot
try {
    $gitStatus = & git status --porcelain 2>$null | Select-Object -First 10
    if ($gitStatus) {
        $modifiedCount = ($gitStatus | Measure-Object).Count
        $summary += "Git: $modifiedCount modified files. "
    }
} catch {}

# Truncate to safe length
if ($summary.Length -gt 2000) { $summary = $summary.Substring(0,2000) }

if ($summary) {
    [PSCustomObject]@{
        hookSpecificOutput = [PSCustomObject]@{
            hookEventName     = 'PreCompact'
            additionalContext = "Pre-compaction workspace snapshot: $summary"
        }
    } | ConvertTo-Json -Depth 5
} else {
    '{"continue": true}'
}
