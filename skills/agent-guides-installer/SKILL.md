---
name: agent-guides-installer
description: Install sanitized global Codex and Claude Code guide templates from this repository or from the installed skill assets. Use when the user asks to install, update, verify, dry-run, bootstrap, or scan agent global guides, AGENTS.md, CLAUDE.md, Codex global instructions, or Claude global instructions from this guide package.
---

# Agent Guides Installer

Install sanitized global guide templates for Codex and Claude Code.

This skill supports two modes:

- Repository mode: the user cloned this repository and wants to install `docs/AGENTS.md` and `docs/CLAUDE.md`.
- Installed-skill mode: this skill was installed separately, and the templates in `assets/guides/` are the source.

## Workflow

1. Identify the source directory:
   - Prefer the repository `docs/` directory when it exists.
   - Otherwise use this skill's `assets/guides/` directory.
2. Run the scan before installing:

   ```bash
   skills/agent-guides-installer/scripts/scan-guides.sh --source docs
   ```

   If running from an installed skill without the repository root, use:

   ```bash
   <skill-dir>/scripts/scan-guides.sh
   ```

3. Run a dry-run install:

   ```bash
   scripts/install-global-guides.sh --dry-run
   ```

   Or, from an installed skill:

   ```bash
   <skill-dir>/scripts/install-global-guides.sh --dry-run
   ```

4. Install only after the scan and dry-run are acceptable:

   ```bash
   scripts/install-global-guides.sh
   ```

5. Report:
   - Which source directory was used.
   - Whether the scan passed.
   - Which global files were installed.
   - Whether existing files were backed up.
   - That new Codex and Claude Code sessions are needed to guarantee the new rules are loaded.

## Safety Rules

- Do not install unscanned templates unless the user explicitly asks to skip scanning.
- Do not overwrite existing global files without backup.
- Do not install the Chinese reference files as active global guides. They are review/reference copies only.
- Do not edit the user's current repository unless the user asked to update the guide package itself.
- If target global paths are read-only in the current sandbox, request escalation or explain the required manual command.

## Scripts

- `scripts/scan-guides.sh`: scans markdown templates for known personal values and common secret patterns.
- `scripts/install-global-guides.sh`: scans, backs up existing global files, installs English templates, and verifies copies.

Useful options:

- `--dry-run`: show actions without writing files.
- `--source <dir>`: install from an explicit source directory containing `AGENTS.md` and `CLAUDE.md`.
- `--codex-home <dir>`: override `${CODEX_HOME:-$HOME/.codex}`.
- `--claude-home <dir>`: override `${CLAUDE_HOME:-$HOME/.claude}`.
- `--skip-scan`: skip scanning only when the user explicitly accepts that risk.
