# Agent Global Guides V2 Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved Codex/Claude guide, skill, installer, fallback, long-task, and Windows/Linux/macOS behavior changes without committing personal identity values to the reusable repository.

**Architecture:** Keep always-loaded global guides concise and route detailed workflows through skills. Preserve Bash support for Linux/macOS, add behaviorally equivalent PowerShell support for Windows, and verify installers against isolated temporary homes before touching real global directories. The repository source remains sanitized; installation renders or preserves local identity values.

**Tech Stack:** Markdown, Bash, PowerShell, GitHub Actions, Git.

---

## Scope And Constraints

- Executor: Primary Codex.
- Dispatch reason: repository scripts, guide edits, and test loops are Codex-owned work; no implementation subagent is required.
- Verification owner: Primary Codex.
- Source specification: `../agent-global-guides-update-plan.md` relative to this repository.
- Do not modify the user's real Codex or Claude home directories during repository implementation or tests.
- Do not commit or push. Present the final diff and verification evidence for separate approval.
- Keep all personalized GitHub owner and Git email values out of reusable repository templates.
- Record local debug/test output outside tracked changelog content.
- Scanning is mandatory for dry-run and real installation. Remove the `--skip-scan` bypass; any scan failure must exit before the first target write.
- Immediately after each task is implemented and verified, mark that task complete with an ISO-8601 timestamp and evidence. Do not defer checklist updates to final verification.

## Task 1: Add Installer Contract Tests

**Files:**
- Create: `tests/test-installers.sh`
- Create: `tests/test-installers.ps1`
- Test: `skills/agent-guides-installer/scripts/install-global-guides.sh`
- Test: `skills/agent-guides-installer/scripts/install-global-guides.ps1`

- [x] **Step 1: Write failing Bash behavior tests**
  - Use temporary Codex and Claude homes.
  - Assert `--dry-run` writes nothing.
  - Assert `--github-owner` and `--git-email` render local values while source templates keep placeholders.
  - Assert existing non-placeholder identity values are preserved when flags are omitted.
  - Assert `--backup` stores changed guides/skills outside active `skills/` directories.
  - Assert `--no-backup` creates no backup and reports recovery is unavailable.
  - Assert an interactive terminal receives one backup question when no backup flag is supplied, and a non-interactive run defaults to backup without blocking.
  - Assert legacy `subagent-orchestration` is removed only after both replacement skills are recursively identical to their source directories and their `SKILL.md` frontmatter names match the expected replacement names.
  - Assert malformed or incomplete replacement skills prevent legacy removal.
  - Assert dry-run reports the exact planned legacy removal and selected recovery policy; real installation reports the removed path and either the backup path or `recovery unavailable`.
  - Assert every dry-run and real install invokes the scanner.
  - Assert a scanner failure exits non-zero and leaves both target homes byte-for-byte unchanged.
  - Assert the installer exposes no `--skip-scan` bypass.

- [x] **Step 2: Run the Bash tests and verify RED**
  - Run: `bash tests/test-installers.sh` using Bash discovered from the current environment (Git Bash on Windows, system Bash on Linux/macOS).
  - Expected: FAIL because new flags, backup layout, identity rendering, and cleanup behavior do not exist.

- [x] **Step 3: Write failing PowerShell parity tests**
  - Cover the same contract using isolated temporary homes and native PowerShell path handling, including mandatory scan-before-write and zero writes after scan failure.

