# Global Claude Agent Guide

## Purpose

This file is a global guide for Claude acting as the primary agent across repositories. It is intentionally project-agnostic. Repository-specific rules belong in the target repository's local `CLAUDE.md`, `CONTEXT.md`, or domain docs.

## Repository bootstrap

When starting work in a project, first determine whether a repository already exists.

If no repository exists, ask the user whether to create one. If the user wants a new repository, use:

- GitHub owner / username: `<your-github-username>`
- Commit email, when a local Git identity is needed: `<your-git-email@example.com>`
- Repository visibility: private, unless the user explicitly requests public

After a repository exists, initialize the project with `setup-matt-pocock-skills`.

If `setup-matt-pocock-skills` asks about issue tracking, triage labels, domain documents, or related defaults, and the user says to use the defaults, accept the defaults without asking more questions.

## Project structure and debug artifacts

Use a dedicated debug directory for local-only debugging artifacts.

Preferred root:

```text
.debug/
```

The debug directory is for logs, screenshots, traces, temporary captures, generated task specs, subagent logs, and other throwaway debugging output. It must be Git-ignored and must not be committed.

Organize debug artifacts by date and type. Prefer a structure like:

```text
.debug/
  2026-06-21/
    logs/
    screenshots/
    traces/
    subagents/
    codex-tasks/
    claude-tasks/
    image-inspection/
    temp/
```

Use stable filenames that explain what was captured. Avoid dumping unrelated files into one flat directory.

For design drafts, generated references, or non-debug temporary assets, use a separate local workspace such as `temp/` when the repository defines one. Keep `temp/` and `.debug/` separate.

## Issue tracker, triage labels, and domain docs

Issue tracking, triage labels, and domain documentation are normally created as a side effect of `setup-matt-pocock-skills`.

When the user says "all defaults" or equivalent, use the default setup directly.

Default expectations:

- Issues and PRDs are tracked in the configured issue tracker.
- Triage labels are created and used consistently.
- Domain docs, decision records, and context docs are the authoritative planning baseline.
- Local implementation must be landed back into the docs before downstream dependent work advances.

If a repository already has local instructions for issue tracking, labels, or domain docs, follow the repository-specific instructions unless the user explicitly overrides them.

## Authoritative plan and checklist rules

For multi-step work, create or identify an authoritative plan before implementation. Chat messages are not the authoritative plan unless the same plan is written to a repository document.

Use one main plan document for the overall objective. For larger work, split details into child documents and link them from the main plan.

Recommended layout when the repository has no stronger convention:

```text
docs/plans/<plan-name>.md
docs/plans/<plan-name>/<subtask>.md
```

The main plan should contain:

- Objective and non-goals.
- Links to child task documents.
- A Markdown checklist using `- [ ]` and `- [x]`.
- Acceptance checks for each item or linked child item.
- Executor for each item: `Primary Claude`, `Codex subagent`, `Claude subagent`, or another explicitly named agent.
- Dispatch reason for each non-trivial item, especially when the primary agent intentionally skips or routes around a useful subagent.
- A short progress log or links to dated validation artifacts.

Each child document should contain:

- Scope and owner agent, if subagents are used.
- Files or modules expected to change.
- Constraints and non-goals.
- Completion definition.
- Verification commands or manual checks.
- Executor, dispatch reason, and verification owner.
- A local checklist for its own subtasks.

Checklist discipline:

- Do not mark an item complete before implementation and verification are both done.
- After each item is completed and verified, immediately update the authoritative checklist from `- [ ]` to `- [x]`.
- Include the validation evidence beside the item or in the linked child document: command, test result, screenshot path, log path, diff reference, or explanation.
- Do not wait until the end to batch-check completed items.
- If an item is partially done, leave it unchecked and add a concise status note.
- If the plan changes, update the plan document before continuing dependent work.

Context recovery and compacted sessions:

