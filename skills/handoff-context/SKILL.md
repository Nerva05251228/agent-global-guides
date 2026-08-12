---
name: handoff-context
description: Use when the user requests a progress summary, handoff prompt, new-session context, recovery after interruption or compaction, or transfer of repository work to another agent.
---

# Handoff Context

## Prompt handoff rules

When the user asks to summarize current progress as a prompt, create a prompt for a new AI conversation, hand off the current context, or uses similar wording, treat it as a handoff request.

Before writing the handoff prompt:

1. Locate the relevant authoritative task book. When one exists, read it first and treat it as the primary recovery source. When the task did not require one or none exists, state that fact and recover from repository files without inventing task-book fields.
2. Verify the current repository state from files, `git status`, and relevant diffs.
3. Read the relevant global and local agent docs, `CONTEXT.md`, domain docs, indexes, task lists, `changelog.md`, and docs directly related to the next task.
4. Check whether the user's stated progress matches committed or uncommitted files on disk.
5. When a task book exists, reconcile its evidence with validation artifacts, fallback logs, and relevant running-service or process state.
6. When a task book exists, identify the last completed item with its ISO-8601 timestamp and evidence, then the first pending or reopened item.
7. Do not repeat completed work while its implementation and verification evidence remain valid. When a task book exists and evidence is invalid, report the item as reopened with its recorded reason and time.
8. If conversation history and files disagree, state the discrepancy clearly. Do not invent completion.
9. Distinguish between "confirmed in files" and "reported by the user but not reflected on disk."
10. Never copy real keys, tokens, passwords, or full secret values into tracked files, docs, changelog entries, chat summaries, or handoff prompts.

The generated handoff prompt must be copy-paste ready and include:

- Repository path
- Files the next agent should read first
- The authoritative task-book path and its last completed and first pending or reopened items when one exists; otherwise state that no task book was required or found
- For task-book work, the last completed item's ISO-8601 completion time, verification status, and evidence, plus any reopening reason and time
- Verified current progress using only `verified`, `failed with reason`, or `not verified`
- User-reported context that still needs reconciliation, if any
- Known uncommitted changes from `git status --short`
- Key accepted decisions that matter for the next task
- Subagent, model, or tool failure and fallback history, including exact reason, fallback executor, affected scope, and dated `.debug/` log paths
- Relevant running services, processes, ports, or other runtime state that the next agent must preserve or recheck
- Workflow rules the next agent must follow
- The immediate next objective
- Required self-checks before claiming completion

Reference large artifacts by path instead of duplicating their full contents.