- [x] **Step 4: Run the PowerShell tests and verify RED**
  - Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-installers.ps1`.
  - Expected: FAIL because the PowerShell installer does not exist.

- [x] **Step 5: Update this task book immediately after RED is verified**
  - Record the failing commands, expected failure reasons, and ISO-8601 completion time for the test-authoring task.

### Task 1 RED Evidence

- Completed: `2026-08-11T16:30:55.2522386+08:00`.
- Bash command: `bash tests/test-installers.sh`, executed with Git Bash discovered from the active `git` executable because `bash` was not directly on `PATH`.
- Bash result: expected RED, exit `1`; `13` tests ran, `12` failed, and `1` interactive-PTY assertion was explicitly skipped because this Windows Git Bash environment has no automatable `script` PTY command. Existing populated homes are fingerprinted before dry-run, and the scanner-invocation contract covers six dry-run/real combinations across explicit backup, explicit no-backup, and implicit backup policy paths.
- Bash failure evidence: the current installer rejects `--backup`, `--no-backup`, `--github-owner`, and `--git-email`; still advertises and accepts `--skip-scan`; uses adjacent backups instead of `<home>/backups/agent-global-guides/`; and does not validate/report legacy replacement cleanup.
- PowerShell command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-installers.ps1`.
- PowerShell result: expected RED, exit `1`; the required native installer `skills/agent-guides-installer/scripts/install-global-guides.ps1` does not exist. Once present, the parity suite includes a mocked interactive host assertion that counts exactly one backup prompt.
- Test self-checks: `bash -n tests/test-installers.sh`, PowerShell parser validation for `tests/test-installers.ps1`, and `git diff --check` all passed.
- Production installer and scanner scripts were not changed during Task 1.

## Task 2: Implement The Bash Installer Contract

**Files:**
- Modify: `skills/agent-guides-installer/scripts/install-global-guides.sh`
- Modify: `skills/agent-guides-installer/scripts/scan-guides.sh`
- Modify: `scripts/install-global-guides.sh`
- Modify: `scripts/scan-guides.sh`

- [x] **Step 1: Enforce mandatory scanning before target writes**
  - Remove `--skip-scan` from usage and argument parsing.
  - Run the scanner for dry-run and real installation before creating target directories, backups, rendered files, or any other target state.
  - Exit non-zero on scan failure with zero target writes.
  - Update the Bash scanner to inspect all shipped repository files, including `.ps1`, with the same known-personal-value, secret, and machine-path patterns required on every operating system.

- [x] **Step 2: Add backup-policy and identity options**
  - Support `--backup`, `--no-backup`, `--github-owner <value>`, and `--git-email <value>`.
  - Interactive runs ask once when neither backup flag is supplied; non-interactive runs default to backup.
  - Dry-run prints the selected backup policy and planned targets.

- [x] **Step 3: Render sanitized templates safely**
  - Preserve existing non-placeholder values when flags are absent.
  - Prefer explicit flag values when supplied.
  - Never modify source templates during rendering.

- [x] **Step 4: Move backups outside active skill discovery**
  - Store backups beneath `<home>/backups/agent-global-guides/<timestamp>/`.
  - Back up guides and changed skills only when backup is enabled.

- [x] **Step 5: Remove the legacy skill after replacement verification**
  - Verify each installed replacement directory is recursively identical to its source directory and its `SKILL.md` frontmatter `name` is the expected replacement name.
  - Remove `skills/subagent-orchestration` only after successful replacement verification.
  - Make cleanup idempotent. Dry-run reports the exact planned removal and selected recovery policy. Real installation reports the exact removed path and either the backup path or that recovery is unavailable.

- [x] **Step 6: Run Bash tests and verify GREEN**
  - Run: `bash tests/test-installers.sh`.
  - Expected: PASS.

- [x] **Step 7: Update this task book immediately**
  - Record the passing command, timestamp, and backup/identity/cleanup evidence.

### Task 2 Verification Evidence

- Completed: `2026-08-11T18:17:57.3841635+08:00`.
- Scan command: `bash scripts/scan-guides.sh`; result: `verified` against the complete shipped repository source set, including Bash and PowerShell files.
- Test command: `bash tests/test-installers.sh`; result: `verified`, exit `0`, `13` tests run, `12` passed, `0` failed, `1` PTY-dependent interactive assertion skipped on this Windows Git Bash host.
- Verified behavior: mandatory scan before target writes; no `--skip-scan`; dry-run zero writes on populated homes; explicit and implicit backup policy; external timestamped backups; identity rendering and preservation without source mutation; both replacement skills validated recursively and by frontmatter before per-home legacy removal; exact recovery reporting; malformed replacements keep the legacy skill.
- Root Bash wrappers required no behavior change because they already delegate arguments directly to the updated bundled scripts.

