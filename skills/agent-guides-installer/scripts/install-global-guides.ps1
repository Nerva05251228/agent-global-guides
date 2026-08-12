[CmdletBinding()]
param(
    [string]$Source,
    [string]$CodexHome = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }),
    [string]$ClaudeHome = $(if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME '.claude' }),
    [string]$GitHubOwner,
    [string]$GitEmail,
    [switch]$Backup,
    [switch]$NoBackup,
    [switch]$DryRun,
    [switch]$SkipSkills
)

$ErrorActionPreference = 'Stop'

if ($Backup -and $NoBackup) {
    throw '-Backup conflicts with -NoBackup.'
}

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

$repoMode = $false
if ([string]::IsNullOrWhiteSpace($Source)) {
    if (Test-RepoLayout $RepoRoot) {
        $Source = Join-Path $RepoRoot 'docs'
        $repoMode = $true
    }
    else {
        $assetRoot = Join-Path $SkillDir 'assets\guides'
        if (Test-Path -LiteralPath (Join-Path $assetRoot 'AGENTS.md') -PathType Leaf) {
            $Source = $assetRoot
        }
        else {
            throw 'Could not find guide source directory. Pass -Source <dir>.'
        }
    }
}

$Source = (Resolve-Path -LiteralPath $Source).Path
if (-not $repoMode -and (Test-RepoLayout $RepoRoot) -and $Source -eq (Join-Path $RepoRoot 'docs')) {
    $repoMode = $true
}

$agentsSource = Join-Path $Source 'AGENTS.md'
$claudeSource = Join-Path $Source 'CLAUDE.md'
if (-not (Test-Path -LiteralPath $agentsSource -PathType Leaf) -or -not (Test-Path -LiteralPath $claudeSource -PathType Leaf)) {
    throw "Source must contain AGENTS.md and CLAUDE.md: $Source"
}

# Scan completion is mandatory before prompting, creating backups, or writing targets.
$scanner = Join-Path $PSScriptRoot 'scan-guides.ps1'
if ($repoMode) {
    & $scanner -Source $RepoRoot
}
else {
    & $scanner -Source $Source
}
if ($LASTEXITCODE -ne 0) {
    throw 'Guide scan failed before installation.'
}

