# Agent Global Guides

Sanitized, project-agnostic global instruction templates for Codex and Claude Code.

## Contents

- `docs/AGENTS.md` - English global guide for Codex as the primary agent.
- `docs/CLAUDE.md` - English global guide for Claude Code as the primary agent.
- `docs/AGENTS.zh.md` - Chinese reference version for the Codex guide.
- `docs/CLAUDE.zh.md` - Chinese reference version for the Claude Code guide.

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