- If the active plan is unclear, the conversation appears compacted or truncated, or work is resumed after an interruption, inspect the repository's authoritative plan documents before continuing from memory.
- Check local `CLAUDE.md`, `CONTEXT.md`, `docs/plans/`, relevant domain docs, task indexes, `changelog.md`, and dated `.debug/` artifacts such as subagent logs, validation logs, screenshots, and task specs.
- Treat the on-disk plan and checklist as the memory baseline. Reconcile them with `git status`, current files, running processes, and validation artifacts before taking dependent action.
- If no plan exists or the plan is stale, create or update the authoritative plan before continuing non-trivial work.

## Subagent orchestration and invocation

Prefer multiple subagents in parallel when a task has independent workstreams. The primary Claude agent must first design the split: define each subagent's scope, file or module ownership, shared resources, dependencies, and acceptance checks. Avoid assigning two agents to edit the same route, component, module, migration, lockfile, process manager entry, or production config unless one task is explicitly review-only or the work is sequenced.

The primary Claude agent remains responsible for planning, review, integration, final verification, and acceptance. Never trust a subagent's self-report alone. Before accepting work, independently:

- Review the diff against the task spec.
- Re-run the relevant build, validation, lint, tests, or project checks.
- Confirm that behavior is unchanged for pure refactors or structural splits.
- Confirm that docs and `changelog.md` were updated when required.

Do not reuse a completed subagent session for unrelated new work. Start a fresh subagent for each independent task.

Exception: when a task requires a continuous back-and-forth conversation with retained context, the same subagent session may stay open until the discussion is finished and the final unified result is confirmed. After that result is accepted, close that session and start a fresh one for unrelated work.

For complex work, keep capabilities, functions, modules, and responsibilities clearly separated.

Avoid piling unrelated behavior into one file. Aim for:

- High cohesion
- Low coupling
- Robustness
- Reuse only when reuse is justified

Do not expose comments, development notes, implementation explanations, debug wording, or internal tool language in frontend UI. UI text must be written for end users.

Before starting any non-trivial plan item, decide and record the executor in the authoritative plan:

```text
Executor: Primary Claude / Codex subagent / Claude subagent / other named agent
Dispatch reason:
Verification owner:
```

Default routing when Claude is the primary agent:

- Use Codex subagents by default for backend work, infrastructure, repository edits, refactors, migrations, build/test loops, mechanical migrations, log analysis, full-codebase search, and process or service management.
- Use Claude directly, or dispatch Claude subagents, for frontend product/design/development work, including UI/UX design, component implementation, layout and styling, interaction behavior, browser-facing copy, frontend review, and image inspection through the Claude SDK path.
- Use Claude subagents for independent reasoning, critique, planning, spec review, product copy review, documentation critique, architecture review, or another second-pass judgment task.
- If a Codex subagent is unavailable or fails, Claude may handle backend or infrastructure work directly or dispatch a Claude subagent instead, but the reason must be recorded.
- Keep planning, integration, dangerous operations, final verification, and acceptance with the primary Claude agent.
- For nginx, production config, database migrations, auth, payments, certificates, process deletion, and other high-risk operations, subagents may draft analysis, patches, or command plans, but the primary Claude agent must perform or explicitly control the final dangerous step and verification.

Parallel dispatch safety:

- Prefer parallel subagents for independent workstreams after the primary agent has assigned clear ownership boundaries.
- If parallel subagents could contend for a database, repository, port, lockfile, process manager, production config, or the same files/modules, do not run those tasks in parallel.
- Parallel-unsafety is not a reason to skip subagents entirely. Use one serial subagent when independent implementation, review, or analysis is still useful.

Allowed direct-primary-agent exceptions:

- The task is genuinely small and single-step, such as a tiny config read, one-line edit, or simple command.
- The user explicitly says not to use subagents.
- The relevant subagent tool is unavailable or has failed, and the failure is recorded.
- The task requires private parent-session context, live user interaction, or an active permission state that cannot be safely handed off.
- The work is an urgent fix where dispatch overhead would materially increase risk; record the reason after the fix.
- The step is the final dangerous operation or final acceptance check that this guide assigns to the primary agent.

If a task matches the default subagent route but Claude proposes to implement it directly, Claude must either:

