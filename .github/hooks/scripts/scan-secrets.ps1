# purpose:  Scan modified files for leaked secrets at session end
# when:     Stop hook — fires when the agent session ends
# inputs:   JSON via stdin
# outputs:  JSON continuation signal
# risk:     read-only

$ErrorActionPreference = 'SilentlyContinue'
$null = $input | Out-String

# Secrets scanning requires Unix tools (grep, file, git).
# Native Windows scanning is not implemented.
# Install Git Bash or WSL and configure the bash hook to enable scanning.
Write-Host "⚠️  Secrets scanner: Windows scanning not implemented. Use WSL or Git Bash."
'{"continue": true}'
