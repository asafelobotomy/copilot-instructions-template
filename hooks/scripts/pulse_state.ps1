#!/usr/bin/env pwsh
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
                idle_gap_minutes = 10
            }
            health_digest = [ordered]@{
                min_emit_spacing_seconds = 120
            }
            messages = [ordered]@{
                session_start_guidance = 'Run HEARTBEAT.md Checks. When thresholds are met, call session_reflect before the session ends.'
                explicit_system = 'Heartbeat triggered. Run HEARTBEAT.md checks.'
                post_tool_reflect_instruction = 'Significant session detected. Call session_reflect now → process silently → continue. If MCP unavailable: review accuracy, scope, identity file persistence.'
                stop_reflect_instruction = 'Call session_reflect → process silently → stop. If MCP unavailable: review accuracy, scope, identity file persistence. Retry session_reflect when restored.'
                accepted_reason = 'User requested retrospective. session_reflect → process → persist → stop.'
            }
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
        session_start_git_count = 0
        task_window_start_epoch = 0
        last_raw_tool_epoch = 0
        active_work_seconds = 0
        copilot_edit_count = 0
        tool_call_counter = 0
        intent_phase = 'quiet'
        intent_phase_epoch = 0
        intent_phase_version = 1
        last_digest_key = ''
        last_digest_epoch = 0
        digest_emit_count = 0
        overlay_sensitive_surface = $false
        overlay_parity_required = $false
        overlay_verification_expected = $false
        overlay_decision_capture_needed = $false
        overlay_retro_requested = $false
        signal_edit_started = $false
        signal_scope_supporting = $false
        signal_scope_strong = $false
        signal_work_supporting = $false
        signal_work_strong = $false
        signal_compaction_seen = $false
        signal_idle_reset_seen = $false
        signal_cross_cutting = $false
        signal_scope_widening = $false
        signal_reflection_likely = $false
        reflect_instruction_emitted = $false
        route_candidate = ''
        route_reason = ''
        route_confidence = 0.0
        route_source = ''
        route_emitted = $false
        route_epoch = 0
        route_last_hint_epoch = 0
        route_emitted_agents = @()
        route_signal_counts = [ordered]@{}
        changed_path_families = @()
        touched_files_sample = @()
        unique_touched_file_count = 0
        prior_small_batches = $false
        prior_explicitness = $false
        prior_reversibility = $false
        prior_baseline_sensitive = $false
        prior_research_first = $false
        prior_non_interruptive_ux = $false
    }
}

function Get-HeartbeatArtifactPaths([string]$Path) {
    $candidates = [System.Collections.Generic.List[string]]::new()
    $candidates.Add($Path)
    try {
        $repoRoot = (Get-Item $workspace -ErrorAction SilentlyContinue)?.Parent?.Parent?.FullName
        if (-not $repoRoot) { $repoRoot = (Get-Location).Path }
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($repoRoot)
        $hash = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').Substring(0, 12).ToLower()
        $name = [System.IO.Path]::GetFileName($Path)
        $roots = [System.Collections.Generic.List[string]]::new()
        $claudeTmp = $env:CLAUDE_TMPDIR
        if ($claudeTmp) { $roots.Add($claudeTmp) }
        $envTmp = $env:TMPDIR
        if ($envTmp) { $roots.Add($envTmp) }
        $sysTmp = [System.IO.Path]::GetTempPath().TrimEnd([char][System.IO.Path]::DirectorySeparatorChar)
        if ($sysTmp -and $sysTmp -notin $roots) { $roots.Add($sysTmp) }
        foreach ($root in $roots) {
            $candidate = [System.IO.Path]::Combine($root, 'copilot-heartbeat', $hash, $name)
            if ($candidate -notin $candidates) { $candidates.Add($candidate) }
        }
    } catch {}
    return $candidates
}

