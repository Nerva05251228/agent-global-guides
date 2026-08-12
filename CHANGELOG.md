# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). This project has not established a versioned release history yet, so current work remains under `Unreleased`.

## [Unreleased]

### Added

- Added native PowerShell scanner and installer support alongside Bash, with isolated Windows/Linux/macOS CI coverage.
- Added long-task recovery rules with tracked task books, ISO-8601 checklist evidence, reopening, and fallback history.
- Added clone-and-run installer scripts for sanitized global Codex and Claude Code guide templates.
- Added `agent-guides-installer` Codex skill with self-contained guide assets.
- Added scanner for known personal values and common secret patterns.
- Added modular skills for authoritative planning, Git repository governance, nginx management, deployment activation, browser validation, handoff context, image inspection, and Codex/Claude subagent orchestration.

### Changed

- Made scanning mandatory, added dry-run and explicit/interactive backup policies, preserved local identity values, and moved backups outside active skill directories.
- Added validated cleanup of the legacy combined orchestration skill after both replacement skills are installed in both homes.
- Standardized required-search routing and executor fallback disclosure while keeping agent delegation preferential rather than mandatory.
- Generalized deployment and nginx workflows around discovered Windows, Linux, macOS, container, proxy, and process-manager architecture.
- Updated Claude-native image inspection to use the required SDK path without hard-coded global module locations.
- Split long global guide workflows into modular skills while keeping `AGENTS.md` and `CLAUDE.md` slim.
- Split the combined `subagent-orchestration` skill into `codex-subagent-orchestration` and `claude-subagent-orchestration`.
- Added installer support for copying modular skills in repository mode and safely skipping skill installation in installed-skill mode.
- Expanded scanner coverage to shipped guide docs and skills.
