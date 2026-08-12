[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$Source
)

$ErrorActionPreference = 'Stop'

$SkillDir = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent (Split-Path -Parent $SkillDir)

function Test-RepoLayout {
    param([string]$Root)
    return (
        (Test-Path -LiteralPath (Join-Path $Root 'docs\AGENTS.md') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'docs\CLAUDE.md') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'scripts\install-global-guides.sh') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Root 'skills\agent-guides-installer\SKILL.md') -PathType Leaf)
    )
}

if (-not $Source -or $Source.Count -eq 0) {
    if (Test-RepoLayout $RepoRoot) {
        $Source = @($RepoRoot)
    }
    else {
        $assetRoot = Join-Path $SkillDir 'assets\guides'
        if (Test-Path -LiteralPath (Join-Path $assetRoot 'AGENTS.md') -PathType Leaf) {
            $Source = @($assetRoot)
        }
        else {
            throw 'Could not find guide source directory. Pass -Source <dir>.'
        }
    }
}

$resolvedSources = foreach ($sourceDir in $Source) {
    if (-not (Test-Path -LiteralPath $sourceDir -PathType Container)) {
        throw "Source directory does not exist: $sourceDir"
    }
    (Resolve-Path -LiteralPath $sourceDir).Path
}

$extensions = @('.md', '.sh', '.ps1', '.yaml', '.yml', '.json')
$files = @(
    foreach ($sourceDir in $resolvedSources) {
        Get-ChildItem -LiteralPath $sourceDir -File -Recurse -Force | Where-Object {
            $relative = $_.FullName.Substring($sourceDir.Length).TrimStart([char[]]@('\', '/'))
            $segments = $relative -split '[\\/]'
            $_.Extension.ToLowerInvariant() -in $extensions -and
            $_.Name -notin @('scan-guides.sh', 'scan-guides.ps1') -and
            $segments -notcontains '.git' -and
            $segments -notcontains '.debug' -and
            $segments -notcontains 'backups'
        }
    }
)

if ($files.Count -eq 0) {
    throw "No scan target files found under: $($resolvedSources -join ', ')"
}

$rules = @(
    @{ Label = 'local Windows workspace path'; Pattern = '[A-Za-z]:[\\/]+(?:Users|Workspace|Work|Projects)[\\/]+[^\s`"''<>]+' },
    @{ Label = 'local Unix home path'; Pattern = '/(?:Users|home)/[^/\s`"''<>]+/[^\s`"''<>]+' },
    @{ Label = 'private key block'; Pattern = 'BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY' },
    @{ Label = 'AWS access key'; Pattern = 'AKIA[0-9A-Z]{16}' },
    @{ Label = 'OpenAI-style API key'; Pattern = 'sk-[A-Za-z0-9_-]{20,}' },
    @{ Label = 'GitHub token'; Pattern = 'gh[pousr]_[A-Za-z0-9_]{20,}' },
    @{ Label = 'Slack token'; Pattern = 'xox[baprs]-[A-Za-z0-9-]{20,}' },
    @{ Label = 'Google API key'; Pattern = 'AIza[0-9A-Za-z_-]{20,}' },
    @{ Label = 'Authorization header'; Pattern = 'Authorization:\s*\S+' },
    @{ Label = 'Bearer token'; Pattern = 'Bearer\s+[A-Za-z0-9._-]{20,}' },
    @{ Label = 'database URL'; Pattern = '(?:postgresql|postgres|mysql|redis)://\S+' },
    @{ Label = 'credential assignment'; Pattern = '(?m)^\s*(?:export\s+)?[A-Z0-9_]*(?:KEY|TOKEN|SECRET|PASSWORD|PASS|PWD)[A-Z0-9_]*\s*=\s*\S+' }
)

$failed = $false
foreach ($file in $files) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $emailMatches = [regex]::Matches($content, '[A-Za-z0-9._%+-]+@(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}')
    foreach ($match in $emailMatches) {
        if ($match.Value -notmatch 'example\.com$') {
            Write-Error "Potential leak: real email address`n$($file.FullName): $($match.Value)" -ErrorAction Continue
            $failed = $true
        }
    }
    foreach ($rule in $rules) {
        if ([regex]::IsMatch($content, $rule.Pattern)) {
            Write-Error "Potential leak: $($rule.Label)`n$($file.FullName)" -ErrorAction Continue
            $failed = $true
        }
    }
}

if ($failed) {
    Write-Error 'Guide scan failed.' -ErrorAction Continue
    exit 1
}

Write-Output "Guide scan passed: $($resolvedSources -join ', ')"
exit 0