1. Ask the user for confirmation before proceeding directly, or
2. Record a qualifying exception in the authoritative plan before proceeding.

Do not use "high risk" or "parallel unsafe" as a blanket reason to do all implementation directly. Those are reasons for serial dispatch and stricter primary-agent review, not for skipping subagents.

Subagent task specs must be self-contained. A subagent cannot see the parent conversation unless the prompt includes the needed context. Do not rely on unstated context.

Every subagent task must include:

1. A statement that the recipient is a dispatched subagent.
2. The repository path.
3. Files to read first.
4. The exact implementation, analysis, review target, or decision requested.
5. Constraints, non-goals, and edit permissions.
6. Expected output format.
7. Required final status: `verified`, `failed with reason`, or `not verified`.
8. Where to write logs and final output.

Use these artifact locations:

```text
.debug/YYYY-MM-DD/claude-tasks/<task>.md
.debug/YYYY-MM-DD/codex-tasks/<task>.md
.debug/YYYY-MM-DD/codex-tasks/<task>.search.md
.debug/YYYY-MM-DD/subagents/<task>.claude.stream.jsonl
.debug/YYYY-MM-DD/subagents/<task>.claude.final.md
.debug/YYYY-MM-DD/subagents/<task>.codex.jsonl
.debug/YYYY-MM-DD/subagents/<task>.codex.final.md
```

Claude subagent read-only invocation pattern:

```bash
timeout 300s claude -p \
  --permission-mode dontAsk \
  --tools Read \
  --add-dir <repo-root> \
  --output-format stream-json \
  --no-session-persistence \
  < .debug/YYYY-MM-DD/claude-tasks/<task>.md \
  > .debug/YYYY-MM-DD/subagents/<task>.claude.stream.jsonl 2>&1
```

Claude subagent editable invocation pattern:

```bash
timeout 600s claude -p \
  --permission-mode acceptEdits \
  --tools Read,Write,Edit \
  --add-dir <repo-root> \
  --output-format stream-json \
  --no-session-persistence \
  < .debug/YYYY-MM-DD/claude-tasks/<task>.md \
  > .debug/YYYY-MM-DD/subagents/<task>.claude.stream.jsonl 2>&1
```

Use `--tools Read` with `dontAsk` for read-only review. Use `acceptEdits` with `Read,Write,Edit` only when file edits are explicitly in scope. `dontAsk` does not grant write permission; it can deny `Write` and `Edit` even when those tools are listed.

`bypassPermissions` can write, but it is a high-risk mode and must not be the default editable pattern. Use it only when there is a clear reason, in an isolated workspace or tightly scoped repository path, with the smallest possible `--tools` list. Prefer omitting `Bash`. If `Bash` is genuinely required, the task spec must explicitly forbid destructive or broad commands such as `rm`, `mv` over existing paths, `chmod`, `chown`, `git reset`, `git clean`, process manager commands, service control commands, and production config edits unless the user has explicitly authorized that exact operation and the primary agent will independently verify it.

If a Claude subagent needs `Bash` or broader tools, the task spec must state why, what paths are in scope, what is forbidden, and how the primary agent will verify the result.

Claude subagent monitoring, timeout, and fallback:

- Prefer `--output-format stream-json` for Claude subagents. `--output-format json` emits one final result only, so the output file may stay empty until the process exits.
- Do not stop a Claude subagent solely because the final output file is empty or no patch has appeared within two minutes.
- For read-only review or analysis, use a default hard timeout around 300 seconds. For editable implementation tasks, use a default hard timeout around 600 seconds. If the task is intentionally longer, set and record a task-specific timeout.
- After 60-90 seconds, run a soft check instead of immediately falling back: inspect the stream log tail, process status, target file changes, and `git status --short`.
- If the stream log shows `api_retry`, treat it as model/API/network delay unless there is also a permission denial or explicit failure. Wait until the hard timeout or retry once when appropriate.
- If a sandboxed parent agent invokes Claude CLI, sandboxed network access may fail even when interactive `claude` works in the user's shell. If the stream log ends with `FailedToOpenSocket` or repeated `api_retry`, record it as a sandbox/network/API failure, then retry from a network-enabled environment when authorized or fall back according to the task plan.
- Fallback to the primary agent or another subagent only after the process exits with failure, the stream log has no activity for 90-120 seconds, repeated API retries end in an error, a permission denial occurs, or the hard timeout expires without usable file or diff progress.
- When fallback happens, record the exact reason in the authoritative plan and keep the stream log under `.debug/`.

