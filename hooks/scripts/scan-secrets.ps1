# purpose:  Scan modified files for leaked secrets at session end
# when:     Stop hook — fires when the agent session ends
# inputs:   JSON via stdin
# outputs:  JSON continuation signal on stdout; diagnostics on stderr
# risk:     read-only
# ESCALATION: block
# STOP LOOP: if stop_hook_active is true in the Stop payload, do not re-enter blocking Stop logic.

$ErrorActionPreference = 'SilentlyContinue'
$inputJson = $input | Out-String

$stopHookActive = $false
if ($inputJson) {
    try {
        $payload = $inputJson | ConvertFrom-Json -ErrorAction Stop
        if ($payload.stop_hook_active -eq $true) {
            $stopHookActive = $true
        }
    } catch {
        $stopHookActive = $false
    }
}

if ($stopHookActive) {
    '{"continue": true}'; exit 0
}

# ---------------------------------------------------------------------------
# Concurrency guard — prevent duplicate scans from overlapping Stop cycles
# ---------------------------------------------------------------------------
$lockDir = if ($env:SECRETS_LOG_DIR) { $env:SECRETS_LOG_DIR } else { 'logs/secrets' }
if (-not (Test-Path $lockDir)) { New-Item -ItemType Directory -Path $lockDir -Force | Out-Null }
$lockFile = Join-Path $lockDir '.scan-secrets.lock'

function Remove-ScanLock { Remove-Item $lockFile -ErrorAction SilentlyContinue }

