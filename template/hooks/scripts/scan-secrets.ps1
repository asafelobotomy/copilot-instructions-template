# purpose:  Scan modified files for leaked secrets at session end
# when:     Stop hook — fires when the agent session ends
# inputs:   JSON via stdin
# outputs:  JSON continuation signal; scan results on stderr
# risk:     read-only

$ErrorActionPreference = 'SilentlyContinue'
$null = $input | Out-String

# ---------------------------------------------------------------------------
# Environment variables
#   SCAN_MODE          - "warn" (log only) or "block" (block on findings)
#   SCAN_SCOPE         - "diff" (changed files) or "staged" (staged files)
#   SKIP_SECRETS_SCAN  - "true" to disable scanning
#   SECRETS_ALLOWLIST  - Comma-separated patterns to ignore
# ---------------------------------------------------------------------------

if ($env:SKIP_SECRETS_SCAN -eq 'true') {
    Write-Host "⏭️  Secrets scan skipped (SKIP_SECRETS_SCAN=true)" -ForegroundColor Yellow
    '{"continue": true}'; exit 0
}

# Verify git is available and we are in a repo
$gitCheck = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or $gitCheck -ne 'true') {
    Write-Host "⚠️  Not in a git repository, skipping secrets scan" -ForegroundColor Yellow
    '{"continue": true}'; exit 0
}

$Mode  = if ($env:SCAN_MODE)  { $env:SCAN_MODE }  else { 'warn' }
$Scope = if ($env:SCAN_SCOPE) { $env:SCAN_SCOPE } else { 'diff' }

# Secret patterns: Name, Severity, Regex
$Patterns = @(
    @('AWS_ACCESS_KEY',       'critical', 'AKIA[0-9A-Z]{16}')
    @('AWS_SECRET_KEY',       'critical', 'aws_secret_access_key\s*[:=]\s*[''"]?[A-Za-z0-9/+=]{40}')
    @('GCP_API_KEY',          'high',     'AIza[0-9A-Za-z_-]{35}')
    @('GITHUB_PAT',           'critical', 'ghp_[0-9A-Za-z]{36}')
    @('GITHUB_OAUTH',         'critical', 'gho_[0-9A-Za-z]{36}')
    @('GITHUB_APP_TOKEN',     'critical', 'ghs_[0-9A-Za-z]{36}')
    @('GITHUB_REFRESH_TOKEN', 'critical', 'ghr_[0-9A-Za-z]{36}')
    @('GITHUB_FINE_PAT',      'critical', 'github_pat_[0-9A-Za-z_]{82}')
    @('PRIVATE_KEY',          'critical', '-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----')
    @('GENERIC_SECRET',       'high',     '(secret|token|password|passwd|pwd|api[_-]?key|apikey|access[_-]?key|auth[_-]?token|client[_-]?secret)\s*[:=]\s*[''"]?[A-Za-z0-9_/+=~.-]{8,}')
    @('CONNECTION_STRING',    'high',     '(mongodb(\+srv)?|postgres(ql)?|mysql|redis|amqp|mssql)://[^\s''"]{10,}')
    @('SLACK_TOKEN',          'high',     'xox[baprs]-[0-9]{10,}-[0-9A-Za-z-]+')
    @('STRIPE_SECRET_KEY',    'critical', 'sk_live_[0-9A-Za-z]{24,}')
    @('NPM_TOKEN',            'high',     'npm_[0-9A-Za-z]{36}')
    @('JWT_TOKEN',            'medium',   'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}')
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
    Write-Host "✨ No modified files to scan" -ForegroundColor Green
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

Write-Host "🔍 Scanning $($Files.Count) modified file(s) for secrets..." -ForegroundColor Cyan

foreach ($filepath in $Files) {
    if (-not (Test-Path $filepath -PathType Leaf)) { continue }
    $filename = Split-Path $filepath -Leaf
    if ($SkipNames -contains $filename) { continue }
    if ($SkipExtensions -contains [System.IO.Path]::GetExtension($filepath)) { continue }

    $lineNum = 0
    foreach ($line in Get-Content $filepath -ErrorAction SilentlyContinue) {
        $lineNum++
        foreach ($pat in $Patterns) {
            $pName, $pSev, $pRegex = $pat
            if ($line -match $pRegex) {
                $matchVal = $Matches[0]
                # Skip placeholder / example values
                if ($matchVal -match '(example|placeholder|your[_-]|xxx|changeme|TODO|FIXME|replace[_-]?me|dummy|fake|test[_-]?key|sample)') { continue }
                # Check allowlist
                $allowed = $false
                foreach ($al in $Allowlist) {
                    if ($matchVal -like "*$al*") { $allowed = $true; break }
                }
                if ($allowed) { continue }
                # Redact
                $redacted = if ($matchVal.Length -le 12) { '[REDACTED]' } else { $matchVal.Substring(0,4) + '...' + $matchVal.Substring($matchVal.Length - 4) }
                $Findings += [PSCustomObject]@{ File=$filepath; Line=$lineNum; Pattern=$pName; Severity=$pSev; Match=$redacted }
            }
        }
    }
}

if ($Findings.Count -gt 0) {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "⚠️  Found $($Findings.Count) potential secret(s) in modified files:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host ("  {0,-40} {1,-6} {2,-28} {3}" -f 'FILE','LINE','PATTERN','SEVERITY') -ForegroundColor Yellow
    Write-Host ("  {0,-40} {1,-6} {2,-28} {3}" -f '----','----','-------','--------') -ForegroundColor Yellow

    foreach ($f in $Findings) {
        Write-Host ("  {0,-40} {1,-6} {2,-28} {3}" -f $f.File, $f.Line, $f.Pattern, $f.Severity)
    }
    Write-Host ""

    if ($Mode -eq 'block') {
        Write-Host "🚫 Session blocked: resolve the findings above before committing." -ForegroundColor Red
        Write-Host "   Set SCAN_MODE=warn to log without blocking, or add patterns to SECRETS_ALLOWLIST." -ForegroundColor Red
        '{"continue": false}'; exit 0
    } else {
        Write-Host "💡 Review the findings above. Set SCAN_MODE=block to prevent commits with secrets." -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ No secrets detected in $($Files.Count) scanned file(s)" -ForegroundColor Green
}

'{"continue": true}'
