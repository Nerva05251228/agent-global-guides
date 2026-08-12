[CmdletBinding()]
param([string[]]$Source)

$scriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'skills\agent-guides-installer\scripts\scan-guides.ps1'
if ($Source) {
    & $scriptPath -Source $Source
}
else {
    & $scriptPath
}
exit $LASTEXITCODE