function Get-State {
    $state = Get-DefaultState
    foreach ($candidate in (Get-HeartbeatArtifactPaths $statePath)) {
        if (-not (Test-Path $candidate)) { continue }
        try {
            $loaded = Get-Content $candidate -Raw | ConvertFrom-Json
            foreach ($key in @($state.Keys)) {
                $property = $loaded.PSObject.Properties[$key]
                if ($null -ne $property) {
                    $state[$key] = $property.Value
                }
            }
            return $state
        } catch {}
    }
    return $state
}

function Save-State([hashtable]$State) {
    $text = ($State | ConvertTo-Json -Depth 8) + "`n"
    foreach ($candidate in (Get-HeartbeatArtifactPaths $statePath)) {
        try {
            $dir = Split-Path $candidate
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $tmp = "$candidate.tmp"
            $text | Set-Content $tmp -Encoding utf8 -NoNewline
            Move-Item -Force $tmp $candidate
            return
        } catch {}
    }
}

function Convert-EpochToUtcString([int64]$Epoch) {
    [DateTimeOffset]::FromUnixTimeSeconds($Epoch).UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ')
}

function Add-HeartbeatEvent([string]$Name, [string]$Detail = '', [nullable[int]]$DurationS = $null) {
    $eventRecord = [ordered]@{ ts = $now; ts_utc = (Convert-EpochToUtcString $now); trigger = $Name }
    if ($Detail) { $eventRecord.detail = $Detail }
    if ($null -ne $DurationS) { $eventRecord.duration_s = $DurationS }
    if ($sessionId) { $eventRecord.session_id = [string]$sessionId }
    $line = ($eventRecord | ConvertTo-Json -Depth 4 -Compress) + "`n"
    foreach ($candidate in (Get-HeartbeatArtifactPaths $eventsPath)) {
        try {
            $dir = Split-Path $candidate
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $line | Add-Content $candidate -Encoding utf8
            return
        } catch {}
    }
}