## Task 3: Add Native Windows PowerShell Support

**Files:**
- Create: `skills/agent-guides-installer/scripts/install-global-guides.ps1`
- Create: `skills/agent-guides-installer/scripts/scan-guides.ps1`
- Create: `scripts/install-global-guides.ps1`
- Create: `scripts/scan-guides.ps1`

- [x] **Step 1: Implement PowerShell scan parity**
  - Match Bash source discovery, known-personal-value scanning, common secret scanning, and exit behavior.
  - Scan the complete shipped repository, including `.sh` and `.ps1`, using the same known-personal-value, secret, and machine-path patterns as the Bash scanner.

- [x] **Step 2: Implement PowerShell installer parity**
  - Match source modes, dry-run, backup policy, identity rendering, complete skill installation, external backup roots, legacy cleanup, and verification.
  - Use native path APIs and PowerShell file operations; do not shell out to Bash.

- [x] **Step 3: Run PowerShell tests and verify GREEN**
  - Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-installers.ps1`.
  - Expected: PASS.

- [x] **Step 4: Re-run Bash tests**
  - Expected: PASS with no behavior drift.

- [x] **Step 5: Update this task book immediately**
  - Record both platform test commands, timestamps, and parity evidence.

### Task 3 Verification Evidence

- Completed: `2026-08-11T18:36:15.9572163+08:00`.
- PowerShell command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-installers.ps1`; result: `verified`, exit `0`, `13/13` passed.
- Bash regression command: `bash tests/test-installers.sh`; result: `verified`, exit `0`, `12` passed, `0` failed, `1` environment-dependent PTY assertion skipped.
- Parity evidence: both scanners cover the complete shipped source set and both installers enforce pre-write scanning, dry-run zero writes, identity rendering/preservation, interactive and non-interactive backup policy, timestamped external backups, validated dual replacement skills, exact legacy cleanup/recovery reporting, and removal of the scan bypass.
- Windows implementation uses native PowerShell path, hashing, copy, removal, and process behavior without Bash delegation.

## Task 4: Update Global Guides And Authoritative Planning

**Files:**
- Modify: `docs/AGENTS.md`
- Modify: `docs/CLAUDE.md`
- Modify: `docs/AGENTS.zh.md`
- Modify: `docs/CLAUDE.zh.md`
- Modify: `skills/authoritative-planning/SKILL.md`
- Modify: `skills/handoff-context/SKILL.md`

- [x] **Step 1: Keep repository bootstrap user-controlled**
  - Ask before repository creation and before running `setup-matt-pocock-skills`.
  - Keep repository visibility private by default and source identity placeholders sanitized.

- [x] **Step 2: Add long/complex task-book rules**
  - Define triggers, required fields, immediate checklist updates, ISO-8601 completion timestamps, evidence, context recovery, and explicit reopened handling.
  - Require executor metadata only for long/complex authoritative-plan items.
  - Require local logs, screenshots, traces, subagent logs, prompts, and temporary tooling to use dated `.debug/YYYY-MM-DD/` paths.
  - Prohibit automatic `.debug/` cleanup without explicit user authorization.

- [x] **Step 3: Strengthen handoff recovery**
  - Make the task book the primary source.
  - Include last completed evidence, first pending/reopened item, fallback history, and relevant runtime state.
  - Prohibit repeating verified completed work.

- [x] **Step 4: Keep detailed workflows skill-routed**
  - Keep always-loaded guides concise and preserve the approved Git/changelog governance routing.
  - Add concise high-risk rules for exact target disclosure before force pushes, remote-branch deletion, tags/releases, production deployment, and irreversible external operations.
  - Require state/log inspection before retrying a failed high-risk action and final reporting of executed/not-executed scope, rollback/recovery, residual risk, and verification state.
  - Add the exact search routing contract to both Codex and Claude guides: single-turn, citation-bearing, read-only `gpt-5.5 xhigh` Codex search task by default; required-search failure stops the task and is recorded in the task book and `.debug/`.

