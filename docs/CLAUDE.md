# Global Claude Agent Guide

## Purpose

This file is the global, always-loaded guide for Claude acting as the primary agent. Keep it small. Long, task-specific workflows live in skills and should be invoked only when relevant.

Repository-specific rules belong in the target repository's local `CLAUDE.md`, `CONTEXT.md`, or domain docs.

## Repository Bootstrap

When starting work in a project, first determine whether a repository already exists.

If no repository exists, ask whether to create one. If the user wants a new repository, use:

- GitHub owner / username: `<your-github-username>`
- Commit email, when a local Git identity is needed: `<your-git-email@example.com>`
- Repository visibility: private, unless the user explicitly requests public

After a repository exists, initialize the project with `setup-matt-pocock-skills`. If it asks about issue tracking, triage labels, domain documents, or related defaults, and the user says to use defaults, accept the defaults without asking more questions.

## Core Operating Rules

Use `.debug/` for local-only debugging artifacts: logs, screenshots, traces, subagent logs, task specs, and temporary captures. Keep `.debug/` Git-ignored and do not commit it.

For multi-step work, create or identify an authoritative plan before implementation. Chat messages are not the authoritative plan unless the same plan is written to a repository document. Use `$authoritative-planning` for plan/checklist details.

If active context is unclear, the conversation appears compacted, or work resumes after interruption, inspect repository plan documents before continuing from memory. If no plan exists or it is stale, update it before dependent non-trivial work.

Docs are the planning baseline, but self-consistent docs are not proof that implementation works. Completed items need implementation, real checks, updated owning docs, reconciled decision changes, `changelog.md` when appropriate, and immediate checklist updates.

Use explicit verification statuses: `verified`, `failed with reason`, or `not verified`.

## Skill Routing

Invoke these skills for long or task-specific workflows:

- `$authoritative-planning`: multi-step plans, child task docs, checklists, executor records, verification evidence, progress recovery, and implementation-to-documentation landing.
- `$subagent-orchestration`: Codex/Claude subagent routing, task specs, parallel/serial dispatch, read-only/editable invocation, stream logs, timeouts, retries, and fallback.
- `$nginx-service-management`: nginx inspection, route changes, service add/remove, SSL/proxy caution, listener/proxy port reporting, and production web-server config.
- `$deployment-activation`: frontend rebuild/deploy, nginx root/API proxy discovery, FastAPI process restart, health/API/frontend verification, and making current project changes take effect.
- `$browser-validation`: Playwright/headless browser checks, screenshots, traces, Xvfb, canvas/UI rendering evidence, and real-machine validation.
- `$handoff-context`: handoff prompts, context summaries, repo state verification, discrepancy reporting, and next-session instructions.
- `$claude-image-inspection`: Claude-specific image reading through the Claude Agent SDK path and image judgment logs.
- `$agent-guides-installer`: install, scan, dry-run, or update this global guide package.

When a task involves web search, latest information, external official docs, prices, laws, versions, news, online fact-checking, or information that may change over time, use a single-turn Codex subagent for search. Do not let Claude directly perform web search by default. The Codex search task must search/verify/summarize only, avoid repository edits, include source links, distinguish source-confirmed facts from inference, and return `verified`, `failed with reason`, or `not verified`.

## Subagent Defaults

Before starting any non-trivial plan item, decide and record the executor: `Primary Claude`, `Codex subagent`, `Claude subagent`, or another named agent. Record the dispatch reason and verification owner.

Default routing when Claude is primary:

- Use Codex subagents by default for backend work, infrastructure, repository edits, refactors, migrations, build/test loops, mechanical migrations, log analysis, full-codebase search, and process or service management.
- Use Claude directly, or dispatch Claude subagents, for frontend product/design/development work, including UI/UX design, component implementation, layout and styling, interaction behavior, browser-facing copy, frontend review, and image inspection through the Claude SDK path.
- Use Claude subagents for independent reasoning, critique, planning, spec review, product copy review, documentation critique, architecture review, or second-pass judgment.
- If a Codex subagent is unavailable or fails, Claude may handle backend or infrastructure work directly or dispatch a Claude subagent instead, but record the reason.
- Keep planning, review, integration, dangerous operations, final verification, and acceptance with the primary Claude agent.

Prefer parallel subagents for independent workstreams after assigning clear ownership boundaries. If parallel work could contend for a database, repository, port, lockfile, process manager, production config, or the same files/modules, do not run those tasks in parallel. Parallel-unsafety is not a reason to skip useful subagents; use one serial subagent when helpful.

For nginx, production config, database migrations, auth, payments, certificates, process deletion, and other high-risk operations, subagents may draft analysis, patches, or command plans, but the primary Claude agent must perform or explicitly control final dangerous steps and verification.

Do not accept a subagent self-report alone. Independently review diffs, rerun relevant checks, confirm behavior, and verify docs/changelog updates when required.

## High-Risk Safety

Never delete databases, clear user uploads, modify production secrets, print private key contents, or change production keys unless the user explicitly authorizes that exact operation.

Do not repeat-start duplicate backend processes. Before restarting a service, inspect how it is actually managed: PM2, systemd, supervisor, Docker, or manual process.

For nginx, inspect effective config with `nginx -T` before changes. Run `nginx -t` after edits and reload only after it succeeds. Distinguish public listener ports from backend proxy ports.

For websocket or long-running proxy routes, preserve `Upgrade`, `Connection`, longer timeouts, and `proxy_buffering off` unless it is explicitly safe to remove them.

Do not expose comments, development notes, implementation explanations, debug wording, or internal tool language in frontend UI. UI text must be written for end users.

Before committing or pushing to remote `main`:

1. Report the planned changes.
2. Update `changelog.md` when the repo uses it or the change is user-facing.
3. Wait for user confirmation.

## Rule Loading

Global guide edits affect only newly started sessions reliably. Already-running sessions do not automatically reload this file. If latest rules must apply, close the old session and start a new Claude Code session in the target directory.
