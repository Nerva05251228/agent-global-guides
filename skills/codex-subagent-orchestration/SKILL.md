---
name: codex-subagent-orchestration
description: Use when Codex is primary and delegation, independent review, required web search, parallel workstreams, or cross-agent execution may materially improve the result.
---

# Codex Subagent Orchestration

## Core Rules

Use subagents when delegation is materially useful, such as for independent workstreams, specialized capabilities, isolated review, required search, or a bounded task that reduces primary-agent context pressure. Delegation is a preference, not a requirement for every non-trivial task. When dispatching parallel work, first define each subagent's scope, file or module ownership, shared resources, dependencies, and acceptance checks. Avoid assigning two agents to edit the same route, component, module, migration, lockfile, process manager entry, or production config unless one task is explicitly review-only or the work is sequenced.

The primary Codex agent remains responsible for planning, review, integration, final verification, and acceptance. Never trust a subagent's self-report alone. Before accepting work, independently:

- Review the diff against the task spec.
- Re-run the relevant build, validation, lint, tests, or project checks.
- Confirm that behavior is unchanged for pure refactors or structural splits.
- Confirm that docs and changelog entries were updated when required.

Do not reuse a completed subagent session for unrelated new work. Start a fresh subagent for each independent task.

Exception: when a task requires a continuous back-and-forth conversation with retained context, the same subagent session may stay open until the discussion is finished and the final unified result is confirmed. After that result is accepted, close the session and start a fresh one for unrelated work.

For complex work, keep capabilities, functions, modules, and responsibilities clearly separated. Avoid piling unrelated behavior into one file. Aim for high cohesion, low coupling, robustness, and reuse only when reuse is justified.

Do not expose comments, development notes, implementation explanations, debug wording, or internal tool language in frontend UI. UI text must be written for end users.

## Codex-Primary Routing

For each long or complex item in an authoritative task book, decide and record the executor:

```text
Executor: Primary Codex / Codex subagent / Claude subagent / other named agent
Dispatch reason:
Verification owner:
```

Default routing when Codex is the primary agent:

- Prefer Codex directly or a Codex subagent for backend work, infrastructure, repository edits, refactors, migrations, build/test loops, mechanical migrations, log analysis, full-codebase search, and process or service management.
- Prefer Claude subagents for frontend product/design/development work, including UI/UX design, component implementation, layout and styling, interaction behavior, browser-facing copy, and frontend review.
- Prefer Claude subagents for independent reasoning, critique, planning, spec review, product copy review, documentation critique, architecture review, or second-pass judgment.
- These are routing preferences. Codex may work directly when dispatch adds no material value, the task is small or tightly coupled to primary-session state, or the primary must retain control.
- Keep integration, dangerous operations, final verification, and acceptance with the primary Codex agent.
- For nginx, production config, database migrations, auth, payments, certificates, process deletion, and other high-risk operations, subagents may draft analysis, patches, or command plans, but the primary Codex agent must perform or explicitly control the final dangerous step and verification.

Parallel dispatch safety:

- Prefer parallel subagents for independent workstreams after assigning clear ownership boundaries.
- If parallel subagents could contend for a database, repository, port, lockfile, process manager, production config, or the same files/modules, do not run those tasks in parallel.
- When parallel work is unsafe but delegation is still materially useful, use one serial subagent.

Direct primary-agent work is appropriate when:

- The task is genuinely small and single-step, such as a tiny config read, one-line edit, or simple command.
- The user explicitly says not to use subagents.
- The preferred subagent is unavailable or has failed and the fallback is recorded as specified below.
- The task requires private parent-session context, live user interaction, or an active permission state that cannot be safely handed off.
- The work is an urgent fix where dispatch overhead would materially increase risk; record the reason after the fix.
- The step is the final dangerous operation or final acceptance check assigned to the primary agent.

For a long or complex task-book item, record why the primary agent is the executor when a materially useful delegation route was considered but not used. Small or routine direct work does not require executor metadata.

## Required Search Route

When correct completion requires web search, current data, external official documentation, prices, laws, versions, news, online fact-checking, or other information that may have changed, default to one single-turn, read-only Codex search task with exactly:

```text
Model: gpt-5.5
Reasoning effort: xhigh
Turns: 1
Access: read-only
Allowed work: search, verify, summarize, cite
Forbidden work: repository edits or any other state change
```

The search result must include direct source links and clearly separate source-confirmed facts from inference. It must return `verified`, `failed with reason`, or `not verified`.

Do not silently or explicitly substitute another model, reasoning effort, or execution route. A different launcher may be used only when it still runs the exact `gpt-5.5`/`xhigh`, single-turn, read-only search task. If that exact search cannot be started or fails, stop the affected task, do not guess from memory, and report `failed with reason` or `not verified`. Record the unavailable or failed search in the authoritative task book when one exists and in dated `.debug/YYYY-MM-DD/`, then disclose it in the final result.

Prefer built-in task controls that expose exact model and reasoning settings. For CLI fallback, preserve this exact option set before adding platform-specific input and logging syntax:

```text
codex --ask-for-approval never --search --model gpt-5.5 -c model_reasoning_effort="xhigh" exec --ephemeral --sandbox read-only ...
```

On Linux/macOS, feed the task spec through standard input and redirect JSONL/final output into dated `.debug/`. On Windows PowerShell, use `Get-Content -Raw` for the task spec and `Tee-Object` for the stream log. If the installed CLI rejects any exact option or cannot make search available, treat the required search as unavailable; do not alter the model or reasoning effort to make the command run.

