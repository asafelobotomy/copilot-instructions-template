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
try {
    $payload = if ($inputJson.Trim()) { $inputJson | ConvertFrom-Json } else { [PSCustomObject]@{} }
} catch {
    $payload = [PSCustomObject]@{}
}

$workspace = '.copilot/workspace'
$statePath = Join-Path $workspace 'state.json'
$sentinelPath = Join-Path $workspace '.heartbeat-session'
$eventsPath = Join-Path $workspace '.heartbeat-events.jsonl'
$heartbeatPath = Join-Path $workspace 'HEARTBEAT.md'
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

function Emit-Json([object]$obj) {
    $obj | ConvertTo-Json -Depth 8 -Compress
}

function Get-DefaultState {
    [ordered]@{
        schema_version = 1
        session_id = 'unknown'
        session_state = 'pending'
        last_trigger = ''
        last_write_epoch = 0
        last_soft_trigger_epoch = 0
        last_compaction_epoch = 0
        last_explicit_epoch = 0
    }
}

function Get-State {
    $state = Get-DefaultState
    if (Test-Path $statePath) {
        try {
            $loaded = Get-Content $statePath -Raw | ConvertFrom-Json
            foreach ($k in $state.Keys) {
                if ($null -ne $loaded.$k) { $state[$k] = $loaded.$k }
            }
        } catch {
            # Corrupt state should not break hooks.
        }
    }
    return $state
}

function Save-State([hashtable]$state) {
    if (-not (Test-Path $workspace)) { return }
    $tmp = "$statePath.tmp"
    ($state | ConvertTo-Json -Depth 8) + "`n" | Set-Content $tmp -Encoding utf8 -NoNewline
    Move-Item -Force $tmp $statePath
}

function Append-Event([string]$name, [string]$detail = '') {
    if (-not (Test-Path $workspace)) { return }
    $event = [ordered]@{ ts = $now; trigger = $name }
    if ($detail) { $event.detail = $detail }
    ($event | ConvertTo-Json -Depth 4 -Compress) + "`n" | Add-Content $eventsPath -Encoding utf8
}

function Set-Sentinel([string]$sessionId, [string]$status) {
    if (-not (Test-Path $workspace)) { return }
    $ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    "$sessionId|$ts|$status" | Set-Content $sentinelPath -Encoding utf8 -NoNewline
}

function Test-SentinelComplete {
    if (-not (Test-Path $sentinelPath)) { return $false }
    try {
        $line = (Get-Content $sentinelPath -Raw).Trim()
        $parts = $line -split '\|'
        return ($parts.Count -ge 3 -and $parts[2] -eq 'complete')
    } catch {
        return $false
    }
}

function Test-HeartbeatFresh([int]$minutes) {
    if (-not (Test-Path $heartbeatPath)) { return $false }
    try {
        $mtime = (Get-Item $heartbeatPath).LastWriteTimeUtc
        return ((Get-Date).ToUniversalTime() - $mtime -lt [TimeSpan]::FromMinutes($minutes))
    } catch {
        return $false
    }
}

$state = Get-State
$providedId = if ($payload.sessionId) { [string]$payload.sessionId } else { '' }
$sessionId = if ($providedId) {
    $providedId
} elseif ($Trigger -eq 'session_start') {
    # Fallback: generate a local ID if VS Code does not provide one (should be rare).
    'local-' + [System.Guid]::NewGuid().ToString('N').Substring(0, 8)
} else {
    if ($state.session_id) { [string]$state.session_id } else { 'unknown' }
}
$state.session_id = $sessionId
$state.last_trigger = $Trigger

if ($Trigger -eq 'session_start') {
    $state.session_state = 'pending'
    $state.last_write_epoch = $now
    Set-Sentinel $sessionId 'pending'
    Append-Event $Trigger
    Save-State $state
    Emit-Json @{ continue = $true; hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = 'Session started. Open .copilot/workspace/HEARTBEAT.md, run all checks, answer Retrospective Q1-Q8, persist insights to SOUL.md / MEMORY.md / USER.md, mark the sentinel complete, and append a History row.' } }
    exit 0
}

if ($Trigger -eq 'soft_post_tool') {
    $last = [int64]$state.last_soft_trigger_epoch
    if (($now - $last) -lt 300) {
        Emit-Json @{ continue = $true }
        exit 0
    }
    $state.last_soft_trigger_epoch = $now
    $state.last_write_epoch = $now
    Append-Event $Trigger
    Save-State $state
    Emit-Json @{ continue = $true }
    exit 0
}

if ($Trigger -eq 'compaction') {
    $state.last_compaction_epoch = $now
    $state.last_write_epoch = $now
    Append-Event $Trigger
    Save-State $state
    Emit-Json @{ continue = $true }
    exit 0
}

if ($Trigger -in @('user_prompt', 'explicit')) {
    $prompt = [string]($payload.prompt ?? '')
    if ($prompt -match '(?i)\b(heartbeat|retrospective|health check)\b') {
        $state.last_explicit_epoch = $now
        $state.last_write_epoch = $now
        Append-Event 'explicit_prompt'
        Save-State $state
        # Note: UserPromptSubmit has no hookSpecificOutput injection — systemMessage is a
        # UI-only chat banner; the model does not receive it. Model context injection is
        # only available on SessionStart via hookSpecificOutput.additionalContext.
        Emit-Json @{ continue = $true; systemMessage = 'Heartbeat trigger detected. Run HEARTBEAT.md protocol now: run all checks, answer Retrospective Q1-Q8, persist insights to SOUL.md / MEMORY.md / USER.md, mark the sentinel complete, and append a History row.' }
    } else {
        Emit-Json @{ continue = $true }
    }
    exit 0
}

if ($Trigger -eq 'stop') {
    if ($payload.stop_hook_active -eq $true) {
        Emit-Json @{ continue = $true }
        exit 0
    }

    $retroRan = Test-SentinelComplete

    if (-not $retroRan -and $payload.transcript_path -and (Test-Path $payload.transcript_path)) {
        $content = Get-Content $payload.transcript_path -Raw -ErrorAction SilentlyContinue
        if ($content -match '(?i)Q[1-8].*SOUL|Q[1-8].*MEMORY|Q[1-8].*USER|heartbeat-session.*complete') {
            $retroRan = $true
        }
    }

    if (-not $retroRan -and -not (Test-Path $sentinelPath) -and (Test-HeartbeatFresh 120)) {
        $retroRan = $true
    }

    if ($retroRan) {
        $state.session_state = 'complete'
        $state.last_write_epoch = $now
        Set-Sentinel $sessionId 'complete'
        Append-Event $Trigger 'complete'
        Save-State $state
        Emit-Json @{ continue = $true }
        exit 0
    }

    $state.session_state = 'pending'
    $state.last_write_epoch = $now
    Append-Event $Trigger 'blocked'
    Save-State $state
    Emit-Json @{
        hookSpecificOutput = @{
            hookEventName = 'Stop'
            decision = 'block'
            reason = 'The retrospective has not been run this session. Before stopping, run HEARTBEAT.md Retrospective, persist insights, then mark .copilot/workspace/.heartbeat-session as complete.'
        }
    }
    exit 0
}

Emit-Json @{ continue = $true }