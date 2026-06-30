---
name: authoritative-planning
description: Create and maintain authoritative plan documents, child task docs, checklists, executor records, verification evidence, and implementation-to-documentation landing for multi-step work. Use when work needs planning, checklist tracking, progress recovery after compaction, or docs-as-baseline discipline.
---

# Authoritative Planning

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
- Executor for each item: `Primary Codex`, `Primary Claude`, `Codex subagent`, `Claude subagent`, or another explicitly named agent.
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
- Check local `AGENTS.md`, `CONTEXT.md`, `docs/plans/`, relevant domain docs, task indexes, `changelog.md`, and dated `.debug/` artifacts such as subagent logs, validation logs, screenshots, and task specs.
- Treat the on-disk plan and checklist as the memory baseline. Reconcile them with `git status`, current files, running processes, and validation artifacts before taking dependent action.
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
- `changelog.md` has an honest entry.
- The authoritative plan checklist and any relevant child task checklist are updated from `- [ ]` to `- [x]` immediately after verification.
- Progress indexes or task lists are updated when the repository uses them.

Use explicit verification statuses:

- `verified`
- `failed with reason`
- `not verified`

Do not collapse mixed results into vague claims like "all good" or "looks fine."
