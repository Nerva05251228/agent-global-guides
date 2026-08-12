---
name: authoritative-planning
description: Use when work has three or more dependent steps, spans modules or services, uses subagents, involves deployment, migration, or high-risk operations, may cross sessions or context compression, or is explicitly designated long or complex.
---

# Authoritative Planning

## Trigger and storage rules

Create or identify an authoritative task book before implementation when work:

- Has three or more dependent steps.
- Spans multiple modules or services.
- Uses subagents.
- Includes deployment, migration, or high-risk operations.
- May continue across sessions or context compression.
- Is explicitly designated long or complex by the user.

Chat messages are not the authoritative task book. Keep it tracked under `docs/plans/`. Put local logs, screenshots, traces, subagent logs, prompts, task specs, and temporary tooling under `.debug/YYYY-MM-DD/`; keep `.debug/` ignored and uncommitted. Never clean `.debug/` automatically without explicit user authorization.

## Task-book fields

Use one main plan document for the overall objective. For larger work, split details into child documents and link them from the main plan.

Recommended layout when the repository has no stronger convention:

```text
docs/plans/<plan-name>.md
docs/plans/<plan-name>/<subtask>.md
```

The main plan should contain:

- Objective, non-goals, scope, and acceptance criteria.
- Expected files, modules, or services.
- Accepted decisions, dependencies, and constraints.
- Links to child task documents.
- A Markdown checklist using `- [ ]` and `- [x]`.
- Acceptance checks for each item or linked child item.
- Executor, dispatch reason, and verification owner for each long or complex item. These fields are not mandatory for ordinary short tasks outside the task book.
- A short progress log or links to dated validation artifacts.
- Recovery files and relevant runtime or process state.
- Subagent or tool fallback history: original executor, exact failure or unavailability reason, fallback executor (or `none` when no compliant fallback exists), affected scope, and dated `.debug/` log path.

Each child document should contain:

- Scope and owner agent, if subagents are used.
- Files or modules expected to change.
- Constraints and non-goals.
- Completion definition.
- Verification commands or manual checks.
- Executor, dispatch reason, and verification owner when the child item is long or complex.
- A local checklist for its own subtasks.

Checklist discipline:

- Do not mark an item complete before implementation and verification are both done.
- After each item is implemented and verified, immediately update the authoritative checklist from `- [ ]` to `- [x]` and record an ISO-8601 completion timestamp.
- Include the validation evidence beside the item or in the linked child document: command, test result, screenshot path, log path, diff reference, or explanation.
- Do not wait until the end to batch-check completed items.
- If an item is partially done, leave it unchecked and add a concise status note.
- If completed evidence becomes invalid, reopen the item, change it back to `- [ ]`, and record the reason and ISO-8601 reopening time.
- If the plan changes, update the plan document before continuing dependent work.

For a search-required item, record the exact requested search executor and model, outcome, and dated log path. If an attempt fails or the required route is confirmed unavailable, stop that item and mark it `failed with reason`. Use `not verified` when the search could not be attempted and availability was not established. Do not infer an answer from memory or substitute another model or route unless the user or governing policy explicitly changes the requirement. Independent items may continue; dependent items must stop. Record `fallback executor: none` when no compliant fallback exists.

Context recovery and compacted sessions:

- If the active plan is unclear, the conversation appears compacted or truncated, or work resumes after an interruption, read the authoritative task book first rather than continuing from memory.
- Check local `AGENTS.md`, `CONTEXT.md`, `docs/plans/`, relevant domain docs, task indexes, `changelog.md`, and dated `.debug/` artifacts such as subagent logs, validation logs, screenshots, and task specs.
- Treat the on-disk plan and checklist as the memory baseline. Reconcile them with `git status`, current files, running processes, and validation artifacts before taking dependent action.
- Identify the last completed item and its timestamp and evidence, then the first pending or reopened item in task-book order. Do not repeat a completed item while its implementation and verification evidence remain valid.
- If no plan exists or the plan is stale, create or update the authoritative plan before continuing non-trivial work.

## Implementation-to-documentation landing

Docs are the authoritative baseline, but self-consistent docs are not proof that an implementation works.

When an implementation item is completed and verified, land the result back into the docs before moving to dependent work.

An item is only done after:

- Implementation is complete.
- Relevant real checks pass.
- Owning docs describe what was actually built.
- Divergences from prior design are reconciled.
- Accepted decision changes are recorded in ADRs or equivalent decision docs.
- The repository changelog has an entry only when policy requires it, and the entry describes the resulting repository or product change rather than implementation history, agent activity, or validation logs.
- The authoritative plan checklist and any relevant child task checklist are updated from `- [ ]` to `- [x]` immediately after verification, with an ISO-8601 completion timestamp.
- Progress indexes or task lists are updated when the repository uses them.

Use explicit verification statuses:

- `verified`
- `failed with reason`
- `not verified`

Do not collapse mixed results into vague claims like "all good" or "looks fine."
