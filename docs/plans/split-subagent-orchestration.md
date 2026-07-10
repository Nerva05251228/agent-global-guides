# Split Subagent Orchestration Skill

## Objective

Split the combined `subagent-orchestration` skill into two separately installable skills:

- `codex-subagent-orchestration`
- `claude-subagent-orchestration`

This lets users install or invoke the orchestration guidance that matches the current primary agent more directly.

## Non-Goals

- Do not change the core routing policy.
- Do not change installer behavior beyond relying on existing `skills/*` discovery.
- Do not commit or push without explicit user confirmation.

## Checklist

- [x] Create Codex-primary subagent orchestration skill.
  - Executor: Primary Codex
  - Dispatch reason: Small repository documentation and skill split; direct edit is lower overhead. A subagent review will validate the result.
  - Verification owner: Primary Codex
  - Evidence: `quick_validate.py skills/codex-subagent-orchestration` passed.
- [x] Create Claude-primary subagent orchestration skill.
  - Executor: Primary Codex
  - Dispatch reason: Same split as above; keep both skill files structurally aligned.
  - Verification owner: Primary Codex
  - Evidence: `quick_validate.py skills/claude-subagent-orchestration` passed.
- [x] Remove old combined `subagent-orchestration` skill.
  - Executor: Primary Codex
  - Dispatch reason: Mechanical rename/removal tied to the split.
  - Verification owner: Primary Codex
  - Evidence: `find skills -maxdepth 2 -type f | sort` no longer lists `skills/subagent-orchestration`.
- [x] Update guide references, installer assets, README, and changelog.
  - Executor: Primary Codex
  - Dispatch reason: References must stay synchronized with shipped skill names.
  - Verification owner: Primary Codex
  - Evidence: `rg -nF '$subagent-orchestration' -g 'AGENTS.md' -g 'CLAUDE.md' -g 'SKILL.md' -g '*.md' docs skills .` returned no matches.
- [x] Validate skills, scanner, shell syntax, and references.
  - Executor: Primary Codex
  - Dispatch reason: Local deterministic checks.
  - Verification owner: Primary Codex
  - Evidence: all skills passed `quick_validate.py`; `bash -n` passed for installer/scanner scripts; `scripts/scan-guides.sh` passed; `git diff --check` passed.
- [x] Run an independent Codex subagent review of the split.
  - Executor: Codex subagent
  - Dispatch reason: The change affects agent-routing guidance; independent review can catch stale references or install issues.
  - Verification owner: Primary Codex
  - Evidence: short read-only Codex review returned `verified` with no findings in `.debug/2026-06-30/subagents/review-split-subagent-orchestration-short.codex.final.md`.

## Progress Log

- 2026-06-30: Plan created before editing.
- 2026-06-30: Split skills created, old combined skill removed, guide references updated, and deterministic checks passed.
- 2026-06-30: First broad read-only Codex review did not produce a final report within the review window; recorded as `not verified` in `.debug/2026-06-30/subagents/review-split-subagent-orchestration.codex.final.md`.
- 2026-06-30: Follow-up short read-only Codex review returned `verified` with no findings.
