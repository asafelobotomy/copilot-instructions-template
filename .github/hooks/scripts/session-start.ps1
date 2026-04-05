# purpose:  Inject project context into every new agent session
# when:     SessionStart hook — fires when a new agent session begins
# inputs:   JSON via stdin (common hook fields)
# outputs:  JSON with additionalContext for the agent
# risk:     safe
# ESCALATION: none

$ErrorActionPreference = 'SilentlyContinue'

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
if (Test-Path '.copilot/workspace/HEARTBEAT.md') {
    $pulse = (Select-String -Path '.copilot/workspace/HEARTBEAT.md' -Pattern 'HEARTBEAT' |
              Select-Object -First 1).Line ?? 'unknown'
}

[PSCustomObject]@{
    hookSpecificOutput = [PSCustomObject]@{
        hookEventName     = 'SessionStart'
        additionalContext = "OS: $osDisplay | Pkg: $pkgMgr | Immutable: $immutable | Project: $projectName v$projectVer | Branch: $branch ($commit) | Node: $nodeVer | Python: $pyVer | Heartbeat: $pulse"
    }
} | ConvertTo-Json -Depth 5
