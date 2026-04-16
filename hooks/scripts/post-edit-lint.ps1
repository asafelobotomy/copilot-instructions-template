#!/usr/bin/env pwsh
# purpose:  Auto-format files after agent edits them
# when:     PostToolUse hook — fires after a tool completes successfully
# inputs:   JSON via stdin with tool_name and tool_input
# outputs:  JSON with additionalContext if lint errors found
# risk:     safe

Set-StrictMode -Version 1
$ErrorActionPreference = 'Continue'
$input_json = $input | Out-String

try {
    $data = $input_json | ConvertFrom-Json
} catch {
    '{"continue": true}'; exit 0
}

$toolName = $data.tool_name ?? ''

# Only run after file-editing tools
if ($toolName -notmatch 'edit|create|write|replace') {
    '{"continue": true}'; exit 0
}

$ti = $data.tool_input
$files = @()

foreach ($key in @('filePath','file','path','files','file_path')) {
    $val = $ti.$key
    if ($null -ne $val) {
        if ($val -is [array]) { $files += $val }
        elseif ($val) { $files += $val }
    }
}

if ($files.Count -eq 0) {
    '{"continue": true}'; exit 0
}

$lintNotes = ''

foreach ($filepath in $files) {
    if (-not $filepath -or -not (Test-Path $filepath)) { continue }

    # Workspace boundary check — reject paths outside the repo root
    $repoRoot = (git rev-parse --show-toplevel 2>$null)
    if (-not $repoRoot) { $repoRoot = $PWD.Path }
    $repoRoot = $repoRoot.Trim().TrimEnd('/', '\')
    $resolvedPath = (Resolve-Path $filepath -ErrorAction SilentlyContinue)?.Path
    if (-not $resolvedPath -or -not $resolvedPath.StartsWith($repoRoot)) { continue }

    $ext = [System.IO.Path]::GetExtension($filepath).TrimStart('.')

    switch ($ext) {
        { $_ -in 'js','jsx','ts','tsx','mjs','cjs' } {
            if ((Get-Command npx -ErrorAction SilentlyContinue) -and (Test-Path 'node_modules/.bin/prettier')) {
                $fmtOut = npx prettier --write $filepath 2>&1
                if ($LASTEXITCODE -ne 0) { $lintNotes += "[prettier:${filepath}] $($fmtOut -join ' ') " }
            }
        }
        'py' {
            if (Get-Command black -ErrorAction SilentlyContinue) {
                $fmtOut = black --quiet $filepath 2>&1
                if ($LASTEXITCODE -ne 0) { $lintNotes += "[black:${filepath}] $($fmtOut -join ' ') " }
            } elseif (Get-Command ruff -ErrorAction SilentlyContinue) {
                $fmtOut = ruff format $filepath 2>&1
                if ($LASTEXITCODE -ne 0) { $lintNotes += "[ruff:${filepath}] $($fmtOut -join ' ') " }
            }
        }
        'rs' {
            if (Get-Command rustfmt -ErrorAction SilentlyContinue) {
                $fmtOut = rustfmt $filepath 2>&1
                if ($LASTEXITCODE -ne 0) { $lintNotes += "[rustfmt:${filepath}] $($fmtOut -join ' ') " }
            }
        }
        'go' {
            if (Get-Command gofmt -ErrorAction SilentlyContinue) {
                $fmtOut = gofmt -w $filepath 2>&1
                if ($LASTEXITCODE -ne 0) { $lintNotes += "[gofmt:${filepath}] $($fmtOut -join ' ') " }
            }
        }
    }
}

if ($lintNotes) {
    $escaped = $lintNotes.Trim() -replace '\\', '\\' -replace '"', '\"'
    "{`"continue`": true, `"additionalContext`": `"$escaped`"}"
} else {
    '{"continue": true}'
}
