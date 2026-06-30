---
name: handoff-context
description: Create accurate handoff prompts and context summaries for a new AI conversation, including repository state verification, git status, local/global agent docs, plans, changelog, confirmed progress, uncommitted changes, discrepancies, and required next-agent checks. Use when the user asks to summarize progress, create a handoff, prepare a prompt for a new session, recover context, or transfer work to another agent.
---

# Handoff Context

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
