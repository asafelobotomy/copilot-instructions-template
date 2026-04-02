# purpose:  Dispatch PowerShell heartbeat trigger state and retrospective gating.
# when:     Invoked by pulse.ps1 after reading stdin.
# inputs:   -Trigger <session_start|soft_post_tool|compaction|stop|user_prompt|explicit> and raw JSON payload.
# outputs:  JSON hook response (`continue` or Stop `decision:block`).
# risk:     safe

[CmdletBinding()]
param(
    [string]$Trigger = '',
    [string]$InputJson = ''
)

$ErrorActionPreference = 'SilentlyContinue'

if (-not $Trigger) {
    '{"continue": true}'
    exit 0
}

try {
    $payload = if ($InputJson.Trim()) {
        $InputJson | ConvertFrom-Json
    } else {
        [PSCustomObject]@{}
    }
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

. (Join-Path $PSScriptRoot 'pulse_state.ps1')
. (Join-Path $PSScriptRoot 'pulse_paths.ps1')
. (Join-Path $PSScriptRoot 'pulse_intent.ps1')

function Write-JsonOutput([object]$Object) {
    $Object | ConvertTo-Json -Depth 8 -Compress
}

$defaultPolicy = Get-DefaultPolicy
$policy = Get-Policy
$retrospectivePolicy = if ($policy['retrospective']) { $policy['retrospective'] } else { $defaultPolicy['retrospective'] }
$retroThresholds = if ($retrospectivePolicy['thresholds']) { $retrospectivePolicy['thresholds'] } else { $defaultPolicy['retrospective']['thresholds'] }
$retroModifiedThresholds = if ($retroThresholds['modified_files']) { $retroThresholds['modified_files'] } else { $defaultPolicy['retrospective']['thresholds']['modified_files'] }
$retroElapsedThresholds = if ($retroThresholds['elapsed_minutes']) { $retroThresholds['elapsed_minutes'] } else { $defaultPolicy['retrospective']['thresholds']['elapsed_minutes'] }
$idleGapMinutes = [int]($retroThresholds['idle_gap_minutes'] ?? 10)
$healthDigestConfig = if ($retrospectivePolicy['health_digest']) { $retrospectivePolicy['health_digest'] } else { $defaultPolicy['retrospective']['health_digest'] }
$healthDigestMinSpacingSeconds = [int]($healthDigestConfig['min_emit_spacing_seconds'] ?? 120)
$retroMessages = if ($retrospectivePolicy['messages']) { $retrospectivePolicy['messages'] } else { $defaultPolicy['retrospective']['messages'] }
$sessionStartGuidance = [string]($retroMessages['session_start_guidance'] ?? $defaultPolicy['retrospective']['messages']['session_start_guidance'])
$explicitSystemMessage = [string]($retroMessages['explicit_system'] ?? $defaultPolicy['retrospective']['messages']['explicit_system'])
$stopReflectInstruction = [string]($retroMessages['stop_reflect_instruction'] ?? $defaultPolicy['retrospective']['messages']['stop_reflect_instruction'])
$acceptedReason = [string]($retroMessages['accepted_reason'] ?? $defaultPolicy['retrospective']['messages']['accepted_reason'])
$retroTranscriptPattern = [string]($retrospectivePolicy['transcript_complete_pattern'] ?? $defaultPolicy['retrospective']['transcript_complete_pattern'])

$state = Get-State
$providedId = if ($payload.sessionId) { [string]$payload.sessionId } else { '' }
$sessionId = if ($providedId) {
    $providedId
} elseif ($Trigger -eq 'session_start') {
    'local-' + [System.Guid]::NewGuid().ToString('N').Substring(0, 8)
} else {
    if ($state['session_id']) { [string]$state['session_id'] } else { 'unknown' }
}
$state.session_id = $sessionId
$state.last_trigger = $Trigger

if ($Trigger -eq 'session_start') {
    $priors = Get-SessionPriors
    $state.session_state = 'pending'
    $state.retrospective_state = 'idle'
    $state.last_write_epoch = $now
    $state.session_start_epoch = $now
    $state.session_start_git_count = Get-GitModifiedFileCount
    $state.task_window_start_epoch = 0
    $state.last_raw_tool_epoch = 0
    $state.active_work_seconds = 0
    $state.copilot_edit_count = 0
    $state.tool_call_counter = 0
    $state.intent_phase = 'quiet'
    $state.intent_phase_epoch = $now
    $state.intent_phase_version = 1
    $state.last_digest_key = ''
    $state.last_digest_epoch = 0
    $state.digest_emit_count = 0
    $state.overlay_sensitive_surface = $false
    $state.overlay_parity_required = $false
    $state.overlay_verification_expected = $false
    $state.overlay_decision_capture_needed = $false
    $state.overlay_retro_requested = $false
    $state.signal_edit_started = $false
    $state.signal_scope_supporting = $false
    $state.signal_scope_strong = $false
    $state.signal_work_supporting = $false
    $state.signal_work_strong = $false
    $state.signal_compaction_seen = $false
    $state.signal_idle_reset_seen = $false
    $state.signal_cross_cutting = $false
    $state.signal_scope_widening = $false
    $state.signal_reflection_likely = $false
    $state.changed_path_families = @()
    $state.touched_files_sample = @()
    $state.unique_touched_file_count = 0
    foreach ($key in @($priors.Keys)) {
        $state[$key] = $priors[$key]
    }
    Set-Sentinel $sessionId 'pending'
    Add-HeartbeatEvent $Trigger
    Invoke-PruneEvents
    Save-State $state
    $dtStr = Convert-EpochToUtcString $now
    $timingHint = Get-SessionMedians
    $ctxParts = @("Session started at $dtStr.")
    if ($timingHint) { $ctxParts += $timingHint }
    $ctxParts += $sessionStartGuidance
    $additionalCtx = $ctxParts -join ' '
    Write-JsonOutput @{ continue = $true; hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $additionalCtx } }
    exit 0
}