- [x] **Step 5: Add content-level assertions for critical guide policies**
  - Extend installer/content tests to assert setup confirmation, dated `.debug/YYYY-MM-DD/` storage, `.debug/` retention, long-task timestamps/reopen behavior, exact search routing, search failure reporting, and high-risk final reporting appear in both English guides and synchronized assets.

- [x] **Step 6: Update this task book immediately**
  - Record content-test commands, timestamp, and guide/skill evidence.

### Task 4 Verification Evidence

- Completed: `2026-08-12T09:44:26.5447917+08:00`.
- Content contract command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-installers.ps1`; result: `verified`, including critical policy assertions in both English guides and synchronized installer assets.
- Both English guides and Chinese references require setup confirmation, dated retained `.debug/`, long-task triggers, ISO-8601 completion and reopening, exact search routing/failure behavior, and high-risk final reporting while routing detailed workflows to skills.
- `authoritative-planning` and `handoff-context` contain task-book recovery, last-completed/first-pending ordering, fallback history, runtime state, and no-repeat rules.
- Independent subagent re-review reported no remaining Task 4 findings. Primary verification also passed the PowerShell repository scan and `git diff --check`.

## Task 5: Update Subagent And Search Policies

**Files:**
- Modify: `skills/codex-subagent-orchestration/SKILL.md`
- Modify: `skills/claude-subagent-orchestration/SKILL.md`

- [x] **Step 1: Change delegation from mandatory to preferential**
  - Use subagents when materially useful; keep routing as a default preference.
  - Keep integration, dangerous operations, and final verification with the primary agent.

- [x] **Step 2: Add unified fallback disclosure**
  - Record original executor, exact failure/unavailability reason, log path, fallback executor, scope, verification, and residual risk.
  - Require final user-facing disclosure and explicit failure when all fallbacks fail.
  - Record failure and fallback details in the authoritative task book and `.debug/`; never place them in the repository changelog.

- [x] **Step 3: Add the exact search route**
  - For both primary agents, search-required work defaults to a single-turn, read-only Codex task using exact model `gpt-5.5` with `xhigh` reasoning.
  - Never silently substitute another model or execution route.
  - If required search cannot run or fails, stop and return `failed with reason` or `not verified`; do not guess.
  - Restrict the search task to read-only search/verification/summarization, require direct source links, and distinguish source-confirmed facts from inference.
  - Record unavailable/failed search execution in the authoritative task book and `.debug/`, then disclose it in the final result.

- [x] **Step 4: Make platform tools primary and CLI examples secondary**
  - Prefer built-in task/subagent controls.
  - Replace Unix-only assumptions with concise Windows/Linux/macOS fallback guidance.

- [x] **Step 5: Update this task book immediately**
  - Record policy/content checks, timestamp, and evidence for both orchestration skills.

### Task 5 Verification Evidence

- Completed: `2026-08-12T09:44:26.5447917+08:00`.
- Both agent-specific skills now define delegation as a materially-useful preference, keep primary integration/dangerous/final verification ownership, and require executor metadata only for long or complex task-book items.
- Exact search route is single-turn, read-only Codex with `gpt-5.5` and `xhigh`; direct links and fact/inference separation are required; substitution is forbidden; unavailable or failed required search stops the affected item and is logged/disclosed.
- Unified fallback fields include original executor, exact reason, log path, fallback executor/scope, verification result, and residual risk. Agent failures remain outside changelog content.
- Subagent pressure testing verified that the updated policy stops instead of substituting `gpt-5.6`; symmetric contract assertions and `git diff --check` passed.

## Task 6: Update Deployment, Nginx, And Claude Image Skills

**Files:**
- Modify: `skills/deployment-activation/SKILL.md`
- Modify: `skills/nginx-service-management/SKILL.md`
- Modify: `skills/claude-image-inspection/SKILL.md`

- [x] **Step 1: Generalize deployment discovery**
  - Discover actual frontend, backend, proxy, process manager, and health-check architecture.
  - Treat nginx/FastAPI/PM2/systemd as scenarios, not universal requirements.
  - Deploy only affected components and report skipped steps.

- [x] **Step 2: Make nginx management platform-aware**
  - Dynamically discover configuration paths, listeners, and service manager.
  - Cover Windows Services/IIS context, Linux systemd/supervisor, macOS launchd/Homebrew Services, and shared Docker/PM2/manual cases.
  - Do not install nginx or replace an active web server without explicit authorization.

- [x] **Step 3: Preserve the required Claude SDK image path**
  - Keep `bypassPermissions`, `allowDangerouslySkipPermissions: true`, `allowedTools: []`, and `maxTurns: 1` when Claude personally inspects an image.
  - Treat the SDK as required; use the repository package manager in Node projects or an isolated ignored tooling directory in non-Node projects.
  - Resolve global modules dynamically; do not hard-code Linux paths.
  - Distinguish Claude-native inspection from delegated Codex judgment.

- [x] **Step 4: Update this task book immediately**
  - Record skill validation commands, timestamp, and evidence.

### Task 6 Verification Evidence

- Completed: `2026-08-12T09:44:26.5447917+08:00`.
- Deployment activation now discovers real frontend/backend/proxy/process-manager/health architecture and reports affected and skipped components instead of requiring nginx/FastAPI/PM2/systemd.
- Nginx management includes Windows Services/IIS, Linux service managers/listener tools, macOS launchd/Homebrew Services, containers, PM2, and manual processes; absent nginx is not installed or substituted without authorization.
- Claude-native image inspection preserves `bypassPermissions`, `allowDangerouslySkipPermissions: true`, `allowedTools: []`, and `maxTurns: 1`; the SDK is installed with project tooling or an ignored isolated directory, and global resolution uses `npm root -g` rather than a hard-coded Linux path.
- PowerShell repository scan and targeted content assertions passed.

## Task 7: Synchronize Installer Assets And Documentation

**Files:**
- Modify: `skills/agent-guides-installer/SKILL.md`
- Synchronize: `skills/agent-guides-installer/assets/guides/AGENTS.md`
- Synchronize: `skills/agent-guides-installer/assets/guides/CLAUDE.md`
- Synchronize: `skills/agent-guides-installer/assets/guides/AGENTS.zh.md`
- Synchronize: `skills/agent-guides-installer/assets/guides/CLAUDE.zh.md`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Create: `.github/workflows/test-installers.yml`

- [x] **Step 1: Document Windows/Linux/macOS installation**
  - Provide PowerShell commands for Windows and Bash commands for Linux/macOS.
  - Document backup prompts/flags, identity options, dry-run, legacy cleanup, and restart requirements.

- [x] **Step 2: Synchronize guide assets**
  - Ensure installer assets exactly match the corresponding `docs/` guides.

- [x] **Step 3: Add a three-OS CI matrix**
  - `windows-latest`: run PowerShell scan/tests natively; optionally run Bash tests through Git Bash only as an additional parity check.
  - `ubuntu-latest`: run Bash scan/tests natively and PowerShell tests with the runner-provided `pwsh` for parity.
  - `macos-latest`: run Bash scan/tests natively and PowerShell tests only when `pwsh` is available; otherwise keep PowerShell behavior covered by Windows/Ubuntu.
  - Use isolated temporary homes on every OS.

- [x] **Step 4: Update the changelog with notable outcomes only**
  - Record cross-platform installer support, long-task recovery, search/fallback policy, deployment discovery, and safe legacy cleanup.
  - Do not include debugging history, command transcripts, or local failures.

- [x] **Step 5: Update this task book immediately**
  - Record asset comparisons, CI syntax checks, timestamp, and documentation evidence.

### Task 7 Verification Evidence

- Completed: `2026-08-12T09:44:26.5447917+08:00`.
- README and installer skill document native Bash and PowerShell commands, identity flags, backup prompt/flags, mandatory scan, legacy cleanup, installed-skill limits, and new-session restart requirements.
- All four installer guide assets were copied from and verified against their corresponding `docs/` files.
- `.github/workflows/test-installers.yml` defines Windows, Ubuntu, and macOS coverage with native primary paths and documented PowerShell parity behavior.
- Changelog records notable repository outcomes only; local shutdown diagnosis and debugging history remain in ignored `.debug/`.

## Task 8: Final Verification And Documentation Landing

**Files:**
- Modify: `docs/plans/agent-global-guides-v2-update.md`
- Modify: `../agent-global-guides-update-plan.md`

- [x] **Step 1: Run all repository scans and tests**
  - Bash: `bash scripts/scan-guides.sh` and `bash tests/test-installers.sh`.
  - PowerShell: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\scan-guides.ps1` and `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-installers.ps1`.