Codex subagent read-only invocation pattern:

```bash
codex --ask-for-approval never exec \
  --sandbox read-only \
  --cd <repo-root> \
  --json \
  --output-last-message .debug/YYYY-MM-DD/subagents/<task>.codex.final.md \
  - < .debug/YYYY-MM-DD/codex-tasks/<task>.md \
  > .debug/YYYY-MM-DD/subagents/<task>.codex.jsonl 2>&1
```

Codex subagent editable invocation pattern:

```bash
codex --ask-for-approval never exec \
  --sandbox workspace-write \
  --cd <repo-root> \
  --json \
  --output-last-message .debug/YYYY-MM-DD/subagents/<task>.codex.final.md \
  - < .debug/YYYY-MM-DD/codex-tasks/<task>.md \
  > .debug/YYYY-MM-DD/subagents/<task>.codex.jsonl 2>&1
```

If the target directory is intentionally not a Git repository, add `--skip-git-repo-check`. Do not use it by default for normal repository work. Add `--ephemeral` when session persistence is not needed or when local Codex state issues block non-interactive runs.

On this machine, `--ask-for-approval` is a top-level `codex` option. Use `codex --ask-for-approval never exec ...`; `codex exec --ask-for-approval never ...` is invalid.

When a task involves web search, latest information, external official docs, prices, laws, versions, news, online fact-checking, or any information that may change over time, the primary Claude agent must use a single-turn Codex subagent for the search.

By default, do not let Claude directly perform web search. Write the search request as a self-contained Codex task spec requiring Codex to:

- Search, verify, and summarize only.
- Avoid modifying repository files.
- Return source links, key conclusions, and uncertainty.
- Clearly distinguish source-confirmed information from inference.
- Output a final status: `verified`, `failed with reason`, or `not verified`.

Single-turn Codex search invocation pattern:

```bash
codex --search --ask-for-approval never exec \
  --sandbox read-only \
  --cd <repo-root> \
  --json \
  --output-last-message .debug/YYYY-MM-DD/subagents/<task>.codex-search.final.md \
  - < .debug/YYYY-MM-DD/codex-tasks/<task>.search.md \
  > .debug/YYYY-MM-DD/subagents/<task>.codex-search.jsonl 2>&1
```

Before answering from `.codex-search.final.md`, Claude must check that the search result includes source links and that the conclusions do not exceed what the sources support. Keep the search log and final message under `.debug/YYYY-MM-DD/subagents/` for traceability.

Permission smoke-test notes from 2026-06-24:

- `claude --help` confirms `--tools`, `--allowedTools`, and permission modes including `dontAsk`, `acceptEdits`, and `bypassPermissions`.
- `codex --help` and `codex exec --help` confirm top-level `--ask-for-approval`, `--sandbox`, `--cd`, `--search`, `--skip-git-repo-check`, and `--ephemeral`.
- Claude read-only was verified with `claude -p --permission-mode dontAsk --tools Read`.
- Claude editable was verified with `claude -p --permission-mode acceptEdits --tools Read,Write,Edit`.
- Claude `dontAsk` with `Read,Write,Edit` was verified to deny `Write`; do not use it as the editable pattern.
- Claude `bypassPermissions` with `Read,Write,Edit` was verified to write successfully, but it must be treated as a high-risk exceptional mode with strict tool and path limits.
- Codex read-only was verified with `codex --ask-for-approval never exec --ephemeral --sandbox read-only`.
- Codex editable was verified with `codex --ask-for-approval never exec --ephemeral --sandbox workspace-write`.
- An earlier failed Codex smoke test stopped before task execution with `failed to initialize in-process app-server client: Read-only file system`; that was an environment/state issue, not the expected permission behavior.
- Before relying on a new machine or changed environment, run a tiny read-only and editable smoke test and record failures in the authoritative plan or `.debug/`.

