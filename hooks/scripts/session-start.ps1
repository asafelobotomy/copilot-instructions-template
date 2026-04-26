#!/usr/bin/env pwsh
# purpose:  Add project context to each new agent session
# when:     SessionStart
# inputs:   JSON via stdin
# outputs:  JSON with additionalContext
# risk:     safe
# ESCALATION: none

Set-StrictMode -Version 1
$ErrorActionPreference = 'Continue'

# Consume stdin per hook stdio protocol (SessionStart payload, not used but must be drained)
$input_json = $input | Out-String

# Detect operating system
if ($IsLinux) {
    $osRelease = @{}
    if (Test-Path '/etc/os-release') {
        Get-Content '/etc/os-release' | ForEach-Object {
            if ($_ -match '^(\w+)=(.*)$') {
                $osRelease[$Matches[1]] = $Matches[2].Trim('"')
            }
        }
    }
    $osId       = $osRelease['ID']         ?? 'unknown'
    $osVersion  = $osRelease['VERSION_ID'] ?? 'unknown'
    $osVariant  = $osRelease['VARIANT_ID'] ?? ''
    $osArch     = try { (uname -m) } catch { 'unknown' }
    $immutable  = (Test-Path '/run/ostree-booted') -or
                  (($osRelease.Values -join ' ') -match 'ostree|atomic|immutable')
    $pkgMgr     = if (Get-Command apt   -ErrorAction Ignore) { 'apt' }
             elseif (Get-Command pacman -ErrorAction Ignore) { 'pacman' }
             elseif (Get-Command dnf    -ErrorAction Ignore) { 'dnf' }
             elseif (Get-Command rpm-ostree -ErrorAction Ignore) { 'rpm-ostree' }
             else { 'unknown' }
    $variantTag = if ($osVariant) { "/$osVariant" } else { '' }
    $osDisplay  = "${osId}${variantTag} ${osVersion} ($osArch)"
} elseif ($IsMacOS) {
    $osId      = 'macos'
    $osVersion = try { (sw_vers -productVersion) } catch { 'unknown' }
    $osArch    = try { (uname -m) } catch { 'unknown' }
    $immutable = $false
    $pkgMgr    = if (Get-Command brew -ErrorAction Ignore) { 'brew' } else { 'unknown' }
    $osDisplay = "macOS $osVersion ($osArch)"
} else {
    $osId      = 'windows'
    $osVersion = [System.Environment]::OSVersion.Version.ToString()
    $osArch    = $env:PROCESSOR_ARCHITECTURE ?? 'unknown'
    $immutable = $false
    $pkgMgr    = if (Get-Command winget -ErrorAction Ignore) { 'winget' }
            elseif (Get-Command choco  -ErrorAction Ignore) { 'choco' }
            elseif (Get-Command scoop  -ErrorAction Ignore) { 'scoop' }
            else { 'unknown' }
    $osDisplay = "Windows $osVersion ($osArch)"
}

function Invoke-Git {
    param([string[]]$Args)
    try { & git @Args 2>$null } catch { 'unknown' }
}

$branch  = (Invoke-Git 'rev-parse', '--abbrev-ref', 'HEAD') ?? 'unknown'
$commit  = (Invoke-Git 'rev-parse', '--short', 'HEAD') ?? 'unknown'
$nodeVer = (node --version 2>$null) ?? 'n/a'
$pyVer   = try { (python --version 2>&1) -replace '^Python ','' } catch { 'n/a' }

$projectName = 'unknown'
$projectVer  = 'n/a'

if (Test-Path 'package.json') {
    $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json
    $projectName = $pkg.name    ?? 'unknown'
    $projectVer  = $pkg.version ?? 'unknown'
} elseif (Test-Path 'pyproject.toml') {
    $content = Get-Content 'pyproject.toml' -Raw
    $projectName = [regex]::Match($content, '(?m)^name\s*=\s*"([^"]+)"').Groups[1].Value
    $projectVer  = [regex]::Match($content, '(?m)^version\s*=\s*"([^"]+)"').Groups[1].Value
} elseif (Test-Path 'Cargo.toml') {
    $content = Get-Content 'Cargo.toml' -Raw
    $projectName = [regex]::Match($content, '(?m)^name\s*=\s*"([^"]+)"').Groups[1].Value
    $projectVer  = [regex]::Match($content, '(?m)^version\s*=\s*"([^"]+)"').Groups[1].Value
} else {
    $projectName = Split-Path -Leaf $PWD
}

$pulse = 'unknown'
if (Test-Path '.copilot/workspace/operations/HEARTBEAT.md') {
    $pulse = (Select-String -Path '.copilot/workspace/operations/HEARTBEAT.md' -Pattern 'HEARTBEAT' |
              Select-Object -First 1).Line ?? 'unknown'
}

$routingRoster = 'specialists: Code, Review, Fast, Audit, Commit, Explore | internal: Organise, Extensions, Researcher, Planner, Docs, Debugger | guarded: Setup'
$_manifestPath = if (Test-Path 'agents/routing-manifest.json') {
  'agents/routing-manifest.json'
} elseif (Test-Path '.github/agents/routing-manifest.json') {
  '.github/agents/routing-manifest.json'
} else { $null }
if ($null -ne $_manifestPath) {
    try {
        $manifest = Get-Content $_manifestPath -Raw | ConvertFrom-Json -AsHashtable
        $direct = New-Object System.Collections.Generic.List[string]
        $internal = New-Object System.Collections.Generic.List[string]
        $guarded = New-Object System.Collections.Generic.List[string]
        foreach ($entry in @($manifest['agents'])) {
            if ($null -eq $entry) { continue }
            $route = [string]($entry['route'] ?? 'inactive')
            if ($route -notin @('active', 'guarded')) { continue }
            $name = [string]($entry['name'] ?? '')
            if (-not $name) { continue }
            if ($route -eq 'guarded') {
                $guarded.Add($name)
            } elseif ([string]($entry['visibility'] ?? 'internal') -eq 'picker-visible') {
                $direct.Add($name)
            } else {
                $internal.Add($name)
            }
        }
        $parts = New-Object System.Collections.Generic.List[string]
        if ($direct.Count -gt 0) { $parts.Add('specialists: ' + ($direct -join ', ')) }
        if ($internal.Count -gt 0) { $parts.Add('internal: ' + ($internal -join ', ')) }
        if ($guarded.Count -gt 0) { $parts.Add('guarded: ' + ($guarded -join ', ')) }
        if ($parts.Count -gt 0) {
            $routingRoster = $parts -join ' | '
        }
    } catch {}
}

[PSCustomObject]@{
    hookSpecificOutput = [PSCustomObject]@{
        hookEventName     = 'SessionStart'
        additionalContext = "OS:$osDisplay|Pkg:$pkgMgr|Imm:$immutable|Proj:$projectName v$projectVer|Branch:$branch($commit)|Node:$nodeVer|Py:$pyVer|HB:$pulse|Route:$routingRoster"
    }
} | ConvertTo-Json -Depth 5