function Get-SessionMedians {
    if (-not (Test-Path $eventsPath)) { return '' }
    $durations = @()
    try {
        foreach ($line in (Get-Content $eventsPath -Encoding utf8)) {
            if (-not $line.Trim()) { continue }
            try {
                $parsedEvent = $line | ConvertFrom-Json
                if ($parsedEvent.trigger -eq 'stop' -and $null -ne $parsedEvent.duration_s) {
                    $durations += [int]$parsedEvent.duration_s
                }
            } catch {}
        }
    } catch { return '' }
    if ($durations.Count -eq 0) { return '' }
    $sorted = $durations | Sort-Object
    $count = $sorted.Count
    $mid = [int]($count / 2)
    $median = if ($count % 2 -eq 0) {
        [int](($sorted[$mid - 1] + $sorted[$mid]) / 2)
    } else {
        $sorted[$mid]
    }
    $mins = [int]($median / 60)
    $secs = $median % 60
    $label = if ($mins -ge 1) {
        if ($secs -lt 30) { "~${mins}m" } else { "~$($mins + 1)m" }
    } else {
        "~${secs}s"
    }
    return "Typical session: $label (median of $count)."
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

function Set-Sentinel([string]$SessionId, [string]$Status) {
    $ts = Convert-EpochToUtcString $now
    $content = "$SessionId|$ts|$Status"
    foreach ($candidate in (Get-HeartbeatArtifactPaths $sentinelPath)) {
        try {
            $dir = Split-Path $candidate
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $content | Set-Content $candidate -Encoding utf8 -NoNewline
            return
        } catch {}
    }
}

function Test-SentinelComplete([string]$SessionId = '') {
    foreach ($candidate in (Get-HeartbeatArtifactPaths $sentinelPath)) {
        if (-not (Test-Path $candidate)) { continue }
        try {
            $line = (Get-Content $candidate -Raw).Trim()
            $parts = $line -split '\|'
            if ($parts.Count -ge 3 -and $parts[2] -eq 'complete') {
                if ($SessionId -and $parts[0] -ne $SessionId) { continue }
                return $true
            }
        } catch {}
    }
    return $false
}

function Test-ReflectionComplete([string]$SessionId, [int64]$SessionStartEpoch) {
    if (-not (Test-Path $eventsPath)) { return $false }
    try {
        $lines = @(Get-Content $eventsPath -Encoding utf8)
    } catch {
        return $false
    }
    for ($index = $lines.Count - 1; $index -ge 0; $index--) {
        $line = [string]$lines[$index]
        if (-not $line.Trim()) { continue }
        try {
            $event = $line | ConvertFrom-Json -AsHashtable
        } catch {
            continue
        }
        if ($event['trigger'] -ne 'session_reflect' -or $event['detail'] -ne 'complete') {
            continue
        }
        $eventSessionId = [string]($event['session_id'] ?? '')
        if ($eventSessionId) {
            return $eventSessionId -eq $SessionId
        }
        $eventTs = $event['ts']
        if ($SessionStartEpoch -gt 0 -and $null -ne $eventTs) {
            return [int64]$eventTs -ge $SessionStartEpoch
        }
    }
    return $false
}

function Test-HeartbeatFresh([int]$Minutes) {
    if (-not (Test-Path $heartbeatPath)) { return $false }
    try {
        $mtime = (Get-Item $heartbeatPath).LastWriteTimeUtc
        return ((Get-Date).ToUniversalTime() - $mtime -lt [TimeSpan]::FromMinutes($Minutes))
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

function Read-WorkspaceFile([string]$Name, [int]$Limit = 4000) {
    $path = Join-Path $workspace $Name
    if (-not (Test-Path $path)) { return '' }
    try {
        $text = [string](Get-Content $path -Raw -Encoding utf8)
        if ($text.Length -gt $Limit) {
            return $text.Substring(0, $Limit)
        }
        return $text
    } catch {
        return ''
    }
}

function Get-SessionPriors {
    $soul = ([string](Read-WorkspaceFile 'identity/SOUL.md')).ToLowerInvariant()
    $user = ([string](Read-WorkspaceFile 'knowledge/USER.md')).ToLowerInvariant()
    return [ordered]@{
        prior_small_batches = $soul.Contains('small batches')
        prior_explicitness = $soul.Contains('explicit over implicit')
        prior_reversibility = $soul.Contains('reversibility')
        prior_baseline_sensitive = $soul.Contains('baselines')
        prior_research_first = ($user.Contains('research and design confirmation') -or $user.Contains('investigation preference'))
        prior_non_interruptive_ux = ($user.Contains('dislikes disruptive') -or $user.Contains('non-blocking'))
    }
}

function Get-RetrospectiveState([hashtable]$State) {
    if ($State['retrospective_state']) { return [string]$State['retrospective_state'] }
    return 'idle'
}

function Test-RetrospectiveRequest([string]$Prompt) {
    if ($Prompt -notmatch '(?i)\bretrospective\b') { return $false }
    if ($Prompt -match "(?i)\b(no|skip|don't|do not|not now)\b.*\bretrospective\b") { return $false }
    if ($Prompt -match '(?i)\b(explain|review|describe|summari[sz]e|discuss|compare|analy[sz]e|policy|threshold|logic|docs?|documentation|rules?)\b') { return $false }
    return (
        $Prompt -match '(?i)^\s*retrospective(?:\s+(?:now|please))?\s*[?.!]*$' -or
        $Prompt -match '(?i)^\s*(run|do|start|perform)\s+(a\s+)?retrospective\b' -or
        $Prompt -match '(?i)\b(run|do|start|perform)\b.*\bretrospective\b' -or
        $Prompt -match '(?i)\b(can|could|would)\s+you\b.*\b(run|do|start|perform)\b.*\bretrospective\b' -or
        $Prompt -match '(?i)\bplease\b.*\b(run|do|start|perform)\b.*\bretrospective\b'
    )
}

function Test-HeartbeatRequest([string]$Prompt) {
    if ($Prompt -match "(?i)\b(no|skip|don't|do not)\b.*\b(heartbeat|health check)\b") { return $false }
    if ($Prompt -match '(?i)\b(explain|review|describe|summari[sz]e|discuss|compare|analy[sz]e|policy|threshold|logic|docs?|documentation|rules?)\b') { return $false }
    return (
        $Prompt -match '(?i)^\s*heartbeat(?:\s+now)?\s*[?.!]*$' -or
        $Prompt -match '(?i)^\s*(check|run)\s+(your\s+)?heartbeat\b' -or
        $Prompt -match '(?i)\b(check|run)\b.*\bheartbeat\b' -or
        $Prompt -match '(?i)\b(run|do)\b.*\bhealth check\b' -or
        $Prompt -match '(?i)\b(can|could|would)\s+you\b.*\b(check|run|do)\b.*\b(heartbeat|health check)\b'
    )
}

function Close-WorkWindow([hashtable]$State) {
    $taskWindowStart = [int64]($State['task_window_start_epoch'] ?? 0)
    $lastTool = [int64]($State['last_raw_tool_epoch'] ?? 0)
    if ($taskWindowStart -gt 0 -and $lastTool -ge $taskWindowStart) {
        $windowS = [Math]::Max(0, $lastTool - $taskWindowStart)
        $State['active_work_seconds'] = [int]($State['active_work_seconds'] ?? 0) + $windowS
        $State['task_window_start_epoch'] = 0
    }
    return $State
}

function Get-RetrospectiveRecommendation([hashtable]$State) {
    $strongSignals = New-Object System.Collections.Generic.List[string]
    $supportingSignals = New-Object System.Collections.Generic.List[string]
    $basisSignals = New-Object System.Collections.Generic.List[string]
    $strongModified = [int]($retroModifiedThresholds['strong'] ?? 8)
    $supportingModified = [int]($retroModifiedThresholds['supporting'] ?? 5)
    $strongElapsedMinutes = [int]($retroElapsedThresholds['strong'] ?? 30)
    $supportingElapsedMinutes = [int]($retroElapsedThresholds['supporting'] ?? 15)

    $sessionStartCount = [int]($State['session_start_git_count'] ?? 0)
    $currentCount = Get-GitModifiedFileCount
    $deltaFiles = [Math]::Max(0, $currentCount - $sessionStartCount)
    $editCount = [int]($State['copilot_edit_count'] ?? 0)
    $effectiveFiles = if ($deltaFiles -gt 0) { $deltaFiles } else { $editCount }

    if ($effectiveFiles -eq 0) {
        return [ordered]@{ required = $false; basis = 'no files changed this session' }
    }

    $fileLabel = if ($deltaFiles -gt 0) { 'files changed this session' } else { 'files edited (previously committed)' }
    if ($effectiveFiles -ge $strongModified) {
        $strongSignals.Add("$effectiveFiles $fileLabel")
    } elseif ($effectiveFiles -ge $supportingModified) {
        $supportingSignals.Add("$effectiveFiles $fileLabel")
    }

    $activeS = [int]($State['active_work_seconds'] ?? 0)
    $activeMinutes = [int]($activeS / 60)
    if ($activeMinutes -ge $strongElapsedMinutes) {
        $strongSignals.Add("${activeMinutes}m active work")
    } elseif ($activeMinutes -ge $supportingElapsedMinutes) {
        $supportingSignals.Add("${activeMinutes}m active work")
    }

    $startEpoch = [int64]($State['session_start_epoch'] ?? 0)
    $lastCompaction = [int64]($State['last_compaction_epoch'] ?? 0)
    if ($startEpoch -gt 0 -and $lastCompaction -ge $startEpoch) {
        $supportingSignals.Add('context compaction occurred')
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
