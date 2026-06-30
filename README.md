# Agent Global Guides

Sanitized, project-agnostic global instruction templates for Codex and Claude Code.

## Contents

- `docs/AGENTS.md` - English global guide for Codex as the primary agent.
- `docs/CLAUDE.md` - English global guide for Claude Code as the primary agent.
- `docs/AGENTS.zh.md` - Chinese reference version for the Codex guide.
- `docs/CLAUDE.zh.md` - Chinese reference version for the Claude Code guide.
- `scripts/install-global-guides.sh` - Clone-and-run installer for the English global guides.
- `scripts/scan-guides.sh` - Secret and personal-info scanner for the guide templates.
- `skills/agent-guides-installer/` - Codex skill for installing this guide package.
- `skills/authoritative-planning/` - Planning, checklists, verification evidence, and docs landing workflow.
- `skills/subagent-orchestration/` - Codex/Claude subagent dispatch, monitoring, permissions, and fallback workflow.
- `skills/nginx-service-management/` - Nginx inspection, modification, reload, removal, and port reporting workflow.
- `skills/deployment-activation/` - Frontend/backend/nginx deployment activation workflow.
- `skills/browser-validation/` - Browser, screenshot, trace, and real-machine validation workflow.
- `skills/handoff-context/` - Handoff prompt and context recovery workflow.
- `skills/claude-image-inspection/` - Claude-specific image inspection workflow.

## Install From a Clone

Run the scanner first:

```bash
scripts/scan-guides.sh
```

Preview the install:

```bash
scripts/install-global-guides.sh --dry-run
```

Install the English global guides:

```bash
scripts/install-global-guides.sh
```

The installer writes:

- `docs/AGENTS.md` to `${CODEX_HOME:-$HOME/.codex}/AGENTS.md`
- `docs/CLAUDE.md` to `${CLAUDE_HOME:-$HOME/.claude}/CLAUDE.md`
- `skills/*` to `${CODEX_HOME:-$HOME/.codex}/skills/`
- `skills/*` to `${CLAUDE_HOME:-$HOME/.claude}/skills/`

Existing target files and changed same-named skill directories are backed up with a timestamp before replacement. Identical skill directories are left in place. Use `--skip-skills` to install only the global markdown files.

Start new Codex and Claude Code sessions after installation to guarantee the new global rules are loaded.

## Install as a Codex Skill

From Codex, ask to install the skill from this repository path:

```text
Install the Codex skill from <owner>/<repo> path skills/agent-guides-installer
```

After installing the skill, restart Codex. Then ask:

```text
Use $agent-guides-installer to install the agent global guides.
```

The skill includes its own copy of the sanitized templates under `skills/agent-guides-installer/assets/guides/`, so it can install the global markdown files even when only the skill path is available. Installed-skill mode skips modular skills by design. Clone the full repository and run `scripts/install-global-guides.sh` when you also want `skills/*` installed.

## What Was Sanitized

These files are intended as reusable templates. Personal and machine-specific values are represented with placeholders, including:

- GitHub owner / username
- Git commit email
- Local example file paths
- Business-specific callback route examples

Before using these guides on a real machine, replace placeholders such as `<your-github-username>` and `<your-git-email@example.com>` with local values.

## Notes

The English files are the intended source of truth for global agent configuration. The Chinese files are reference translations for review and discussion.

The global `docs/AGENTS.md` and `docs/CLAUDE.md` files are intentionally slim. They keep always-loaded rules focused on safety, routing, and defaults. Longer task workflows live in skills and are loaded only when relevant.

Repository-specific rules should still live in the target repository's local agent docs, context docs, plans, ADRs, or domain documentation.
