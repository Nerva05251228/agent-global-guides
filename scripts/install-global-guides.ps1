[CmdletBinding()]
param(
    [string]$Source,
    [string]$CodexHome,
    [string]$ClaudeHome,
    [string]$GitHubOwner,
    [string]$GitEmail,
    [switch]$Backup,
    [switch]$NoBackup,
    [switch]$DryRun,
    [switch]$SkipSkills
)

$scriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'skills\agent-guides-installer\scripts\install-global-guides.ps1'
$arguments = @{}
foreach ($name in @('Source', 'CodexHome', 'ClaudeHome', 'GitHubOwner', 'GitEmail')) {
    $value = Get-Variable -Name $name -ValueOnly
    if (-not [string]::IsNullOrWhiteSpace($value)) { $arguments[$name] = $value }
}
foreach ($name in @('Backup', 'NoBackup', 'DryRun', 'SkipSkills')) {
    if ((Get-Variable -Name $name -ValueOnly).IsPresent) { $arguments[$name] = $true }
}
& $scriptPath @arguments
exit $LASTEXITCODE