## Fallback And Disclosure

When a preferred executor, model, tool, or permission route is unavailable, fails, times out, or is denied, fallback is allowed only when it preserves the task's requirements. The exact search route above is non-substitutable.

For every fallback, record this unified entry in the authoritative task book for long or complex work and in dated `.debug/YYYY-MM-DD/`:

```text
Original executor:
Exact failure or unavailability reason:
Log path:
Fallback executor:
Fallback scope:
Verification owner and result:
Residual risk:
```

Never put agent failures, local permission problems, timeouts, or fallback history in the repository changelog. The final user-facing result must disclose the original executor, exact reason, fallback executor, affected scope, verification result, and residual risk. If every permitted fallback fails, stop the affected work and return an explicit `failed with reason` or `not verified` result rather than implying completion.

## Task Specs

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

## Calling Claude From Codex

Prefer the platform's built-in task/subagent controls for dispatch, monitoring, cancellation, timeout, and result collection. Use CLI invocation only when built-in controls are unavailable or the task explicitly requires a CLI process. The examples below use POSIX shell syntax for Linux. On macOS, prefer the built-in timeout because GNU `timeout` is not installed by default. On Windows PowerShell, replace input/output redirection with `Get-Content -Raw ... | & <command> ... 2>&1 | Tee-Object -FilePath ...`, and enforce the hard timeout with the built-in task control or PowerShell process/job APIs.

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

`bypassPermissions` can write, but it is a high-risk mode and must not be the default editable pattern. Use it only when there is a clear reason, in an isolated workspace or tightly scoped repository path, with the smallest possible `--tools` list. Prefer omitting `Bash`. If `Bash` is genuinely required, the task spec must explicitly forbid destructive or broad commands such as `rm`, `mv` over existing paths, `chmod`, `chown`, `git reset`, `git clean`, process manager commands, service control commands, and production config edits unless the user has explicitly authorized that exact operation and the primary Codex agent will independently verify it.

If a Claude subagent needs `Bash` or broader tools, the task spec must state why, what paths are in scope, what is forbidden, and how the primary Codex agent will verify the result.

Claude subagent monitoring, timeout, and fallback:

- Prefer `--output-format stream-json` for Claude subagents. `--output-format json` emits one final result only, so the output file may stay empty until the process exits.
- Do not stop a Claude subagent solely because the final output file is empty or no patch has appeared within two minutes.
- For read-only review or analysis, use a default hard timeout around 300 seconds. For editable implementation tasks, use a default hard timeout around 600 seconds. If the task is intentionally longer, set and record a task-specific timeout.
- After 60-90 seconds, run a soft check instead of immediately falling back: inspect the stream log tail, process status, target file changes, and `git status --short`.
- If the stream log shows `api_retry`, treat it as model/API/network delay unless there is also a permission denial or explicit failure. Wait until the hard timeout or retry once when appropriate.
- From a Codex primary agent, a sandboxed shell may block Claude CLI network access even when interactive `claude` works in the user's shell. If the stream log ends with `FailedToOpenSocket` or repeated `api_retry`, record it as a sandbox/network/API failure, then retry from a network-enabled environment when authorized or fall back according to the task plan.
- Fallback to the primary Codex agent or another subagent only after the process exits with failure, the stream log has no activity for 90-120 seconds, repeated API retries end in an error, a permission denial occurs, or the hard timeout expires without usable file or diff progress.
- When fallback happens, record the exact reason in the authoritative plan and keep the stream log under `.debug/`.

## Calling Codex Subagents

Use built-in Codex task/subagent controls first. For CLI fallback, Linux/macOS may use the POSIX forms below. In Windows PowerShell, pipe `Get-Content -Raw` into `codex`, use `Tee-Object` for the JSONL log, and keep all paths native or quoted; do not assume Bash, `/tmp`, `timeout`, `tail`, `sed`, or `ps` exists.

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

## Verified Behavior Notes

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

## Monitoring And Acceptance

Progress synchronization is snapshot-based, not a live shared state. Prefer built-in status/wait/read controls. CLI fallback checks for Linux/macOS include:

```bash
tail -n 80 .debug/YYYY-MM-DD/subagents/<task>.codex.jsonl
tail -n 80 .debug/YYYY-MM-DD/subagents/<task>.claude.stream.jsonl
sed -n '1,220p' .debug/YYYY-MM-DD/subagents/<task>.codex.final.md
sed -n '1,220p' .debug/YYYY-MM-DD/subagents/<task>.claude.final.md
ps aux | grep <process-name>
git status --short
ls <target-dir>
```

Windows PowerShell equivalents include:

```powershell
Get-Content -LiteralPath .debug/YYYY-MM-DD/subagents/<task>.codex.jsonl -Tail 80
Get-Content -LiteralPath .debug/YYYY-MM-DD/subagents/<task>.claude.stream.jsonl -Tail 80
Get-Content -LiteralPath .debug/YYYY-MM-DD/subagents/<task>.codex.final.md -TotalCount 220
Get-Process -Name <process-name> -ErrorAction SilentlyContinue
git status --short
Get-ChildItem -LiteralPath <target-dir>
```

The primary Codex agent must still make the final decision and must independently verify the real path, diff, logs, and relevant checks. Never accept a subagent self-report alone.

Before committing or pushing to remote `main`:

1. Report the planned changes.
2. Update the repository changelog only when policy requires it; record notable outcomes, not debugging or agent activity.
3. Wait for user confirmation.
