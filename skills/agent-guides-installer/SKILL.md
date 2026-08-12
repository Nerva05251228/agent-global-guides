---
name: agent-guides-installer
description: Use when a user asks to install, update, scan, dry-run, verify, or remove legacy versions of the global Codex and Claude guide package.
---

# Agent Guides Installer

## Modes

- Repository mode installs the English `docs/AGENTS.md`, `docs/CLAUDE.md`, and every modular `skills/*` directory into both Codex and Claude homes.
- Installed-skill mode uses `assets/guides/` and installs only the global markdown guides. Use a full repository clone to update all modular skills.

## Required workflow

1. Resolve the source and both target homes.
2. Run the mandatory scanner. There is no scan bypass.
3. Run a dry-run with the intended identity and backup options.
4. Ask for approval before a real local installation when approval has not already been given.
5. Run the real installer and report every installed, unchanged, backed-up, removed, skipped, failed, or unverified target.
6. Start new Codex and Claude sessions after installation.

Linux and macOS:

```bash
scripts/scan-guides.sh
scripts/install-global-guides.sh --dry-run
scripts/install-global-guides.sh
```

Windows PowerShell:

```powershell
.\scripts\scan-guides.ps1
.\scripts\install-global-guides.ps1 -DryRun
.\scripts\install-global-guides.ps1
```

## Identity and backup policy

- Reusable source templates retain `<your-github-username>` and `<your-git-email@example.com>`.
- Explicit `--github-owner` / `-GitHubOwner` and `--git-email` / `-GitEmail` values are rendered only into installed targets.
- When flags are omitted, preserve existing non-placeholder local values independently in Codex and Claude guides.
- Interactive installation asks once whether to back up, defaulting to yes.
- Non-interactive installation defaults to backup.
- Use `--backup` / `-Backup` or `--no-backup` / `-NoBackup` to make the choice explicit.
- Backups belong under `<home>/backups/agent-global-guides/<timestamp>/`, outside active skill discovery.
- When backup is disabled, report that installer recovery is unavailable.

## Legacy skill cleanup

Repository-mode installation places both `codex-subagent-orchestration` and `claude-subagent-orchestration` into both homes. Remove `skills/subagent-orchestration` only after both installed replacement directories are recursively identical to source and each `SKILL.md` frontmatter name matches its directory. Malformed or incomplete replacements must keep the legacy skill and make cleanup fail explicitly.

Dry-run reports each exact planned removal and recovery policy. Real installation reports each removed path and its backup path or `recovery unavailable`. Cleanup is idempotent.

## Safety

- Scanner failure must exit before the first target write.
- Dry-run must not modify populated or absent targets.
- Never edit the source templates to personalize an installation.
- Never back up changed skills inside active `skills/` directories.
- Do not install modular skills when source and target resolve to the same directory.
- Chinese guide files are synchronized review references, not active installed guides.
- Do not modify a repository or real global homes outside the user's requested scope.

## Options

Bash: `--source`, `--codex-home`, `--claude-home`, `--github-owner`, `--git-email`, `--backup`, `--no-backup`, `--dry-run`, `--skip-skills`.

PowerShell: `-Source`, `-CodexHome`, `-ClaudeHome`, `-GitHubOwner`, `-GitEmail`, `-Backup`, `-NoBackup`, `-DryRun`, `-SkipSkills`.