if (Test-Path $lockFile) {
    $lockPid = Get-Content $lockFile -ErrorAction SilentlyContinue
    $lockAlive = $false
    if ($lockPid) {
        try { $lockAlive = [bool](Get-Process -Id ([int]$lockPid) -ErrorAction Stop) } catch { $lockAlive = $false }
    }
    if ($lockAlive) {
        Write-Error "Scan already in progress — check that terminal for results."
        '{"continue": true}'; exit 0
    }
    Remove-Item $lockFile -ErrorAction SilentlyContinue
}
$PID | Set-Content $lockFile -ErrorAction SilentlyContinue
try {

# ---------------------------------------------------------------------------
# Debounce — skip if last scan was clean, recent, and file count unchanged
# ---------------------------------------------------------------------------
$debounceSeconds = if ($env:SCAN_DEBOUNCE_SECONDS) { [int]$env:SCAN_DEBOUNCE_SECONDS } else { 60 }
$logFilePath = Join-Path $lockDir 'scan.log'
if ((Test-Path $logFilePath) -and $debounceSeconds -gt 0) {
    $lastLine = Get-Content $logFilePath -Tail 1 -ErrorAction SilentlyContinue
    if ($lastLine -match '"status":"clean"') {
        $tsMatch = [regex]::Match($lastLine, '"timestamp":"([^"]+)"')
        $countMatch = [regex]::Match($lastLine, '"files_scanned":(\d+)')
        if ($tsMatch.Success) {
            try {
                $lastEpoch = [DateTimeOffset]::Parse($tsMatch.Groups[1].Value).ToUnixTimeSeconds()
                $nowEpoch  = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
                $age = $nowEpoch - $lastEpoch
                if ($age -ge 0 -and $age -lt $debounceSeconds) {
                    $lastCount = if ($countMatch.Success) { [int]$countMatch.Groups[1].Value } else { -1 }
                    $curDiff = (git diff --name-only --diff-filter=ACMR HEAD 2>$null | Where-Object { $_ }).Count
                    $curUntracked = (git ls-files --others --exclude-standard 2>$null | Where-Object { $_ }).Count
                    $curCount = $curDiff + $curUntracked
                    if ($lastCount -eq $curCount) {
                        Write-Error "Scan skipped — clean scan ${age}s ago with same file count."
                        '{"continue": true}'
                        Remove-ScanLock
                        exit 0
                    }
                }
            } catch { <# date parse failed — proceed with scan #> }
        }
    }
}

# ---------------------------------------------------------------------------
# Environment variables
#   SCAN_MODE          - "warn" (log only) or "block" (block on findings)
#   SCAN_SCOPE         - "diff" (changed files) or "staged" (staged files)
#   SKIP_SECRETS_SCAN  - "true" to disable scanning
#   SECRETS_ALLOWLIST  - Comma-separated patterns to ignore
# ---------------------------------------------------------------------------

if ($env:SKIP_SECRETS_SCAN -eq 'true') {
    Write-Error "Secrets scan skipped (SKIP_SECRETS_SCAN=true)"
    '{"continue": true}'; exit 0
}

# Verify git is available and we are in a repo
$gitCheck = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or $gitCheck -ne 'true') {
    Write-Error "Not in a git repository, skipping secrets scan"
    '{"continue": true}'; exit 0
}

$Mode  = if ($env:SCAN_MODE)  { $env:SCAN_MODE }  else { 'warn' }
$Scope = if ($env:SCAN_SCOPE) { $env:SCAN_SCOPE } else { 'diff' }

# Secret patterns: Name, Severity, Regex  (kept in parity with scan-secrets.sh)
$Patterns = @(
    [PSCustomObject]@{ Name = 'AWS_ACCESS_KEY';          Severity = 'critical'; Regex = 'AKIA[0-9A-Z]{16}' }
    [PSCustomObject]@{ Name = 'AWS_SECRET_KEY';          Severity = 'critical'; Regex = 'aws_secret_access_key\s*[:=]\s*[''"]?[A-Za-z0-9/+=]{40}' }
    [PSCustomObject]@{ Name = 'GCP_SERVICE_ACCOUNT';     Severity = 'critical'; Regex = '"type"\s*:\s*"service_account"' }
    [PSCustomObject]@{ Name = 'GCP_API_KEY';             Severity = 'high';     Regex = 'AIza[0-9A-Za-z_-]{35}' }
    [PSCustomObject]@{ Name = 'AZURE_CLIENT_SECRET';     Severity = 'critical'; Regex = 'azure[_\-]?client[_\-]?secret\s*[:=]\s*[''"]?[A-Za-z0-9_~.\-]{34,}' }
    [PSCustomObject]@{ Name = 'GITHUB_PAT';              Severity = 'critical'; Regex = 'ghp_[0-9A-Za-z]{36}' }
    [PSCustomObject]@{ Name = 'GITHUB_OAUTH';            Severity = 'critical'; Regex = 'gho_[0-9A-Za-z]{36}' }
    [PSCustomObject]@{ Name = 'GITHUB_APP_TOKEN';        Severity = 'critical'; Regex = 'ghs_[0-9A-Za-z]{36}' }
    [PSCustomObject]@{ Name = 'GITHUB_REFRESH_TOKEN';    Severity = 'critical'; Regex = 'ghr_[0-9A-Za-z]{36}' }
    [PSCustomObject]@{ Name = 'GITHUB_FINE_GRAINED_PAT'; Severity = 'critical'; Regex = 'github_pat_[0-9A-Za-z_]{82}' }
    [PSCustomObject]@{ Name = 'PRIVATE_KEY';             Severity = 'critical'; Regex = '-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----' }
    [PSCustomObject]@{ Name = 'PGP_PRIVATE_BLOCK';       Severity = 'critical'; Regex = '-----BEGIN PGP PRIVATE KEY BLOCK-----' }
    [PSCustomObject]@{ Name = 'GENERIC_SECRET';          Severity = 'high';     Regex = '(secret|token|password|passwd|pwd|api[_\-]?key|apikey|access[_\-]?key|auth[_\-]?token|client[_\-]?secret)\s*[:=]\s*[''"]?[A-Za-z0-9_/+=~.\-]{8,}' }
    [PSCustomObject]@{ Name = 'CONNECTION_STRING';       Severity = 'high';     Regex = '(mongodb(\+srv)?|postgres(ql)?|mysql|redis|amqp|mssql)://[^\s''"][^\s''"]{9,}' }
    [PSCustomObject]@{ Name = 'BEARER_TOKEN';            Severity = 'medium';   Regex = '[Bb]earer\s+[A-Za-z0-9_\-]{20,}\.[A-Za-z0-9_\-]{20,}' }
    [PSCustomObject]@{ Name = 'SLACK_TOKEN';             Severity = 'high';     Regex = 'xox[baprs]-[0-9]{10,}-[0-9A-Za-z\-]+' }
    [PSCustomObject]@{ Name = 'SLACK_WEBHOOK';           Severity = 'high';     Regex = 'https://hooks\.slack\.com/services/T[0-9A-Z]{8,}/B[0-9A-Z]{8,}/[0-9A-Za-z]{24}' }
    [PSCustomObject]@{ Name = 'DISCORD_TOKEN';           Severity = 'high';     Regex = '[MN][A-Za-z0-9]{23,}\.[A-Za-z0-9_\-]{6}\.[A-Za-z0-9_\-]{27,}' }
    [PSCustomObject]@{ Name = 'TWILIO_API_KEY';          Severity = 'high';     Regex = 'SK[0-9a-fA-F]{32}' }
    [PSCustomObject]@{ Name = 'SENDGRID_API_KEY';        Severity = 'high';     Regex = 'SG\.[0-9A-Za-z_\-]{22}\.[0-9A-Za-z_\-]{43}' }
    [PSCustomObject]@{ Name = 'STRIPE_SECRET_KEY';       Severity = 'critical'; Regex = 'sk_live_[0-9A-Za-z]{24,}' }
    [PSCustomObject]@{ Name = 'STRIPE_RESTRICTED_KEY';   Severity = 'high';     Regex = 'rk_live_[0-9A-Za-z]{24,}' }
    [PSCustomObject]@{ Name = 'NPM_TOKEN';               Severity = 'high';     Regex = 'npm_[0-9A-Za-z]{36}' }
    [PSCustomObject]@{ Name = 'JWT_TOKEN';               Severity = 'medium';   Regex = 'eyJ[A-Za-z0-9_\-]{10,}\.eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}' }
    [PSCustomObject]@{ Name = 'INTERNAL_IP_PORT';        Severity = 'low';      Regex = '10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{2,5}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{2,5}' }
)

# Collect files to scan
$Files = @()
if ($Scope -eq 'staged') {
    $Files = git diff --cached --name-only --diff-filter=ACMR 2>$null | Where-Object { $_ }
} else {
    $Files = git diff --name-only --diff-filter=ACMR HEAD 2>$null | Where-Object { $_ }
    if (-not $Files) {
        $Files = git diff --name-only --diff-filter=ACMR 2>$null | Where-Object { $_ }
    }
    $untracked = git ls-files --others --exclude-standard 2>$null | Where-Object { $_ }
    if ($untracked) { $Files = @($Files) + @($untracked) }
}

if (-not $Files -or $Files.Count -eq 0) {
    Write-Error "No modified files to scan"
    '{"continue": true}'; exit 0
}

# Parse allowlist
$Allowlist = @()
if ($env:SECRETS_ALLOWLIST) {
    $Allowlist = $env:SECRETS_ALLOWLIST -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

# Skip lock files and binary files
$SkipExtensions = @('.lock')
$SkipNames = @('package-lock.json', 'pnpm-lock.yaml', 'go.sum')

$Findings = @()
$TempFiles = @()

Write-Error "Scanning $($Files.Count) modified file(s) for secrets..."

try {
    foreach ($filepath in $Files) {
        $filename = Split-Path $filepath -Leaf
        if ($SkipNames -contains $filename) { continue }
        if ($SkipExtensions -contains [System.IO.Path]::GetExtension($filepath)) { continue }

        # For staged scope, read the staged blob via git show rather than the working-tree file
        $readPath = $filepath
        if ($Scope -eq 'staged') {
            $tmpFile = [System.IO.Path]::GetTempFileName()
            $TempFiles += $tmpFile
            git show ":$filepath" 2>$null | Set-Content $tmpFile -Encoding utf8 -ErrorAction SilentlyContinue
            if (Test-Path $tmpFile) { $readPath = $tmpFile } else { continue }
        } else {
            if (-not (Test-Path $filepath -PathType Leaf)) { continue }
        }

        $lineNum = 0
        foreach ($line in Get-Content $readPath -ErrorAction SilentlyContinue) {
            $lineNum++
            $lineText = [string]$line
            foreach ($pat in $Patterns) {
                $pRegex = [string]$pat.Regex
                if (-not $pRegex) { continue }
                $match = [regex]::Match($lineText, $pRegex)
                if (-not $match.Success) { continue }

                $matchVal = $match.Value
                # Skip placeholder / example values
                if ($matchVal -match '(example|placeholder|your[_\-]|xxx|changeme|TODO|FIXME|replace[_\-]?me|dummy|fake|test[_\-]?key|sample)') { continue }
                # Check allowlist
                $allowed = $false
                foreach ($al in $Allowlist) {
                    if ($matchVal -like "*$al*") { $allowed = $true; break }
                }
                if ($allowed) { continue }
                # Redact match value
                $redacted = if ($matchVal.Length -le 12) { '[REDACTED]' } else { $matchVal.Substring(0,4) + '...' + $matchVal.Substring($matchVal.Length - 4) }
                $Findings += [PSCustomObject]@{ File=$filepath; Line=$lineNum; Pattern=[string]$pat.Name; Severity=[string]$pat.Severity; Match=$redacted }
            }
        }
    }
} finally {
    foreach ($tmp in $TempFiles) {
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
}

if ($Findings.Count -gt 0) {
    Write-Error ""
    Write-Error "Found $($Findings.Count) potential secret(s) in modified files:"
    Write-Error ""
    Write-Error ("  {0,-40} {1,-6} {2,-28} {3}" -f 'FILE','LINE','PATTERN','SEVERITY')
    Write-Error ("  {0,-40} {1,-6} {2,-28} {3}" -f '----','----','-------','--------')

    foreach ($f in $Findings) {
        Write-Error ("  {0,-40} {1,-6} {2,-28} {3}" -f $f.File, $f.Line, $f.Pattern, $f.Severity)
    }
    Write-Error ""

    if ($Mode -eq 'block') {
        Write-Error "Session blocked: resolve the findings above before committing."
        Write-Error "Set SCAN_MODE=warn to log without blocking, or add patterns to SECRETS_ALLOWLIST."
        ConvertTo-Json -Compress @{
            hookSpecificOutput = @{
                hookEventName = 'Stop'
                decision = 'block'
                reason = "Secrets detected ($($Findings.Count) finding(s)). Resolve before ending the session or set SCAN_MODE=warn to continue."
            }
            continue = $true
        }
        exit 0
    } else {
        Write-Error "Review the findings above. Set SCAN_MODE=block to prevent commits with secrets."
    }
} else {
    Write-Error "No secrets detected in $($Files.Count) scanned file(s)"
}

'{"continue": true}'

} finally {
    Remove-ScanLock
}