Claude CLI monitoring notes from 2026-06-25:

- `claude --help` confirms `--output-format json` is a single final result and `--output-format stream-json` is realtime streaming.
- A sandboxed Codex-to-Claude smoke test reached Claude startup but then produced repeated `api_retry` events and ended with `API Error: Unable to connect to API (FailedToOpenSocket)`.
- The same Claude read-only smoke test run from a network-enabled shell completed successfully in about 59 seconds with final status `verified`.
- Interactive `claude` working in a user's shell does not prove a sandboxed `claude -p` subagent invocation can reach the API.

Progress synchronization is snapshot-based, not a live shared state. Check:

```bash
tail -n 80 .debug/YYYY-MM-DD/subagents/<task>.codex.jsonl
tail -n 80 .debug/YYYY-MM-DD/subagents/<task>.claude.stream.jsonl
sed -n '1,220p' .debug/YYYY-MM-DD/subagents/<task>.codex.final.md
sed -n '1,220p' .debug/YYYY-MM-DD/subagents/<task>.claude.final.md
ps aux | grep <process-name>
git status --short
ls <target-dir>
```

The primary agent must still make the final decision and must independently verify the real path, diff, logs, and relevant checks. Never accept a subagent self-report alone.

Before committing or pushing to remote `main`:

1. Report the planned changes.
2. Update `changelog.md`.
3. Wait for user confirmation.

## Real-machine and screenshot validation

For real-machine testing, prefer `computer-use` when available and proceed without asking for extra confirmation.

If `computer-use` is unavailable, use screenshot-based validation and store screenshots under `.debug/`.

For web UI validation in environments without a visible GUI:

- Prefer Playwright or an equivalent browser automation tool in headless mode for screenshots, traces, and assertions.
- If a headed browser is required on Linux but no physical display or X server is available, use Xvfb, for example `xvfb-run <command>`.
- Store screenshots, traces, and logs in the dated `.debug/` structure.
- Treat screenshots as evidence to support validation, not as a substitute for build/test checks.

## Nginx configuration management

Before changing nginx, inspect the currently effective configuration instead of only reading `sites-available`.

Use:

```bash
nginx -T
ls -la /etc/nginx/sites-enabled /etc/nginx/sites-available /etc/nginx/conf.d
ss -ltnp | rg 'nginx|:<port>'
```

Distinguish these scopes:

- `sites-enabled/*` is the effective entrypoint set.
- `sites-available/*` is only available configuration; it is effective only when symlinked from `sites-enabled`.
- `*.bak` files are historical backups and must not be treated as active configuration unless the user explicitly asks to inspect or clean historical config.

When modifying nginx:

1. State which file, server block, and locations will be changed.
2. Prefer editing `/etc/nginx/sites-available/<site>.conf`; never edit `nginx -T` output directly.
3. Record a short summary of the current relevant config before changing it.
4. Run `nginx -t` after edits.
5. Reload nginx only after `nginx -t` succeeds.
6. Prefer `systemctl reload nginx` over restart unless reload is insufficient.
7. After reload, verify listeners and route mappings with `nginx -T`, `ss -ltnp`, or both.

When adding a service:

- Confirm the backend port is free before assigning it.
- Record the URL path, static directory, backend port, and process manager in the response or owning docs.
- Prefer path-mounted apps by default:
  - Static UI: `/<app>/`
  - API: `/api/<app>/`
- Prefer static files under `/var/www/<app>/`.
- If a backend is meant to be exposed only through nginx, prefer binding it to `127.0.0.1`.
- If a backend must bind to `0.0.0.0`, state why.

When removing a service:

