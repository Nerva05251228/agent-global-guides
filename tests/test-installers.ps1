[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$TestRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-guides-installers-" + [guid]::NewGuid().ToString('N'))
$PowerShellExe = (Get-Process -Id $PID).Path
$TestsRun = 0
$TestsPassed = 0
$TestsFailed = 0
$TestsSkipped = 0
$TestWasSkipped = $false
$CaseDir = $null
$FixtureRepo = $null
$LastStatus = 0
$LastOutput = ''

New-Item -ItemType Directory -Path $TestRoot | Out-Null

function Write-Skip {
    param([string]$Message)
    $script:TestsSkipped++
    $script:TestWasSkipped = $true
    Write-Host "SKIP: $Message"
}

function Invoke-Test {
    param(
        [string]$Name,
        [scriptblock]$Body
    )

    $script:TestsRun++
    $script:TestWasSkipped = $false
    try {
        & $Body
        if (-not $script:TestWasSkipped) {
            $script:TestsPassed++
            Write-Host "PASS: $Name"
        }
    }
    catch {
        $script:TestsFailed++
        Write-Error "FAIL: $Name`n$($_.Exception.Message)" -ErrorAction Continue
    }
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Success {
    Assert-True ($script:LastStatus -eq 0) "Expected success, got exit $script:LastStatus. Output: $script:LastOutput"
}

function Assert-Failure {
    Assert-True ($script:LastStatus -ne 0) "Expected a non-zero exit. Output: $script:LastOutput"
}

function Assert-OutputContains {
    param([string]$Needle)
    Assert-True ($script:LastOutput.Contains($Needle)) "Expected output to contain '$Needle'. Output: $script:LastOutput"
}

function Assert-OutputMatches {
    param([string]$Pattern)
    Assert-True ($script:LastOutput -match $Pattern) "Expected output to match /$Pattern/. Output: $script:LastOutput"
}

function Assert-OutputLineContainsAndMatches {
    param(
        [string]$Needle,
        [string]$Pattern
    )
    $matchingLines = @($script:LastOutput -split '\r?\n' | Where-Object { $_.Contains($Needle) })
    Assert-True ($matchingLines.Count -gt 0) "Expected an output line containing '$Needle'."
    Assert-True (($matchingLines | Where-Object { $_ -match $Pattern }).Count -gt 0) "Expected the line containing '$Needle' to match /$Pattern/. Lines: $($matchingLines -join ' | ')"
}

function New-RepoFixture {
    param([string]$Name)

    $script:CaseDir = Join-Path $TestRoot $Name
    $script:FixtureRepo = Join-Path $script:CaseDir 'repo'
    New-Item -ItemType Directory -Path $script:FixtureRepo -Force | Out-Null
    foreach ($directory in @('docs', 'scripts', 'skills')) {
        Copy-Item -LiteralPath (Join-Path $RepoRoot $directory) -Destination $script:FixtureRepo -Recurse
    }
    foreach ($file in @('README.md', 'CHANGELOG.md', '.gitignore')) {
        Copy-Item -LiteralPath (Join-Path $RepoRoot $file) -Destination $script:FixtureRepo
    }
}

function Invoke-Installer {
    param([string[]]$InstallerArguments)

    $installer = Join-Path $script:FixtureRepo 'skills\agent-guides-installer\scripts\install-global-guides.ps1'
    $hostArguments = @('-NoProfile', '-NonInteractive')
    if ($env:OS -eq 'Windows_NT') {
        $hostArguments += @('-ExecutionPolicy', 'Bypass')
    }
    $hostArguments += @('-File', $installer)
    $hostArguments += $InstallerArguments

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $PowerShellExe @hostArguments 2>&1 | ForEach-Object { $_.ToString() }
        $script:LastStatus = $LASTEXITCODE
        $script:LastOutput = $output -join [Environment]::NewLine
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

function Get-TreeFingerprint {
    param([string]$Root)

    if (-not (Test-Path -LiteralPath $Root)) {
        return 'ABSENT'
    }

    $resolvedRoot = (Resolve-Path -LiteralPath $Root).Path.TrimEnd([char[]]@('\', '/'))
    $records = foreach ($item in Get-ChildItem -LiteralPath $resolvedRoot -Force -Recurse | Sort-Object FullName) {
        $relative = $item.FullName.Substring($resolvedRoot.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
        if ($item.PSIsContainer) {
            "D $relative"
        }
        else {
            $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
            "F $relative $($item.Length) $hash"
        }
    }
    return $records -join "`n"
}

function Set-ChangedTargets {
    param(
        [string]$CodexHome,
        [string]$ClaudeHome
    )

    $codexSkill = Join-Path $CodexHome 'skills\codex-subagent-orchestration'
    $claudeSkill = Join-Path $ClaudeHome 'skills\claude-subagent-orchestration'
    New-Item -ItemType Directory -Path $codexSkill -Force | Out-Null
    New-Item -ItemType Directory -Path $claudeSkill -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $CodexHome 'AGENTS.md') -Value 'old-codex-guide'
    Set-Content -LiteralPath (Join-Path $ClaudeHome 'CLAUDE.md') -Value 'old-claude-guide'
    Set-Content -LiteralPath (Join-Path $codexSkill 'SKILL.md') -Value 'old-codex-skill'
    Set-Content -LiteralPath (Join-Path $claudeSkill 'SKILL.md') -Value 'old-claude-skill'
}

function Set-LegacySkills {
    param(
        [string]$CodexHome,
        [string]$ClaudeHome
    )

    foreach ($targetHome in @($CodexHome, $ClaudeHome)) {
        $legacy = Join-Path $targetHome 'skills\subagent-orchestration'
        New-Item -ItemType Directory -Path $legacy -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $legacy 'SKILL.md') -Value 'legacy-skill'
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

function Find-FileContaining {
    param(
        [string]$Root,
        [string]$Text
    )
    if (-not (Test-Path -LiteralPath $Root)) {
        return $false
    }
    foreach ($file in Get-ChildItem -LiteralPath $Root -File -Recurse) {
        if ((Get-Content -LiteralPath $file.FullName -Raw).Contains($Text)) {
            return $true
        }
    }
    return $false
}

function Assert-CriticalGuidePolicies {
    param([string]$Repo)

    $guidePaths = @(
        'docs\AGENTS.md',
        'docs\CLAUDE.md',
        'skills\agent-guides-installer\assets\guides\AGENTS.md',
        'skills\agent-guides-installer\assets\guides\CLAUDE.md'
    )
    foreach ($relativePath in $guidePaths) {
        $content = Get-Content -LiteralPath (Join-Path $Repo $relativePath) -Raw
        foreach ($pattern in @(
            'ask whether to run `setup-matt-pocock-skills`',
            '\.debug/YYYY-MM-DD/',
            'Never clean it automatically',
            'ISO-8601',
            'reopen',
            'gpt-5\.5',
            'xhigh',
            'Never silently substitute',
            'failed with reason',
            'residual risk',
            'rollback or recovery'
        )) {
            Assert-True ($content -match $pattern) "Missing critical policy /$pattern/ in $relativePath."
        }
    }
}

try {
    $expectedInstaller = Join-Path $RepoRoot 'skills\agent-guides-installer\scripts\install-global-guides.ps1'
    if (-not (Test-Path -LiteralPath $expectedInstaller)) {
        $TestsRun++
        $TestsFailed++
        Write-Error "FAIL: PowerShell installer exists`nMissing expected installer: $expectedInstaller" -ErrorAction Continue
    }
    else {
        Invoke-Test 'critical policies are present in both English guides and installer assets' {
            Assert-CriticalGuidePolicies $RepoRoot
        }

        Invoke-Test 'PowerShell dry-run writes nothing' {
            New-RepoFixture 'ps-dry-run'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            Set-ChangedTargets $codexHome $claudeHome
            Set-LegacySkills $codexHome $claudeHome
            $beforeCodex = Get-TreeFingerprint $codexHome
            $beforeClaude = Get-TreeFingerprint $claudeHome

            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-DryRun', '-Backup')
            Assert-Success
            Assert-True ((Get-TreeFingerprint $codexHome) -eq $beforeCodex) 'Dry-run changed the Codex home.'
            Assert-True ((Get-TreeFingerprint $claudeHome) -eq $beforeClaude) 'Dry-run changed the Claude home.'
            Assert-OutputMatches 'dry.run.*no files (were )?changed'
        }

        Invoke-Test 'PowerShell identity flags render without modifying sanitized sources' {
            New-RepoFixture 'ps-identity-render'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            $agentsSource = Join-Path $FixtureRepo 'docs\AGENTS.md'
            $claudeSource = Join-Path $FixtureRepo 'docs\CLAUDE.md'
            $agentsHash = (Get-FileHash -LiteralPath $agentsSource -Algorithm SHA256).Hash
            $claudeHash = (Get-FileHash -LiteralPath $claudeSource -Algorithm SHA256).Hash

            Invoke-Installer @(
                '-CodexHome', $codexHome,
                '-ClaudeHome', $claudeHome,
                '-GitHubOwner', 'rendered-owner',
                '-GitEmail', 'rendered.user@example.com',
                '-NoBackup'
            )
            Assert-Success
            $agentsInstalled = Get-Content -LiteralPath (Join-Path $codexHome 'AGENTS.md') -Raw
            $claudeInstalled = Get-Content -LiteralPath (Join-Path $claudeHome 'CLAUDE.md') -Raw
            Assert-True ($agentsInstalled.Contains('rendered-owner')) 'Codex owner was not rendered.'
            Assert-True ($agentsInstalled.Contains('rendered.user@example.com')) 'Codex email was not rendered.'
            Assert-True ($claudeInstalled.Contains('rendered-owner')) 'Claude owner was not rendered.'
            Assert-True ($claudeInstalled.Contains('rendered.user@example.com')) 'Claude email was not rendered.'
            Assert-True ((Get-Content -LiteralPath $agentsSource -Raw).Contains('<your-github-username>')) 'AGENTS.md source placeholder changed.'
            Assert-True ((Get-Content -LiteralPath $claudeSource -Raw).Contains('<your-git-email@example.com>')) 'CLAUDE.md source placeholder changed.'
            Assert-True ((Get-FileHash -LiteralPath $agentsSource -Algorithm SHA256).Hash -eq $agentsHash) 'AGENTS.md source changed during rendering.'
            Assert-True ((Get-FileHash -LiteralPath $claudeSource -Algorithm SHA256).Hash -eq $claudeHash) 'CLAUDE.md source changed during rendering.'
        }

        Invoke-Test 'PowerShell preserves existing non-placeholder identities without flags' {
            New-RepoFixture 'ps-identity-preserve'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            New-Item -ItemType Directory -Path $codexHome, $claudeHome -Force | Out-Null
            $agents = (Get-Content -LiteralPath (Join-Path $FixtureRepo 'docs\AGENTS.md') -Raw).
                Replace('<your-github-username>', 'preserved-codex-owner').
                Replace('<your-git-email@example.com>', 'preserved.codex@example.com')
            $claude = (Get-Content -LiteralPath (Join-Path $FixtureRepo 'docs\CLAUDE.md') -Raw).
                Replace('<your-github-username>', 'preserved-claude-owner').
                Replace('<your-git-email@example.com>', 'preserved.claude@example.com')
            Set-Content -LiteralPath (Join-Path $codexHome 'AGENTS.md') -Value $agents -NoNewline
            Set-Content -LiteralPath (Join-Path $claudeHome 'CLAUDE.md') -Value $claude -NoNewline

            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-NoBackup')
            Assert-Success
            $installedAgents = Get-Content -LiteralPath (Join-Path $codexHome 'AGENTS.md') -Raw
            $installedClaude = Get-Content -LiteralPath (Join-Path $claudeHome 'CLAUDE.md') -Raw
            Assert-True ($installedAgents.Contains('preserved-codex-owner')) 'Existing Codex owner was not preserved.'
            Assert-True ($installedAgents.Contains('preserved.codex@example.com')) 'Existing Codex email was not preserved.'
            Assert-True ($installedClaude.Contains('preserved-claude-owner')) 'Existing Claude owner was not preserved.'
            Assert-True ($installedClaude.Contains('preserved.claude@example.com')) 'Existing Claude email was not preserved.'
        }

        Invoke-Test 'PowerShell backup is outside active skills directories' {
            New-RepoFixture 'ps-external-backup'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            Set-ChangedTargets $codexHome $claudeHome

            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-Backup')
            Assert-Success
            $codexBackup = Join-Path $codexHome 'backups\agent-global-guides'
            $claudeBackup = Join-Path $claudeHome 'backups\agent-global-guides'
            Assert-True (Test-Path -LiteralPath $codexBackup -PathType Container) 'Codex external backup root was not created.'
            Assert-True (Test-Path -LiteralPath $claudeBackup -PathType Container) 'Claude external backup root was not created.'
            $codexSnapshots = @(Get-ChildItem -LiteralPath $codexBackup -Directory)
            $claudeSnapshots = @(Get-ChildItem -LiteralPath $claudeBackup -Directory)
            Assert-True ($codexSnapshots.Count -eq 1) 'Codex backup root does not contain exactly one timestamp snapshot.'
            Assert-True ($claudeSnapshots.Count -eq 1) 'Claude backup root does not contain exactly one timestamp snapshot.'
            Assert-True ($codexSnapshots[0].Name -match '^\d{8}-\d{6}([-.]\d+)?$') 'Codex backup snapshot is not timestamp-named.'
            Assert-True ($claudeSnapshots[0].Name -match '^\d{8}-\d{6}([-.]\d+)?$') 'Claude backup snapshot is not timestamp-named.'
            Assert-True (Find-FileContaining $codexBackup 'old-codex-guide') 'Old Codex guide was not backed up externally.'
            Assert-True (Find-FileContaining $claudeBackup 'old-claude-skill') 'Old Claude skill was not backed up externally.'
            $activeBackups = Get-ChildItem -Path (Join-Path $codexHome 'skills'), (Join-Path $claudeHome 'skills') -Filter '*.bak.*' -Recurse -ErrorAction SilentlyContinue
            Assert-True ($null -eq $activeBackups) 'A backup was left inside an active skills directory.'
            Assert-OutputMatches 'backup.*agent-global-guides'
        }

        Invoke-Test 'PowerShell no-backup reports unavailable recovery' {
            New-RepoFixture 'ps-no-backup'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            Set-ChangedTargets $codexHome $claudeHome
            Set-LegacySkills $codexHome $claudeHome

            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-NoBackup')
            Assert-Success
            Assert-True (-not (Test-Path -LiteralPath (Join-Path $codexHome 'backups\agent-global-guides'))) 'Codex backup exists despite -NoBackup.'
            Assert-True (-not (Test-Path -LiteralPath (Join-Path $claudeHome 'backups\agent-global-guides'))) 'Claude backup exists despite -NoBackup.'
            $unexpectedBackups = @(Get-ChildItem -Path $codexHome, $claudeHome -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match '\.bak\.' -or $_.FullName -match '[\\/]backups[\\/]agent-global-guides[\\/]'
            })
            Assert-True ($unexpectedBackups.Count -eq 0) 'A backup artifact exists despite -NoBackup.'
            Assert-OutputMatches 'recovery unavailable'
            Assert-OutputLineContainsAndMatches (Join-Path $codexHome 'skills\subagent-orchestration') 'removed'
            Assert-OutputLineContainsAndMatches (Join-Path $claudeHome 'skills\subagent-orchestration') 'removed'
        }

        Invoke-Test 'PowerShell non-interactive install defaults to backup' {
            New-RepoFixture 'ps-noninteractive-default'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            Set-ChangedTargets $codexHome $claudeHome

            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome)
            Assert-Success
            Assert-True (Test-Path -LiteralPath (Join-Path $codexHome 'backups\agent-global-guides') -PathType Container) 'Non-interactive install did not default to backup.'
            $promptMatches = [regex]::Matches($LastOutput, 'back[ -]?up.*\[[Yy]/[Nn]\]', 'IgnoreCase')
            Assert-True ($promptMatches.Count -eq 0) 'Non-interactive install emitted an interactive prompt.'
        }

        Invoke-Test 'PowerShell interactive install asks exactly one backup question' {
            New-RepoFixture 'ps-interactive-default'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            Set-ChangedTargets $codexHome $claudeHome
            $installer = Join-Path $FixtureRepo 'skills\agent-guides-installer\scripts\install-global-guides.ps1'
            $runner = Join-Path $CaseDir 'interactive-runner.ps1'
            $runnerContent = @'
param([string]$Installer, [string]$CodexHome, [string]$ClaudeHome)
$script:BackupPromptCount = 0
function global:Read-Host {
    param([string]$Prompt)
    if ($Prompt -match 'back[ -]?up') { $script:BackupPromptCount++ }
    return 'y'
}
try {
    . $Installer -CodexHome $CodexHome -ClaudeHome $ClaudeHome -DryRun
    Write-Output "PROMPT_COUNT=$script:BackupPromptCount"
}
finally {
    Remove-Item Function:\Read-Host -ErrorAction SilentlyContinue
}
'@
            Set-Content -LiteralPath $runner -Value $runnerContent -NoNewline
            $previousErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                $output = & $PowerShellExe -NoProfile -File $runner -Installer $installer -CodexHome $codexHome -ClaudeHome $claudeHome 2>&1 | ForEach-Object { $_.ToString() }
                $status = $LASTEXITCODE
            }
            finally {
                $ErrorActionPreference = $previousErrorActionPreference
            }
            Assert-True ($status -eq 0) "Interactive dry-run failed: $($output -join [Environment]::NewLine)"
            $countLines = @($output | Where-Object { $_ -match '^PROMPT_COUNT=' })
            Assert-True ($countLines.Count -eq 1) 'Interactive runner did not report exactly one prompt count.'
            Assert-True ($countLines[0] -eq 'PROMPT_COUNT=1') "Expected exactly one backup prompt. Output: $($output -join [Environment]::NewLine)"
        }

        Invoke-Test 'PowerShell legacy cleanup requires valid recursive replacements and frontmatter names' {
            New-RepoFixture 'ps-legacy-cleanup'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            Set-LegacySkills $codexHome $claudeHome

            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-Backup')
            Assert-Success
            foreach ($targetHome in @($codexHome, $claudeHome)) {
                foreach ($replacement in @('codex-subagent-orchestration', 'claude-subagent-orchestration')) {
                    $source = Join-Path $FixtureRepo "skills\$replacement"
                    $installed = Join-Path $targetHome "skills\$replacement"
                    Assert-True ((Get-TreeFingerprint $source) -eq (Get-TreeFingerprint $installed)) "$replacement in $targetHome differs recursively from source."
                    Assert-True ((Get-FrontmatterName (Join-Path $installed 'SKILL.md')) -eq $replacement) "$replacement frontmatter name is invalid in $targetHome."
                }
            }
            Assert-True (-not (Test-Path -LiteralPath (Join-Path $codexHome 'skills\subagent-orchestration'))) 'Codex legacy skill was not removed.'
            Assert-True (-not (Test-Path -LiteralPath (Join-Path $claudeHome 'skills\subagent-orchestration'))) 'Claude legacy skill was not removed.'
            Assert-OutputLineContainsAndMatches (Join-Path $codexHome 'skills\subagent-orchestration') 'removed'
            Assert-OutputLineContainsAndMatches (Join-Path $claudeHome 'skills\subagent-orchestration') 'removed'
            $codexSnapshot = @(Get-ChildItem -LiteralPath (Join-Path $codexHome 'backups\agent-global-guides') -Directory)[0].FullName
            $claudeSnapshot = @(Get-ChildItem -LiteralPath (Join-Path $claudeHome 'backups\agent-global-guides') -Directory)[0].FullName
            Assert-OutputContains (Join-Path $codexSnapshot 'skills\subagent-orchestration')
            Assert-OutputContains (Join-Path $claudeSnapshot 'skills\subagent-orchestration')
        }

        Invoke-Test 'PowerShell malformed replacements keep legacy skills' {
            New-RepoFixture 'ps-malformed-replacements'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            Set-LegacySkills $codexHome $claudeHome
            $codexSkill = Join-Path $FixtureRepo 'skills\codex-subagent-orchestration\SKILL.md'
            $content = (Get-Content -LiteralPath $codexSkill -Raw).Replace('name: codex-subagent-orchestration', 'name: wrong-codex-name')
            Set-Content -LiteralPath $codexSkill -Value $content -NoNewline
            Remove-Item -LiteralPath (Join-Path $FixtureRepo 'skills\claude-subagent-orchestration\SKILL.md')

            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-NoBackup')
            Assert-True (Test-Path -LiteralPath (Join-Path $codexHome 'skills\subagent-orchestration\SKILL.md')) 'Malformed Codex replacement allowed legacy removal.'
            Assert-True (Test-Path -LiteralPath (Join-Path $claudeHome 'skills\subagent-orchestration\SKILL.md')) 'Incomplete Claude replacement allowed legacy removal.'
            Assert-OutputMatches 'verification failed|validation failed|cannot remove|not removed|kept'
        }

        Invoke-Test 'PowerShell body name cannot bypass frontmatter validation' {
            New-RepoFixture 'ps-body-name-bypass'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            Set-LegacySkills $codexHome $claudeHome
            $codexSkill = Join-Path $FixtureRepo 'skills\codex-subagent-orchestration\SKILL.md'
            $content = (Get-Content -LiteralPath $codexSkill -Raw).
                Replace('name: codex-subagent-orchestration', 'title: invalid-frontmatter')
            $content += "`nname: codex-subagent-orchestration`n"
            Set-Content -LiteralPath $codexSkill -Value $content -NoNewline

            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-NoBackup')
            Assert-Failure
            Assert-True (Test-Path -LiteralPath (Join-Path $codexHome 'skills\subagent-orchestration\SKILL.md')) 'Body name bypass allowed Codex legacy removal.'
            Assert-True (Test-Path -LiteralPath (Join-Path $claudeHome 'skills\subagent-orchestration\SKILL.md')) 'Body name bypass allowed Claude legacy removal.'
            Assert-OutputMatches 'verification failed|validation failed|cannot remove|not removed|kept'
        }

        Invoke-Test 'PowerShell dry-run reports exact legacy removal and recovery policy' {
            New-RepoFixture 'ps-cleanup-dry-run-backup'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            Set-LegacySkills $codexHome $claudeHome

            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-DryRun', '-Backup')
            Assert-Success
            Assert-OutputLineContainsAndMatches (Join-Path $codexHome 'skills\subagent-orchestration') 'would remove|planned removal'
            Assert-OutputLineContainsAndMatches (Join-Path $claudeHome 'skills\subagent-orchestration') 'would remove|planned removal'
            Assert-OutputMatches 'backup.*agent-global-guides'
            Assert-True (Test-Path -LiteralPath (Join-Path $codexHome 'skills\subagent-orchestration\SKILL.md')) 'Dry-run removed the Codex legacy skill.'

            New-RepoFixture 'ps-cleanup-dry-run-no-backup'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            Set-LegacySkills $codexHome $claudeHome
            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-DryRun', '-NoBackup')
            Assert-Success
            Assert-OutputLineContainsAndMatches (Join-Path $codexHome 'skills\subagent-orchestration') 'would remove|planned removal'
            Assert-OutputLineContainsAndMatches (Join-Path $claudeHome 'skills\subagent-orchestration') 'would remove|planned removal'
            Assert-OutputMatches 'recovery unavailable'
        }

        Invoke-Test 'PowerShell every dry-run and real install invokes the scanner' {
            New-RepoFixture 'ps-scanner-invocation'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            $scanner = Join-Path $FixtureRepo 'skills\agent-guides-installer\scripts\scan-guides.ps1'
            $realScanner = Join-Path $CaseDir 'real-scan-guides.ps1'
            $scanLog = Join-Path $CaseDir 'scan.log'
            Copy-Item -LiteralPath $scanner -Destination $realScanner
            @'
Add-Content -LiteralPath $env:AGENT_GUIDES_TEST_SCAN_LOG -Value 'scan'
& $env:AGENT_GUIDES_REAL_SCANNER @args
exit $LASTEXITCODE
'@ | Set-Content -LiteralPath $scanner -NoNewline
            $env:AGENT_GUIDES_TEST_SCAN_LOG = $scanLog
            $env:AGENT_GUIDES_REAL_SCANNER = $realScanner
            try {
                Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-DryRun', '-Backup')
                Assert-Success
                Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-DryRun', '-NoBackup')
                Assert-Success
                Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-DryRun')
                Assert-Success
                Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-Backup')
                Assert-Success
                Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-NoBackup')
                Assert-Success
                Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome)
                Assert-Success
            }
            finally {
                Remove-Item Env:AGENT_GUIDES_TEST_SCAN_LOG -ErrorAction SilentlyContinue
                Remove-Item Env:AGENT_GUIDES_REAL_SCANNER -ErrorAction SilentlyContinue
            }
            $scanLines = @(Get-Content -LiteralPath $scanLog)
            Assert-True ($scanLines.Count -eq 6) 'Expected one scanner invocation per install.'
        }

        Invoke-Test 'PowerShell scanner failure exits before target writes' {
            New-RepoFixture 'ps-scanner-failure'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            New-Item -ItemType Directory -Path (Join-Path $codexHome 'skills\sentinel'), (Join-Path $claudeHome 'skills\sentinel') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $codexHome 'skills\sentinel\value.txt') -Value 'codex-sentinel'
            Set-Content -LiteralPath (Join-Path $claudeHome 'skills\sentinel\value.txt') -Value 'claude-sentinel'
            Set-Content -LiteralPath (Join-Path $FixtureRepo 'docs\scan-contract-leak.sh') -Value ('leak.user@' + 'invalid.test')
            $beforeCodex = Get-TreeFingerprint $codexHome
            $beforeClaude = Get-TreeFingerprint $claudeHome

            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-Backup')
            Assert-Failure
            Assert-OutputMatches 'scan failed|potential leak|real email address'
            Assert-True ((Get-TreeFingerprint $codexHome) -eq $beforeCodex) 'Codex home changed after scanner failure.'
            Assert-True ((Get-TreeFingerprint $claudeHome) -eq $beforeClaude) 'Claude home changed after scanner failure.'
        }

        Invoke-Test 'PowerShell installer exposes no SkipScan bypass' {
            New-RepoFixture 'ps-no-skip-scan'
            $codexHome = Join-Path $CaseDir 'codex-home'
            $claudeHome = Join-Path $CaseDir 'claude-home'
            Invoke-Installer @('-CodexHome', $codexHome, '-ClaudeHome', $claudeHome, '-DryRun', '-SkipScan')
            Assert-Failure
            Assert-OutputMatches 'parameter.*SkipScan|cannot be found|unrecognized'
            Assert-True (-not (Test-Path -LiteralPath $codexHome)) 'Rejected SkipScan invocation changed the Codex home.'
            Assert-True (-not (Test-Path -LiteralPath $claudeHome)) 'Rejected SkipScan invocation changed the Claude home.'
        }
    }
}
finally {
    Remove-Item -LiteralPath $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host ("PowerShell installer contract: {0} run, {1} passed, {2} failed, {3} skipped" -f $TestsRun, $TestsPassed, $TestsFailed, $TestsSkipped)

if ($TestsFailed -ne 0) {
    exit 1
}
