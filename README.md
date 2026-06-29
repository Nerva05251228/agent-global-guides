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

Existing target files are backed up with a timestamp before replacement.

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

The skill includes its own copy of the sanitized templates under `skills/agent-guides-installer/assets/guides/`, so it can install even when only the skill path is available.

## What Was Sanitized

These files are intended as reusable templates. Personal and machine-specific values are represented with placeholders, including:

- GitHub owner / username
- Git commit email
- Local example file paths
- Business-specific callback route examples

Before using these guides on a real machine, replace placeholders such as `<your-github-username>` and `<your-git-email@example.com>` with local values.

## Notes

The English files are the intended source of truth for global agent configuration. The Chinese files are reference translations for review and discussion.

Repository-specific rules should still live in the target repository's local agent docs, context docs, plans, ADRs, or domain documentation.