if ($Trigger -eq 'soft_post_tool') {
    $fileWritingTools = @('create_file', 'replace_string_in_file', 'multi_replace_string_in_file', 'editFiles', 'writeFile')
    $toolName = [string]($payload.tool_name ?? '')
    if ($fileWritingTools -contains $toolName) {
        $state.copilot_edit_count = [int]($state['copilot_edit_count'] ?? 0) + 1
    }

    $idleGapS = $idleGapMinutes * 60
    $taskWindowStart = [int64]($state['task_window_start_epoch'] ?? 0)
    $lastTool = [int64]($state['last_raw_tool_epoch'] ?? 0)
    if ($taskWindowStart -eq 0) {
        $state.task_window_start_epoch = $now
    } elseif ($lastTool -gt 0 -and ($now - $lastTool) -gt $idleGapS) {
        $windowS = [Math]::Max(0, $lastTool - $taskWindowStart)
        $state.active_work_seconds = [int]($state['active_work_seconds'] ?? 0) + $windowS
        $state.task_window_start_epoch = $now
        $state.signal_idle_reset_seen = $true
    }
    $state.last_raw_tool_epoch = $now
    $state.last_write_epoch = $now
    $state.tool_call_counter = [int]($state['tool_call_counter'] ?? 0) + 1

    $last = [int64]($state['last_soft_trigger_epoch'] ?? 0)
    if (($now - $last) -ge 300) {
        $state.last_soft_trigger_epoch = $now
        Add-HeartbeatEvent $Trigger
    }

    $intentUpdate = Update-IntentEngine $state $payload $true
    $state = $intentUpdate['state']
    $digest = [string]($intentUpdate['digest'] ?? '')
    Save-State $state

    if ($digest) {
        Write-JsonOutput @{ continue = $true; hookSpecificOutput = @{ hookEventName = 'PostToolUse'; additionalContext = $digest } }
    } else {
        Write-JsonOutput @{ continue = $true }
    }
    exit 0
}

if ($Trigger -eq 'compaction') {
    $state = Close-WorkWindow $state
    $state.last_compaction_epoch = $now
    $state.last_write_epoch = $now
    Add-HeartbeatEvent $Trigger
    $intentUpdate = Update-IntentEngine $state $null $false
    $state = $intentUpdate['state']
    Save-State $state
    Write-JsonOutput @{ continue = $true }
    exit 0
}

if ($Trigger -in @('user_prompt', 'explicit')) {
    $prompt = [string]($payload.prompt ?? '')
    $retrospectiveRequested = Test-RetrospectiveRequest $prompt
    $heartbeatRequested = Test-HeartbeatRequest $prompt

    if ($retrospectiveRequested) {
        $state.retrospective_state = 'accepted'
    }

    if ($heartbeatRequested -or $retrospectiveRequested) {
        $state.last_explicit_epoch = $now
        $state.last_write_epoch = $now
        Add-HeartbeatEvent 'explicit_prompt' $(if ($heartbeatRequested) { 'heartbeat' } else { 'retrospective' })
        $intentUpdate = Update-IntentEngine $state $null $false
        $state = $intentUpdate['state']
        Save-State $state
        if ($heartbeatRequested) {
            Write-JsonOutput @{ continue = $true; systemMessage = $explicitSystemMessage }
        } else {
            Write-JsonOutput @{ continue = $true }
        }
    } else {
        Write-JsonOutput @{ continue = $true }
    }
    exit 0
}

if ($Trigger -eq 'stop') {
    if ($payload.stop_hook_active -eq $true) {
        Write-JsonOutput @{ continue = $true }
        exit 0
    }

    $state = Close-WorkWindow $state
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

    if ($retroRan) {
        $state.session_state = 'complete'
        $state.retrospective_state = 'complete'
        $state.last_write_epoch = $now
        Set-Sentinel $sessionId 'complete'
        Add-HeartbeatEvent $Trigger 'complete' -DurationS $durationS
        Save-State $state
        Write-JsonOutput @{ continue = $true }
        exit 0
    }

    $retroState = Get-RetrospectiveState $state
    if ($retroState -eq 'accepted') {
        $state.session_state = 'pending'
        $state.last_write_epoch = $now
        Add-HeartbeatEvent $Trigger 'accepted-pending'
        Save-State $state
        Write-JsonOutput @{
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
        Add-HeartbeatEvent $Trigger 'reflect-needed'
        Save-State $state
        Write-JsonOutput @{
            hookSpecificOutput = @{
                hookEventName = 'Stop'
                decision = 'block'
                reason = "Significant session ($($retroRecommendation.basis)). $stopReflectInstruction"
            }
        }
        exit 0
    }

    $state.session_state = 'complete'
    $state.retrospective_state = 'not-needed'
    $state.last_write_epoch = $now
    Add-HeartbeatEvent $Trigger 'not-needed' -DurationS $durationS
    Save-State $state
    Write-JsonOutput @{ continue = $true }
    exit 0
}

Write-JsonOutput @{ continue = $true }