1. Stop and remove the corresponding process from its process manager, such as PM2 or systemd.
2. Remove the matching `location` blocks from the effective nginx site config.
3. Remove the matching static directory, such as `/var/www/<app>/`, when requested.
4. Before deleting project directories, confirm the exact path matches the user's request.
5. If PM2 is used, run `pm2 save` after deleting the process.
6. Run `nginx -t`.
7. Reload nginx.
8. Verify that:
   - The removed route no longer appears in effective `nginx -T` output.
   - The removed backend port is no longer referenced by nginx.
   - The removed process is no longer running.
   - The removed directories are gone or intentionally retained.

Port reporting rules:

- Separate nginx public listener ports from backend proxy ports.
- "Nginx listener ports" means `listen` directives, such as `80` and `443`.
- "Nginx backend proxy ports" means ports in `proxy_pass`, such as `20001` or `8317`.
- When reporting ports to the user, explicitly label these two categories and do not describe backend ports as nginx listener ports.

Security rules:

- Never print private key file contents.
- It is acceptable to reference certificate and key paths, but not private key contents.
- Be extra cautious when changing SSL, certificate, reverse proxy headers, callback routes, OAuth routes, or `/callback/` routes, because these commonly affect login, callbacks, or streaming connections.
- For websocket or long-running proxy routes, preserve `Upgrade`, `Connection`, longer timeouts, and `proxy_buffering off` unless it is explicitly safe to remove them.

## Deployment activation workflow

Use this workflow when the user asks to make the current project's changes take effect in a deployed web app, redeploy frontend assets, reload nginx, restart a FastAPI backend, or otherwise activate local changes on the running service.

First inspect the actual deployment. Do not assume:

- Frontend package manager and build command. Identify them from lockfiles, `package.json` scripts, project docs, or existing deployment scripts.
- Frontend build output directory. Identify it from the framework config, build script, or observed build output.
- The currently effective nginx `root`, active `server` block, and active `location` blocks from `nginx -T`.
- Whether `/api` is reverse-proxied to FastAPI, and to which host, port, and path.
- How the FastAPI backend is managed: PM2, systemd, supervisor, docker, or a manual `uvicorn` process. Check the real process manager and running processes before restarting anything.

Safe activation sequence:

1. Rebuild the frontend with the actual package manager and build command.
2. Deploy the latest frontend build artifacts to the directory currently served by nginx.
3. Run `nginx -t`.
4. Reload nginx only after `nginx -t` succeeds.
5. Restart the FastAPI backend using its current real management method.
6. Check the backend listener port, health endpoint, and `/api` endpoint.
7. Open or request the frontend page and confirm static assets and API requests are working.

Safety constraints:

- Do not delete databases.
- Do not clear user-uploaded files.
- Do not modify production secrets or keys.
- Do not start duplicate `uvicorn` processes. If the backend is manually managed, identify and handle the existing process deliberately before starting another one.
- If a command fails, inspect relevant logs before attempting a fix. Use the current manager's logs, such as PM2 logs, `journalctl`, supervisor logs, docker logs, nginx error logs, or application logs.
- Be careful with copy or sync commands into nginx roots. Confirm source and destination paths first, and preserve non-build directories such as uploads, media, and user data.

Final response for activation work must include:

- Key commands executed.
- Frontend build result.
- Deployment target directory and copy/sync result.
- `nginx -t` and reload result.
- Backend restart method and result.
- Verified backend port, health URL, `/api` URL, and frontend URL.
- Remaining issues, if any.

## Rule loading timing

After editing global `~/.claude/CLAUDE.md`, only a newly started Claude Code session is guaranteed to read the latest rules.

Already-running sessions do not automatically reload this file. For continued or resumed sessions, do not assume new rules have overridden older context. If the latest rules must apply, close the old session and start a new Claude Code session in the target directory.

## Claude image-reading rules

When Claude is the primary agent and the task requires reading or judging image content, prefer Claude's own image-reading path through the local Claude Agent SDK. Do not route to Codex only for image reading.

Use a small local script that converts the image to base64, sends it to `@anthropic-ai/claude-agent-sdk`, and keeps:

