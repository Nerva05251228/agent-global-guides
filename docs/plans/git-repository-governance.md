# Git Repository Governance

## Objective

Add project-agnostic global guidance for maintaining a clean, reviewable, secure, and release-ready Git repository. Changelog policy is one part of the broader repository governance workflow.

## Non-Goals

- Do not impose one branching model on every repository.
- Do not require Semantic Versioning or Conventional Commits when a repository already uses another documented convention.
- Do not commit or push without explicit user confirmation.
- Do not rewrite unrelated existing changes.

## Checklist

- [x] Research authoritative guidance for repository hygiene, commits, documentation, security, releases, and changelogs.
  - Executor: Codex search subagent attempted; Primary Codex fallback
  - Dispatch reason: Independent read-only web research with source links.
  - Verification owner: Primary Codex
  - Evidence: Primary-source summary at `.debug/2026-07-10/research/git-repository-governance-sources.md`. The search subagent timed out after DNS failures; its log remains under `.debug/2026-07-10/subagents/`.
- [x] Define a project-agnostic repository governance policy with local-convention precedence.
  - Executor: Primary Codex
  - Dispatch reason: Integration requires reconciling multiple standards with the existing global guides.
  - Verification owner: Primary Codex
  - Evidence: `skills/git-repository-governance/SKILL.md` explicitly gives local documented conventions precedence over optional defaults.
- [x] Add a modular Git repository governance skill and UI metadata.
  - Executor: Primary Codex
  - Dispatch reason: Repository editing and skill integration.
  - Verification owner: Primary Codex
  - Evidence: `quick_validate.py skills/git-repository-governance` passed; `agents/openai.yaml` is present.
- [x] Add concise routing and critical hygiene rules to Codex/Claude global docs and installer assets.
  - Executor: Primary Codex
  - Dispatch reason: Keep always-loaded context small while making the policy discoverable.
  - Verification owner: Primary Codex
  - Evidence: English and Chinese docs route to `$git-repository-governance`; installer asset copies match with `cmp`.
- [x] Update README, changelog, and related planning/documentation language.
  - Executor: Primary Codex
  - Dispatch reason: Shipped package documentation must reflect the new skill.
  - Verification owner: Primary Codex
  - Evidence: README lists the skill; `CHANGELOG.md` follows Keep a Changelog structure and contains only resulting repository changes.
- [x] Validate skills, scanner, shell syntax, references, and temporary installation behavior.
  - Executor: Primary Codex
  - Dispatch reason: Deterministic local acceptance checks.
  - Verification owner: Primary Codex
  - Evidence: all skills passed `quick_validate.py`; scanner, `bash -n`, `git diff --check`, asset comparisons, and temporary Codex/Claude installation passed.
- [x] Run an independent documentation and policy review.
  - Executor: Claude subagent
  - Dispatch reason: Independent critique of policy clarity, safety, and internal consistency.
  - Verification owner: Primary Codex
  - Evidence: Claude returned `verified`; its plan-status and skill-pointer findings were addressed. Stream log: `.debug/2026-07-10/subagents/review-git-repository-governance.claude.stream.jsonl`.

## Progress Log

- 2026-07-10: Scope clarified as full Git repository governance, not changelog-only guidance.
- 2026-07-10: Official Git, GitHub, Keep a Changelog, SemVer, and Conventional Commits guidance reviewed and summarized.
- 2026-07-10: Added the governance skill, global routing, changelog policy, repository documentation updates, and installer integration.
- 2026-07-10: Deterministic validation and temporary installation passed; independent Claude review returned `verified` after findings were resolved.