$backupEnabled = $true
if ($NoBackup) {
    $backupEnabled = $false
}
elseif (-not $Backup) {
    $readHostCommand = Get-Command Read-Host -ErrorAction SilentlyContinue
    $mockedReadHost = $null -ne $readHostCommand -and $readHostCommand.CommandType -eq 'Function'
    $interactiveConsole = $false
    try {
        $interactiveConsole = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
    }
    catch {
        $interactiveConsole = $false
    }
    if ($mockedReadHost -or $interactiveConsole) {
        $answer = Read-Host 'Create backups before replacing files? [Y/n]'
        if ($answer -match '^(?i:n|no)$') {
            $backupEnabled = $false
        }
    }
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$codexBackupRoot = Join-Path $CodexHome "backups\agent-global-guides\$timestamp"
$claudeBackupRoot = Join-Path $ClaudeHome "backups\agent-global-guides\$timestamp"

if ($backupEnabled) {
    Write-Output 'Backup policy: enabled'
    Write-Output "Codex backup snapshot: $codexBackupRoot"
    Write-Output "Claude backup snapshot: $claudeBackupRoot"
}
else {
    Write-Output 'Backup policy: disabled; installer recovery unavailable.'
}

function Get-ExistingIdentity {
    param(
        [string]$Path,
        [string]$Label
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return ''
    }
    $content = Get-Content -LiteralPath $Path -Raw
    $pattern = '(?m)^' + [regex]::Escape("- ${Label}:") + '\s*`([^`]*)`'
    $match = [regex]::Match($content, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value
    }
    return ''
}

function Resolve-Identity {
    param(
        [string]$ExplicitValue,
        [string]$ExistingPath,
        [string]$Label,
        [string]$Placeholder
    )
    if (-not [string]::IsNullOrWhiteSpace($ExplicitValue)) {
        return $ExplicitValue
    }
    $existing = Get-ExistingIdentity -Path $ExistingPath -Label $Label
    if (-not [string]::IsNullOrWhiteSpace($existing) -and $existing -ne $Placeholder) {
        return $existing
    }
    return $Placeholder
}

function Get-RenderedGuide {
    param(
        [string]$SourcePath,
        [string]$ExistingPath
    )
    $owner = Resolve-Identity -ExplicitValue $GitHubOwner -ExistingPath $ExistingPath -Label 'GitHub owner / username' -Placeholder '<your-github-username>'
    $email = Resolve-Identity -ExplicitValue $GitEmail -ExistingPath $ExistingPath -Label 'Commit email, when a local Git identity is needed' -Placeholder '<your-git-email@example.com>'
    return (Get-Content -LiteralPath $SourcePath -Raw).
        Replace('<your-github-username>', $owner).
        Replace('<your-git-email@example.com>', $email)
}

function Get-BackupPath {
    param(
        [string]$Path,
        [string]$TargetHome,
        [string]$BackupRoot
    )
    $normalizedHome = $TargetHome.TrimEnd([char[]]@('\', '/'))
    $relative = $Path.Substring($normalizedHome.Length).TrimStart([char[]]@('\', '/'))
    return Join-Path $BackupRoot $relative
}

function Backup-Existing {
    param(
        [string]$Path,
        [string]$TargetHome,
        [string]$BackupRoot
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }
    $destination = Get-BackupPath -Path $Path -TargetHome $TargetHome -BackupRoot $BackupRoot
    if ($DryRun) {
        Write-Output "[dry-run] would back up $Path -> $destination"
        return
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $Path -Destination $destination -Recurse -Force
    Write-Output "Backed up $Path -> $destination"
}

function Install-Guide {
    param(
        [string]$Content,
        [string]$Destination,
        [string]$Label,
        [string]$TargetHome,
        [string]$BackupRoot
    )
    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        $existing = Get-Content -LiteralPath $Destination -Raw
        if ($existing -eq $Content) {
            Write-Output "$Label already up to date: $Destination"
            return
        }
    }
    if ($DryRun) {
        if ($backupEnabled -and (Test-Path -LiteralPath $Destination)) {
            Backup-Existing -Path $Destination -TargetHome $TargetHome -BackupRoot $BackupRoot
        }
        Write-Output "[dry-run] install $Label -> $Destination"
        return
    }
    if ($backupEnabled -and (Test-Path -LiteralPath $Destination)) {
        Backup-Existing -Path $Destination -TargetHome $TargetHome -BackupRoot $BackupRoot
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force | Out-Null
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Destination, $Content, $utf8NoBom)
    if ((Get-Content -LiteralPath $Destination -Raw) -ne $Content) {
        throw "Verification failed after installing ${Label}: $Destination"
    }
    Write-Output "Installed ${Label}: $Destination"
}

function Get-DirectorySignature {
    param([string]$Root)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return @()
    }
    $normalizedRoot = (Resolve-Path -LiteralPath $Root).Path.TrimEnd([char[]]@('\', '/'))
    return @(
        Get-ChildItem -LiteralPath $normalizedRoot -File -Recurse -Force | Sort-Object FullName | ForEach-Object {
            $relative = $_.FullName.Substring($normalizedRoot.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
            $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            "$relative|$hash"
        }
    )
}

function Test-DirectoryEqual {
    param(
        [string]$Left,
        [string]$Right
    )
    $leftSignature = Get-DirectorySignature $Left
    $rightSignature = Get-DirectorySignature $Right
    return ($leftSignature.Count -eq $rightSignature.Count -and ($leftSignature -join "`n") -ceq ($rightSignature -join "`n"))
}

$renderedAgents = Get-RenderedGuide -SourcePath $agentsSource -ExistingPath (Join-Path $CodexHome 'AGENTS.md')
$renderedClaude = Get-RenderedGuide -SourcePath $claudeSource -ExistingPath (Join-Path $ClaudeHome 'CLAUDE.md')
Install-Guide -Content $renderedAgents -Destination (Join-Path $CodexHome 'AGENTS.md') -Label 'Codex AGENTS.md' -TargetHome $CodexHome -BackupRoot $codexBackupRoot
Install-Guide -Content $renderedClaude -Destination (Join-Path $ClaudeHome 'CLAUDE.md') -Label 'Claude CLAUDE.md' -TargetHome $ClaudeHome -BackupRoot $claudeBackupRoot

$skillsSource = if ($repoMode) { Join-Path $RepoRoot 'skills' } else { '' }

function Install-Skills {
    param(
        [string]$TargetHome,
        [string]$Label,
        [string]$BackupRoot
    )
    if ([string]::IsNullOrWhiteSpace($skillsSource) -or -not (Test-Path -LiteralPath $skillsSource -PathType Container)) {
        Write-Warning "No skills source directory found; skipping $Label skills."
        return
    }
    $targetRoot = Join-Path $TargetHome 'skills'
    if ((Test-Path -LiteralPath $targetRoot) -and (Resolve-Path -LiteralPath $targetRoot).Path -eq (Resolve-Path -LiteralPath $skillsSource).Path) {
        throw "Refusing to install $Label skills because source and target are the same: $skillsSource"
    }
    foreach ($skill in Get-ChildItem -LiteralPath $skillsSource -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf }) {
        $destination = Join-Path $targetRoot $skill.Name
        if ((Test-Path -LiteralPath $destination -PathType Container) -and (Test-DirectoryEqual $skill.FullName $destination)) {
            Write-Output "$Label skill already up to date: $destination"
            continue
        }
        if ($DryRun) {
            if ($backupEnabled -and (Test-Path -LiteralPath $destination)) {
                Backup-Existing -Path $destination -TargetHome $TargetHome -BackupRoot $BackupRoot
            }
            Write-Output "[dry-run] install $Label skill: $($skill.FullName) -> $destination"
            continue
        }
        if ($backupEnabled -and (Test-Path -LiteralPath $destination)) {
            Backup-Existing -Path $destination -TargetHome $TargetHome -BackupRoot $BackupRoot
        }
        if (Test-Path -LiteralPath $destination) {
            Remove-Item -LiteralPath $destination -Recurse -Force
        }
        New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
        Copy-Item -LiteralPath $skill.FullName -Destination $destination -Recurse
        if (-not (Test-DirectoryEqual $skill.FullName $destination)) {
            throw "Verification failed after installing $Label skill: $destination"
        }
        Write-Output "Installed $Label skill: $destination"
    }
}

function Get-FrontmatterName {
    param([string]$SkillFile)
    $lines = Get-Content -LiteralPath $SkillFile
    if ($lines.Count -eq 0 -or $lines[0] -notmatch '^---\s*$') {
        return ''
    }
    for ($index = 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^---\s*$') {
            break
        }
        if ($lines[$index] -match '^name:\s*(.+)$') {
            return $Matches[1].Trim()
        }
    }
    return ''
}

function Test-ReplacementValid {
    param(
        [string]$TargetHome,
        [string]$Replacement
    )
    $sourcePath = Join-Path $skillsSource $Replacement
    $installedPath = Join-Path (Join-Path $TargetHome 'skills') $Replacement
    $sourceSkill = Join-Path $sourcePath 'SKILL.md'
    $installedSkill = Join-Path $installedPath 'SKILL.md'
    return (
        (Test-Path -LiteralPath $sourceSkill -PathType Leaf) -and
        (Test-Path -LiteralPath $installedSkill -PathType Leaf) -and
        (Get-FrontmatterName $installedSkill) -eq $Replacement -and
        (Test-DirectoryEqual $sourcePath $installedPath)
    )
}

function Remove-LegacySkill {
    param(
        [string]$TargetHome,
        [string]$Label,
        [string]$BackupRoot
    )
    $legacy = Join-Path (Join-Path $TargetHome 'skills') 'subagent-orchestration'
    if (-not (Test-Path -LiteralPath $legacy)) {
        return
    }
    if ($DryRun) {
        if ($backupEnabled) {
            $recovery = Get-BackupPath -Path $legacy -TargetHome $TargetHome -BackupRoot $BackupRoot
            Write-Output "[dry-run] would remove $legacy after replacement validation; recovery: $recovery"
        }
        else {
            Write-Output "[dry-run] would remove $legacy after replacement validation; recovery unavailable"
        }
        return
    }
    if (-not (Test-ReplacementValid -TargetHome $TargetHome -Replacement 'codex-subagent-orchestration') -or
        -not (Test-ReplacementValid -TargetHome $TargetHome -Replacement 'claude-subagent-orchestration')) {
        Write-Warning "$Label legacy skill kept: replacement validation failed for $legacy"
        $script:CleanupFailed = $true
        return
    }
    if ($backupEnabled) {
        $recovery = Get-BackupPath -Path $legacy -TargetHome $TargetHome -BackupRoot $BackupRoot
        Backup-Existing -Path $legacy -TargetHome $TargetHome -BackupRoot $BackupRoot
        Remove-Item -LiteralPath $legacy -Recurse -Force
        Write-Output "Removed $legacy; recovery: $recovery"
    }
    else {
        Remove-Item -LiteralPath $legacy -Recurse -Force
        Write-Output "Removed $legacy; recovery unavailable"
    }
}

$script:CleanupFailed = $false
if (-not $SkipSkills) {
    if ($repoMode) {
        Install-Skills -TargetHome $CodexHome -Label 'Codex' -BackupRoot $codexBackupRoot
        Install-Skills -TargetHome $ClaudeHome -Label 'Claude' -BackupRoot $claudeBackupRoot
        Remove-LegacySkill -TargetHome $CodexHome -Label 'Codex' -BackupRoot $codexBackupRoot
        Remove-LegacySkill -TargetHome $ClaudeHome -Label 'Claude' -BackupRoot $claudeBackupRoot
    }
    else {
        Write-Output 'Installed-skill mode detected; skipping modular skills. Clone the full repository to install skills/*.'
    }
}

if ($DryRun) {
    Write-Output 'Dry run complete. No files were changed.'
}
else {
    Write-Output 'Install complete. Restart Codex and Claude Code sessions to load the new global guides.'
}

if ($script:CleanupFailed) {
    throw 'Legacy skill cleanup was not completed because replacement validation failed.'
}
