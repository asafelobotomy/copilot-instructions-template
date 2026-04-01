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
$policyPath = Join-Path $PSScriptRoot 'heartbeat-policy.json'
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

function Get-DefaultPolicy {
    [ordered]@{
        retrospective = [ordered]@{
            thresholds = [ordered]@{
                modified_files = [ordered]@{
                    supporting = 5
                    strong = 8
                }
                elapsed_minutes = [ordered]@{
                    supporting = 15
                    strong = 30
                }
            }
            messages = [ordered]@{
                session_start_guidance = 'Open .copilot/workspace/HEARTBEAT.md and run the Checks section. Retrospective is optional: only run it when explicitly requested, or after a medium/large task once the user agrees.'
                explicit_system = 'Heartbeat trigger detected. Run HEARTBEAT.md checks now. Retrospective is optional unless explicitly requested or the user agrees after a medium/large task.'
                stop_prompt_question = 'That was a large change to the codebase, would you like me to run a retrospective?'
                accepted_reason = 'The user agreed to a retrospective. Run HEARTBEAT.md Retrospective now, persist any insights, then stop normally.'
            }
            transcript_complete_pattern = 'Q[1-5].*SOUL|Q[1-5].*MEMORY|Q[1-5].*USER|heartbeat-session.*complete'
        }
    }
}

function Get-Policy {
    if (Test-Path $policyPath) {
        try {
            $loaded = Get-Content $policyPath -Raw | ConvertFrom-Json -AsHashtable
            if ($null -ne $loaded) {
                return $loaded
            }
        } catch {}
    }
    return Get-DefaultPolicy
}

$defaultPolicy = Get-DefaultPolicy
$policy = Get-Policy
$retrospectivePolicy = if ($policy['retrospective']) { $policy['retrospective'] } else { $defaultPolicy['retrospective'] }
$retroThresholds = if ($retrospectivePolicy['thresholds']) { $retrospectivePolicy['thresholds'] } else { $defaultPolicy['retrospective']['thresholds'] }
$retroModifiedThresholds = if ($retroThresholds['modified_files']) { $retroThresholds['modified_files'] } else { $defaultPolicy['retrospective']['thresholds']['modified_files'] }
$retroElapsedThresholds = if ($retroThresholds['elapsed_minutes']) { $retroThresholds['elapsed_minutes'] } else { $defaultPolicy['retrospective']['thresholds']['elapsed_minutes'] }
$retroMessages = if ($retrospectivePolicy['messages']) { $retrospectivePolicy['messages'] } else { $defaultPolicy['retrospective']['messages'] }
$sessionStartGuidance = [string]($retroMessages['session_start_guidance'] ?? $defaultPolicy['retrospective']['messages']['session_start_guidance'])
$explicitSystemMessage = [string]($retroMessages['explicit_system'] ?? $defaultPolicy['retrospective']['messages']['explicit_system'])
$stopPromptQuestion = [string]($retroMessages['stop_prompt_question'] ?? $defaultPolicy['retrospective']['messages']['stop_prompt_question'])
$acceptedReason = [string]($retroMessages['accepted_reason'] ?? $defaultPolicy['retrospective']['messages']['accepted_reason'])
$retroTranscriptPattern = [string]($retrospectivePolicy['transcript_complete_pattern'] ?? $defaultPolicy['retrospective']['transcript_complete_pattern'])

function Emit-Json([object]$obj) {
    $obj | ConvertTo-Json -Depth 8 -Compress
}

function Get-DefaultState {
    [ordered]@{
        schema_version = 1
        session_id = 'unknown'
        session_state = 'pending'
        retrospective_state = 'idle'
        last_trigger = ''
        last_write_epoch = 0
        last_soft_trigger_epoch = 0
        last_compaction_epoch = 0
        last_explicit_epoch = 0
        session_start_epoch = 0
    }
}

