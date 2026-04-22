param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,

    [Parameter(Mandatory = $true)]
    [string]$TracePath
,

    [Parameter()]
    [string]$Payload
)

$ErrorActionPreference = 'Stop'
$payload = if ($PSBoundParameters.ContainsKey('Payload')) { $Payload } else { $input | Out-String }
$resolvedScriptPath = (Resolve-Path $ScriptPath).Path
$resolvedTracePath = [System.IO.Path]::GetFullPath($TracePath)
$traceDir = Split-Path -Parent $resolvedTracePath

if ($traceDir) {
    New-Item -ItemType Directory -Path $traceDir -Force | Out-Null
}

function Get-MeasurableLines {
    param([string]$Path)

    $skipTokens = @('{', '}')
    $inBlockComment = $false
    $lineNumber = 0

    foreach ($line in Get-Content -Path $Path) {
        $lineNumber++
        $trimmed = $line.Trim()

        if (-not $trimmed) {
            continue
        }

        if ($inBlockComment) {
            if ($trimmed.Contains('#>')) {
                $inBlockComment = $false
            }
            continue
        }

        if ($trimmed.StartsWith('<#')) {
            if (-not $trimmed.Contains('#>')) {
                $inBlockComment = $true
            }
            continue
        }

        if ($trimmed.StartsWith('#')) {
            continue
        }

        if ($skipTokens -contains $trimmed) {
            continue
        }

        $lineNumber
    }
}

$breakpoints = @()
$traceTargets = @($resolvedScriptPath)
$scriptDir = Split-Path -Parent $resolvedScriptPath
if ($scriptDir -and (Test-Path $scriptDir)) {
    $siblings = Get-ChildItem -Path $scriptDir -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
    foreach ($sibling in $siblings) {
        if ($traceTargets -notcontains $sibling) {
            $traceTargets += $sibling
        }
    }
}

foreach ($targetPath in $traceTargets) {
    foreach ($currentLine in Get-MeasurableLines -Path $targetPath) {
        $breakpoints += Set-PSBreakpoint -Script $targetPath -Line $currentLine -Action ({
            Add-Content -Path $resolvedTracePath -Value ("TRACE:{0}:{1}:" -f $targetPath, $currentLine)
        }.GetNewClosure())
    }
}

try {
    $originalIn = [Console]::In
    $payloadReader = [System.IO.StringReader]::new($payload)
    [Console]::SetIn($payloadReader)
    try {
        $payload | & $resolvedScriptPath
    }
    finally {
        [Console]::SetIn($originalIn)
        $payloadReader.Dispose()
    }
} finally {
    if ($breakpoints.Count -gt 0) {
        $breakpoints | Remove-PSBreakpoint | Out-Null
    }
}
