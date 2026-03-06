param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,

    [Parameter(Mandatory = $true)]
    [string]$TracePath
)

$ErrorActionPreference = 'Stop'
$payload = $input | Out-String
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
foreach ($currentLine in Get-MeasurableLines -Path $resolvedScriptPath) {
    $breakpoints += Set-PSBreakpoint -Script $resolvedScriptPath -Line $currentLine -Action ({
        Add-Content -Path $resolvedTracePath -Value ("TRACE:{0}:{1}:" -f $resolvedScriptPath, $currentLine)
    }.GetNewClosure())
}

try {
    $payload | & $resolvedScriptPath
} finally {
    if ($breakpoints.Count -gt 0) {
        $breakpoints | Remove-PSBreakpoint | Out-Null
    }
}