function Get-State {
    $state = Get-DefaultState
    if (Test-Path $statePath) {
        try {
            $loaded = Get-Content $statePath -Raw | ConvertFrom-Json
            foreach ($k in @($state.Keys)) {
                $prop = $loaded.PSObject.Properties[$k]
                if ($null -ne $prop) { $state[$k] = $prop.Value }
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

function Convert-EpochToUtcString([int64]$Epoch) {
    [DateTimeOffset]::FromUnixTimeSeconds($Epoch).UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ')
}

function Append-Event([string]$name, [string]$detail = '', [nullable[int]]$DurationS = $null) {
    if (-not (Test-Path $workspace)) { return }
    $event = [ordered]@{ ts = $now; ts_utc = (Convert-EpochToUtcString $now); trigger = $name }
    if ($detail) { $event.detail = $detail }
    if ($null -ne $DurationS) { $event.duration_s = $DurationS }
    ($event | ConvertTo-Json -Depth 4 -Compress) + "`n" | Add-Content $eventsPath -Encoding utf8
}

function Get-SessionMedians {
    if (-not (Test-Path $eventsPath)) { return '' }
    $durations = @()
    try {
        foreach ($line in (Get-Content $eventsPath -Encoding utf8)) {
            if (-not $line.Trim()) { continue }
            try {
                $ev = $line | ConvertFrom-Json
                if ($ev.trigger -eq 'stop' -and $null -ne $ev.duration_s) {
                    $durations += [int]$ev.duration_s
                }
            } catch {}
        }
    } catch { return '' }
    if ($durations.Count -eq 0) { return '' }
    $sorted = $durations | Sort-Object
    $n = $sorted.Count
    $mid = [int]($n / 2)
    $median = if ($n % 2 -eq 0) { [int](($sorted[$mid - 1] + $sorted[$mid]) / 2) } else { $sorted[$mid] }
    $mins = [int]($median / 60)
    $secs = $median % 60
    $label = if ($mins -ge 1) { if ($secs -lt 30) { "~${mins}m" } else { "~$($mins + 1)m" } } else { "~${secs}s" }
    return "Typical session: $label (median of $n)."
}

function Invoke-PruneEvents([int]$Keep = 100) {
    if (-not (Test-Path $eventsPath)) { return }
    try {
        $lines = @(Get-Content $eventsPath -Encoding utf8 | Where-Object { $_.Trim() })
        if ($lines.Count -gt $Keep) {
            $start = $lines.Count - $Keep
            ($lines[$start..($lines.Count - 1)] -join "`n") + "`n" | Set-Content $eventsPath -Encoding utf8 -NoNewline
        }
    } catch {}
}

function Set-Sentinel([string]$sessionId, [string]$status) {
    if (-not (Test-Path $workspace)) { return }
    $ts = Convert-EpochToUtcString $now
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

function Get-GitModifiedFileCount {
    try {
        $statusLines = @(& git status --porcelain 2>$null | Where-Object { $_.Trim() })
        return $statusLines.Count
    } catch {
        return 0
    }
}

function Get-RetrospectiveState([hashtable]$state) {
    if ($state['retrospective_state']) { return [string]$state['retrospective_state'] }
    return 'idle'
}

function Get-RetrospectiveRecommendation([hashtable]$state) {
    $strongSignals = New-Object System.Collections.Generic.List[string]
    $supportingSignals = New-Object System.Collections.Generic.List[string]
    $basisSignals = New-Object System.Collections.Generic.List[string]
    $strongModified = [int]($retroModifiedThresholds['strong'] ?? 8)
    $supportingModified = [int]($retroModifiedThresholds['supporting'] ?? 5)
    $strongElapsedSeconds = [int]($retroElapsedThresholds['strong'] ?? 30) * 60
    $supportingElapsedSeconds = [int]($retroElapsedThresholds['supporting'] ?? 15) * 60
    $modifiedCount = Get-GitModifiedFileCount
    if ($modifiedCount -ge $strongModified) {
        $strongSignals.Add("$modifiedCount modified files")
    } elseif ($modifiedCount -ge $supportingModified) {
        $supportingSignals.Add("$modifiedCount modified files")
    }

    $startEpoch = if ($state['session_start_epoch']) { [int64]$state['session_start_epoch'] } else { 0 }
    if ($startEpoch -gt 0) {
        $durationS = [int]($now - $startEpoch)
        if ($durationS -lt 0) { $durationS = 0 }
        if ($durationS -ge $strongElapsedSeconds) {
            $strongSignals.Add("$([int]($durationS / 60))m elapsed")
        } elseif ($durationS -ge $supportingElapsedSeconds) {
            $supportingSignals.Add("$([int]($durationS / 60))m elapsed")
        }
        $lastCompaction = if ($state['last_compaction_epoch']) { [int64]$state['last_compaction_epoch'] } else { 0 }
        if ($lastCompaction -ge $startEpoch -and $lastCompaction -gt 0) {
            $supportingSignals.Add('context compaction occurred')
        }
    }

    foreach ($signal in $strongSignals) {
        $basisSignals.Add($signal)
    }
    foreach ($signal in $supportingSignals) {
        $basisSignals.Add($signal)
    }

    return [ordered]@{
        required = ($strongSignals.Count -gt 0 -or $supportingSignals.Count -ge 2)
        basis = ($basisSignals -join ', ')
    }
}

function Get-RetrospectiveResponse([string]$Prompt) {
    $normalized = $Prompt.Trim().ToLowerInvariant()
    $accepted = @('yes', 'yes please', 'yep', 'yeah', 'sure', 'ok', 'okay', 'please do', 'go ahead', 'do it', 'run it')
    $declined = @('no', 'no thanks', 'no thank you', 'nope', 'nah', 'skip', 'not now', "don't", 'do not')

    foreach ($phrase in $accepted) {
        if ($normalized -eq $phrase -or $normalized.StartsWith($phrase + ' ')) {
            return 'accepted'
        }
    }

    foreach ($phrase in $declined) {
        if ($normalized -eq $phrase -or $normalized.StartsWith($phrase + ' ')) {
            return 'declined'
        }
    }

    return 'unknown'
}

$state = Get-State
$providedId = if ($payload.sessionId) { [string]$payload.sessionId } else { '' }
$sessionId = if ($providedId) {
    $providedId
} elseif ($Trigger -eq 'session_start') {
    # Fallback: generate a local ID if VS Code does not provide one (should be rare).
    'local-' + [System.Guid]::NewGuid().ToString('N').Substring(0, 8)
} else {
    if ($state['session_id']) { [string]$state['session_id'] } else { 'unknown' }
}
$state.session_id = $sessionId
$state.last_trigger = $Trigger

if ($Trigger -eq 'session_start') {
    $state.session_state = 'pending'
    $state.retrospective_state = 'idle'
    $state.last_write_epoch = $now
    $state.session_start_epoch = $now
    Set-Sentinel $sessionId 'pending'
    Append-Event $Trigger
    Invoke-PruneEvents
    Save-State $state
    $dtStr = Convert-EpochToUtcString $now
    $timingHint = Get-SessionMedians
    $ctxParts = @("Session started at $dtStr.")
    if ($timingHint) { $ctxParts += $timingHint }
    $ctxParts += $sessionStartGuidance
    $additionalCtx = $ctxParts -join ' '
    Emit-Json @{ continue = $true; hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $additionalCtx } }
    exit 0
}

if ($Trigger -eq 'soft_post_tool') {
    $last = if ($state['last_soft_trigger_epoch']) { [int64]$state['last_soft_trigger_epoch'] } else { 0 }
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
    $retroState = Get-RetrospectiveState $state

    if ($retroState -eq 'suggested') {
        $retroResponse = Get-RetrospectiveResponse $prompt
        if ($retroResponse -eq 'accepted') {
            $state.retrospective_state = 'accepted'
            $state.last_write_epoch = $now
            Append-Event 'retrospective_response' 'accepted'
            Save-State $state
            Emit-Json @{ continue = $true }
            exit 0
        }
        if ($retroResponse -eq 'declined') {
            $state.retrospective_state = 'declined'
            $state.session_state = 'complete'
            $state.last_write_epoch = $now
            Append-Event 'retrospective_response' 'declined'
            Save-State $state
            Emit-Json @{ continue = $true }
            exit 0
        }
    }

    if ($prompt -match '(?i)\bretrospective\b' -and $prompt -notmatch "(?i)\b(no|skip|don't|do not)\b.*\bretrospective\b") {
        $state.retrospective_state = 'accepted'
    }

    if ($prompt -match '(?i)\b(heartbeat|retrospective|health check)\b') {
        $state.last_explicit_epoch = $now
        $state.last_write_epoch = $now
        Append-Event 'explicit_prompt'
        Save-State $state
        # Note: UserPromptSubmit has no hookSpecificOutput injection — systemMessage is a
        # UI-only chat banner; the model does not receive it. Model context injection is
        # only available on SessionStart via hookSpecificOutput.additionalContext.
        Emit-Json @{ continue = $true; systemMessage = $explicitSystemMessage }
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

    $retroState = Get-RetrospectiveState $state
    $retroRan = Test-SentinelComplete

    if (-not $retroRan -and $payload.transcript_path -and (Test-Path $payload.transcript_path)) {
        $content = Get-Content $payload.transcript_path -Raw -ErrorAction SilentlyContinue
        if ($content -match $retroTranscriptPattern) {
            $retroRan = $true
        }
    }

    if (-not $retroRan -and -not (Test-Path $sentinelPath) -and (Test-HeartbeatFresh 120)) {
        $retroRan = $true
    }

    $startEpoch = if ($state['session_start_epoch']) { [int64]$state['session_start_epoch'] } else { $now }
    $durationS = [int]($now - $startEpoch)
    if ($durationS -lt 0) { $durationS = 0 }

    if ($retroState -eq 'declined') {
        $state.session_state = 'complete'
        $state.last_write_epoch = $now
        Append-Event $Trigger 'declined' -DurationS $durationS
        Save-State $state
        Emit-Json @{ continue = $true }
        exit 0
    }

    if ($retroRan) {
        $state.session_state = 'complete'
        $state.retrospective_state = 'complete'
        $state.last_write_epoch = $now
        Set-Sentinel $sessionId 'complete'
        Append-Event $Trigger 'complete' -DurationS $durationS
        Save-State $state
        Emit-Json @{ continue = $true }
        exit 0
    }

    if ($retroState -eq 'accepted') {
        $state.session_state = 'pending'
        $state.last_write_epoch = $now
        Append-Event $Trigger 'accepted-pending'
        Save-State $state
        Emit-Json @{
            hookSpecificOutput = @{
                hookEventName = 'Stop'
                decision = 'block'
                reason = $acceptedReason
            }
        }
        exit 0
    }

    $retroRecommendation = Get-RetrospectiveRecommendation $state
    if ($retroRecommendation.required -eq $true) {
        $state.session_state = 'pending'
        $state.retrospective_state = 'suggested'
        $state.last_write_epoch = $now
        Append-Event $Trigger 'suggested'
        Save-State $state
        Emit-Json @{
            hookSpecificOutput = @{
                hookEventName = 'Stop'
                decision = 'block'
                reason = "This looks like a medium/large task ($($retroRecommendation.basis)). Ask the user: `"$stopPromptQuestion`" Run HEARTBEAT.md Retrospective only if they agree."
            }
        }
        exit 0
    }

    $state.session_state = 'complete'
    $state.retrospective_state = 'not-needed'
    $state.last_write_epoch = $now
    Append-Event $Trigger 'not-needed' -DurationS $durationS
    Save-State $state
    Emit-Json @{ continue = $true }
    exit 0
}

Emit-Json @{ continue = $true }