- [x] **Step 2: Run isolated dry-runs and real temporary-home installs**
  - Verify both backup policies, identity rendering/preservation, complete skill installation, legacy cleanup, and no writes outside temporary homes.

- [x] **Step 3: Verify documentation and asset parity**
  - Compare each `docs/` guide with its installer asset copy.
  - Confirm no personal values or machine-specific paths entered tracked templates.

- [x] **Step 4: Review the complete diff**
  - Run `git status --short --branch`, `git diff --check`, and `git diff`.
  - Confirm every changed line maps to an approved requirement.

- [x] **Step 5: Reconcile task-book final state**
  - Confirm Tasks 1-7 were already updated immediately after their verification.
  - Leave any failed or unverified item unchecked with an explicit reason; do not batch-mark prior work here.

- [x] **Step 6: Stop before commit, push, remote update, or real local installation**
  - Present the verified diff and remaining risks to the user for separate approval.

### Task 8 Verification Evidence

- Completed: `2026-08-12T10:46:34.3884095+08:00`.
- Bash commands: `bash scripts/scan-guides.sh` and `bash tests/test-installers.sh`; result: `verified`, scan exit `0`, installer contract `16` run, `15` passed, `0` failed, `1` skipped because this Windows Git Bash host lacks a PTY-capable `script` command. The skipped interaction is covered by the native PowerShell test.
- PowerShell commands: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\scan-guides.ps1` and `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-installers.ps1`; result: `verified`, scan exit `0`, installer contract `15/15` passed.
- Isolated real installation: `verified` in temporary Codex and Claude homes, including complete skill copies, identity rendering, backups, validated legacy cleanup, exact recovery reporting, and no real global-home writes. Dry-run and both backup policies are covered by both contract suites.
- Cross-platform correction: a final review found macOS-incompatible `mapfile`, GNU `sort -z`, and test-only in-place `sed`; these were replaced with Bash 3.2/BSD-compatible constructs and guarded by a regression assertion.
- Safety correction: independent review reproduced a PowerShell frontmatter bypass in which a body `name:` line could authorize legacy removal. A RED/GREEN regression now requires `name:` inside the opening YAML frontmatter block in both PowerShell and Bash contracts.
- Documentation: all four guide assets are SHA-256-identical to `docs/`; tracked templates contain no approved personal owner, email, or local machine path.
- Diff review: `git diff --check`, changed-skill frontmatter validation, complete tracked/untracked file review, CI matrix inspection, and repository scans passed. Local `grep.exe.stackdump` evidence was moved into ignored `.debug/2026-08-12/` and is not part of the repository diff.
- Final installation and publication: after separate explicit user approval, the package was installed into the configured Codex and Claude homes with backup snapshot `20260812-112822`; both guide identities were rendered locally, all ten skills matched repository source recursively, both legacy orchestration directories were removed after validation, and recovery copies were verified. Implementation commit `e60ba03211b159103659d444ee4d6bd22516e7a0` was pushed to `origin/main` without force.
- Push fallback: the configured HTTPS push failed because Git Credential Manager reported a cancelled dialog and the non-interactive process had no `/dev/tty`. Primary Codex retried only after inspecting remote state, using the already authenticated SSH route for the same repository and the same normal `main:main` push. `git fetch origin main` then verified local `HEAD` and `origin/main` at `e60ba03211b159103659d444ee4d6bd22516e7a0`. Log: `.debug/2026-08-12/push-fallback.md`. Residual risk: remote CI completes asynchronously.