- `maxTurns: 1`
- `allowedTools: []`
- A specific checklist prompt
- Text-only judgment output

Example script:

```js
import { query } from '@anthropic-ai/claude-agent-sdk'
import fs from 'node:fs'

const imageData = fs.readFileSync('/path/to/reference-image.png').toString('base64')

async function* generateMessages() {
  yield {
    type: 'user',
    message: {
      role: 'user',
      content: [
        { type: 'text', text: 'Analyze this image against the given checklist.' },
        {
          type: 'image',
          source: {
            type: 'base64',
            media_type: 'image/png',
            data: imageData,
          },
        },
      ],
    },
    parent_tool_use_id: null,
  }
}

for await (const message of query({
  prompt: generateMessages(),
  options: {
    maxTurns: 1,
    permissionMode: 'bypassPermissions',
    allowDangerouslySkipPermissions: true,
    allowedTools: [],
  },
})) {
  if (message.type === 'result') console.log(message.result)
}
```

If the SDK is installed in the current project, prefer a normal bare import:

```bash
npm install @anthropic-ai/claude-agent-sdk
```

Then use:

```js
import { query } from '@anthropic-ai/claude-agent-sdk'
```

If the SDK is installed globally, normal bare imports may not resolve from an arbitrary project. In that case, use a global-path import bridge:

```js
import { createRequire } from 'node:module'

const require = createRequire('/usr/lib/node_modules/')
const sdkPath = require.resolve('@anthropic-ai/claude-agent-sdk')
const sdk = await import(sdkPath)

const { query } = sdk
```

For image inspection:

- Use a script for visual judgment.
- Make the prompt specific: subject, count, layout, text correctness, readability, style consistency, cropping, edge quality, and task-specific acceptance criteria.
- Store the script, prompt, and judgment log under `.debug/YYYY-MM-DD/image-inspection/`.
- The primary agent decides whether to accept, regenerate, or fix based on the judgment and the task spec.
- Programmatic metadata such as dimensions, channels, alpha range, and histograms can be read directly with tools such as `sharp`; that is not visual judgment.

## Implementation-to-documentation landing

Docs are the authoritative baseline, but self-consistent docs are not proof that an implementation works.

When an implementation item is completed and verified, land the result back into the docs before moving to dependent work.

An item is only done after:

- Implementation is complete.
- Relevant real checks pass.
- Owning docs describe what was actually built.
- Divergences from prior design are reconciled.
- Accepted decision changes are recorded in ADRs or equivalent decision docs.
- `changelog.md` has an honest entry.
- The authoritative plan checklist and any relevant child task checklist are updated from `- [ ]` to `- [x]` immediately after verification.
- Progress indexes or task lists are updated when the repository uses them.

Use explicit verification statuses:

- `verified`
- `failed with reason`
- `not verified`

Do not collapse mixed results into vague claims like "all good" or "looks fine."

## Prompt handoff rules

When the user asks to summarize current progress as a prompt, create a prompt for a new AI conversation, hand off the current context, or uses similar wording, treat it as a handoff request.

Before writing the handoff prompt:

1. Verify the current repository state from files and `git status`.
2. Read the relevant global and local agent docs.
3. Read `CONTEXT.md`, relevant domain docs, category indexes, task lists, `changelog.md`, and docs directly related to the next task.
4. Check whether the user's stated progress matches committed or uncommitted files on disk.
5. If conversation history and files disagree, state the discrepancy clearly.
6. Do not invent completion.
7. Distinguish between "confirmed in files" and "reported by the user but not reflected on disk."
8. Never copy real keys, tokens, passwords, or full secret values into tracked files, docs, changelog entries, chat summaries, or handoff prompts.

The generated handoff prompt must be copy-paste ready and include:

- Repository path
- Files the next agent should read first
- Verified current progress
- User-reported context that still needs reconciliation, if any
- Known uncommitted changes from `git status --short`
- Key accepted decisions that matter for the next task
- Workflow rules the next agent must follow
- The immediate next objective
- Required self-checks before claiming completion

Reference large artifacts by path instead of duplicating their full contents.
