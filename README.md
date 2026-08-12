# Agent Global Guides

Sanitized, project-agnostic global instruction templates and skill-routed workflows for Codex and Claude Code.

## Package

- `docs/AGENTS.md`, `docs/CLAUDE.md`: concise English global guides.
- `docs/AGENTS.zh.md`, `docs/CLAUDE.zh.md`: synchronized Chinese review references.
- `skills/`: authoritative planning, repository governance, agent-specific orchestration, deployment, nginx, browser validation, handoff, image inspection, and installer workflows.
- `scripts/install-global-guides.sh`, `scripts/scan-guides.sh`: Linux/macOS entrypoints.
- `scripts/install-global-guides.ps1`, `scripts/scan-guides.ps1`: Windows PowerShell entrypoints.

## Install From A Clone

Scanning is mandatory and runs again inside every dry-run and real installation.

Linux or macOS:

```bash
scripts/scan-guides.sh
scripts/install-global-guides.sh --dry-run --backup
scripts/install-global-guides.sh --backup
```

Windows PowerShell:

```powershell
.\scripts\scan-guides.ps1
.\scripts\install-global-guides.ps1 -DryRun -Backup
.\scripts\install-global-guides.ps1 -Backup
```

Without an explicit backup flag, an interactive run asks once and defaults to backup; a non-interactive run backs up automatically. Use `--no-backup` or `-NoBackup` only when installer recovery is intentionally waived.

Backups are stored outside active skills at:

```text
<home>/backups/agent-global-guides/<timestamp>/
```

The installer writes English guides and, in repository mode, the complete `skills/*` package to both Codex and Claude homes. After validating both new orchestration skills, it removes the legacy `skills/subagent-orchestration` from both homes. Dry-run reports the exact planned removals.

## Local Identity Values

The repository keeps sanitized placeholders. Render local values during installation:

```bash
scripts/install-global-guides.sh --github-owner <owner> --git-email <email>
```

```powershell
.\scripts\install-global-guides.ps1 -GitHubOwner <owner> -GitEmail <email>
```

When identity flags are omitted, existing non-placeholder values in each local global guide are preserved. Source templates are never personalized.

## Installed-Skill Mode

Installing only `skills/agent-guides-installer` provides bundled templates under `assets/guides/`. That mode updates the global markdown guides only. Clone the full repository to install or update every modular skill and perform legacy cleanup.

## Verification And Restart

The project includes isolated Bash and PowerShell installer contracts and a Windows/Linux/macOS CI matrix. Tests never target real global homes.

Start new Codex and Claude Code sessions after installation because already-running sessions do not reliably reload global guides.

## Repository Scope

Always-loaded guides stay concise. Detailed workflows load through skills. Repository-specific rules still belong in the target repository's `AGENTS.md`, `CLAUDE.md`, `CONTEXT.md`, plans, ADRs, or domain documentation.
