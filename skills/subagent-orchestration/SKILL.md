---
name: subagent-orchestration
description: Plan, dispatch, monitor, and verify Codex and Claude subagents, including routing decisions, task specs, read-only/editable invocation patterns, stream-json monitoring, timeout handling, retries, and fallback. Use when a task involves subagents, parallel workstreams, implementation delegation, review delegation, or Claude/Codex cross-agent execution.
---

# Subagent Orchestration

## Subagent orchestration and invocation

Prefer multiple subagents in parallel when a task has independent workstreams. The primary agent must first design the split: define each subagent's scope, file or module ownership, shared resources, dependencies, and acceptance checks. Avoid assigning two agents to edit the same route, component, module, migration, lockfile, process manager entry, or production config unless one task is explicitly review-only or the work is sequenced.

The primary agent remains responsible for planning, review, integration, final verification, and acceptance. Never trust a subagent's self-report alone. Before accepting work, independently:

- Review the diff against the task spec.
- Re-run the relevant build, validation, lint, tests, or project checks.
- Confirm that behavior is unchanged for pure refactors or structural splits.
- Confirm that docs and changelog entries were updated when required.

Do not reuse a completed subagent session for unrelated new work. Start a fresh subagent for each independent task.

Exception: when a task requires a continuous back-and-forth conversation with retained context, the same subagent session may stay open until the discussion is finished and the final unified result is confirmed. After that result is accepted, close the session and start a fresh one for unrelated work.

For complex work, keep capabilities, functions, modules, and responsibilities clearly separated.

Avoid piling unrelated behavior into one file. Aim for:

- High cohesion
- Low coupling
- Robustness
- Reuse only when reuse is justified

Do not expose comments, development notes, implementation explanations, debug wording, or internal tool language in frontend UI. UI text must be written for end users.

Before starting any non-trivial plan item, decide and record the executor in the authoritative plan:

```text
Executor: Primary Codex or Primary Claude / Codex subagent / Claude subagent / other named agent
Dispatch reason:
Verification owner:
```

Default routing:

- Follow the current primary agent's always-loaded `AGENTS.md` or `CLAUDE.md` routing rules first.
- Backend, infrastructure, repository edits, refactors, migrations, build/test loops, mechanical migrations, log analysis, full-codebase search, and process or service management generally route to Codex or Codex subagents.
- Frontend product/design/development work, including UI/UX design, component implementation, layout and styling, interaction behavior, browser-facing copy, frontend review, and Claude SDK image inspection generally route to Claude or Claude subagents.
- Independent reasoning, critique, planning, spec review, product copy review, documentation critique, architecture review, and second-pass judgment generally route to Claude subagents.
- If the preferred subagent is unavailable or fails, the primary agent may handle the work directly or dispatch another suitable subagent, but the reason must be recorded.
- Keep integration, dangerous operations, final verification, and acceptance with the primary agent.
- For nginx, production config, database migrations, auth, payments, certificates, process deletion, and other high-risk operations, subagents may draft analysis, patches, or command plans, but the primary agent must perform or explicitly control the final dangerous step and verification.

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

If a task strongly calls for independent subagent implementation, review, or analysis but the primary agent handles it fully directly, record the reason in the authoritative plan or state it before proceeding.

Do not use "high risk" or "parallel unsafe" as a blanket reason to skip subagents. Those are reasons for serial dispatch and stricter primary-agent review, not for skipping useful subagent work.

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
- From a Codex primary agent, a sandboxed shell may block Claude CLI network access even when interactive `claude` works in the user's shell. If the stream log ends with `FailedToOpenSocket` or repeated `api_retry`, record it as a sandbox/network/API failure, then retry from a network-enabled environment when authorized or fall back according to the task plan.
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

Verified CLI behavior: `--ask-for-approval` is a top-level `codex` option. Use `codex --ask-for-approval never exec ...`; `codex exec --ask-for-approval never ...` is invalid.

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
